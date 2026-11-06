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
func click(control:Control) -> void:
	var point:=control.get_global_transform_with_canvas()*(control.size*.5)
	var move:=InputEventMouseMotion.new()
	move.position=point
	move.global_position=point
	game.get_viewport().push_input(move,true)
	for down in [true,false]:
		if game.get_window().size.x<600:
			var finger:=InputEventScreenTouch.new()
			finger.index=0
			finger.position=point
			finger.pressed=down
			game.get_viewport().push_input(finger,true)
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.device=InputEvent.DEVICE_ID_EMULATION if game.get_window().size.x<600 else 0
		event.position=point
		event.global_position=point
		event.pressed=down
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
		game.get_viewport().push_input(event,true)
	await settle()
func verify(node: Node) -> void:
	if node is Label or node is Button:
		check(node.get_theme_color("font_color") == TaleTheme.text_color(node), "Text follows active theme: " + str(node.get_path()))
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
		for fill in ["background", "surface", "surface_top", "card", "card_top", "well", "button", "button_top", "primary", "primary_top", "hover", "pressed"]:
			check(contrast(TaleTheme.c("text"), TaleTheme.c(fill)) >= 4.5, mode + " text contrast on " + fill)
		var health=preload("res://scripts/health_display.gd")
		for i in 5:
			check(health.tint({"hp":90-i*20,"max_hp":100})==Color(["67cf85","c5e85a","f2d36b","f5a052","ff6969"][i]),"Original five health colors in "+mode)
		for i in 7:check(TaleTheme.rarity(i)==Color(["858b94","50b86a","5097ee","ac6bef","ef9c39","ee5555","e6cb79"][i]),"Original rarity color in "+mode)
		check(TaleTheme.c("physical")==Color("ff6969") and TaleTheme.c("magical")==Color("64c7ff"),"Damage colors survive the theme")
		for key in ["corner_filigrane","horizontal_border","section_divider","mandala_watermark","surface_texture","panel_frame"]:
			check(TaleTheme.asset(key)!=null and TaleTheme.asset(key).get_meta("theme_colorized",false),"Generated PNG ornament loaded: "+mode+"/"+key)
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
					var toggle := game.page.find_child("ThemeToggle", true, false) as CheckButton
					check(toggle != null and not toggle.disabled and toggle.button_pressed==(mode=="light"), "Settings exposes a synchronized native switch")
					await click(toggle)
					await settle()
					check(game.campaign.ui_theme != mode, "Settings button activates theme switch")
					await click(toggle)
					await settle()
					var saved := TaleCampaign.new()
					check(saved.load_from(game.save_path) and saved.ui_theme == mode, "Button choice persists to disk")
					toggle.grab_focus()
					for trial in 2:
						for down in [true,false]:
							var key:=InputEventKey.new()
							key.keycode=KEY_SPACE
							key.pressed=down
							game.get_viewport().push_input(key,true)
						await settle()
						check(toggle.button_pressed==(game.campaign.ui_theme=="light"),"Keyboard keeps switch synchronized")
					check(game.campaign.ui_theme==mode,"Keyboard toggles twice without resetting preferences")
			game.run = IdleRun.new()
			check(game.run.start_expedition(game.campaign, "alice", "vigor"), "Start test run")
			var gear=preload("res://scripts/equipment.gd")
			for rank in 6:
				for id in gear.ITEMS:
					if int(gear.ITEMS[id].rarity)==rank and not gear.ITEMS[id].get("consumable",false):
						game.run.inventory.append(id)
						break
			game.run.interlude="route"
			check(game.run.equip_item(0,game.run.inventory[1],0),"Equip colored item for real HUD")
			game.run.interlude=""
			game.run.actors[0].hp=game.run.actors[0].max_hp*.5
			game.run.actors[0].shield=18
			game.run.actors[0].energy=40
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
			check(game.card_health[0].target_color==Color("f2d36b"),"Manager HP targets yellow at half life; its outline remains black")
			check(game.ult_meters[0].target_color==Color("8ab4f0"),"Real combat resource bar remains blue")
			verify(game.page)
			game.arena.damage_number("17",Vector2(350,200),Color("ffb5b4"))
			await settle()
			var damage:Label=game.arena.numbers.back().node
			check(damage.get_theme_color("font_color")==Color("ffb5b4"),"Combat damage keeps its authored color")
			game.show_character_information(0)
			await capture("%s-inspector-%d" % [mode, extent.x])
			verify(game.overlay)
			var sheet: Control = game.overlay
			var summary:=sheet.find_child("AbilitySummary",true,false) as RichTextLabel
			check(summary.text.contains("#ff6969") and summary.text.contains("#64c7ff"),"Physical/magical damage remain red/blue in real ability text")
			var hp: float = game.run.actors[0].hp
			var scene_art: Texture2D = game.arena.backdrop.texture
			var hero_extent: Vector2 = game.arena.heroes[0].scale
			var state: String = game.state
			var nodes_before := game.get_child_count()
			game.toggle_ui_theme()
			await settle()
			verify(sheet)
			check(summary.text.contains("#ff6969") and summary.text.contains("#64c7ff"),"Switch does not rewrite semantic BBCode colors")
			check(damage.get_theme_color("font_color")==Color("ffb5b4"),"Switch does not flatten damage feedback")
			check(game.card_health[0].target_color==Color("f2d36b"),"Switch does not recolor a live HP bar")
			check(game.overlay == sheet and game.state == state and game.get_child_count() == nodes_before, "Live switch preserves existing screen and controls")
			check(game.arena.backdrop.texture == scene_art and game.arena.heroes[0].scale == hero_extent, "Art and character scale survive theme change")
			check(game.run.actors[0].hp == hp, "Switch does not simulate or restart combat")
			game.toggle_ui_theme()
			game.close_character_information()
			game.run.interlude = "route"
			game.show_equipment(0)
			await capture("%s-equipment-%d" % [mode, extent.x])
			verify(game.equipment_panel)
			for tile in game.equipment_panel.find_children("*","Button",true,false):
				if tile.has_meta("inventory_item"):
					var id:String=tile.get_meta("inventory_item")
					check(tile.get_theme_stylebox("normal").get_meta("rarity_color")==gear.tint(id),"Inventory border keeps the actual item rarity")
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
