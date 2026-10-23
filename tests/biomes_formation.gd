extends SceneTree
const Biomes = preload("res://scripts/biomes.gd")
const Tactics = preload("res://scripts/tactics.gd")
const Synergies = preload("res://scripts/team_synergies.gd")
const Art = preload("res://scripts/ultimate_art.gd")
const SAVE := "user://biomes_formation_isolated.json"
var game: Control
var captures := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): captures = arg.trim_prefix("--screenshots=")
	call_deferred("checks")

func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(captures)
	root.get_texture().get_image().save_png(captures.path_join(name + ".png"))

func prepare(ids: Array, stage: int) -> void:
	game.campaign.checkpoint.clear()
	game.run = IdleRun.new()
	assert(game.run.start_expedition(game.campaign, ids[0], "vigor"))
	for id in ids.slice(1):
		game.run.pending_choice = true
		game.run.offers.assign(["ally:" + id, "heart", "power"])
		assert(game.run.recruit(game.campaign, id))
	game.run.stage = stage
	game.run.wave = 2 if ExpeditionContent.is_boss(stage) else 0
	game.run.rooms_cleared = stage
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	for tick in 25:
		game._process(0.05)
		game.arena._process(0.05)
	for foe in game.run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.evasion = 0
		foe.pp = 0
	game.run.tactics.sync_totals()
	game.update_hud()

