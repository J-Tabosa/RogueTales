extends SceneTree
var game: Control
var destination := ""
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("test")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func contrast(a: Color, b: Color) -> float:
	return (maxf(a.srgb_to_linear().get_luminance(), b.srgb_to_linear().get_luminance()) + .05) / (minf(a.srgb_to_linear().get_luminance(), b.srgb_to_linear().get_luminance()) + .05)
func settle() -> void:
	for i in 3: await process_frame
func capture(key: String) -> void:
	await settle()
	if destination.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(key + ".png"))
func verify(node: Node) -> void:
	if node is Label or node is Button:
		check(node.get_theme_color("font_color") == TaleTheme.c(str(node.get_meta("theme_text_role", "text"))), "Text follows active theme: " + str(node.get_path()))
	if node is Button:
		check(node.get_theme_stylebox("normal").get_meta("theme_generation", -1) == TaleTheme.generation, "Button uses native themed style")
	for child in node.get_children(): verify(child)

func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var c := TaleCampaign.new()
	c.load_data({"ui_theme": "invalid"})
	check(c.ui_theme == "dark", "Old and invalid preferences default to dark")
	c.ui_theme = "light"
	var restored := TaleCampaign.new()
	restored.load_data(c.to_dict())
	check(restored.ui_theme == "light", "Theme preference survives save serialization")
	for mode in ["dark", "light"]:
		TaleTheme.set_mode(mode)
		for fill in ["background", "surface", "surface_top", "button", "hover", "pressed"]:
			check(contrast(TaleTheme.c("text"), TaleTheme.c(fill)) >= 4.5, mode + " text contrast on " + fill)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://ui_themes_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode = "windowed"
	game.campaign.window_mode_selected = true
	game.apply_window_mode()
	for extent in [Vector2i(1280, 800), Vector2i(360, 640)]:
		game.get_window().size = extent
		game.get_window().content_scale_size = extent
		await settle()
		for mode in ["dark", "light"]:
			game.campaign.ui_theme = mode
			game.ui_theme.switch_to(mode)
			for screen in ["menu", "map", "heroes", "settings", "daily", "achievements"]:
				if screen in ["daily", "achievements"]: game.show_goals(screen)
				else: game.call("show_" + screen)
				await capture("%s-%s-%d" % [mode, screen, extent.x])
				verify(game.page)
				if screen == "settings":
					var toggle := game.page.find_child("ThemeToggle", true, false) as Button
					check(toggle != null and not toggle.disabled, "Settings exposes theme switch")
					toggle.pressed.emit()
					await settle()
					check(game.campaign.ui_theme != mode, "Settings button activates theme switch")
					toggle.pressed.emit()
					await settle()
					var saved := TaleCampaign.new()
					check(saved.load_from(game.save_path) and saved.ui_theme == mode, "Button choice persists to disk")
			game.run = IdleRun.new()
			check(game.run.start_expedition(game.campaign, "alice", "vigor"), "Start test run")
			game.run.spawn_enemy()
			game.build_battle()
			game.arena.sync_enemies()
			game.arena.enemy_visible = true
			game.arena.set_process(false)
			game.feedback.set_process(false)
			game.arena.entrance_left = 0
			game.arena.intro_left = 0
			game.arena.frozen = true
			game.arena.fit_field(game.battle_viewport.size)
			game.arena._process(0)
			game.update_hud()
			check(not game.arena.atmosphere.weather.has_node("ThemeSurface"), "Weather never receives an opaque UI surface")
			await capture("%s-battle-%d" % [mode, extent.x])
			verify(game.page)
			game.show_character_information(0)
			await capture("%s-inspector-%d" % [mode, extent.x])
			verify(game.overlay)
			var sheet: Control = game.overlay
			var hp: float = game.run.actors[0].hp
			var scene_art: Texture2D = game.arena.backdrop.texture
			var hero_extent: Vector2 = game.arena.heroes[0].scale
			var state: String = game.state
			var nodes_before := game.get_child_count()
			game.toggle_ui_theme()
			await settle()
			verify(sheet)
			check(game.overlay == sheet and game.state == state and game.get_child_count() == nodes_before, "Live switch preserves existing screen and controls")
			check(game.arena.backdrop.texture == scene_art and game.arena.heroes[0].scale == hero_extent, "Art and character scale survive theme change")
			check(game.run.actors[0].hp == hp, "Switch does not simulate or restart combat")
			game.toggle_ui_theme()
			game.close_character_information()
			game.run.interlude = "route"
			game.show_equipment(0)
			await capture("%s-equipment-%d" % [mode, extent.x])
			verify(game.equipment_panel)
			game.close_equipment()
			game.state = "battle"
			game.paused = false
			game.toggle_pause()
			await settle()
			check(game.overlay.find_child("ThemeToggle", true, false) != null, "Pause exposes theme switch")
			game.resume_battle()
			game.run = null
			game.campaign.checkpoint.clear()
	game.show_loading(Callable(), 0)
	await capture("loading")
	verify(game.page)
	game.queue_free()
	await process_frame
	print("UI THEMES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
