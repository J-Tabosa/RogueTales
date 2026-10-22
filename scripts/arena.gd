extends Node2D
## Visuals only; each party member has an independent, duration-aware attack clock.
signal attack_hit(index: int)
signal attack_started(index: int)
const Enemy = preload("res://scripts/enemy.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
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
var high_quality := true
var enemy_windup := 0.0
var enemy_interval := 2.4
var enemy: AnimatedSprite2D
# Temporary drawing context, set separately for each track.
var attack_time := -1.0
var attack_duration := 1.0
var flash := 0.0
var backdrop: Node2D
var applied_preferences := Vector4(-1, -1, -1, -1)
var stone_boxes: Dictionary = {}
var redraw_timer := 0.0


func _ready() -> void:
	backdrop = Node2D.new()
	backdrop.set_script(Backdrop)
	backdrop.stage = stage
	backdrop.high_quality = high_quality
	backdrop.show_behind_parent = true
	add_child(backdrop)
	if party_scenes.is_empty():
		party_scenes.append(hero_scene)
	for index in party_scenes.size():
		var actor: AnimatedSprite2D = party_scenes[index].instantiate()
		add_child(actor)
		actor.texture_filter = hero_filter()
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
				"sway": actor.idle_sway_amplitude,
				"home": actor.position,
				"return_left": 0.0,
				"return_from": actor.position
			}
		)
	hero = heroes[0]
	enemy = Enemy.warm(stage).instantiate()
	add_child(enemy)
	enemy.visible = enemy_visible
	enemy.advance(0.0, boss, enemy_windup, enemy_interval)


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
	tracks[index].return_left = 0.0
	actor.position = tracks[index].home
	tracks[index].time = 0.0
	tracks[index].duration = duration
	tracks[index].hit = false
	actor.show_animation("attack")
	actor.seek_animation("attack", 0)
	attack_started.emit(index)
	return true


func reset_effects() -> void:
	walking = false
	preview = false
	flash = 0.0
	if is_instance_valid(enemy):
		enemy.reset_damage()
	for index in heroes.size():
		if heroes[index].position.distance_to(tracks[index].home) > 0.1:
			tracks[index].return_from = heroes[index].position
			tracks[index].return_left = 0.18
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

	apply_visual_preferences(true)
	queue_redraw()


func hurt(index: int) -> void:
	if index >= 0 and index < tracks.size():
		tracks[index].hurt = 0.24
		heroes[index].modulate = Enemy.hurt_color(0.24)


func _process(delta: float) -> void:
	apply_visual_preferences()
	backdrop.walking = walking
	backdrop.frozen = frozen
	backdrop.high_quality = high_quality
	backdrop.speed = speed
	enemy.visible = enemy_visible
	enemy.texture_filter = hero_filter()
	enemy.advance(0.0 if frozen else minf(delta, 0.25) * speed, boss, enemy_windup, enemy_interval)
	if frozen:
		return
	var dt := minf(delta, 0.25) * speed
	clock += dt
	flash = maxf(0, flash - dt)
	for index in tracks.size():
		var track: Dictionary = tracks[index]
		track.impact = maxf(0, track.impact - dt)
		track.hurt = maxf(0, track.hurt - dt)
		if track.return_left > 0.0:
			track.return_left = maxf(0.0, track.return_left - dt)
			heroes[index].position = track.return_from.lerp(
				track.home, smoothstep(0.0, 1.0, 1.0 - track.return_left / 0.18)
			)
		if track.alive:
			heroes[index].modulate = Enemy.hurt_color(track.hurt)
		if track.time >= 0:
			track.time += dt
			update_attack_position(index, track.time / track.duration)
			heroes[index].seek_animation("attack", track.time)
			var landed: bool = (
				not track.hit and track.time >= track.duration * heroes[index].impact_ratio
			)
			if landed:
				track.hit = true
				track.impact = 0.28
				flash = 0.16
				if preview:
					enemy.hurt()
			if track.time >= track.duration:
				track.time = -1.0
				heroes[index].position = track.home
				heroes[index].show_animation("idle")
			if landed:
				attack_hit.emit(index)
	if preview and tracks[0].time < 0:
		attack()
	redraw_timer -= delta
	var moving := enemy_visible or preview or walking or flash > 0
	for track in tracks:
		moving = moving or track.time >= 0 or track.return_left > 0 or track.impact > 0
	if moving and redraw_timer <= 0:
		redraw_timer = 1.0 / (60.0 if high_quality else 30.0)
		queue_redraw()


func apply_visual_preferences(force := false) -> void:
	var preferences := Vector4(speed, float(frozen), float(reduced_motion), float(high_quality))
	if not force and preferences == applied_preferences:
		return
	applied_preferences = preferences
	for index in heroes.size():
		heroes[index].texture_filter = hero_filter()
		heroes[index].speed_scale = 0.0 if frozen or not tracks[index].alive else speed
		heroes[index].walk_shoulders_enabled = tracks[index].shoulders and not reduced_motion
		heroes[index].idle_sway_amplitude = 0.0 if reduced_motion else tracks[index].sway


func hero_filter() -> CanvasItem.TextureFilter:
	return (
		CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if high_quality
		else CanvasItem.TEXTURE_FILTER_LINEAR
	)


func smooth_circle(at: Vector2, radius: float, color: Color) -> void:
	draw_circle(at, radius, color, true, -1.0, high_quality)


