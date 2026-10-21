extends Node2D
## Provisional enemies and scenery are deliberately drawn with simple shapes.
signal attack_hit

@export var hero_scene: PackedScene = preload("res://scenes/heroes/scarlet.tscn")
var hero: AnimatedSprite2D
var stage := 0
var boss := false
var enemy_visible := false
var walking := false
var clock := 0.0
var attack_time := -1.0
var attack_duration := 1.0
var impact_effect := 0.0
var flash := 0.0
var speed := 1.0
var frozen := false
var preview := false


func _ready() -> void:
	hero = hero_scene.instantiate()
	add_child(hero)
	hero.position = Vector2(135, 308)
	hero.show_animation("idle")


func set_animation(anim: String) -> void:
	hero.show_animation(anim)


func attack() -> void:
	attack_time = 0.0
	attack_duration = hero.get_animation_duration("attack")
	hero.stop()
	hero.show_animation("attack")


func reset_effects() -> void:
	attack_time = -1.0
	impact_effect = 0.0
	flash = 0.0
	walking = false
	preview = false
	hero.modulate = Color.WHITE
	hero.stop()
	hero.show_animation("idle")


func _process(delta: float) -> void:
	hero.speed_scale = 0.0 if frozen else speed
	if frozen:
		return
	var dt := delta * speed
	clock += dt
	flash = maxf(0.0, flash - dt)
	impact_effect = maxf(0.0, impact_effect - dt)
	if attack_time >= 0.0:
		attack_time += dt
		if attack_time >= attack_duration * hero.impact_ratio:
			attack_time = -1.0
			impact_effect = 0.28
			flash = 0.16
			attack_hit.emit()
	if preview and hero.animation == "attack" and not hero.is_playing():
		attack()
	elif preview and hero.is_idle_animation():
		attack()
	queue_redraw()


func _draw() -> void:
	var palettes := [Color("142e2b"), Color("25263c"), Color("3b242a")]
	draw_rect(Rect2(0, 0, 492, 340), palettes[stage])
	# Layers of forest / ruins / volcanic silhouettes.
	for i in 9:
		var x := float(i * 68 - 30)
		if walking:
			x -= fmod(clock * 42.0, 68.0)
		var tint := Color("0e2025") if stage == 0 else Color("191d30")
		if stage == 0:
			draw_rect(Rect2(x + 25, 20, 14, 230), tint)
			draw_circle(Vector2(x + 32, 20), 65, tint)
		elif stage == 1:
			draw_rect(Rect2(x + 25, 45 + (i % 3) * 20, 32, 210), tint)
			draw_rect(Rect2(x + 18, 45 + (i % 3) * 20, 46, 10), Color("42405d"))
		else:
			draw_colored_polygon(
				PackedVector2Array(
					[Vector2(x, 250), Vector2(x + 45, 55 + (i % 2) * 60), Vector2(x + 110, 250)]
				),
				tint
			)
	draw_circle(Vector2(390, 65), 29, Color(0.95, 0.84, 0.62, 0.13))
	draw_rect(Rect2(0, 265, 492, 75), Color("18212b"))
	draw_line(Vector2(0, 265), Vector2(492, 265), Color("81725a"), 2)
	for i in 17:
		var x := fmod(i * 37.0 - (clock * 70.0 if walking else 0.0), 520.0)
		draw_line(
			Vector2(x, 290 + i % 3 * 13), Vector2(x + 11, 290 + i % 3 * 13), Color("34404b"), 2
		)
	for i in 15:
		var p := Vector2(fmod(i * 67.0 + sin(clock + i) * 5, 492), fmod(i * 41.0 - clock * 9, 240))
		draw_circle(p, 1.5, Color(0.95, 0.78, 0.49, 0.25))
	draw_set_transform(hero.position, 0.0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 57, Color(0.02, 0.03, 0.04, 0.45))
	draw_set_transform(Vector2.ZERO)
	if enemy_visible:
		draw_enemy(Vector2(369, 292), boss)
	if hero.is_hair_attack() and attack_time >= 0.0:
		draw_hair_attack()
	elif attack_time > attack_duration * 0.5:
		var t := clampf((attack_time / attack_duration - 0.5) / 0.42, 0.0, 1.0)
		var p := Vector2(210, 217).lerp(Vector2(369, 260), t)
		p.y -= sin(t * PI) * 60
		draw_circle(p, 10, Color("11151f"))
		draw_arc(p, 8, 3.6, 5.6, 12, Color("677286"), 2)
		draw_circle(p + Vector2(1, -14), 4, Color("ffd38a"))
	if impact_effect > 0:
		var radius := (1.0 - impact_effect / 0.28) * 56 + 8
		if hero.is_hair_attack():
			for index in 8:
				var direction := Vector2.from_angle(index * TAU / 8.0)
				draw_line(Vector2(369, 255) + direction * radius * 0.3,
					Vector2(369, 255) + direction * radius, Color("ffe3a0"), 3, true)
		else:
			draw_circle(Vector2(369, 255), radius, Color(1, 0.65, 0.3, impact_effect * 2))
			draw_arc(Vector2(369, 255), radius + 6, 0, TAU, 28, Color("fcd9a0"), 3)


