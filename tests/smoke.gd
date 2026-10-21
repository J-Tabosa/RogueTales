extends SceneTree
## godot --headless --path . --script tests/smoke.gd
const HeroScript = preload("res://scripts/hero.gd")
var game: Control


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	seed(42)
	# Saved resources, FPS and transforms stay editable and local to each scene.
	var scene: PackedScene = load("res://scenes/heroes/scarlet.tscn")
	var first: AnimatedSprite2D = scene.instantiate()
	var second: AnimatedSprite2D = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	assert(first.sprite_frames != second.sprite_frames)
	assert(first.material != second.material)
	first.set_process(false)
	second.set_process(false)
	# Standing must stay still, rather than continuously cycling the frames.
	first.show_animation("idle")
	assert(first.frame == 0 and not first.is_playing())
	first._process(2.0)
	assert(first.idle_state == HeroScript.IdleState.REST)
	assert(first.frame == 0 and first.idle_weight == 0.0)
	first.idle_wait_left = 0.1
	first.speed_scale = 0.0
	first._process(0.5)
	assert(first.idle_wait_left == 0.1)
	first.speed_scale = 1.0
	first._process(0.2)
	assert(first.idle_state != HeroScript.IdleState.REST)
	# The closed-eye drawing exists and a real blink returns to the held pose.
	assert(first.sprite_frames.get_frame_texture("idle_blink", 2).resource_name == "idle_07")
	first._start_idle_variation(HeroScript.IdleState.BLINK)
	assert(first.animation == &"idle_blink")
	await create_timer(0.5).timeout
	assert(first.idle_state == HeroScript.IdleState.REST)
	assert(first.frame == 0 and not first.is_playing())
	assert(first.idle_wait_left >= first.idle_min_wait)
	assert(first.idle_wait_left <= first.idle_max_wait)
	first._start_idle_variation(HeroScript.IdleState.SWAY)
	first._process(0.5)
	assert(first.idle_weight > 0.6)
	# Walking interrupts the idle event and follows frame position, even at 2×.
	first.show_animation("walk")
	first.set_frame_and_progress(4, 0.5)
	first._process(0.5)
	assert(first.idle_weight < 0.01)
	assert(first.walk_weight > 0.99)
	assert(first.idle_state == HeroScript.IdleState.REST)
	var phase: float = first.material.get_shader_parameter("walk_phase")
	assert(is_equal_approx(phase, 4.5 / 16.0 * TAU))
	first.speed_scale = 0.0
	first._process(0.5)
	assert(first.material.get_shader_parameter("walk_phase") == phase)
	first.speed_scale = 1.0
	first.show_animation("attack")
	first._process(0.5)
	assert(first.walk_weight < 0.01)
	assert(is_equal_approx(first.get_animation_duration("walk"), 16.0 / 12.0))
	assert(first.sprite_frames.get_animation_speed("idle") == 2.0)
	first.scale = Vector2(0.55, 0.55)
	first.sprite_frames.set_animation_speed("idle", 1.0)
	first.show_animation("walk")
	first.show_animation("idle")
	assert(first.scale == Vector2(0.55, 0.55))
	assert(first.sprite_frames.get_animation_speed("idle") == 1.0)
	assert(second.sprite_frames.get_animation_speed("idle") == 2.0)
	first.sprite_frames.set_animation_speed("attack", 5.0)
	assert(is_equal_approx(first.get_animation_duration("attack"), 2.0))
	first.queue_free()
	second.queue_free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.show_preview()
	assert(game.arena.hero.sprite_frames.get_frame_count("idle") == 4)
	assert(game.arena.hero.sprite_frames.get_frame_count("walk") == 16)
	assert(game.arena.hero.sprite_frames.get_frame_count("attack") == 10)
	game.preview_anim("attack")
	game.start_run()
	assert(not game.arena.hero.sprite_frames.get_animation_loop("attack"))
	game.arena.set_process(false)
	game.toggle_pause()
	var timer: float = game.travel_timer
	game._process(1.0)
	assert(game.travel_timer == timer)
	game.toggle_pause()
	game.toggle_speed()
	assert(game.game_speed == 2.0 and game.arena.speed == 2.0)
	for tick in 4000:
		game._process(0.05)
		game.arena._process(0.1)
		if game.state == "choice":
			game.select_relic("power")
		if game.state == "result":
			break
	assert(game.state == "result")
	assert(game.run.kills == 9, "Seed 42 should complete the three stages")
	assert(game.run.stage == 2)
	assert(game.run.relics.size() == 2)
	game.start_run()
	game.arena.set_process(false)
	game._process(2.0)
	game.run.hp = 1.0
	game.enemy_timer = 0.0
	game._process(0.01)
	assert(game.state == "result" and game.run.hp == 0.0)
	game.show_menu()
	assert(game.state == "menu")
	# Rapunzel is selectable, uses hair and completes the same three-stage loop.
	game.choose_hero("rapunzel")
	assert(game.selected_hero == "rapunzel")
	assert(game.arena.hero.hero_name == "Rapunzel")
	assert(game.arena.hero.is_hair_attack())
	game.show_preview()
	assert(game.arena.hero.sprite_frames.get_frame_count("walk") == 8)
	assert(game.arena.hero.sprite_frames.get_frame_count("attack") == 8)
	var hits := [0]
	game.arena.attack_hit.connect(func(): hits[0] += 1)
	game.arena.set_process(false)
	game.preview_anim("attack")
	game.arena._process(0.4)
	assert(hits[0] == 0)
	game.arena._process(0.16)
	assert(hits[0] == 1)
	game.arena._process(0.1)
	assert(hits[0] == 1, "A hair strike must deal damage only once")
	seed(42)
	game.start_run()
	game.arena.set_process(false)
	for tick in 4000:
		game._process(0.05)
		game.arena._process(0.05)
		if game.state == "choice":
			game.select_relic("power")
		if game.state == "result":
			break
	assert(game.state == "result" and game.run.kills == 9)
	game.show_menu()
	game.choose_hero("scarlet")
	assert(game.arena.hero.hero_name == "Scarlet")
	assert(not game.arena.hero.is_hair_attack())
	game.queue_free()
	await process_frame
	print(
		"PASS: editable hero scene, isolated resources, saved FPS/scale, idle waits/blink/sway, paused timers, stride-synced shoulders, 16-frame walk, sheets, pause, speed, three stages, relics, victory, defeat and menu; Rapunzel selection, hair hit timing and three-stage victory"
	)
	quit()
