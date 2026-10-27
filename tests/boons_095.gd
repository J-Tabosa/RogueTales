extends "res://tests/rules_095.gd"
func test() -> void:
	var run:=make(["scarlet"],0)
	var a:Dictionary=run.actors[0]
	check(R.cost(a)==90,"Pavio Curto actual90mana")
	run=make(["scarlet"],1);a=run.actors[0]
	var out:Dictionary=run.hit_enemy(0,6)
	check(out.targets.size()==3 and a.energy==30,"Fragments3 targets eachmana10")
	check(run.tactics.enemies[6].powder==1,"No naturalextra powderoncrit")
	run=make(["scarlet"],3);a=run.actors[0];a.energy=120
	run.hit_enemy(0,6)
	check(run.tactics.enemies[6].powder==2,"Scarlet finalboon doublepowder")
	run.tactics.reserve_ultimate(0);out=run.tactics.ultimate(0,6)
	check(close(out.target_damage[6],86.4),"Scarlet finalult360% with2powder")
	run=make(["alice"],0);a=run.actors[0];a.attacks=8
	run.tactics.enemies=run.tactics.enemies.slice(6,9)
	var flow:=Flow.new();flow.bind(run)
	var basics:=0;var ults:=0
	for n in 25:
		var entry:=flow.next_action()
		if entry.is_empty():continue
		if entry.side!="ally":break
		flow.begin(entry)
		if entry.get("ultimate",false):
			check(run.tactics.reserve_ultimate(0),"Alice reservation ready")
			run.tactics.ultimate(0,0);ults+=1
		else:run.hit_enemy(0,0);basics+=1
		flow.complete()
	check(basics==10 and ults==2 and a.card_charge==2,"FullHouse eightavailable=tenbasics twoUlts twocharges")
	run=make(["alice","ariel"],2);a=run.actors[0];a.hp=1
	out=R.hurt(run.tactics,a,100,0,0,true,{"id":"enemy_0"})
	check(a.hp==1 and out.get("redirect_id","")=="ariel" and a.escape_evasion,"Alice fatal swapincludesmage")
	check(a.alice_stage==0,"Alice stageflag recorded")
	R.start_turn(run.tactics,a)
	check(not a.escape_evasion,"100%evasionexpiresownturn")
	run=make(["snow_white"],1);a=run.actors[0];a.armor=100
	check(close(R.power(a,false),30),"Duro eAfiado100defense50%physical")
	run=make(["snow_white"],2);a=run.actors[0]
	check(not R.status(a,"poison","enemy_0",2,5) and R.status(a,"bubble","ariel",1),"Snow immuneharmfuldots butnotcontrols")
	run=make(["snow_white","alice"],3);a=run.actors[0];a.intercept_fail=2
	out=R.incoming(run.tactics,0,1)
	check(out.target==0 and out.guarded and a.intercept_used and a.intercept_fail==0,"Snow guaranteedthirdtry andonceuntilownturn")
	out=R.incoming(run.tactics,0,1)
	check(out.target==1,"Snow nosecondinterception")
	R.start_turn(run.tactics,a);a.intercept_fail=2
	out=R.incoming(run.tactics,0,1,true)
	check(out.target==1,"Snow neverinterceptsarea")
	run=make(["ariel","scarlet"],0);a=run.actors[0]
	for n in 50:run.hit_enemy(0,0)
	check(run.actors[0].shield>0 or run.actors[1].shield>0,"Umi overhealtofoam")
	for ally in run.actors:check(ally.shield<=ally.max_hp*.15+.001,"Foam owncap15%")
	R.status(run.tactics.enemies[0],"bubble","ariel",1)
	R.status(run.tactics.enemies[0],"bubble","ariel",1)
	var turn:=R.start_turn(run.tactics,run.tactics.enemies[0])
	check(turn.attacks==0,"Bubble removesoneattack noextraactivationroll")
	R.end_turn(run.tactics.enemies[0])
	check(not R.has_status(run.tactics.enemies[0],"bubble"),"Bubble nonstacking oneownturn")
	var mid:Dictionary=run.tactics.enemies[1]
	R.start_turn(run.tactics,mid)
	R.status(mid,"bubble","ariel",1)
	R.end_turn(mid)
	check(R.has_status(mid,"bubble"),"Bubble appliedmidturn survivesuntilnextownturn")
	turn=R.start_turn(run.tactics,mid)
	check(turn.attacks==0,"MidturnBubble consumesnextsequence")
	R.end_turn(mid)
	run=make(["rapunzel"],2);a=run.actors[0]
	R.shield(a,30,a,"silk")
	for n in 8:R.start_turn(run.tactics,a);R.end_turn(a)
	check(a.shield==30,"Silk eternalshields surviveeightturns")
	run=make(["rapunzel","scarlet"],1);a=run.actors[0];a.energy=0
	R.shield(run.actors[1],1,a,"silk")
	R.incoming(run.tactics,0,1)
	check(a.energy==10,"FiosResistentes breakgrants10")
	R.shield(run.actors[1],1,a,"silk");R.incoming(run.tactics,0,1)
	check(a.energy==10,"FiosResistentes onceperbeneficiary betweenSilkturns")
	R.shield(a,1,a,"silk")
	var hp:float=run.tactics.enemies[0].hp
	R.incoming(run.tactics,0,0)
	check(run.tactics.enemies[0].hp<hp,"Silk retaliation evenbreakinghit")
	run=make(["mulan"],2);a=run.actors[0];a.escape_evasion=true
	for n in 5:R.incoming(run.tactics,0,0)
	check(a.counter_used==3 and a.energy==0,"Mulan max3counters, nomana")
	run=make(["mulan"],3);a=run.actors[0];a.crit=1
	out=run.hit_enemy(0,0);check(close(out.damage,60),"Mulan crituseseffectbeforecharge")
	out=run.hit_enemy(0,0);check(close(out.damage,63),"Mulan nextbasicplus5points")
	run=make(["mulan"],1);a=run.actors[0];a.energy=100
	run.tactics.reserve_ultimate(0);out=run.tactics.ultimate(0,0)
	check(out.targets.size()==6 and not out.targets.has(6),"Fireworks currentandnextcolumnonly")
	run=make(["maria"],0);a=run.actors[0]
	for n in 8:run.hit_enemy(0,0)
	check(close(run.tactics.enemies[0].poison,12.5),"Gretel booncap5doses")
	run=make(["joao"],0);a=run.actors[0];run.tactics.enemies[0].armor=100
	out=run.hit_enemy(0,0)
	check(close(out.damage,20*100.0/150),"Joao ignore50%pointsnotflat")
	run=make(["joao"],2);a=run.actors[0];a.energy=80
	run.tactics.reserve_ultimate(0);run.tactics.ultimate(0,0)
	check(R.has_status(run.tactics.enemies[0],"bleed"),"Sixlandedstabs applybleed")
	run=make(["joao"],3);a=run.actors[0];a.crit=1;a.energy=80
	run.tactics.reserve_ultimate(0);out=run.tactics.ultimate(0,0)
	check(out.strikes.size()==9,"Ultcritmax3extrasnorecursion")
	run=make(["matches"],0);a=run.actors[0]
	turn=R.start_turn(run.tactics,a)
	check(turn.attacks==2,"Lume initialboon +1basic")
	run=make(["matches"],1);a=run.actors[0]
	for n in 15:run.hit_enemy(0,0)
	R.cleanse(run.tactics.enemies[0])
	check(close(run.tactics.enemies[0].burn,40),"Permanentfire cannotcleanse andcap200%")
	run=make(["aladin"],0);a=run.actors[0]
	check(close(R.power(a,true),40),"Lamp20%perwishinitial60%")
	run=make(["aladin"],1);a=run.actors[0]
	check(not R.status(a,"curse","enemy_0",2),"Aladin allnegativeimmunitywhilewishes")
	run=make(["aladin"],2);a=run.actors[0]
	check(R.wishes_left(a)==4,"Fourthfreechargecountsinpassive")
	R.wish(run,"wealth");R.wish(run,"wealth")
	check(R.wishes_left(a)==2 and a.wish_extra,"Fourthcharge repeatoneonly")
	run=make(["aladin"],3);a=run.actors[0];a.wishes=["wealth","life","death"]
	turn=R.start_turn(run.tactics,a)
	check(turn.attacks==3,"Freedgenie plus2attacks")
	run.tactics.enemies[0].magic_defense=10000
	check(close(run.hit_enemy(0,0).damage,25),"Freedgenie directrealdamage")
	run=make(["peter"],3);a=run.actors[0];a.shadows=3
	out=run.hit_enemy(0,0)
	check(close(out.damage,44),"Peter lastboonshadows75%magic45%real plusbasic")
	a.energy=70;run.tactics.reserve_ultimate(0);run.tactics.ultimate(0)
	out=run.hit_enemy(0,0)
	check(close(out.damage,53),"Peter boosted40magic15realpershadow")
	run=make(["puss"],3);a=run.actors[0];a.energy=40
	R.status(a,"curse","enemy_0",2)
	R.hurt(run.tactics,a,0,0,10000,true,{"id":"enemy_0"})
	check(close(a.hp,66) and a.energy==40 and a.statuses.is_empty() and a.resurrections==1,"Gato firstreturn100%,20%life,cleansestatusretainmana")
	# All twelve kits retain four mutually exclusive paths and exact base stats.
	for id in R.Data.BASE:
		var base:Dictionary=TaleCatalog.hero_stats(id,[0,0,0],{})
		check(close(base.max_hp,R.Data.BASE[id].hp) and R.Data.BOONS[id].size()==4,"Roster "+id)
	print("BOONS 095 ","PASS" if failures==0 else "FAIL"," · ",checks," checks · ",failures," failures")
	quit(1 if failures>0 else 0)
