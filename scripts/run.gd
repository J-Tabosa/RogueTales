class_name IdleRun
extends RefCounted
## A chapter consists of two encounters and a boss. Permanent upgrades live in Campaign.
const Tactics = preload("res://scripts/tactics.gd")
const Endless = preload("res://scripts/endless_rules.gd")
var tactics
const STAGES = TaleCatalog.STAGES
const RELICS = TaleCatalog.RELICS
var stage := 0
var phase := 0
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
var expedition := false
var run_gold := 0
var blessing := "vigor"
var leader := "scarlet"
var interlude := ""
var route_offers: Array[String] = []
var room_kind := "battle"
var shop_stock: Array[String] = []
var shop_bought: Array[String] = []
var rooms_cleared := 0
var mercy_used := false
var curse_count := 0
var elite_bonuses := 0
var build_history: Array[String] = []
var synergies_seen: Array[String] = []
var synergy_activations := 0
var pending_event := ""
var seen_events: Array[String] = []
var events_discovered: Array[String] = []
var endless := false
var continuation_from := 0
var score := 0
var last_room_score := 0
var upgrade_counts: Dictionary = {}
var team_template: Dictionary = Endless.template()


func setup(campaign: TaleCampaign, index: int, fresh: bool = true) -> void:
	expedition = false
	endless = false
	score = 0
	last_room_score = 0
	continuation_from = 0
	tactics = null
	stage = index
	phase = 0
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
	if expedition:
		return apply_run_upgrade(id)
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
	if id.begins_with("skill:"):
		var parts := id.split(":")
		if parts.size() == 3 and parts[1] == actor.id and not actor.get("mutations", []).has(parts[2]):
			if not actor.has("mutations"): actor["mutations"] = []
			actor.mutations.append(parts[2])
		return
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
	if expedition:
		roll_run_offers()
		return
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
		"expedition": expedition, "world_format": 2, "phase": phase,
		"run_gold": run_gold, "blessing": blessing, "leader": leader,
		"interlude": interlude, "route_offers": route_offers.duplicate(),
		"room_kind": room_kind, "rooms_cleared": rooms_cleared,
		"shop_stock": shop_stock.duplicate(), "shop_bought": shop_bought.duplicate(),
		"mercy_used": mercy_used, "curse_count": curse_count, "elite_bonuses": elite_bonuses,
		"build_history": build_history.duplicate(),
		"synergies_seen": synergies_seen.duplicate(), "synergy_activations": synergy_activations,
		"pending_event": pending_event, "seen_events": seen_events.duplicate(), "events_discovered": events_discovered.duplicate(),
		"score": score, "last_room_score": last_room_score,
		"endless": endless, "continuation_from": continuation_from, "endless_build": Endless.snapshot(self) if endless else {}, "run_build": Endless.snapshot(self) if expedition else {},
		"ability_state": ability_snapshot(),
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
	expedition = bool(data.get("expedition", false))
	score = maxi(0, int(data.get("score", 0)))
	last_room_score = maxi(0, int(data.get("last_room_score", 0)))
	endless = expedition and bool(data.get("endless", false))
	continuation_from = maxi(0, int(data.get("continuation_from", 0))) if endless else 0
	if expedition:
		var location := ExpeditionContent.location(data)
		stage = location.x
		phase = location.y
	if expedition:
		run_gold = clampi(int(data.get("run_gold", 0)), 0, 2147483647 if endless else 99999)
		blessing = str(data.get("blessing", "vigor"))
		if not ExpeditionContent.BLESSINGS.has(blessing): blessing = "vigor"
		leader = str(data.get("leader", "scarlet"))
		interlude = str(data.get("interlude", ""))
		if interlude not in ["", "reward", "route", "shop", "event"]: interlude = ""
		pending_event = str(data.get("pending_event", ""))
		if not preload("res://scripts/team_events.gd").EVENTS.has(pending_event): pending_event = ""
		seen_events.clear()
		events_discovered.clear()
		for key in data.get("seen_events", []):
			if preload("res://scripts/team_events.gd").EVENTS.has(key) and not seen_events.has(key): seen_events.append(key)
		for key in data.get("events_discovered", []):
			if preload("res://scripts/team_events.gd").EVENTS.has(key) and not events_discovered.has(key): events_discovered.append(key)
		room_kind = "elite" if data.get("room_kind") == "elite" else "battle"
		rooms_cleared = clampi(int(data.get("rooms_cleared", 0)), 0, 2147483647 if endless else 72)
		mercy_used = bool(data.get("mercy_used", false))
		curse_count = clampi(int(data.get("curse_count", 0)), 0, 2147483647 if endless else 72)
		elite_bonuses = clampi(int(data.get("elite_bonuses", 0)), 0, 2147483647 if endless else 72)
		build_history.clear()
		synergies_seen.clear()
		for key in data.get("synergies_seen", []):
			if preload("res://scripts/team_synergies.gd").PAIRS.has(key) and not synergies_seen.has(key): synergies_seen.append(key)
		synergy_activations = maxi(0, int(data.get("synergy_activations", 0)))
		for key in data.get("build_history", []):
			if build_history.size() >= 64: break
			if key in ["event:curse", "event:elite"] or not TaleCatalog.offer_data(str(key)).is_empty(): build_history.append(str(key))
		route_offers.clear()
		for key in data.get("route_offers", []):
			if ExpeditionContent.ROUTES.has(key) and not route_offers.has(key): route_offers.append(key)
		shop_stock.clear()
		for key in data.get("shop_stock", []):
			if key == "potion" or not TaleCatalog.offer_data(str(key)).is_empty(): shop_stock.append(key)
		shop_bought.clear()
		for key in data.get("shop_bought", []):
			if shop_stock.has(key) and not shop_bought.has(key): shop_bought.append(key)
	run_id = int(data.get("run_id", 0))
	if run_id <= 0:
		run_id = campaign.new_run_id()
	var saved_ids: Variant = data.get("hero_ids", campaign.party)
	actors.clear()
	for id in saved_ids:
		actors.append(run_actor(id) if expedition else TaleCatalog.hero_stats(id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]))
	var saved_drafted: Variant = data.get("drafted", [])
	if saved_drafted is Array:
		for id in saved_drafted:
			if (TaleCatalog.HEROES.has(id) if expedition else TaleCatalog.UNLOCKS.has(id)) and not drafted.has(id):
				drafted.append(id)
	var metrics: Variant = data.get("unlock_stats", {})
	if metrics is Dictionary:
		unlock_stats.healing = maxf(0, float(metrics.get("healing", 0)))
		unlock_stats.combos = maxi(0, int(metrics.get("combos", 0)))
		if expedition:
			unlock_stats["boss_guests"] = metrics.get("boss_guests", {}).duplicate(true) if metrics.get("boss_guests", {}) is Dictionary else {}
		var new_hits: Variant = metrics.get("new_hits", {})
		unlock_stats["new_hits"] = {}
		if new_hits is Dictionary:
			for id in TaleCatalog.NEW_HERO_IDS:
				unlock_stats.new_hits[id] = clampi(int(new_hits.get(id, 0)), 0, 20)
	wave = clampi(int(data.get("wave", 0)), 0, 2)
	var saved_relics: Variant = data.get("relics", [])
	if saved_relics is Array:
		for id in saved_relics.slice(0, (42 if endless else 32) if expedition else 2):
			if expedition:
				if not TaleCatalog.offer_data(str(id)).is_empty():
					relics.append(str(id))
			else:
				apply_relic(str(id))
	if expedition:
		if data.has("run_build") or endless:
			Endless.restore(self, data.get("run_build", data.get("endless_build", {})))
		else:
			for event in build_history:
				for actor in actors: apply_build_event(actor, event)
			Endless.promote(self)
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
	if expedition:
		var states: Variant = data.get("ability_state", {})
		for actor in actors:
			var saved: Variant = states.get(actor.id, {}) if states is Dictionary else {}
			if saved is Dictionary:
				for key in ["shadows", "suit", "wish", "charged", "nine_used", "spirit_flames"]:
					if saved.has(key): actor[key] = saved[key]

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
	if not pending_choice or not offers.has("ally:" + id) or not (TaleCatalog.HEROES.has(id) if expedition else TaleCatalog.UNLOCKS.has(id)):
		return false
	if actor_ids().has(id) or drafted.has(id):
		return false
	if actors.size() >= 3 and (replace_index < 0 or replace_index >= actors.size()):
		return false
	var actor := run_actor(id) if expedition else TaleCatalog.hero_stats(id, campaign.levels[id], campaign.choices, campaign.hero_levels[id])
	if expedition:
		Endless.apply_template(self, actor)
	else:
		for relic in relics: apply_relic_to_actor(actor, relic)
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
	if expedition: interlude = "route"
	return true


