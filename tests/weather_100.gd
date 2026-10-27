extends "res://tests/seasonal_ui_100.gd"
func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://weather_100_isolated.json";root.add_child(game);game.set_process(false)
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true;game.apply_window_mode();await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent;await process_frame;game.center_content()
		game.campaign=preload("res://tests/test_accounts.gd").legacy()
		for id in ["FlorestaInverno","BosqueNoturno","CamposDeGirassois","PontoVulcanico","InteriorDoMoinho"]:
			game.run=make(["matches","snow_white","rapunzel","mulan","alice"]);game.run.party_capacity=5
			for a in game.run.actors:game.run.tactics.configure_actor(a,a.row)
			game.run.journey=prefix_for(id);game.run.stage=W.NODES[id].depth-1;game.run.phase=2
			game.build_battle();game.spawn_enemy();game.arena.set_process(false);game.arena.entrance_left=0;game.arena.intro_left=0
			game.feedback.set_process(false);game.paused=false
			var atmosphere=game.arena.atmosphere;atmosphere.set_process(false);atmosphere.frozen=false
			var modes:={"snow":1,"rain":2,"sun":3,"embers":4,"none":0}
			check(atmosphere.weather_mode==modes[W.NODES[id].weather],"Appropriate weather for "+id)
			for tick in 18:atmosphere._process(.05)
			check(atmosphere.weather.visible==(atmosphere.weather_mode>0),"Indoor maps have no outdoor particles")
			await capture("weather-"+id+"-%d"%extent.x)
			var before:float=atmosphere.weather_clock
			atmosphere.frozen=true;atmosphere._process(.3);check(atmosphere.weather_clock==before,"Pause freezes climate")
			atmosphere.frozen=false;atmosphere.reduced_motion=true;atmosphere._process(.3)
			check(atmosphere.weather_clock==before,"Reduced motion holds climate still")
			game.arena.high_quality=false;atmosphere._process(.1)
			check(atmosphere.weather.material.get_shader_parameter("layers")==1,"Low quality uses one particle layer")
			atmosphere.reduced_motion=false;game.arena.high_quality=true
			if id=="PontoVulcanico":
				game.run.actors[0].energy=10000
				for foe in game.run.tactics.enemies:foe.hp=100000;foe.max_hp=100000
				check(game.run.tactics.reserve_ultimate(0) and game.arena.attack(0,0,true),"Real Lume ultimate begins")
				for tick in 100:
					game.arena._process(.05);atmosphere._process(.05)
					if atmosphere.burn_left>0:break
				check(atmosphere.burn_left>0 and atmosphere.fire.visible,"Actual ultimate impact triggers burning screen")
				atmosphere._process(.3);await capture("fire-ultimate-%d"%extent.x)
				atmosphere.blue_wave();atmosphere._process(.2)
				check(atmosphere.wave.visible and atmosphere.wave_left>0,"Umi blue wave remains available")
				for tick in 30:atmosphere._process(.05)
				check(not atmosphere.fire.visible and not atmosphere.wave.visible,"Transient screens finish and clear")
	print("WEATHER100 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	game.queue_free();quit(1 if failures else 0)
