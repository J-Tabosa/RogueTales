extends SceneTree
const Art=preload("res://scripts/hero_art.gd")
const Status=preload("res://scripts/status_art.gd")
var game
var destination:=""
func _initialize() -> void:call_deferred("checks")
func descendants(node:Node) -> Array[Node]:
	var nodes:Array[Node]=[]
	for child in node.get_children():
		nodes.append(child)
		nodes.append_array(descendants(child))
	return nodes
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func swipe(scroll:ScrollContainer) -> void:
	var point:=scroll.get_global_transform_with_canvas()*(scroll.size*.5)
	var touch:=InputEventScreenTouch.new()
	touch.index=0
	touch.pressed=true
	touch.position=point
	scroll._input(touch)
	var drag:=InputEventScreenDrag.new()
	drag.index=0
	drag.position=point-Vector2(0,140)
	drag.relative=Vector2(0,-140)
	scroll._input(drag)
	touch.pressed=false
	touch.position=drag.position
	scroll._input(touch)
	await process_frame
	assert(scroll.scroll_vertical>30,"Finger drag must work over the team skill cards")
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	for id in TaleCatalog.HEROES:
		var model:AnimatedSprite2D=TaleCatalog.HERO_SCENES[id].instantiate()
		root.add_child(model)
		model.set_process(false)
		assert(model.idle_min_wait>=7 and model.idle_max_wait>=11)
		model.show_animation("walk")
		model._process(20)
		assert(model.frame==0 and not model.is_playing() and model.walk_weight==0)
		model.show_animation("idle")
		model._process(6)
		assert(model.is_idle_resting() and model.frame==0)
		for pace in [1,2,3]:
			model.speed_scale=pace
			model._start_idle_variation(model.IdleState.SWAY)
			model._process(model.get_animation_duration("idle")+.02)
			assert(model.is_idle_resting() and model.frame==0 and model.idle_wait_left>=7)
		var current:=Art.body(id)
		assert(current.texture.get_height()>=1024 and current.bounds.size.y>0)
		assert(Art.head(id) is AtlasTexture)
		assert(Art.head(id).region.size.x>20)
		if id!="puss":assert(current.texture.get_image().get_pixel(0,0).a<.01)
		model.free()
	var conditions:=Status.active({"hp":100,"curse_left":8,"bleed":4,"bleed_left":5},true)
	assert(conditions.has("curse") and conditions.curse[0]==0 and conditions.has("bleed"))
	assert(not Status.description("curse",0,8).contains("dano/s"))
	for kind in ["coin","bleed","curse"]:
		assert(Status.texture(kind)!=null and Status.texture(kind).get_image().get_format()==Image.FORMAT_RGBA8)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://presentation_092_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	await process_frame
	for dimensions in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=dimensions
		game.get_window().content_scale_size=dimensions
		await process_frame
		await process_frame
		game.center_content()
		assert(game.audio.music.stream is AudioStreamOggVorbis and game.audio.music.stream.loop,"Window reparent must preserve music")
		var prefix:="mobile" if dimensions.x<700 else "pc"
		game.selected_hero="matches"
		game.show_heroes()
		await process_frame
		var nodes:=descendants(game.page)
		assert(not nodes.any(func(n):return n is Button and n.text=="Habilidades"))
		var action:Button=nodes.filter(func(n):return n.get_meta("select_character",false))[0]
		assert(action.size.x>450)
		assert(game.static_portraits.matches.source==Art.source_path("matches"))
		await capture(prefix+"-selection")
		game.select_gallery_hero("snow_white")
		assert(game.state=="hero_details")
		await capture(prefix+"-details")
		game.run=IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"ariel","vigor"))
		game.run.stage=2
		game.enter_encounter()
		game.spawn_enemy()
		game.arena.set_process(false)
		game.arena.intro_left=0
		game.arena.entrance_left=0
		game.arena.walking=false
		game.arena.set_animation("idle")
		game.arena._process(.01)
		game.run.run_gold=1234567
		game.update_hud()
		await process_frame
		assert(game.battle_gold.position.y<50 and game.page.has_node("BattleCoin"))
		game.feedback.announce_ultimate("snow_white")
		game.feedback.enqueue({"hero":"mulan","kind":"passive","title":"Corte de retorno","detail":"Reagiu"})
		game.feedback._process(.3)
		for face in [game.feedback.ribbon_face,game.feedback.cutin_face]:
			assert(face.get_parent().clip_contents and face.get_rect()==Rect2(Vector2.ZERO,face.get_parent().size))
		await capture(prefix+"-ribbons")
		game.run.actors[0].equipment.assign(["echo_bell","venom_vial"])
		game.run.actors[0]["hostile_burn"]=3.0
		game.run.actors[0]["hostile_dot_left"]=5.0
		game.show_character_information(0)
		await process_frame
		var scroll:ScrollContainer=descendants(game.overlay).filter(func(n):return n is ScrollContainer)[0]
		assert(scroll.get_script()==preload("res://scripts/touch_scroll.gd"))
		await process_frame
		await process_frame
		await swipe(scroll)
		await capture(prefix+"-inspector")
		game.close_character_information()
		var fx=game.arena.atmosphere
		fx.set_process(false)
		fx.frozen=false
		fx.blue_wave()
		fx.shake(20)
		fx._process(.09)
		assert(fx.shake_offset.length()<2.5 and fx.wave.visible)
		fx._process(.21)
		assert(fx.shake_offset==Vector2.ZERO and fx.wave_left>0)
		game.run.actors[0]["immortal_turns"]=1
		assert(fx.color_for(game.run.actors[0],0)=="red")
		game.run.tactics.enemies[0]["curse_left"]=8
		game.run.tactics.enemies[0]["bleed"]=4
		game.run.tactics.enemies[0]["bleed_left"]=5
		game.arena.sync_health(game.run.actors)
		assert(game.arena.foe_widgets[0].badges.has("curse"))
		assert(game.arena.foe_widgets[0].badges.curse.text.is_empty())
		fx.queue_redraw()
		await capture(prefix+"-effects")
		game.run.actors[0].immortal_turns=0
		assert(fx.color_for(game.run.actors[0],0).is_empty())
		fx.reduced_motion=true
		fx.shake(2)
		fx._process(2)
		assert(fx.shake_offset==Vector2.ZERO and not fx.wave.visible)
	game.queue_free()
	await process_frame
	print("PRESENTATION 092 PASS: static travel, slow one-shot idle/rests, unified transparent art, contained ribbons, wide selection, touch inspector, top gold, subtle wave/shake/auras and non-damaging status icons")
	quit()
