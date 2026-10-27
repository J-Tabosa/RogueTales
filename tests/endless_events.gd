extends SceneTree
const Events = preload("res://scripts/team_events.gd")
const SAVE := "user://endless_events_isolated.json"
func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	# All events are playable solo and have an enforced party-only alternative.
	for key in Events.EVENTS:
		var data: Dictionary = Events.EVENTS[key]
		var account := TaleCampaign.new()
		account.unlocked.assign(TaleCatalog.HEROES.keys())
		var run := IdleRun.new()
		run.start_expedition(account, data.pair[0], "vigor")
		assert(Events.available(run).has(key))
		assert(Events.dialogue(run, key).size() == 2)
		run.interlude = "event"
		run.pending_event = key
		assert(not Events.resolve(run, "pair"))
		assert(run.interlude == "event" and run.run_gold == 35)
		run.pending_choice = true
		run.offers.assign(["ally:" + str(data.pair[1]), "power", "heart"])
		assert(run.recruit(account, data.pair[1]))
		run.interlude = "event"
		assert(Events.dialogue(run, key).size() == 3 and Events.can_pair(run, key))
		account.checkpoint = run.to_checkpoint()
		assert(account.save_to(SAVE))
		var loaded := TaleCampaign.new()
		assert(loaded.load_from(SAVE))
		var resumed := IdleRun.new()
		resumed.restore(loaded, loaded.checkpoint)
		assert(resumed.interlude == "event" and resumed.pending_event == key)
		assert(Events.resolve(resumed, "pair"))
		assert(resumed.seen_events.has(key) and resumed.events_discovered == [key])
		assert(not Events.resolve(resumed, "pair"), "No reward can be claimed again")
		assert(not Events.available(resumed).has(key))
	# Hundreds of phases retain three choices; phase 12 is never a terminal transition.
	var account := TaleCampaign.new()
	account.expedition_wins = 1
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "vigor", true))
	run.rng.seed = 8381
	for phase in 180:
		assert(run.stage == (phase / 6) % 12 and run.phase == phase % 6)
		assert(not run.clear_encounter())
		assert(run.rooms_cleared == phase + 1 and run.offers.size() == 3)
		var choice: String = run.offers.filter(func(id): return not id.begins_with("ally:"))[0]
		if choice.begins_with("bonus:"):
			var b=preload("res://scripts/run_bonuses.gd").parse(choice)
			var target=run.actors.filter(func(a):return preload("res://scripts/run_bonuses.gd").useful(a,b.attribute,-1))[0]
			assert(run.confirm_bonus(choice,target.id,-1))
		else:assert(run.apply_relic(choice))
		assert(run.choose_route("battle"))
	assert(run.build_history.is_empty() and run.relics.size() < 12)
	assert(run.upgrade_total() + run.inventory.size() == 180)
	for i in 20: assert(run.apply_relic("power"))
	assert(run.upgrade_count("power") > 3)
	run.interlude = "route"
	run.route_offers.assign(["battle", "curse"])
	assert(run.choose_route("curse"))
	assert(run.apply_relic("heart"))
	run.actors[0].hp = 73
	run.actors[0].shadows = 2
	run.interlude = "route"
	run.route_offers.assign(["battle", "shop"])
	assert(run.choose_route("shop"))
	run.shop_stock.assign(["potion", "power", "armor"])
	assert(run.buy_supply("power"))
	account.checkpoint = run.to_checkpoint()
	assert(JSON.stringify(account.checkpoint).length() < 120000, "180 floors retain the required bonus history/ledger within a bounded practical save size")
	assert(account.save_to(SAVE))
	var loaded := TaleCampaign.new()
	assert(loaded.load_from(SAVE))
	var resumed := IdleRun.new()
	resumed.restore(loaded, loaded.checkpoint)
	assert(resumed.endless and resumed.rooms_cleared == 180 and resumed.actors[0].hp == 73)
	assert(resumed.actors[0].shadows == 2 and resumed.upgrade_counts == run.upgrade_counts)
	assert(is_equal_approx(resumed.actors[0].max_hp, run.actors[0].max_hp))
	assert(is_equal_approx(resumed.actors[0].damage, run.actors[0].damage))
	assert(resumed.interlude == "shop" and not resumed.buy_supply("power"))
	assert(resumed.rng.randf() == run.rng.randf())
	# New recruits inherit the compact affine build, including health additions before curses.
	resumed.pending_choice = true
	resumed.offers.assign(["ally:alice", "heart", "power"])
	assert(resumed.recruit(loaded, "alice"))
	var expected: float = TaleCatalog.HEROES.alice.hp * 1.25 * resumed.team_template.hp_scale + resumed.team_template.hp_flat
	for b in resumed.bonus_history:
		if b.mode=="group" and b.attribute=="max_hp":expected+=float(b.magnitude)
	assert(is_equal_approx(resumed.actors[1].max_hp, expected))
	resumed.rooms_cleared = 181
	resumed.stage = 1
	resumed.rng.seed = 812
	resumed.spawn_enemy()
	var strength: float = resumed.enemy_max
	resumed.rooms_cleared = 193
	resumed.rng.seed = 812
	resumed.spawn_enemy()
	assert(resumed.enemy_max > strength)
	resumed.rooms_cleared = 100000
	resumed.spawn_enemy()
	assert(is_finite(resumed.enemy_max) and resumed.enemy_max > strength)
	# Endless records and first-time milestones are independent of normal victories.
	resumed.rooms_cleared = 29
	var result := loaded.finish_expedition(resumed.to_checkpoint(), false)
	assert(result.endless and result.milestones == 2 and loaded.best_endless == 29)
	assert(loaded.expedition_wins == 1 and loaded.endless_runs == 1)
	assert(result.reward == 29 * 4 + 40 and loaded.checkpoint.is_empty())
	assert(loaded.finish_expedition(resumed.to_checkpoint(), false).is_empty())
	var fresh := IdleRun.new()
	assert(fresh.start_expedition(loaded, "scarlet", "vigor", true))
	fresh.rooms_cleared = 24
	result = loaded.finish_expedition(fresh.to_checkpoint(), false)
	assert(result.milestones == 0 and loaded.best_endless == 29)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("ENDLESS EVENTS PASS: all six conditional stories, no absent speakers or duplicate rewards, event resume, 180 continuous floors, inexhaustible upgrades, compact exact build/recruit saves, deep finite scaling and first-time milestones")
	quit()
