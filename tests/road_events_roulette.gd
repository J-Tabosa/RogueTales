extends SceneTree

const Road = preload("res://scripts/road_events.gd")
const Gear = preload("res://scripts/equipment.gd")
const Content = preload("res://scripts/expedition_content.gd")
const MYSTERY = Content.RANDOM_ITEM_OFFER

func _initialize() -> void: call_deferred("checks")

func saved(account: TaleCampaign, run: IdleRun) -> IdleRun:
	var copy := IdleRun.new()
	copy.restore(account, JSON.parse_string(JSON.stringify(run.to_checkpoint())))
	return copy

func scene_event(run: IdleRun, key: String) -> void:
	run.phase = 2
	run.interlude = "event"
	run.pending_event = key

func check_events(account: TaleCampaign) -> void:
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "vigor"))
	run.phase = 1
	run.rng.seed = 18
	for trial in 100:
		run.roll_routes()
		if run.route_offers.has("road_event"): break
	assert(run.route_offers == ["battle", "road_event"])
	run.interlude = "route"
	assert(run.choose_route("road_event"))
	var event := run.pending_event
	var room := run.rooms_cleared
	run = saved(account, run)
	assert(run.pending_event == event and run.interlude == "event")
	assert(Road.resolve(run, "leave") and run.phase == 1 and run.rooms_cleared == room)
	assert(not Road.resolve(run, "leave"))
	run.seen_road_events.clear()

	scene_event(run, "road_spring")
	run.actors[0].hp = 1.0
	run.actors.append(run.run_actor("mulan"))
	run.actors[1].hp = 0.0
	var max_hp: float = run.actors[0].max_hp
	assert(Road.resolve(run, "heal") and is_equal_approx(run.actors[0].hp, 1.0 + max_hp * 0.25) and run.actors[1].hp == 0)
	scene_event(run, "road_thorns")
	run.actors[0].hp = 2.0
	var gold := run.run_gold
	assert(Road.resolve(run, "cross") and run.actors[0].hp == 1.0 and run.run_gold == gold + 45)

	var actor := run.actors[0]
	actor.physical_damage = 25
	actor.attacks = 2
	scene_event(run, "road_boulder")
	gold = run.run_gold
	assert(not Road.resolve(run, "break") and run.run_gold == gold)
	actor.physical_damage = 26
	assert(Road.resolve(run, "break") and run.run_gold == gold + 55)

	scene_event(run, "road_bridge")
	actor.physical_defense = 19
	assert(not Road.resolve(run, "hold"))
	actor.physical_defense = 20
	assert(Road.resolve(run, "hold") and is_equal_approx(actor.hp, 1.0 + max_hp * 0.20))

	scene_event(run, "road_current")
	actor.initiative = 74
	assert(not Road.resolve(run, "catch"))
	actor.initiative = 75
	assert(Road.resolve(run, "catch"))

	scene_event(run, "road_rumpel")
	var damage: float = actor.damage
	assert(Road.resolve(run, "power") and is_equal_approx(actor.damage, damage * 1.18))
	assert(is_equal_approx(actor.max_hp, max_hp * 0.90))
	var restored := saved(account, run)
	assert(is_equal_approx(restored.actors[0].max_hp, actor.max_hp))
	assert(restored.curse_count == 1 and is_equal_approx(restored.team_template.damage_scale, 1.18))
	assert(restored.seen_road_events.size() == Road.EVENTS.size())
	var next := Road.roll(restored)
	assert(next != "road_rumpel" and restored.seen_road_events.is_empty())
	restored.phase = 4
	assert(Road.roll(restored).is_empty())
	restored.phase = 5
	assert(Road.roll(restored).is_empty())

func check_roulette(account: TaleCampaign) -> void:
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "vigor"))
	run.reward_boss = true
	run.roll_run_offers()
	assert(run.offers.has(MYSTERY) and not run.offers.any(func(id): return id.begins_with("item:") and id != MYSTERY))
	assert(run.pending_item_reveal.is_empty())
	var retry := saved(account, run)
	assert(run.apply_relic(MYSTERY) and retry.apply_relic(MYSTERY))
	assert(run.pending_item_reveal == retry.pending_item_reveal and run.rng.state == retry.rng.state)
	var item := run.pending_item_reveal
	assert(Gear.ITEMS.has(item))
	assert(run.party_capacity == 4 if item == "travelers_page" else run.inventory == [item])
	assert(not run.apply_relic(MYSTERY))
	retry = saved(account, run)
	assert(retry.pending_item_reveal == item and retry.inventory == run.inventory and retry.party_capacity == run.party_capacity)
	assert(not retry.apply_relic(MYSTERY))
	retry.route_offers.assign(["battle"])
	assert(retry.choose_route("battle") and retry.pending_item_reveal.is_empty())
	retry.interlude = "shop"
	retry.shop_stock.assign([MYSTERY])
	assert(not retry.buy_supply(MYSTERY))

func check_ui(account: TaleCampaign) -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://road_events_roulette_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = account
	game.run = IdleRun.new()
	assert(game.run.start_expedition(account, "scarlet", "vigor"))
	scene_event(game.run, "road_boulder")
	game.show_team_event()
	await process_frame
	var blocked: Button = game.page.get_children().filter(func(n): return n.get_meta("road_choice", "") == "break")[0]
	assert(blocked.disabled)
	game.run.actors[0].physical_damage = 60
	game.show_team_event()
	await process_frame
	var enabled: Button = game.page.get_children().filter(func(n): return n.get_meta("road_choice", "") == "break")[0]
	assert(not enabled.disabled)
	game.run.roll_routes()
	game.run.reward_boss = true
	game.run.roll_run_offers()
	game.show_relics()
	game.select_relic(MYSTERY)
	assert(game.state == "item_reveal" and not game.run.pending_item_reveal.is_empty())
	assert(game.campaign.checkpoint.pending_item_reveal == game.run.pending_item_reveal)
	var spin: Array = game.page.get_children().filter(func(n): return n.has_meta("roulette_marker"))
	assert(spin.size() == 1)
	await create_timer(2.15).timeout
	assert(game.page.get_children().any(func(n): return n is Label and n.text == "Item recebido"))
	game.restore_checkpoint_now()
	await process_frame
	assert(game.state == "item_reveal" and game.page.get_children().any(func(n): return n is Label and n.text == "Item recebido"))
	game.continue_after_item_reveal()
	assert(game.run.pending_item_reveal.is_empty() and game.campaign.checkpoint.pending_item_reveal.is_empty())
	game.queue_free()
	await process_frame

func checks() -> void:
	var account := TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	check_events(account)
	check_roulette(account)
	await check_ui(account)
	print("ROAD EVENTS AND ROULETTE PASS: route odds, checks, contracts, eligibility, one draw and resumed reward")
	quit()
