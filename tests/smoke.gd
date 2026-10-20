extends SceneTree
## godot --headless --path . --script tests/smoke.gd
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
	first.show_animation("idle")
	first._process(0.5)
	assert(first.idle_weight > 0.99)
	assert(first.material.get_shader_parameter("idle_weight") > 0.99)
	var phase: float = first.idle_phase
	first.speed_scale = 0.0
	first._process(0.5)
	assert(first.idle_phase == phase)
	first.speed_scale = 1.0
	first.show_animation("walk")
	first._process(0.5)
	assert(first.idle_weight < 0.01)
	assert(second.idle_phase == 0.0)
	assert(is_equal_approx(first.get_animation_duration("walk"), 16.0 / 12.0))
	assert(first.sprite_frames.get_frame_texture("walk", 0).base_texture.resource_path.ends_with("walk_16.png"))
	assert(first.sprite_frames.get_animation_speed("idle") == 6.0)
	first.scale = Vector2(0.55, 0.55)
	first.sprite_frames.set_animation_speed("idle", 2.0)
	first.show_animation("walk")
	first.show_animation("idle")
	assert(first.scale == Vector2(0.55, 0.55))
	assert(first.sprite_frames.get_animation_speed("idle") == 2.0)
	assert(second.sprite_frames.get_animation_speed("idle") == 6.0)
	first.sprite_frames.set_animation_speed("attack", 5.0)
	assert(is_equal_approx(first.get_animation_duration("attack"), 2.0))
	first.queue_free()
	second.queue_free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.show_preview()
	assert(game.arena.hero.sprite_frames.get_frame_count("idle") == 18)
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
	game.queue_free()
	await process_frame
	print(
		"PASS: editable hero scene, isolated resources, saved FPS/scale, idle motion/pause/fade, 16-frame walk, sheets, pause, speed, three stages, relics, victory, defeat and menu"
	)
	quit()