func enable_tactics(campaign: TaleCampaign) -> void:
	if tactics == null:
		tactics = Tactics.new()
		tactics.bind(self, campaign)


func start_expedition(campaign: TaleCampaign, id: String, gift: String, infinite := false) -> bool:
	if (infinite and campaign.expedition_wins == 0) or not campaign.checkpoint.is_empty() or not campaign.unlocked.has(id) or not campaign.blessings_unlocked.has(gift):
		return false
	setup(campaign, 0)
	expedition = true
	endless = infinite
	upgrade_counts.clear()
	team_template = Endless.template()
	leader = id
	blessing = gift
	run_gold = 35
	rooms_cleared = 0
	interlude = ""
	room_kind = "battle"
	route_offers.clear()
	shop_stock.clear()
	shop_bought.clear()
	mercy_used = false
	curse_count = 0
	elite_bonuses = 0
	build_history.clear()
	synergies_seen.clear()
	synergy_activations = 0
	pending_event = ""
	seen_events.clear()
	events_discovered.clear()
	actors.clear()
	actors.append(run_actor(id))
	unlock_stats["boss_guests"] = {}
	enable_tactics(campaign)
	return true


func run_actor(id: String) -> Dictionary:
	var actor := TaleCatalog.hero_stats(id, [0, 0, 0], {}, 1)
	actor["mutations"] = []
	actor["shadows"] = 0
	actor["suit"] = 0
	actor["wish"] = 0
	actor["charged"] = false
	actor["nine_used"] = false
	if blessing == "vigor": actor.max_hp *= 1.25
	if blessing == "fury": actor.damage *= 1.18
	if blessing == "echo":
		actor.energy = 40.0
		actor.energy_bonus = 3.0
	actor.hp = actor.max_hp
	return actor


