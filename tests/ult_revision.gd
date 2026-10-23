extends SceneTree
const Abilities=preload("res://scripts/hero_abilities.gd")
func _initialize() -> void:call_deferred("checks")
func fixture(id:String) -> IdleRun:
	var account:=TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run:=IdleRun.new()
	assert(run.start_expedition(account,id,"vigor"))
	run.spawn_enemy()
	for actor in run.actors:
		actor.evasion=0
		actor.energy=100
		actor.pp=0
	for foe in run.tactics.enemies:
		foe.hp=10000
		foe.max_hp=10000
		foe.evasion=0
		foe.pp=0
		foe.damage=5
	return run
func checks() -> void:
	var run:=fixture("peter")
	assert(run.tactics.reserve_ultimate(0))
	var result:Dictionary=run.tactics.ultimate(0)
	assert(result.damage==0 and run.actors[0].spirit_flames==3 and run.actors[0].shield>0)
	for remaining in [2,1,0]:
		var hit:=Abilities.incoming(run.tactics,0,0)
		assert(hit.counter>0 and run.actors[0].spirit_flames==remaining)
	var exhausted:=Abilities.incoming(run.tactics,0,0)
	assert(not exhausted.has("counter"))
	run.actors[0].spirit_flames=2
	var restored:=IdleRun.new()
	restored.restore(TaleCampaign.new(),run.to_checkpoint())
	assert(restored.actors[0].spirit_flames==2)
	run=fixture("maria")
	run.tactics.enemies[0].armor=20
	var normal:float=run.tactics.deal(run.tactics.enemies[0],100,false,true).damage
	assert(run.tactics.reserve_ultimate(0))
	run.tactics.ultimate(0)
	assert(run.tactics.enemies[0].armor_break_left==6.0)
	var weakened:float=run.tactics.deal(run.tactics.enemies[0],100,false,true).damage
	assert(weakened>normal)
	run.tactics.tick(6.1)
	assert(run.tactics.deal(run.tactics.enemies[0],100,false,true).damage==normal)
	run=fixture("ariel")
	for key in ["hostile_burn","hostile_poison","hostile_dot_left"]:run.actors[0][key]=10.0
	run.actors[0].sealed=true
	assert(run.tactics.reserve_ultimate(0))
	run.tactics.ultimate(0)
	assert(not run.actors[0].sealed and run.actors[0].hostile_dot_left==0 and run.actors[0].hostile_burn==0 and run.actors[0].hostile_poison==0)
	print("ULT REVISION PASS: three reactive spirit shields, checkpoint persistence, timed armor break, negative-effect cleansing")
	quit()
