extends SceneTree
## Recruitment, unique requirements and atomic run resolution. Use an isolated save.
var game: Control
const TEST_PATH := "user://recruitment_test_isolated.json"


func _initialize() -> void:
	call_deferred("checks")


func invite(run: IdleRun, campaign: TaleCampaign, id: String, slot: int = -1) -> void:
	run.pending_choice = true
	run.offers.assign(["ally:" + id, "power", "heart"])
	assert(run.recruit(campaign, id, slot))


func checks() -> void:
	var campaign := TaleCampaign.new()
	assert(campaign.unlocked == ["scarlet"] and campaign.party == ["scarlet"])
	var run := IdleRun.new()
	run.setup(campaign, 0)
	run.wave = 1
	run.pending_choice = true
	run.roll_offers(campaign)
	assert(run.offers[0] == "ally:snow_white" and run.offers.size() == 3)
	assert(run.recruit(campaign, "snow_white"))
	assert(run.actor_ids() == ["scarlet", "snow_white"] and campaign.party == ["scarlet"])
	assert(not campaign.can_level_hero("snow_white") and not campaign.toggle_party("snow_white"))
	assert(not run.recruit(campaign, "snow_white"))
	# A guest's IDs, health, future offers and RNG survive save/load with a one-person base party.
	run.actors[0].hp = 83
	run.pending_choice = true
	run.roll_offers(campaign)
	campaign.checkpoint = run.to_checkpoint()
	assert(campaign.save_to(TEST_PATH))
	var loaded := TaleCampaign.new()
	assert(loaded.load_from(TEST_PATH) and not loaded.checkpoint.is_empty())
	var restored := IdleRun.new()
	restored.restore(loaded, loaded.checkpoint)
	assert(restored.actor_ids() == run.actor_ids() and restored.actors[0].hp == 83)
	assert(restored.offers == run.offers and restored.run_id == run.run_id)
	assert(restored.rng.randf() == run.rng.randf())
	# Completing a chapter no longer grants the story heroine automatically.
	campaign.complete_stage(0)
	assert(campaign.unlocked == ["scarlet"])
	campaign.choose_memory(0, "hope")
	# Three distinct victorious runs with Snow White; no duplicate credit or defeat credit.
	for trial in 3:
		run = IdleRun.new()
		run.setup(campaign, 0)
		invite(run, campaign, "snow_white")
		run.wave = 2
		var snapshot := run.to_checkpoint()
		var unlocked := campaign.resolve_run(snapshot, true)
		assert(campaign.unlock_amount("snow_white") == trial + 1)
		assert(campaign.resolve_run(snapshot, true).is_empty())
		assert(campaign.unlock_amount("snow_white") == trial + 1)
		assert(unlocked.has("snow_white") == (trial == 2))
	assert(campaign.unlocked.has("snow_white") and campaign.party.has("snow_white"))
	var fresh := TaleCampaign.new()
	run.setup(fresh, 0)
	invite(run, fresh, "snow_white")
	fresh.resolve_run(run.to_checkpoint(), false)
	assert(fresh.unlock_amount("snow_white") == 0)
	# Rapunzel counts actual HP restored by her own third hit, never overheal or a relic.
	var healer := TaleCampaign.new()
	run.setup(healer, 0)
	invite(run, healer, "rapunzel")
	run.spawn_enemy()
	run.enemy_hp = 100000
	for hit in 3:
		run.hit_enemy(1)
	assert(run.unlock_stats.healing == 0)
	for cycle in 10:
		run.actors[0].hp -= 3
		run.actors[1].hp -= 3
		for hit in 3:
			run.hit_enemy(1)
	assert(run.unlock_stats.healing == 60)
	run.apply_relic("heart")
	assert(run.unlock_stats.healing == 60)
	healer.checkpoint = run.to_checkpoint()
	var healer_reload := TaleCampaign.new()
	healer_reload.load_data(healer.to_dict())
	var healer_run := IdleRun.new()
	healer_run.restore(healer_reload, healer_reload.checkpoint)
	assert(healer_run.unlock_stats.healing == 60 and healer_run.actors[1].hits == 33)
	assert(healer_reload.resolve_run(healer_run.to_checkpoint(), false) == ["rapunzel"])
	assert(healer_reload.resolve_run(healer_run.to_checkpoint(), false).is_empty())
	assert(healer.resolve_run(run.to_checkpoint(), false) == ["rapunzel"])
	# Mulan's mission counts eight real third hits, not ordinary hits or attacks from a fallen ally.
	var warrior := TaleCampaign.new()
	run.setup(warrior, 0)
	invite(run, warrior, "mulan")
	run.spawn_enemy()
	run.enemy_hp = 100000
	for hit in 24:
		run.hit_enemy(1)
	assert(run.unlock_stats.combos == 8)
	run.actors[1].hp = 0
	assert(run.hit_enemy(1).is_empty() and run.unlock_stats.combos == 8)
	assert(warrior.resolve_run(run.to_checkpoint(), false) == ["mulan"])
	# Ariel must survive bosses in two DIFFERENT chapters. Repeats and a fallen Ariel do not count.
	var sailor := TaleCampaign.new()
	for chapter in [0, 0, 1, 1]:
		run.setup(sailor, chapter)
		invite(run, sailor, "ariel")
		run.wave = 2
		if chapter == 1 and sailor.run_counter == 3:
			run.actors[1].hp = 0
		sailor.resolve_run(run.to_checkpoint(), true)
		assert(sailor.unlock_amount("ariel") == (2 if sailor.run_counter == 4 else 1))
	assert(sailor.unlocked.has("ariel"))
	# Old owned heroes remain owned. New progress and run IDs roundtrip without re-crediting.
	var old := TaleCampaign.new()
	old.load_data(
		{"version": 2, "unlocked": ["scarlet", "mulan"], "party": ["mulan"], "cleared": [0]}
	)
	assert(old.unlocked.has("mulan") and old.party == ["mulan"])
	var roundtrip := TaleCampaign.new()
	roundtrip.load_data(sailor.to_dict())
	assert(roundtrip.unlock_amount("ariel") == 2 and roundtrip.unlocked.has("ariel"))
	assert(roundtrip.resolve_run(run.to_checkpoint(), true).is_empty())
	# Full-team swap: existing relics apply to the guest; other health and the base formation stay intact.
	var full := TaleCampaign.new()
	full.unlocked.assign(["scarlet", "snow_white", "rapunzel"])
	full.party.assign(full.unlocked)
	run.setup(full, 0)
	run.apply_relic("power")
	run.apply_relic("heart")
	run.actors[0].hp = 45
	invite(run, full, "mulan", 1)
	assert(run.actor_ids() == ["scarlet", "mulan", "rapunzel"] and run.actors[0].hp == 45)
	assert(full.party == ["scarlet", "snow_white", "rapunzel"])
	assert(is_equal_approx(run.actors[1].damage, TaleCatalog.HEROES.mulan.damage * 1.2))
	assert(run.actors[1].max_hp == TaleCatalog.HEROES.mulan.hp + 25)
	full.checkpoint = run.to_checkpoint()
	assert(full.save_to(TEST_PATH) and loaded.load_from(TEST_PATH))
	assert(not loaded.checkpoint.is_empty())
	# Real UI replacement and visual battle rebuild use the run party rather than the permanent party.
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = TEST_PATH
	root.add_child(game)
	game.set_process(false)
	game.campaign = full
	game.run = run
	game.build_battle()
	game.run.pending_choice = true
	game.run.offers.assign(["ally:ariel", "haste", "armor"])
	game.show_relics()
	game.select_relic("ally:ariel")
	assert(game.state == "replacement" and game.run.actor_ids()[1] == "mulan")
	game.confirm_replacement("ally:ariel", 1)
	assert(game.state == "travel" and game.run.actor_ids() == ["scarlet", "ariel", "rapunzel"])
	assert(game.arena.heroes[1].hero_name == "Ariel" and game.arena.heroes.size() == 3)
	game.leave_battle()
	game.resume_checkpoint()
	assert(game.run.actor_ids()[1] == "ariel" and game.arena.heroes[1].hero_name == "Ariel")
	game.abandon_expedition()
	assert(game.campaign.party == ["scarlet", "snow_white", "rapunzel"])
	game.show_heroes()
	game.show_unlock_details("mulan")
	assert(is_instance_valid(game.overlay))
	# Play genuine fights from a new account until Snow White's third invited victory unlocks her.
	game.campaign = TaleCampaign.new()
	var invited_wins := 0
	for trial in 30:
		game.begin_chapter_combat(0)
		game.run.rng.seed = 777 + trial
		for tick in 4000:
			game._process(0.05)
			if is_instance_valid(game.arena):
				game.arena.set_process(false)
				game.arena._process(0.05)
			if game.state == "choice":
				game.select_relic(
					(
						"ally:snow_white"
						if game.run.offers.has("ally:snow_white")
						else game.run.offers[0]
					)
				)
			if game.state in ["result", "defeat"]:
				break
		assert(game.state == "result")
		if game.run.drafted.has("snow_white"):
			invited_wins += 1
		assert(game.campaign.unlock_amount("snow_white") == invited_wins)
		if trial == 0:
			game.campaign.choose_memory(0, "hope")
		if game.campaign.unlocked.has("snow_white"):
			break
	assert(invited_wins == 3 and game.campaign.unlocked.has("snow_white"))
	game.begin_chapter_combat(0)
	assert(
		game.run.actor_ids().has("snow_white"),
		"A permanently unlocked heroine can start the next run"
	)
	game.abandon_expedition()
	game.queue_free()
	await process_frame
	for path in [TEST_PATH, TEST_PATH + ".bak", TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print(
		"PASS: solo start; temporary draft/visual team; four unique unlocks; actual healing/combos; surviving distinct bosses; no duplicate run credits; guest saves/RNG; legacy ownership; full-team swap/relics; three genuine invited victories and permanent next-run selection"
	)
	quit()
