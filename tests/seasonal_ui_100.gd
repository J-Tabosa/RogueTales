extends "res://tests/release_ui_0910.gd"
const W=preload("res://scripts/world_routes.gd")
const F=preload("res://scripts/formation_layout.gd")
func prefix_for(id:String) -> Dictionary:
	for season in W.SEASONS:
		for route in W.PATHS[season]:
			if route.has(id):return {"format":1,"season":season,"path":route.slice(0,route.find(id)+1)}
	return {}
func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://seasonal_ui_100_isolated.json"
	root.add_child(game);game.set_process(false)
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true;game.apply_window_mode()
	await process_frame
	var scenes:=0
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent;await process_frame;game.center_content()
		game.campaign=preload("res://tests/test_accounts.gd").legacy()
		game.run=make(["snow_white","rapunzel","mulan","alice","ariel"])
		game.run.party_capacity=5
		for actor in game.run.actors:game.run.tactics.configure_actor(actor,actor.row)
		for id in W.NODES:
			game.run.journey=prefix_for(id);game.run.stage=W.NODES[id].depth-1;game.run.phase=2;game.run.interlude=""
			# Visual stress fixture: every map gets all14 units, even early maps capped below9 during play.
			for i in 9:
				var foe:Dictionary=game.run.tactics.enemies[i]
				foe["biome"]=W.NODES[id].biome;foe["variant"]=i%6;foe["interval"]=3.0;foe["name"]="Teste de terreno";foe.row=["front","middle","back"][i/3]
			game.build_battle();game.arena.sync_enemies();game.arena.enemy_visible=true
			game.arena.entrance_left=0;game.arena.intro_left=0;game.arena.frozen=true;game.paused=true
			game.arena.fit_field(game.battle_viewport.size);game.update_hud();await process_frame
			check(game.arena.heroes.size()==5 and game.arena.foes.size()==9,"All14 units on "+id)
			check(game.arena.backdrop.texture.resource_path==W.NODES[id].texture,"Correct HD scenario "+id)
			for model in game.arena.heroes+game.arena.foes:
				var feet:Vector2=model.position/Vector2(game.arena.field_width,game.arena.field_height)
				check(feet.y>=.40-.001 and feet.y<=.92+.001 and feet.x>.05 and feet.x<.95,"Anchored feet within projected ground on "+id)
			check(is_equal_approx(game.arena.backdrop.material.get_shader_parameter("ground_start"),W.NODES[id].floor[0]),"Per-map safe floor configured")
			if id in ["FlorestaPrimavera","FlorestaVerao","FlorestaOutono","FlorestaInverno","NavioPirata","Oceano","PontoVulcanico","CasteloDoAutor","Cume"]:await capture(id+"-%d"%extent.x)
			scenes+=1
		# Actual pointer/touch choice from a legal split; saved route retains selected map.
		game.run.journey={"format":1,"season":"spring","path":["FlorestaPrimavera"]}
		game.run.stage=1;game.run.phase=0;game.run.pending_choice=false;game.run.interlude="route";game.run.roll_routes()
		game.build_battle()
		game.show_routes();await process_frame
		var buttons:=descendants(game.overlay).filter(func(n):return n is Button and n.has_meta("map_choice"))
		check(buttons.size()==2,"Only legal forest branches rendered")
		await capture("map-choice-%d"%extent.x)
		var wanted:Button=buttons.filter(func(n):return n.get_meta("map_choice")=="Pomar")[0]
		await click(wanted,Vector2(280,50),extent.x==540)
		check(game.run.journey.path==["FlorestaPrimavera","Pomar"] and game.state=="route","Touch/click selects legal map without skipping combat")
		check(game.campaign.checkpoint.journey.path==game.run.journey.path,"Selected route checkpoint saved")
		game.run.actors.pop_back()
		game.run.interlude="shop";game.run.shop_stock.assign(["item:travelers_page"]);game.run.shop_bought.clear();game.run.party_capacity=4;game.run.run_gold=1000
		game.show_run_shop();await process_frame
		var item:Button=descendants(game.page).filter(func(n):return n is Button and n.get_meta("shop_item","")=="item:travelers_page")[0]
		await capture("mythic-page-%d"%extent.x)
		await click(item,Vector2(230,45),extent.x==540)
		check(game.run.party_capacity==5 and game.run.run_gold==450,"Actual mythic purchase adds exactly one slot")
		check(not game.run.inventory.has("travelers_page"),"Mythic consumes itself and never occupies gear slot")
	print("SEASONAL UI100 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",scenes," full14-unit scenes")
	game.queue_free()
	quit(1 if failures else 0)
