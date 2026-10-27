extends "res://tests/rules_095.gd"
const G=preload("res://scripts/equipment.gd")
const E=preload("res://scripts/equipment_rules.gd")
func equip(run:IdleRun,ids:Array,index:=0) -> void:
	run.interlude="route"
	for slot in ids.size():
		check(run.grant_item(ids[slot]),"Grant "+ids[slot])
		check(run.equip_item(index,ids[slot],slot),"Equip "+ids[slot])
	E.start_combat(run.tactics)
func test() -> void:
	check(G.ITEMS.size()==27 and G.TROPHIES.size()==12,"27 general and 12 special items")
	for id in G.ITEMS.keys()+G.TROPHIES.keys().map(func(key):return "trophy_"+key):
		check(not G.data(id).get("detail","").is_empty(),"Description: "+id)
		check(ResourceLoader.exists("res://assets/items/"+id+".png"),"Icon: "+id)
	for id in ["ember_pearl","winter_match","venom_vial","hunters_lens","tower_braid","red_goblet","jade_seal"]:check(G.data(id).is_empty(),"Retired "+id)
	var run:=make(["scarlet"])
	equip(run,["whetstone","echo_bell"])
	var a:Dictionary=run.actors[0]
	R.start_turn(run.tactics,a)
	var hit:Dictionary=run.hit_enemy(0)
	check(close(hit.damage,24*1.2*1.5+24*1.2*.6*1.1),"First physical hit and 60% echo with second powder stack")
	check(a.energy==20 and a.hits==2,"Echo is full basic and grants mana")
	check(run.hit_enemy(0).strikes.size()==1,"Echo once per own turn")
	run=make(["alice"])
	equip(run,["echo_bell"])
	a=run.actors[0];R.start_turn(run.tactics,a);run.hit_enemy(0)
	check(a.card_charge==2,"Echo advances Alice deck per executed basic")
	run=make(["scarlet"])
	equip(run,["shrapnel_bag","star_powder"])
	a=run.actors[0];R.start_turn(run.tactics,a);hit=run.hit_enemy(0)
	check(hit.targets.size()==4 and a.energy==40,"Spread gives 3 distinct extra targets and per-hit mana")
	check(hit.targets.all(func(at):return run.tactics.enemies[at].powder==1),"Each spread impact applies powder once")
	run=make(["joao"])
	equip(run,["trophy_joao"])
	a=run.actors[0];a.crit=1;R.start_turn(run.tactics,a)
	run.hit_enemy(0);run.hit_enemy(0);run.hit_enemy(0)
	check(a.get("bonus_attacks",0)==1,"Sugar knife grants one attack after two critical hits")
	run=make(["rapunzel","scarlet"])
	equip(run,["enchanted_needle","world_needle"])
	a=run.actors[0]
	var ally:Dictionary=run.actors[1]
	ally.hp=100
	R.shield(ally,20,a)
	check(close(ally.shield,34) and close(ally.hp,110.2),"Shield bonuses additive, heal from actual shield once")
	check(R.effective_initiative(ally)==60,"Shield grants initiative")
	R.start_turn(run.tactics,a)
	check(R.effective_initiative(ally)==50,"Shield initiative expires at creator next turn")
	run=make(["ariel"])
	equip(run,["full_tide_shell","world_needle"])
	a=run.actors[0];a.hp=a.max_hp
	R.heal(a,100,a)
	check(close(a.shield,a.max_hp*.2),"Overheal respects own shield cap and recursion stops")
	run=make(["scarlet"])
	equip(run,["immortal_wolf_heart"])
	a=run.actors[0];var foe:Dictionary=run.tactics.enemies[0]
	R.hurt(run.tactics,a,10000,0,0,true,foe)
	check(a.hp==1 and close(a.shield,a.max_hp*.5),"Fatal heart activates before death")
	R.hurt(run.tactics,a,10000,0,0,true,foe)
	check(a.hp==0,"Fatal heart cannot protect twice per stage")
	run=make(["scarlet"])
	equip(run,["mirror_shard"])
	a=run.actors[0];foe=run.tactics.enemies[0]
	var before:float=foe.hp
	R.hurt(run.tactics,a,20,0,0,true,foe)
	check(foe.hp==before,"Mirror never reflects physical damage")
	var received:=R.hurt(run.tactics,a,0,24,0,true,foe)
	check(close(before-foe.hp,received.damage*.25),"Mirror reflects only actual magical damage")
	run=make(["scarlet","alice"])
	equip(run,["trophy_scarlet"])
	run.actors[1].row=run.actors[0].row
	check(run.tactics.choose_target(run.tactics.enemies[0],run.actors)==1,"Pelt avoids normal single-target priority")
	run=make(["scarlet"])
	equip(run,["trophy_aladin"])
	var flow:=Flow.new();flow.bind(run)
	check(flow.delay_enemy(0,0),"Sands activation")
	check(not flow.delay_enemy(0,1),"Sands only once per combat")
	check(flow.preview(20)[-1].index==0,"Delayed enemy is last without losing its turn")
	run=make(["mulan","scarlet"])
	equip(run,["trophy_mulan"])
	a=run.actors[0]
	check(not R.status(a,"bubble","enemy_0",1) and not R.status(a,"hangover","enemy_0",1),"Banner blocks attack/initiative penalties")
	a.hp=0;E.refresh_banner(run.tactics)
	check(not run.actors[1].get("gear_banner",false),"Dead banner stops protecting")
	run=make(["scarlet"])
	equip(run,["empty_lamp","blue_hourglass"])
	a=run.actors[0];a.energy=R.cost(a)
	run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0)
	check(a.energy==R.cost(a)+15,"First ult cost refunded and blue hourglass once")
	run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0)
	check(a.energy==15,"Refund does not loop")
	run=make(["scarlet"])
	equip(run,["seven_league_boots","author_quill"])
	a=run.actors[0]
	check(R.start_turn(run.tactics,a).attacks==3 and close(R.power(a,false),31.2),"Opening boots and quill attacks/power")
	run.hit_enemy(0)
	check(a.energy==25,"Quill opening mana per impact")
	R.end_turn(a)
	check(R.start_turn(run.tactics,a).attacks==1 and close(R.power(a,false),24),"Opening effects expire and do not renew each round")
	run=make(["scarlet"])
	run.tactics.enemies[0].armor=120;run.tactics.enemies[1].magic_defense=80
	equip(run,["trophy_snow_white"])
	a=run.actors[0]
	check(R.defense(a,false)==120 and R.defense(a,true)==80,"Queen mirror copies separate maximum defenses")
	run=make(["scarlet"])
	equip(run,["trophy_ariel"])
	a=run.actors[0];foe=run.tactics.enemies[6]
	R.shield(foe,200,foe)
	R.start_turn(run.tactics,a);run.hit_enemy(0)
	check(close(foe.shield,76),"Trident halves shield before 24 physical damage")
	run=make(["scarlet"])
	equip(run,["trophy_rapunzel"])
	a=run.actors[0];foe=run.tactics.enemies[6]
	R.shield(foe,90,foe);foe.shield_parts[0].turns=3
	R.start_turn(run.tactics,a);run.hit_enemy(0)
	check(a.shield==90 and a.shield_parts[0].turns==3 and foe.shield==0,"Scissors transfer shield value and remaining duration")
	run=make(["scarlet"])
	equip(run,["trophy_alice"])
	a=run.actors[0];foe=run.tactics.enemies[6]
	R.start_turn(run.tactics,a);run.hit_enemy(0)
	check(R.has_status(foe,"antiheal") and R.has_status(foe,"shield_break"),"Scepter applies both restrictions")
	R.start_turn(run.tactics,a)
	check(not R.has_status(foe,"antiheal") and not R.has_status(foe,"shield_break"),"Scepter expires at creator's next turn")
	run=make(["maria"])
	equip(run,["trophy_maria"])
	a=run.actors[0];a.hp=100;foe=run.tactics.enemies[0]
	R.shield(foe,100,foe);R.start_turn(run.tactics,a);run.hit_enemy(0)
	check(a.energy==25 and close(a.hp,118) and foe.shield==0,"Cauldron consumes remaining positive shield and grants resources")
	run=make(["scarlet"])
	equip(run,["golden_spool"])
	a=run.actors[0];a.hp=100;foe=run.tactics.enemies[0]
	R.shield(a,10,a);R.hurt(run.tactics,a,20,0,0,true,foe)
	check(close(a.hp,110) and a.energy==15,"Spool reacts after incoming shield overflow damage")
	R.shield(a,10,a);R.hurt(run.tactics,a,20,0,0,true,foe)
	check(close(a.hp,100) and a.energy==15,"Spool once per protected character between owner turns")
	run=make(["peter"])
	equip(run,["black_cat_boots","hundred_mirrors_crown"])
	a=run.actors[0];a.evasion=.8
	E.on_evade(run.tactics,a)
	check(R.start_turn(run.tactics,a).attacks==6,"Crown adds 1+4 attacks after first dodge")
	check(run.hit_enemy(0).critical,"Dodge boots guarantee next main basic critical")
	check(R.start_turn(run.tactics,a).attacks==1,"Dodge attacks consumed only once")
	run=make(["alice"])
	equip(run,["hunter_glasses","fate_scissors"])
	a=run.actors[0];a.crit+=.7
	var baseline:float=a.crit
	var account:=TaleCampaign.new();account.unlocked.assign(TaleCatalog.HEROES.keys())
	var loaded:=IdleRun.new();loaded.restore(account,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
	check(close(loaded.actors[0].crit,baseline),"Save retains raw equipped crit over 100% for reversible removal")
	loaded.interlude="route";loaded.equip_item(0,"",0);loaded.equip_item(0,"",1)
	check(close(loaded.actors[0].crit,.7),"Restore then unequip subtracts only equipment contribution")
	run=make(["scarlet"])
	a=run.actors[0];a.max_hp+=40;a.armor+=4
	run.inventory.assign(["tower_braid"])
	var previous:={a.id:{"items":["tower_braid"],"applied":{"damage":1,"interval":1,"hp":40,"armor":4}}}
	run.inventory.assign([G.migrate("tower_braid")]);run.restore_equipment(previous)
	check(a.equipment==["stone_heart"] and a.max_hp==300 and a.armor==0,"Old equipped stats removed before migration to approved replacement")
	for id in G.ITEMS:
		run=make(["scarlet"])
		a=run.actors[0];var hp:float=a.max_hp;var crit:float=a.crit;var init:float=a.initiative
		equip(run,[id]);run.equip_item(0,"",0)
		check(close(a.max_hp,hp) and close(a.crit,crit) and close(a.initiative,init),"Reversible stats "+id)
	print("EQUIPMENT OVERHAUL: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
