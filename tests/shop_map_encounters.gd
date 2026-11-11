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
	var potion_pairs := {}
	for seed_value in 30:
		run.rng.seed = seed_value
		run.interlude = "route"
		run.roll_routes()
		assert(run.choose_route("shop"))
		var items := run.merchant_stock()
		var potions := items.filter(func(id): return ExpeditionContent.SHOP_POTIONS.has(id))
		assert(potions.size() == 2 and potions[0] != potions[1] and items.has("revive"))
		assert(items.filter(func(id): return id.begins_with("item:")).size() == 3)
		potion_pairs[",".join(potions)] = true
		assert(run.switch_merchant("trader"))
		assert(run.merchant_stock().size() == 3 and run.merchant_stock().all(func(id): return id.begins_with("bonus:")))
	assert(potion_pairs.size() == 3, "Any of the three potion pairs can be stocked")

	var price_rows := [
		[32,70,22,40,60,32], [50,109,24,44,66,35], [64,140,26,48,72,38], [72,158,29,52,78,42],
		[80,175,32,58,87,46], [85,186,35,64,96,51], [99,217,40,72,108,58], [107,235,44,80,120,64]
	]
	var price_ids := ["bonus:99:max_hp:unique:0","item:whetstone","potion","potion_medium","potion_full","revive"]
	for stage in price_rows.size():
		run.stage = stage
		for index in price_ids.size():
			assert(run.supply_cost(price_ids[index]) == price_rows[stage][index])
	assert(Routes.place(run, "CasteloDoAutor"))
	var stock := run.shop_stock.duplicate()
	var random_state := run.rng.state
	var equipment := str(stock[0])
	var bonus := run.merchant_stock()[0]
	assert(not run.buy_supply(equipment), "The buff merchant cannot sell equipment")
	assert(not run.buy_supply(bonus), "Buffs still require explicit confirmation")
	assert(run.switch_merchant("shop"))
	assert(not run.confirm_bonus(bonus, "scarlet", 1, "shop"), "The item merchant cannot sell buffs")
	var price := run.supply_cost(equipment)
	run.run_gold = price - 1
	assert(not run.buy_supply(equipment) and run.run_gold == price - 1)
	run.run_gold = price + 107
	assert(run.buy_supply(equipment) and run.run_gold == 107)
	assert(run.switch_merchant("trader"))
	var data := IdleRun.Bonuses.parse(bonus)
	var target := "scarlet"
	for actor in run.actors:
		if IdleRun.Bonuses.useful(actor, data.attribute, 1):
			target = actor.id
			break
	assert(run.confirm_bonus(bonus, target, 1, "shop") and run.run_gold == 0)
	assert(not run.confirm_bonus(bonus, target, 1, "shop"))
	assert(run.phase == 4 and run.shop_stock == stock and run.rng.state == random_state)
	run = load_run(account, run.to_checkpoint())
	assert(run.merchant_kind == "trader" and run.shop_stock == stock and run.rng.state == random_state)
	assert(run.shop_bought == [equipment, bonus] and run.run_gold == 0)
	assert(run.switch_merchant("shop") and not run.buy_supply(equipment))

	# Independent purchase checks keep all three heal strengths covered.
	run.stage = 0
	run.run_gold = 300
	for potion in [["potion", .33, 22], ["potion_medium", .66, 40], ["potion_full", 1.0, 60]]:
		run.shop_stock.assign([potion[0]])
		run.actors[0].hp = run.actors[0].max_hp * .10
		run.actors[1].hp = run.actors[1].max_hp * .90
		run.actors[2].hp = 0
		var gold := run.run_gold
		assert(run.buy_supply(potion[0]))
		assert(is_equal_approx(run.actors[0].hp / run.actors[0].max_hp, minf(1, .10 + potion[1])))
		assert(run.actors[1].hp == run.actors[1].max_hp and run.actors[2].hp == 0)
		assert(not run.buy_supply(potion[0]) and run.run_gold == gold - potion[2])
	run.shop_stock.assign(["revive"])
	var balance := run.run_gold
	run.actors[0].hp = run.actors[0].max_hp * .40
	run.actors[1].hp = 0
	var hp: float = run.actors[0].hp
	assert(not run.buy_supply("revive") and not run.buy_supply("revive", 0) and run.run_gold == balance)
	assert(run.buy_supply("revive", 2))
	assert(is_equal_approx(run.actors[2].hp / run.actors[2].max_hp, .20))
	assert(run.actors[1].hp == 0 and run.actors[0].hp == hp and run.run_gold == balance - 32)

	var old := run.to_checkpoint()
	old.erase("shop_format")
	old.shop_stock = ["potion", "potion_medium", "potion_full", "revive", "item:echo_bell", bonus]
	old.shop_bought = ["potion"]
	run = load_run(account, old)
	assert(run.merchant_stock().filter(func(id): return ExpeditionContent.SHOP_POTIONS.has(id)).size() == 2)
	assert(run.shop_stock.has("potion") and run.shop_stock.has("item:echo_bell") and run.shop_stock.has(bonus))
	assert(run.shop_bought == ["potion"] and run.rng.state == random_state and not run.buy_supply("potion"))
	assert(run.switch_merchant("trader") and run.merchant_stock() == [bonus])

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
	var stock: Array = game.run.shop_stock.duplicate()
	for kind in ["shop", "trader", "shop"]:
		if game.run.merchant_kind != kind:
			var tabs: Array = game.page.get_children().filter(func(n): return n.get_meta("merchant_tab", "") == kind)
			tabs[0].pressed.emit()
			await process_frame
		var list: Control = game.page.get_node("ShopList").get_child(0)
		var portraits := list.get_children().filter(func(n): return n.get_meta("merchant_portrait", "") == kind)
		var cards := list.get_children().filter(func(n): return n.has_meta("shop_item"))
		assert(portraits.size() == 1 and cards.size() == (3 if kind == "trader" else 6))
		assert(portraits[0].size.x == portraits[0].size.y and portraits[0].get_rect().end.y < cards[0].position.y)
		assert(game.run.shop_stock == stock)
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
	print("SHOP AND MAP ENCOUNTERS PASS: separate merchants, stage prices, potion pairs, chosen revival, purchases and legacy saves, map gates, stale encounters")
	quit()
