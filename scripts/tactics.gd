extends RefCounted
const Modifiers = preload("res://scripts/combat_modifiers.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const Biomes = preload("res://scripts/biomes.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const UltRules = preload("res://scripts/ultimate_rules.gd")
## Formation rules and all combat results; contains no nodes or rendering logic.
## The weak owner avoids a Run -> Tactics -> Run reference cycle.
var owner_ref: WeakRef
var enemies: Array[Dictionary] = []
var slow_left := 0.0
var last_dot_targets: Array[int] = []
var elapsed := 0.0
var synergy_used: Dictionary = {}
var last_ultimate: Dictionary = {}
var ultimate_serial := 0
var feedback_events: Array[Dictionary] = []
var damage_received := 0.0


func run():
	return owner_ref.get_ref()


func bind(owner, campaign: TaleCampaign) -> void:
	owner_ref = weakref(owner)
	for actor in owner.actors:
		configure_actor(actor, campaign.row_for(actor.id))
	ensure_front()


func configure_actor(actor: Dictionary, row: String) -> void:
	var profile: Dictionary = TaleCatalog.HERO_TACTICS[actor.id]
	actor["class"] = profile["class"]
	actor.row = rank_for_class(actor["class"]) if run().expedition else row
	actor.evasion = float(actor.get("evasion", TaleCatalog.CLASSES[profile["class"]].evasion))
	actor.base_evasion = actor.evasion
	actor.evasion_left = 0.0
	actor.energy = 0.0 if run().expedition and actor.id=="alice" else clampf(float(actor.get("energy", 0.0)), 0, 100)
	actor["ult_pending"] = false
	actor["ult_queued"] = false
	actor["ap"] = 0
	actor["pp"] = 0


static func rank_for_class(job: String) -> String:
	return "front" if job == "vanguard" else ("middle" if job == "assassin" else "back")


func ensure_front() -> void:
	if run().expedition:
		# A class update can overflow an older saved formation. Reserve each natural
		# row before distributing overflow, preserving all nine existing recruits.
		var occupied:Dictionary={"front":0,"middle":0,"back":0}
		var overflow:Array=[]
		for actor in run().actors:
			var preferred:=rank_for_class(actor["class"])
			if occupied[preferred]<3:
				actor.row=preferred
				occupied[preferred]+=1
			else:overflow.append(actor)
		for actor in overflow:
			for row in ["middle","back","front"]:
				if occupied[row]<3:
					actor.row=row
					occupied[row]+=1
					break
		return
	for actor in run().actors:
		if actor.row == "front":
			return
	if not run().actors.is_empty():
		run().actors[0].row = "front"


func spawn() -> void:
	var owner = run()
	enemies.clear()
	feedback_events.clear()
	synergy_used.clear()
	slow_left = 0
	elapsed = 0
	damage_received = 0
	var count: int = 1 if owner.stage == 0 and owner.wave == 0 else (2 if owner.stage < 3 else 3)
	var total: float = TaleCatalog.STAGES[owner.stage].hp * [1.0, 1.25, 2.4][owner.wave]
	if owner.expedition:
		var depth: int = owner.rooms_cleared if owner.endless else owner.stage * 6 + owner.phase
		count = 3 if ExpeditionContent.is_boss(owner.stage,owner.phase) else owner.rng.randi_range(1,ExpeditionContent.enemy_limit(owner.stage,owner.endless))
		total = 86.0 * ((1.0 + depth * 0.05) * pow(1.045, mini(depth, 120)) * (1.0 + maxi(0, depth - 120) * 0.08)) * (1.5 if ExpeditionContent.is_boss(owner.stage, owner.phase) else 1.0) * (1.35 if owner.room_kind == "elite" else 1.0)
	var roles: Array = ["vanguard", "ranger", "mage"]
	if owner.stage % 4 == 2:
		roles[1] = "assassin"
	elif owner.stage % 4 == 1:
		roles[2] = "assassin"
	var picked: Array[int] = []
	var row_counts:Dictionary={"front":0,"middle":0,"back":0}
	if owner.expedition and not owner.active_secret.is_empty():
		count=0
		enemies.append(preload("res://scripts/secret_encounters.gd").spawn(owner))
	for index in count:
		var boss_unit: bool = (ExpeditionContent.is_boss(owner.stage, owner.phase) if owner.expedition else owner.wave == 2) and index == 0
		var weight := (0.70 if index == 0 else 0.30 / maxf(1, count - 1)) if (ExpeditionContent.is_boss(owner.stage,owner.phase) if owner.expedition else owner.wave==2) and count > 1 else (0.72 if owner.expedition else 1.0/count)
		var job: String = "mage" if boss_unit and owner.stage % 2 == 1 else str(roles[index % roles.size()])
		var interval := 3.1 + index * 0.35
		var variant := 0
		if owner.expedition:
			variant = (0 if ExpeditionContent.boss_rule(owner.stage) == 3 else (3 if ExpeditionContent.boss_rule(owner.stage) == 7 else 5)) if boss_unit else Biomes.pick(owner.stage, owner.phase, index, owner.rng, picked)
			if not boss_unit:
				var options:Array[int]=[]
				for candidate in 6:
					if row_counts[rank_for_class(Biomes.CLASSES[candidate])]<3:options.append(candidate)
				if not options.has(variant):variant=options[owner.rng.randi_range(0,options.size()-1)]
			picked.append(variant)
			job = str(Biomes.CLASSES[variant]) if not boss_unit else ("vanguard" if ExpeditionContent.boss_rule(owner.stage) == 3 else "mage")
			interval = float(Biomes.INTERVALS[variant])
			row_counts[rank_for_class(job)]+=1
		enemies.append({
			"id": "enemy_%d" % index, "class": job,
			"name": TaleCatalog.STAGES[owner.stage].boss if boss_unit else TaleCatalog.STAGES[owner.stage].enemy,
			"row": "front" if index == 0 else "back", "hp": total * weight, "max_hp": total * weight,
			"damage": float(TaleCatalog.STAGES[owner.stage].damage) * (1.25 if boss_unit else 0.75) / sqrt(float(count)),
			"armor": 1.0 + owner.stage * 0.6 if job == "vanguard" else owner.stage * 0.22,
			"evasion": float(TaleCatalog.CLASSES[job].evasion) * (0.55 if boss_unit else 1.0),
			"boss": boss_unit, "interval": interval, "timer": 1.8 + index * 0.5,
			"burn": 0.0, "burn_left": 0.0, "poison": 0.0, "poison_left": 0.0
		})
		if owner.expedition:
			enemies[-1]["variant"] = variant
			enemies[-1]["biome"] = Biomes.biome(owner.stage)
			enemies[-1].row = rank_for_class(job)
			if not boss_unit: enemies[-1].name = Biomes.ENEMIES[Biomes.biome(owner.stage)][variant]
			enemies[-1].hp *= float(Biomes.HP[variant]) if not boss_unit else 1.0
			enemies[-1].max_hp = enemies[-1].hp
			enemies[-1].damage = (13.0 + (owner.rooms_cleared if owner.endless else owner.stage * 6 + owner.phase) * 0.85) * (1.2 if boss_unit else 1.0) * (1.15 if owner.room_kind == "elite" else 1.0) * (float(Biomes.POWER[variant]) if not boss_unit else 1.0)
	for actor in owner.actors:
		actor.ult_pending = false
		actor.ult_queued = false
		actor.shield = actor.max_hp*float(Modifiers.effects(actor).get("shield_start",0)) if owner.expedition else 0.0
		actor["burn_follow_ready"]=0.0
		actor["spirit_flames"] = 0
		if owner.expedition:
			actor.evasion = actor.base_evasion
			actor.evasion_left = 0.0
		if owner.expedition and actor.id == "puss" and ExpeditionContent.has(actor, "ready"): actor.charged = true
	if owner.expedition:
		for at in enemies.size(): enemies[at]["slot"] = at
		BossRules.setup(self)
	sync_totals()


static func eligible(attacker: Dictionary, defenders: Array) -> Array[int]:
	if attacker.get("sealed", false):
		var threads: Array[int] = []
		for at in defenders.size():
			if defenders[at].hp > 0 and defenders[at].get("binds", "") == attacker.get("id", ""): threads.append(at)
		if not threads.is_empty(): return threads
	var front: Array[int] = []
	var middle: Array[int] = []
	var back: Array[int] = []
	for index in defenders.size():
		if float(defenders[index].hp) <= 0: continue
		match str(defenders[index].row):
			"front": front.append(index)
			"middle": middle.append(index)
			_: back.append(index)
	match str(attacker["class"]):
		"vanguard": return front if not front.is_empty() else (middle if not middle.is_empty() else back)
		"ranger", "assassin": return back if not back.is_empty() else (middle if not middle.is_empty() else front)
	return front + middle + back


static func choose_target(attacker: Dictionary, defenders: Array) -> int:
	var candidates := eligible(attacker, defenders)
	if candidates.is_empty():
		return -1
	var selected: int = candidates[0]
	for index in candidates:
		if attacker["class"] == "artificer":
			if float(defenders[index].armor) < float(defenders[selected].armor):
				selected = index
		elif attacker["class"] in ["mage", "assassin", "ranger"]:
			if float(defenders[index].hp) / float(defenders[index].max_hp) < float(defenders[selected].hp) / float(defenders[selected].max_hp):
				selected = index
	return selected


func target_for(index: int) -> int:
	if index < 0 or index >= run().actors.size():
		return -1
	return choose_target(run().actors[index], enemies)


func deal(target: Dictionary, amount: float, magical: bool, certain := false) -> Dictionary:
	var owner = run()
	var evaded: bool = not certain and owner.rng.randf() < float(target.evasion)
	if evaded:
		return {"damage": 0.0, "evaded": true, "absorbed": 0.0}
	if target.get("guarded_by_banner", false): amount *= 0.60
	var guarded: bool = not magical and not certain and target.get("class", "") == "vanguard" and int(target.get("pp", 0)) > 0
	if guarded:
		target.pp -= 1
		amount *= 0.65
	var armor:float=float(target.armor)*(0.8 if float(target.get("curse_left",0))>0 else 1.0)
	var raw := maxf(amount * 0.28 if owner.expedition else 1.0, amount - armor * (0.8 if target.get("armor_break_left",0.0)>0 else 1.0) * (0.35 if magical else 1.0))
	var absorbed := minf(float(target.get("shield", 0.0)), raw)
	if target.has("shield"):
		target.shield -= absorbed
	var actual := minf(float(target.hp), raw - absorbed)
	target.hp = maxf(0, target.hp - actual)
	if owner.expedition and owner.actor_ids().has(str(target.get("id", ""))): damage_received += actual
	return {"damage": actual, "evaded": false, "absorbed": absorbed, "guarded": guarded}


func hit_enemy(index: int, requested := -1) -> Dictionary:
	if run().expedition:
		var hit: Dictionary = Abilities.attack(self, index, requested)
		BossRules.refresh(self)
		return hit
	var owner = run()
	if index < 0 or index >= owner.actors.size() or owner.actors[index].hp <= 0:
		return {}
	var actor: Dictionary = owner.actors[index]
	var valid := eligible(actor, enemies)
	var target: int = requested if valid.has(requested) else target_for(index)
	if target < 0:
		return {}
	var critical: bool = owner.rng.randf() < float(actor.crit)
	var amount: float = actor.damage * (2.0 if critical else 1.0)
	var combo: bool = actor.id == "mulan" and (int(actor.hits) + 1) % 3 == 0
	if combo:
		amount *= 1.3 + actor.ranks[1] * 0.2
	var focused: bool = actor["class"] in ["mage", "artificer"] and int(actor.get("pp", 0)) > 0
	if focused:
		actor.pp -= 1
		amount *= 1.20
	var hit := deal(enemies[target], amount, actor["class"] in ["mage", "artificer"])
	if hit.evaded and enemies[target]["class"] == "assassin" and int(enemies[target].get("pp", 0)) > 0:
		enemies[target].pp -= 1
		hit["counter"] = deal(actor, float(enemies[target].damage) * 0.6, false, true).damage
	elif not hit.evaded and actor["class"] == "ranger" and int(actor.get("pp", 0)) > 0 and enemies[target].hp > 0:
		actor.pp -= 1
		hit.damage += deal(enemies[target], actor.damage * 0.25, false, true).damage
		hit["followup"] = true
	if focused:
		hit["focused"] = true
	hit.merge({"target": target, "critical": critical, "message": "Esquiva" if hit.evaded else "", "targets": [target]})
	actor.energy = minf(100, actor.energy + (8.0 if hit.evaded else 18.0 + actor.get("energy_bonus", 0.0)))
	if not hit.evaded:
		actor.hits += 1
		if TaleCatalog.NEW_HERO_IDS.has(actor.id):
			if not owner.unlock_stats.has("new_hits"):
				owner.unlock_stats["new_hits"] = {}
			owner.unlock_stats.new_hits[actor.id] = int(owner.unlock_stats.new_hits.get(actor.id, 0)) + 1
		match str(actor.id):
			"scarlet":
				enemies[target].burn = 2.0 + actor.ranks[1] * 2
				enemies[target].burn_left = 3.0
			"snow_white":
				enemies[target].poison = 2.0 + actor.ranks[0] * 2
				enemies[target].poison_left = 4.0
			"mulan":
				if combo:
					owner.unlock_stats.combos += 1
					hit.message = "Terceiro corte"
			"rapunzel":
				if int(actor.hits) % 3 == 0:
					owner.unlock_stats.healing += owner.heal_group(3.0 + actor.ranks[0] * 3)
			"ariel":
				if int(actor.hits) % 3 == 0:
					owner.heal_group(3.0 + actor.ranks[0] * 4)
			"maria":
				enemies[target].poison = 2.0 + actor.ranks[2] * 2
				enemies[target].poison_left = 4.0
			"matches":
				enemies[target].burn = 2.0 + actor.ranks[0] * 2
				enemies[target].burn_left = 3.0
			"aladin":
				if int(actor.hits) % 3 == 0:
					for ally in owner.actors:
						if ally.hp > 0:
							ally.shield = minf(ally.max_hp, ally.shield + 3.0 + actor.ranks[0] * 2)
		actor.hp = minf(actor.max_hp, actor.hp + actor.leech)
	sync_totals()
	return hit


func hit_party(enemy_index := 0) -> Dictionary:
	if run().expedition:
		return BossRules.execute(self, enemy_index)
	var owner = run()
	if enemy_index < 0 or enemy_index >= enemies.size() or enemies[enemy_index].hp <= 0:
		return {}
	var enemy: Dictionary = enemies[enemy_index]
	var target := choose_target(enemy, owner.actors)
	if target < 0:
		return {}
	var weakness := 0.0
	for ally in owner.actors:
		if ally.id == "rapunzel" and ally.hp > 0:
			weakness = ally.ranks[2] * 0.03
	var actor: Dictionary = owner.actors[target]
	var amount: float = float(enemy.damage) * (1.0 - weakness)
	var focused: bool = enemy["class"] in ["mage","artificer"] and int(enemy.get("pp",0)) > 0
	if focused:
		enemy.pp -= 1
		amount *= 1.20
	var hit := deal(actor, amount, enemy["class"] == "mage")
	if focused:
		hit["focused"] = true
	if not hit.evaded and actor.hp > 0 and enemy["class"] == "ranger" and int(enemy.get("pp",0)) > 0:
		enemy.pp -= 1
		hit.damage += deal(actor, float(enemy.damage) * 0.25, false, true).damage
		hit["followup"] = true
	if not hit.evaded and actor.id=="peter" and int(actor.get("spirit_flames",0))>0:
		actor.spirit_flames-=1
		hit["counter"]=deal(enemy,actor.damage,true,true).damage
	if hit.evaded and actor["class"] == "assassin" and int(actor.get("pp", 0)) > 0:
		actor.pp -= 1
		hit["counter"] = deal(enemy, actor.damage * 0.6, false, true).damage
		sync_totals()
	if actor.hp > 0 and actor.hp < actor.max_hp * 0.5:
		for support in owner.actors:
			if support.id in ["rapunzel", "ariel"] and support.hp > 0 and int(support.get("pp", 0)) > 0:
				support.pp -= 1
				var healed := minf(actor.max_hp - actor.hp, actor.max_hp * 0.08)
				actor.hp += healed
				hit["support_heal"] = healed
				if support.id == "rapunzel":
					owner.unlock_stats.healing += healed
				break
	actor.energy = minf(100, actor.energy + hit.damage / actor.max_hp * 80.0)
	hit["target"] = target
	hit["enemy"] = enemy_index
	return hit


func interval_for(index: int) -> float:
	var slow := 0.30 if slow_left > 0 else 0.0
	for actor in run().actors:
		if actor.id == "ariel" and actor.hp > 0:
			slow += 0.08 + actor.ranks[1] * 0.06
	return float(enemies[index].interval) * (1 + slow) * (1.15 if float(enemies[index].get("item_slow_left",0))>0 else 1.0)


func tick(delta: float) -> void:
	elapsed += delta
	slow_left = maxf(0, slow_left - delta)
	last_dot_targets.clear()
	for index in enemies.size():
		var enemy: Dictionary = enemies[index]
		if enemy.hp <= 0:
			continue
		enemy["item_slow_left"]=maxf(0,float(enemy.get("item_slow_left",0))-delta)
		enemy["curse_left"]=maxf(0,float(enemy.get("curse_left",0))-delta)
		var fire_damage: float = enemy.burn * minf(delta, enemy.burn_left)
		var poison_damage: float = enemy.poison * minf(delta, enemy.poison_left)
		var damage: float = fire_damage + poison_damage
		enemy["armor_break_left"]=maxf(0,float(enemy.get("armor_break_left",0.0))-delta)
		enemy.burn_left = maxf(0, enemy.burn_left - delta)
		enemy.poison_left = maxf(0, enemy.poison_left - delta)
		enemy.hp = maxf(0, enemy.hp - damage)
		if enemy.hp <= 0 and run().expedition:
			enemy["died_burning"] = fire_damage > 0
			enemy["died_poisoned"] = poison_damage > 0
		if damage > 0:
			last_dot_targets.append(index)
	for actor in run().actors:
		if run().expedition and actor.hp > 0 and actor.get("hostile_dot_left", 0.0) > 0:
			var duration := minf(delta, float(actor.hostile_dot_left))
			var before: float = actor.hp
			actor.hp = maxf(0, actor.hp - duration * (float(actor.get("hostile_burn", 0)) + float(actor.get("hostile_poison", 0))))
			damage_received += before - float(actor.hp)
			actor.hostile_dot_left = maxf(0, actor.hostile_dot_left - delta)
		if actor.get("evasion_left", 0.0) > 0:
			actor.evasion_left = maxf(0, actor.evasion_left - delta)
			if actor.evasion_left == 0:
				actor.evasion = actor.base_evasion
		if run().expedition and actor.id=="alice":actor.energy=0.0
		if actor.get("hair_guard",false) and actor.shield<=0:actor.hair_guard=false
		if actor.hp > 0 and not actor.ult_pending and (not run().expedition or actor.id!="alice"):
			actor.energy = minf(100, actor.energy + delta * 1.4)
	if run().expedition:
		Abilities.deaths(self)
		BossRules.refresh(self)
	sync_totals()


func sync_totals() -> void:
	var owner = run()
	owner.enemy_hp = 0.0
	owner.enemy_max = 0.0
	owner.burn_left = 0.0
	owner.poison_left = 0.0
	for enemy in enemies:
		owner.enemy_hp += enemy.hp
		owner.enemy_max += enemy.max_hp
		owner.burn_left = maxf(owner.burn_left, enemy.burn_left)
		owner.poison_left = maxf(owner.poison_left, enemy.poison_left)


func reserve_ultimate(index: int) -> bool:
	if index < 0 or index >= run().actors.size():
		return false
	var actor: Dictionary = run().actors[index]
	if actor.hp <= 0 or not ultimate_ready(index) or actor.ult_pending or target_for(index) < 0:
		return false
	if run().expedition and actor.id=="alice":actor.card_charge=0
	else:actor.energy = 0.0
	actor.ult_pending = true
	return true

func ultimate_ready(index: int) -> bool:
	if index<0 or index>=run().actors.size():return false
	return UltRules.resource_ready(run().actors[index]) if run().expedition else run().actors[index].energy>=100


func ultimate(index: int, requested := -1) -> Dictionary:
	var owner = run()
	if index < 0 or index >= owner.actors.size():
		return {}
	var actor: Dictionary = owner.actors[index]
	if not actor.ult_pending or actor.hp <= 0:
		return {}
	if owner.expedition and UltRules.IDS.has(str(actor.id)):return UltRules.execute(self,index,requested)
	actor.ult_pending = false
	var target := target_for(index)
	if eligible(actor, enemies).has(requested):
		target = requested
	if target < 0:
		return {}
	var targets: Array[int] = []
	var amount := 0.0
	var healed := 0.0
	var per_target := {}
	match str(actor.id):
		"scarlet", "ariel", "alice", "aladin", "maria", "matches":
			for at in enemies.size():
				if enemies[at].hp > 0:
					targets.append(at)
		"mulan":
			targets = eligible({"class": "vanguard"}, enemies)
			actor.shield += actor.max_hp * 0.35
		"snow_white", "joao":
			targets.append(target)
		"peter":
			actor["spirit_flames"]=3
			actor.shield=minf(actor.max_hp,actor.shield+actor.max_hp*0.30)
		"puss":
			targets = eligible({"class": "vanguard"}, enemies)
			actor.shield = minf(actor.max_hp, actor.shield + actor.max_hp * 0.25)
		"rapunzel":
			for ally in owner.actors:
				if ally.hp > 0:
					var before: float = ally.hp
					ally.hp = minf(ally.max_hp, ally.hp + ally.max_hp * 0.35 * (1.0+float(Modifiers.effects(actor).get("heal_mult",0))))
					healed += ally.hp - before
					ally.shield += ally.max_hp * 0.20
			owner.unlock_stats.healing += healed
	if not targets.is_empty() and not targets.has(target):target=targets[0]
	for at in targets:
		var multiplier: float = {"scarlet": 2.0, "snow_white": 4.0, "mulan": 3.2, "ariel": 1.6, "joao": 4.2, "maria": 2.8, "alice": 2.0, "puss": 3.6, "peter": 3.0, "matches": 2.0, "aladin": 2.0}.get(actor.id, 1.0)
		var dealt := 0.0
		for strike in (5 if actor.id=="joao" else 1):
			dealt += deal(enemies[at],Modifiers.amount(actor,enemies[at],actor.damage*multiplier,true)/(5.0 if actor.id=="joao" else 1.0),actor["class"] in ["mage","artificer"],true).damage
		per_target[at] = dealt
		amount += dealt
		if actor.id=="scarlet":Modifiers.burn(self,actor,enemies[at],6.0+actor.ranks[1]*2,4.0)
		elif actor.id in ["snow_white","maria"]:
			Modifiers.venom(actor,enemies[at],8.0+actor.ranks[0 if actor.id=="snow_white" else 2]*2)
			enemies[at].poison_left=6.0
			if actor.id=="maria":enemies[at]["armor_break_left"]=6.0
		elif actor.id=="matches":Modifiers.burn(self,actor,enemies[at],8.0+actor.ranks[0]*2)

	if actor.id == "aladin":
		for ally in owner.actors:
			if ally.hp > 0:
				var before: float = ally.hp
				ally.hp = minf(ally.max_hp, ally.hp + ally.max_hp * 0.15 * (1.0+float(Modifiers.effects(actor).get("heal_mult",0))))
				healed += ally.hp - before
				ally.shield = minf(ally.max_hp, ally.shield + ally.max_hp * 0.15)
	if actor.id == "ariel":
		slow_left = 5.0
		for ally in owner.actors:
			if ally.hp > 0:
				ally.hp = minf(ally.max_hp, ally.hp + ally.max_hp * 0.2 * (1.0+float(Modifiers.effects(actor).get("heal_mult",0))))
				for key in ["hostile_burn","hostile_poison","hostile_dot_left"]:ally[key]=0.0
				ally["sealed"]=false
	if owner.expedition:
		Modifiers.after(self,actor,targets,per_target,true)
		Abilities.deaths(self)
		BossRules.refresh(self)
		ultimate_serial += 1
		last_ultimate = {"hero": str(actor.id), "serial": ultimate_serial}
	sync_totals()
	return {"damage": amount, "target_damage": per_target, "targets": targets, "target": target, "critical": false, "evaded": false, "message": TaleCatalog.HERO_TACTICS[actor.id].ult, "healed": healed, "ultimate": true}


func snapshot() -> Dictionary:
	var units := {}
	for actor in run().actors:
		units[actor.id] = {"row": actor.row, "energy": actor.energy}
	return {"units": units}


func restore(data: Dictionary) -> void:
	var units: Variant = data.get("units", {})
	for actor in run().actors:
		var stored: Variant = units.get(actor.id, {}) if units is Dictionary else {}
		if stored is Dictionary:
			actor.row = str(stored.get("row", actor.row))
			if run().expedition: actor.row = rank_for_class(actor["class"])
			if actor.row not in ["front", "middle", "back"]:
				actor.row = "front"
			actor.energy = 0.0 if run().expedition and actor.id=="alice" else clampf(float(stored.get("energy", 0)), 0, 100)
	ensure_front()


func intent_for(index: int) -> Dictionary:
	return BossRules.plan(self, index) if run().expedition else {}


func commit_intent(index: int) -> Dictionary:
	var intent := intent_for(index)
	if not intent.is_empty(): intent.locked = true
	return intent


func notify(id: String, title: String, detail: String, kind := "passive") -> void:
	feedback_events.append({"hero": id, "title": title, "detail": detail, "kind": kind})

func pressure() -> float:
	return 1.0 + minf(2.0, maxf(0, elapsed - 28.0) / 40.0)
