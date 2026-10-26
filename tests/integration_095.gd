extends "res://tests/rules_095.gd"
const Blessings=preload("res://scripts/hero_blessings.gd")
var game
var destination:=""
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func test() -> void:
	# Exercise complete battle turns for every path against real world boss mechanics.
	var encounters:=0
	for id in R.Data.BASE:
		for path in 4:
			var c:=TaleCampaign.new();c.unlocked.assign(TaleCatalog.HEROES.keys())
			var run:=IdleRun.new()
			run.start_expedition(c,id,"blessing:%s:0"%id)
			run.actors[0].blessing_index=path
			if id!="scarlet":run.actors.append(run.run_actor("scarlet"))
			if id!="rapunzel":run.actors.append(run.run_actor("rapunzel"))
			for a in run.actors:run.tactics.configure_actor(a,a.row)
			run.rng.seed=9500+R.Data.BASE.keys().find(id)*4+path
			run.stage=path*3;run.phase=5
			run.spawn_enemy()
			for a in run.actors:a.max_hp*=10;a.hp=a.max_hp;a.energy=400
			var flow:=Flow.new();flow.bind(run);flow.auto_ult=true
			var actions:=0
			while run.alive() and run.enemy_hp>0 and actions<160:
				var entry:=flow.next_action()
				if entry.is_empty():continue
				flow.begin(entry)
				if entry.side=="ally":
					if entry.get("ultimate",false):
						if run.tactics.reserve_ultimate(entry.index):run.tactics.ultimate(entry.index)
					else:run.hit_enemy(entry.index)
				else:run.hit_party(entry.index)
				flow.complete()
				actions+=1
				for a in run.actors:check(is_finite(a.hp) and a.energy>=0 and a.shield>=0,"Finite battle state")
			R.finish_combat(run)
			encounters+=1
	check(encounters==48,"48 roster/path boss encounter integrations")
	# Persist achievement identity without the old twelve-room substitution.
	var run:=make(["snow_white"])
	run.actors[0].armor=100
	R.finish_combat(run)
	var c:=TaleCampaign.new();c.unlocked.assign(TaleCatalog.HEROES.keys())
	Blessings.record(c,run.to_checkpoint())
	check(Blessings.unlocked(c,"blessing:snow_white:1"),"Defense100 actualunlock")
	check(not Blessings.unlocked(c,"blessing:scarlet:1"),"Scarlet ninehitsnot12rooms")
	var snapshot:Dictionary=run.to_checkpoint()
	snapshot.leader="snow_white";snapshot.hero_ids=["snow_white","scarlet"]
	Blessings.record(c,snapshot,true)
	check(Blessings.unlocked(c,"blessing:snow_white:3") and not Blessings.unlocked(c,"blessing:scarlet:3"),"Completionboon protagonistonly")
	var restored_c:=TaleCampaign.new();restored_c.load_data(c.to_dict())
	check(Blessings.unlocked(restored_c,"blessing:snow_white:1"),"Feat survivesaccount serialization")
	# Real scene and mobile/desktop UI, using exactly the live mana and wish paths.
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://integration095_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new();game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	await process_frame
	game.run=IdleRun.new();game.run.start_expedition(game.campaign,"aladin","blessing:aladin:0")
	game.run.actors.append(game.run.run_actor("scarlet"));game.run.actors.append(game.run.run_actor("rapunzel"))
	for a in game.run.actors:game.run.tactics.configure_actor(a,a.row)
	game.build_battle();game.spawn_enemy();game.state="battle";game.paused=false;game.arena.reset_effects()
	game.run.actors[0].hp=0
	check(game.try_ultimate(0),"Aladin manualspecialbutton accessiblewhiledead")
	check(game.paused and is_instance_valid(game.overlay),"Wishchooser pausescombat")
	game.close_wishes()
	game.run.actors[0].hp=180
	for extent in [Vector2i(1280,800),Vector2i(540,960)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent
		await process_frame
		game.center_content()
		game.update_hud()
		await capture("combat-%d"%extent.x)
		game.show_character_information(2)
		await capture("silk-sheet-%d"%extent.x)
		game.close_character_information()
	game.run.interlude="shop";game.run.shop_stock.assign(["item:clockwork","item:tower_braid"])
	game.show_run_shop()
	game.show_wishes()
	await capture("wishes-mobile")
	var gold:int=game.run.run_gold
	game.perform_wish("wealth")
	check(game.run.run_gold==gold+200 and game.state=="shop","Wealthworksatmerchant")
	game.show_hero_details("alice")
	await capture("alice-details-mobile")
	game.queue_free()
	await process_frame
	print("INTEGRATION 095 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",encounters," boss encounters")
	quit(1 if failures>0 else 0)
