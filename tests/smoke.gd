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
	# The five profiles retain their damage, healing and unique upgrades.
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
	all.party.assign(["mulan", "rapunzel", "ariel"])
	rules.setup(all, 5)
	rules.spawn_enemy()
	assert(rules.actors[0].shield == 0 and rules.enemy_interval() > 2.5)
	var hit := rules.hit_party()
	assert(hit.target == 0 and hit.absorbed == 0 and hit.damage > 0)
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
	# Twelve chapters with ordinary XP/gold, temporary recruitment and replay farming on defeat.
	for chapter in TaleCatalog.CHAPTER_COUNT:
		assert(game.campaign.can_play(chapter))
		train_party()
		game.start_stage(chapter)
		assert(game.state == "story")
		game.finish_story()
		assert(game.state == "loading")
		finish_loading()
		assert(game.state == "travel")
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
		drive_combat(42, chapter == 0)
		for retry in 8:
			if game.state == "result":
				break
			# Idle progression includes replaying an easier cleared chapter, with no free currency.
			for farm in 2:
				train_party()
				game.begin_chapter_combat(maxi(0, chapter - 3))
				drive_combat(100 + retry * 13 + farm)
				assert(game.state == "result", "The earlier chapter must remain farmable")
			train_party()
			game.begin_chapter_combat(chapter)
			drive_combat(200 + retry * 17)
		assert(
			game.state == "result",
			"Chapter %d must be reachable with earned progression" % (chapter + 1)
		)
		assert(game.campaign.cleared.has(chapter) and game.campaign.party.size() <= 3)
		game.show_story(chapter, "outro")
		game.finish_story()
		assert(game.state == "memory")
		game.save_memory("hope")
		assert(game.campaign.checkpoint.is_empty())
	assert(game.campaign.cleared.size() == TaleCatalog.CHAPTER_COUNT)
	assert(game.state == "ending" and game.campaign.choices.size() == TaleCatalog.CHAPTER_COUNT)
	var saved := TaleCampaign.new()
	assert(saved.load_from(test_path) and saved.cleared.size() == TaleCatalog.CHAPTER_COUNT)
	var gold: int = game.campaign.gold
	game.show_story(0, "intro", 0, true)
	game.finish_story()
	assert(game.state == "journal" and game.campaign.gold == gold)
	# Party formation rules, fallback targets, defeat and checkpoint disposal.
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
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
	assert(game.state == "hero")
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
		"PASS: 12 chapters + ending; temporary recruitment; 3-member formation; unique skills/upgrades; earned-income balance; relics/checkpoint; atomic saves/backup; pause/2x; attack recovery/one hit; idle; debug Ctrl+B guard; all screens; defeat and replay"
	)
	quit()


func train_party() -> void:
	var trained := true
	while trained:
		trained = false
		for id in game.campaign.party:
			if game.campaign.can_level_hero(id):
				assert(game.campaign.level_hero(id))
				trained = true
	for branch in 3:
		for id in game.campaign.party:
			game.campaign.buy_upgrade(id, branch)


func drive_combat(seed_value: int, check_resume: bool = false) -> void:
	game.run.rng.seed = seed_value
	game.arena.set_process(false)
	for tick in 12000:
		game._process(0.05)
		if is_instance_valid(game.arena):
			game.arena.set_process(false)
			game.arena._process(0.05)
		if game.state == "choice":
			if check_resume and game.run.wave == 1:
				var offered: Array = game.run.offers.duplicate()
				game.leave_battle()
				game.resume_checkpoint()
				finish_loading()
				game.arena.set_process(false)
				assert(game.run.offers == offered and game.state == "choice")
			game.select_relic(game.run.offers[0])
			if game.state == "replacement":
				var weakest := 0
				for slot in game.run.actors.size():
					if (
						game.run.actors[slot].hp / game.run.actors[slot].max_hp
						< game.run.actors[weakest].hp / game.run.actors[weakest].max_hp
					):
						weakest = slot
				game.confirm_replacement(game.run.offers[0], weakest)
		if game.state in ["result", "defeat"]:
			return
	assert(false, "Combat stalled in state: " + game.state)


func finish_loading() -> void:
	for step in 8:
		if game.state != "loading":
			return
		game._process(0.1)
	assert(false, "Mission transition did not finish")
