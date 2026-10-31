extends RefCounted
const Rules=preload("res://scripts/combat_rules.gd")
var round_number:=0
const Modifiers = preload("res://scripts/combat_modifiers.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const Biomes = preload("res://scripts/biomes.gd")
const EnemyBalance = preload("res://scripts/enemy_balance.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const UltRules = preload("res://scripts/ultimate_rules.gd")
const Phase1 = preload("res://scripts/phase1_enemies.gd")
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
var enemy_action_serial := 0


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
	actor.energy = 0.0 if run().expedition and actor.id=="alice" else maxf(0,float(actor.get("energy",0)))
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
	EnemyBalance.reload_if_changed()
	enemies.clear()
	feedback_events.clear()
	synergy_used.clear()
	slow_left = 0
	elapsed = 0
	damage_received = 0
	if owner.expedition and owner.active_secret.is_empty() and ExpeditionContent.is_market(owner.phase):
		sync_totals()
		return
	if not Phase1.season_for(owner).is_empty():
		enemies=Phase1.spawn(owner,EnemyBalance.profiles)
		Rules.start_combat(self)
		for at in enemies.size():enemies[at]["slot"]=at
		BossRules.setup(self)
		sync_totals()
		return
	var count: int = 1 if owner.stage == 0 and owner.wave == 0 else (2 if owner.stage < 3 else 3)
	var total: float = TaleCatalog.STAGES[owner.stage].hp * [1.0, 1.25, 2.4][owner.wave]
	if owner.expedition:
		var depth: int = owner.rooms_cleared if owner.endless else owner.stage * 6 + owner.phase
		if ExpeditionContent.is_boss(owner.stage,owner.phase):count=3
		elif not owner.endless and owner.stage==0 and owner.phase<3:count=owner.phase+1
		else:count=owner.rng.randi_range(1,ExpeditionContent.enemy_limit(owner.stage,owner.endless))
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
			variant = (0 if owner.current_boss_rule() == 3 else (3 if owner.current_boss_rule() == 7 else 5)) if boss_unit else Biomes.pick(owner.stage, owner.phase, index, owner.rng, picked)
			if not boss_unit:
				var options:Array[int]=[]
				for candidate in 6:
					if row_counts[rank_for_class(Biomes.CLASSES[candidate])]<3:options.append(candidate)
				if not options.has(variant):variant=options[owner.rng.randi_range(0,options.size()-1)]
			picked.append(variant)
			job = str(Biomes.CLASSES[variant]) if not boss_unit else ("vanguard" if owner.current_boss_rule() == 3 else "mage")
			interval = float(Biomes.INTERVALS[variant])
			row_counts[rank_for_class(job)]+=1
		enemies.append({
			"id": "enemy_%d" % index, "class": job,
			"name": owner.boss_name() if boss_unit and owner.expedition else TaleCatalog.STAGES[owner.stage].boss if boss_unit else TaleCatalog.STAGES[owner.stage].enemy,
			"row": "front" if index == 0 else "back", "hp": total * weight, "max_hp": total * weight,
			"damage": float(TaleCatalog.STAGES[owner.stage].damage) * (1.25 if boss_unit else 0.75) / sqrt(float(count)),
			"armor": 1.0 + owner.stage * 0.6 if job == "vanguard" else owner.stage * 0.22,
			"evasion": 0.0,
			"boss": boss_unit, "interval": interval, "timer": 1.8 + index * 0.5,
			"burn": 0.0, "burn_left": 0.0, "poison": 0.0, "poison_left": 0.0
		})
		if owner.expedition:
			enemies[-1]["variant"] = variant
			enemies[-1]["biome"] = owner.current_biome()
			enemies[-1].row = rank_for_class(job)
			if not boss_unit: enemies[-1].name = Biomes.ENEMIES[owner.current_biome()][variant]
			enemies[-1].hp *= float(Biomes.HP[variant]) if not boss_unit else 1.0
			enemies[-1].max_hp = enemies[-1].hp
			enemies[-1].damage = (13.0 + (owner.rooms_cleared if owner.endless else owner.stage * 6 + owner.phase) * 0.85) * (1.2 if boss_unit else 1.0) * (1.15 if owner.room_kind == "elite" else 1.0) * (float(Biomes.POWER[variant]) if not boss_unit else 1.0)
	for foe in enemies: EnemyBalance.apply(foe, owner)
	Rules.start_combat(self)
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
	if attacker.get("range","")=="medium":return front+middle if not (front+middle).is_empty() else back
	match str(attacker["class"]):
		"vanguard": return front if not front.is_empty() else (middle if not middle.is_empty() else back)
		"ranger": return back if not back.is_empty() else (middle if not middle.is_empty() else front)
		"assassin": return front+middle+back
	return front + middle + back


static func choose_target(attacker: Dictionary, defenders: Array) -> int:
	var candidates := eligible(attacker, defenders)
	var visible:Array[int]=[]
	for at in candidates:
		var hidden:bool=Rules.Gear.effects(defenders[at]).get("wolf_hide",false) and candidates.any(func(other):return other!=at and defenders[other].row==defenders[at].row)
		if not hidden:visible.append(at)
	if not visible.is_empty():candidates=visible
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


func deal(target:Dictionary,amount:float,magical:bool,certain:=false) -> Dictionary:
	return Rules.hurt(self,target,0 if magical else amount,amount if magical else 0,0,certain)

func hit_enemy(index:int,requested:=-1) -> Dictionary:
	var hit:Dictionary=Rules.attack(self,index,requested)
	if run().expedition:BossRules.refresh(self)
	return hit

func hit_party(index:=0) -> Dictionary:
	enemy_action_serial+=1
	return BossRules.execute(self,index) if run().expedition else Rules.incoming(self,index)

func phase1_impact(index:int,part:int,total:int) -> Dictionary:
	var foe:Dictionary=enemies[index]
	if part==0:
		enemy_action_serial+=1
		foe["strike_target"]=int(BossRules.plan(self,index).get("target",-1))
		foe.action_count=int(foe.get("action_count",0))+1
		foe.intent={}
	var target:int=int(foe.get("strike_target",-1))
	if foe.hp<=0 or target<0 or run().actors[target].hp<=0:return {}
	var power:float=foe.damage
	foe.damage=power/maxi(1,total)
	var result:Dictionary=Rules.incoming(self,index,target)
	foe.damage=power
	return result


func interval_for(index: int) -> float:
	var slow := 0.30 if slow_left > 0 else 0.0
	for actor in run().actors:
		if actor.id == "ariel" and actor.hp > 0:
			slow += 0.08 + actor.ranks[1] * 0.06
	return float(enemies[index].interval) * (1 + slow) * (1.15 if float(enemies[index].get("item_slow_left",0))>0 else 1.0)


func tick(delta:float) -> void:
	elapsed+=delta
	# Combat resources and conditions advance only at the beneficiary's own turn.
	if run().expedition:BossRules.refresh(self)
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


func reserve_ultimate(index:int) -> bool:
	if index<0 or index>=run().actors.size():return false
	var a:Dictionary=run().actors[index]
	if a.hp<=0 or a.get("ult_pending",false) or not Rules.ready(a):return false
	if a.id=="alice":a.card_charge-=4
	else:Rules.mana(a,-Rules.cost(a))
	a.ult_pending=true
	return true

func ultimate_ready(index:int) -> bool:
	return index>=0 and index<run().actors.size() and Rules.ready(run().actors[index])

func ultimate(index:int,requested:=-1) -> Dictionary:
	if index<0 or index>=run().actors.size() or not run().actors[index].get("ult_pending",false) or run().actors[index].hp<=0:return {}
	return Rules.ultimate(self,index,requested)


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
			actor.energy = 0.0 if run().expedition and actor.id=="alice" else maxf(0,float(stored.get("energy",0)))
	ensure_front()


func intent_for(index: int) -> Dictionary:
	return BossRules.plan(self, index) if run().expedition else {}


func commit_intent(index: int) -> Dictionary:
	var intent := intent_for(index)
	if not intent.is_empty(): intent.locked = true
	return intent


func notify(id: String, title: String, detail: String, kind := "passive") -> void:
	var hero_id:=id.trim_prefix("item_")
	var source_name:String=str(TaleCatalog.HEROES[hero_id].name) if TaleCatalog.HEROES.has(hero_id) else "Efeito de combate"
	for foe in enemies:
		if str(foe.get("id",""))==hero_id:source_name=str(foe.get("name",source_name));break
	feedback_events.append({"hero":hero_id,"source":id,"source_name":source_name,"title":title,"detail":detail,"kind":kind})

func pressure() -> float:
	return 1.0
