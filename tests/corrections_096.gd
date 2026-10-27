extends "res://tests/rules_095.gd"
const StatusArt=preload("res://scripts/status_art.gd")
const Blessings=preload("res://scripts/hero_blessings.gd")
var native_game
var destination:=""
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	native_game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func test() -> void:
	var run:=make(["scarlet"])
	var a:Dictionary=run.actors[0]
	var target:Dictionary=run.tactics.enemies[6]
	var hit:Dictionary=run.hit_enemy(0,6)
	check(close(hit.damage,24) and target.powder==1,"First basic applies its stack after damage")
	hit=run.hit_enemy(0,6)
	check(close(hit.damage,26.4) and target.powder==2,"Existing stack raises the next basic10%")
	target.powder=5
	hit=run.hit_enemy(0,6)
	check(close(hit.damage,36),"Five stacks give basic+50%")
	target.powder=10
	a.energy=120
	run.tactics.reserve_ultimate(0)
	hit=run.tactics.ultimate(0,6)
	check(close(hit.target_damage[6],72),"Ten stacks double150%ult to300%, without double-counting")
	check(target.powder==0 and not StatusArt.active(target,true).has("powder"),"Ult consumes powder and removes badge")
	target.powder=9;target.escape_evasion=true
	hit=run.hit_enemy(0,6)
	check(hit.evaded and target.powder==9,"An evaded basic adds no powder")
	target.escape_evasion=false;target.powder=10
	var other:Dictionary=run.tactics.enemies[7]
	other.powder=0
	hit=run.hit_enemy(0,7)
	check(close(hit.damage,24),"Powder bonus belongs to its target")
	check(StatusArt.active(target,true).powder==[10.0,0.0],"Powder status exposes exact stack count")
	var badge:Button=load("res://scripts/status_badge.gd").new()
	badge.configure("powder",10,0)
	check(badge.text.contains("10") and not badge.text.contains(".0"),"Badge displays integer stacks")
	check(badge.tooltip_text.contains("+100%"),"Powder tooltip explains actual damage bonus")
	badge.free()
	# The opening is deterministic across seeds and routes; later counts remain random.
	var account:=TaleCampaign.new();account.unlocked.assign(TaleCatalog.HEROES.keys())
	run=IdleRun.new();run.start_expedition(account,"scarlet","blessing:scarlet:0")
	for phase in 3:
		run.phase=phase
		for seed_value in 60:
			run.rng.seed=seed_value
			run.spawn_enemy()
			check(run.tactics.enemies.size()==phase+1,"Opening encounter1/2/3")
	for phase in [3,4]:
		run.phase=phase
		var seen:Dictionary={}
		for seed_value in 100:
			run.rng.seed=seed_value;run.spawn_enemy()
			seen[run.tactics.enemies.size()]=true
		check(seen.size()==3 and seen.has(1) and seen.has(2) and seen.has(3),"Later first-world encounters vary1to3")
	run.phase=5;run.spawn_enemy()
	check(run.tactics.enemies.size()==3 and run.tactics.enemies[0].boss,"Boss and two escorts unchanged")
	# Guarantee is an offer, preserving all other reward choices and actual recruitment history.
	for foe in run.tactics.enemies:foe.hp=0
	run.tactics.sync_totals()
	run.clear_encounter()
	check(run.reward_boss and run.stage==1 and run.phase==0 and run.offers.any(func(id):return id.begins_with("ally:")),"First boss transitions worlds with a guaranteed optional recruit")
	for seed_value in 80:
		run.rng.seed=seed_value;run.roll_run_offers()
		check(run.offers.size()==3 and run.offers.filter(func(id):return id.begins_with("ally:")).size()==1,"Solo boss always offers one recruit")
		check(run.offers.any(func(id):return id.begins_with("item:")),"Guaranteed boss item retained")
	var alternative:String=run.offers.filter(func(id):return not id.begins_with("ally:"))[0]
	check(run.apply_run_upgrade(alternative) and run.actors.size()==1 and run.drafted.is_empty(),"Player can decline the invitation")
	run.roll_run_offers()
	check(run.offers.any(func(id):return id.begins_with("ally:")),"Declining keeps guarantee at the next boss")
	var recruit_id:String=run.offers.filter(func(id):return id.begins_with("ally:"))[0].trim_prefix("ally:")
	check(run.recruit(account,recruit_id),"Accepting an offer performs recruitment")
	var with_offer:=0;var without_offer:=0
	for seed_value in 120:
		run.rng.seed=seed_value;run.roll_run_offers()
		if run.offers.any(func(id):return id.begins_with("ally:")):with_offer+=1
		else:without_offer+=1
	check(with_offer>0 and without_offer>0,"Boss returns to normal chance once somebody was recruited")
	# A fallen/replaced recruit still counts as having recruited before.
	run.actors.resize(1)
	var replay:=IdleRun.new();replay.restore(account,run.to_checkpoint())
	check(not replay.drafted.is_empty(),"Recruitment history survives save even when solo again")
	# Exact reported Alice scenario with ordinary items and the default blessing.
	run=make(["alice"] ,0);a=run.actors[0]
	run.tactics.round_number=1
	a.equipment=["ember_pearl","venom_vial"]
	hit=run.hit_enemy(0,6)
	check(a.get("boon_feats",{}).get("two_conditions",false),"Item burn+poison unlock without owning ChapeleiraMaluca")
	var earned:int=run.tactics.feedback_events.filter(func(e):return e.kind=="achievement").size()
	run.hit_enemy(0,6)
	check(earned==1 and run.tactics.feedback_events.filter(func(e):return e.kind=="achievement").size()==1,"Achievement feedback emitted once")
	a.hp=0 # The earned feat must also survive a defeat without finish_combat().
	account=TaleCampaign.new()
	Blessings.record(account,run.to_checkpoint())
	check(Blessings.unlocked(account,"blessing:alice:1"),"Unlock persists from live feat even without a victory")
	var saved_account:=TaleCampaign.new();saved_account.load_data(account.to_dict())
	check(Blessings.unlocked(saved_account,"blessing:alice:1"),"Permanent Alice unlock survives reload")
	run=make(["alice"],0);a=run.actors[0];a.equipment=["venom_vial","winter_match"]
	run.hit_enemy(0,6)
	check(a.get("boon_feats",{}).get("two_conditions",false),"Poison+slow also qualifies")
	run=make(["alice"],0);a=run.actors[0];a.equipment=["ember_pearl","venom_vial"]
	for foe in run.tactics.enemies:foe.immune_poison=true
	run.hit_enemy(0,6)
	check(not a.get("boon_feats",{}).get("two_conditions",false),"An immune condition is not credited")
	run=make(["alice"],0);a=run.actors[0];a.equipment=["venom_vial"]
	run.hit_enemy(0,6);run.hit_enemy(0,7)
	check(not a.get("boon_feats",{}).get("two_conditions",false),"Repeating one condition does not fake two different conditions")
	run.tactics.round_number+=1;a.equipment=["ember_pearl"]
	run.hit_enemy(0,6)
	check(not a.get("boon_feats",{}).get("two_conditions",false),"Conditions from separate rounds do not combine")
	# Same round number in a new encounter cannot reuse the old condition.
	run.tactics.spawn();run.tactics.round_number=0
	check(a.round_conditions.is_empty(),"New encounter resets condition-round tracking")
	for foe in run.tactics.enemies:foe.hp=10000;foe.max_hp=10000;foe.evasion=0
	run.hit_enemy(0)
	check(not a.get("boon_feats",{}).get("two_conditions",false),"No cross-encounter condition credit")
	# Native PC/mobile preview and real badge insertion/removal on the combat HUD.
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	native_game=load("res://scenes/main.tscn").instantiate()
	native_game.save_path="user://corrections096_isolated.json"
	root.add_child(native_game);native_game.set_process(false)
	native_game.campaign=TaleCampaign.new()
	native_game.campaign.window_mode="windowed";native_game.campaign.window_mode_selected=true
	native_game.apply_window_mode()
	await process_frame
	await process_frame
	native_game.run=IdleRun.new();native_game.run.start_expedition(native_game.campaign,"scarlet","blessing:scarlet:0")
	native_game.run.phase=2
	native_game.build_battle();native_game.spawn_enemy();native_game.arena.reset_effects()
	native_game.arena.entrance_left=0
	native_game.arena.intro_left=0
	native_game.arena.enemy_visible=true
	native_game.arena.frozen=true
	native_game.arena._process(0)
	for foe in native_game.run.tactics.enemies:foe.powder=10
	for extent in [Vector2i(1280,800),Vector2i(540,960)]:
		native_game.get_window().size=extent;native_game.get_window().content_scale_size=extent
		await process_frame
		native_game.center_content();native_game.arena.sync_health(native_game.run.actors)
		for widget in native_game.arena.foe_widgets:
			check(widget.badges.has("powder") and widget.badges.powder.text.contains("10"),"Enemy HUD includes powder stackbadge")
		await capture("powder-%d"%extent.x)
	native_game.run.tactics.enemies[0].powder=0
	native_game.arena.sync_health(native_game.run.actors)
	check(not native_game.arena.foe_widgets[0].badges.has("powder"),"Badge disappears when powder is consumed")
	native_game.queue_free();await process_frame
	print("CORRECTIONS 096 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	quit(1 if failures>0 else 0)
