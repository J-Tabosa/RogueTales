extends SceneTree
const Sunflowers = preload("res://scripts/sunflower_enemies.gd")
const Balance = preload("res://scripts/enemy_balance.gd")
const Art = preload("res://scripts/sunflower_art.gd")
const Flow = preload("res://scripts/battle_flow.gd")
const Rules = preload("res://scripts/combat_rules.gd")
const Model = preload("res://scripts/enemy.gd")
const Formation = preload("res://scripts/formation_layout.gd")
var destination := ""

func _initialize() -> void:
	call_deferred("test")

func configure(run: IdleRun) -> void:
	run.journey = {"format": 1, "season": "summer", "path": ["FlorestaVerao", Sunflowers.MAP]}
	run.stage = 1
	run.phase = 5
	run.room_kind = "battle"
	var actor := run.actors[0]
	actor.hp = 10000.0
	actor.max_hp = actor.hp
	actor.evasion = 0.0
	actor.base_evasion = 0.0
	actor.initiative = 100.0

func test() -> void:
	var campaign := preload("res://tests/test_accounts.gd").legacy()
	var run := IdleRun.new()
	assert(run.start_expedition(campaign, "scarlet", "blessing:scarlet:0"))
	configure(run)
	run.phase = 0
	var seen := {}
	for seed_value in 40:
		run.rng.seed = seed_value
		run.spawn_enemy()
		assert(not run.tactics.enemies.is_empty() and run.tactics.enemies.size() <= ExpeditionContent.enemy_limit(1))
		for foe in run.tactics.enemies:
			assert(foe.sunflower_id in Sunflowers.COMMON and not foe.boss and foe.attacks == 1)
			seen[foe.sunflower_id] = true
			var hit := run.hit_party(foe.slot)
			assert(hit.damage > 0 and not hit.evaded)
			var actor := run.actors[hit.target]
			assert(is_equal_approx(float(actor.poison), float(Sunflowers.DATA[foe.sunflower_id][7])))
			Rules.cleanse(actor)
	assert(seen.size() == 3)
	assert(Balance.profiles[Sunflowers.WORKER].vida_base > Balance.profiles.phase1_summer_raccoon.vida_base * .85)
	assert(Balance.profiles.sunflower_wasp.iniciativa > Balance.profiles.phase1_summer_falcon.iniciativa)
	assert(Balance.profiles.sunflower_drone.def_fisica_base > Balance.profiles[Sunflowers.WORKER].def_fisica_base)
	run.phase = 4
	run.spawn_enemy()
	assert(run.tactics.enemies.is_empty())
	run.journey.path[1] = "CamposVerdejantes"
	run.phase = 5
	run.spawn_enemy()
	assert(not run.tactics.enemies[0].has("sunflower_id"))
	configure(run)
	assert(run.boss_name() == "Rainha Abelha")
	var opening_sizes := {}
	for seed_value in 24:
		run.rng.seed = seed_value
		run.spawn_enemy()
		var queen: Dictionary = run.tactics.enemies[0]
		assert(run.tactics.enemies.size() == 1 and queen.boss and queen["class"] == "mage")
		assert(queen.mana == 120 and not queen.has("mechanic"))
		var flow := Flow.new()
		flow.bind(run)
		var first := flow.next_action()
		assert(first.side == "enemy" and first.index == 0)
		assert(run.tactics.commit_intent(0).key == Sunflowers.SUMMON)
		flow.begin(first)
		var opening := run.hit_party(0)
		flow.complete()
		opening_sizes[opening.summoned] = true
		assert(queen.mana == 0 and queen.casts == 1)
		assert(flow.next_action().side == "ally" and flow.preview().all(func(entry): return entry.side != "enemy"))
		for i in range(1, run.tactics.enemies.size()):
			var worker: Dictionary = run.tactics.enemies[i]
			assert(worker.sunflower_id == Sunflowers.WORKER and worker.summoned and worker.slot == i)
			assert(worker.hp < Balance.profiles[Sunflowers.WORKER].vida_base)
		for cast in 2:
			for strike in 4:
				assert(run.tactics.intent_for(0).key == "sunflower_strike")
				var hit := run.hit_party(0)
				assert(hit.damage > 0 and queen.mana == (strike + 1) * 30)
				assert(Rules.has_status(run.actors[hit.target], "poison"))
			var next := run.hit_party(0)
			assert(next.non_attack and next.summoned in [2, 3])
		assert(queen.casts == 3 and queen.mana == 0)
		assert(Formation.max_stack(run.tactics.enemies) <= Formation.MAX_PER_ROW and run.tactics.enemies.size() <= 9)
		for strike in 5: assert(not run.hit_party(0).has("summoned"))
		assert(queen.casts == 3)
		configure(run)
	assert(opening_sizes.has(2) and opening_sizes.has(3))
	assert(Model.hurt_color(.24, true).g > Model.hurt_color(.24, true).r)
	assert(Model.hurt_color(.24).r > Model.hurt_color(.24).g)
	for id in Sunflowers.DATA:
		var art := Art.frames(id)
		for anim in art.get_animation_names():
			for n in art.get_frame_count(anim):
				var image := art.get_frame_texture(anim, n).get_image()
				assert(image.get_size() == Vector2i(Art.CELL, Art.CELL))
				assert(image.get_pixel(0, 0).a == 0.0 and image.get_used_rect().has_area())
	assert(await test_battle_view(campaign))
	print("SUNFLOWER ENEMIES: roster, balance, summoning, animations and poison passed")
	quit()

