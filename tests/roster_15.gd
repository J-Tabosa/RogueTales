extends SceneTree

const R := preload("res://scripts/combat_rules.gd")
const B := preload("res://scripts/hero_blessings.gd")
const Art := preload("res://scripts/hero_art.gd")
const TRIO := ["aurora", "mogli", "pinocchio"]

func _initialize() -> void: call_deferred("checks")

func fixture(account: TaleCampaign, id: String) -> IdleRun:
	var run := IdleRun.new()
	assert(run.start_expedition(account, id, B.id_for(id,0)))
	run.phase = 2
	run.rng.seed = 4159
	run.spawn_enemy()
	assert(not run.tactics.enemies.is_empty())
	for foe in run.tactics.enemies:
		foe.hp = 1000
		foe.max_hp = 1000
		foe.armor = 0
		foe.magic_defense = 0
		foe.evasion = 0.0
	run.actors[0].crit = 0.0
	return run

func checks() -> void:
	assert(TaleCatalog.HEROES.size() == 15 and TaleCatalog.HERO_SCENES.size() == 15)
	var account := preload("res://tests/test_accounts.gd").legacy()
	account.gold = 15000
	for id in TRIO:
		assert(account.buy_hero(id) and account.unlocked.has(id))
		assert(B.unlocked(account, B.id_for(id,0)) and B.data(B.id_for(id,1)).is_empty())
		var sprite: AnimatedSprite2D = TaleCatalog.HERO_SCENES[id].instantiate()
		var frames := sprite.sprite_frames
		assert(frames.get_frame_count("idle") == 4 and frames.get_frame_count("attack") == 3)
		assert(frames.get_frame_count("ultimate") == 3)
		assert(Art.body(id).texture != null and Art.head(id) != null)
		sprite.free()

	var run := fixture(account,"aurora")
	var hero := run.actors[0]
	hero.energy = 100.0
	assert(run.tactics.reserve_ultimate(0))
	var hit: Dictionary = run.tactics.ultimate(0,0)
	assert(hit.damage > 0 and hit.targets.size() <= 2 and hit.status_targets == hit.targets)
	for at in hit.targets: assert(R.has_status(run.tactics.enemies[at],"sleep"))
	hero.energy = 0.0
	run.hit_enemy(0,0)
	assert(hero.energy == 20.0)

	run = fixture(account,"mogli")
	assert(R.start_turn(run.tactics,run.actors[0]).attacks == 2)
	hit = run.hit_enemy(0,0)
	var normal := float(hit.damage)
	run.tactics.enemies[0].hp = 400
	hit = run.hit_enemy(0,0)
	assert(is_equal_approx(hit.damage, normal*1.5))
	run.actors[0].energy = 80.0
	assert(run.tactics.reserve_ultimate(0))
	hit = run.tactics.ultimate(0,0)
	assert(hit.targets == [0] and is_equal_approx(hit.damage, normal*2.5))

	run = fixture(account,"pinocchio")
	hero = run.actors[0]
	var opening := float(hero.max_hp)*.12
	assert(is_equal_approx(hero.shield,opening))
	hero.energy = 90.0
	assert(run.tactics.reserve_ultimate(0))
	hit = run.tactics.ultimate(0,0)
	assert(hit.targets == [0] and hit.damage > 0.0)
	assert(is_equal_approx(hero.shield,opening+float(hero.max_hp)*.10))

	# Each new character can also join an ordinary run and survives a save/reload.
	run = fixture(account,"scarlet")
	run.party_capacity = 5
	for id in TRIO:
		run.pending_choice = true
		run.offers.assign(["ally:"+id,"power","heart"])
		assert(run.recruit(account,id))
	var reloaded := IdleRun.new()
	reloaded.restore(account,JSON.parse_string(JSON.stringify(run.to_checkpoint())))
	assert(reloaded.actor_ids() == ["scarlet","aurora","mogli","pinocchio"])
	var count := 0
	run.rng.seed = 28493
	for trial in 4000:
		run.roll_run_offers()
		if run.offers.has(ExpeditionContent.RANDOM_ITEM_OFFER): count+=1
	assert(count > 1100 and count < 1300, str(count))
	run.reward_boss = true
	for trial in 100:
		run.roll_run_offers()
		assert(run.offers.has(ExpeditionContent.RANDOM_ITEM_OFFER))

	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://roster_15_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = account
	game.run = run
	for id in TRIO:
		game.selected_hero = id
		game.show_heroes()
		await process_frame
		game.show_hero_details(id)
		await process_frame
		game.show_map()
		await process_frame
		assert(game.page.find_child("BlessingList",true,false) != null)
	game.queue_free()
	await process_frame
	print("ROSTER 15 PASS: trio portraits, animations, purchases, abilities, recruitment, saved party, UI, 30% items and boss reward")
	quit()
