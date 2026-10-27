extends "res://tests/rules_095.gd"
const E=preload("res://scripts/equipment.gd")
const C=preload("res://scripts/expedition_content.gd")
func account() -> TaleCampaign:
	var c:=TaleCampaign.new()
	check(c.buy_hero("scarlet"),"Buy first protagonist with welcome memories")
	return c
func choose_reward(run:IdleRun) -> void:
	for id in run.offers:
		if id.begins_with("item:"):
			check(run.apply_relic(id),"Choose item reward");return
		if id.begins_with("bonus:"):
			var b=R.Bonuses.parse(id)
			for a in run.actors:
				if R.Bonuses.useful(a,b.attribute,-1):
					check(run.confirm_bonus(id,a.id,-1),"Choose bonus reward");return
	check(false,"At least one valid reward")
func test() -> void:
	var fresh:=TaleCampaign.new()
	check(fresh.unlocked.is_empty() and fresh.party.is_empty() and fresh.gold==5000,"All heroes start locked, first purchase funded")
	check(not fresh.buy_hero("invalid") and fresh.gold==5000,"Invalid hero cannot charge")
	check(fresh.buy_hero("ariel") and fresh.gold==0 and fresh.total_spent==5000 and fresh.party==["ariel"],"One purchase charges exact5000 and equips first hero")
	check(not fresh.buy_hero("ariel") and not fresh.buy_hero("alice") and fresh.unlocked==["ariel"],"No duplicate or unaffordable unlock")
	var restored:=TaleCampaign.new();restored.load_data(JSON.parse_string(JSON.stringify(fresh.to_dict())))
	check(restored.gold==0 and restored.unlocked==["ariel"],"Purchase survives JSON without regranting welcome")
	var zero:=TaleCampaign.new();zero.load_data({"version":10,"gold":0,"unlocked":[],"party":[]})
	check(zero.unlocked.is_empty() and zero.party.is_empty() and zero.gold==0,"No implicit free Scarlet on new-format load")
	var old:=TaleCampaign.new();old.load_data({"version":9,"gold":123,"unlocked":["scarlet","alice"],"party":["alice"]})
	check(old.unlocked.has("scarlet") and old.unlocked.has("alice") and old.gold==123,"Old purchased/earned collection and balance preserved")
	var c:=account()
	c.unlock_progress.snow_white=3
	var number:=c.new_run_id()
	check(c.resolve_run({"run_id":number,"drafted":[],"unlock_stats":{}},false).is_empty() and not c.unlocked.has("snow_white"),"Feats cannot auto-unlock permanent heroes")
	c.earn_gold(5000)
	check(c.buy_hero("snow_white") and c.unlocked.has("snow_white"),"Subsequent unlock only by explicit memory purchase")
	# Umi's corrected base and signed/gear/bonus values survive migrations once.
	var run:=make(["ariel"])
	var a:Dictionary=run.actors[0]
	check(a.initiative==50 and R.effective_initiative(a)==50,"Umi base initiative50")
	run.interlude="route";run.grant_item("clockwork");check(run.equip_item(0,"clockwork",0),"Equip clock with initiative penalty")
	check(R.effective_initiative(a)==30,"Umi gear -20 applied to base50")
	var save:Dictionary=run.to_checkpoint()
	save.run_build.erase("roster_format");save.run_build.stats.ariel.initiative=-10
	var loaded:=IdleRun.new();loaded.restore(c,save)
	check(loaded.actors[0].initiative==30,"Old Umi base10 plus gear corrected by40")
	var again:=IdleRun.new();again.restore(c,JSON.parse_string(JSON.stringify(loaded.to_checkpoint())))
	check(again.actors[0].initiative==30,"Umi correction not repeated on future loads")
	# Generate actual normal/boss/secret enemies across every stage and boundary.
	run=make(["scarlet"])
	var generated:=0
	for stage in 12:
		run.stage=stage
		var limit:=3 if stage<2 else 6 if stage<6 else 9
		check(C.enemy_limit(stage)==limit,"Exact staged cap3/6/9")
		for phase in 6:
			run.phase=phase
			for seed_value in 24:
				run.rng.seed=seed_value;run.spawn_enemy();generated+=1
				if phase==4:
					check(run.tactics.enemies.is_empty(),"Market never generates a fight");continue
				check(run.tactics.enemies.size()>=1 and run.tactics.enemies.size()<=limit,"Real enemy generator respects stage ceiling")
				check(run.tactics.enemies.all(func(foe):return foe.evasion==0),"All current enemies have zero dodge")
	for id in preload("res://scripts/secret_encounters.gd").DATA:
		run.active_secret=id;run.spawn_enemy()
		check(run.tactics.enemies.size()==1 and run.tactics.enemies[0].evasion==0,"Secret enemy also has zero dodge")
	run.active_secret=""
	# A complete run has60 combats,12 shopping phases and72 completed phases.
	c=account();run=IdleRun.new();check(run.start_expedition(c,"scarlet","blessing:scarlet:0"),"Start purchased hero");run.journey.clear() # Explicit pre1.0 route migration fixture.
	var combats:=0;var markets:=0
	for stage in 12:
		for phase in 6:
			check(run.stage==stage and run.phase==phase,"Fixed stage-phase progression")
			if phase==4:
				check(run.interlude=="route" and run.route_offers==["shop","trader"],"X-5 offers only both merchants")
				check(not run.choose_route("battle"),"Cannot skip shopping phase with combat route")
				var entry:String="trader" if stage%2 else "shop"
				check(run.choose_route(entry) and run.interlude=="shop" and run.merchant_kind==entry,"Either merchant opens in same phase")
				var at_shop:Dictionary=run.to_checkpoint()
				var resumed:=IdleRun.new();resumed.restore(c,JSON.parse_string(JSON.stringify(at_shop)))
				check(resumed.phase==4 and resumed.merchant_kind==entry and resumed.shop_stock==run.shop_stock,"Save preserves shop stock and merchant type")
				var score_before:int=run.score;var kills_before:int=run.kills;var progress:int=run.rooms_cleared
				run.leave_shop();run.leave_shop()
				check(run.phase==5 and run.rooms_cleared==progress+1 and run.score==score_before and run.kills==kills_before,"Shop advances exactly once, no combat rewards")
				markets+=1;continue
			if run.interlude=="route":check(run.choose_route("battle"),"Continue mandatory combat")
			run.spawn_enemy();combats+=1
			var finished:=run.clear_encounter()
			if stage==11 and phase==5:check(finished,"Final boss completes the run");continue
			check(not finished and run.pending_choice and run.offers.size()==3,"Each combat preserves three rewards")
			choose_reward(run)
			if run.phase!=4:check(run.route_offers.has("battle") and run.route_offers.all(func(route):return route in ["battle","team_event"]),"No random merchant/elite route replaces required combats")
	check(combats==60 and markets==12 and run.rooms_cleared==72,"Exact60combats12shops72phases")
	# Team capacity purchases stop at five; replacement still works.
	run=make(["scarlet"]);run.interlude="shop";run.run_gold=10000
	check(run.grant_item("travelers_page") and run.party_capacity==4,"Capacity3to4")
	check(run.grant_item("travelers_page") and run.party_capacity==5,"Capacity4to5")
	var balance:int=run.run_gold
	check(run.capacity_cost()==-1 and not run.buy_supply("capacity") and run.run_gold==balance,"Cannot buy sixth slot or charge gold")
	for id in ["snow_white","rapunzel","joao","ariel"]:
		run.pending_choice=true;run.offers.assign(["ally:"+id]);check(run.recruit(c,id),"Recruit within five slots")
	check(run.actors.size()==5 and not run.can_recruit("mulan") and run.can_recruit("mulan",3),"Five maximum, legal substitution allowed")
	# Safe old9-member checkpoint migration keeps leader, live units and inactive records.
	run=make(["snow_white","rapunzel","puss","joao","mulan","peter","scarlet","ariel","alice"])
	run.leader="scarlet";run.party_capacity=9
	for unit in run.actors:run.tactics.configure_actor(unit,unit.row)
	run.tactics.ensure_front();run.actors[0].hp=0
	save=run.to_checkpoint();save.route_format=2;save.run_build.roster_format=10
	loaded=IdleRun.new();loaded.restore(c,JSON.parse_string(JSON.stringify(save)))
	check(loaded.actors.size()==5 and loaded.party_capacity==5 and loaded.actor_ids().has("scarlet"),"Old team capped with protagonist retained")
	check(loaded.inactive_companions.size()==4 and loaded.actors.all(func(unit):return unit.hp>0),"Living team preferred and extras archived")
	again=IdleRun.new();again.restore(c,JSON.parse_string(JSON.stringify(loaded.to_checkpoint())))
	check(again.inactive_companions.size()==4 and again.actors.size()==5,"Migration idempotent")
	# Random events remain optional without consuming/replacing the combat phase.
	run=make(["scarlet"]);run.phase=1;run.interlude="route"
	var offered:=false
	for i in 100:
		run.roll_routes()
		if run.route_offers.has("team_event"):offered=true;break
	check(offered and run.choose_route("team_event"),"Random event can be offered on combat route")
	var event_phase:int=run.phase;var progress_before:int=run.rooms_cleared
	var choice:String="leave" if run.pending_event.begins_with("secret_") else "supplies"
	check(preload("res://scripts/team_events.gd").resolve(run,choice) and run.phase==event_phase and run.rooms_cleared==progress_before,"Random event does not skip combat phase")
	print("PROGRESSION 0910 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",generated," generated positions")
	quit(1 if failures>0 else 0)
