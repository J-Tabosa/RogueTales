extends SceneTree
const Gear = preload("res://scripts/equipment.gd")
const Blessings = preload("res://scripts/hero_blessings.gd")
const Layout = preload("res://scripts/formation_layout.gd")
const Modifiers = preload("res://scripts/combat_modifiers.gd")
const Secrets = preload("res://scripts/secret_encounters.gd")
const SAVE = "user://equipment_progression_isolated.json"
var account: TaleCampaign
func _initialize() -> void: call_deferred("checks")
func fixture(hero := "scarlet") -> IdleRun:
	account = preload("res://tests/test_accounts.gd").legacy()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run := IdleRun.new()
	assert(run.start_expedition(account, hero, Blessings.id_for(hero, 0)))
	return run
func checks() -> void:
	# Symmetric positions: every row starts centered, then splits in a straight column.
	for row in Layout.ROWS:
		var units: Array = []
		for count in range(1, 4):
			units.append({"row": row})
			var center := 0.0
			for i in units.size():
				var home := Layout.home(units, i, false)
				center += home.y
				assert(home.x == Layout.home(units, 0, false).x)
				assert(is_equal_approx(home.x + Layout.home(units, i, true).x, 1.0))
			assert(is_equal_approx(center / count, 0.66))
	var run := fixture()
	# Every party size is reachable, never more than three in one position.
	run.interlude = "shop"
	run.run_gold = 10000
	for price in Gear.CAPACITY_PRICES:
		var before := run.run_gold
		assert(run.capacity_cost() == price and run.buy_supply("capacity"))
		assert(run.run_gold == before - price)
	assert(run.party_capacity == 5 and not run.buy_supply("capacity"))
	for hero in ["rapunzel","joao","puss","alice"]:
		run.pending_choice = true
		run.offers.assign(["ally:" + hero, "power", "heart"])
		assert(run.recruit(account, hero))
	assert(run.actors.size() == 5 and not run.can_recruit("ariel"))
	assert(run.can_recruit("ariel",1) and run.can_recruit("ariel",0))
	assert(account.valid_checkpoint_party(run.to_checkpoint()))
	# All group counts occur, and normal/boss encounters respect the 3x3 field.
	var counts := {}
	for world in 12:
		run.stage = world
		for phase in 6:
			if phase==4:continue
			run.phase = phase
			for seed_value in 30:
				run.rng.seed = seed_value * 71 + world
				run.spawn_enemy()
				assert(run.tactics.enemies.size() <= ExpeditionContent.enemy_limit(world), "Enemy count exceeded this world's difficulty cap")
				var rows := {"front":0, "middle":0, "back":0}
				for foe in run.tactics.enemies:
					rows[foe.row] += 1
					assert(rows[foe.row] <= 3)
				if phase == 5:
					assert(run.tactics.enemies.size() == 3)
					assert(run.tactics.enemies.filter(func(foe): return foe.boss).size() == 1)
				else: counts[run.tactics.enemies.size()] = true
	assert(counts.size() == 9)
	# Copies cannot be duplicated across heroes. Removing/equipping never heals.
	run.interlude = "shop"
	for item in ["stone_heart", "hunter_glasses", "black_apple", "blue_hourglass"]: assert(run.grant_item(item))
	var actor: Dictionary = run.actors[0]
	actor.hp = 70
	var base_damage: float = actor.damage
	var base_hp: float = actor.max_hp
	assert(run.equip_item(0, "stone_heart", 0))
	assert(actor.max_hp == base_hp + 100 and actor.hp == 70)
	assert(not run.equip_item(1, "stone_heart", 0))
	assert(run.equip_item(0, "hunter_glasses", 1))
	assert(is_equal_approx(actor.damage, base_damage))
	assert(run.apply_relic("power"))
	run.interlude = "shop"
	assert(run.equip_item(0, "", 1))
	assert(is_equal_approx(actor.damage, base_damage * 1.2))
	assert(run.equip_item(0, "hunter_glasses", 1))
	assert(run.equip_item(0, "", 0) and actor.max_hp == base_hp and actor.hp == 70)
	assert(run.equip_item(0, "stone_heart", 0))
	run.shop_stock.assign(["item:echo_bell"])
	run.shop_bought.clear()
	run.run_gold = 500
	assert(run.buy_supply("item:echo_bell") and run.run_gold == 330)
	assert(not run.buy_supply("item:echo_bell"))
	# Full JSON/disk round trip preserves nine heroes, equipped stats and stock.
	account.checkpoint = run.to_checkpoint()
	assert(account.save_to(SAVE))
	var loaded := preload("res://tests/test_accounts.gd").legacy()
	assert(loaded.load_from(SAVE))
	var restored := IdleRun.new()
	restored.restore(loaded, loaded.checkpoint)
	assert(restored.party_capacity == 5 and restored.actors.size() == 5)
	assert(restored.inventory == run.inventory and restored.actors[0].equipment == actor.equipment)
	for key in ["hp", "max_hp", "damage", "interval", "crit", "armor", "leech", "energy_bonus"]:
		assert(is_equal_approx(restored.actors[0][key], actor[key]), key)
	assert(not restored.buy_supply("item:echo_bell"))
	assert(restored.equip_item(0, "", 1))
	assert(is_equal_approx(restored.actors[0].damage, base_damage * 1.2))
	restored.interlude = ""
	assert(not restored.equip_item(0, "black_apple", 0))
	# Special interactions work on actual targets and do not recurse.
	run = fixture("ariel")
	run.interlude = "route"
	assert(run.grant_item("black_apple") and run.equip_item(0, "black_apple", 0))
	run.spawn_enemy()
	for foe in run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.evasion = 0
	run.hit_enemy(0)
	assert(run.tactics.enemies.any(func(foe): return foe.poison > 0))
	run.interlude = "route"
	assert(run.grant_item("blue_hourglass") and run.equip_item(0, "blue_hourglass", 1))
	for foe in run.tactics.enemies: foe.burn = 0;foe.statuses=[];foe.burn_left=0
	run.hit_enemy(0)
	assert(run.tactics.enemies.any(func(foe): return foe.poison > 0))
	assert(run.tactics.enemies.all(func(foe): return foe.burn == 0))
	# Four blessings per hero, with participation and idempotent mission credit.
	for hero in TaleCatalog.HEROES:
		run = fixture(hero)
		for i in 4:
			var id := Blessings.id_for(hero, i)
			assert(not Blessings.data(id).is_empty())
			assert(Blessings.unlocked(account, id) == (i == 0))
		run.hero_room_counts[hero] = 12
		var data := run.to_checkpoint()
		Blessings.record(account, data)
		Blessings.record(account, data)
		assert(account.hero_milestones[hero].rooms == 12)
		assert(not Blessings.unlocked(account, Blessings.id_for(hero, 1)),"Participation is not a substitute for the documented feat")
		run.active_secret = hero
		run.clear_encounter()
		assert(run.inventory.has("trophy_" + hero))
		var copies := run.inventory.size()
		run.clear_encounter()
		assert(run.inventory.size() == copies)
		Blessings.record(account, run.to_checkpoint(), true)
		assert(Blessings.unlocked(account, Blessings.id_for(hero, 2)))
		assert(Blessings.unlocked(account, Blessings.id_for(hero, 3)))
		var saved := preload("res://tests/test_accounts.gd").legacy()
		saved.load_data(JSON.parse_string(JSON.stringify(account.to_dict())))
		assert(saved.hero_milestones == account.hero_milestones)
	# Boss reward screens always offer an item alongside three valid choices.
	run = fixture()
	run.stage = 0
	run.phase = 5
	run.clear_encounter()
	assert(run.offers.size() == 3 and run.offers.any(func(id): return id.begins_with("item:")))
	assert(run.run_gold >= 171)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("EQUIPMENT PROGRESSION PASS: centered rows, 1-9 enemies, 12 boss formations, 9-hero saves, physical copies, reversible stats, atomic shop, poison equipment, 48 blessings and idempotent trophies/missions")
	quit()
