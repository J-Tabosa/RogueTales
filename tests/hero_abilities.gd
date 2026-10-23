extends SceneTree
const Flow = preload("res://scripts/battle_flow.gd")

func _initialize() -> void: call_deferred("checks")

func fixture(id: String, stage := 8) -> IdleRun:
	var account := TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run := IdleRun.new()
	assert(run.start_expedition(account, id, "vigor"))
	run.stage = stage
	run.wave = 0
	run.rng.seed = 123
	run.spawn_enemy()
	var flow := Flow.new()
	flow.bind(run)
	for foe in run.tactics.enemies:
		foe.row = "front" if foe.slot == 0 else "back"
		foe.evasion = 0
		foe.armor = 0
		foe.damage = 5
		foe.pp = 0
		foe.hp = 10000
		foe.max_hp = 10000
	run.actors[0].crit = 0
	run.actors[0].evasion = 0
	return run

func checks() -> void:
	for id in TaleCatalog.HEROES:
		var run := fixture(id)
		assert(ExpeditionContent.KITS[id].size() == 4 and ExpeditionContent.MUTATIONS[id].size() == 3)
		for mutation in ExpeditionContent.MUTATIONS[id]: assert(run.apply_relic("skill:%s:%s" % [id, mutation[0]]))
		for action in 8:
			assert(not run.hit_enemy(0).is_empty())
			run.actors[0].pp = 1
			run.hit_party(0)
		assert(run.actors[0].mutations.size() == 3)
	# Scarlet's modifier changes detonation timing and adds group protection.
	var run := fixture("scarlet")
	run.apply_relic("skill:scarlet:quick")
	run.apply_relic("skill:scarlet:shelter")
	var first := run.hit_enemy(0)
	var second := run.hit_enemy(0)
	assert(first.targets.size() == 1 and second.targets.size() == 3 and run.actors[0].shield > 0)
	# Mulan's second hit combo can reach both rows.
	run = fixture("mulan")
	run.apply_relic("skill:mulan:quick")
	run.apply_relic("skill:mulan:dragon")
	run.hit_enemy(0)
	second = run.hit_enemy(0)
	assert(second.targets.size() == 3 and run.unlock_stats.combos == 1)
	# Maria consumes actual poison and heals, rather than applying another flat stat.
	run = fixture("maria")
	run.actors[0].hp = 70
	first = run.hit_enemy(0)
	var at: int = first.target
	assert(run.tactics.enemies[at].poison > 0)
	second = run.hit_enemy(0, at)
	assert(second.damage > first.damage and run.actors[0].hp > 70 and run.tactics.enemies[at].poison_left == 0)
	# Peter spends exactly one PP on an evasion and uses the generated shadows.
	run = fixture("peter")
	run.apply_relic("skill:peter:double")
	run.apply_relic("skill:peter:keep")
	run.actors[0].evasion = 1
	first = run.hit_party(0)
	second = run.hit_party(0)
	assert(first.evaded and first.counter > 0 and not second.has("counter"))
	assert(run.actors[0].shadows == 2 and run.actors[0].pp == 0)
	first = run.hit_enemy(0)
	assert(first.damage > run.actors[0].damage * 2 and run.actors[0].shadows == 1)
	# Gato alternates charge and swing; nine lives is once per run.
	run = fixture("puss")
	first = run.hit_enemy(0)
	second = run.hit_enemy(0)
	assert(second.damage > first.damage * 3)
	run.apply_relic("skill:puss:nine")
	run.tactics.enemies[0].damage = 99999
	run.actors[0].pp = 0
	run.hit_party(0)
	assert(run.actors[0].hp > 0 and run.actors[0].nine_used)
	run.hit_party(0)
	assert(run.actors[0].hp == 0)
	# Rapunzel credits actual restoration and ignores overhealing.
	run = fixture("rapunzel")
	run.hit_enemy(0)
	assert(run.unlock_stats.healing == 0)
	run.actors[0].hp -= 50
	run.hit_enemy(0)
	assert(run.unlock_stats.healing > 0 and run.unlock_stats.healing <= 50)
	# Alice's four suits and Aladin's three wishes execute distinct effects.
	run = fixture("alice")
	run.actors[0].hp = 100
	for i in 3: run.hit_enemy(0)
	assert(run.actors[0].hp > 100 and run.actors[0].shield > 0 and run.actors[0].suit == 3)
	run = fixture("aladin")
	run.actors[0].hp = 100
	for i in 3: run.hit_enemy(0)
	assert(run.actors[0].hp > 100 and run.actors[0].shield > 0 and run.actors[0].wish == 0)
	# Fire deaths caused by status ticks invoke the same bounded chain reaction.
	run = fixture("matches")
	run.apply_relic("skill:matches:ash")
	run.actors[0].energy = 0
	run.tactics.enemies[0].hp = 1
	run.tactics.enemies[0].burn = 100
	run.tactics.enemies[0].burn_left = 0.05 # Expiry on the killing tick still triggers the reaction.
	run.tick_status(0.1)
	assert(run.tactics.enemies[0].hp == 0 and run.tactics.enemies[1].burn > 0 and run.actors[0].energy >= 25)
	var energy: float = run.actors[0].energy
	run.tick_status(0)
	assert(run.actors[0].energy == energy)
	# João's follow-up is a bounded reaction to another member hitting his mark.
	run = fixture("joao")
	var account := TaleCampaign.new()
	run.pending_choice = true
	run.offers.assign(["ally:maria", "power", "heart"])
	assert(run.recruit(account, "maria"))
	run.actors[1].crit = 0
	run.actors[0].pp = 1
	first = run.hit_enemy(0)
	second = run.hit_enemy(1, first.target)
	assert(second.followup and run.actors[0].pp == 0)
	assert(not run.hit_enemy(1, first.target).has("followup"))
	# Gato intercepts an endangered back-row ally, spending his own PP.
	run = fixture("puss")
	run.pending_choice = true
	run.offers.assign(["ally:snow_white", "power", "heart"])
	assert(run.recruit(account, "snow_white"))
	run.actors[1].hp = 20
	run.tactics.enemies[0]["class"] = "ranger"
	first = run.hit_party(0)
	assert(first.target == 0 and first.guarded and run.actors[0].pp == 0 and run.actors[1].hp == 20)
	# Ariel's emergency reaction has its own trigger and changes enemy initiative.
	run = fixture("ariel")
	run.actors[0].hp = 70
	first = run.hit_party(0)
	assert(first.support_heal > 0 and run.actors[0].pp == 0 and run.tactics.slow_left > 0)
	print("HERO ABILITIES PASS: all 12 kits/36 choices, detonation, combo reach, poison consumption, PP/shadows, charged cleave, one-use survival, actual healing, suits/wishes and status death chains")
	quit()
