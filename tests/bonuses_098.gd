extends "res://tests/rules_095.gd"
const B=preload("res://scripts/run_bonuses.gd")
var serial:=1000
func grant(run:IdleRun,key:String,rank:=5,mode:="unique",target:="",sign:=1) -> bool:
	serial+=1
	var id:="bonus:%d:%s:%s:%d"%[serial,key,mode,rank]
	run.offers.assign([id]);run.pending_choice=true;run.interlude="reward"
	return run.confirm_bonus(id,str(run.actors[0].id) if target.is_empty() else target,sign)
func test() -> void:
	check(B.WEIGHTS.reduce(func(a,b):return a+b,0)==100,"Rarity weights total100")
	check(B.MODE_WEIGHTS==[70,30],"Independent70/30mode weights")
	var unique:={"magic_damage":[5,8,12,16,20,25],"physical_damage":[5,8,12,16,20,25],"physical_defense":[8,12,17,23,29,35],"magic_defense":[8,12,17,23,29,35],"attacks":[0,0,1,1,2,3],"mana_hit":[5,7,10,13,16,20],"mana_turn":[2,3,4,6,8,10],"max_hp":[20,30,45,60,80,100],"crit":[10,15,20,30,40,50],"crit_multiplier":[5,10,20,30,40,50],"evasion":[5,7,10,13,16,20],"initiative":[5,8,12,16,20,25],"healing":[5,8,12,16,20,25],"spread":[0,0,1,1,2,3]}
	var group:={"magic_damage":[3,4,6,8,10,13],"physical_damage":[3,4,6,8,10,13],"physical_defense":[4,6,9,12,15,18],"magic_defense":[4,6,9,12,15,18],"attacks":[0,0,0,0,1,1],"mana_hit":[3,4,5,7,8,10],"mana_turn":[1,2,2,3,4,5],"max_hp":[10,15,23,30,40,50],"crit":[5,8,10,15,20,25],"crit_multiplier":[3,5,10,15,20,25],"evasion":[3,4,5,7,8,10],"initiative":[3,4,6,8,10,13],"healing":[3,4,6,8,10,13]}
	check(B.UNIQUE==unique and B.GROUP==group,"All exact approved tables")
	check(B.COLORS==["858b94","50b86a","5097ee","ac6bef","ef9c39","ee5555"],"Gray green blue purple orange red")
	for mode in ["unique","group"]:
		var table:Dictionary=unique if mode=="unique" else group
		for key in table:
			for rank in 6:
				var b:=B.parse("bonus:1:%s:%s:%d"%[key,mode,rank])
				check(b.is_empty() if int(table[key][rank])==0 or key=="spread" else b.magnitude==table[key][rank],"Exact existing combinations, disabled spread")
	for invalid in ["bonus:1:spread:group:5","bonus:1:spread:unique:5","bonus:1:shield:unique:5","bonus:0:max_hp:group:0","bonus:1:crit:unique:6","bonus:1:crit:wrong:0"]:check(B.parse(invalid).is_empty(),"Reject invalid bonus")
	var run:=make(["scarlet","ariel","rapunzel"])
	run.rng.seed=9808
	var ranks:=[0,0,0,0,0,0]
	var groups:=0
	for i in 12000:
		var id:=B.roll(run)
		var b:=B.parse(id)
		check(not b.is_empty() and b.attribute!="spread" and not B.attributes(run.actors,b.mode,b.rarity).is_empty(),"Draw valid and useful")
		ranks[b.rarity]+=1
		if b.mode=="group":groups+=1
	for i in 6:check(absf(float(ranks[i])/12000-B.WEIGHTS[i]/100.0)<.015,"Observed deterministic rarity distribution")
	check(absf(groups/12000.0-.3)<.02,"Observed mode distribution independent of rarity")
	var empty:=IdleRun.new();empty.rng.seed=1
	check(B.roll(empty).is_empty(),"Empty team bounded no-reroll failure")
	# Individual application, additive damage and valid receiver selection.
	run=make(["scarlet","ariel"])
	var a:Dictionary=run.actors[0]
	a.physical_damage=20
	check(grant(run,"physical_damage") and grant(run,"physical_damage"),"Repeatable individual acquisition")
	check(close(R.power(a,false),30) and close(R.power(run.actors[1],false),0),"25+25 additive, zero stays zero, other unit unaffected")
	check(a.physical_damage==20 and B.total(a,"physical_damage")==.5,"Base independent from bonus totals")
	check(not grant(run,"magic_damage",5,"unique","scarlet"),"Zero magic recipient excluded")
	var pending:String=run.offers[0]
	check(run.pending_choice and run.offers.has(pending),"Invalid confirmation consumes nothing")
	check(not run.apply_relic(pending) and not run.add_upgrade(pending),"Legacy paths cannot bypass confirmation")
	var c:=TaleCampaign.new();c.unlocked.assign(TaleCatalog.HEROES.keys())
	# Group once per actor, future recruit once, no heal duplication on JSON save cycles.
	run=make(["scarlet","snow_white"]);a=run.actors[0]
	a.hp=50;run.actors[1].hp=0
	check(grant(run,"max_hp",5,"group"),"GroupHP acquisition")
	check(a.max_hp==250 and a.hp==100 and run.actors[1].max_hp==350 and run.actors[1].hp==0,"Preserve missingHP and dead stay dead")
	B.recruit(run,a);B.recruit(run,a)
	check(a.hp==100 and a.max_hp==250,"Same group acquisition idempotent")
	run.offers.assign(["ally:ariel"]);run.pending_choice=true
	check(run.recruit(c,"ariel"),"Real recruit receives group")
	var recruited:Dictionary=run.actors[2]
	check(recruited.max_hp==float(R.Data.BASE.ariel.hp)+50 and recruited.hp==recruited.max_hp,"Future recruit groupHP once")
	for cycle in 3:
		var checkpoint:Dictionary=JSON.parse_string(JSON.stringify(run.to_checkpoint()))
		var loaded:=IdleRun.new();loaded.restore(c,checkpoint);run=loaded
		check(run.actors[0].hp==100 and run.actors[0].max_hp==250 and run.actors[1].hp==0,"Load does not repeat HP or revive")
		B.recruit(run,run.actors[0])
		check(run.actors[0].max_hp==250 and run.bonus_history.size()==1,"Ledger survives JSON restoration")
	check(grant(run,"max_hp",0,"unique","snow_white") and run.actors[1].hp==0 and run.actors[1].max_hp==370,"Dead eligible unique without resurrection")
	# Separate accumulators remain through equipment changes.
	run=make(["scarlet"]);a=run.actors[0]
	grant(run,"physical_damage");grant(run,"max_hp",0)
	run.interlude="shop";run.inventory.assign(["whetstone","stone_heart"])
	var power_before:=R.power(a,false)
	var hp_before:float=a.hp
	for cycle in 3:
		check(run.equip_item(0,"whetstone",0),"Equip damage multiplier")
		check(close(R.power(a,false),power_before+24*.2),"Gear order preserved")
		check(run.equip_item(0,"stone_heart",0) and a.max_hp==320,"HPgear separate")
		check(run.equip_item(0,"",0) and close(R.power(a,false),power_before) and a.hp==hp_before and a.max_hp==220,"Unequip no bonus replay")
	# Cap previews and absolute critical multiplier.
	run=make(["peter","scarlet"]);a=run.actors[0];a.crit=.15
	check(grant(run,"crit_multiplier") and close(B.critical_multiplier(a),3.5),"Peter3 becomes3.5, not4.5")
	a.crit=.95
	var b:=B.parse("bonus:9:crit:unique:5")
	check(close(B.preview(a,b,1).gain,5),"Critical partial cap preview in pp")
	check(grant(run,"crit") and B.chance(a)==1 and not B.useful(a,"crit"),"Crit cap100 and exclude useless")
	check(grant(run,"crit_multiplier") and close(B.critical_multiplier(a),4),"Crit damage no artificial cap")
	a.evasion=.75;b=B.parse("bonus:10:evasion:unique:5")
	check(close(B.preview(a,b,1).after,80) and close(B.preview(a,b,1).gain,5),"75+20 evasion effectivegain5")
	check(grant(run,"evasion") and B.evasion(a)==.8 and not B.useful(a,"evasion"),"Evasion80 cap")
	a.escape_evasion=true
	check(R.hurt(run.tactics,a,100,0).evaded,"Alice temporary100 remains independent")
	# Initiative signed, group one direction, capped each, status penalties below zero.
	run=make(["scarlet","snow_white"]);a=run.actors[0]
	a.initiative=10;run.actors[1].initiative=100
	b=B.parse("bonus:11:initiative:unique:5")
	check(B.preview(a,b,-1).after==-15,"Preview negative initiative")
	check(grant(run,"initiative",5,"unique","scarlet",-1) and R.effective_initiative(a)==-15,"Negative initiative no zero floor")
	check(grant(run,"initiative",5,"group","",-1) and R.effective_initiative(a)==-28 and R.effective_initiative(run.actors[1])==87,"Single sign for group")
	R.status(a,"hangover","test",1)
	check(R.effective_initiative(a)==-48,"Old reduction also below zero")
	a.initiative=-100
	var loaded:=IdleRun.new();loaded.restore(c,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
	check(loaded.actors[0].initiative==-100 and R.effective_initiative(loaded.actors[0])==-158,"Signed raw and aggregate survive save")
	var flow:=Flow.new();flow.bind(loaded)
	check(flow.order.back().side=="ally" and flow.order.back().index==0,"Negative initiative acts last")
	run=make(["scarlet"]);a=run.actors[0];a.initiative=100
	check(B.useful(a,"initiative") and not B.useful(a,"initiative",1) and B.useful(a,"initiative",-1),"All capped still allows negative option")
	check(not grant(run,"initiative",0,"unique","",0),"Direction must be explicit")
	# Defense absolute, correct mitigation.
	run=make(["snow_white"]);a=run.actors[0]
	check(grant(run,"physical_defense") and close(R.defense(a,false),45),"10def+35points=45")
	check(close(R.hurt(run.tactics,a,100,0,0,true).damage,10000.0/145),"Rational defense formula")
	check(grant(run,"magic_defense") and close(R.defense(a,true),40),"Separate magicdef points")
	# Healing is source-produced and antiheal follows the increase.
	run=make(["ariel","scarlet"]);a=run.actors[0]
	var target:Dictionary=run.actors[1];target.hp=50
	check(grant(run,"healing") and grant(run,"healing"),"Healing stacks additively")
	check(close(R.heal(target,20,a).healed,30),"Produced20 with50%=30")
	R.status(target,"antiheal","test",2)
	check(close(R.heal(target,20,a).healed,15),"Antiheal after produced boost")
	a.hp=50
	check(close(R.heal(a,20,target).healed,20),"Receiving heal doesn't use recipient multiplier")
	check(not B.compatible(target,"healing") and B.compatible(a,"healing"),"No cosmetic heal option")
	var silk:=run.run_actor("rapunzel");var lume:=run.run_actor("matches")
	check(not B.compatible(silk,"healing") and B.compatible(silk,"magic_damage"),"Silk supports magic retaliation/shield, not healing")
	lume.blessing_index=2
	check(B.compatible(lume,"healing"),"Lume path healing eligible")
	target.leech=4
	check(B.compatible(target,"healing"),"Compatible gear/legacy healing source")
	run=make(["ariel","scarlet"],0);a=run.actors[0];target=run.actors[1]
	grant(run,"healing");target.hp=target.max_hp
	run.hit_enemy(0,0)
	var foam:=0.0
	for ally in run.actors:
		foam+=float(ally.shield)
		check(ally.shield<=ally.max_hp*.15,"Umi per-target foam cap")
	check(close(foam,R.power(a,true)*.15*1.25*3),"Umi boosted produced overflow")
	# Mana per eligible impact / per ownturn. Counter, shadows and ult exceptions.
	run=make(["alice","aladin","rapunzel","ariel","joao","mulan","peter"])
	for i in [0,1]:check(not B.compatible(run.actors[i],"mana_hit") and not B.compatible(run.actors[i],"mana_turn"),"No-mana heroes excluded")
	check(not B.compatible(run.actors[2],"mana_hit") and B.compatible(run.actors[2],"mana_turn"),"Silk only manaTurn")
	check(grant(run,"mana_hit",5,"group"),"Group mana skips incompatible")
	check(B.total(run.actors[0],"mana_hit")==0 and B.total(run.actors[2],"mana_hit")==0,"Incompatible ignored")
	a=run.actors[3];run.hit_enemy(3,0)
	check(a.energy==3*(float(a.mana_hit)+10),"Umi three eligible targets each grant bonus mana")
	var mana_before:float=a.energy
	R.start_turn(run.tactics,a);run.tick_status(20)
	check(a.energy==mana_before+float(a.mana_turn),"No timed regeneration")
	grant(run,"mana_turn",5,"unique","rapunzel");a=run.actors[2]
	R.start_turn(run.tactics,a)
	check(a.energy==float(a.mana_turn)+10,"Silk gains bonus once at own start")
	mana_before=a.energy;run.hit_enemy(2,0)
	check(a.energy==mana_before,"Silk basic no mana hit")
	a=run.actors[4];a.energy=80;run.tactics.reserve_ultimate(4);run.tactics.ultimate(4,0)
	check(a.energy==0,"Joao ult six thrusts excluded mana")
	a=run.actors[6];a.shadows=3;run.hit_enemy(6,0)
	check(a.energy==float(a.mana_hit)+10,"Peter shadows excluded mana")
	a=run.actors[5];mana_before=a.energy
	a.evasion=1;R.incoming(run.tactics,0,5)
	check(a.energy==mana_before,"Mulan retaliation excluded mana")
	# Extra full basics and interleaved ults use live battle scheduler.
	run=make(["scarlet"]);a=run.actors[0];a.energy=110;a.initiative=100
	check(grant(run,"attacks",5) and B.attacks(a)==4,"Mythic+3 full basics")
	flow=Flow.new();flow.bind(run);flow.auto_ult=true
	var entry:=flow.next_action();flow.begin(entry);run.hit_enemy(0,0);flow.complete()
	entry=flow.next_action()
	check(entry.get("ultimate",false),"Mana ult interleaves after first added basic")
	flow.begin(entry);run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0);flow.complete()
	check(flow.remaining==3 and not flow.next_action().get("ultimate",false),"ULT preserves remaining three basics")
	# Shop confirmation charges once, preview/cancel changes nothing.
	run=make(["scarlet"]);run.interlude="shop";run.run_gold=100
	var shop_id:="bonus:60:max_hp:unique:0"
	run.shop_stock.assign([shop_id])
	check(not run.buy_supply(shop_id) and run.run_gold==100,"Shop requires same explicit confirmation")
	check(run.confirm_bonus(shop_id,"scarlet",1,"shop") and run.run_gold==68,"Atomic charge and application")
	check(not run.confirm_bonus(shop_id,"scarlet",1,"shop") and run.run_gold==68 and run.actors[0].max_hp==220,"No doublebuy")
	# Legacy migration preserves all original values, no arbitrary conversion.
	run=make(["scarlet"]);run.apply_relic("power");run.apply_relic("heart");run.actors[0].hp=71
	var legacy:Dictionary=run.to_checkpoint();legacy.erase("bonuses")
	loaded=IdleRun.new();loaded.restore(c,JSON.parse_string(JSON.stringify(legacy)))
	check(loaded.bonus_history.is_empty() and loaded.relics.has("power") and loaded.relics.has("heart"),"Legacy effects explicitly retained without conversion")
	check(close(R.power(loaded.actors[0],false),R.power(run.actors[0],false)) and loaded.actors[0].hp==71 and loaded.actors[0].max_hp==225,"Legacy damage/hp exact")
	# Rates remain one screen draw for recruit/item, always three options.
	run=make(["scarlet"])
	for i in 300:
		run.roll_run_offers()
		check(run.offers.size()==3,"Three reward options")
		for id in run.offers:check(id.begins_with("bonus:") or id.begins_with("item:") or id.begins_with("ally:"),"No newly rolled legacy relics")
	print("BONUSES 098 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	quit(1 if failures>0 else 0)