func ability_snapshot() -> Dictionary:
	var saved := {}
	for actor in actors:
		var entry := {}
		for key in ["shadows", "suit", "wish", "charged", "nine_used", "spirit_flames"]:
			if actor.has(key): entry[key] = actor[key]
		saved[actor.id] = entry
	return saved


func apply_run_upgrade(id: String) -> bool:
	if not Endless.add_upgrade(self, id): return false
	pending_choice = false
	offers.clear()
	interlude = "route"
	return true


func roll_run_offers() -> void:
	offers.clear()
	var guests: Array[String] = []
	for id in TaleCatalog.HEROES:
		if not actor_ids().has(id) and not drafted.has(id): guests.append(id)
	# One Bernoulli draw for the whole screen, never one draw per card.
	if not guests.is_empty() and rng.randf() < ExpeditionContent.RECRUIT_CHANCE:
		offers.append("ally:" + guests[rng.randi_range(0, guests.size() - 1)])
	var candidates: Array[String] = []
	for actor in actors:
		if actor.hp <= 0: continue
		for entry in ExpeditionContent.MUTATIONS[actor.id]:
			var key: String = "skill:%s:%s" % [actor.id, entry[0]]
			if upgrade_count(key) == 0: candidates.append(key)
	# Guarantee a meaningful skill option while there are unchosen mutations.
	if not candidates.is_empty():
		var slot := rng.randi_range(0, candidates.size() - 1)
		offers.append(candidates[slot])
		candidates.remove_at(slot)
	for item in RELICS:
		if true:
			if item.id == "critical" and actors.all(func(actor): return actor.hp <= 0 or actor.crit >= 0.949): continue
			if item.id == "haste" and actors.all(func(actor): return actor.hp <= 0 or actor.interval <= 0.651): continue
			candidates.append(item.id)
	while offers.size() < 3 and not candidates.is_empty():
		var slot := rng.randi_range(0, candidates.size() - 1)
		offers.append(candidates[slot])
		candidates.remove_at(slot)
	# At most 11 rewards + 3 shop items; the generic pool cannot run out.
	interlude = "reward"
	pending_choice = true


func clear_encounter() -> bool:
	if not expedition: return false
	last_room_score = 100 + (300 if ExpeditionContent.is_boss(stage, phase) else 0) + (150 if room_kind == "elite" else 0)
	if tactics != null:
		last_room_score += maxi(0, 120 - int(tactics.elapsed * 2))
		if tactics.damage_received <= 0: last_room_score += 100
	last_room_score += actors.filter(func(actor): return actor.hp > 0).size() * 25
	score += last_room_score
	rooms_cleared += 1
	kills += 1
	run_gold += 16 + stage * 3 + (25 if room_kind == "elite" else 0)
	if room_kind == "elite":
		elite_bonuses += 1
		Endless.event(self, "elite")
	if ExpeditionContent.is_boss(stage, phase):
		for id in drafted:
			var slot := actor_ids().find(id)
			if slot >= 0 and actors[slot].hp > 0:
				if not unlock_stats.boss_guests.has(id): unlock_stats.boss_guests[id] = []
				if not unlock_stats.boss_guests[id].has(stage): unlock_stats.boss_guests[id].append(stage)
	if stage == 11 and phase == 5 and not endless: return true
	phase += 1
	if phase >= 6:
		phase = 0
		stage = (stage + 1) % 12
		seen_events.clear()
		restore_party(0.12)
	wave = 2 if ExpeditionContent.is_boss(stage, phase) else 0
	room_kind = "battle"
	roll_run_offers()
	roll_routes()
	return false


