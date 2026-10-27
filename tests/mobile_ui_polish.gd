extends SceneTree
## Reproduces the uploaded portrait screenshots and checks the usable text areas.
var game: Control
var destination: String
func _initialize() -> void:call_deferred("checks")
func descendants(node: Node) -> Array[Node]:
	var result:Array[Node]=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func capture(file: String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(file+".png"))
func fits(label: Label, rect: Rect2) -> void:
	assert(rect.encloses(label.get_rect()),label.text+" escaped its frame")
	var font:=label.get_theme_font("font")
	var point_size:=label.get_theme_font_size("font_size")
	assert(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x<=label.size.x,label.text+" exceeds its label width")
	assert(font.get_height(point_size)<=label.size.y,label.text+" exceeds its label height")
func touch(at: Vector2, pressed: bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.window_id=game.get_window().get_window_id()
	event.index=0
	event.position=at
	event.pressed=pressed
	Input.parse_input_event(event)
	await process_frame
func check_gallery_touch() -> void:
	var gallery:ScrollContainer=game.gallery_scroll
	gallery.scroll_horizontal=0
	await process_frame
	var previous:String=game.selected_hero
	var point:=gallery.get_global_rect().get_center()
	await touch(point,true)
	var drag:=InputEventScreenDrag.new()
	drag.window_id=game.get_window().get_window_id()
	drag.index=0
	drag.position=point-Vector2(100,0)
	drag.relative=Vector2(-100,0)
	Input.parse_input_event(drag)
	await process_frame
	await touch(drag.position,false)
	assert(gallery.scroll_horizontal>40 and game.selected_hero==previous,"Swiping must not select a card")
	gallery.scroll_horizontal=0
	await process_frame
	var second:Control=gallery.get_child(0).get_child(1)
	var visible:=second.get_global_rect().intersection(gallery.get_global_rect())
	assert(visible.has_area())
	await touch(visible.get_center(),true)
	await touch(visible.get_center(),false)
	assert(game.selected_hero=="rapunzel","A tap must select the visible second card")
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://mobile_ui_polish_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	for dimensions in [Vector2i(1280,800),Vector2i(540,960),Vector2i(360,800)]:
		game.get_window().content_scale_size=dimensions
		game.get_window().size=dimensions
		await process_frame
		await process_frame
		var suffix:="_%dx%d"%[dimensions.x,dimensions.y]
		game.campaign.checkpoint.clear()
		game.selected_hero="scarlet"
		game.show_heroes()
		await process_frame
		var nodes:=descendants(game.page)
		for node in game.page.get_children():
			if node is Button:assert(Rect2(Vector2.ZERO,game.page.size).encloses(node.get_rect()),"Gallery action clipped outside the screen")
		assert(not nodes.any(func(node):return node is Button and node.text.contains("Animações")))
		var scarlet:Control=nodes.filter(func(node):return node.get_meta("hero_id","")=="scarlet")[0]
		assert(scarlet.get_node("HeroArt").get_meta("visual_height")>290)
		await capture("selection"+suffix)
		await check_gallery_touch()
		game.show_map()
		await process_frame
		nodes=descendants(game.page)
		var locks:=nodes.filter(func(node):return node.get_meta("locked",false))
		assert(locks.size()==3)
		for card in locks:
			var texts:=descendants(card).filter(func(node):return node is Label)
			assert(texts.size()==1 and texts[0].text.contains("Desbloqueia"))
			var blessing:Dictionary=game.Blessings.data(card.get_meta("blessing_id"))
			assert(not texts[0].text.contains(blessing.title) and not texts[0].text.contains(blessing.detail))
		var list:Control=game.page.get_node("BlessingList")
		var start:Button=nodes.filter(func(node):return node is Button and node.text.begins_with("Iniciar expedição"))[0]
		assert(list.position.y+list.size.y<start.position.y-60,"Blessings overlap the footer")
		var chosen:Button=nodes.filter(func(node):return node is Button and node.get_meta("primary",false))[0]
		assert(chosen.get_theme_stylebox("normal").bg_color.g>chosen.get_theme_stylebox("normal").bg_color.r)
		await capture("locked_blessings"+suffix)
		game.choose_blessing("blessing:scarlet:2")
		assert(not descendants(game.overlay).any(func(node):return node is Label and node.text.contains("reverberam")),"Locked modal leaks the effect")
		game.show_map()
		game.run=IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"scarlet","blessing:scarlet:0"))
		game.run.run_gold=1234567
		game.run.interlude="shop"
		game.run.shop_stock.assign(["potion","item:echo_bell","item:black_apple","item:stone_heart","item:blue_hourglass","armor"])
		game.show_run_shop()
		await process_frame
		nodes=descendants(game.page)
		assert(nodes.any(func(node):return node.get_meta("effect_badge","")=="magic"))
		assert(nodes.any(func(node):return node is TextureRect and node.texture==game.ItemArt.texture("echo_bell")))
		var shop:Control=game.page.get_node("ShopList")
		var bag:Button=nodes.filter(func(node):return node is Button and node.text.begins_with("Equipar itens"))[0]
		assert(shop.position.y+shop.size.y<bag.position.y,"Shop overlaps the bag button")
		await capture("shop"+suffix)
		var before:int=game.run.run_gold
		game.show_supply_details("item:echo_bell")
		assert(game.run.run_gold==before,"Viewing effects must not buy the item")
		assert(descendants(game.overlay).any(func(node):return node is Label and node.text.contains("60%")))
		game.show_run_shop()
		game.buy_run_supply("item:echo_bell")
		assert(game.run.inventory.has("echo_bell") and game.run.run_gold==before-170)
		game.run.interlude=""
		game.enter_encounter()
		game.spawn_enemy()
		game.arena.set_process(false)
		game.arena.entrance_left=0
		game.arena.walking=false
		game.arena._process(.01)
		game.arena.sync_health(game.run.actors)
		game.update_hud()
		await process_frame
		var gold:Control=game.page.get_node("BattleGoldBox")
		fits(game.battle_gold,Rect2(gold.position+Vector2(8,3),gold.size-Vector2(16,6)))
		var frame:Control=game.page.get_node("BattleHeader")
		for stage in 12:
			game.run.stage=stage
			game.run.endless=true
			game.run.rooms_cleared=999999
			game.update_hud()
			fits(game.stage_label,Rect2(frame.position+Vector2(12,6),frame.size-Vector2(24,12)))
		game.run.stage=0
		game.run.endless=false
		game.update_hud()
		game.current_action("Scarlet")
		await capture("combat"+suffix)
	game.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		var path:String="user://mobile_ui_polish_isolated.json"+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MOBILE UI POLISH PASS: large static collection with touch swipe/tap, hidden locked effects, dark green selection, icon shop with inspect/buy, nonoverlapping footers and fitted gold/world labels at three resolutions")
	quit()
