extends SceneTree
const Art=preload("res://scripts/hero_art.gd")
var game
var destination:=""
func _initialize() -> void:call_deferred("checks")
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://hd_093_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	await process_frame
	game.get_window().size=Vector2i(1280,800)
	game.get_window().content_scale_size=Vector2i(1280,800)
	await process_frame
	game.center_content()
	game.state="portrait_qa"
	game.clear_page()
	var sheet:=Control.new()
	sheet.size=Vector2(1280,800)
	sheet.z_index=3900
	game.get_window().add_child(sheet)
	var backdrop:=ColorRect.new()
	backdrop.color=Color("102421")
	backdrop.size=sheet.size
	sheet.add_child(backdrop)
	var at:=0
	for id in TaleCatalog.HEROES:
		var data:=Art.body(id)
		if id!="puss":assert(data.texture.get_height()>=1400,"Selection must use HD art")
		var head:AtlasTexture=Art.head(id)
		assert(head.region.size.x>=270,"Icons must crop the HD source")
		var model:AnimatedSprite2D=TaleCatalog.HERO_SCENES[id].instantiate()
		if id!="puss":assert(model.sprite_frames.get_frame_texture("idle",0).base_texture.resource_path.ends_with("_idle.webp"),"Combat sprites must keep their original source")
		model.free()
		var x:=20+(at%6)*210
		var y:=12+floori(at/6.0)*388
		var card:=Panel.new()
		card.position=Vector2(x,y)
		card.size=Vector2(198,372)
		sheet.add_child(card)
		game.banner_portrait(card,id,Rect2(8,30,182,300),false)
		game.face_portrait(card,id,Rect2(112,26,78,78))
		game.label(card,TaleCatalog.HEROES[id].name,Rect2(8,336,184,26),14)
		at+=1
	await capture("hd-roster")
	sheet.get_parent().remove_child(sheet)
	sheet.queue_free()
	for dimensions in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=dimensions
		game.get_window().content_scale_size=dimensions
		await process_frame
		game.center_content()
		var prefix:="mobile" if dimensions.x<700 else "pc"
		game.selected_hero="matches"
		game.show_heroes()
		await capture(prefix+"-hd-selection")
		game.run=IdleRun.new()
		assert(game.run.start_expedition(game.campaign,"snow_white","vigor"))
		game.enter_encounter()
		game.spawn_enemy()
		game.arena.set_process(false)
		game.arena.intro_left=0
		game.arena.entrance_left=0
		game.arena.walking=false
		game.arena.set_animation("idle")
		game.arena._process(.01)
		game.feedback.set_process(false)
		game.feedback.queue.clear()
		game.feedback.ribbon_left=0
		game.feedback.enqueue({"hero":"mulan","kind":"passive","title":"Corte de retorno","detail":"Reação"})
		game.feedback.announce_ultimate("snow_white")
		game.feedback._process(.30)
		for face in [game.feedback.ribbon_face,game.feedback.cutin_face]:
			var holder:Control=face.get_parent()
			assert(holder.position==Vector2(10,10) and holder.size==Vector2(44,44))
			assert(face.get_rect()==Rect2(Vector2.ZERO,holder.size))
			assert(holder.clip_contents)
		assert(game.feedback.ribbon_name.position.x>=70 and game.feedback.ribbon_title.get_rect().end.y<=54)
		await capture(prefix+"-fitted-ribbons")
	game.queue_free()
	await process_frame
	print("HD PORTRAITS 093 PASS: high-resolution UI originals, precise painted-frame insets, clipped HD icons, unchanged combat assets")
	quit()
