extends SceneTree
const Visuals=preload("res://scripts/character_visuals.gd")
var game
var destination: String
func _initialize() -> void: call_deferred("checks")
func prepare(ids: Array, world: int) -> void:
	game.campaign.checkpoint.clear()
	game.run=IdleRun.new()
	assert(game.run.start_expedition(game.campaign,ids[0],"vigor"))
	for id in ids.slice(1):
		game.run.pending_choice=true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		assert(game.run.recruit(game.campaign,id))
	game.run.stage=world
	game.run.phase=2
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.intro_left=0
	game.arena.entrance_left=0
	game.arena._process(.01)
	for actor in game.arena.heroes:
		actor.set_process(false)
		actor.pause()
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(destination+"/"+name+".png")==OK)
func checks() -> void:
	assert(DisplayServer.get_name()!="headless")
	destination=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://character_revision_visual_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new()
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await create_timer(.15).timeout
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	for dimensions in [Vector2i(540,960),Vector2i(1280,800)]:
		root.content_scale_size=dimensions
		root.size=dimensions
		await create_timer(.1).timeout
		game.center_content()
		var mode:="mobile" if dimensions.x==540 else "pc"
		for ids in [["joao","mulan","alice"],["rapunzel","puss","snow_white"]]:
			prepare(ids,2)
			game.arena.walking=true
			game.arena.travel_progress=1
			game.arena.set_animation("walk")
			for actor in game.arena.heroes: actor.pause()
			for at in 16:
				for index in game.arena.heroes.size():
					var actor: AnimatedSprite2D=game.arena.heroes[index]
					actor.seek_animation("walk",float(at)/12+.001)
					var texture: MeshTexture=actor.sprite_frames.get_frame_texture("walk",at)
					var bounds:=texture.mesh.get_aabb()
					assert(absf(bounds.size.y-400)<2,"Walking height must match idle: "+str(ids[index]))
					assert(absf(bounds.end.y-1400)<2,"All feet use the exact same baseline")
					assert(actor.position.y==game.arena.tracks[index].home.y)
				if at in [0,3,7,11,15]: await capture("walk_%s_%s_%02d"%[ids[0],mode,at])
		prepare(["snow_white","alice","mulan"],0)
		game.run.tactics.enemies[0].poison=3.4
		game.run.tactics.enemies[0].poison_left=5
		game.run.tactics.enemies[0].burn=4.5
		game.run.tactics.enemies[0].burn_left=4
		game.run.actors[0].hostile_poison=2.1
		game.run.actors[0].hostile_burn=1.2
		game.run.actors[0].hostile_dot_left=3
		game.update_hud()
		assert(game.arena.foe_widgets[0].badges.size()==2 and game.arena.unit_widgets[0].badges.size()==2)
		await capture("conditions_"+mode)
		game.run.tactics.tick(6)
		game.update_hud()
		assert(game.arena.foe_widgets[0].badges.is_empty() and game.arena.unit_widgets[0].badges.is_empty(),"Expired conditions leave no stale badges")
		game.run.actors[0].hostile_poison=2.1
		game.run.actors[0].hostile_dot_left=3
		var before_energy: float=game.run.actors[0].energy
		var info_button: Button=game.ult_buttons[0].get_node("CharacterInformation")
		var press:=InputEventMouseButton.new()
		press.button_index=MOUSE_BUTTON_LEFT
		press.position=info_button.get_global_rect().get_center()
		press.pressed=true
		Input.parse_input_event(press)
		await process_frame
		press=InputEventMouseButton.new()
		press.button_index=MOUSE_BUTTON_LEFT
		press.position=info_button.get_global_rect().get_center()
		press.pressed=false
		Input.parse_input_event(press)
		await process_frame
		assert(game.paused and game.arena.frozen and game.run.actors[0].energy==before_energy)
		await capture("information_"+mode)
		game.close_character_information()
		for value in [2,3,1]:
			game.toggle_speed()
			assert(game.game_speed==value and game.arena.speed==value)
		game.show_heroes()
		await process_frame
		await process_frame
		var gallery: ScrollContainer=game.gallery_scroll
		gallery.scroll_horizontal=0
		var point: Vector2=gallery.get_global_rect().get_center()
		var selected: String=game.selected_hero
		var touch:=InputEventScreenTouch.new()
		touch.index=0
		touch.position=point
		touch.pressed=true
		Input.parse_input_event(touch)
		await process_frame
		var drag:=InputEventScreenDrag.new()
		drag.index=0
		drag.position=point-Vector2(180,0)
		drag.relative=Vector2(-180,0)
		Input.parse_input_event(drag)
		await process_frame
		touch=InputEventScreenTouch.new()
		touch.index=0
		touch.position=drag.position
		touch.pressed=false
		Input.parse_input_event(touch)
		await process_frame
		assert(gallery.scroll_horizontal>40 and game.selected_hero==selected,"Touch swipes scroll without selecting a hero")
		await capture("touch_gallery_"+mode)
		gallery.scroll_horizontal=0
		var tap_point:=gallery.get_global_rect().position+Vector2(360,180)
		var tap:=InputEventScreenTouch.new()
		tap.index=1
		tap.position=tap_point
		tap.pressed=true
		Input.parse_input_event(tap)
		await process_frame
		tap=InputEventScreenTouch.new()
		tap.index=1
		tap.position=tap_point
		tap.pressed=false
		Input.parse_input_event(tap)
		await process_frame
		assert(game.selected_hero=="rapunzel","A touch tap still selects its card after a swipe")
	root.content_scale_size=Vector2i(540,960)
	root.size=Vector2i(540,960)
	game.center_content()
	var secrets=preload("res://scripts/secret_encounters.gd")
	for id in secrets.DATA:
		var world: int=preload("res://scripts/biomes.gd").STAGE_BIOMES.find(secrets.DATA[id].biomes[0])
		prepare([id],world)
		game.run.active_secret=id
		game.run.tactics.spawn()
		game.arena.sync_enemies()
		game.arena.enemy_visible=true
		game.arena._process(.01)
		await capture("secret_"+id)
		game.run.pending_event="secret_"+id
		game.run.interlude="event"
		game.run.active_secret=""
		game.show_team_event()
		await capture("dialogue_"+id)
	prepare(["scarlet"],0)
	game.run.pending_event="secret_scarlet"
	game.run.interlude="event"
	game.show_team_event()
	game.select_team_event("challenge")
	assert(game.run.active_secret=="scarlet")
	game.spawn_enemy()
	game.state="battle"
	for foe in game.run.tactics.enemies: foe.hp=0
	game.run.tactics.sync_totals()
	game.resolve_enemy()
	game.finish_encounter_now()
	assert(game.state=="secret_reward" and game.run.interlude=="secret_reward" and game.run.phase==2 and game.run.rooms_cleared==0)
	await capture("secret_reward")
	var won_damage: float=game.run.actors[0].damage
	game.restore_checkpoint_now()
	assert(game.state=="secret_reward" and game.run.actors[0].damage==won_damage)
	game.continue_after_secret()
	game.spawn_enemy()
	assert(game.run.active_secret.is_empty() and game.run.phase==2 and not game.run.tactics.enemies[0].has("secret_id"))
	game.show_hero_details("puss")
	await capture("numeric_collection")
	var old_size:=root.size
	game.campaign.window_mode="windowed"
	game.toggle_fullscreen()
	await process_frame
	assert(root.mode==Window.MODE_EXCLUSIVE_FULLSCREEN)
	game.toggle_fullscreen()
	await process_frame
	assert(root.mode==Window.MODE_WINDOWED and root.size==old_size)
	game.campaign.window_mode="fullscreen"
	game.apply_embedded_fullscreen()
	await process_frame
	print("FULLSCREEN HOST: own_window=",game.get_window()==game.fullscreen_host," force=",game.fullscreen_host.force_native," mode=",game.fullscreen_host.mode)
	assert(game.get_window()==game.fullscreen_host and game.fullscreen_host.force_native and game.fullscreen_host.mode==Window.MODE_EXCLUSIVE_FULLSCREEN)
	game.campaign.window_mode="windowed"
	game.apply_embedded_fullscreen()
	await process_frame
	assert(game.get_parent()==game.fullscreen_host and game.fullscreen_host.mode==Window.MODE_WINDOWED)
	print("CHARACTER VISUAL PASS: stable 16-frame walks mobile/PC, status pairs, info buttons, 3x, real touch drags, 12 secret bosses/dialogues, native fullscreen roundtrip")
	game.queue_free()
	await process_frame
	quit()
