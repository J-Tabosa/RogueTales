class_name IdleRun
extends RefCounted
## A chapter consists of two encounters and a boss. Permanent upgrades live in Campaign.
const STAGES = TaleCatalog.STAGES
const RELICS = TaleCatalog.RELICS
var stage := 0
var wave := 0
var actors: Array[Dictionary] = []
var enemy_hp := 0.0
var enemy_max := 0.0
var kills := 0
var relics: Array[String] = []
var pending_choice := false
var offers: Array[String] = []
var burn := 0.0
var burn_left := 0.0
var poison := 0.0
var poison_left := 0.0
var rng := RandomNumberGenerator.new()


func setup(campaign: TaleCampaign, index: int) -> void:
	stage = index
	rng.randomize()
	actors.clear()
	for id in campaign.party:
		actors.append(
			TaleCatalog.hero_stats(
				id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]
			)
		)


func spawn_enemy() -> void:
	enemy_max = float(STAGES[stage].hp) * ([1.0, 1.25, 2.4][wave])
	enemy_hp = enemy_max
	burn_left = 0.0
	poison_left = 0.0
	burn = 0.0
	poison = 0.0
	for actor in actors:
		actor.shield = 0.0


func alive() -> bool:
	for actor in actors:
		if actor.hp > 0:
			return true
	return false


func enemy_interval() -> float:
	var slow := 0.0
	for actor in actors:
		if actor.id == "ariel" and actor.hp > 0:
			slow = 0.08 + actor.ranks[1] * 0.06
	return 2.5 * (1.0 + slow)


func heal_group(amount: float) -> void:
	for actor in actors:
		if actor.hp > 0:
			actor.hp = minf(actor.max_hp, actor.hp + amount)


func hit_enemy(index: int) -> Dictionary:
	if index < 0 or index >= actors.size() or actors[index].hp <= 0 or enemy_hp <= 0:
		return {}
	var actor: Dictionary = actors[index]
	actor.hits += 1
	var critical := rng.randf() < float(actor.crit)
	var amount: float = actor.damage * (2.0 if critical else 1.0)
	var message: String = ""
	match actor.id:
		"scarlet":
			burn = 2.0 + actor.ranks[1] * 2
			burn_left = 3.0
			message = "Queimadura"
		"snow_white":
			poison = 2.0 + actor.ranks[0] * 2
			poison_left = 4.0
			message = "Envenenado"
		"mulan":
			if int(actor.hits) % 3 == 0:
				amount *= 1.3 + actor.ranks[1] * 0.2
				message = "Terceiro corte"
		"rapunzel":
			if int(actor.hits) % 3 == 0:
				heal_group(3.0 + actor.ranks[0] * 3)
				message = "Trança restauradora"
		"ariel":
			if int(actor.hits) % 3 == 0:
				heal_group(3.0 + actor.ranks[0] * 4)
				message = "Canção das marés"
	enemy_hp = maxf(0.0, enemy_hp - amount)
	actor.hp = minf(actor.max_hp, actor.hp + actor.leech)
	return {"damage": amount, "critical": critical, "message": message}


func tick_status(delta: float) -> void:
	if enemy_hp <= 0:
		return
	var amount := burn * minf(delta, burn_left) + poison * minf(delta, poison_left)
	burn_left = maxf(0, burn_left - delta)
	poison_left = maxf(0, poison_left - delta)
	enemy_hp = maxf(0, enemy_hp - amount)


func hit_party() -> Dictionary:
	var weakness := 0.0
	for actor in actors:
		if actor.id == "rapunzel" and actor.hp > 0:
			weakness = actor.ranks[2] * 0.03
	for index in actors.size():
		var actor: Dictionary = actors[index]
		if actor.hp <= 0:
			continue
		var raw := maxf(
			1.0,
			(
				float(STAGES[stage].damage) * (1.4 if wave == 2 else 1.0) * (1.0 - weakness)
				- float(actor.armor)
			)
		)
		var absorbed := minf(actor.shield, raw)
		actor.shield -= absorbed
		var damage := raw - absorbed
		actor.hp = maxf(0, actor.hp - damage)
		return {"target": index, "damage": damage, "absorbed": absorbed}
	return {}


func apply_relic(id: String) -> bool:
	var valid := false
	for item in RELICS:
		if item.id == id:
			valid = true
	if not valid:
		return false
	relics.append(id)
	for actor in actors:
		match id:
			"power":
				actor.damage *= 1.2
			"heart":
				actor.max_hp += 25.0
				if actor.hp > 0:
					actor.hp = minf(actor.max_hp, actor.hp + 40.0)
			"haste":
				actor.interval = maxf(0.65, actor.interval * 0.88)
			"critical":
				actor.crit = minf(0.95, actor.crit + 0.12)
			"leech":
				actor.leech += 3
			"armor":
				actor.armor += 3
	pending_choice = false
	offers.clear()
	return true


func roll_offers() -> void:
	offers.clear()
	var candidates: Array[String] = []
	for item in RELICS:
		if not relics.has(item.id):
			candidates.append(item.id)
	while offers.size() < 3 and not candidates.is_empty():
		var index := rng.randi_range(0, candidates.size() - 1)
		offers.append(candidates[index])
		candidates.remove_at(index)


func to_checkpoint() -> Dictionary:
	var health: Array = []
	var hits: Array = []
	for actor in actors:
		health.append(float(actor.hp))
		hits.append(int(actor.hits))
	return {
		"stage": stage,
		"wave": wave,
		"health": health,
		"hits": hits,
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
		"relics": relics.duplicate(),
		"pending_choice": pending_choice,
		"offers": offers.duplicate()
	}


func restore(campaign: TaleCampaign, data: Dictionary) -> void:
	setup(campaign, int(data.stage))
	wave = clampi(int(data.get("wave", 0)), 0, 2)
	var saved_relics: Variant = data.get("relics", [])
	if saved_relics is Array:
		for id in saved_relics.slice(0, 2):
			apply_relic(str(id))
	var health: Array = data.get("health", [])
	for index in mini(health.size(), actors.size()):
		actors[index].hp = clampf(float(health[index]), 0, actors[index].max_hp)
	pending_choice = bool(data.get("pending_choice", false))
	offers.clear()
	if pending_choice:
		var saved_offers: Variant = data.get("offers", [])
		if saved_offers is Array:
			for id in saved_offers:
				for item in RELICS:
					if item.id == id and not offers.has(id):
						offers.append(id)
		if offers.size() != 3:
			roll_offers()

	# Preserve combos and the random stream at the encounter boundary.
	var counts: Variant = data.get("hits", [])
	if counts is Array:
		for index in mini(counts.size(), actors.size()):
			actors[index].hits = maxi(0, int(counts[index]))
	if data.has("rng_seed") and data.has("rng_state"):
		rng.seed = int(data.rng_seed)
		rng.state = int(data.rng_state)