func checks() -> void:
	assert(Biomes.KEYS.size() == 8 and Synergies.PAIRS.size() == 3)
	assert(Synergies.PAIRS.hunters.heroes == ["joao", "maria"])
	assert(Synergies.PAIRS.powder.heroes == ["scarlet", "matches"])
	assert(Synergies.PAIRS.dance.heroes == ["mulan", "peter"])
	var unique := {}
	for biome in 8:
		assert(Biomes.ENEMIES[biome].size() == 6)
		var source := Biomes.sheet(biome)
		assert(source != null)
		for variant in 6:
			var frames := Biomes.frames(biome, variant)
			assert(frames.get_frame_count("attack") == 4)
			assert(not unique.has(Biomes.ENEMIES[biome][variant]))
			unique[Biomes.ENEMIES[biome][variant]] = true
			var poses := {}
			for frame in 4:
				var texture: AtlasTexture = frames.get_frame_texture("attack", frame)
				assert(Rect2(Vector2.ZERO, source.get_size()).encloses(texture.region))
				var image := texture.get_image()
				assert(image.get_used_rect().size.y > 40)
				assert(image.get_pixel(0, 0).a < 0.04, "Sprites retain real alpha; no opaque atlas rectangles")
				poses[hash(image.get_data())] = true
			assert(poses.size() == 4, "Every enemy has four different authored poses")
	assert(unique.size() == 48)
	for id in TaleCatalog.HEROES:
		var phases := {}
		for frame in 6:
			var texture: AtlasTexture = Art.frame(id, frame / 6.0)
			phases[str(texture.atlas.resource_path) + str(texture.region)] = true
			assert(texture.get_image().get_used_rect().has_area())
		assert(phases.size() == 6)
	# Every archetype is actually reachable through seeded encounter generation.
	for stage in 12:
		var seen := {}
		for seed_value in 90:
			var account := TaleCampaign.new()
			var run := IdleRun.new()
			run.start_expedition(account, "scarlet", "vigor")
			run.stage = stage
			run.wave = 2 if ExpeditionContent.is_boss(stage) else 0
			run.rng.seed = seed_value + 87
			run.spawn_enemy()
			var local := {}
			for foe in run.tactics.enemies:
				assert(not local.has(foe.variant))
				local[foe.variant] = true
				seen[foe.variant] = true
				assert(foe.biome == Biomes.biome(stage))
				if foe.get("mechanic", -1) == 3: assert(foe.row == "front")
				if not foe.has("mechanic") and not foe.get("banner", false) and not foe.has("binds"): assert(foe.row == Tactics.rank_for_class(foe["class"]))
		assert(seen.size() == 6)
	root.content_scale_size = Vector2i(540, 960)
	root.size = Vector2i(540, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.auto_ult = false
	prepare(["mulan", "peter", "alice"], 3)
	assert(game.run.actors.map(func(actor): return actor.row) == ["front", "middle", "back"])
	assert(game.arena.tracks[0].home.x > game.arena.tracks[1].home.x and game.arena.tracks[1].home.x > game.arena.tracks[2].home.x)
	await capture("three_ranks_ice_mobile")
	# A legacy checkpoint's forced front row cannot override class formation in a run.
	var checkpoint: Dictionary = game.run.to_checkpoint()
	for id in checkpoint.tactics.units: checkpoint.tactics.units[id].row = "front"
	var restored := IdleRun.new()
	restored.restore(game.campaign, checkpoint)
	assert(restored.actors.map(func(actor): return actor.row) == ["front", "middle", "back"])
	var actual_heights := []
	for id in TaleCatalog.HEROES:
		prepare([id], 0)
		var actor: AnimatedSprite2D = game.arena.heroes[0]
		var height: float = game.arena.hero_bounds(actor).size.y * actor.scale.y
		if id in ["puss", "matches"]: assert(is_equal_approx(height, game.arena.human_height() * 0.5))
		else: actual_heights.append(height)
	assert(float(actual_heights.max()) - float(actual_heights.min()) < 0.1)
	prepare(["scarlet", "alice", "ariel"], 6)
	var homes: Array = game.arena.tracks.map(func(track): return track.home)
	assert(homes[0].y == homes[1].y and homes[1].y == homes[2].y)
	assert(homes[0].x < homes[1].x and homes[1].x < homes[2].x)
	await capture("same_rank_fire_mobile")
	prepare(["mulan", "puss", "matches"], 4)
	assert(game.arena.tracks[1].home.y >= game.arena.tracks[0].home.y)
	assert(game.arena.tracks[0].home.x != game.arena.tracks[1].home.x)
	await capture("half_size_mobile")
	prepare(["mulan", "peter", "alice"], 6)
	for actor in game.run.actors: actor.evasion = 0
	var foe: Dictionary = game.run.tactics.enemies[0]
	foe["class"] = "assassin"
	foe.row = "middle"
	foe.action_count = 0
	foe.intent = {}
	assert(game.run.tactics.intent_for(0).target == 2)
	var hit: Dictionary = game.run.hit_party(0)
	assert(hit.target == 2 and hit.damage > 0)
	foe["class"] = "mage"
	foe.row = "back"
	foe.intent = {}
	hit = game.run.hit_party(0)
	assert(hit.targets.size() == 3 and hit.target_damage.size() == 3)
	foe["class"] = "vanguard"
	foe.row = "front"
	foe.intent = {}
	game.arena.sync_enemies()
	var home: Vector2 = game.arena.foe_homes[0]
	assert(game.arena.begin_enemy_attack(0, 0))
	game.combat_flow.begin({"side": "enemy", "index": 0})
	game.arena._process(0.25)
	game.arena._process(0.25)
	assert(game.arena.foes[0].position.x < home.x - 15)
	await capture("melee_dash_mobile")
	for tick in 24: game.arena._process(0.05)
	assert(game.arena.foes[0].position.is_equal_approx(home))
	prepare(["alice", "mulan", "matches"], 7)
	game.run.actors[0].energy = 100
	assert(game.try_ultimate(0))
	game.feedback._process(0.25)
	assert(game.feedback.cutin.size.y <= 64 and game.feedback.cutin.size.x < 300)
	await capture("alice_subtle_ult_mobile")
	for tick in 90:
		game.arena._process(0.05)
		game.feedback._process(0.05)
		if not game.arena.bursts.is_empty(): break
	game.arena._process(0.2)
	await capture("alice_cards_release_mobile")
	game.arena._process(0.25)
	await capture("alice_cards_spread_mobile")
	# Score and high score survive saves and cannot be paid/settled twice.
	prepare(["scarlet"], 3)
	game.run.phase = 5
	game.run.tactics.elapsed = 10
	game.run.tactics.damage_received = 0
	game.run.clear_encounter()
	assert(game.run.last_room_score == 625 and game.run.score == 625)
	var data: Dictionary = game.run.to_checkpoint()
	game.campaign.checkpoint = data
	game.campaign.best_score = 900
	assert(game.campaign.save_to(SAVE))
	var saved := TaleCampaign.new()
	assert(saved.load_from(SAVE) and saved.best_score == 900)
	restored = IdleRun.new()
	restored.restore(saved, saved.checkpoint)
	assert(restored.score == 625)
	var result := saved.finish_expedition(restored.to_checkpoint(), false)
	assert(result.score == 625 and saved.best_score == 900)
	assert(saved.finish_expedition(restored.to_checkpoint(), false).is_empty())
	for stage in [0, 1, 3, 5, 6, 7, 8, 10]:
		prepare(["mulan", "peter", "alice"], stage)
		await capture("biome_%s_mobile" % Biomes.KEYS[Biomes.biome(stage)])
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	prepare(["scarlet", "alice", "ariel"], 6)
	await capture("same_rank_fire_pc")
	root.content_scale_size = Vector2i(360, 800)
	root.size = Vector2i(360, 800)
	await process_frame
	game.center_content()
	await capture("same_rank_narrow_mobile")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("BIOMES FORMATION PASS: 48 unique enemies/192 poses, 8 scenery stages, 12 generated six-frame ULTs, seeded encounter variety, three class ranks, side-by-side allies, equal humans/half-size cat and child, subtle ULT, mage AOE, melee dash, backline assassination, score persistence and mobile/PC")
	quit()