func draw_hair_attack() -> void:
	var phase := attack_time / attack_duration
	var windup := minf(0.18, hero.impact_ratio * 0.3)
	if phase < windup:
		return
	var progress := clampf((phase - windup) / (hero.impact_ratio - windup), 0.0, 1.0)
	var start := hero.position + Vector2(-4, -84)
	var end := start.lerp(Vector2(369, 255), sin(progress * PI * 0.5))
	var strand := PackedVector2Array()
	for index in 25:
		var t := index / 24.0
		var point := start.lerp(end, t)
		point.y -= sin(t * PI) * (34.0 + sin(phase * TAU) * 18.0)
		point.y += sin(t * TAU - phase * 9.0) * 10.0 * sin(t * PI)
		strand.append(point)
	draw_polyline(strand, Color("936020"), 13, true)
	draw_polyline(strand, Color("f4c454"), 9, true)
	draw_polyline(strand, Color("fff0a9"), 3, true)


func draw_enemy(at: Vector2, is_boss: bool) -> void:
	var s := 1.3 if is_boss else 1.0
	var bob := sin(clock * 3) * 3
	var color: Color = IdleRun.STAGES[stage].color
	if flash > 0:
		color = Color.WHITE
	draw_set_transform(at + Vector2(0, bob), 0.0, Vector2.ONE * s)
	draw_set_transform(at, 0.0, Vector2(s, s * 0.22))
	draw_circle(Vector2.ZERO, 47, Color(0.02, 0.03, 0.04, 0.45))
	draw_set_transform(at + Vector2(0, bob), 0.0, Vector2.ONE * s)
	match stage:
		0:
			draw_circle(Vector2(0, -28), 39, color.darkened(0.2))
			draw_circle(Vector2(-7, -34), 30, color)
			draw_rect(Rect2(-39, -25, 78, 28), color)
		1:
			draw_style_box(stone_box(color), Rect2(-33, -79, 66, 76))
			draw_rect(Rect2(-49, -63, 13, 53), color.darkened(0.2))
			draw_rect(Rect2(36, -63, 13, 53), color.darkened(0.2))
			draw_line(Vector2(-9, -75), Vector2(5, -41), Color("49435e"), 3)
		2:
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-39, -10),
						Vector2(-29, -48),
						Vector2(-13, -38),
						Vector2(0, -98),
						Vector2(18, -48),
						Vector2(35, -61),
						Vector2(42, -10)
					]
				),
				color
			)
			draw_circle(Vector2(1, -28), 21, Color("ffc77b"))
	draw_circle(Vector2(-13, -34), 5, Color("101923"))
	draw_circle(Vector2(12, -34), 5, Color("101923"))
	draw_line(Vector2(-6, -19), Vector2(7, -19), Color("101923"), 3)
	if is_boss:
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(-25, -90),
					Vector2(-27, -112),
					Vector2(-10, -101),
					Vector2(0, -119),
					Vector2(10, -101),
					Vector2(27, -112),
					Vector2(25, -90)
				]
			),
			Color("eec578")
		)
	draw_set_transform(Vector2.ZERO)


func stone_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(7)
	return box
