extends SceneTree
const Flow = preload("res://scripts/battle_flow.gd")
const SAVE := "user://flow_isolated.json"
func _initialize() -> void: call_deferred("checks")
func make_run(ids: Array) -> IdleRun:
	var campaign := TaleCampaign.new()
	campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	campaign.party.assign(ids)
	var run := IdleRun.new()
	run.setup(campaign,8)
	run.enable_tactics(campaign)
	run.spawn_enemy()
	return run
func checks() -> void:
	var run := make_run(["peter","alice","puss"])
	var flow := Flow.new()
	flow.bind(run)
	assert(flow.order[0].side == "ally" and flow.order[0].index == 0, "Fastest initiative acts first")
	var actions := 0
	while flow.round_number == 1:
		var entry := flow.next_action()
		if entry.is_empty(): continue
		flow.begin(entry)
		assert(flow.next_action().is_empty(), "An active action excludes every other actor")
		actions += 1
		flow.complete()
	assert(actions == 9, "Three heroes get two AP; three ordinary enemies get one AP")
	assert(run.actors[0].ap == 2 and run.actors[0].pp == 1)
	# Reactions consume PP, cannot chain recursively and reset only with the round.
	run = make_run(["puss"])
	flow = Flow.new()
	flow.bind(run)
	run.actors[0].evasion = 0
	var first := run.hit_party(0)
	var second := run.hit_party(0)
	assert(first.guarded and not second.guarded and first.damage < second.damage)
	assert(run.actors[0].pp == 0)
	run = make_run(["peter"])
	flow = Flow.new()
	flow.bind(run)
	run.actors[0].evasion = 1
	first = run.hit_party(0)
	second = run.hit_party(0)
	assert(first.evaded and first.counter > 0 and second.evaded and not second.has("counter"))
	run = make_run(["alice"])
	flow = Flow.new()
	flow.bind(run)
	for foe in run.tactics.enemies: foe.evasion = 0
	first = run.hit_enemy(0)
	second = run.hit_enemy(0)
	assert(first.focused and not second.has("focused") and run.actors[0].pp == 0)
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.party.assign(["puss","alice","peter"])
	game.campaign.auto_ult = false
	game.begin_chapter_combat(0)
	game.spawn_enemy()
	game.arena.set_process(false)
	for foe in game.run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.damage = 1
	game.run.tactics.sync_totals()
	assert(game.arena.begin_enemy_attack(0,0))
	game.combat_flow.begin({"side":"enemy","index":0})
	assert(not game.arena.attack(0,0), "No overlapping ally attack during an enemy action")
	game.run.actors[1].energy = 100
	assert(game.try_ultimate(1) and not game.try_ultimate(1))
	assert(game.run.actors[1].ult_queued and game.run.actors[1].energy == 100)
	game.toggle_pause()
	var clock: float = game.arena.enemy_track.time
	game.arena._process(0.2)
	game._process(0.2)
	assert(game.arena.enemy_track.time == clock)
	game.resume_battle()
	var bursts: Array[int] = [0]
	game.arena.attack_started.connect(func(index):
		if index == 1 and game.arena.tracks[1].ultimate: bursts[0] += 1)
	for step in 100:
		game._process(0.05)
		game.arena._process(0.05)
		var concurrent := 1 if game.arena.enemy_track.time >= 0 else 0
		for track in game.arena.tracks:
			if track.time >= 0: concurrent += 1
		assert(concurrent <= 1)
	assert(bursts[0] == 1 and not game.run.actors[1].ult_queued)
	assert(game.run.actors[1].energy < 100)
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SAVE + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("BATTLE FLOW PASS: initiative, AP rounds, limited guard/counter/focus reactions, serial animation impacts, pause and one queued manual ULT")
	quit()
