extends "res://tests/release_ui_0910.gd"
const Phase1=preload("res://scripts/phase1_enemies.gd")
var impact_frames:Array[int]=[]

func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://phase1_visual_isolated.json"
	root.add_child(game);game.set_process(false)
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true;game.apply_window_mode()
	await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent
		await process_frame;game.center_content()
		for map in Phase1.MAPS:
			game.campaign=preload("res://tests/test_accounts.gd").legacy()
			game.run=make(["scarlet","snow_white","rapunzel","ariel","mulan"])
			game.run.party_capacity=5
			for actor in game.run.actors:game.run.tactics.configure_actor(actor,actor.row)
			game.run.tactics.ensure_front()
			game.run.journey={"format":1,"season":Phase1.MAPS[map],"path":[map]}
			game.run.stage=0;game.run.phase=2;game.run.room_kind="battle"
			game.run.spawn_enemy()
			game.build_battle();game.arena.sync_enemies();game.arena.enemy_visible=true
			game.arena.set_process(false);game.arena.entrance_left=0;game.arena.intro_left=0;game.arena.hit_stop=0
			game.arena.frozen=true;game.paused=true
			game.arena.fit_field(game.battle_viewport.size);game.arena._process(0);game.update_hud()
			check(game.arena.foes.size()==3 and game.arena.heroes.size()==5,"Real forest battle with five allies")
			for i in game.arena.foes.size():
				var model=game.arena.foes[i]
				var meta=Phase1.metadata(model.species_id)
				check(model.offset==-Vector2(meta.anchor[0],meta.anchor[1]),"Registered root anchor used")
				check(model.has_node("Hitbox"),"Scaled selection hitbox present")
			await capture(map+"-%d"%extent.x)
			game.run.phase=5;game.run.spawn_enemy();game.arena.sync_enemies()
			var boss=game.arena.foes[0]
			check(close(boss.boss_height/boss.regular_height,1.25),"Boss visual and inherited hitbox multiplier exactly1.25")
			game.arena.enemy_visible=true;game.arena._process(0)
			await capture(map+"-boss-%d"%extent.x)
	# Actual arena clock: three bear impacts on frames4/5/6; pause freezes;
	# finishing the eight frames immediately selects the static idle.
	game.run.journey={"format":1,"season":"spring","path":["FlorestaPrimavera"]}
	game.run.phase=5;game.run.spawn_enemy();game.arena.sync_enemies()
	game.arena.set_process(false);game.arena.entrance_left=0;game.arena.intro_left=0;game.arena.hit_stop=0
	game.arena.attack_warmup.busy=false;game.arena.attack_warmup.set_process(false)
	game.state="battle";game.paused=false;game.arena.frozen=false;game.arena.speed=1
	game.arena.enemy_attack_hit.connect(func(index):impact_frames.append(game.arena.foes[index].frame+1))
	check(game.arena.begin_enemy_attack(0,0),"Start real enemy animation")
	game.arena.frozen=true;game.arena._process(.2)
	check(game.arena.enemy_track.time==0,"Pause freezes attack and damage")
	game.arena.frozen=false
	for n in 17:
		game.arena.hit_stop=0
		game.arena._process(.05)
	check(impact_frames==[4,5,6],"Damage emitted on authored bear impact frames")
	check(game.arena.enemy_track.time<0 and game.arena.foes[0].animation=="boss_idle","No terminal-frame hold or animation loop")
	print("PHASE1 VISUAL: %d checks, %d failures"%[checks,failures])
	game.queue_free();quit(1 if failures else 0)
