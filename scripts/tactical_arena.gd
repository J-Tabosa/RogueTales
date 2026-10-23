extends Node2D
## Combat view. Every effect follows the target selected by the formation rules.
signal attack_hit(index: int)
signal attack_started(index: int)
signal enemy_attack_hit(index: int)
const Biomes = preload("res://scripts/biomes.gd")
const UltimateArt = preload("res://scripts/ultimate_art.gd")
const Enemy = preload("res://scripts/enemy.gd")
var party_scenes: Array = []
var simulation
var heroes: Array[AnimatedSprite2D] = []
var tracks: Array[Dictionary] = []
var foes: Array[AnimatedSprite2D] = []
var foe_homes: Array[Vector2] = []
var unit_widgets: Array[Dictionary] = []
var foe_widgets: Array[Dictionary] = []
var enemy: AnimatedSprite2D
var hero: AnimatedSprite2D
var stage := 0
var boss := false
var enemy_visible := false
var walking := false
var speed := 1.0
var frozen := false
var preview := false
var reduced_motion := false
var high_quality := true
var enemy_windup := 0.0
var enemy_interval := 2.4
var clock := 0.0
var health_tick := 0.0
var effects: Array[Dictionary] = []
var field_height := 550.0
var field_width := 492.0
var backdrop: TextureRect
var enemy_track := {"time": -1.0, "duration": 0.9, "index": -1, "target": -1, "hit": false}
var numbers: Array[Dictionary] = []
var hit_stop := 0.0
var intro_left := 0.0
var travel_progress := 0.0
var entrance_left := 0.0
var bursts: Array[Dictionary] = []
var feedback: Control
var enemy_areas: Array[Dictionary] = []
static var hero_shape_cache: Dictionary = {}



func _ready() -> void:
	backdrop = TextureRect.new()
	backdrop.texture = Biomes.scenery(stage)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size = Vector2(field_width, field_height)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = 0
	backdrop.show_behind_parent = true
	add_child(backdrop)
	for index in party_scenes.size():
		var actor: AnimatedSprite2D = party_scenes[index].instantiate()
		actor.return_to_idle = false
		normalize_hero(actor, str(simulation.actors[index].id))
		actor.set_meta("battle_scale", actor.scale)
		actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(actor)
		heroes.append(actor)
		var home := home_for(simulation.actors[index].row, index, false)
		actor.position = home
		actor.z_index = int(home.y)
		actor.show_animation("idle")
		tracks.append({"home": home, "time": -1.0, "duration": 1.0, "hit": false, "hurt": 0.0, "alive": true, "target": -1, "ultimate": false})
		unit_widgets.append(widget(home, TaleCatalog.hero_class_name(simulation.actors[index].id), Color("a3d9c3")))
	if not heroes.is_empty():
		hero = heroes[0]
	queue_redraw()


func home_for(row: String, index: int, hostile: bool) -> Vector2:
	var same: Array[int] = []
	var units: Array = simulation.tactics.enemies if hostile else simulation.actors
	for at in units.size():
		if units[at].row == row: same.append(at)
	var order := maxi(0, same.find(index))
	var center: float = {"front": 0.40, "middle": 0.26, "back": 0.12}.get(row, 0.12)
	var y: float = {"front": 0.88, "middle": 0.83, "back": 0.78}.get(row, 0.78)
	if same.size() == 2: center = {"front": 0.31, "middle": 0.25, "back": 0.19}.get(row, 0.19)
	if same.size() >= 3: center = 0.26
	var x := center + (order - (same.size() - 1) * 0.5) * 0.18
	var half_width := 48.0
	if hostile and units[index].has("variant"):
		var bounds := Biomes.bounds(int(units[index].biome), int(units[index].variant))
		var height := human_height() * (1.0 if units[index].boss else Biomes.height_factor(int(units[index].biome), int(units[index].variant)))
		half_width = bounds.size.x / maxf(1, bounds.size.y) * height * 0.5
	elif not hostile:
		var id: String = units[index].id
		if not hero_shape_cache.has(id):
			var model: AnimatedSprite2D = TaleCatalog.HERO_SCENES[id].instantiate()
			hero_shape_cache[id] = hero_bounds(model)
			model.free()
		var bounds: Rect2 = hero_shape_cache[id]
		half_width = bounds.size.x / maxf(1, bounds.size.y) * human_height() * (0.25 if id in ["puss", "matches"] else 0.5)
	return Vector2(clampf((1.0 - x if hostile else x) * field_width, half_width + 8, field_width - half_width - 8), field_height * y)

