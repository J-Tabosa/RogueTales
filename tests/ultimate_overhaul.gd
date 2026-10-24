extends SceneTree
const Rules=preload("res://scripts/ultimate_rules.gd")
const VFX=preload("res://scripts/ultimate_vfx.gd")
const Abilities=preload("res://scripts/hero_abilities.gd")
func _initialize() -> void:call_deferred("checks")
func fixture(ids:Array) -> IdleRun:
	var account:=TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run:=IdleRun.new()
	assert(run.start_expedition(account,ids[0],"vigor"))
	run.party_capacity=9
	for id in ids.slice(1):
		run.pending_choice=true
		run.offers.assign(["ally:"+id,"heart","power"])
		assert(run.recruit(account,id))
	run.stage=3
	run.spawn_enemy()
	while run.tactics.enemies.size()<9:
		var foe:Dictionary=run.tactics.enemies[0].duplicate(true)
		foe.slot=run.tactics.enemies.size()
		run.tactics.enemies.append(foe)
	for at in 9:
		var foe:Dictionary=run.tactics.enemies[at]
		foe.row=["front","middle","back"][at/3]
		foe["class"]=["vanguard","assassin","mage"][at/3]
		foe.hp=100000.0
		foe.max_hp=100000.0
		foe.armor=0.0
		foe.evasion=0.0
		foe.damage=40.0
		foe.pp=0
	for actor in run.actors:
		actor.evasion=0.0
		actor.crit=0.0
		actor.pp=0
		actor.armor=0.0
	return run
func cast(run:IdleRun,index:=0,target:=0) -> Dictionary:
	var actor:Dictionary=run.actors[index]
	if actor.id=="alice":actor.card_charge=4
	else:actor.energy=100
	assert(run.tactics.reserve_ultimate(index))
	assert(not run.tactics.reserve_ultimate(index))
	var hit:Dictionary=run.tactics.ultimate(index,target)
	assert(not hit.is_empty() and run.tactics.ultimate(index,target).is_empty())
	return hit
