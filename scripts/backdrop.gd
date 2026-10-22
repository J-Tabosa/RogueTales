extends Node2D
## Its canvas display list is retained during combat. Only travel redraws the scenery.
var stage := 0
var walking := false
var frozen := false
var high_quality := true
var speed := 1.0
var clock := 0.0
var redraw_timer := 0.0
var previous_walking := false
var previous_quality := true


func _process(delta: float) -> void:
	if previous_walking != walking or previous_quality != high_quality:
		previous_walking = walking
		previous_quality = high_quality
		queue_redraw()
	if not walking or frozen:
		return
	clock += minf(delta, 0.25) * speed
	redraw_timer -= delta
	if redraw_timer <= 0:
		redraw_timer = 1.0 / (30.0 if high_quality else 15.0)
		queue_redraw()


func smooth_circle(at: Vector2, radius: float, color: Color) -> void:
	draw_circle(at, radius, color, true, -1.0, high_quality)


func _draw() -> void:
	var data: Dictionary = TaleCatalog.STAGES[clampi(stage, 0, TaleCatalog.FINAL_CHAPTER)]
	var biome: int = data.biome
	draw_rect(Rect2(0, 0, 492, 340), data.sky)
	smooth_circle(Vector2(395, 68), 32, Color(data.color, 0.15))
	for index in 9:
		var x := index * 68.0 - 30.0 - (fmod(clock * 32.0, 68.0) if walking else 0.0)
		var tint: Color = data.sky.darkened(0.32)
		match biome:
			0, 2:
				draw_rect(Rect2(x + 25, 30, 12, 240), tint)
				smooth_circle(Vector2(x + 30, 55 + (index % 2) * 25), 64, tint)
				if biome == 2:
					smooth_circle(Vector2(x + 14, 104), 5, Color("b85b7e"))
			1, 4, 7:
				draw_rect(Rect2(x + 22, 40, 30, 225), tint)
				draw_rect(Rect2(x + 16, 36, 42, 10), Color(data.color, 0.17))
				if biome == 7:
					for shelf in 4:
						draw_line(
							Vector2(x, 92 + shelf * 38),
							Vector2(x + 64, 92 + shelf * 38),
							Color(data.color, 0.16),
							3
						)
						for book in 5:
							draw_rect(
								Rect2(x + book * 11, 69 + shelf * 38, 7, 20),
								Color(data.color, 0.08 + book * 0.03)
							)
			3, 6:
				draw_colored_polygon(
					PackedVector2Array(
						[
							Vector2(x, 265),
							Vector2(x + 50, 50 + (index % 2) * 55),
							Vector2(x + 114, 265)
						]
					),
					tint
				)
			5:
				for band in 4:
					draw_arc(
						Vector2(x + 20, 55 + band * 55),
						40,
						0.1,
						2.9,
						16,
						Color(data.color, 0.09),
						2,
						true
					)
				draw_line(
					Vector2(x + 20, 280),
					Vector2(x + 14 + sin(clock + index) * 8, 180),
					Color(data.color, 0.24),
					4,
					true
				)
	draw_rect(Rect2(0, 268, 492, 72), data.sky.darkened(0.35))
	draw_line(Vector2(0, 268), Vector2(492, 268), Color(data.color, 0.35), 2)
	if biome == 3:
		# Static snow is retained in the canvas display list during combat.
		draw_rect(Rect2(0, 268, 492, 72), Color("b8d2d4"))
		for drift in 8:
			draw_set_transform(Vector2(drift * 74 - 12, 270), 0, Vector2(1, 0.18))
			smooth_circle(Vector2.ZERO, 52, Color("e3edef"))
		draw_set_transform(Vector2.ZERO)
		for flake in 24:
			var at := Vector2(
				fposmod(flake * 79.0 - clock * 13, 492), fposmod(flake * 43.0 + clock * 25, 263)
			)
			smooth_circle(at, 1.5, Color("e3edef", 0.55))
	elif biome == 5:
		# Shoreline, foam and shells make this chapter read as a beach.
		draw_rect(Rect2(0, 190, 492, 78), Color("28686e"))
		for band in 3:
			draw_line(
				Vector2(0, 209 + band * 19), Vector2(492, 209 + band * 19), Color("85d4d2", 0.6), 2
			)
		draw_rect(Rect2(0, 268, 492, 72), Color("c7b68b"))
		draw_line(Vector2(0, 270), Vector2(492, 270), Color("e6ebd3"), 5)
		for shell in 7:
			smooth_circle(Vector2(shell * 73 + 12, 300 + shell % 2 * 18), 3, Color("f1d9ba"))

	for index in 15:
		var x := fposmod(index * 39.0 - (clock * 58 if walking else 0), 520)
		draw_line(
			Vector2(x, 290 + index % 3 * 12),
			Vector2(x + 14, 290 + index % 3 * 12),
			Color(data.color, 0.16),
			2
		)
