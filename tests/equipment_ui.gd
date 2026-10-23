extends SceneTree
const Gear = preload("res://scripts/equipment.gd")
var game: Control
const SAVE = "user://equipment_ui_isolated.json"
func _initialize() -> void: call_deferred("checks")
func descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func checks() -> void:
	root.content_scale_size = Vector2i(540, 960)
	root.size = Vector2i(540, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.run = IdleRun.new()
	assert(game.run.start_expedition(game.campaign, "scarlet", "blessing:scarlet:0"))
	game.run.party_capacity = 9
	for hero in ["rapunzel", "joao", "puss", "mulan", "maria", "peter", "snow_white", "alice"]:
		game.run.pending_choice = true
		game.run.offers.assign(["ally:" + hero, "power", "heart"])
		assert(game.run.recruit(game.campaign, hero))
	for id in Gear.ITEMS: assert(game.run.grant_item(id))
	for hero in Gear.TROPHIES: assert(game.run.grant_item("trophy_" + hero))
	for dimensions in [Vector2i(540, 960), Vector2i(1280, 800)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await process_frame
		game.center_content()
		game.enter_encounter()
		game.spawn_enemy()
		game.arena.set_process(false)
		game.feedback.set_process(false)
		assert(game.ult_buttons.size() == 9)
		assert(game.hero_deck.custom_minimum_size.y > 492 if game.desktop else game.hero_deck.custom_minimum_size.x > 508)
		for card in game.ult_buttons:
			assert(card.get_children().filter(func(child): return child.has_meta("card_items")).size() == 2)
		game.run.interlude = "route"
		game.run.route_offers.assign(["battle"])
		game.show_routes()
		game.show_equipment(8)
		assert(game.paused and game.equipment_panel.hero_index == 8)
		game.equip_from_panel(8, "tower_braid", 0)
		assert(game.run.actors[8].equipment[0] == "tower_braid")
		assert(game.campaign.checkpoint.equipment_state.alice.items[0] == "tower_braid")
		game.equipment_panel.select_tab("appearance")
		var scroll: ScrollContainer = game.equipment_panel.find_child("InventoryScroll", true, false)
		assert(scroll != null)
		await process_frame
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.pressed = true
		touch.position = scroll.get_global_transform_with_canvas() * Vector2(30, 80)
		scroll._input(touch)
		assert(scroll.finger == 0)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = touch.position - Vector2(0, 80)
		scroll._input(drag)
		assert(scroll.dragging and scroll.scroll_vertical > 0)
		touch.pressed = false
		scroll._input(touch)
		game.close_equipment()
		assert(game.paused)
		await process_frame
		game.run.interlude = ""
		game.state = "battle"
		game.paused = false
		game.show_equipment()
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = KEY_SPACE
		game._input(event)
		assert(game.paused and is_instance_valid(game.equipment_panel))
		event.keycode = KEY_ESCAPE
		game._input(event)
		assert(not game.paused and game.equipment_panel == null)
		await process_frame
		game.run.pending_choice = true
		game.run.offers.assign(["ally:ariel", "power", "heart"])
		game.show_recruit_replacement("ally:ariel")
		var replacement: ScrollContainer = game.overlay.find_child("RecruitReplacementScroll", true, false)
		assert(replacement != null)
		var buttons := descendants(replacement).filter(func(child): return child is Button)
		assert(buttons.size() == 9 and buttons.filter(func(button): return not button.disabled).size() == 3)
		game.run.interlude = "shop"
		game.run.shop_stock.assign(["item:echo_bell"])
		game.run.run_gold = 200
		game.show_run_shop()
		assert(descendants(game.page).any(func(child): return child.get_meta("shop_item", "") == "capacity"))
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("EQUIPMENT UI PASS: mobile/PC 9-hero deck, item panel and save, scaled touch scrolling, pause/escape, valid replacements and merchant capacity")
	quit()
