extends AnimatedSprite2D
## Sheets are read row-by-row. Keep the original images intact.
## Non-integer attack/idle cells are intentional: sheets are 1983 × 793.


func _ready() -> void:
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	add_sheet("idle", "res://assets/hero/idle.png", 5, 2, 8.0, true)
	add_sheet("walk", "res://assets/hero/walk.png", 3, 2, 9.0, true)
	add_sheet("attack", "res://assets/hero/ataack.png", 5, 2, 10.0, false)
	animation_finished.connect(func(): play("idle"))
	play("idle")


func add_sheet(
	anim: String, path: String, columns: int, rows: int, fps: float, loops: bool
) -> void:
	var sheet: Texture2D = load(path)
	var cell := Vector2(sheet.get_width() / float(columns), sheet.get_height() / float(rows))
	sprite_frames.add_animation(anim)
	sprite_frames.set_animation_speed(anim, fps)
	sprite_frames.set_animation_loop(anim, loops)
	for row in rows:
		for column in columns:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(Vector2(column, row) * cell, cell)
			sprite_frames.add_frame(anim, atlas)


func show_animation(anim: String) -> void:
	play(anim)
	# walk has larger source cells; normalize its rendered height.
	scale = Vector2.ONE * (0.31 if anim == "walk" else 0.4)