func checks() -> void:
	for id in Rules.IDS:
		var model=load("res://scenes/heroes/%s.tscn"%id).instantiate()
		assert(model.sprite_frames.get_frame_count("idle")==8)
		assert(model.sprite_frames.get_frame_count("attack")==12)
		assert(model.sprite_frames.get_frame_count("ultimate")==12)
		assert(VFX.frame(id,0)!=VFX.frame(id,.9))
		model.free()
	for id in ["scarlet","ariel","matches"]:
		var run:=fixture([id])
		var result:=cast(run)
		assert(result.targets.size()==9 and result.damage>0)
		for foe in run.tactics.enemies:
			assert(foe.hp<foe.max_hp)
			if id=="matches":assert(foe.burn_left==6 and foe.burn>0)
	var run:=fixture(["aladin"])
	var original:float=run.tactics.enemies[0].hp
	var asleep:=0
	for trial in 100:
		var result:=cast(run)
		assert(result.damage==0)
		asleep+=result.status_targets.size()
	assert(asleep>350 and asleep<550,"Sleep rolls must be independent, near 50% per target")
	assert(run.tactics.enemies[0].hp==original)
	run.tactics.enemies[0].sleep_turns=1
	var before:float=run.actors[0].hp
	var skipped:Dictionary=run.tactics.hit_party(0)
	assert(skipped.get("sleep_skipped",false) and skipped.damage==0 and run.tactics.enemies[0].sleep_turns==0 and run.actors[0].hp==before)
	assert(run.tactics.hit_party(0).damage>0)
	run=fixture(["maria"])
	run.tactics.enemies[0].armor=20.0
	var normal:float=run.tactics.deal(run.tactics.enemies[0],100,false,true).damage
	var hp:float=run.tactics.enemies[0].hp
	assert(cast(run).damage==0 and run.tactics.enemies[0].hp==hp)
	assert(is_equal_approx(run.tactics.deal(run.tactics.enemies[0],100,false,true).damage,normal+4))
	var weakened:Dictionary=Abilities.incoming(run.tactics,0,0)
	assert(is_equal_approx(weakened.damage,32*run.tactics.pressure()))
	run.tactics.tick(8.1)
	assert(run.tactics.enemies[0].curse_left==0 and run.tactics.enemies[0].armor==20)
	assert(is_equal_approx(run.tactics.deal(run.tactics.enemies[0],100,false,true).damage,normal))
	run=fixture(["peter"])
	for count in [1,2,3]:
		assert(cast(run).damage==0 and run.actors[0].guardian_spirits==count)
	run.actors[0].energy=100
	assert(not run.tactics.reserve_ultimate(0))
	run.actors[0].shield=25.0
	var health:float=run.actors[0].hp
	for remaining in [2,1,0]:
		var blocked:=Abilities.incoming(run.tactics,0,0)
		assert(blocked.damage==0 and blocked.counter>0 and blocked.blocked_spirit)
		assert(run.actors[0].hp==health and run.actors[0].shield==25 and run.actors[0].guardian_spirits==remaining)
	assert(Abilities.incoming(run.tactics,0,0).damage>0)
	run.actors[0].guardian_spirits=2
	var restored:=IdleRun.new()
	restored.restore(TaleCampaign.new(),run.to_checkpoint())
	assert(restored.actors[0].guardian_spirits==2)
	run=fixture(["joao"])
	var joao:=cast(run)
	assert(joao.targets==[0] and joao.strikes.size()==6)
	assert(is_equal_approx(joao.damage,run.actors[0].damage*4.2))
	run=fixture(["snow_white"])
	assert(is_equal_approx(cast(run).damage,run.actors[0].damage*8))
	assert(run.tactics.enemies[1].hp==100000)
	run=fixture(["mulan"])
	assert(cast(run).targets==[0,1,2])
	run=fixture(["rapunzel","scarlet","maria","joao"])
	for actor in run.actors:actor.hp=actor.max_hp*.5
	var roots:=cast(run)
	assert(roots.damage==0 and roots.ally_targets==[0,1,2])
	for at in 4:
		assert(run.actors[at].hp==run.actors[at].max_hp*.5)
		assert(is_equal_approx(run.actors[at].shield,run.actors[at].max_hp*.3 if at<3 else 0))
	run=fixture(["alice"])
	assert(not run.tactics.reserve_ultimate(0))
	run.actors[0].energy=100
	run.tactics.tick(1)
	assert(run.actors[0].energy==0 and not run.tactics.reserve_ultimate(0))
	for attack in 4:
		run.hit_enemy(0,0)
		assert(run.actors[0].card_charge==attack+1 and run.actors[0].suit==(attack+1)%4 and run.actors[0].energy==0)
	assert(run.tactics.ultimate_ready(0))
	var flow:=preload("res://scripts/battle_flow.gd").new()
	flow.bind(run)
	flow.begin({"side":"ally","index":0})
	flow.complete()
	assert(flow.next_action().get("ultimate",false),"The fourth attack queues Alice's automatic cortejo immediately")
	assert(run.tactics.reserve_ultimate(0))
	var cards:Dictionary=run.tactics.ultimate(0,0)
	assert(cards.targets.size()==3)
	assert(cards.targets==Rules.line_targets(run.tactics.enemies,0))
	assert(cards.targets.has(0) and cards.targets.has(3) and cards.targets.has(6),"Alice crosses columns in one horizontal lane")
	assert(not cards.targets.has(1) and run.actors[0].card_charge==0)
	run.actors[0].card_charge=3
	restored=IdleRun.new()
	restored.restore(TaleCampaign.new(),run.to_checkpoint())
	assert(restored.actors[0].card_charge==3 and restored.actors[0].energy==0)
	print("ULT OVERHAUL PASS: 11 animated kits, AOE/single/lane targeting, six thrusts, sleep chance/skip, timed curse, three full-hit spirit blocks, hair shields, mana-free Alice and save persistence")
	quit()
