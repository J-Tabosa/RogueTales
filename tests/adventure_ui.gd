extends SceneTree
const SAVE := "user://adventure_ui_isolated.json"
var game: Control
var captures := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): captures = arg.trim_prefix("--screenshots=")
	call_deferred("checks")

func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(captures)
	root.get_texture().get_image().save_png(captures.path_join(name + ".png"))

func prepare(ids: Array, stage: int, depth: int, infinite := false) -> void:
	game.campaign.checkpoint.clear()
	game.run = IdleRun.new()
	assert(game.run.start_expedition(game.campaign, ids[0], "vigor", infinite))
	for id in ids.slice(1):
		game.run.pending_choice = true
		game.run.offers.assign(["ally:" + id, "power", "heart"])
		assert(game.run.recruit(game.campaign, id))
	game.run.stage = stage
	game.run.phase = 5 if ExpeditionContent.is_boss(stage) else 0
	game.run.wave = 2 if ExpeditionContent.is_boss(stage) else 0
	game.run.rooms_cleared = depth
	game.run.interlude = ""
	game.persist_run()
	game.enter_encounter()
	game.spawn_enemy()
	game._process(1.2)
	game.arena.set_process(false)

func checks() -> void:
	root.content_scale_size = Vector2i(540, 960)
	root.size = Vector2i(540, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.set_run_mode(true)
	assert(not game.chosen_endless and game.state == "expedition_setup")
	game.campaign.expedition_wins = 1
	await capture("mode_mobile")
	prepare(["scarlet", "matches", "puss"], 3, 3)
	assert(game.arena.foe_widgets.size() == 3 and not game.arena.foe_widgets[0].has("intent"))
	for foe in game.run.tactics.enemies:
		foe.hp = 20000
		foe.max_hp = 20000
		foe.evasion = 0
		foe.armor = 0
		foe.pp = 0
	var fire: Dictionary = game.run.hit_enemy(1)
	var combo: Dictionary = game.run.hit_enemy(0, fire.target)
	assert(combo.synergies == ["powder"])
	game.arena.present_result(combo, false, 0)
	game.update_hud()
	await capture("synergy_mobile")
	game.show_enemy_intents(0)
	assert(game.paused and game.arena.frozen)
	var clock: float = game.arena.clock
	game._process(0.2)
	game.arena._process(0.2)
	assert(game.arena.clock == clock)
	await capture("general_intent_mobile")
	game.resume_battle()
	assert(not game.paused and not game.arena.frozen)
	prepare(["scarlet", "rapunzel"], 7, 7)
	game.run.actors[0].energy = 100
	assert(game.run.tactics.reserve_ultimate(0))
	game.run.tactics.ultimate(0)
	game.update_hud()
	assert(game.run.tactics.intent_for(0).key == "copy")
	await capture("index_mobile")
	prepare(["scarlet", "mulan", "alice"], 11, 11)
	assert(game.run.actors[0].sealed and game.run.actors[1].sealed)
	await capture("weaver_mobile")
	# The same UI continues into floor 13, with 3 stronger enemies and its build intact.
	prepare(["scarlet"], 11, 71, true)
	game.run.actors[0].hp = 93
	for foe in game.run.tactics.enemies: foe.hp = 0
	game.run.tactics.sync_totals()
	game.resolve_enemy()
	game._process(1.3)
	assert(game.state == "choice" and game.run.rooms_cleared == 72 and game.run.stage == 0)
	assert(game.run.actors[0].hp >= 93 and game.campaign.expedition_wins == 1)
	await capture("endless_reward_mobile")
	var key: String = game.run.offers.filter(func(id): return not id.begins_with("ally:"))[0]
	game.select_relic(key)
	game._process(2.4)
	game.select_route("battle")
	game.spawn_enemy()
	game._process(1.2)
	game.arena.set_process(false)
	assert(game.run.tactics.enemies.size() == 3 and game.run.enemy_max > 76)
	assert(game.enemy_label.text.contains("INFINITO"))
	await capture("endless_13_mobile")
	# An actual event choice resumes the run; reloading before selection preserves it.
	prepare(["scarlet", "matches"], 1, 1, true)
	game.run.interlude = "event"
	game.run.pending_event = "powder_shop"
	game.persist_run()
	game.show_team_event()
	assert(game.state == "team_event")
	await capture("team_event_mobile")
	game.leave_battle()
	game.restore_checkpoint_now()
	assert(game.state == "team_event" and game.run.pending_event == "powder_shop")
	game.select_team_event("pair")
	assert(game.state == "travel" and game.run.events_discovered == ["powder_shop"])
	assert(game.run.actors[0].mutations.has("spread") and game.run.actors[1].mutations.has("fuel"))
	game.run.interlude = "route"
	game.run.route_offers.assign(["battle"])
	game.show_run_build()
	await capture("synergy_build_mobile")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	prepare(["scarlet", "mulan", "alice"], 11, 23, true)
	await capture("weaver_pc")
	game.show_enemy_intents(0)
	await capture("intent_pc")
	game.resume_battle()
	game.show_journal()
	game.show_profile()
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("ADVENTURE UI PASS: earned endless gating, synergy toast, history/pause, copy and threads, endless floor 13, persistent party event choices, synergy build and PC layout")
	quit()