func test_battle_view(campaign: TaleCampaign) -> bool:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		destination = args[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://sunflower_test_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = campaign
	game.campaign.window_mode = "windowed"
	game.campaign.window_mode_selected = true
	game.apply_window_mode()
	for dimensions in [Vector2i(1280, 720), Vector2i(540, 960)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		game.center_content()
		game.run = IdleRun.new()
		assert(game.run.start_expedition(campaign, "scarlet", "blessing:scarlet:0"))
		configure(game.run)
		game.enter_encounter()
		game.spawn_enemy()
		for frame in 240:
			if not game.arena.warming_attacks(): break
			await process_frame
		assert(not game.arena.warming_attacks())
		game.state = "battle"
		game.arena.set_process(false)
		game.arena.entrance_left = 0
		game.arena.speed = 1.0
		var queen_sprite: AnimatedSprite2D = game.arena.foes[0]
		assert(game.arena.foe_widgets[0].energy.visible and game.arena.foe_widgets[0].energy.value == 120)
		game.process_tactical_combat(.4)
		assert(game.arena.enemy_track.animation == "summon" and game.arena.enemy_track.target == -1)
		game.arena._process(.25)
		game.arena._process(.25)
		assert(game.arena.foes.size() == game.run.tactics.enemies.size() and game.arena.foes.size() in [3, 4])
		assert(game.arena.foes[0] == queen_sprite and game.arena.foe_widgets[0].energy.value == 0)
		for tick in 5: game.arena._process(.15)
		await capture("colmeia-%d" % dimensions.x)
		var actor: Dictionary = game.run.actors[0]
		assert(game.arena.begin_enemy_attack(0, 0))
		assert(game.arena.enemy_track.animation == "boss_attack")
		game.arena._process(.20)
		game.arena._process(.20)
		await capture("ferrao-%d" % dimensions.x)
		game.arena._process(.20)
		assert(Rules.has_status(actor, "poison") and game.arena.heroes[0].modulate.g > game.arena.heroes[0].modulate.r)
		assert(not game.arena.enemy_impacts.is_empty() and game.arena.enemy_impacts[-1].sunflower)
		await capture("impacto-%d" % dimensions.x)
		Rules.cleanse(actor)
		game.arena.hurt(0)
		assert(game.arena.heroes[0].modulate.r > game.arena.heroes[0].modulate.g)
		Rules.status(game.run.tactics.enemies[1], "poison", actor.id, 1, 2.0)
		game.arena.hurt_enemy(1)
		assert(game.arena.foes[1].modulate.g > game.arena.foes[1].modulate.r)
	game.queue_free()
	await process_frame
	return true

func capture(title: String) -> void:
	if destination.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join(title + ".png"))
