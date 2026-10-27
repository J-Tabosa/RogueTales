extends SceneTree
const Gear = preload("res://scripts/equipment.gd")
const Art = preload("res://scripts/item_art.gd")
var game: Control
var destination := ""
func _initialize() -> void: call_deferred("checks")
func capture(label: String) -> void:
	if destination.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := game.get_window().get_texture().get_image()
	assert(image.get_pixel(3,3) != image.get_pixel(image.get_width()/2,image.get_height()/2), "Capture must show the game window")
	image.save_png(destination.path_join(label + ".png"))
func body_rect(sprite: AnimatedSprite2D, hero: bool) -> Rect2:
	var bounds: Rect2
	if hero:
		bounds = game.arena.hero_bounds(sprite)
	else:
		bounds = Rect2(sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_image().get_used_rect())
	return Rect2(sprite.position + (bounds.position + sprite.offset) * sprite.scale, bounds.size * sprite.scale)
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	for id in Gear.ITEMS:
		assert(Art.texture(id) != null, id)
	for hero in Gear.TROPHIES:
		assert(Art.texture("trophy_" + hero) != null, hero)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://arena_equipment_layout_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.window_mode = "windowed"
	game.campaign.window_mode_selected = true
	game.apply_window_mode()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	await process_frame
	await process_frame
	for dimensions in [Vector2i(1280,800), Vector2i(540,960), Vector2i(360,800)]:
		game.get_window().content_scale_size = dimensions
		game.get_window().size = dimensions
		await process_frame
		await process_frame
		game.center_content()
		game.campaign.checkpoint.clear()
		game.run = IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"scarlet","blessing:scarlet:0"))
		game.run.party_capacity = 9
		for hero in ["rapunzel","joao","puss","mulan","maria","aladin","snow_white","alice"]:
			game.run.pending_choice = true
			game.run.offers.assign(["ally:" + hero, "heart", "power"])
			assert(game.run.recruit(game.campaign,hero))
		for id in Gear.ITEMS: game.run.grant_item(id)
		for hero in Gear.TROPHIES: game.run.grant_item("trophy_" + hero)
		game.run.interlude = "route"
		assert(game.run.equip_item(0,"star_powder",0))
		assert(game.run.equip_item(0,"blue_hourglass",1))
		game.run.interlude = ""
		game.run.stage = 2 # Nine-enemy formations become available in stage 3.
		game.enter_encounter()
		game.spawn_enemy()
		for attempt in 1000:
			game.run.spawn_enemy()
			if game.run.tactics.enemies.size() == 9: break
		assert(game.run.tactics.enemies.size() == 9)
		game.arena.sync_enemies()
		game.arena.set_process(false)
		game.feedback.set_process(false)
		game.arena.enemy_visible = true
		game.arena.entrance_left = 0
		game.arena.walking = false
		game.arena._process(.01)
		game.arena.sync_health(game.run.actors)
		game.update_hud()
		await process_frame
		var plates: Array[Rect2] = []
		var bodies: Array[Rect2] = []
		var body_depth: Array[int] = []
		for sprite in game.arena.heroes:
			bodies.append(body_rect(sprite,true))
			body_depth.append(sprite.z_index)
			assert(sprite.z_index == int(sprite.position.y))
		for sprite in game.arena.foes:
			bodies.append(body_rect(sprite,false))
			body_depth.append(sprite.z_index)
			assert(sprite.z_index == int(sprite.position.y))
		for item in game.arena.unit_widgets + game.arena.foe_widgets:
			var plate := Rect2(item.root.position, item.panel.size)
			assert(Rect2(Vector2.ZERO,game.battle_viewport.size).encloses(plate), "Plate clipped outside arena")
			for other in plates: assert(not plate.intersects(other), "Health plates overlap")

			plates.append(plate)
		# Partial sprite overlap is intentional; no target may disappear behind the rest.
		for index in bodies.size():
			var visible_samples := 0
			for x in 10:
				for y in 16:
					var point: Vector2 = bodies[index].position + bodies[index].size * Vector2((x+.5)/10.0,(y+.5)/16.0)
					var covered := false
					for other in bodies.size():
						if other != index and body_depth[other] > body_depth[index] and bodies[other].has_point(point):covered=true
					if not covered:visible_samples+=1
			assert(visible_samples >= 24,"A target was almost entirely obscured")
		assert(plates.size() == 18 and not game.log_label.visible)
		assert(not game.enemy_label.visible and not game.power_label.visible and not game.timeline.visible)
		assert(game.stage_label.text.contains("ESTÁGIO") and game.stage_label.text.contains("FASE"))
		assert(game.battle_gold.text.contains("OURO") and game.battle_gold.z_index>1600)
		assert(game.action_label.z_index>1600)
		assert(game.battle_viewport.position.y < 70)
		assert(game.arena.human_height() >= minf(184,game.arena.field_width*.175))
		assert(game.ult_buttons[0].get_children().filter(func(node):return node.has_meta("card_box")).size()==5)
		assert(not game.page.get_children().any(func(node):return node is Button and node.text in ["F11","Histórico"]))
		game.feedback.enqueue({"hero":"alice","kind":"passive","title":"Carta na manga","detail":"Avançou o naipe e ganhou 25 mana"})
		game.feedback._process(.3)
		assert(game.feedback.ribbon_face.texture != null and game.feedback.ribbon.size.y<=70)
		assert(game.feedback.ribbon.position.x==12 and not game.feedback.ribbon_detail.visible)
		assert(game.battle_viewport.size.y > (560 if game.desktop else 490))
		var slots: Array = game.ult_buttons[0].get_children().filter(func(n): return n.has_meta("card_items"))
		assert(slots.size() == 2)
		assert(slots[0].get_meta("item_picture").texture == Art.texture("star_powder"))
		assert(slots[1].get_meta("item_picture").texture == Art.texture("blue_hourglass"))
		game.current_action("Scarlet")
		await capture("nine_vs_nine_%dx%d" % [dimensions.x,dimensions.y])
		game.run.interlude = "route"
		game.show_equipment(0,1)
		assert(game.equipment_panel.selected_slot == 1 and game.equipment_panel.selected_item == "blue_hourglass")
		game.equipment_panel.select_item("enchanted_needle")
		await process_frame
		var description: Control = game.equipment_panel.find_child("DescriptionPane",true,false)
		for node in description.get_children():
			if node is TextureRect: assert(Rect2(Vector2.ZERO,description.size).encloses(node.get_rect()), "Item preview escaped its pane")
		var equip: Button = game.equipment_panel.find_child("EquipSelectedItem",true,false)
		assert(equip != null and not equip.disabled)
		equip.pressed.emit()
		assert(game.run.actors[0].equipment[1] == "enchanted_needle")
		await capture("item_description_%dx%d" % [dimensions.x,dimensions.y])
		game.equipment_panel.select_tab("appearance")
		game.equipment_panel.select_category("trophy")
		await capture("item_trophies_%dx%d" % [dimensions.x,dimensions.y])
		game.close_equipment()
		await process_frame
	game.campaign.checkpoint.clear()
	game.show_map()
	assert(game.page.get_children().any(func(n): return n is Button and n.get_children().any(func(c): return c is Label and c.text == "Selecionar Personagem")))
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = "user://arena_equipment_layout_isolated.json" + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ARENA EQUIPMENT LAYOUT PASS: 39 icon assets, 18 separate plates, larger partially overlapping sprites with visible targets and depth order, compact HUD and portrait abilities, responsive arena, two equipped slots, selected-slot equip, appearance/description and trophy filters")
	quit()