func hero_bounds(actor: AnimatedSprite2D) -> Rect2:
	var texture: Texture2D = actor.sprite_frames.get_frame_texture("idle", 0)
	if texture is MeshTexture:
		var bounds: AABB = texture.mesh.get_aabb()
		return Rect2(Vector2(bounds.position.x, bounds.position.y), Vector2(bounds.size.x, bounds.size.y))
	if texture is AtlasTexture: return Rect2(texture.margin.position, texture.region.size)
	return Rect2(Vector2.ZERO, texture.get_size())

func human_height() -> float:
	return clampf(field_height * 0.30, 132, 174)

func normalize_hero(actor: AnimatedSprite2D, id: String) -> void:
	var bounds := hero_bounds(actor)
	var height := human_height() * (0.5 if id in ["puss", "matches"] else 1.0)
	actor.scale = Vector2.ONE * (height / maxf(1, bounds.size.y))
	actor.offset = -Vector2(bounds.get_center().x, bounds.end.y)
	actor.set_meta("visual_height", height)



func widget(at: Vector2, title: String, tint: Color) -> Dictionary:
	var group := Node2D.new()
	group.position = at + Vector2(-43, 12)
	group.z_index = 900
	add_child(group)
	var text := Label.new()
	text.text = title
	text.position = Vector2(-4, -3)
	text.size = Vector2(94, 20)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color("e9e8dd"))
	text.add_theme_color_override("font_shadow_color", Color("10171c"))
	text.add_theme_constant_override("shadow_outline_size", 3)
	group.add_child(text)
	var bars: Array[ProgressBar] = []
	for index in 2:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.position = Vector2(0, 20 + index * 8)
		bar.size = Vector2(86, 5)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("141e27")
		bg.corner_radius_top_left = 2
		bg.corner_radius_bottom_left = 2
		bg.corner_radius_top_right = 2
		bg.corner_radius_bottom_right = 2
		var fill := bg.duplicate()
		fill.bg_color = tint if index == 0 else Color("8ab4f0")
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		group.add_child(bar)
		bars.append(bar)
	return {"root": group, "health": bars[0], "energy": bars[1], "text": text}


func sync_enemies() -> void:
	for actor in foes:
		actor.queue_free()
	for item in foe_widgets:
		item.root.queue_free()
	foes.clear()
	foe_homes.clear()
	foe_widgets.clear()
	for index in simulation.tactics.enemies.size():
		var data: Dictionary = simulation.tactics.enemies[index]
		var model: AnimatedSprite2D
		if simulation.expedition:
			model = AnimatedSprite2D.new()
			model.set_script(Enemy)
			model.sprite_frames = Biomes.frames(int(data.biome), int(data.variant))
			model.body_height = model.sprite_frames.get_frame_texture("idle", 0).get_image().get_used_rect().size.y
			model.illustrated = true
			model.flip_h = true
		else: model = Enemy.warm(stage).instantiate()
		model.regular_height = human_height() * (Biomes.height_factor(int(data.biome), int(data.variant)) if simulation.expedition else 1.0)
		model.boss_height = human_height() * (1.0 if simulation.expedition else 1.22)
		add_child(model)
		var home := home_for(str(data.row), index, true)
		model.advance(0, data.boss, 0, data.interval)
		model.position = home
		model.z_index = int(home.y)
		foes.append(model)
		foe_homes.append(home)
		foe_widgets.append(widget(home, ("★ " if data.boss else "") + str(TaleCatalog.CLASSES[data["class"]].name), Color("dd9691")))
		data["death_left"] = 0.0
		data["was_alive"] = true
	if not foes.is_empty():
		enemy = foes[0]
	sync_health(simulation.actors)