func _draw() -> void:
	if heroes.is_empty():
		return
	for index in heroes.size():
		draw_set_transform(heroes[index].position, 0, Vector2(1, 0.22))
		smooth_circle(Vector2.ZERO, 42 if heroes.size() > 1 else 55, Color(0.02, 0.03, 0.04, 0.45))
	draw_set_transform(Vector2.ZERO)
	if enemy_visible:
		draw_set_transform(Vector2(402, 296), 0, Vector2(1, 0.22))
		smooth_circle(Vector2.ZERO, 55 if boss else 42, Color(0.02, 0.03, 0.04, 0.45))
		draw_set_transform(Vector2.ZERO)
		if enemy_windup > 0.72:
			draw_arc(Vector2(402, 302), 52, -PI, PI * enemy_windup, 24, Color("dd8997"), 3, true)
	for index in heroes.size():
		hero = heroes[index]
		attack_time = tracks[index].time
		attack_duration = tracks[index].duration
		if attack_time >= 0 and not tracks[index].hit:
			match hero.attack_style:
				HeroScript.AttackStyle.HAIR:
					draw_melee_contact()
				HeroScript.AttackStyle.SWORD, HeroScript.AttackStyle.DAGGER, HeroScript.AttackStyle.GREATSWORD, HeroScript.AttackStyle.SPIRIT:
					draw_melee_contact()
				HeroScript.AttackStyle.TIDE:
					draw_water_attack()
				_:
					draw_projectile(hero.attack_style)
		if tracks[index].impact > 0:
			var radius: float = (
				(1.0 - tracks[index].impact / 0.28) * (16 if is_melee(index) else 38) + 5
			)
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


func projectile_point(style: int, origin: Vector2, progress: float) -> Vector2:
	var t := clampf(progress, 0, 1)
	var point := origin.lerp(Vector2(402, 253), t)
	if style == HeroScript.AttackStyle.BOMB:
		point.y -= sin(t * PI) * 60
	return point


func draw_projectile(style: int) -> void:
	# Release and arrival follow each scene's editable impact ratio.
	var release: float = hero.impact_ratio * 0.52
	var phase := attack_time / attack_duration
	if phase < release:
		return
	var t := clampf((phase - release) / (hero.impact_ratio - release), 0.0, 1.0)
	var point := projectile_point(style, hero.position + Vector2(45, -85), t)
	if style == HeroScript.AttackStyle.APPLE:
		var direction := (Vector2(402, 253) - (hero.position + Vector2(45, -85))).normalized()
		draw_line(
			point - direction * 30, point - direction * 11, Color(0.95, 0.45, 0.5, 0.45), 2, true
		)
		smooth_circle(point + Vector2(-4, 0), 8, Color("b32349"))
		smooth_circle(point + Vector2(4, 0), 8, Color("df3951"))
		draw_line(point + Vector2(0, -6), point + Vector2(1, -13), Color("97683e"), 3)
		draw_colored_polygon(
			PackedVector2Array(
				[point + Vector2(1, -11), point + Vector2(12, -15), point + Vector2(8, -7)]
			),
			Color("8ec686")
		)
		smooth_circle(point + Vector2(5, -3), 2, Color("ffd0bd"))
	elif style == HeroScript.AttackStyle.CROSSBOW:
		draw_line(point - Vector2(28, 0), point, Color("eee5cf"), 3, true)
	elif style == HeroScript.AttackStyle.CARDS:
		draw_rect(Rect2(point - Vector2(6, 9), Vector2(12, 18)), Color("f9edce"))
		smooth_circle(point, 3, Color("d94764"))
	elif style == HeroScript.AttackStyle.MATCH:
		draw_line(point - Vector2(22, 0), point, Color("ed6f3b"), 7, true)
		smooth_circle(point, 5, Color("ffe2a0"))
	elif style == HeroScript.AttackStyle.LAMP:
		draw_arc(point, 10, 0, TAU, 20, hero.accent_color, 3, true)
	else:
		smooth_circle(point, 10, Color("11151f"))
		draw_arc(point, 8, 3.6, 5.6, 12, Color("677286"), 2)
		smooth_circle(point + Vector2(1, -14), 4, Color("ffd38a"))


func is_melee(index: int) -> bool:
	return heroes[index].is_melee_attack()


func update_attack_position(index: int, phase: float) -> void:
	if not is_melee(index):
		return
	var actor: AnimatedSprite2D = heroes[index]
	var home: Vector2 = tracks[index].home
	var target := Vector2(334 + index * 3, 306 + (index % 2) * 8)
	var contact: float = actor.impact_ratio
	var arrival := contact * 0.78
	var depart := minf(0.86, contact + 0.13)
	if phase < arrival:
		actor.position = home.lerp(target, smoothstep(0.0, arrival, phase))
	elif phase <= depart:
		actor.position = target
	else:
		actor.position = target.lerp(home, smoothstep(depart, 1.0, phase))
	actor.z_index = int(actor.position.y)


func draw_melee_contact() -> void:
	# The sprite's real sword/hair makes contact. Only a small local glint is added.
	var phase := attack_time / attack_duration
	if phase < hero.impact_ratio * 0.88:
		return
	var tint := Color("fff0b3") if hero.is_hair_attack() else Color("e9fff8")
	draw_line(Vector2(385, 241), Vector2(400, 260), tint, 2.5, true)
	draw_line(Vector2(390, 261), Vector2(402, 246), tint, 2, true)


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


func set_home(index: int, at: Vector2) -> void:
	if index < 0 or index >= tracks.size():
		return
	tracks[index].home = at
	tracks[index].return_left = 0.0
	heroes[index].position = at
