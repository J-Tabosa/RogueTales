extends SceneTree
const R=preload("res://scripts/combat_rules.gd")
const Flow=preload("res://scripts/battle_flow.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("test")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:
		push_error("FAIL: "+message)
		failures+=1
func close(a:float,b:float) -> bool:return absf(a-b)<.001
func make(ids:Array,blessing:=-1) -> IdleRun:
	var c:=preload("res://tests/test_accounts.gd").legacy()
	c.unlocked.assign(TaleCatalog.HEROES.keys())
	var run:=IdleRun.new()
	run.start_expedition(c,str(ids[0]),"blessing:%s:0"%ids[0])
	run.journey.clear() # Isolated legacy combat fixture; seasonal paths have their own integration suite.
	run.actors.clear()
	for id in ids:
		var a:=run.run_actor(id)
		a.blessing_index=blessing if id==ids[0] else -1
		a.crit=0.0
		a.evasion=0.0
		run.actors.append(a)
	run.enable_tactics(c)
	run.spawn_enemy()
	run.tactics.enemies.clear()
	for i in 9:
		run.tactics.enemies.append({"id":"enemy_%d"%i,"hp":10000.0,"max_hp":10000.0,"damage":20.0,"armor":0.0,"magic_defense":0.0,"evasion":0.0,"shield":0.0,"shield_parts":[],"statuses":[],"burn":0.0,"burn_left":0.0,"poison":0.0,"poison_left":0.0,"row":["front","middle","back"][i/3],"class":"vanguard","boss":false,"interval":2.0,"initiative":50.0,"attacks":1,"own_turn":0})
	run.tactics.sync_totals()
	run.rng.seed=9505
	return run
func test() -> void:
	var run:=make(["scarlet"])
	var a:Dictionary=run.actors[0]
	var foe:Dictionary=run.tactics.enemies[0]
	check(a.max_hp==200 and R.power(a,false)==24 and R.cost(a)==120,"Scarlet final base")
	foe.armor=100;foe.magic_defense=0
	check(close(R.hurt(run.tactics,foe,20,20,0,true).damage,30),"Hybrid separately mitigated once")
	check(close(R.hurt(run.tactics,foe,.1,.1,0,true).damage,1),"Hybrid single positive damage floor")
	check(R.hurt(run.tactics,foe,0,0,0,true).damage==0,"Support never causes floor damage")
	foe.evasion=1
	var dodges:=0
	for n in 500:
		if R.hurt(run.tactics,foe,0,0,1).evaded:dodges+=1
	check(dodges>300 and dodges<480,"Real direct damage can evade, ordinary cap80")
	foe.evasion=0;foe.armor=0
	foe=run.tactics.enemies[6]
	for n in 12:run.hit_enemy(0,0)
	check(a.energy==120 and foe.powder==10 and foe.hp>9000,"Powder caps10 and never autoexplodes; mana120")
	a.energy=155
	check(run.tactics.reserve_ultimate(0),"Scarlet may reserve")
	check(a.energy==35,"Mana surplus retained")
	var hit:Dictionary=run.tactics.ultimate(0,0)
	check(close(hit.target_damage[6],72) and foe.powder==0,"Physical300% powder consumed")
	check(a.energy==35,"Ult does not generate mana")
	run.tick_status(100)
	check(a.energy==35,"No real-time regeneration")
	run=make(["alice"])
	a=run.actors[0];foe=run.tactics.enemies[0]
	var initial_gold:int=run.run_gold
	hit=run.hit_enemy(0,0)
	check(close(hit.damage,20) and run.run_gold==initial_gold+5,"Alice hybrid + diamond economy")
	for n in 7:run.hit_enemy(0,0)
	check(a.card_charge==8 and a.energy==0,"Alice nontruncated eight basics")
	run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0)
	run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0)
	check(a.card_charge==0,"Alice two ultimates from eight basics")
	run=make(["snow_white"])
	a=run.actors[0];foe=run.tactics.enemies[0]
	foe.shield=30
	hit=run.hit_enemy(0,0)
	check(close(hit.damage,10) and close(hit.strikes[0].damage,10) and foe.shield==0,"Snow shield-only extra cannot spill toHP")
	check(a.max_hp==300 and a.armor==10 and a.magic_defense==5,"Snow tank stats")
	run=make(["rapunzel","scarlet","ariel"],0)
	a=run.actors[0]
	var health:float=run.tactics.enemies[0].hp
	hit=run.hit_enemy(0,0)
	check(hit.non_attack and run.tactics.enemies[0].hp==health,"Silk basic non offensive")
	check(run.actors.all(func(x):return x.shield==15),"Double braid self plus2")
	a.energy=100;run.tactics.reserve_ultimate(0);hit=run.tactics.ultimate(0)
	check(run.actors[1].shield==45 and close(R.defense(run.actors[1],true),4.5),"Silk ult shield30 +4.5points")
	for n in 20:R.shield(run.actors[1],15,a,"silk")
	check(close(run.actors[1].shield,60),"Silk ownsource cap30%")
	R.start_turn(run.tactics,a)
	check(a.energy==20,"Silk only20 atownturn")
	run=make(["mulan"])
	a=run.actors[0]
	hit=run.hit_enemy(0,0);check(close(hit.damage,30),"Mulan basic100%")
	run.hit_enemy(0,0);hit=run.hit_enemy(0,0)
	check(close(hit.damage,45),"Mulan thirdbasic150%")
	a.energy=100;run.tactics.reserve_ultimate(0);hit=run.tactics.ultimate(0,4)
	check(hit.targets==[3,4,5] and close(hit.target_damage[3],75),"Mulan chosen column250%")
	run=make(["maria"])
	a=run.actors[0];foe=run.tactics.enemies[0]
	for n in 5:run.hit_enemy(0,0)
	check(close(foe.poison,7.5),"Gretel natural3 doses")
	var hp:float=foe.hp
	R.start_turn(run.tactics,foe)
	check(close(hp-foe.hp,7.5),"Poison real atstart ownturn")
	R.end_turn(foe);R.start_turn(run.tactics,foe);R.end_turn(foe)
	check(foe.poison==0,"Poison expires after2 beneficiaryturns")
	run=make(["joao"])
	a=run.actors[0]
	check(run.hit_enemy(0,0).damage==20 and run.hit_enemy(0,0).damage==24,"Joao markfirst20 next24")
	a.energy=80;run.tactics.reserve_ultimate(0);hit=run.tactics.ultimate(0,0)
	check(hit.strikes.size()==6 and close(hit.damage,84) and a.energy==0,"Joao sixindependent70% no mana")
	run=make(["matches"])
	a=run.actors[0];foe=run.tactics.enemies[0]
	hit=run.hit_enemy(0,0)
	check(hit.damage==10 and foe.burn==20,"Lume spark50 andfire100")
	for n in 8:run.hit_enemy(0,0)
	check(close(foe.burn,30),"Lume intensity cap150%")
	var saved_hp:float=foe.hp
	run.tick_status(10)
	check(close(foe.hp,saved_hp),"Dots never tick realtime")
	foe.immune_burn=true
	R.cleanse(foe);R.ignite(a,foe)
	check(foe.burn==0,"Fire immunity respected")
	run=make(["aladin","scarlet"])
	a=run.actors[0]
	check(close(R.power(a,true),32.5),"Aladin threewishes30%")
	foe=run.tactics.enemies[0];foe.boss=true;foe.armor=0
	hit=R.wish(run,"death")
	check(close(hit.target_damage[0],325),"Deathwish snapshots damage before spending")
	check(run.tactics.enemies.slice(1).all(func(x):return x.hp==0),"Deathwish eliminates normals")
	check(close(R.power(a,true),30),"Afterwish20% passive")
	a.hp=0;run.actors[1].hp=0
	hit=R.wish(run,"life")
	check(a.hp==a.max_hp and run.actors[1].hp==run.actors[1].max_hp,"Wish life available whiledead")
	var gold:int=run.run_gold;run.stage=2
	R.wish(run,"wealth")
	check(run.run_gold==gold+600 and R.wishes_left(a)==0,"Wealth200xstage, oneuseeach")
	check(R.wish(run,"wealth").is_empty(),"Spentwish cannotrepeat")
	run=make(["peter"])
	a=run.actors[0];a.shadows=3
	hit=run.hit_enemy(0,0)
	check(close(hit.damage,29) and a.shadows==3,"Peter shadows15% each notconsumed")
	var before:float=a.hp
	hit=run.hit_party(0)
	check(close(before-a.hp,20) and a.shadows==2,"Peter directhit removes shadow butdoesnotblock")
	a.energy=70;run.tactics.reserve_ultimate(0);run.tactics.ultimate(0)
	hit=run.hit_enemy(0,0)
	check(close(hit.damage,38) and a.shadows==3,"Peter ult fills3 shadows30%")
	run=make(["puss"])
	a=run.actors[0];a.hp=a.max_hp*.5
	check(close(R.power(a,false),45),"Gato missing percent50 gives45")
	a.hp=a.max_hp*.25
	check(close(R.power(a,false),52.5),"Gato missing percent75 gives52.5")
	run=make(["puss"],1)
	a=run.actors[0]
	R.hurt(run.tactics,a,0,0,10000,true,{"id":"enemy_0"})
	check(a.hp==1 and a.immortal_turns==1,"Gato survive1PV")
	R.hurt(run.tactics,a,0,0,10000,true,{"id":"enemy_0"})
	check(a.hp==1,"Gato protected untilownturn")
	R.start_turn(run.tactics,a)
	R.hurt(run.tactics,a,0,0,10000,true,{"id":"enemy_0"})
	check(a.hp==0,"Protection expiresownturn")
	run=make(["scarlet","ariel","mulan"])
	run.tactics.enemies.clear()
	var flow:=Flow.new();flow.bind(run)
	check(flow.order[0].index==0 and flow.order[1].index==1 and flow.order[2].index==2,"Umi50 ties ordered stably by party index")
	run.actors[0].attacks=3
	var entry:=flow.next_action()
	flow.begin(entry);flow.complete()
	entry=flow.next_action()
	check(entry.index==0 and flow.remaining==2,"Sequential basics samenonconsumedturn")
	R.status(run.actors[2],"hangover","ariel",1)
	var round_before:int=flow.round_number
	for n in 15:
		entry=flow.next_action()
		if entry.is_empty():continue
		flow.begin(entry);flow.complete()
		if flow.round_number>round_before:break
	check(flow.round_number>round_before,"All actorsfinish before nextround")
	# Resource/state ownership across checkpoints and combat boundaries.
	run=make(["aladin","rapunzel","peter"])
	run.actors[0].wishes=["wealth"]
	run.actors[2].shadows=2
	R.shield(run.actors[1],20,run.actors[1],"silk")
	run.actors[1].shield_parts[0].turns=3
	var c:=preload("res://tests/test_accounts.gd").legacy();c.unlocked.assign(TaleCatalog.HEROES.keys())
	var restored:=IdleRun.new();restored.restore(c,run.to_checkpoint())
	check(restored.actors[0].wishes==["wealth"] and restored.actors[2].shadows==2,"Checkpoint wishes/shadows")
	check(restored.actors[1].shield_parts[0].turns==3,"Checkpoint individual shieldremainingturns")
	print("RULES 095 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",failures," failures")
	quit(1 if failures>0 else 0)