func attack(index: int = 0, target: int = -1, ultimate := false) -> bool:
	if is_action_busy():
		return false
	if index < 0 or index >= tracks.size() or not tracks[index].alive or tracks[index].time >= 0 or target < 0 or target >= foes.size():
		return false
	var actor: AnimatedSprite2D = heroes[index]
	tracks[index].time = 0.0
	tracks[index].duration = maxf(1.7 if ultimate else 1.12, actor.get_animation_duration("attack") * (1.40 if ultimate else 1.20))
	if ultimate:
		intro_left = 0.55
		if is_instance_valid(feedback): feedback.announce_ultimate(simulation.actors[index].id)
	tracks[index].hit = false
	tracks[index].target = target
	tracks[index].ultimate = ultimate
	actor.show_animation("attack")
	actor.seek_animation("attack", 0)
	attack_started.emit(index)
	return true


func set_animation(id: String) -> void:
	for index in heroes.size():
		if tracks[index].alive:
			heroes[index].show_animation(id)


func reset_effects() -> void:
	walking = false
	intro_left = 0.0
	bursts.clear()
	enemy_areas.clear()
	enemy_track.time = -1.0
	hit_stop = 0.0
	for item in numbers:
		item.node.queue_free()
	numbers.clear()
	effects.clear()
	for index in tracks.size():
		if simulation.actors[index].ult_pending:
			simulation.actors[index].energy = 100.0
			simulation.actors[index].ult_pending = false
		tracks[index].time = -1.0
		heroes[index].position = tracks[index].home
		if tracks[index].alive:
			heroes[index].show_animation("idle")
	for actor in foes:
		actor.reset_damage()
	queue_redraw()


func sync_health(actors: Array[Dictionary]) -> void:
	for index in mini(actors.size(), tracks.size()):
		tracks[index].alive = actors[index].hp > 0
		if actors[index].hp <= 0:
			tracks[index].time = -1.0
			heroes[index].modulate = Color(0.4, 0.42, 0.48, 0.35)
		unit_widgets[index].health.max_value = actors[index].max_hp
		unit_widgets[index].health.value = actors[index].hp
		unit_widgets[index].energy.value = actors[index].energy
		unit_widgets[index].text.text = "%s / %s PV" % [compact_hp(actors[index].hp), compact_hp(actors[index].max_hp)]
	for index in foes.size():
		var data: Dictionary = simulation.tactics.enemies[index]
		foes[index].visible = enemy_visible and (data.hp > 0 or data.get("death_left", 0) > 0)
		foe_widgets[index].root.visible = enemy_visible and data.hp > 0
		foe_widgets[index].health.max_value = data.max_hp
		foe_widgets[index].health.value = data.hp
		foe_widgets[index].energy.visible = false
		foe_widgets[index].text.text = "%s / %s PV" % [compact_hp(data.hp), compact_hp(data.max_hp)]



func hurt(index: int) -> void:
	if index >= 0 and index < tracks.size():
		tracks[index].hurt = 0.24
		heroes[index].modulate = Enemy.hurt_color(0.24)


func hurt_enemy(index: int, continuous := false) -> void:
	if index >= 0 and index < foes.size():
		foes[index].hurt(continuous)


func enemy_strike(index: int, target: int) -> void:
	if index < 0 or index >= foes.size() or target < 0 or target >= heroes.size():
		return
	foes[index].begin_strike(simulation.tactics.enemies[index].boss)
	effects.append({"from": foe_homes[index] + Vector2(0, -60), "to": tracks[target].home + Vector2(0, -60), "time": 0.18, "duration": 0.18, "color": Color("d49096")})


