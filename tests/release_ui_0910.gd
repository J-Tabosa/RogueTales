extends "res://tests/rules_095.gd"
var game
var destination:=""
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func send_event(event:InputEvent) -> void:
	game.get_viewport().push_input(event,true)
func mouse_at(point:Vector2,pressed:bool,emulated:=false) -> void:
	var event:=InputEventMouseButton.new()
	event.position=point;event.global_position=point
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.device=InputEvent.DEVICE_ID_EMULATION if emulated else 0
	send_event(event)
func touch_at(point:Vector2,pressed:bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.position=point;event.index=0;event.pressed=pressed
	send_event(event)
func click(control:Control,local:Vector2,touch:=false) -> void:
	var point:=control.get_global_transform_with_canvas()*local
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
	send_event(motion)
	if touch:touch_at(point,true)
	mouse_at(point,true,touch)
	if touch:touch_at(point,false)
	mouse_at(point,false,touch)
	await process_frame
func descendants(node:Node) -> Array[Node]:
	var out:Array[Node]=[]
	for child in node.get_children():out.append(child);out.append_array(descendants(child))
	return out
func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://release_ui_0910_isolated.json"
	root.add_child(game);game.set_process(false)
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true;game.apply_window_mode()
	await process_frame;await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent
		await process_frame;game.center_content()
		game.campaign=TaleCampaign.new();game.selected_hero="alice";game.run=null
		game.show_map()
		check(game.state=="heroes" and game.campaign.unlocked.is_empty(),"Fresh account routes to purchase collection without empty-party crash")
		await capture("locked-collection-%d"%extent.x)
		game.show_unlock_details("alice");await process_frame
		var buy:Button=game.overlay.find_child("PurchaseHero",true,false)
		check(not buy.disabled,"Welcome balance can purchase first hero")
		await click(buy,buy.size*.5,extent.x==540)
		check(game.campaign.unlocked==["alice"] and game.campaign.gold==0,"Actual purchase click charges exact5000 once")
		game.buy_character("alice")
		check(game.campaign.gold==0 and game.campaign.unlocked.size()==1,"Repeat click cannot charge/unlock twice")
		game.use_protagonist("alice")
		await capture("purchased-setup-%d"%extent.x)
		# Real negative-item DOT notifications, controller, portraits and battle log.
		game.run=IdleRun.new();check(game.run.start_expedition(game.campaign,"alice","blessing:alice:0"),"Start purchased Alice")
		game.run.interlude="route"
		for i in 2:
			var item:String=["black_apple","trophy_alice"][i]
			game.run.grant_item(item);check(game.run.equip_item(0,item,i),"Equip negative-effect item")
		game.run.interlude=""
		game.build_battle();game.spawn_enemy();game._process(1.2)
		game.arena.set_process(false);game.arena.entrance_left=0;game.arena.intro_left=0
		game.run.actors[0].hp=100000;game.run.actors[0].max_hp=100000
		for foe in game.run.tactics.enemies:foe.max_hp=100000;foe.hp=100000
		for tick in 950:
			game._process(.05);game.arena._process(.05)
			if is_instance_valid(game.feedback):game.feedback._process(.05)
			if tick%25==0:await process_frame
		check(game.run.actors[0].get("boon_feats",{}).get("two_conditions",false),"Alice item conditions unlock her feat through real controller")
		check(game.battle_history.any(func(line):return "Alice" in line and ("Veneno" in line or "Queimadura" in line)),"Item DOT source displayed with actual hero name")
		game.run.tactics.notify("enemy_0","Veneno","Origem inimiga","status")
		game.consume_feedback()
		game.feedback.enqueue({"hero":"item_alice","title":"Condição","detail":"Legado","kind":"status"})
		game.feedback.enqueue({"hero":"removed_hero","title":"Condição","detail":"Desconhecido","kind":"status"})
		check(game.feedback.queue.all(func(event):return TaleCatalog.HEROES.has(event.hero)),"Unknown/item sources cannot enter portrait lookup unsafely")
		game.feedback.announce_ultimate("enemy_0")
		game.paused=true;game.arena.frozen=true
		await capture("alice-items-combat-%d"%extent.x)
		game.persist_run()
		var normal=game.campaign
		var original_checkpoint:Dictionary=normal.checkpoint.duplicate(true)
		var original_model:=JSON.stringify(normal.to_dict())
		var original_file:=FileAccess.get_file_as_string(game.save_path)
		game.show_menu();game.debug_enabled=true;game.prepare_debug_run()
		check(game.debug_session and game.debug_source_campaign==normal and game.campaign!=normal,"PC debug uses isolated campaign")
		check(game.campaign.unlocked.size()==12,"All protagonists selectable in debug")
		for hero in TaleCatalog.HEROES:
			for path in 4:check(preload("res://scripts/hero_blessings.gd").unlocked(game.campaign,"blessing:%s:%d"%[hero,path]),"All48blessings unlocked in sandbox")
		game.show_debug_run_setup()
		game.debug_party.assign(["alice","snow_white","rapunzel","mulan","ariel"])
		check(not game.can_add_debug_hero("peter"),"Debug team respects five cap")
		game.show_debug_run_setup();await capture("debug-team-%d"%extent.x)
		game.configure_debug_protagonist();game.chosen_blessing="blessing:alice:1"
		game.begin_expedition()
		check(game.run.actors.size()==5 and game.run.party_capacity==5 and game.run.inventory.size()==39,"Real debug run starts with five and current39items")
		check(game.run.actors[0].blessing_index==1 and game.run.interlude=="route","Chosen unlocked blessing active; equipment preparation before combat")
		game.persist_run();game.persist()
		check(FileAccess.get_file_as_string(game.save_path)==original_file,"Debug checkpoints/unlocks cannot overwrite normal save")
		game.run.phase=4;game.run.roll_routes();game.run.interlude="route";game.show_routes()
		await capture("market-choice-%d"%extent.x)
		game.select_route("trader")
		check(game.state=="shop" and game.run.merchant_kind=="trader" and game.run.phase==4,"X-5 Negociante opens without combat")
		await capture("trader-%d"%extent.x)
		game.leave_run_shop()
		check(game.run.phase==5 and game.state=="travel","Leaving trader advances to boss")
		game.toggle_debug()
		check(not game.debug_session and game.campaign==normal and normal.checkpoint==original_checkpoint,"Leaving debug restores actual collection and pending run")
		check(FileAccess.get_file_as_string(game.save_path)==original_file,"Normal file unchanged after complete debug session")
		check(JSON.stringify(normal.to_dict())==original_model,"Sandbox never mutates in-memory normal progression")
	game.queue_free();await process_frame
	print("RELEASE UI 0910 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	quit(1 if failures>0 else 0)
