extends SceneTree

const Routes = preload("res://tests/test_routes.gd")
const Events = preload("res://scripts/team_events.gd")
const Secrets = preload("res://scripts/secret_encounters.gd")

func _initialize() -> void: call_deferred("checks")

func load_run(account: TaleCampaign, data: Dictionary) -> IdleRun:
	var run := IdleRun.new()
	run.restore(account, JSON.parse_string(JSON.stringify(data)))
	return run

func check_shop(account: TaleCampaign) -> void:
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "vigor"))
	for id in ["mulan", "alice"]:
		run.pending_choice = true
		run.offers.assign(["ally:" + id])
		assert(run.recruit(account, id))
	run.phase = 4
	run.run_gold = 500
	for merchant in ["shop", "trader"]:
		run.interlude = "route"
		run.roll_routes()
		assert(run.choose_route(merchant))
		assert(run.shop_stock.slice(0, 4) == ["potion", "potion_medium", "potion_full", "revive"])
		for potion in [["potion", .33, 22], ["potion_medium", .66, 40], ["potion_full", 1.0, 60]]:
			run.actors[0].hp = run.actors[0].max_hp * .10
			run.actors[1].hp = run.actors[1].max_hp * .90
			run.actors[2].hp = 0
			var gold := run.run_gold
			assert(run.buy_supply(potion[0]))
			assert(is_equal_approx(run.actors[0].hp / run.actors[0].max_hp, minf(1, .10 + potion[1])))
			assert(run.actors[1].hp == run.actors[1].max_hp and run.actors[2].hp == 0)
			assert(not run.buy_supply(potion[0]) and run.run_gold == gold - potion[2])
		var balance := run.run_gold
		run.actors[0].hp = run.actors[0].max_hp * .40
		run.actors[1].hp = 0
		var hp: float = run.actors[0].hp
		assert(not run.buy_supply("revive") and not run.buy_supply("revive", 0) and run.run_gold == balance)
		assert(run.buy_supply("revive", 2))
		assert(is_equal_approx(run.actors[2].hp / run.actors[2].max_hp, .20))
		assert(run.actors[1].hp == 0 and run.actors[0].hp == hp and run.run_gold == balance - 32)
		run = load_run(account, run.to_checkpoint())
		assert(run.merchant_kind == merchant and run.shop_bought.size() == 4 and not run.buy_supply("revive", 1))
	run.roll_shop()
	for a in run.actors: a.hp = a.max_hp
	assert(not run.buy_supply("potion") and not run.buy_supply("revive", 1))
	run.actors[1].hp = 1
	run.run_gold = 21
	assert(not run.buy_supply("potion") and run.run_gold == 21 and run.actors[1].hp == 1)
	var old := run.to_checkpoint()
	old.shop_stock = ["potion", "item:echo_bell"]
	old.shop_bought = ["potion"]
	run = load_run(account, old)
	assert(run.shop_stock == ["potion", "potion_medium", "potion_full", "revive", "item:echo_bell"])
	assert(run.shop_bought == ["potion"] and not run.buy_supply("potion"))

func check_map_encounters(account: TaleCampaign) -> void:
	for hero in Secrets.DATA:
		var trial := IdleRun.new()
		assert(trial.start_expedition(account, hero, "vigor"))
		assert(not Secrets.eligible(trial, hero), "A forest opening is not a personal encounter map")
		assert(Routes.place_at_meeting(trial, hero))
		assert(Secrets.eligible(trial, hero), "Missing secret encounter for " + hero)
	var run := IdleRun.new()
	assert(run.start_expedition(account, "ariel", "vigor"))
	run.phase = 1
	run.interlude = "route"
	assert(Routes.place(run, "Oceano"))
	assert(Secrets.eligible(run, "ariel") and Events.available(run).has("bottled_tide"))
	run.route_offers.assign(["battle", "team_event"])
	run.pending_event = "secret_ariel"
	run.interlude = "event"
	var valid := load_run(account, run.to_checkpoint())
	assert(valid.interlude == "event" and Events.resolve(valid, "challenge"))
	assert(valid.active_secret == "ariel")
	assert(Routes.place(run, "Praia"))
	assert(not Secrets.eligible(run, "ariel") and Events.available(run).is_empty())
	assert(Events.dialogue(run, "secret_ariel").is_empty() and not Events.resolve(run, "challenge"))
	var stale := load_run(account, run.to_checkpoint())
	assert(stale.pending_event.is_empty() and stale.interlude == "route" and stale.route_offers == ["battle"])
	assert(stale.choose_route("battle"))
	run.interlude = ""
	run.active_secret = "ariel"
	stale = load_run(account, run.to_checkpoint())
	stale.spawn_enemy()
	assert(stale.active_secret.is_empty() and not stale.tactics.enemies[0].has("secret_id"))
	run.active_secret = ""
	run.interlude = "event"
	run.pending_event = "bottled_tide"
	var balance := run.run_gold
	assert(not Events.resolve(run, "supplies") and run.run_gold == balance)
	assert(Routes.place(run, "Oceano"))
	assert(Events.resolve(run, "supplies") and run.run_gold == balance + 30)
	assert(not Events.available(run).has("bottled_tide"))

func check_revive_ui(account: TaleCampaign) -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://shop_map_encounters_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = account
	game.run = IdleRun.new()
	assert(game.run.start_expedition(account, "scarlet", "vigor"))
	game.run.pending_choice = true
	game.run.offers.assign(["ally:alice"])
	assert(game.run.recruit(account, "alice"))
	game.run.interlude = "shop"
	game.run.actors[1].hp = 0
	game.run.roll_shop()
	game.show_run_shop()
	await process_frame
	game.buy_run_supply("revive")
	var choices: Array = game.overlay.get_children().filter(func(n): return n.has_meta("revive_target"))
	assert(choices.size() == 1 and choices[0].get_meta("revive_target") == "alice")
	assert(game.run.run_gold == 35 and game.run.actors[1].hp == 0)
	choices[0].pressed.emit()
	assert(game.run.run_gold == 3 and game.run.actors[1].hp > 0 and game.campaign.checkpoint.shop_bought == ["revive"])
	game.queue_free()
	await process_frame

func checks() -> void:
	var account := TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	check_shop(account)
	check_map_encounters(account)
	await check_revive_ui(account)
	print("SHOP AND MAP ENCOUNTERS PASS: both merchants, exact cures, chosen revival, purchases and legacy saves, map gates, stale encounters")
	quit()
