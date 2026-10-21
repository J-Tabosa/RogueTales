extends SceneTree
## Run with Godot 4.7: godot --headless --path . --script tests/smoke.gd
const HeroScript = preload("res://scripts/hero.gd")
var game: Control
var test_path := "user://campaign_smoke_isolated.json"


func _initialize() -> void:
	call_deferred("checks")


func checks() -> void:
	# Resource independence and long idle holds survive the expanded battle system.
	var one: AnimatedSprite2D = TaleCatalog.HERO_SCENES.scarlet.instantiate()
	var two: AnimatedSprite2D = TaleCatalog.HERO_SCENES.scarlet.instantiate()
	root.add_child(one)
	root.add_child(two)
	one.set_process(false)
	two.set_process(false)
	assert(one.sprite_frames != two.sprite_frames and one.material != two.material)
	one.show_animation("idle")
	one._process(2)
	assert(one.frame == 0 and not one.is_playing() and one.idle_weight == 0)
	one._start_idle_variation(HeroScript.IdleState.BLINK)
	await create_timer(0.4).timeout
	assert(one.is_idle_resting())
	one.show_animation("walk")
	one.set_frame_and_progress(4, 0.5)
	one._process(0.1)
	assert(is_equal_approx(one.material.get_shader_parameter("walk_phase"), 4.5 / 16.0 * TAU))
	one.sprite_frames.set_animation_speed("attack", 5)
	one.seek_animation("attack", 1.25)
	assert(one.frame == 6 and one.sprite_frames.get_animation_speed("attack") == 5)
	assert(two.sprite_frames.get_animation_speed("attack") == 10)
	one.free()
	two.free()
	# Save roundtrip, backup recovery, validation and no upgrades during expeditions.
	var profile := TaleCampaign.new()
	assert(profile.party == ["scarlet"] and not profile.can_play(1))
	assert(profile.buy_upgrade("scarlet", 0) and profile.gold == 45)
	assert(not profile.buy_upgrade("ariel", 0))
	profile.checkpoint = {"stage": 0, "wave": 0, "health": [200.0]}
	assert(not profile.buy_upgrade("scarlet", 1))
	assert(not profile.toggle_party("scarlet"))
	assert(profile.save_to(test_path))
	profile.gold = 99
	assert(profile.save_to(test_path))
	var restored := TaleCampaign.new()
	assert(restored.load_from(test_path))
	assert(restored.gold == 99 and restored.levels.scarlet[0] == 1)
	var bad := FileAccess.open(test_path, FileAccess.WRITE)
	bad.store_string("{broken")
	bad.close()
	assert(restored.load_from(test_path) and restored.gold == 45)
	var invalid := TaleCampaign.new()
	invalid.load_data(
		{
			"party": ["missing"],
			"unlocked": ["missing"],
			"levels": {"scarlet": [999, -4, 2]},
			"cleared": [7],
			"checkpoint": {"stage": 9}
		}
	)
	assert(
		(
			invalid.party == ["scarlet"]
			and invalid.levels.scarlet == [5, 0, 2]
			and invalid.cleared.is_empty()
			and invalid.checkpoint.is_empty()
		)
	)
	# All six innate/upgrade effects operate on combat, including shields and healing.
	var all := TaleCampaign.new()
	all.unlocked.assign(TaleCatalog.HEROES.keys())
	all.party.assign(["scarlet", "snow_white", "mulan"])
	var rules := IdleRun.new()
	rules.setup(all, 7)
	rules.spawn_enemy()
	rules.rng.seed = 5
	rules.hit_enemy(0)
	rules.hit_enemy(1)
	var before: float = rules.enemy_hp
	rules.tick_status(1)
	assert(rules.enemy_hp < before and rules.burn_left > 0 and rules.poison_left > 0)
	rules.hit_enemy(2)
	rules.hit_enemy(2)
	var combo := rules.hit_enemy(2)
	assert(combo.message == "Terceiro corte")
	all.party.assign(["mulan", "cinderella", "ariel"])
	rules.setup(all, 5)
	rules.spawn_enemy()
	assert(rules.actors[0].shield == 8 and rules.enemy_interval() > 2.5)
	var hit := rules.hit_party()
	assert(hit.target == 0 and hit.absorbed == 8)
	rules.actors[0].hp = 100
	rules.hit_enemy(2)
	rules.hit_enemy(2)
	rules.hit_enemy(2)
	assert(rules.actors[0].hp > 100)
	all.party.assign(["rapunzel", "snow_white", "scarlet"])
	all.levels.rapunzel = [2, 2, 2]
	rules.setup(all, 5)
	rules.spawn_enemy()
	assert(rules.actors[0].max_hp == 216)
	rules.actors[2].hp = 50
	for count in 3:
		rules.hit_enemy(0)
	assert(rules.actors[2].hp == 59)
	var old_hp: float = rules.actors[1].hp
	rules.actors[1].hp -= 10
	rules.hit_enemy(1)
	assert(rules.actors[1].hp == old_hp - 9)
	rules.actors[0].hits = 2
	var checkpoint := rules.to_checkpoint()
	var recovered := IdleRun.new()
	recovered.restore(all, checkpoint)
	assert(recovered.actors[0].hits == 2)
	assert(recovered.rng.randf() == rules.rng.randf())
	# No normal route opens debug. Ctrl+B works even while a control owns focus.
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = test_path
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.show_menu()
	var wrapped: Label = game.label(
		game.page,
		"Uma voz que atravessa o mar não vai se calar diante de uma página rasgada.",
		Rect2(0, 0, 492, 57),
		15
	)
	await process_frame
	assert(
		wrapped.size == Vector2(492, 57), "Labels must wrap without retaining an oversized minimum"
	)
	game.show_menu()
	assert(not game.debug_enabled)
	game.show_preview()
	assert(game.state == "menu")
	var key := InputEventKey.new()
	key.keycode = KEY_B
	key.physical_keycode = KEY_B
	key.pressed = true
	key.ctrl_pressed = true
	game._input(key)
	assert(game.debug_enabled)
	game.show_preview()
	assert(game.state == "preview")
	game.preview_anim("attack")
	game.arena.set_process(false)
	var hits: Array[int] = [0]
	game.arena.attack_hit.connect(func(_index: int): hits[0] += 1)
	var timeline: Dictionary = game.arena.tracks[0]
	var duration: float = timeline.duration
	for tick in 19:
		game.arena._process(duration / 20.0)
	assert(hits[0] == 1 and timeline.time >= 0, "Attack keeps its recovery after one impact")
	game.arena.frozen = true
	var held: float = timeline.time
	game.arena._process(0.2)
	assert(timeline.time == held)
	game.arena.frozen = false
	game.arena.preview = false
	game.arena._process(duration / 10)
	assert(hits[0] == 1 and timeline.time < 0)
	game._input(key)
	assert(not game.debug_enabled and game.state == "menu")
	# Eight chapters, genuine UI combat, relic choices, recruiting, persistence and ending.
	for chapter in 8:
		assert(game.campaign.can_play(chapter))
		game.campaign.checkpoint.clear()
		# Buy affordable upgrades between chapters; the same income is available in normal play.
		for id in game.campaign.party:
			for branch in 3:
				if game.campaign.gold >= game.campaign.upgrade_cost(id, branch):
					game.campaign.buy_upgrade(id, branch)
		# Test a tank + healer formation as soon as it is recruited.
		if chapter >= 3:
			game.campaign.party.assign(["mulan", "rapunzel", "scarlet"])
		game.start_stage(chapter)
		assert(game.state == "story")
		game.finish_story()
		assert(game.state == "travel")
		game.run.rng.seed = 42
		game.arena.set_process(false)
		for actor in game.arena.heroes:
			actor.set_process(false)
		assert(game.arena.heroes.size() == game.campaign.party.size())
		if chapter == 0:
			game.toggle_pause()
			var travel: float = game.travel_timer
			game._process(0.2)
			game.arena._process(0.2)
			assert(game.travel_timer == travel)
			game.resume_battle()
			game.toggle_speed()
			assert(game.game_speed == 2)
		for tick in 12000:
			game._process(0.05)
			if is_instance_valid(game.arena):
				game.arena._process(0.05)
			if game.state == "choice":
				if chapter == 0 and game.run.wave == 1:
					var offered: Array = game.run.offers.duplicate()
					game.leave_battle()
					game.resume_checkpoint()
					game.arena.set_process(false)
					assert(game.run.offers == offered and game.state == "choice")
				game.select_relic(game.run.offers[0])
			if game.state in ["result", "defeat"]:
				break
		assert(
			game.state == "result",
			"Chapter %d should be winnable with earned upgrades" % (chapter + 1)
		)
		assert(game.campaign.cleared.has(chapter))
		assert(game.campaign.party.size() <= 3)
		game.show_story(chapter, "outro")
		game.finish_story()
		assert(game.state == "memory")
		game.save_memory("hope")
		assert(game.campaign.checkpoint.is_empty())
	assert(game.campaign.unlocked.size() == 6 and game.campaign.cleared.size() == 8)
	assert(game.state == "ending" and game.campaign.choices.size() == 8)
	var saved := TaleCampaign.new()
	assert(saved.load_from(test_path))
	assert(saved.cleared.size() == 8)
	var gold: int = game.campaign.gold
	game.show_story(0, "intro", 0, true)
	game.finish_story()
	assert(game.state == "journal" and game.campaign.gold == gold)
	# Party formation rules, fallback targets, defeat and checkpoint disposal.
	game.campaign.party.assign(["scarlet", "rapunzel", "ariel"])
	assert(not game.campaign.toggle_party("mulan"))
	assert(game.campaign.promote("ariel") and game.campaign.party[0] == "ariel")
	game.begin_chapter_combat(7)
	game.arena.set_process(false)
	game.spawn_enemy()
	game.run.actors[0].hp = 0
	assert(game.run.hit_party().target == 1)
	for actor in game.run.actors:
		actor.hp = 0
	game.enemy_timer = 0
	game._process(0.05)
	assert(game.state == "defeat" and game.campaign.checkpoint.is_empty())
	game.show_upgrades()
	assert(game.state == "upgrade")
	game.show_party()
	game.show_map()
	game.show_settings()
	game.show_help()
	game.show_credits()
	game.queue_free()
	await process_frame
	for path in [test_path, test_path + ".bak", test_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print(
		"PASS: 8 chapters + ending; six recruits; 3-member formation; unique skills/upgrades; earned-income balance; relics/checkpoint; atomic saves/backup; pause/2x; attack recovery/one hit; idle; debug Ctrl+B guard; all screens; defeat and replay"
	)
	quit()
