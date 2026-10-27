extends SceneTree
const Visuals=preload("res://scripts/character_visuals.gd")
var game
var destination:=""
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
	assert(root.get_texture().get_image().save_png(destination+"/"+file+".png")==OK)
func prepare(ids: Array) -> void:
	game.campaign.checkpoint.clear()
	game.run=IdleRun.new()
	assert(game.run.start_expedition(game.campaign,ids[0],"vigor"))
	for id in ids.slice(1):
		game.run.pending_choice=true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		assert(game.run.recruit(game.campaign,id))
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.intro_left=0
	game.arena.entrance_left=0
	game.arena.enemy_visible=true
	game.arena._process(.01)
func f11() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_F11
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
func checks() -> void:
	if OS.get_cmdline_user_args().size()>0:
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var fresh:=preload("res://tests/test_accounts.gd").legacy()
	assert(fresh.window_mode=="fullscreen" and not fresh.window_mode_selected)
	fresh.load_data({"window_mode":"windowed"})
	assert(fresh.window_mode=="fullscreen","Migrate the old implicit windowed default")
	fresh.load_data({"window_mode":"windowed","window_mode_selected":true})
	assert(fresh.window_mode=="windowed" and fresh.window_mode_selected)
	var saved:=preload("res://tests/test_accounts.gd").legacy()
	saved.load_data(fresh.to_dict())
	assert(saved.window_mode=="windowed" and saved.window_mode_selected)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://visual_consistency_isolated.json"
	root.add_child(game)
	game.set_process(false)
	# Do not inherit a previous test's display preference.
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	if DisplayServer.get_name()!="headless":
		game.apply_window_mode()
		await process_frame
		await process_frame
		assert(game.get_window().mode==Window.MODE_FULLSCREEN)
		for i in 4:
			await f11()
			assert(game.get_window().mode==(Window.MODE_WINDOWED if i%2==0 else Window.MODE_FULLSCREEN),"F11 must change the actual native window mode once")
		await f11()
		assert(game.get_window().mode==Window.MODE_WINDOWED)
	var unlocks:Array=game.campaign.unlocked.duplicate()
	game.toggle_debug()
	game.reveal_debug_roster()
	assert(game.debug_enabled and game.debug_roster_all)
	assert(game.campaign.unlocked==unlocks,"Debug reveal must preserve actual unlocks")
	for id in TaleCatalog.HEROES:
		game.choose_preview(id)
		assert(game.selected_hero==id and game.state=="preview")
		var frames:SpriteFrames=game.arena.heroes[0].sprite_frames
		assert(frames.get_frame_count("walk")== (16 if id=="puss" else 8) and frames.get_frame_count("attack")== (10 if id=="puss" else 12))
	game.toggle_debug()
	assert(not game.debug_roster_all and not game.hero_revealed("mulan"))
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	for dimensions in [Vector2i(540,960),Vector2i(1280,800)]:
		root.content_scale_size=dimensions
		root.size=dimensions
		game.center_content()
		var mode:="mobile" if dimensions.x==540 else "pc"
		game.show_heroes()
		await process_frame
		for card in descendants(game.page).filter(func(n):return n.has_meta("hero_id")):
			var id:String=card.get_meta("hero_id")
			var sprite:Sprite2D=card.get_node("HeroArt")
			var bounds:Rect2=game.static_portraits[id].bounds
			var height:float=bounds.size.y*sprite.scale.y
			var area:Rect2=sprite.get_meta("portrait_rect")
			assert(height>248*Visuals.height(id),id+" enlarged gallery height")
			assert(absf(sprite.position.y+bounds.end.y*sprite.scale.y-area.end.y)<.1,id+" common gallery baseline")
			assert(sprite.position.x+bounds.position.x*sprite.scale.x>=0 and sprite.position.x+bounds.end.x*sprite.scale.x<=card.size.x,id+" art fits inside card")
		for id in ["scarlet","mulan","alice","matches","aladin"]:
			game.select_gallery_hero(id)
			await process_frame
			await process_frame
			await capture("gallery_"+id+"_"+mode)
		prepare(["scarlet","alice","ariel"])
		var height:float=game.arena.human_height()
		while game.run.tactics.enemies.size()<3:game.run.tactics.enemies.append(game.run.tactics.enemies[0].duplicate(true))
		game.run.tactics.enemies.resize(3)
		for foe in game.run.tactics.enemies:foe.row="front"
		game.arena.sync_enemies()
		assert(game.arena.human_height()==height,"Enemy row composition must never shrink anyone")
		for unit in game.arena.heroes:assert(absf(float(unit.get_meta("visual_height"))-height)<.1)
		await capture("three_back_"+mode)
		game.run.actors[0].damage=123.4
		preload("res://scripts/combat_rules.gd").status(game.run.actors[0],"poison","enemy_0",2,2.1)
		game.show_character_information(0)
		await process_frame
		var children:=descendants(game.overlay)
		assert(children.filter(func(n):return n.has_meta("stat")).size()==8)
		assert(children.filter(func(n):return n.has_meta("skill")).size()==4)
		assert(children.any(func(n):return n is Label and n.text=="123.4"),"Live run buffs appear in stat cards")
		assert(children.any(func(n):return n.name=="CharacterArt"))
		await capture("inspector_"+mode)
		game.close_character_information()
		assert(not game.paused)
		game.paused=true
		game.show_character_information(1)
		game.close_character_information()
		assert(game.paused)
		prepare(["joao","rapunzel","puss"])
		await capture("three_front_"+mode)
		for id in ["mulan","ariel","snow_white","joao"]:
			prepare([id])
			game.arena.heroes[0].pause()
			game.arena.heroes[0].animation="attack"
			game.arena.heroes[0].frame=4
			await capture("attack_"+id+"_"+mode)
	if DisplayServer.get_name()!="headless":
		game.campaign.window_mode="fullscreen"
		game.apply_embedded_fullscreen()
		await process_frame
		await process_frame
		assert(game.get_window()==game.fullscreen_host and game.fullscreen_host.mode==Window.MODE_FULLSCREEN)
		await f11()
		assert(game.get_window()==game.fullscreen_host and game.fullscreen_host.mode==Window.MODE_WINDOWED,"Editor fallback keeps its native keyboard target")
		await f11()
		assert(game.fullscreen_host.mode==Window.MODE_FULLSCREEN)
	print("VISUAL CONSISTENCY PASS: native F11/default, temporary all-hero debug, 34 frames, standard gallery height/baseline, stable arena scale, 8 live stat boxes and separate skills")
	if is_instance_valid(game.fullscreen_host):
		var host:Window=game.fullscreen_host
		game.reparent(root)
		host.queue_free()
	game.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://visual_consistency_isolated.json"+suffix))
	quit()
