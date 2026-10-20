extends SceneTree
## godot --headless --path . --script tests/smoke.gd
var game: Control


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	seed(42)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.show_preview()
	assert(game.arena.hero.sprite_frames.get_frame_count("idle") == 10)
	assert(game.arena.hero.sprite_frames.get_frame_count("walk") == 6)
	assert(game.arena.hero.sprite_frames.get_frame_count("attack") == 10)
	game.preview_anim("attack")
	game.start_run()
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
	print("PASS: sheets, pause, speed, three stages, relics, victory, defeat and menu")
	quit()
