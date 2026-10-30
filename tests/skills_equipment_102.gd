extends SceneTree
const Gear=preload("res://scripts/equipment.gd")
const Art=preload("res://scripts/skill_art.gd")
var game:Control
var destination:=""
func _initialize() -> void:call_deferred("checks")
func descendants(node:Node) -> Array[Node]:
	var result:Array[Node]=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func capture(title:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(title+".png"))
func click(button:Button) -> void:
	var point:=button.get_global_transform_with_canvas()*(button.size*.5)
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	motion.global_position=point
	game.get_viewport().push_input(motion,true)
	for down in [true,false]:
		if game.logical_width<900:
			var finger:=InputEventScreenTouch.new()
			finger.index=0
			finger.position=point
			finger.pressed=down
			game.get_viewport().push_input(finger,true)
		var event:=InputEventMouseButton.new()
		event.device=InputEvent.DEVICE_ID_EMULATION if game.logical_width<900 else 0
		event.position=point
		event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed=down
		game.get_viewport().push_input(event,true)
	await process_frame
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var regions:Dictionary={}
	for id in TaleCatalog.HEROES:
		for kind in 3:
			var image:=Art.texture(id,kind) as AtlasTexture
			assert(image!=null and image.region.size==Vector2(362,362))
			var key:=str(kind)+str(image.region)
			assert(not regions.has(key))
			regions[key]=true
	assert(regions.size()==36)
	var test_portrait:=Sprite2D.new()
	preload("res://scripts/hero_art.gd").ink(test_portrait,"scarlet",1)
	assert(is_equal_approx(test_portrait.material.get_shader_parameter("ink_width"),.35))
	assert(is_equal_approx(test_portrait.material.get_shader_parameter("inner_width"),.1125))
	preload("res://scripts/hero_art.gd").ink(test_portrait,"alice",1)
	assert(is_equal_approx(test_portrait.material.get_shader_parameter("ink_width"),.8))
	test_portrait.free()
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://skills_equipment_102_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	for extent in [Vector2i(1280,800),Vector2i(540,960),Vector2i(360,640)]:
		game.get_window().size=extent
		game.get_window().content_scale_size=extent
		await process_frame
		await process_frame
		game.center_content()
		game.campaign.checkpoint={}
		game.run=IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"scarlet","vigor"))
		for hero in ["alice","rapunzel"]:
			game.run.pending_choice=true
			game.run.offers.assign(["ally:"+hero,"power","heart"])
			assert(game.run.recruit(game.campaign,hero))
		game.enter_encounter()
		game.spawn_enemy()
		game.arena.set_process(false)
		game.feedback.set_process(false)
		game.show_character_information(1)
		for frame in 5:await process_frame
		var sheet=game.overlay
		var nodes:=descendants(sheet)
		assert(nodes.filter(func(n):return n.has_meta("stat")).size()==11)
		var portrait:Sprite2D=nodes.filter(func(n):return n is Sprite2D and n.name=="HeroArt")[0]
		assert(portrait.scale.x<0 and portrait.get_meta("visual_height")>180,"Large left-facing portrait on PC and mobile")
		assert(nodes.filter(func(n):return n.name=="AbilityPicture").size()==3)
		assert(sheet.find_child("AbilityGrid",true,false).columns==1)
		assert(nodes.filter(func(n):return n.name=="AbilityDescription" and not n.text.is_empty()).size()==3)
		var info:Button=nodes.filter(func(n):return n.name=="SkillInfo0")[0]
		info.mouse_entered.emit()
		assert(sheet.detail==null)
		await click(info)
		assert(is_instance_valid(sheet.detail) and sheet.pinned and sheet.detail_key=="skill0")
		var margin:MarginContainer=info.get_parent()
		assert(margin.get_theme_constant("margin_left")==5)
		assert(info.size.x==info.size.y)
		assert(info.get_theme_stylebox("normal").corner_radius_top_left==0)
		assert(info.get_theme_font("font").resource_path.ends_with("Goldman-Regular.ttf"))
		var inside:=InputEventMouseButton.new()
		inside.button_index=MOUSE_BUTTON_LEFT
		inside.pressed=true
		inside.position=sheet.detail.get_global_rect().get_center()
		sheet._input(inside)
		assert(is_instance_valid(sheet.detail))
		var outside:=InputEventScreenTouch.new()
		outside.pressed=true
		outside.position=Vector2(2,2)
		sheet._input(outside)
		assert(sheet.detail==null)
		await capture("sheet-"+str(extent.x))
		game.close_character_information()
		game.run.interlude="route"
		for id in ["stone_heart","blue_hourglass"]:assert(game.run.grant_item(id))
		assert(game.run.equip_item(0,"stone_heart",0))
		assert(game.run.equip_item(1,"blue_hourglass",1))
		game.show_equipment(1,1)
		var panel=game.equipment_panel
		panel.select_item("stone_heart")
		var action:Button=panel.find_child("EquipSelectedItem",true,false)
		assert(not action.disabled,"Used items stay actionable through confirmation")
		var before:Dictionary=game.run.equipment_snapshot().duplicate(true)
		var inventory:Array=game.run.inventory.duplicate()
		panel.request_equip()
		assert(is_instance_valid(panel.transfer_prompt))
		assert(game.run.equipment_snapshot()==before,"Opening the prompt changes nothing")
		var explanation:Label=panel.transfer_prompt.find_child("TransferExplanation",true,false)
		assert(explanation.text.contains(TaleCatalog.HEROES.scarlet.name) and explanation.text.contains("voltará para a bolsa"))
		await capture("transfer-"+str(extent.x))
		await click(panel.transfer_prompt.find_child("CancelTransfer",true,false))
		assert(panel.transfer_prompt==null and game.run.equipment_snapshot()==before and game.run.inventory==inventory)
		panel.request_equip()
		await click(panel.transfer_prompt.find_child("ConfirmTransfer",true,false))
		assert(Gear.item_at(game.run.actors[0],0)=="" and Gear.item_at(game.run.actors[1],1)=="stone_heart")
		assert(game.run.equipped_count("stone_heart")==1 and game.run.equipped_count("blue_hourglass")==0)
		assert(game.run.inventory==inventory)
		assert(game.campaign.checkpoint.equipment_state.alice.items[1]=="stone_heart")
		var remove:Button=panel.find_child("RemoveEquipment",true,false)
		assert(remove.text.begins_with("Remover equipamento") and remove.size.x>200 and remove.size.y>=48)
		await capture("equipment-"+str(extent.x))
		await click(remove)
		assert(Gear.item_at(game.run.actors[1],1)=="")
		assert(game.run.equip_item(0,"stone_heart",0))
		panel.select_item("stone_heart")
		panel.request_equip()
		var esc:=InputEventKey.new()
		esc.keycode=KEY_ESCAPE
		esc.pressed=true
		game._input(esc)
		assert(panel.transfer_prompt==null and is_instance_valid(game.equipment_panel))
		panel.request_equip()
		assert(game.run.equip_item(0,"",0))
		panel.confirm_transfer()
		assert(Gear.item_at(game.run.actors[1],1)=="","A stale source cannot transfer")
		assert(game.run.equip_item(0,"stone_heart",0))
		panel.request_equip()
		game.run.interlude=""
		before=game.run.equipment_snapshot().duplicate(true)
		panel.confirm_transfer()
		assert(game.run.equipment_snapshot()==before,"Combat blocks transfers even with an old prompt")
		game.close_equipment()
	game.queue_free()
	await process_frame
	print("SKILLS EQUIPMENT 102 PASS: 36 images, info buttons, large left portrait, confirmation/cancel/transfer/remove, checkpoint, stale source and combat lock at PC/mobile sizes")
	quit()
