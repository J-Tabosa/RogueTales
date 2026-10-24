extends SceneTree
const Secrets=preload("res://scripts/secret_encounters.gd")
const Events=preload("res://scripts/team_events.gd")
const Details=preload("res://scripts/combat_details.gd")
const Biomes=preload("res://scripts/biomes.gd")
func _initialize() -> void: call_deferred("checks")
func checks() -> void:
	var account:=TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	for id in Secrets.DATA:
		var run:=IdleRun.new()
		assert(run.start_expedition(account,id,"vigor"))
		var biome: int=Secrets.DATA[id].biomes[0]
		run.stage=Biomes.STAGE_BIOMES.find(biome)
		run.phase=2
		assert(Events.available(run).has("secret_"+id))
		assert(Events.dialogue(run,"secret_"+id).size()==2)
		run.actors[0].hp=0
		assert(not Secrets.eligible(run,id))
		run.actors[0].hp=run.actors[0].max_hp
		run.pending_event="secret_"+id
		run.interlude="event"
		assert(Events.resolve(run,"challenge"))
		assert(run.active_secret==id)
		run.tactics.spawn()
		assert(run.tactics.enemies.size()==1 and run.tactics.enemies[0].secret_id==id)
		assert(not run.tactics.enemies[0].has("binds") and not run.tactics.enemies[0].has("banner"))
		var old_score: int=run.score
		var old_gold: int=run.run_gold
		var old_stage: int=run.stage
		var old_phase: int=run.phase
		var old_rooms: int=run.rooms_cleared
		var resumed:=IdleRun.new()
		resumed.restore(account,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
		assert(resumed.active_secret==id)
		resumed.tactics.spawn()
		assert(resumed.tactics.enemies.size()==1 and resumed.tactics.enemies[0].secret_id==id)
		assert(not resumed.clear_encounter())
		assert(resumed.stage==old_stage and resumed.phase==old_phase and resumed.rooms_cleared==old_rooms)
		assert(resumed.score==old_score+600 and resumed.run_gold==old_gold+75+old_stage*5)
		assert(resumed.interlude=="secret_reward" and resumed.secret_defeated.has(id))
		var reward_stats: Dictionary=resumed.actors[0].duplicate(true)
		var reward_copy:=IdleRun.new()
		reward_copy.restore(account,JSON.parse_string(JSON.stringify(resumed.to_checkpoint())))
		assert(reward_copy.pending_secret_reward==id and reward_copy.secret_defeated.has(id))
		for key in ["max_hp","damage","interval","crit","armor","leech","energy_bonus","base_evasion"]:
			assert(is_equal_approx(reward_copy.actors[0][key],reward_stats[key]),id+" reward survives without doubling: "+key)
		assert(not reward_copy.clear_encounter() and reward_copy.score==old_score+600)
		assert(not Secrets.eligible(reward_copy,id))
		var frames:=preload("res://scripts/secret_enemy_art.gd").frames(id)
		assert(frames.get_frame_count("boss_attack")==5)
		assert(Details.sheet(reward_copy.actors[0]).contains(Details.n(reward_copy.actors[0].damage)))
		var before: String=Details.active(run.actors[0])
		run.actors[0].damage*=2
		assert(Details.active(run.actors[0])!=before,"Numeric descriptions follow live upgrades")
	var fresh:=IdleRun.new()
	assert(fresh.start_expedition(account,"snow_white","vigor"))
	fresh.tactics.spawn()
	# Poison must hit a reachable, surviving target, regardless of the rolled group.
	var foe_index: int=fresh.tactics.target_for(0)
	var foe: Dictionary=fresh.tactics.enemies[foe_index]
	foe.evasion=0
	foe.hp=10000
	foe.max_hp=10000
	fresh.hit_enemy(0,foe_index)
	assert(foe.poison>0 and foe.poison_left>0)
	assert(Details.active(fresh.actors[0]).contains(Details.n(fresh.actors[0].damage*.10)))
	var mulan_run:=IdleRun.new()
	assert(mulan_run.start_expedition(account,"mulan","vigor"))
	mulan_run.tactics.spawn()
	mulan_run.actors[0].evasion=1.0
	mulan_run.actors[0].pp=1
	mulan_run.tactics.enemies[0].hp=10000
	var counter: Dictionary=mulan_run.tactics.hit_party(0)
	assert(counter.evaded and counter.get("counter",0)>0 and mulan_run.actors[0].pp==0 and mulan_run.actors[0].shield>0)
	for speed in [1,2,3]:
		account.speed=speed
		assert(account.save_to("user://revision_speed_test.json"))
		var loaded:=TaleCampaign.new()
		assert(loaded.load_from("user://revision_speed_test.json") and loaded.speed==speed)
	print("CHARACTER REVISION PASS: 12 solo trials, biome/alive gates, no phase skipping, save/resume, rewards once, live numerical kits, poison, 1/2/3x persistence")
	quit()
