extends Node2D
## Visuals only; each party member has an independent, duration-aware attack clock.
signal attack_hit(index: int)
const HeroScript = preload("res://scripts/hero.gd")
@export var hero_scene: PackedScene = preload("res://scenes/heroes/scarlet.tscn")
var party_scenes: Array[PackedScene] = []
var heroes: Array[AnimatedSprite2D] = []
var tracks: Array[Dictionary] = []
var hero: AnimatedSprite2D
var stage := 0
var boss := false
var enemy_visible := false
var walking := false
var clock := 0.0
var speed := 1.0
var frozen := false
var preview := false
var reduced_motion := false
var enemy_windup := 0.0
# Temporary drawing context, set separately for each track.
var attack_time := -1.0
var attack_duration := 1.0
var flash := 0.0


func _ready() -> void:
	if party_scenes.is_empty():
		party_scenes.append(hero_scene)
	for index in party_scenes.size():
		var actor: AnimatedSprite2D = party_scenes[index].instantiate()
		add_child(actor)
		heroes.append(actor)
		if party_scenes.size() == 1:
			actor.position = Vector2(140, 314)
		else:
			actor.position = [Vector2(250, 316), Vector2(160, 292), Vector2(83, 318)][index]
			actor.scale *= 0.79
		actor.z_index = int(actor.position.y)
		actor.show_animation("idle")
		tracks.append(
			{
				"time": -1.0,
				"duration": 1.0,
				"hit": false,
				"impact": 0.0,
				"hurt": 0.0,
				"alive": true,
				"shoulders": actor.walk_shoulders_enabled,
				"sway": actor.idle_sway_amplitude
			}
		)
	hero = heroes[0]


func set_animation(anim: String) -> void:
	for index in heroes.size():
		if tracks[index].alive:
			heroes[index].show_animation(anim)


func attack(index: int = 0) -> bool:
	if index < 0 or index >= tracks.size() or not tracks[index].alive or tracks[index].time >= 0:
		return false
	var actor: AnimatedSprite2D = heroes[index]
	var duration: float = actor.get_animation_duration("attack")
	if not is_finite(duration) or duration <= 0:
		return false
	tracks[index].time = 0.0
	tracks[index].duration = duration
	tracks[index].hit = false
	actor.show_animation("attack")
	actor.seek_animation("attack", 0)
	return true


func reset_effects() -> void:
	walking = false
	preview = false
	flash = 0.0
	for index in heroes.size():
		tracks[index].time = -1.0
		tracks[index].impact = 0.0
		tracks[index].hurt = 0.0
		if tracks[index].alive:
			heroes[index].show_animation("idle")


func sync_health(actors: Array[Dictionary]) -> void:
	for index in mini(actors.size(), heroes.size()):
		var living: bool = actors[index].hp > 0
		tracks[index].alive = living
		if not living:
			tracks[index].time = -1.0
			heroes[index].show_animation("idle")
			heroes[index].speed_scale = 0
			heroes[index].modulate = Color(0.42, 0.42, 0.48, 0.6)


func hurt(index: int) -> void:
	if index >= 0 and index < tracks.size():
		tracks[index].hurt = 0.2


func _process(delta: float) -> void:
	for index in heroes.size():
		heroes[index].speed_scale = 0.0 if frozen or not tracks[index].alive else speed
		heroes[index].walk_shoulders_enabled = tracks[index].shoulders and not reduced_motion
		heroes[index].idle_sway_amplitude = 0.0 if reduced_motion else tracks[index].sway
	if frozen:
		return
	var dt := minf(delta, 0.25) * speed
	clock += dt
	flash = maxf(0, flash - dt)
	for index in tracks.size():
		var track: Dictionary = tracks[index]
		track.impact = maxf(0, track.impact - dt)
		track.hurt = maxf(0, track.hurt - dt)
		if track.alive:
			heroes[index].modulate = Color("f2acac") if track.hurt > 0 else Color.WHITE
		if track.time >= 0:
			track.time += dt
			heroes[index].seek_animation("attack", track.time)
			var landed: bool = (
				not track.hit and track.time >= track.duration * heroes[index].impact_ratio
			)
			if landed:
				track.hit = true
				track.impact = 0.28
				flash = 0.16
			if track.time >= track.duration:
				track.time = -1.0
				heroes[index].show_animation("idle")
			if landed:
				attack_hit.emit(index)
	if preview and tracks[0].time < 0:
		attack()
	queue_redraw()


