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
	# Android's mouse emulation must reach GUI handling after the finger press.
	# A direct ScreenTouch can still work on desktop, masking this canceled event.
	var surface:=SubViewport.new();surface.size=Vector2i(100,100)
	root.add_child(surface)
	var scroll:=ScrollContainer.new();scroll.set_script(preload("res://scripts/touch_scroll.gd"));scroll.size=Vector2(100,100)
	surface.add_child(scroll)
	var clear_event:=InputEventKey.new();clear_event.keycode=KEY_F9
	surface.push_input(clear_event,true)
	var press:=InputEventScreenTouch.new();press.position=Vector2(20,20);press.pressed=true;press.index=0
	scroll._input(press)
	var emulated:=InputEventMouseButton.new();emulated.position=press.position;emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=true;emulated.device=InputEvent.DEVICE_ID_EMULATION
	scroll._input(emulated)
	check(not surface.is_input_handled(),"Normal emulated press reaches GUI after a touch, instead of being canceled by scroll")
	surface.queue_free()
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://wishes097_isolated.json"
	root.add_child(game);game.set_process(false)
	game.campaign=TaleCampaign.new();game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true
	game.apply_window_mode();await process_frame;await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent
		await process_frame;game.center_content()
		game.run=IdleRun.new();game.run.start_expedition(game.campaign,"aladin","blessing:aladin:0")
		game.run.actors.append(game.run.run_actor("rapunzel"));game.run.actors.append(game.run.run_actor("scarlet"))
		for a in game.run.actors:game.run.tactics.configure_actor(a,a.row)
		game.build_battle();game.spawn_enemy();game.arena.reset_effects()
		game.arena.set_process(false);game.arena.entrance_left=0;game.arena.intro_left=0;game.arena.enemy_visible=true
		game.state="battle";game.paused=false;game.update_hud()
		await process_frame
		var card:Button=game.ult_buttons[0]
		game.run.actors[0].hp=0;game.update_hud()
		check(not card.disabled and game.run.actors[0].energy==0,"Aladin button needs no mana and remains available when fallen")
		if extent.x==540:
			var point:Vector2=card.get_global_transform_with_canvas()*Vector2(45,25)
			touch_at(point,true);mouse_at(point,true,true)
			var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=point-Vector2(65,0);drag.relative=Vector2(-65,0)
			send_event(drag);touch_at(drag.position,false);mouse_at(drag.position,false,true)
			await process_frame
			check(not game.paused and not is_instance_valid(game.overlay),"Swipe over the card does not open wishes")
			check(not game.hero_deck_scroll.suppress_mouse_release,"Drag release does not swallow the next tap")
			game.hero_deck_scroll.scroll_horizontal=0
		# Tap the actual card, including its decorative health/mana bars.
		var area:Vector2=game.ult_meters[0].position+game.ult_meters[0].size*.5
		await click(card,area,extent.x==540)
		check(game.paused and is_instance_valid(game.overlay),"Actual mouse/touch tap opens wishes during combat")
		if not is_instance_valid(game.overlay):quit(1);return
		await capture("wishes-%d"%extent.x)
		var life:Button=descendants(game.overlay).filter(func(n):return n is Button and n.text.begins_with("Ressurreição"))[0]
		game.run.actors[0].hp=0;game.run.actors[2].hp=0
		game.arena.sync_health(game.run.actors)
		await click(life,life.size*.5)
		check(game.run.actors[0].hp==game.run.actors[0].max_hp and game.run.actors[2].hp==game.run.actors[2].max_hp,"Resurrection works with Aladin fallen and revives everyone")
		check(not game.paused and game.arena.tracks[0].alive and game.arena.tracks[2].alive,"Revived sprites return and battle resumes")
		await click(card,Vector2(22,23),extent.x==540)
		check(is_instance_valid(game.overlay),"Portrait tap opens wishes too")
		var death:Button=descendants(game.overlay).filter(func(n):return n is Button and n.text.begins_with("Abate"))[0]
		check(not death.disabled,"Abate is available in combat")
		await click(death,death.size*.5)
		check(game.run.enemy_hp==0 and game.run.actors[0].wishes.has("death"),"Clicking Abate eliminates normals and spends once")
		# Silk's ULT must keep a complete, properly scaled body and hit once at every speed.
		for speed in [1.0,2.0,3.0]:
			game.run.spawn_enemy();game.arena.sync_enemies();game.arena.reset_effects();game.arena.intro_left=0;game.arena.entrance_left=0
			game.paused=false;game.state="battle";game.arena.frozen=false;game.arena.speed=speed
			game.run.actors[1].energy=100
			for ally in game.run.actors:ally.shield=0.0;ally.shield_parts=[]
			check(game.run.tactics.reserve_ultimate(1) and game.arena.attack(1,0,true),"Silk ult starts")
			game.arena.intro_left=0
			var model:AnimatedSprite2D=game.arena.heroes[1]
			var scale:Vector2=model.scale
			var home:Vector2=game.arena.tracks[1].home
			var unique:Dictionary={}
			# Controller callbacks apply the ULT; the pending flag proves exactly one resolution.
			for step in 64:
				game.arena._process(.05/speed)
				if game.arena.tracks[1].time<0:break
				unique[model.frame]=true
				check(model.animation=="attack" and model.scale==scale,"Silk uses intact cast cells without resizing")
				check(model.position.distance_to(home)<.1,"Silk feet remain anchored while casting")
				if speed==1 and extent.x==540 and step in [3,14,28,42]:await capture("silk-%02d"%step)
			check(unique.size()>=10,"Silk full cast sequence advances instead of freezing on one pose")
			check(not game.run.actors[1].ult_pending and close(game.run.actors[0].shield,30),"Silk shield resolves exactly once through real impact callback")
			check(model.animation=="idle" and model.scale==scale,"Silk returns to idle at the same scale")
		# Opening a wish mid-cast must not reset another ally's animation.
		game.run.actors[0].wishes=[];game.run.actors[1].energy=100
		game.run.tactics.reserve_ultimate(1);game.arena.attack(1,0,true);game.arena.intro_left=0;game.arena._process(.4)
		var before_frame:int=game.arena.heroes[1].frame
		game.show_wishes();game.perform_wish("wealth")
		check(game.arena.heroes[1].animation=="attack" and game.arena.heroes[1].frame==before_frame,"Wish does not reset a living ally's active cast")
		game.arena.reset_effects()
	game.queue_free();await process_frame
	print("WISHES SILK 097 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	quit(1 if failures>0 else 0)
