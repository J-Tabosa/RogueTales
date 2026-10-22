extends SceneTree
const Arena = preload("res://scripts/arena.gd")
const Hero = preload("res://scripts/hero.gd")


func _initialize() -> void:
	call_deferred("checks")


func checks() -> void:
	assert(TaleCatalog.HEROES.size() == 5 and not TaleCatalog.HERO_SCENES.has("cinderella"))
	assert(not FileAccess.file_exists("res://scenes/heroes/cinderella.tscn"))
	# Old saves retain progress and refund the removed heroine once, without a broken party.
	var migrated := TaleCampaign.new()
	migrated.load_data(
		{
			"version": 1,
			"gold": 10,
			"unlocked": ["scarlet", "rapunzel", "cinderella"],
			"party": ["rapunzel", "cinderella"],
			"levels": {"cinderella": [2, 1, 0]},
			"cleared": [0.0, 1.0],
			"checkpoint": {"stage": 1, "wave": 0, "health": [100, 100]}
		}
	)
	assert(migrated.gold == 145 and migrated.party == ["rapunzel"] and migrated.cleared == [0, 1])
	assert(migrated.checkpoint.is_empty() and not migrated.levels.has("cinderella"))
	var again := TaleCampaign.new()
	again.load_data(migrated.to_dict())
	assert(again.gold == 145 and again.unlocked.size() == 2)
	# Offline settlement is capped, idempotent and rejects backwards clock changes.
	var bank := TaleCampaign.new()
	bank.settle_idle(1000)
	bank.settle_idle(2000)
	assert(bank.idle_seconds == 0)
	bank.complete_stage(0)
	bank.choose_memory(0, "hope")
	bank.settle_idle(2060)
	assert(bank.idle_reward().gold == 10 and bank.idle_reward().xp == 4)
	var before: int = bank.gold
	var earned := bank.claim_idle(2060)
	assert(earned.gold == 10 and bank.gold == before + 10 and bank.claim_idle(2060).is_empty())
	bank.settle_idle(2060 + 100 * 3600)
	assert(bank.idle_seconds == 8 * 3600 and bank.idle_reward().gold == 4800)
	var anchor: int = bank.idle_anchor
	bank.settle_idle(anchor - 5000)
	assert(bank.idle_anchor == anchor and bank.idle_seconds == 8 * 3600)
	bank.claim_idle(anchor)
	assert(bank.idle_seconds == 0)
	# Hero training spends real XP/gold, changes stats, and is locked during an expedition.
	bank.grant_xp(300)
	var base := TaleCatalog.hero_stats("scarlet", bank.levels.scarlet, bank.choices, 1)
	assert(bank.level_hero("scarlet") and bank.hero_levels.scarlet == 2)
	var trained := TaleCatalog.hero_stats("scarlet", bank.levels.scarlet, bank.choices, 2)
	assert(trained.max_hp > base.max_hp and trained.damage > base.damage and bank.player_level > 1)
	bank.checkpoint = {"stage": 0}
	assert(not bank.level_hero("scarlet"))
	bank.checkpoint.clear()
	assert(bank.claim_achievement("first") and not bank.claim_achievement("first"))
	assert(not bank.claim_achievement("ending"))
	# Apples move on a straight fast shot. Only the bomb retains its lob.
	var arena := Node2D.new()
	arena.set_script(Arena)
	arena.party_scenes.assign([TaleCatalog.HERO_SCENES.mulan, TaleCatalog.HERO_SCENES.rapunzel])
	root.add_child(arena)
	arena.set_process(false)
	var origin := Vector2(170, 230)
	assert(
		(
			arena.projectile_point(Hero.AttackStyle.APPLE, origin, 0.5)
			== origin.lerp(Vector2(402, 253), 0.5)
		)
	)
	assert(
		(
			arena.projectile_point(Hero.AttackStyle.BOMB, origin, 0.5).y
			< origin.lerp(Vector2(402, 253), 0.5).y
		)
	)
	assert(not arena.has_method("draw_hair_attack") and not arena.has_method("draw_sword_attack"))
	for index in 2:
		var actor: AnimatedSprite2D = arena.heroes[index]
		var home: Vector2 = arena.tracks[index].home
		var hits: Array[int] = [0]
		var contact: Array[Vector2] = [Vector2.ZERO]
		var callback := func(who: int):
			if who == index:
				hits[0] += 1
				contact[0] = arena.heroes[who].position
		arena.attack_hit.connect(callback)
		assert(arena.attack(index))
		var duration: float = arena.tracks[index].duration
		while arena.tracks[index].time >= 0:
			arena._process(0.01)
		assert(hits[0] == 1 and contact[0].x >= 330 and actor.position.distance_to(home) < 0.01)
		arena.attack_hit.disconnect(callback)
		assert(arena.attack(index))
		arena._process(duration * 0.25)
		var held: Vector2 = actor.position
		arena.frozen = true
		arena._process(0.2)
		assert(actor.position == held)
		arena.frozen = false
		arena.reset_effects()
		for tick in 5:
			arena._process(0.05)
		assert(actor.position.distance_to(home) < 0.01)
	arena.queue_free()
	await process_frame
	# New screens, preferences, native HD scaling, profile editing and replay farming.
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://idle_test_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.complete_stage(0)
	game.campaign.choose_memory(0, "hope")
	game.show_heroes()
	assert(game.state == "heroes")
	game.campaign.unlocked.append("rapunzel")
	game.campaign.grant_xp(100)
	game.show_hero_details("scarlet")
	game.train_hero()
	assert(game.state == "hero" and game.campaign.hero_levels.scarlet == 2)
	game.show_profile()
	game.edit_profile()
	game.profile_name.text = "Milorde"
	game.select_avatar("rapunzel")
	game.save_profile()
	assert(game.campaign.player_name == "Milorde" and game.campaign.avatar == "rapunzel")
	game.campaign.music_volume = 0
	game.campaign.effects_volume = 0
	game.campaign.high_quality = false
	game.campaign.fps_limit = 30
	game.apply_preferences()
	assert(game.audio.music.volume_db <= -70 and game.audio.effects_gain == 0)
	assert(root.msaa_2d == Viewport.MSAA_DISABLED and Engine.max_fps == 30)
	assert(game.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
	assert(game.content.scale.x > 0 and game.content.position.x >= 0, "The responsive interface must fit the viewport")
	game.campaign.auto_repeat = true
	game.start_stage(0)
	assert(game.state == "loading")
	for step in 4:
		game._process(0.1)
	assert(game.state == "travel")
	assert(not game.arena.high_quality)
	for tick in 4000:
		game._process(0.05)
		if is_instance_valid(game.arena):
			game.arena.set_process(false)
			game.arena._process(0.05)
		if game.campaign.total_wins >= 3:
			break
	assert(
		game.campaign.total_wins >= 3,
		"Auto patrol should replay and collect rewards without dialogue stops"
	)
	game.leave_battle()
	assert(game.state == "menu" and game.farm_timer < 0)
	game.queue_free()
	await process_frame
	for path in ["user://idle_test_isolated.json", "user://idle_test_isolated.json.bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Engine.max_fps = 60
	print(
		"PASS: removed-hero migration/refund; offline cap/claim/clock; hero XP and training; milestones; straight apple; melee dash/contact/return/cancel/pause; hero/profile screens; audio/graphics prefs; 1080p scaling; automatic replay"
	)
	quit()