func roll_routes() -> void:
	route_offers.assign(["battle"])
	if ExpeditionContent.is_boss(stage, phase): return
	var choices := ["elite", "camp", "shop", "spring", "curse", "cache"]
	if not preload("res://scripts/team_events.gd").available(self).is_empty(): choices.append("team_event")
	if run_gold < 18: choices.erase("camp")
	route_offers.append(str(choices[rng.randi_range(0, choices.size() - 1)]))
	shop_stock.assign(["potion"])
	shop_bought.clear()
	var stock: Array[String] = []
	for relic in RELICS:
		stock.append(relic.id)
	while shop_stock.size() < 3 and not stock.is_empty():
		var slot := rng.randi_range(0, stock.size() - 1)
		shop_stock.append(stock[slot])
		stock.remove_at(slot)


func choose_route(id: String) -> bool:
	if interlude != "route" or not route_offers.has(id): return false
	if id == "camp" and run_gold < 18: return false
	if id == "team_event":
		var events: Array = preload("res://scripts/team_events.gd").available(self)
		if events.is_empty(): return false
		pending_event = events[rng.randi_range(0, events.size() - 1)]
		interlude = "event"
		return true
	if id == "shop":
		interlude = "shop"
		return true
	if id in ["elite", "cache"]: room_kind = "elite"
	if id == "camp":
		run_gold -= 18
		restore_party(0.30, true)
	elif id == "spring":
		run_gold = maxi(0, run_gold - 12)
		restore_party(0.20)
	elif id == "cache": run_gold += 35
	elif id == "curse":
		curse_count += 1
		Endless.event(self, "curse")
	route_offers.clear()
	interlude = ""
	return true


func restore_party(fraction: float, revive := false) -> void:
	var raised := false
	for actor in actors:
		if actor.hp > 0:
			actor.hp = minf(actor.max_hp, actor.hp + actor.max_hp * fraction)
		elif revive and not raised:
			actor.hp = actor.max_hp * 0.20
			raised = true


func buy_supply(id: String) -> bool:
	var cost := 22 if id == "potion" else 32
	if interlude != "shop" or not shop_stock.has(id) or shop_bought.has(id) or run_gold < cost:
		return false
	if id == "potion": restore_party(0.35, true)
	else:
		if not Endless.add_upgrade(self, id): return false
	run_gold -= cost
	shop_bought.append(id)
	return true


func leave_shop() -> void:
	if interlude == "shop":
		interlude = ""
		route_offers.clear()


func apply_build_event(actor: Dictionary, event: String) -> void:
	if event == "event:curse":
		actor.damage *= 1.18
		actor.max_hp *= 0.9
		actor.hp = minf(actor.hp, actor.max_hp)
	elif event == "event:elite": actor.damage *= 1.1
	else: apply_relic_to_actor(actor, event)


func upgrade_count(id: String) -> int:
	return int(upgrade_counts.get(id, 0))


func upgrade_total() -> int:
	var count := 0
	for value in upgrade_counts.values(): count += int(value)
	return count


func phase_label() -> String:
	return "FASE %03d · INFINITO" % (rooms_cleared + 1) if endless else "MUNDO %02d / 12 · FASE %d / 6" % [stage + 1, phase + 1]


func upgrade_detail(id: String) -> String:
	var item := TaleCatalog.offer_data(id)
	if item.is_empty(): return ""
	var count := upgrade_count(id)
	match id:
		"power": return "+%.1f%% de dano ao grupo nesta escolha. Ganhos decrescentes por acúmulo." % (20.0 / (1 + count * 0.08))
		"armor": return "+%.2f de armadura ao grupo nesta escolha. Ganhos decrescentes por acúmulo." % (3.0 / (1 + count * 0.12))
		"leech": return "Cada acerto passa a curar mais %.2f PV. Ganhos decrescentes por acúmulo." % (3.0 / (1 + count * 0.08))
		"critical": return "+%.1f%% de chance crítica, até 95%%. Ganhos decrescentes por acúmulo." % (12.0 / (1 + count * 0.1))
	return item.detail


func continue_endless(campaign: TaleCampaign) -> bool:
	if not expedition or endless or rooms_cleared != 72 or stage != 11 or phase != 5 or not alive() or campaign.expedition_wins <= 0 or not campaign.checkpoint.is_empty(): return false
	# Normal victory has already been settled. The continuation gets a distinct id.
	run_id = campaign.new_run_id()
	continuation_from = 72
	unlock_stats = {"healing": 0.0, "combos": 0, "boss_guests": {}}
	endless = true
	phase = 0
	stage = 0
	wave = 0
	seen_events.clear()
	roll_run_offers()
	return true