func _draw() -> void:
	if heroes.is_empty():
		return
	var data: Dictionary = TaleCatalog.STAGES[clampi(stage, 0, 7)]
	var biome: int = data.biome
	draw_rect(Rect2(0, 0, 492, 340), data.sky)
	draw_circle(Vector2(395, 68), 32, Color(data.color, 0.15))
	for index in 9:
		var x := index * 68.0 - 30.0 - (fmod(clock * 32.0, 68.0) if walking else 0.0)
		var tint: Color = data.sky.darkened(0.32)
		match biome:
			0, 2:
				draw_rect(Rect2(x + 25, 30, 12, 240), tint)
				draw_circle(Vector2(x + 30, 55 + (index % 2) * 25), 64, tint)
				if biome == 2:
					draw_circle(Vector2(x + 14, 104), 5, Color("b85b7e"))
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
	for index in 15:
		var x := fposmod(index * 39.0 - (clock * 58 if walking else 0), 520)
		draw_line(
			Vector2(x, 290 + index % 3 * 12),
			Vector2(x + 14, 290 + index % 3 * 12),
			Color(data.color, 0.16),
			2
		)
	for index in heroes.size():
		draw_set_transform(heroes[index].position, 0, Vector2(1, 0.22))
		draw_circle(Vector2.ZERO, 42 if heroes.size() > 1 else 55, Color(0.02, 0.03, 0.04, 0.45))
	draw_set_transform(Vector2.ZERO)
	if enemy_visible:
		draw_enemy(Vector2(402, 296), boss)
		if enemy_windup > 0.72:
			draw_arc(Vector2(402, 302), 52, -PI, PI * enemy_windup, 24, Color("dd8997"), 3, true)
	for index in heroes.size():
		hero = heroes[index]
		attack_time = tracks[index].time
		attack_duration = tracks[index].duration
		if attack_time >= 0 and not tracks[index].hit:
			match hero.attack_style:
				HeroScript.AttackStyle.HAIR:
					draw_hair_attack()
				HeroScript.AttackStyle.SWORD:
					draw_sword_attack()
				HeroScript.AttackStyle.TIDE:
					draw_water_attack()
				_:
					draw_projectile(hero.attack_style)
		if tracks[index].impact > 0:
			var radius: float = (1.0 - tracks[index].impact / 0.28) * 44 + 8
			var tint: Color = hero.accent_color
			for spark in 7:
				var direction := Vector2.from_angle(spark * TAU / 7.0)
				draw_line(
					Vector2(402, 253) + direction * radius * 0.35,
					Vector2(402, 253) + direction * radius,
					tint,
					2,
					true
				)
	hero = heroes[0]


func draw_projectile(style: int) -> void:
	# Release and arrival follow each scene's editable impact ratio.
	var release: float = hero.impact_ratio * 0.52
	var phase := attack_time / attack_duration
	if phase < release:
		return
	var t := clampf((phase - release) / (hero.impact_ratio - release), 0.0, 1.0)
	var point := (hero.position + Vector2(45, -91)).lerp(Vector2(402, 253), t)
	point.y -= sin(t * PI) * 60
	if style == HeroScript.AttackStyle.CRYSTAL:
		draw_line(point - Vector2(27, -4), point, Color(0.65, 0.85, 1, 0.5), 4, true)
		draw_colored_polygon(
			PackedVector2Array(
				[
					point + Vector2(14, 0),
					point + Vector2(-2, -9),
					point + Vector2(-10, 0),
					point + Vector2(-2, 9)
				]
			),
			Color("b4d9f5")
		)
		draw_line(point + Vector2(-10, 0), point + Vector2(14, 0), Color.WHITE, 2, true)
	elif style == HeroScript.AttackStyle.APPLE:
		draw_circle(point + Vector2(-4, 0), 8, Color("b32349"))
		draw_circle(point + Vector2(4, 0), 8, Color("df3951"))
		draw_line(point + Vector2(0, -6), point + Vector2(1, -13), Color("97683e"), 3)
		draw_colored_polygon(
			PackedVector2Array(
				[point + Vector2(1, -11), point + Vector2(12, -15), point + Vector2(8, -7)]
			),
			Color("8ec686")
		)
		draw_circle(point + Vector2(5, -3), 2, Color("ffd0bd"))
	else:
		draw_circle(point, 10, Color("11151f"))
		draw_arc(point, 8, 3.6, 5.6, 12, Color("677286"), 2)
		draw_circle(point + Vector2(1, -14), 4, Color("ffd38a"))


func draw_sword_attack() -> void:
	var phase := attack_time / attack_duration
	var windup: float = hero.impact_ratio * 0.35
	if phase < windup:
		return
	var progress := clampf((phase - windup) / (hero.impact_ratio - windup), 0.0, 1.0)
	var center := hero.position + Vector2(10, -63)
	var radius := 70.0 + progress * (Vector2(402, 253).distance_to(center) - 70.0)
	var angle := lerpf(-1.1, 0.25, progress)
	draw_arc(center, radius, angle - 0.65, angle, 24, Color(0.6, 0.9, 0.88, 0.28), 13, true)
	draw_arc(center, radius, angle - 0.55, angle, 24, Color("d5fff4"), 3, true)


