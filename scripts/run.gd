class_name IdleRun
extends RefCounted
## A chapter consists of two encounters and a boss. Permanent upgrades live in Campaign.
const Tactics = preload("res://scripts/tactics.gd")
var tactics
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
var run_id := 0
var drafted: Array[String] = []
var unlock_stats: Dictionary = {"healing": 0.0, "combos": 0}


func setup(campaign: TaleCampaign, index: int, fresh: bool = true) -> void:
	stage = index
	run_id = campaign.new_run_id() if fresh else 0
	wave = 0
	drafted.clear()
	relics.clear()
	offers.clear()
	pending_choice = false
	unlock_stats = {"healing": 0.0, "combos": 0}
	rng.randomize()
	actors.clear()
	for id in campaign.party:
		actors.append(
			TaleCatalog.hero_stats(
				id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]
			)
		)


func spawn_enemy() -> void:
	if tactics != null:
		tactics.spawn()
		return
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


func heal_group(amount: float) -> float:
	var restored := 0.0
	for actor in actors:
		if actor.hp > 0:
			var before: float = actor.hp
			actor.hp = minf(actor.max_hp, actor.hp + amount)
			restored += actor.hp - before
	return restored


func hit_enemy(index: int, target: int = -1) -> Dictionary:
	if tactics != null:
		return tactics.hit_enemy(index, target)
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
				unlock_stats.combos += 1
				amount *= 1.3 + actor.ranks[1] * 0.2
				message = "Terceiro corte"
		"rapunzel":
			if int(actor.hits) % 3 == 0:
				unlock_stats.healing += heal_group(3.0 + actor.ranks[0] * 3)
				message = "Trança restauradora"
		"ariel":
			if int(actor.hits) % 3 == 0:
				heal_group(3.0 + actor.ranks[0] * 4)
				message = "Canção das marés"
	enemy_hp = maxf(0.0, enemy_hp - amount)
	actor.hp = minf(actor.max_hp, actor.hp + actor.leech)
	return {"damage": amount, "critical": critical, "message": message}


func tick_status(delta: float) -> void:
	if tactics != null:
		tactics.tick(delta)
		return
	if enemy_hp <= 0:
		return
	var amount := burn * minf(delta, burn_left) + poison * minf(delta, poison_left)
	burn_left = maxf(0, burn_left - delta)
	poison_left = maxf(0, poison_left - delta)
	enemy_hp = maxf(0, enemy_hp - amount)


func hit_party(enemy_index: int = 0) -> Dictionary:
	if tactics != null:
		return tactics.hit_party(enemy_index)
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
		apply_relic_to_actor(actor, id)
	pending_choice = false
	offers.clear()
	return true


func apply_relic_to_actor(actor: Dictionary, id: String) -> void:
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


func roll_offers(campaign: TaleCampaign) -> void:
	offers.clear()
	var guests: Array[String] = []
	for id in TaleCatalog.UNLOCKS:
		if not actor_ids().has(id) and not drafted.has(id):
			guests.append(id)
	if not guests.is_empty():
		# The first invitation teaches recruitment with Snow White; later offers vary.
		var invited := guests[rng.randi_range(0, guests.size() - 1)]
		if campaign.total_wins == 0 and drafted.is_empty() and guests.has("snow_white"):
			invited = "snow_white"
		offers.append("ally:" + invited)
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
		"tactics": tactics.snapshot() if tactics != null else {},
		"run_id": run_id,
		"hero_ids": actor_ids(),
		"drafted": drafted.duplicate(),
		"unlock_stats": unlock_stats.duplicate(true),
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
	setup(campaign, int(data.stage), false)
	run_id = int(data.get("run_id", 0))
	if run_id <= 0:
		run_id = campaign.new_run_id()
	var saved_ids: Variant = data.get("hero_ids", campaign.party)
	actors.clear()
	for id in saved_ids:
		actors.append(
			TaleCatalog.hero_stats(
				id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]
			)
		)
	var saved_drafted: Variant = data.get("drafted", [])
	if saved_drafted is Array:
		for id in saved_drafted:
			if TaleCatalog.UNLOCKS.has(id) and not drafted.has(id):
				drafted.append(id)
	var metrics: Variant = data.get("unlock_stats", {})
	if metrics is Dictionary:
		unlock_stats.healing = maxf(0, float(metrics.get("healing", 0)))
		unlock_stats.combos = maxi(0, int(metrics.get("combos", 0)))
		var new_hits: Variant = metrics.get("new_hits", {})
		unlock_stats["new_hits"] = {}
		if new_hits is Dictionary:
			for id in TaleCatalog.NEW_HERO_IDS:
				unlock_stats.new_hits[id] = clampi(int(new_hits.get(id, 0)), 0, 20)
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
				if not TaleCatalog.offer_data(str(id)).is_empty() and not offers.has(id):
					offers.append(id)
		if offers.size() != 3:
			roll_offers(campaign)

	# Preserve combos and the random stream at the encounter boundary.
	var counts: Variant = data.get("hits", [])
	if counts is Array:
		for index in mini(counts.size(), actors.size()):
			actors[index].hits = maxi(0, int(counts[index]))
	if data.has("rng_seed") and data.has("rng_state"):
		rng.seed = int(data.rng_seed)
		rng.state = int(data.rng_state)

	if data.get("tactics") is Dictionary and not data.tactics.is_empty():
		enable_tactics(campaign)
		tactics.restore(data.tactics)


func actor_ids() -> Array[String]:
	var ids: Array[String] = []
	for actor in actors:
		ids.append(actor.id)
	return ids


func recruit(campaign: TaleCampaign, id: String, replace_index: int = -1) -> bool:
	if not pending_choice or not offers.has("ally:" + id) or not TaleCatalog.UNLOCKS.has(id):
		return false
	if actor_ids().has(id) or drafted.has(id):
		return false
	if actors.size() >= 3 and (replace_index < 0 or replace_index >= actors.size()):
		return false
	var actor := TaleCatalog.hero_stats(
		id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]
	)
	for relic in relics:
		apply_relic_to_actor(actor, relic)
	if actors.size() < 3:
		actors.append(actor)
	else:
		actors[replace_index] = actor
	if tactics != null:
		tactics.configure_actor(actor, campaign.row_for(id))
		tactics.ensure_front()
	drafted.append(id)
	pending_choice = false
	offers.clear()
	return true


func enable_tactics(campaign: TaleCampaign) -> void:
	if tactics == null:
		tactics = Tactics.new()
		tactics.bind(self, campaign)
