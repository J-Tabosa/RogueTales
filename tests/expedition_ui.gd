extends SceneTree
## Real scene transitions, locked artwork, responsive collection and run lifecycle.
const SAVE := "user://expedition_ui_isolated.json"
var game: Control
var screenshot_dir := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): screenshot_dir = arg.trim_prefix("--screenshots=")
	call_deferred("checks")

func capture(name: String) -> void:
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(screenshot_dir)
	root.get_texture().get_image().save_png(screenshot_dir.path_join(name + ".png"))

func descendants(node: Node) -> Array[Node]:
	var all: Array[Node] = []
	for child in node.get_children():
		all.append(child)
		all.append_array(descendants(child))
	return all

func finish_room() -> void:
	game.spawn_enemy()
	game._process(1.2)
	game.arena.set_process(false)
	for foe in game.run.tactics.enemies: foe.hp = 0
	game.run.tactics.sync_totals()
	game.resolve_enemy()
	game._process(1.3)

func checks() -> void:
	root.content_scale_size = Vector2i(540, 960)
	root.size = Vector2i(540, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.show_menu()
	await capture("run_home_mobile")
	game.show_heroes()
	assert(game.logical_width == 540)
	var cards: Array = descendants(game.page).filter(func(node): return node.has_meta("hero_id"))
	assert(cards.size() == 12)
	var black := 0
	for card in cards:
		if card.get_meta("silhouette"):
			black += 1
			var art: Sprite2D = card.get_node("Silhouette")
			assert(art.self_modulate == Color.BLACK)
			var texts: Array = descendants(card).filter(func(node): return node is Label)
			assert(not texts.any(func(node): return node.text == TaleCatalog.HEROES[card.get_meta("hero_id")].name))
	assert(black == 11)
	await capture("heroes_mobile")
	game.select_gallery_hero("alice")
	game.show_hero_details("alice")
	assert(game.state == "heroes" and is_instance_valid(game.overlay))
	assert(descendants(game.overlay).any(func(node): return node.name == "Silhouette"))
	game.show_hero_details("scarlet")
	assert(game.state == "hero_details")
	await capture("skills_mobile")
	game.use_protagonist("scarlet")
	assert(game.state == "expedition_setup" and game.campaign.party == ["scarlet"])
	await capture("run_setup_mobile")
	game.begin_expedition()
	assert(game.run.expedition and game.run.actors.size() == 1 and not game.campaign.checkpoint.is_empty())
	game.enter_encounter()
	# Exercise a reproducible solo opening; larger groups are covered separately.
	for seed_value in 100:
		var probe := RandomNumberGenerator.new()
		probe.seed = seed_value
		if probe.randi_range(1, ExpeditionContent.enemy_limit(0)) == 1:
			game.run.rng.seed = seed_value
			break
	game.spawn_enemy()
	game._process(1.2)
	game.arena.set_process(false)
	game.run.rng.seed = 901
	await capture("run_arena_mobile")
	# Exercise an actual animated fight through the real scheduler and impact callbacks.
	for tick in 3000:
		game._process(0.05)
		if is_instance_valid(game.arena): game.arena._process(0.05)
		if game.state in ["choice", "result"]: break
	assert(game.state == "choice" and game.run.stage == 0 and game.run.phase == 1)
	assert(game.run.actors[0].hits > 0)
	await capture("run_reward_mobile")
	var offers: Array = game.run.offers.duplicate()
	game.leave_battle()
	game.restore_checkpoint_now()
	assert(game.state == "choice" and game.run.offers == offers)
	var key: String = game.run.offers.filter(func(id): return not id.begins_with("ally:"))[0]
	game.select_relic(key)
	game._process(2.4)
	assert(game.state == "route" and game.run.interlude == "route")
	await capture("run_routes_mobile")
	# Walk every boundary, including all three bosses, without creating a new run.
	var number: int = game.run.run_id
	for stage in range(1, 72):
		assert(game.run.stage == stage / 6 and game.run.phase == stage % 6 and game.run.run_id == number)
		game.select_route("battle")
		assert(game.state == "travel")
		finish_room()
		if stage < 71:
			assert(game.state == "choice")
			key = game.run.offers.filter(func(id): return not id.begins_with("ally:"))[0]
			game.select_relic(key)
			game._process(2.4)
			assert(game.state == "route")
	assert(game.state == "result" and game.campaign.expedition_wins == 1 and game.campaign.checkpoint.is_empty())
	await capture("run_victory_mobile")
	# Full-width desktop collection, including silhouettes, survives viewport changes.
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	game.show_heroes()
	assert(game.logical_width == 1280 and game.page.size.x == 1280)
	await capture("heroes_pc")
	# Defeat resets the next build; guests do not become the starting party.
	game.use_protagonist("scarlet")
	game.begin_expedition()
	game.enter_encounter()
	game.spawn_enemy()
	game._process(1.2)
	for actor in game.run.actors: actor.hp = 0
	game.finish_defeat()
	game._process(1.3)
	assert(game.state == "result" and game.campaign.checkpoint.is_empty())
	game.show_settings()
	assert(game.state == "settings")
	await capture("settings_pc")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("EXPEDITION UI PASS: 11 black/unnamed locked cards, skills gating, mobile/PC collection, genuine animated fight, resume without reroll, all 12 phase transitions, final victory and defeat")
	quit()
