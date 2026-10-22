extends SceneTree
const Tactics = preload("res://scripts/tactics.gd")
var game: Control
const SAVE := "user://tactical_isolated.json"


func _initialize() -> void:
	call_deferred("checks")


func checks() -> void:
	assert(TaleCatalog.STAGES.size() == 12)
	var units: Array = [
		{"hp": 100.0, "max_hp": 100.0, "row": "front", "armor": 10.0},
		{"hp": 20.0, "max_hp": 100.0, "row": "back", "armor": 0.0},
		{"hp": 100.0, "max_hp": 100.0, "row": "back", "armor": 2.0}]
	assert(Tactics.choose_target({"class": "vanguard"}, units) == 0)
	assert(Tactics.choose_target({"class": "ranger"}, units) == 1)
	assert(Tactics.choose_target({"class": "mage"}, units) == 1)
	assert(Tactics.choose_target({"class": "assassin"}, units) == 1)
	assert(Tactics.choose_target({"class": "artificer"}, units) == 1)
	units[0].hp = 0
	assert(Tactics.choose_target({"class": "vanguard"}, units) == 1)
	units[1].hp = 0
	units[2].hp = 0
	assert(Tactics.choose_target({"class": "mage"}, units) == -1)
	var campaign := TaleCampaign.new()
	campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	campaign.party.assign(["mulan", "snow_white", "ariel"])
	campaign.ensure_front()
	assert(not campaign.set_row("mulan", "back"))
	assert(campaign.set_row("ariel", "front") and campaign.set_row("mulan", "back"))
	assert(campaign.save_to(SAVE))
	var saved := TaleCampaign.new()
	assert(saved.load_from(SAVE) and saved.row_for("ariel") == "front")
	# Every ultimate consumes once, has a distinct effect, and survives encounter checkpoints.
	for id in TaleCatalog.HEROES:
		campaign.party.assign([id, "mulan"] if id != "mulan" else ["mulan", "rapunzel"])
		var run := IdleRun.new()
		run.setup(campaign, 8)
		run.enable_tactics(campaign)
		run.spawn_enemy()
		for foe in run.tactics.enemies:
			foe.hp = 10000.0
			foe.max_hp = 10000.0
		for actor in run.actors:
			actor.hp = actor.max_hp * 0.25
		run.actors[0].energy = 100
		assert(run.tactics.reserve_ultimate(0))
		assert(not run.tactics.reserve_ultimate(0))
		var result: Dictionary = run.tactics.ultimate(0)
		assert(not result.is_empty() and run.tactics.ultimate(0).is_empty())
		assert(run.actors[0].energy == 0 and not run.actors[0].ult_pending)
		if id == "rapunzel":
			assert(result.healed > 0 and run.actors[1].shield > 0)
		else:
			assert(result.damage > 0)
		if id in ["ariel", "scarlet"]:
			assert(result.targets.size() == 3)
		if id == "ariel":
			assert(run.tactics.slow_left == 5 and run.actors[0].hp > run.actors[0].max_hp * 0.25)
		if id == "snow_white":
			assert(run.tactics.enemies[result.target].row == "back" and run.tactics.enemies[result.target].poison_left == 6)
		if id == "mulan":
			assert(run.actors[0].shield > 0 and run.tactics.enemies[result.target].row == "front")
		run.actors[0].energy = 75
		var data := run.to_checkpoint()
		var resumed := IdleRun.new()
		resumed.restore(campaign, data)
		assert(resumed.tactics != null and resumed.actors[0].energy == 75 and resumed.actors[0].row == run.actors[0].row)
	# Statistically validate assassin evasion using the actual shared damage resolver.
	var run := IdleRun.new()
	run.setup(campaign, 0)
	run.enable_tactics(campaign)
	run.rng.seed = 91
	var dodges := 0
	for count in 1000:
		var target := {"hp": 100.0, "armor": 0.0, "evasion": 0.35}
		if run.tactics.deal(target, 10, false).evaded:
			dodges += 1
	assert(dodges > 280 and dodges < 420)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.begin_chapter_combat(0)
	game.spawn_enemy()
	game.arena.set_process(false)
	game.arena._process(0)
	assert(game.run.tactics != null and game.arena.foes.size() == 1)
	game.campaign.auto_ult = false
	game.run.actors[0].energy = 100
	assert(game.try_ultimate(0) and not game.try_ultimate(0))
	game.toggle_pause()
	var charge: float = game.run.actors[0].energy
	var timeline: float = game.arena.tracks[0].time
	game._process(0.2)
	game.arena._process(0.2)
	assert(game.run.actors[0].energy == charge and game.arena.tracks[0].time == timeline)
	game.resume_battle()
	# Resize the active battle between PC and mobile without resetting the run.
	game.anchor_right = 0
	game.anchor_bottom = 0
	var identity: int = game.run.run_id
	for dimensions in [Vector2(1280,720), Vector2(540,960), Vector2(360,800), Vector2(1920,1080)]:
		game.size = dimensions
		game.center_content()
		assert(game.run.run_id == identity and game.arena.tracks[0].time == timeline)
		var extent: Vector2 = game.content.position + game.content.size * game.content.scale
		assert(extent.x <= dimensions.x + 0.1 and extent.y <= dimensions.y + 0.1)
		for node in game.battle_nodes:
			var wanted: Rect2 = node.get_meta("pc_rect" if game.desktop else "mobile_rect")
			if node == game.stage_label:
				assert(node.size.y <= wanted.size.y + 0.1, "Battle title must not expand over the arena")
			assert(node.position.x >= 0 and node.position.y >= 0)
			assert(node.position.x + node.size.x <= game.logical_width + 0.1)
			assert(node.position.y + node.size.y <= game.logical_height + 0.1)
	var effects_applied: Array[int] = [0]
	game.arena.attack_hit.connect(func(_index: int): effects_applied[0] += 1)
	for tick in 100:
		game.arena._process(0.05)
	assert(effects_applied[0] == 1 and not game.run.actors[0].ult_pending, "A tactical ULT has one impact, even through recovery")
	game.run.actors[0].energy = 100
	assert(game.try_ultimate(0))
	game.arena.reset_effects()
	assert(game.run.actors[0].energy == 100 and not game.run.actors[0].ult_pending, "An unlanded interrupted ULT refunds its reservation")
	# Reset both the current save and backup so backup recovery cannot restore old progress.
	game.campaign.gold = 99999
	game.persist()
	game.show_settings()
	game.request_reset()
	game.show_settings() # cancel leaves the progress untouched
	assert(game.campaign.gold == 99999)
	game.request_reset()
	game.confirm_reset()
	assert(game.state == "menu" and game.run == null and game.campaign.party == ["scarlet"] and game.campaign.gold == 80)
	for path in [SAVE, SAVE + ".bak"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert(data.gold == 80 and data.unlocked == ["scarlet"] and data.cleared.is_empty() and data.checkpoint.is_empty())
	game.queue_free()
	await process_frame
	for path in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("TACTICS PASS: 12 chapters, class targeting/fallback, evasion, five unique ultimates, atomic ULT reservation, formation/save migration, pause, PC/mobile live resize and irreversible local reset/backup replacement")
	quit()