func _process(delta: float) -> void:
	if is_instance_valid(feedback): feedback.frozen = frozen
	var dt := 0.0 if frozen or hit_stop > 0 or intro_left > 0 else minf(delta, 0.25) * speed
	if not frozen: intro_left = maxf(0, intro_left - delta)
	if walking and dt > 0:
		travel_progress = minf(1, travel_progress + dt / 2.8)
		backdrop.position.x = 0 if reduced_motion else -18 * travel_progress
	entrance_left = maxf(0, entrance_left - dt)
	if not frozen:
		hit_stop = maxf(0, hit_stop - delta * speed)
	clock += dt
	for index in heroes.size():
		var actor: AnimatedSprite2D = heroes[index]
		actor.z_index = int(actor.position.y)
		var track: Dictionary = tracks[index]
		actor.speed_scale = 0.0 if frozen or hit_stop > 0 or intro_left > 0 or not track.alive else speed
		track.hurt = maxf(0, track.hurt - dt)
		if track.alive:
			actor.modulate = Enemy.hurt_color(track.hurt)
		if walking and track.alive:
			actor.position = track.home + Vector2(-90 * (1.0 - travel_progress), 0 if reduced_motion else sin(clock * 8 + index) * 2)
		if track.time < 0 or dt <= 0:
			continue
		track.time += dt
		var phase: float = clampf(track.time / track.duration, 0, 1)
		var target: int = track.target
		if target >= 0 and target < simulation.tactics.enemies.size() and simulation.tactics.enemies[target].hp <= 0 and not track.hit:
			track.target = simulation.tactics.target_for(index)
			target = track.target
		var impact: float = actor.impact_ratio
		actor.seek_animation("attack", phase * actor.get_animation_duration("attack"))
		if actor.is_melee_attack() and not (actor.is_hair_attack() and track.ultimate):
			if target >= 0:
				var contact := foe_homes[target] + Vector2(-62, 8)
				var dash := smoothstep(0, 1, phase / maxf(0.1, impact * 0.65)) if phase < impact else (1.0 - smoothstep(impact, 1, phase))
				actor.position = track.home.lerp(contact, dash)
		if not track.hit and phase >= impact:
			track.hit = true
			# Emit before starting recovery: the controller applies exactly one result.
			attack_hit.emit(index)
			if not is_instance_valid(actor):
				return
		if track.time >= track.duration:
			track.time = -1.0
			actor.position = track.home
			if track.alive:
				actor.show_animation("idle")
	if enemy_track.time >= 0 and dt > 0:
		var index: int = enemy_track.index
		enemy_track.time += dt
		if not enemy_track.hit and enemy_track.time >= enemy_track.duration * 0.55:
			enemy_track.hit = true
			enemy_attack_hit.emit(index)
		if enemy_track.time >= enemy_track.duration:
			enemy_track.time = -1.0
	for index in foes.size():
		var data: Dictionary = simulation.tactics.enemies[index]
		foes[index].advance(dt, data.boss, 0, simulation.tactics.interval_for(index))
		foes[index].position = foe_homes[index] + Vector2(100 * entrance_left, 0)
		if data.hp <= 0:
			if data.get("was_alive", true): data.death_left = 0.75
			data.was_alive = false
			data.death_left = maxf(0, float(data.get("death_left", 0)) - dt)
			foes[index].modulate.a = float(data.death_left) / 0.75
		if enemy_track.time >= 0 and enemy_track.index == index:
			var phase: float = clampf(enemy_track.time / enemy_track.duration, 0, 0.999)
			var anim := "idle" if enemy_track.get("support", false) else ("boss_attack" if data.boss else "attack")
			foes[index].seek(anim, phase * foes[index].animation_duration(anim))
			if not enemy_track.get("support", false) and data["class"] in ["vanguard", "assassin"] and enemy_track.target >= 0:
				var dash := smoothstep(0, 0.52, phase) if phase < 0.55 else (1.0 - smoothstep(0.55, 1, phase))
				var to: Vector2 = tracks[enemy_track.target].home + Vector2(60, 0)
				foes[index].position = foe_homes[index].lerp(to, dash)
			foes[index].z_index = 950
		else:
			foes[index].z_index = int(foe_homes[index].y)
	for area in enemy_areas: area.left -= dt
	enemy_areas = enemy_areas.filter(func(area): return area.left > 0)
	for burst in bursts: burst.left -= dt
	bursts = bursts.filter(func(item): return item.left > 0)
	for item in numbers:
		item.left -= dt
		item.node.position.y -= dt * 30
		item.node.modulate.a = minf(1, item.left * 3)
		if item.left <= 0:
			item.node.queue_free()
	numbers = numbers.filter(func(item): return item.left > 0)
	for item in effects:
		item.time -= dt
	effects = effects.filter(func(item): return item.time > 0)
	health_tick -= delta
	if health_tick <= 0:
		health_tick = 0.08
		sync_health(simulation.actors)
	if dt > 0:
		queue_redraw()


