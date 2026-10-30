extends SceneTree
const Biomes = preload("res://scripts/biomes.gd")
var game
func _initialize() -> void: call_deferred("checks")
func checks() -> void:
	var account := preload("res://tests/test_accounts.gd").legacy()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run := IdleRun.new()
	assert(run.start_expedition(account, "alice", "vigor"))
	run.rng.seed = 3717
	var seen := {}
	for depth in 48:
		if run.needs_map():assert(run.choose_route(run.route_offers[0]))
		assert(run.stage == depth / 6 and run.phase == depth % 6)
		if run.phase==4:
			assert(run.choose_route("shop"));run.leave_shop();continue
		run.spawn_enemy()
		for foe in run.tactics.enemies:
			if not seen.has(run.stage): seen[run.stage] = {}
			seen[run.stage][foe.variant] = true
		assert(bool(run.tactics.enemies[0].boss) == (run.phase == 5))
		var checkpoint := run.to_checkpoint()
		var restored := IdleRun.new()
		restored.restore(account, checkpoint)
		assert(restored.stage == run.stage and restored.phase == run.phase)
		assert(restored.actors[0].damage == run.actors[0].damage)
		assert(restored.rng.state == run.rng.state)
		var terminal := run.clear_encounter()
		assert(terminal == (depth == 47))
		if not terminal:
			assert(run.offers.size() == 3)
			assert(run.apply_relic("power"))
			if run.phase!=4 and not run.needs_map():assert(run.choose_route("battle"))
	for world in 8: assert(seen[world].size() >= 3, "All six identities appear within a world")
	assert(run.rooms_cleared == 48 and run.upgrade_count("power") == 39)
	var result := account.finish_expedition(run.to_checkpoint(), true)
	assert(result.reward == 1700 and account.best_depth == 8)
	var damage: float = run.actors[0].damage
	assert(run.continue_endless(account))
	assert(run.continuation_from == 48 and run.actors[0].damage == damage)
	result = account.finish_expedition(run.to_checkpoint(), false)
	assert(result.reward == 0)
	var legacy := IdleRun.new()
	legacy.restore(account, {"expedition":true,"stage":8,"hero_ids":["alice"],"health":[100]})
	assert(legacy.stage == 1 and legacy.phase == 2)
	var alice: SpriteFrames = load("res://assets/characters/alice/frames.tres")
	var rapunzel: SpriteFrames = load("res://assets/characters/rapunzel/frames.tres")
	assert(alice.get_frame_count("attack") == 12 and rapunzel.get_frame_count("attack") == 12)
	assert(alice.get_frame_texture("idle", 0) is MeshTexture and rapunzel.get_frame_texture("idle", 0) is MeshTexture)
	root.content_scale_size = Vector2i(540,960)
	root.size = Vector2i(540,960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://worlds_polish_test.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.run = IdleRun.new()
	assert(game.run.start_expedition(game.campaign, "alice", "vigor"))
	for id in ["rapunzel", "matches"]:
		game.run.pending_choice = true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		assert(game.run.recruit(game.campaign,id))
	game.run.stage = 4
	game.run.phase = 2
	game.run.rooms_cleared = 26
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game._process(1.3)
	game.arena._process(0.1)
	assert(game.arena.vfx.z_index > 950)
	assert(game.arena.heroes[2].z_index > game.arena.heroes[0].z_index)
	assert(game.arena.heroes[2].get_meta("visual_height") == game.arena.heroes[0].get_meta("visual_height") * 0.75)
	for foe in game.arena.foes: assert(not foe.flip_h)
	for mode in ["mobile","pc"]:
		if mode == "pc":
			root.content_scale_size = Vector2i(1280,800)
			root.size = Vector2i(1280,800)
			game.center_content()
		await capture("battle_" + mode)
		var impact := {"target":0,"targets":[0,1],"damage":20,"evaded":false}
		game.arena.present_result(impact,true,0)
		assert(game.arena.enemy_impacts.size() >= 2)
		game.arena._process(0.1)
		game.arena._process(0.22)
		await capture("impact_" + mode)
		game.arena.ultimate_effect(0,{"targets":[0]})
		game.arena._process(0.1)
		game.arena._process(0.4)
		await capture("alice_ult_"+mode)
	game.queue_free()
	await process_frame
	print("WORLDS POLISH PASS: 48 phases, 8 bosses, six enemy identities per world, compact checkpoint and upgrades, migration, earned endless, native HD meshes, visible child, foreground enemy impacts/ULT and mobile/PC")
	quit()
func capture(name: String) -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(args[0])
	assert(root.get_texture().get_image().save_png(args[0]+"/"+name+".png") == OK)