func draw_water_attack() -> void:
	var phase := attack_time / attack_duration
	var windup: float = hero.impact_ratio * 0.35
	if phase < windup:
		return
	var progress := clampf((phase - windup) / (hero.impact_ratio - windup), 0.0, 1.0)
	var start := hero.position + Vector2(32, -83)
	var end := start.lerp(Vector2(402, 253), progress)
	var wave := PackedVector2Array()
	for index in 25:
		var t := index / 24.0
		var point := start.lerp(end, t)
		point.y += sin(t * TAU * 1.5 - phase * 10.0) * 12.0 * sin(t * PI)
		wave.append(point)
	draw_polyline(wave, Color(0.18, 0.7, 0.78, 0.4), 15, true)
	draw_polyline(wave, Color("8be5e1"), 5, true)
	draw_arc(end, 13, -PI * 0.8, PI * 0.6, 20, Color("d3ffff"), 3, true)


func draw_hair_attack() -> void:
	var phase := attack_time / attack_duration
	var windup := minf(0.18, hero.impact_ratio * 0.3)
	if phase < windup:
		return
	var progress := clampf((phase - windup) / (hero.impact_ratio - windup), 0.0, 1.0)
	var start := hero.position + Vector2(-4, -84)
	var end := start.lerp(Vector2(402, 253), sin(progress * PI * 0.5))
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
	var color: Color = TaleCatalog.STAGES[stage].color
	if flash > 0:
		color = Color.WHITE
	draw_set_transform(at + Vector2(0, bob), 0.0, Vector2.ONE * s)
	draw_set_transform(at, 0.0, Vector2(s, s * 0.22))
	draw_circle(Vector2.ZERO, 47, Color(0.02, 0.03, 0.04, 0.45))
	draw_set_transform(at + Vector2(0, bob), 0.0, Vector2.ONE * s)
	match stage:
		0:
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-40, -12),
						Vector2(-33, -64),
						Vector2(-24, -90),
						Vector2(-9, -71),
						Vector2(12, -74),
						Vector2(29, -96),
						Vector2(37, -54),
						Vector2(43, -12)
					]
				),
				color
			)
			draw_line(Vector2(-25, -14), Vector2(27, -14), color.lightened(0.25), 5)
		1:
			draw_line(Vector2(0, -118), Vector2(0, -71), Color("c9b8a0"), 2)
			draw_circle(Vector2(0, -67), 22, color)
			draw_rect(Rect2(-21, -45, 42, 43), color.darkened(0.2))
			draw_line(Vector2(-22, -43), Vector2(-40, -7), color, 9)
			draw_line(Vector2(22, -43), Vector2(40, -7), color, 9)
		2:
			draw_style_box(stone_box(color.darkened(0.2)), Rect2(-36, -100, 72, 91))
			draw_style_box(stone_box(color.lightened(0.25)), Rect2(-26, -90, 52, 67))
			for thorn in 3:
				draw_line(Vector2(-47 + thorn * 43, 0), Vector2(-38 + thorn * 39, -50), color, 4)
		3:
			draw_rect(Rect2(-26, -67, 52, 62), color)
			draw_colored_polygon(
				PackedVector2Array([Vector2(-41, -68), Vector2(0, -103), Vector2(41, -68)]),
				color.darkened(0.15)
			)
			draw_line(Vector2(33, -15), Vector2(46, -99), Color("e9c488"), 4)
		4:
			draw_circle(Vector2.ZERO, 35, color.darkened(0.3))
			draw_colored_polygon(
				PackedVector2Array(
					[Vector2(0, -108), Vector2(-37, -53), Vector2(0, -7), Vector2(37, -53)]
				),
				color
			)
			draw_line(Vector2(0, -101), Vector2(0, -14), Color.WHITE, 2)
		5:
			draw_circle(Vector2(0, -36), 36, color.darkened(0.2))
			for fin in 3:
				draw_arc(Vector2(-30 + fin * 30, -2), 26, PI, TAU, 14, color, 10, true)
			draw_colored_polygon(
				PackedVector2Array([Vector2(-27, -48), Vector2(-48, -73), Vector2(-20, -66)]), color
			)
		6:
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
		7:
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(-44, -4),
						Vector2(-24, -75),
						Vector2(0, -116),
						Vector2(24, -75),
						Vector2(44, -4)
					]
				),
				color.darkened(0.4)
			)
			draw_circle(Vector2(0, -74), 21, color)
			draw_line(Vector2(-38, -28), Vector2(48, -120), Color("e9c488"), 3)
			for thread in 3:
				draw_arc(Vector2(8, -55), 45 + thread * 8, -2, 1.5, 22, Color(color, 0.4), 1, true)

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
