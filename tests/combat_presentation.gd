extends SceneTree
const Enemy = preload("res://scripts/enemy.gd")
const Audio = preload("res://scripts/audio.gd")
var game: Control
const SAVE := "user://combat_presentation_isolated.json"


func _initialize() -> void:
	call_deferred("checks")


func checks() -> void:
	for chapter in 8:
		var actor: AnimatedSprite2D = Enemy.warm(chapter).instantiate()
		root.add_child(actor)
		actor.visible = true
		for id in ["idle", "attack", "boss_idle", "boss_attack"]:
			assert(actor.sprite_frames.get_frame_count(id) == 4)
			for frame in 4:
				var texture: AtlasTexture = actor.sprite_frames.get_frame_texture(id, frame)
				assert(texture.atlas.get_width() > 1000 and texture.region.size.x > 250)
				assert(texture.get_size() == Vector2(400, 400), "Frames must keep a fixed canvas")
				assert(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region))
		actor.advance(0.1, false, 0.1, 2.4)
		assert(actor.animation == "idle" and actor.frame == 0)
		actor.advance(0.0, false, 0.999, 2.4)
		assert(actor.animation == "attack" and actor.frame == 1)
		actor.begin_strike(false)
		assert(actor.frame == 2)
		actor.advance(0.1, false, 0, 2.4)
		assert(actor.animation == "attack")
		actor.reset_damage()
		actor.advance(0, true, 0, 2.4)
		assert(actor.animation == "boss_idle")
		actor.hurt()
		assert(actor.modulate == Color("ff4545"))
		actor.advance(0.1, true, 0, 2.4)
		assert(actor.modulate == Color.WHITE)
		var remaining: float = actor.hurt_left
		actor.hurt(true)
		assert(actor.hurt_left == remaining, "DOT must not keep a permanent red tint")
		actor.advance(0.04, true, 0, 2.4)
		assert(actor.modulate.r > actor.modulate.g)
		actor.advance(0.2, true, 0, 2.4)
		assert(actor.modulate == Color.WHITE)
		actor.free()
	assert(Enemy.scene_cache.size() <= 2)
	var sound := Node.new()
	sound.set_script(Audio)
	root.add_child(sound)
	assert(sound.voices.size() == 6 and sound.attack_players.size() == 2)
	for id in ["explosion", "win", "achievement"]:
		assert(sound.effects[id].get_length() >= 0.5)
	for id in Audio.ATTACK_CALLS:
		assert(sound.calls[id].get_length() > 0.15)
	assert(sound.reserve_call("scarlet", 100))
	assert(not sound.reserve_call("rapunzel", 100.1))
	assert(sound.reserve_call("rapunzel", 100.5))
	assert(not sound.reserve_call("scarlet", 101))
	assert(sound.reserve_call("scarlet", 104))
	sound.apply_volume(0, 0, 0)
	assert(sound.attack_gain == 0 and sound.effects_gain == 0)
	sound.free()
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.set_voice_volume(0.23)
	var saved := TaleCampaign.new()
	assert(saved.load_from(SAVE) and is_equal_approx(saved.voice_volume, 0.23))
	game.begin_chapter_combat(0)
	game.spawn_enemy()
	game.arena.set_process(false)
	game.arena._process(0)
	assert(game.arena.enemy.visible)
	game.arena.hurt(0)
	assert(game.arena.heroes[0].modulate.r > game.arena.heroes[0].modulate.g)
	game.arena.frozen = true
	game.arena._process(0.1)
	assert(game.arena.tracks[0].hurt == 0.24)
	game.arena.frozen = false
	game.arena.speed = 2
	game.arena._process(0.13)
	assert(game.arena.heroes[0].modulate == Color.WHITE)
	for foe in game.run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.evasion = 0
	game.run.tactics.sync_totals()
	game.on_attack_hit(0)
	assert(game.arena.enemy.hurt_left > 0)
	game.arena.enemy.reset_damage()
	game.run.tactics.enemies[0].burn = 3
	game.run.tactics.enemies[0].burn_left = 2
	game.arena._process(0.06) # Hit-stop freezes simulation, then status damage resumes.
	game._process(0.05)
	assert(game.arena.enemy.hurt_left > 0)
	game.abandon_expedition()
	game.queue_free()
	await process_frame
	for path in [SAVE, SAVE + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print(
		"COMBAT PRESENTATION PASS: 8 sheets, 16 enemies, synced attacks, damage flashes, bounded audio and saved voice volume"
	)
	quit()
