extends RefCounted
## Formation rules and all combat results; contains no nodes or rendering logic.
## The weak owner avoids a Run -> Tactics -> Run reference cycle.
var owner_ref: WeakRef
var enemies: Array[Dictionary] = []
var slow_left := 0.0
var last_dot_targets: Array[int] = []
var elapsed := 0.0


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
	actor.row = row
	actor.evasion = TaleCatalog.CLASSES[profile["class"]].evasion
	actor.energy = clampf(float(actor.get("energy", 0.0)), 0, 100)
	actor["ult_pending"] = false


func ensure_front() -> void:
	for actor in run().actors:
		if actor.row == "front":
			return
	if not run().actors.is_empty():
		run().actors[0].row = "front"


func spawn() -> void:
	var owner = run()
	enemies.clear()
	slow_left = 0
	var count: int = 1 if owner.stage == 0 and owner.wave == 0 else (2 if owner.stage < 3 else 3)
	var total: float = TaleCatalog.STAGES[owner.stage].hp * [1.0, 1.25, 2.4][owner.wave]
	var roles: Array = ["vanguard", "ranger", "mage"]
	if owner.stage % 4 == 2:
		roles[1] = "assassin"
	elif owner.stage % 4 == 1:
		roles[2] = "assassin"
	for index in count:
		var boss_unit: bool = owner.wave == 2 and index == 0
		var weight := (0.6 if index == 0 else 0.4 / maxf(1, count - 1)) if owner.wave == 2 and count > 1 else 1.0 / count
		var job: String = "mage" if boss_unit and owner.stage % 2 == 1 else str(roles[index])
		var interval := 3.1 + index * 0.35
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
	for actor in owner.actors:
		actor.ult_pending = false
		actor.shield = 0.0
	sync_totals()


static func eligible(attacker: Dictionary, defenders: Array) -> Array[int]:
	var front: Array[int] = []
	var back: Array[int] = []
	for index in defenders.size():
		if float(defenders[index].hp) <= 0:
			continue
		if defenders[index].row == "front":
			front.append(index)
		else:
			back.append(index)
	match str(attacker["class"]):
		"vanguard":
			return front if not front.is_empty() else back
		"ranger", "assassin":
			return back if not back.is_empty() else front
	return front + back


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
	var raw := maxf(1, amount - float(target.armor) * (0.35 if magical else 1.0))
	var absorbed := minf(float(target.get("shield", 0.0)), raw)
	if target.has("shield"):
		target.shield -= absorbed
	var actual := minf(float(target.hp), raw - absorbed)
	target.hp = maxf(0, target.hp - actual)
	return {"damage": actual, "evaded": false, "absorbed": absorbed}


func hit_enemy(index: int, requested := -1) -> Dictionary:
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
	var hit := deal(enemies[target], amount, actor["class"] in ["mage", "artificer"])
	hit.merge({"target": target, "critical": critical, "message": "Esquiva" if hit.evaded else "", "targets": [target]})
	actor.energy = minf(100, actor.energy + (8.0 if hit.evaded else 18.0))
	if not hit.evaded:
		actor.hits += 1
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
		actor.hp = minf(actor.max_hp, actor.hp + actor.leech)
	sync_totals()
	return hit


func hit_party(enemy_index := 0) -> Dictionary:
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
	var hit := deal(actor, float(enemy.damage) * (1.0 - weakness), enemy["class"] == "mage")
	actor.energy = minf(100, actor.energy + hit.damage / actor.max_hp * 80.0)
	hit["target"] = target
	hit["enemy"] = enemy_index
	return hit


func interval_for(index: int) -> float:
	var slow := 0.30 if slow_left > 0 else 0.0
	for actor in run().actors:
		if actor.id == "ariel" and actor.hp > 0:
			slow += 0.08 + actor.ranks[1] * 0.06
	return float(enemies[index].interval) * (1 + slow)


func tick(delta: float) -> void:
	elapsed += delta
	slow_left = maxf(0, slow_left - delta)
	last_dot_targets.clear()
	for index in enemies.size():
		var enemy: Dictionary = enemies[index]
		if enemy.hp <= 0:
			continue
		var damage: float = enemy.burn * minf(delta, enemy.burn_left) + enemy.poison * minf(delta, enemy.poison_left)
		enemy.burn_left = maxf(0, enemy.burn_left - delta)
		enemy.poison_left = maxf(0, enemy.poison_left - delta)
		enemy.hp = maxf(0, enemy.hp - damage)
		if damage > 0:
			last_dot_targets.append(index)
	for actor in run().actors:
		if actor.hp > 0 and not actor.ult_pending:
			actor.energy = minf(100, actor.energy + delta * 3.0)
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
	if actor.hp <= 0 or actor.energy < 100 or actor.ult_pending or target_for(index) < 0:
		return false
	actor.energy = 0.0
	actor.ult_pending = true
	return true


func ultimate(index: int, requested := -1) -> Dictionary:
	var owner = run()
	if index < 0 or index >= owner.actors.size():
		return {}
	var actor: Dictionary = owner.actors[index]
	if not actor.ult_pending or actor.hp <= 0:
		return {}
	actor.ult_pending = false
	var target := target_for(index)
	if eligible(actor, enemies).has(requested):
		target = requested
	if target < 0:
		return {}
	var targets: Array[int] = []
	var amount := 0.0
	var healed := 0.0
	match str(actor.id):
		"scarlet", "ariel":
			for at in enemies.size():
				if enemies[at].hp > 0:
					targets.append(at)
		"mulan":
			targets = eligible({"class": "vanguard"}, enemies)
			actor.shield += actor.max_hp * 0.35
		"snow_white":
			targets.append(target)
		"rapunzel":
			for ally in owner.actors:
				if ally.hp > 0:
					var before: float = ally.hp
					ally.hp = minf(ally.max_hp, ally.hp + ally.max_hp * 0.35)
					healed += ally.hp - before
					ally.shield += ally.max_hp * 0.20
			owner.unlock_stats.healing += healed
	for at in targets:
		var multiplier: float = {"scarlet": 2.0, "snow_white": 4.0, "mulan": 3.2, "ariel": 1.6}.get(actor.id, 1.0)
		amount += deal(enemies[at], actor.damage * multiplier, actor.id in ["scarlet", "ariel"], true).damage
		if actor.id == "scarlet":
			enemies[at].burn = 6.0 + actor.ranks[1] * 2
			enemies[at].burn_left = 4.0
		elif actor.id == "snow_white":
			enemies[at].poison = 8.0 + actor.ranks[0] * 2
			enemies[at].poison_left = 6.0
	if actor.id == "ariel":
		slow_left = 5.0
		for ally in owner.actors:
			if ally.hp > 0:
				ally.hp = minf(ally.max_hp, ally.hp + ally.max_hp * 0.2)
	sync_totals()
	return {"damage": amount, "targets": targets, "target": target, "critical": false, "evaded": false, "message": TaleCatalog.HERO_TACTICS[actor.id].ult, "healed": healed, "ultimate": true}


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
			if actor.row not in ["front", "back"]:
				actor.row = "front"
			actor.energy = clampf(float(stored.get("energy", 0)), 0, 100)
	ensure_front()
