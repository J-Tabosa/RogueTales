extends "res://tests/rules_095.gd"
const W=preload("res://scripts/world_routes.gd")
const F=preload("res://scripts/formation_layout.gd")
const E=preload("res://scripts/equipment.gd")
func reward(run:IdleRun) -> void:
	for id in run.offers:
		if id.begins_with("bonus:"):
			var bonus=R.Bonuses.parse(id)
			for a in run.actors:
				if R.Bonuses.useful(a,bonus.attribute,1):
					check(run.confirm_bonus(id,a.id,1),"Claim reward");return
		elif id.begins_with("item:") and run.apply_relic(id):return
	check(false,"Reward remains actionable")
func test() -> void:
	check(W.NODES.size()==65 and W.PATHS.size()==4,"All65 scenes and four seasons imported")
	var rng:=RandomNumberGenerator.new();rng.seed=1001
	var counts:={"spring":0,"summer":0,"autumn":0,"winter":0}
	for i in 4000:counts[W.start(rng).season]+=1
	for key in counts:check(counts[key]>850 and counts[key]<1150,"Uniform initial season")
	var textures:=0
	for id in W.NODES:
		var node:Dictionary=W.NODES[id]
		var art:=W.texture(id)
		check(art!=null and art.get_width()>=1600 and art.get_height()>=900,"HD source imported "+id)
		check(W.textures.size()<=3,"Bounded scenery cache")
		# All anchored feet map into the safe floor band, independently of aspect ratio.
		for depth in [.40,.66,.92]:
			var projected:float=lerpf(node.floor[0],node.floor[1],(depth-F.FLOOR_HORIZON)/(1-F.FLOOR_HORIZON))
			check(projected>node.floor[0] and projected<node.floor[1],"Feet inside source ground "+id)
		textures+=1
	var routes:=0;var combats:=0;var markets:=0
	for season in W.SEASONS:
		for path in W.PATHS[season]:
			var c:=preload("res://tests/test_accounts.gd").legacy()
			var run:=IdleRun.new();check(run.start_expedition(c,"scarlet","blessing:scarlet:0"),"Start real seasonal expedition")
			run.journey={"format":1,"season":season,"path":[path[0]]}
			for stage in 8:
				if stage>0:
					check(run.needs_map() and run.phase==0 and run.interlude=="route","Boss reward opens next territory")
					var before:int=run.rooms_cleared
					check(not run.choose_route("map:FlorestaInverno"),"Invalid cross-season branch rejected")
					check(run.choose_route("map:"+path[stage]) and not run.needs_map(),"Authored next map selectable")
					check(run.rooms_cleared==before and run.phase==0,"Map choice consumes no combat phase")
				check(run.map_name()==W.NODES[path[stage]].name and run.current_biome()==W.NODES[path[stage]].biome,"Terrain chooses map name and enemy ecosystem")
				for phase in 6:
					check(run.stage==stage and run.phase==phase,"Exact stage-phase index")
					if phase==4:
						check(run.route_offers==["shop","trader"] and run.choose_route("trader"),"Every X-5 offers both merchants")
						run.leave_shop();markets+=1;continue
					if run.interlude=="route":check(run.choose_route("battle"),"Required fight still available")
					run.spawn_enemy();combats+=1
					check(run.tactics.enemies.all(func(foe):return foe.biome==run.current_biome() and foe.evasion==0),"Enemies use this scene's biome, no evasion")
					check(run.tactics.enemies.size()<=ExpeditionContent.enemy_limit(stage),"Difficulty cap preserved")
					var finished:=run.clear_encounter()
					if stage==7 and phase==5:
						check(finished and run.rooms_cleared==48,"Castle of Author ends at8-6 after48phases")
						var result:=c.finish_expedition(run.to_checkpoint(),true)
						check(result.won and c.expedition_wins==1 and run.continue_endless(c),"Real victory and endless continuation")
						check(run.continuation_from==48 and run.stage==0 and W.valid(run.journey),"Endless starts new seasonal cycle preserving depth")
						continue
					check(not finished and run.pending_choice,"Combat reward retained")
					if phase==5 and not run.map_guest.is_empty() and not run.actor_ids().has(run.map_guest):check(run.offers.has("ally:"+run.map_guest),"Catalogued hero meeting guaranteed and optional")
					reward(run)
					var loaded:=IdleRun.new();loaded.restore(c,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
					if failures<2 and (loaded.journey!=run.journey or loaded.route_offers!=run.route_offers or loaded.rng.state!=run.rng.state):print("SAVE_DIFF ",stage,"/",phase," ",run.journey," > ",loaded.journey," offers ",run.route_offers," > ",loaded.route_offers," RNG ",run.rng.state," > ",loaded.rng.state)
					check(loaded.journey==run.journey and loaded.route_offers==run.route_offers and loaded.rng.state==run.rng.state,"Save preserves season, prefix, choices and RNG")
			routes+=1
	check(routes==17 and combats==680 and markets==136,"All17exactroutes40fights8shops")
	# Mythic capacity item is consumed once, never a reversible equipment stat.
	var c:=preload("res://tests/test_accounts.gd").legacy();var run:=IdleRun.new();run.start_expedition(c,"scarlet","blessing:scarlet:0")
	check(E.data("travelers_page").rarity==5,"Expansion is mythic")
	check(run.party_capacity==3 and run.grant_item("travelers_page") and run.party_capacity==4,"Mythic+1 first slot")
	run.interlude="shop";run.run_gold=5000;run.shop_stock.assign(["item:travelers_page"])
	check(run.buy_supply("item:travelers_page") and run.party_capacity==5 and run.run_gold==4450,"Shop acquisition consumes one mythic for+1")
	check(not run.buy_supply("item:travelers_page") and not run.grant_item("travelers_page") and run.party_capacity==5,"No double-use or sixth slot")
	check(not run.inventory.has("travelers_page") and not run.buy_supply("capacity") and run.capacity_cost()==-1,"Consumable never equips; old slot purchase removed")
	var loaded:=IdleRun.new();loaded.restore(c,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
	check(loaded.party_capacity==5 and loaded.capacity_relics==2,"Capacity saves without replay")
	for i in 500:
		loaded.roll_shop();check(not loaded.shop_stock.has("item:travelers_page"),"No useless mythic offered at cap")
	# Old12-stage saves complete under their original route, without loss.
	run.journey.clear();run.stage=11;run.phase=5;run.rooms_cleared=71;run.interlude=""
	loaded=IdleRun.new();loaded.restore(c,run.to_checkpoint())
	check(loaded.journey.is_empty() and loaded.world_count()==12 and loaded.stage==11,"Legacy campaign remains resumable")
	check(loaded.clear_encounter() and loaded.rooms_cleared==72,"Legacy final boss still completes")
	print("SEASONAL100 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",routes," routes · ",textures," HD scenes")
	quit(1 if failures else 0)