func _draw() -> void:
	for track in tracks:
		draw_set_transform(track.home, 0, Vector2(1, 0.23))
		draw_circle(Vector2.ZERO, 36, Color("0a151b", 0.5), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	for at in foe_homes:
		draw_set_transform(at, 0, Vector2(1, 0.23))
		draw_circle(Vector2.ZERO, 38, Color("0a151b", 0.5), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	for index in tracks.size():
		var track: Dictionary = tracks[index]
		if track.time < 0 or track.hit or track.target < 0 or track.target >= foe_homes.size():
			continue
		var phase: float = track.time / track.duration
		var release: float = heroes[index].impact_ratio * 0.45
		if phase < release:
			continue
		var t := clampf((phase - release) / maxf(0.01, heroes[index].impact_ratio - release), 0, 1)
		var from := heroes[index].position + Vector2(15, -65)
		var to := foe_homes[track.target] + Vector2(0, -60)
		var tint: Color = TaleCatalog.HEROES[simulation.actors[index].id].color
		if heroes[index].is_melee_attack():
			if phase > heroes[index].impact_ratio * 0.65:
				draw_arc(to, 25 if not track.ultimate else 48, -1.8, 1.2, 18, tint, 3, true)
		else:
			var point := from.lerp(to, t)
			if heroes[index].attack_style == 0:
				point.y -= sin(t * PI) * 50
				draw_circle(point, 9, Color("242127"), true, -1, true)
				draw_line(point + Vector2(3, -8), point + Vector2(7, -14), tint, 3, true)
			elif heroes[index].attack_style == 2:
				draw_circle(point - Vector2(3, 0), 6, Color("dc3f56"), true, -1, true)
				draw_circle(point + Vector2(3, 0), 6, Color("e95062"), true, -1, true)
				draw_line(point + Vector2(0, -5), point + Vector2(2, -10), Color("b4c793"), 2)
			elif heroes[index].attack_style == 5:
				var direction := (to - from).normalized()
				for bolt in (3 if track.ultimate else 1):
					var at := point + Vector2(0, (bolt - (1 if track.ultimate else 0)) * 9)
					draw_line(at - direction * 24, at, Color("eee5cf"), 3, true)
			elif heroes[index].attack_style == 7:
				draw_set_transform(point, t * TAU, Vector2.ONE)
				draw_rect(Rect2(-6, -9, 12, 18), Color("f9edce"))
				draw_circle(Vector2.ZERO, 3, Color("d94764"))
				draw_set_transform(Vector2.ZERO)
			elif heroes[index].attack_style == 9:
				draw_line(from.lerp(to, maxf(0, t - 0.12)), point, Color("ed6f3b"), 7, true)
				draw_circle(point, 5, Color("ffe2a0"), true, -1, true)
			elif heroes[index].attack_style == 11:
				draw_arc(point, 9, 0, TAU, 20, tint, 3, true)
				draw_circle(point, 4, Color("e7fff5"), true, -1, true)
			else:
				draw_line(from.lerp(to, maxf(0, t - 0.18)), point, tint, 6, true)
		if track.ultimate:
			draw_arc(to, 32 + t * 16, 0, TAU, 32, Color(tint, 0.65), 3, true)
	if enemy_track.time >= 0 and not enemy_track.get("support", false) and enemy_track.target >= 0:
		var index: int = enemy_track.index
		var phase: float = enemy_track.time / enemy_track.duration
		if phase >= 0.2 and phase < 0.55 and simulation.tactics.enemies[index]["class"] in ["mage", "ranger"]:
			var from := foe_homes[index] + Vector2(0, -75)
			var to: Vector2 = tracks[enemy_track.target].home + Vector2(0, -65)
			var t := clampf((phase - 0.2) / 0.35, 0, 1)
			var point := from.lerp(to, t)
			draw_line(from.lerp(to, maxf(0, t - 0.20)), point, Color("f09fa6"), 5, true)
			draw_circle(point, 8, Color("ffd4bd"), true, -1, true)
	for area in enemy_areas:
		var tint := Color(Biomes.COLORS[Biomes.biome(stage)], minf(1, area.left * 2))
		var radius: float = 26 + (1.0 - area.left) * 42
		draw_set_transform(area.at, 0, Vector2(1, 0.35))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 30, tint, 4, true)
		for point in 6:
			var dir := Vector2.from_angle(point * TAU / 6)
			draw_line(dir * 10, dir * radius, tint, 3, true)
		draw_set_transform(Vector2.ZERO)
	for burst in bursts: draw_burst(burst)
	if walking:
		for step in 9:
			var x := fposmod(step * 83.0 - clock * 90.0, field_width)
			draw_line(Vector2(x, field_height * 0.9), Vector2(x + 23, field_height * 0.9), Color("d6be88", 0.18), 2)
	for item in effects:
		draw_line(item.from, item.to, Color(item.color, item.time / item.duration), 3, true)
	for index in foe_homes.size():
		var foe: Dictionary = simulation.tactics.enemies[index]
		if not enemy_visible or foe.hp <= 0 or not foe.has("binds"): continue
		for at in simulation.actors.size():
			if simulation.actors[at].id == foe.binds and simulation.actors[at].hp > 0:
				draw_line(foe_homes[index] + Vector2(0, -80), tracks[at].home + Vector2(0, -70), Color("c885b8", 0.55), 2, true)


func set_home(index: int, at: Vector2) -> void:
	if index >= 0 and index < tracks.size():
		tracks[index].home = at
		heroes[index].position = at


func fit_field(dimensions: Vector2) -> void:
	var ratio := dimensions / Vector2(field_width, field_height)
	field_width = dimensions.x
	field_height = dimensions.y
	if is_instance_valid(backdrop):
		backdrop.size = dimensions + Vector2(24, 0)
	for index in heroes.size():
		normalize_hero(heroes[index], str(simulation.actors[index].id))
		heroes[index].position *= ratio
		tracks[index].home = home_for(simulation.actors[index].row, index, false)
		if tracks[index].time < 0:
			heroes[index].position = tracks[index].home
		unit_widgets[index].root.position = tracks[index].home + Vector2(-43, 12)
	for index in foes.size():
		foes[index].regular_height = human_height() * (Biomes.height_factor(int(simulation.tactics.enemies[index].biome), int(simulation.tactics.enemies[index].variant)) if simulation.expedition else 1.0)
		foes[index].boss_height = human_height() * (1.0 if simulation.expedition else 1.22)
		foe_homes[index] = home_for(simulation.tactics.enemies[index].row, index, true)
		foes[index].position = foe_homes[index]
		foe_widgets[index].root.position = foe_homes[index] + Vector2(-43, 12)
	queue_redraw()


func is_action_busy() -> bool:
	if enemy_track.time >= 0:
		return true
	for track in tracks:
		if track.time >= 0:
			return true
	return false


func begin_enemy_attack(index: int, target: int) -> bool:
	if is_action_busy() or index < 0 or index >= foes.size() or target < 0 or target >= heroes.size():
		return false
	enemy_track = {"time": 0.0, "duration": 1.3, "index": index, "target": target, "hit": false}
	return true


func damage_number(message: String, at: Vector2, tint: Color) -> void:
	var text := Label.new()
	text.text = message
	text.position = at + Vector2(-38, -110)
	text.position.x = clampf(text.position.x, 6, field_width - 155)
	text.size = Vector2(160, 36)
	text.add_theme_font_size_override("font_size", 15 if message.contains("ESCUDO") else (18 if message.begins_with("+") else 22))
	text.add_theme_color_override("font_color", tint)
	text.add_theme_color_override("font_outline_color", Color("101321"))
	text.add_theme_constant_override("outline_size", 5)
	text.z_index = 1500
	add_child(text)
	numbers.append({"node": text, "left": 1.35})


func present_result(result: Dictionary, hostile: bool, attacker: int) -> void:
	if hostile and simulation.tactics.enemies[attacker]["class"] == "mage" and not result.get("non_attack", false):
		for target in result.get("targets", [result.get("target", -1)]):
			if target >= 0: enemy_areas.append({"at": tracks[target].home, "left": 1.0})
	if result.get("ultimate", false) and not hostile:
		ultimate_effect(attacker, result)
	if result.get("non_attack", false):
		damage_number("SUPORTE", foe_homes[attacker], Color("b1c5f6"))
		return
	var targets: Array = result.get("targets", [result.target])
	for target in targets:
		var at: Vector2 = tracks[target].home if hostile else foe_homes[target]
		var amount: float = float(result.get("target_damage", {}).get(target, result.damage))
		var text := "ESQUIVA" if result.get("target_evaded", {}).get(target, result.evaded) else ("CRÍTICO  %d" % int(amount) if result.get("critical", false) else str(int(amount)))
		damage_number(text, at, Color("f8d38c") if not hostile else Color("ffb5b4"))
		if result.get("target_guarded", {}).get(target, result.get("guarded", false)):
			damage_number("GUARDA", at + Vector2(0, 32), Color("8bcce4"))

	if result.get("counter", 0) > 0:
		var at: Vector2 = foe_homes[attacker] if hostile else tracks[attacker].home
		damage_number("CONTRA %d" % int(result.counter), at, Color("bca8f6"))
	if result.get("followup", false) or result.get("focused", false):
		damage_number("DISPARO EXTRA" if result.get("followup", false) else "CONCENTRAÇÃO", (foe_homes[attacker] if hostile else tracks[attacker].home) + Vector2(-10, 50), Color("a9c6ff"))
	if not reduced_motion and not result.evaded:
		hit_stop = maxf(hit_stop, 0.045)
	for key in result.get("synergies", []): show_synergy(key)



func show_synergy(key: String) -> void:
	var pairs: Dictionary = preload("res://scripts/team_synergies.gd").PAIRS
	if not pairs.has(key): return
	var homes: Array[Vector2] = []
	for index in simulation.actors.size():
		if pairs[key].heroes.has(simulation.actors[index].id): homes.append(tracks[index].home + Vector2(0, -70))
	if homes.size() == 2:
		effects.append({"from": homes[0], "to": homes[1], "time": 0.8, "duration": 0.8, "color": Color("f8d590")})
	damage_number("SINERGIA · " + str(pairs[key].name), Vector2(field_width * 0.5, field_height * 0.4), Color("ffe0a5"))
	var tag: Label = numbers[-1].node
	tag.position = Vector2(20, field_height * 0.14)
	tag.size = Vector2(field_width - 40, 44)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 18)


