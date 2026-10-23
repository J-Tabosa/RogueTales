extends SceneTree
const Art = preload("res://scripts/character_effects.gd")
var game
var destination: String
func _initialize() -> void:call_deferred("checks")
func prepare(ids:Array,world:int) -> void:
	game.run=IdleRun.new()
	assert(game.run.start_expedition(game.campaign,ids[0],"vigor"))
	for id in ids.slice(1):
		game.run.pending_choice=true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		assert(game.run.recruit(game.campaign,id))
	game.run.stage=world
	game.run.phase=2
	game.run.rooms_cleared=world*6+2
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.intro_left=0
	game.arena.entrance_left=0
	game.arena._process(.01)
func checks() -> void:
	var args:=OS.get_cmdline_user_args()
	destination=args[0] if not args.is_empty() else "user://art-review"
	DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://art_visual_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.auto_ult=false
	for dimensions in [Vector2i(540,960),Vector2i(1280,800)]:
		root.content_scale_size=dimensions
		root.size=dimensions
		game.center_content()
		var mode:="mobile" if dimensions.x==540 else "pc"
		for world in 12:
			prepare(["joao","mulan","alice"],world)
			if world==0:await verify_visible_heroes()
			for item in game.arena.unit_widgets:
				assert(item.text.text.contains("/") and item.energy.visible)
			await capture("world_%02d_%s"%[world+1,mode])
		for ids in [["joao","puss","rapunzel"],["mulan","peter","maria"],["alice","ariel","matches"]]:
			prepare(ids,4)
			await capture("row_%s_%s"%[ids[0],mode])
		game.show_heroes()
		await capture("gallery_"+mode)
	root.content_scale_size=Vector2i(540,960)
	root.size=Vector2i(540,960)
	game.center_content()
	for id in Art.IDS:
		prepare([id,"scarlet"],5)
		await capture(id+"_idle")
		assert(game.arena.attack(0,0))
		game.arena.tracks[0].time=game.arena.tracks[0].duration*.45
		game.arena._process(.01)
		await capture(id+"_attack")
		game.arena.tracks[0].time=-1
		game.arena.heroes[0].show_animation("idle")
		game.arena.ultimate_effect(0,{"targets":[0]})
		game.arena.bursts[0].left=.8
		game.arena.hit_stop=0
		game.arena._process(.01)
		await capture(id+"_ultimate")
	print("ART VISUAL PASS: mobile/PC worlds, three units in every row, gallery, 10 attack/ULT presentations")
	game.queue_free()
	await process_frame
	quit()
func capture(name:String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name()!="headless":assert(root.get_texture().get_image().save_png(destination+"/"+name+".png")==OK)

func verify_visible_heroes() -> void:
	if DisplayServer.get_name()=="headless":return
	for actor in game.arena.heroes:
		actor.set_process(false)
		actor.pause()
		actor.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var background:=root.get_texture().get_image()
	for actor in game.arena.heroes:actor.show()
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered:=root.get_texture().get_image()
	for actor in game.arena.heroes:
		var texture:MeshTexture=actor.sprite_frames.get_frame_texture("idle",0)
		var volume:=texture.mesh.get_aabb()
		var local:=Rect2(Vector2(volume.position.x,volume.position.y)+actor.offset,Vector2(volume.size.x,volume.size.y))
		var area:Rect2=(actor.get_global_transform_with_canvas()*local).intersection(Rect2(Vector2.ZERO,rendered.get_size()))
		var changed:=0
		for y in range(int(area.position.y),int(area.end.y),2):
			for x in range(int(area.position.x),int(area.end.x),2):
				var before:=background.get_pixel(x,y)
				var after:=rendered.get_pixel(x,y)
				if absf(before.r-after.r)+absf(before.g-after.g)+absf(before.b-after.b)>0.08:changed+=1
		assert(changed>20,"A living hero must contribute visible pixels after viewport resize")
