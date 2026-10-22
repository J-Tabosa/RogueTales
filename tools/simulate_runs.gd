extends SceneTree
## Deterministic balance probe: level-one leaders, no permanent bonuses, no forced allies.
const Flow = preload("res://scripts/battle_flow.gd")

func _initialize() -> void: call_deferred("simulate")

func score(run: IdleRun, key: String) -> float:
	if key.begins_with("ally:"): return 120.0 if run.actors.size() < 3 else 0.0
	var life := 1.0
	for actor in run.actors:
		if actor.hp > 0: life = minf(life, actor.hp / actor.max_hp)
	if key == "heart": return 115.0 if life < 0.6 else 25.0
	if key == "leech": return 99.0 - run.relics.count(key) * 22
	if key == "armor": return 94.0 - run.relics.count(key) * 18
	if key == "power": return 75.0
	if key == "critical": return 40.0
	if key == "haste": return 20.0
	if key.ends_with(":shelter") or key.ends_with(":quick"): return 105.0
	if key.ends_with(":barrier") or key.ends_with(":overflow") or key.ends_with(":nine"): return 90.0
	return 65.0

func combat(run: IdleRun) -> void:
	run.spawn_enemy()
	var flow := Flow.new()
	flow.bind(run)
	for action in 1800:
		if not run.alive() or run.enemy_hp <= 0: break
		var entry: Dictionary = flow.next_action()
		if entry.is_empty(): continue
		flow.begin(entry)
		if entry.side == "ally":
			if run.actors[entry.index].energy >= 100:
				run.tactics.reserve_ultimate(entry.index)
				run.tactics.ultimate(entry.index)
			else: run.hit_enemy(entry.index)
		else: run.hit_party(entry.index)
		flow.complete()
		# Approximate action animation/recovery time; this is not a rendered gameplay test.
		for step in 12:
			run.tick_status(0.10)
			if not run.alive() or run.enemy_hp <= 0: break

func simulate() -> void:
	for id in TaleCatalog.HEROES:
		var depths: Array[int] = []
		var wins := 0
		var solo_wins := 0
		for seed_value in 20:
			var account := TaleCampaign.new()
			account.unlocked.assign(TaleCatalog.HEROES.keys())
			var run := IdleRun.new()
			run.start_expedition(account, id, "vigor")
			run.rng.seed = seed_value + 128
			for phase in 12:
				combat(run)
				if not run.alive() or run.enemy_hp > 0: break
				if run.clear_encounter():
					wins += 1
					if run.drafted.is_empty(): solo_wins += 1
					break
				var selected: String = run.offers[0]
				for key in run.offers:
					if score(run, key) > score(run, selected): selected = key
				if selected.begins_with("ally:"):
					run.recruit(account, selected.trim_prefix("ally:"))
				else: run.apply_relic(selected)
				if run.route_offers.has("camp") and run.run_gold >= 18: run.choose_route("camp")
				elif run.route_offers.has("spring"): run.choose_route("spring")
				else: run.choose_route("battle")
			depths.append(run.rooms_cleared)
		var sum_depth := 0
		for depth in depths: sum_depth += depth
		print(id, ": wins=", wins, "/20, solo_wins=", solo_wins, ", mean_depth=", sum_depth / 20.0)
	quit()
