extends SceneTree
## Exercise real generation rather than only checking the cap helper.
func _initialize() -> void: call_deferred("checks")
func checks() -> void:
	var account:=TaleCampaign.new()
	var run:=IdleRun.new()
	assert(run.start_expedition(account,"scarlet","blessing:scarlet:0"))
	assert(run.actors.size()==1)
	var generated:=0
	for stage in 12:
		run.stage=stage
		var expected:int=[3,6,9][mini(stage,2)]
		var observed:Dictionary={}
		for phase in 6:
			run.phase=phase
			for kind in ["battle","elite"]:
				run.room_kind=kind
				for seed_value in 128:
					run.rng.seed=seed_value
					run.spawn_enemy()
					generated+=1
					var count:int=run.tactics.enemies.size()
					assert(count>=1 and count<=expected,"Stage %d phase %d: %d enemies exceeds %d"%[stage+1,phase+1,count,expected])
					if phase==5:
						assert(count==3 and run.tactics.enemies.filter(func(enemy):return enemy.boss).size()==1)
					else:observed[count]=true
		assert(observed.size()==expected,"All counts up to this stage's cap must remain reachable")
	# A saved second-stage run uses the same cap and RNG after restoring.
	run.stage=1
	run.phase=2
	run.room_kind="battle"
	run.rng.seed=411
	var checkpoint:=run.to_checkpoint()
	run.spawn_enemy()
	var expected_enemies:Array=run.tactics.enemies.duplicate(true)
	var restored:=IdleRun.new()
	restored.restore(account,checkpoint)
	restored.spawn_enemy()
	assert(restored.tactics.enemies==expected_enemies and restored.tactics.enemies.size()<=6)
	# Returning to early scenery in endless must not reset its enemy ceiling.
	run.endless=true
	run.rooms_cleared=72
	for stage in 3:
		run.stage=stage
		var observed:Dictionary={}
		for seed_value in 128:
			run.rng.seed=seed_value
			run.spawn_enemy()
			observed[run.tactics.enemies.size()]=true
			assert(run.tactics.enemies.size()<=9)
		assert(observed.size()==9)
	# Secret challenges remain solo, including in the first stage.
	run.endless=false
	run.stage=0
	run.active_secret="scarlet"
	run.spawn_enemy()
	assert(run.tactics.enemies.size()==1 and run.tactics.enemies[0].secret_id=="scarlet")
	print("ENCOUNTER DIFFICULTY PASS: %d encounters across 12 stages, all six phases and elites; caps 3/6/9, boss escorts, solo secret, checkpoint RNG and endless ceiling"%generated)
	quit()
