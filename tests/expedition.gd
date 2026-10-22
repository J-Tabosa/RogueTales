extends SceneTree
## Model, persistence, probabilities and terminal transactions for real runs.
const SAVE := "user://expedition_isolated.json"

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var account := TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	account.party.assign(["scarlet", "mulan", "alice"])
	account.hero_levels.scarlet = 30
	account.levels.scarlet = [5, 5, 5]
	account.choices = {"0": "hope", "1": "power"}
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "vigor"))
	assert(run.actor_ids() == ["scarlet"])
	assert(run.actors[0].damage == 24 and run.actors[0].max_hp == 250)
	assert(run.run_gold == 35 and run.relics.is_empty())
	# Exactly one 10% draw per screen, never a forced first invitation or three draws.
	run.rng.seed = 81234
	var invited := 0
	for trial in 20000:
		run.roll_run_offers()
		assert(run.offers.size() == 3)
		var guests := 0
		for id in run.offers:
			assert(not TaleCatalog.offer_data(id).is_empty())
			if id.begins_with("ally:"): guests += 1
		assert(guests <= 1)
		invited += guests
	assert(invited > 1800 and invited < 2200)
	print("Recruit rate over 20000 screens: ", invited / 200.0, "%")
	# Stacking and transformations preserve >2 choices on reload at later stages.
	for key in ["power", "heart", "power", "leech", "haste", "critical", "armor", "skill:scarlet:quick", "skill:scarlet:shelter"]:
		assert(run.apply_relic(key))
	run.stage = 8
	run.rooms_cleared = 8
	run.actors[0].hp = 81
	run.actors[0].energy = 67
	run.actors[0].hits = 13
	run.run_gold = 193
	run.roll_run_offers()
	run.roll_routes()
	account.checkpoint = run.to_checkpoint()
	assert(account.save_to(SAVE))
	var loaded := TaleCampaign.new()
	assert(loaded.load_from(SAVE) and loaded.checkpoint.stage == 8)
	var restored := IdleRun.new()
	restored.restore(loaded, loaded.checkpoint)
	assert(restored.expedition and restored.run_gold == 193)
	assert(restored.relics == run.relics and restored.offers == run.offers)
	assert(restored.actors[0].hp == 81 and restored.actors[0].hits == 13)
	assert(is_equal_approx(restored.actors[0].damage, run.actors[0].damage))
	assert(restored.actors[0].mutations == ["quick", "shelter"])
	assert(restored.actors[0].energy == 67 and restored.route_offers == run.route_offers)
	assert(restored.rng.randf() == run.rng.randf())
	# Ordered history preserves additive health before and after a multiplicative curse.
	restored.interlude = "route"
	restored.route_offers.assign(["battle", "curse"])
	assert(restored.choose_route("curse"))
	assert(restored.apply_relic("heart"))
	var cursed := IdleRun.new()
	cursed.restore(loaded, restored.to_checkpoint())
	assert(is_equal_approx(cursed.actors[0].max_hp, restored.actors[0].max_hp))
	assert(is_equal_approx(cursed.actors[0].damage, restored.actors[0].damage))
	# A shop purchase is atomic and cannot be repeated after resuming.
	restored.interlude = "route"
	restored.route_offers.assign(["battle", "shop"])
	restored.shop_stock.assign(["potion", "power", "armor"])
	restored.shop_bought.clear()
	assert(restored.choose_route("shop"))
	assert(restored.buy_supply("potion") and restored.run_gold == 171)
	loaded.checkpoint = restored.to_checkpoint()
	var shop := IdleRun.new()
	shop.restore(loaded, loaded.checkpoint)
	assert(shop.interlude == "shop" and not shop.buy_supply("potion"))
	assert(shop.run_gold == 171)
	shop.leave_shop()
	assert(shop.interlude.is_empty())
	# Runs traverse all 12 phases without replacing the team or regenerating health.
	var fresh := TaleCampaign.new()
	run = IdleRun.new()
	assert(run.start_expedition(fresh, "scarlet", "fury"))
	run.actors[0].hp = 97
	for stage in 12:
		assert(run.stage == stage)
		assert((run.wave == 2) == ExpeditionContent.is_boss(stage))
		var health_before: float = run.actors[0].hp
		var terminal := run.clear_encounter()
		assert(terminal == (stage == 11))
		assert(run.actors[0].hp == health_before)
		if not terminal:
			assert(run.interlude == "reward" and run.offers.size() == 3)
			var key: String = run.offers.filter(func(id): return not id.begins_with("ally:"))[0]
			assert(run.apply_relic(key))
			assert(run.interlude == "route" and run.choose_route("battle"))
	assert(run.rooms_cleared == 12)
	var gold_before := fresh.gold
	var terminal_data := run.to_checkpoint()
	var result := fresh.finish_expedition(terminal_data, true)
	assert(result.won and result.depth == 12 and fresh.expedition_wins == 1)
	assert(fresh.gold == gold_before + 78 and fresh.checkpoint.is_empty())
	assert(fresh.finish_expedition(terminal_data, true).is_empty())
	assert(fresh.gold == gold_before + 78 and fresh.expedition_wins == 1)
	# A new run resets the whole temporary build even on a developed account.
	run = IdleRun.new()
	assert(run.start_expedition(fresh, "scarlet", "vigor"))
	assert(run.stage == 0 and run.relics.is_empty() and run.run_gold == 35)
	assert(run.actors[0].hp == 250 and run.actors[0].mutations.is_empty())
	# Defeat resolves guest feats once and preserves already owned characters.
	run.pending_choice = true
	run.offers.assign(["ally:alice", "power", "heart"])
	assert(run.recruit(fresh, "alice"))
	run.unlock_stats["new_hits"] = {"alice": 20}
	run.rooms_cleared = 4
	result = fresh.finish_expedition(run.to_checkpoint(), false)
	assert(result.unlocks == ["alice"] and fresh.unlocked.has("alice"))
	assert(fresh.party == ["scarlet"])
	assert(fresh.finish_expedition(run.to_checkpoint(), false).is_empty())
	# Guest boss feats survive a later defeat and are not credited twice.
	var guests := TaleCampaign.new()
	var journey := IdleRun.new()
	journey.start_expedition(guests, "scarlet", "vigor")
	for id in ["snow_white", "ariel"]:
		journey.pending_choice = true
		journey.offers.assign(["ally:" + id, "power", "heart"])
		assert(journey.recruit(guests, id))
	for boss in [3, 7]:
		journey.stage = boss
		journey.clear_encounter()
	var end := journey.to_checkpoint()
	guests.finish_expedition(end, false)
	assert(guests.unlock_amount("snow_white") == 2 and guests.unlocked.has("ariel"))
	assert(guests.finish_expedition(end, false).is_empty())
	assert(guests.unlock_amount("snow_white") == 2)
	var old := TaleCampaign.new()
	old.load_data({"version": 4, "unlocked": ["scarlet", "mulan"], "party": ["mulan"], "gold": 388})
	assert(old.unlocked.has("mulan") and old.gold == 388 and old.party == ["mulan"])
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("EXPEDITION PASS: 12 phases, solo base stats, 10% per screen, deep checkpoint/RNG, nonrepeatable shop, reset, idempotent victory/defeat, guest unlocks and v4 migration")
	quit()
