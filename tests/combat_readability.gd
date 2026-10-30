extends SceneTree
const Rules=preload("res://scripts/combat_rules.gd")
const Preview=preload("res://scripts/skill_preview.gd")
var game:Control
var destination:=""
func _initialize() -> void:call_deferred("checks")
func descendants(node:Node) -> Array[Node]:
	var all:Array[Node]=[]
	for child in node.get_children():
		all.append(child)
		all.append_array(descendants(child))
	return all
func capture(title:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(title+".png"))
func pointer_at(button:Button) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=button.get_global_transform_with_canvas()*Vector2(24,8)
	event.global_position=event.position
	game.get_viewport().push_input(event,true)
func tap(button:Button) -> void:
	pointer_at(button)
	var point:=button.get_global_transform_with_canvas()*Vector2(24,8)
	for pressed in [true,false]:
		var touch:=InputEventScreenTouch.new()
		touch.index=0
		touch.position=point
		touch.pressed=pressed
		game.get_viewport().push_input(touch,true)
		var mouse:=InputEventMouseButton.new()
		mouse.device=InputEvent.DEVICE_ID_EMULATION
		mouse.position=point
		mouse.global_position=point
		mouse.button_index=MOUSE_BUTTON_LEFT
		mouse.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		mouse.pressed=pressed
		game.get_viewport().push_input(mouse,true)
	await process_frame
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://combat_readability_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	for dimensions in [Vector2i(1280,720),Vector2i(540,960),Vector2i(360,640)]:
		game.get_window().size=dimensions
		game.get_window().content_scale_size=dimensions
		await process_frame
		await process_frame
		game.center_content()
		game.campaign.checkpoint.clear()
		game.run=IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"alice","vigor"))
		game.run.actors[0].bonus_totals={"physical_damage":.2,"initiative":10.0,"attacks":1.0,"crit":.15}
		game.enter_encounter()
		game.spawn_enemy()
		if game.arena.warming_attacks():assert(game.arena.is_action_busy(),"Actions wait for render preparation")
		for frame in 240:
			if not game.arena.warming_attacks():break
			await process_frame
		assert(not game.arena.warming_attacks(),"Render preparation completes")
		assert(preload("res://scripts/combat_warmup.gd").prepared.size()>0,"Prepared resources remain cached")
		assert(game.arena.human_height()+game.arena.widget_size().y+8<=game.arena.field_height*.26+.01,"Body and plate fit the reserved slot")
		game.show_character_information(0)
		for frame in 4:await process_frame
		var inspector=game.overlay
		var nodes:=descendants(inspector)
		var art:Sprite2D=nodes.filter(func(n):return n is Sprite2D and n.name=="HeroArt")[0]
		assert(art.scale.x<0,"Sheet portrait faces left")
		var stats:=nodes.filter(func(n):return n.has_meta("stat"))
		assert(stats.size()==11)
		for stat in stats:assert(Rect2(Vector2.ZERO,inspector.board.size).encloses(Rect2(stat.position,stat.size)),"Stats stay on board")
		var scroll:ScrollContainer=nodes.filter(func(n):return n.name=="SkillScroll")[0]
		assert(scroll.size.y>=150 and scroll.position.y+scroll.size.y<inspector.board.size.y-60)
		var labels:=nodes.filter(func(n):return n is Label)
		assert(labels.any(func(n):return n.text.contains("Dano Físico  +20.0%")))
		assert(labels.any(func(n):return n.text.contains("Quantidade de Ataques  +1.0")))
		var basic:Button=nodes.filter(func(n):return n.name=="SkillInfo0")[0]
		basic.mouse_entered.emit()
		assert(inspector.detail==null,"Skill descriptions open only on the information button click")
		basic.mouse_exited.emit()
		assert(inspector.detail==null)
		await tap(basic)
		assert(inspector.pinned and is_instance_valid(inspector.detail),"Finger plus emulated mouse opens one description")
		await capture("sheet-"+str(dimensions.x))
		inspector.hide_detail()
		var special:Button=nodes.filter(func(n):return n.name=="SkillInfo2")[0]
		# Scroll/focus may have moved after a finger press; reveal the tested card.
		scroll.ensure_control_visible(special)
		await process_frame
		pointer_at(special)
		for frame in 4:await process_frame
		assert(inspector.detail==null,"Hover alone does not open skill information")
		await tap(special)
		assert(inspector.pinned and is_instance_valid(inspector.detail),"The information button opens the complete explanation")
		inspector.hide_detail()
		await capture("sheet-clear-"+str(dimensions.x))
		game.close_character_information()
	for id in TaleCatalog.HEROES:
		var a:Dictionary=game.run.run_actor(id)
		var before:=a.duplicate(true)
		for kind in 3:
			var preview:=Preview.preview(a,kind)
			assert(not preview.summary.is_empty() and not preview.detail.is_empty())
		assert(a==before,"Reading skills never changes combat state")
		if id=="alice":
			var hit:=Rules.basic_components(a)
			assert(hit[0]>0 and hit[1]>0)
	game.show_loading(Callable(),0)
	for frame in 240:
		if not game.attack_warmup.busy:break
		await process_frame
	assert(not game.attack_warmup.busy)
	game.queue_free()
	await process_frame
	print("COMBAT READABILITY PASS: warmup, slots, compact stats, real touch/info buttons, left portrait, run bonuses, read-only previews")
	quit()
