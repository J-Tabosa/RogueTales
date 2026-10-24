extends SceneTree
const Rules=preload("res://scripts/ultimate_rules.gd")
var game
var destination:String
func _initialize() -> void:call_deferred("checks")
func prepare(id:String) -> void:
	game.run=IdleRun.new()
	assert(game.run.start_expedition(game.campaign,id,"vigor"))
	game.run.party_capacity=9
	if id=="rapunzel":
		for ally in ["scarlet","mulan"]:
			game.run.pending_choice=true
			game.run.offers.assign(["ally:"+ally,"heart","power"])
			assert(game.run.recruit(game.campaign,ally))
	game.run.stage=2
	game.run.phase=2
	game.enter_encounter()
	game.spawn_enemy()
	for attempt in 1000:
		game.run.spawn_enemy()
		if game.run.tactics.enemies.size()==9:break
	assert(game.run.tactics.enemies.size()==9)
	game.arena.sync_enemies()
	for foe in game.run.tactics.enemies:
		foe.hp=100000
		foe.max_hp=100000
		foe.evasion=0
	for actor in game.run.actors:
		actor.hp=actor.max_hp*.6
		actor.crit=0
		actor.energy=100
		actor.card_charge=4
	game.state="battle"
	game.paused=false
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.intro_left=0
	game.arena.entrance_left=0
	game.arena.walking=false
	game.arena.enemy_visible=true
	game.arena.set_animation("idle")
	for actor in game.arena.heroes:
		actor.set_process(false)
	game.arena._process(.01)
	game.update_hud()
func checks() -> void:
	var args:=OS.get_cmdline_user_args()
	destination=args[0]
	DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://ultimate_capture_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new()
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.auto_ult=false
	game.campaign.reduced_motion=false
	await process_frame
	game.get_window().size=Vector2i(1280,800)
	game.get_window().content_scale_size=Vector2i(1280,800)
	await process_frame
	game.center_content()
	for id in (Rules.IDS if args.size()<2 else Array(args[1].split(","))):
		prepare(id)
		await capture(id,0)
		var redraws:Array[int]=[0]
		game.arena.vfx.draw.connect(func():redraws[0]+=1)
		assert(game.arena.attack(0,0,true))
		assert(game.run.tactics.reserve_ultimate(0))
		game.arena.intro_left=0
		for step in 36:
			game.arena.hit_stop=0
			game.arena._process(game.arena.tracks[0].duration/36.0+.0001)
			await capture(id,step+1)
		assert(game.arena.tracks[0].hit and not game.run.actors[0].ult_pending)
		assert(redraws[0]>=30,"Effect frames must redraw naturally during gameplay")
		print("CAPTURE ",id)
	game.get_window().size=Vector2i(540,960)
	game.get_window().content_scale_size=Vector2i(540,960)
	await process_frame
	game.center_content()
	prepare("rapunzel")
	await capture("mobile",0)
	assert(game.arena.attack(0,0,true) and game.run.tactics.reserve_ultimate(0))
	game.arena.intro_left=0
	for step in 36:
		game.arena.hit_stop=0
		game.arena._process(game.arena.tracks[0].duration/36+.0001)
		await capture("mobile",step+1)
	assert(game.arena.tracks[0].hit and game.run.actors[0].shield>0)
	print("ULT VISUAL PASS: eleven complete casts at nine enemies, PC and mobile, real impact resolution")
	game.queue_free()
	await process_frame
	quit()
func capture(id:String,step:int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(game.get_window().get_texture().get_image().save_png(destination+"/%s-%02d.png"%[id,step])==OK)
