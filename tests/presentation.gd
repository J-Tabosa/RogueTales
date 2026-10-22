extends SceneTree
const UISkin = preload("res://scripts/ui_skin.gd")
var game: Control
const SAVE := "user://presentation_test_isolated.json"


func _initialize() -> void:
	call_deferred("checks")


func checks() -> void:
	for texture in [
		UISkin.PANEL, UISkin.BUTTON, UISkin.WALLET, UISkin.LOGO, UISkin.MAP, UISkin.FOREST
	]:
		assert(texture != null and texture.get_width() > 0)
	assert(UISkin.artwork("logo") == UISkin.artwork("logo"), "Atlas resources must be shared")
	assert(UISkin.LOGO.get_width() <= 1024 and UISkin.PANEL.get_width() <= 768)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.show_heroes()
	var portraits := 0
	for node in game.find_children("*", "Sprite2D", true, false):
		assert(not node is AnimatedSprite2D and not node.is_processing())
		portraits += 1
	assert(portraits == TaleCatalog.HEROES.size(), "Every collection banner uses a static cached portrait")
	assert(game.box(Color.RED) == game.box(Color.RED), "Identical styles must share resources")
	game.anchor_right = 0
	game.anchor_bottom = 0
	for dimensions in [
		Vector2(360, 640),
		Vector2(360, 800),
		Vector2(540, 1200),
		Vector2(768, 1024),
		Vector2(1920, 1080)
	]:
		game.size = dimensions
		game.center_content()
		game.show_heroes()
		assert(game.content.position.x >= -0.01 and game.content.position.y >= -0.01)
		var extent: Vector2 = game.content.position + game.content.size * game.content.scale
		assert(extent.x <= dimensions.x + 0.01 and extent.y <= dimensions.y + 0.01)
		for node in game.page.get_children():
			if node is Button:
				assert(node.size.y >= 44 and node.position.y + node.size.y <= game.logical_height)
			if node is ScrollContainer:
				assert(is_equal_approx(node.size.y, 416), "The horizontal banner strip keeps its artwork proportions")
		game.show_unlock_details("snow_white")
		var original: float = game.overlay.get_child(1).position.y
		game.center_content()
		assert(
			game.overlay.get_child(1).position.y == original, "Resize must not accumulate offsets"
		)
	game.size = Vector2(540, 1200)
	game.center_content(Rect2(0, 40, 540, 1120))
	assert(game.content.position.y >= 40)
	assert(game.content.position.y + game.content.size.y * game.content.scale.y <= 1160)
	game.center_content()
	game.show_menu()
	game.load_chapter(0)
	assert(game.state == "loading" and game.run == null)
	assert(not game.loading_callback.is_null())
	for step in 4:
		game._process(0.1)
	assert(game.state == "travel" and game.run.stage == 0)
	var identity: int = game.run.run_id
	game._process(0.1)
	assert(game.run.run_id == identity, "The transition must start a run only once")
	var arena: Node2D = game.arena
	var scene_clock: float = arena.clock
	arena._process(0.2)
	assert(arena.clock > scene_clock)
	arena.frozen = true
	arena._process(0.1)
	assert(arena.heroes[0].speed_scale == 0)
	game.leave_battle()
	game.resume_checkpoint()
	assert(game.state == "loading")
	for step in 4:
		game._process(0.1)
	assert(game.state == "travel" and game.run.run_id == identity)
	game.abandon_expedition()
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert(Engine.max_fps == 5)
	if game.audio.music.playing:
		assert(game.audio.music.stream_paused)
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert(Engine.max_fps == game.campaign.fps_limit)
	game.queue_free()
	await process_frame
	for path in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print(
		"PASS: six generated textures/import limits; cached atlases/styles; twelve static portraits; five viewport sizes; safe-area fitting; stable resizing/modals; mission/resume loading with unique run ID; retained scenery; pause and background battery cap"
	)
	quit()