func ultimate_effect(index: int, result: Dictionary) -> void:
	var id: String = simulation.actors[index].id
	var points: Array[Vector2] = []
	for at in result.get("targets", []): points.append(foe_homes[at] + Vector2(0, -human_height() * 0.5))
	if id in ["rapunzel", "ariel", "aladin"]:
		for track in tracks:
			if track.alive: points.append(track.home + Vector2(0, -human_height() * 0.5))
	for at in points:
		bursts.append({"id": id, "from": tracks[index].home + Vector2(0, -human_height() * 0.5), "at": at, "left": 1.5, "duration": 1.5})
	if not reduced_motion: hit_stop = 0.10

func draw_burst(burst: Dictionary) -> void:
	var t: float = 1 - burst.left / burst.duration
	var at: Vector2 = burst.at if reduced_motion else Vector2(burst.from).lerp(burst.at, smoothstep(0, 0.65, t))
	var extent := Vector2.ONE * human_height() * (1.25 if str(burst.id) == "alice" else 1.15)
	var texture := UltimateArt.frame(str(burst.id), t)
	draw_texture_rect(texture, Rect2(at - extent * 0.5, extent), false, Color(1, 1, 1, minf(1, (1 - t) * 5)))


func compact_hp(value: float) -> String:
	if value >= 1000000: return "%.1fm" % (value / 1000000.0)
	if value >= 10000: return "%.0fk" % (value / 1000.0)
	return str(ceili(value))
