extends SceneTree
const Flow = preload("res://scripts/battle_flow.gd")
const Synergies = preload("res://scripts/team_synergies.gd")
var account: TaleCampaign
func _initialize() -> void: call_deferred("checks")

func model(ids: Array, stage := 8) -> IdleRun:
	account = TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run := IdleRun.new()
	run.start_expedition(account, ids[0], "vigor")
	for id in ids.slice(1):
		run.pending_choice = true
		run.offers.assign(["ally:" + id, "power", "heart"])
		assert(run.recruit(account, id))
	run.stage = stage
	run.wave = 2 if ExpeditionContent.is_boss(stage) else 0
	run.spawn_enemy()
	var flow := Flow.new()
	flow.bind(run)
	for actor in run.actors:
		actor.crit = 0
		actor.evasion = 0
	for foe in run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.armor = 0
		foe.evasion = 0
		foe.pp = 0
		foe.damage = 20
	return run

func ult(run: IdleRun, index: int) -> Dictionary:
	run.actors[index].energy = 100
	assert(run.tactics.reserve_ultimate(index))
	return run.tactics.ultimate(index)

func checks() -> void:
	var run := model(["joao", "maria"])
	var marked := run.hit_enemy(0)
	var hit := run.hit_enemy(1, marked.target)
	assert(hit.synergies == ["hunters"] and hit.followup and run.actors[0].pp == 0)
	run.actors[0].pp = 1
	run.hit_enemy(1, marked.target)
	assert(run.synergy_activations == 1, "A pair cannot trigger twice in the same round")
	var flow := Flow.new()
	flow.bind(run)
	hit = run.hit_enemy(1, marked.target)
	assert(hit.synergies == ["hunters"] and run.synergy_activations == 2)
	assert(Synergies.available(run) == ["hunters"])
	run = model(["scarlet", "matches"])
	var fire := run.hit_enemy(1)
	hit = run.hit_enemy(0, fire.target)
	assert(hit.synergies == ["powder"] and run.actors[1].pp == 0)
	run.tactics.synergy_used.clear()
	run.actors[1].hp = 0
	run.tactics.enemies[fire.target].burn_owner = "matches"
	assert(not run.hit_enemy(0, fire.target).has("synergies"), "Fallen partners cannot enable a combo")
	run = model(["ariel", "aladin"])
	run.actors[1].wish = 1
	hit = run.hit_enemy(1)
	assert(hit.synergies == ["tide"] and run.actors[0].shield >= run.actors[0].max_hp * 0.19)
	run = model(["rapunzel", "puss"])
	run.actors[1].charged = true
	run.actors[1].hp = 40
	hit = run.hit_enemy(1)
	assert(hit.synergies == ["threads"] and run.unlock_stats.healing > 0 and run.actors[0].shield > 0)
	run = model(["mulan", "peter"])
	run.actors[1].shadows = 2
	hit = run.hit_enemy(1)
	assert(hit.synergies == ["dance"] and hit.targets.has(0) and hit.targets.size() > 1)
	run = model(["alice", "snow_white"])
	var poisoned := run.hit_enemy(1)
	run.actors[0].suit = 1
	run.actors[0].hp = 40
	hit = run.hit_enemy(0, poisoned.target)
	assert(hit.synergies == ["tea"] and hit.healed > 0)
	# General: protection is real; breaking the banner interrupts an action.
	run = model(["scarlet", "mulan"], 3)
	assert(run.tactics.enemies[1].banner)
	var amount: float = run.tactics.deal(run.tactics.enemies[0], 100, true, true).damage
	assert(is_equal_approx(amount, 60))
	run.tactics.commit_intent(0)
	run.tactics.enemies[1].hp = 0
	run.tactics.BossRules.refresh(run.tactics)
	assert(run.tactics.intent_for(0).key == "stagger")
	hit = run.hit_party(0)
	assert(hit.non_attack and not run.tactics.enemies[0].guarded_by_banner)
	amount = run.tactics.deal(run.tactics.enemies[0], 100, true, true).damage
	assert(is_equal_approx(amount, 100))
	hit = run.hit_party(0)
	assert(hit.message == "Avanço de Jade" and not hit.target_damage.is_empty())
	# Index guardian: a committed copy is stable even when another ULT lands during windup.
	run = model(["scarlet", "rapunzel"], 7)
	ult(run, 0)
	var intent: Dictionary = run.tactics.commit_intent(0)
	assert(intent.key == "copy" and intent.copy == "scarlet")
	ult(run, 1)
	assert(run.tactics.intent_for(0).copy == "scarlet")
	for actor in run.actors: actor.shield = 0 # Isolate copied damage from the intervening defensive ULT.
	hit = run.hit_party(0)
	assert(hit.targets.size() == 2 and hit.damage > 0)
	assert(run.tactics.intent_for(0).copy == "rapunzel")
	run.tactics.enemies[0].hp = 2000
	run.tactics.enemies[0]["shield"] = 0.0
	hit = run.hit_party(0)
	assert(hit.non_attack and run.tactics.enemies[0].hp > 2000 and run.tactics.enemies[0].shield > 0)
	assert(run.tactics.intent_for(0).key == "ink")
	# Weaver: threads, active seal, basic fallback and ULT escape work together.
	run = model(["scarlet"], 11)
	assert(run.actors[0].sealed)
	assert(run.tactics.target_for(0) == 1)
	hit = run.hit_enemy(0)
	assert(hit.message.contains("selada") and run.tactics.enemies[hit.target].burn == 0)
	for foe in run.tactics.enemies:
		if foe.has("binds"): foe.hp = 1
	ult(run, 0)
	assert(not run.actors[0].sealed)
	hit = run.hit_enemy(0)
	assert(not hit.message.contains("selada") and run.tactics.enemies[0].burn > 0)
	# Ordinary intent targets stay fixed through windup and retarget only after death.
	run = model(["alice", "snow_white", "aladin"])
	run.tactics.enemies[1]["class"] = "ranger"
	run.actors[1].hp = 120
	run.actors[2].hp = 160
	intent = run.tactics.commit_intent(1)
	var planned: int = intent.target
	var other := 2 if planned == 1 else 1
	run.actors[other].hp = 50
	assert(run.hit_party(1).target == planned)
	run.tactics.commit_intent(1)
	var next: int = run.tactics.intent_for(1).target
	run.actors[next].hp = 0
	assert(run.hit_party(1).target != next)
	print("PARTY COMBAT PASS: six real pair effects, PP/round/death limits, banner break, committed ULT copy, healing copy, active seals/ULT escape and committed ordinary targets")
	quit()
