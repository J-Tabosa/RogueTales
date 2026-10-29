extends Node2D
const HealthDisplay = preload("res://scripts/health_display.gd")
## Combat view. Every effect follows the target selected by the formation rules.
signal attack_hit(index: int)
signal attack_started(index: int)
signal enemy_attack_hit(index: int)
signal status_requested(index: int, hostile: bool)
const Formation = preload("res://scripts/formation_layout.gd")
const ArenaSkin = preload("res://scripts/ui_skin.gd")
const Biomes = preload("res://scripts/biomes.gd")
const Worlds=preload("res://scripts/world_routes.gd")
const CharacterEffects = preload("res://scripts/character_effects.gd")
const UltVFX = preload("res://scripts/ultimate_vfx.gd")
const UltimateArt = preload("res://scripts/ultimate_art.gd")
const EnemyArt = preload("res://scripts/enemy_art.gd")
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
var attack_warmup:Node
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
var vfx: Node2D
var atmosphere:Control
var enemy_impacts: Array[Dictionary] = []
var enemy_areas: Array[Dictionary] = []
static var hero_shape_cache: Dictionary = {}



func _ready() -> void:
	vfx = Node2D.new()
	vfx.set_script(preload("res://scripts/combat_vfx.gd"))
	vfx.arena = self
	vfx.z_index = 1000
	add_child(vfx)
	backdrop = TextureRect.new()
	var map:Dictionary=Worlds.current(simulation.journey,mini(stage,simulation.journey.path.size()-1)) if simulation.expedition and not simulation.journey.is_empty() else {}
	backdrop.texture = Worlds.texture(str(simulation.journey.path[mini(stage,simulation.journey.path.size()-1)])) if not map.is_empty() else Biomes.scenery(stage)
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var projection := ShaderMaterial.new()
	projection.shader = preload("res://assets/worlds/arena_world.gdshader") if not map.is_empty() else preload("res://assets/biomes/arena_floor.gdshader")
	var window := Vector2(map.floor[0],map.floor[1]) if not map.is_empty() else Biomes.floor_window(stage)
	projection.set_shader_parameter("ground_start",window.x)
	projection.set_shader_parameter("ground_end",window.y)
	projection.set_shader_parameter("floor_horizon",Formation.FLOOR_HORIZON)
	backdrop.material = projection
	backdrop.position.x = -12
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE if not map.is_empty() else TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
		unit_widgets.append(widget(home, TaleCatalog.hero_class_name(simulation.actors[index].id), Color("a3d9c3"),false,index))
	if not heroes.is_empty():
		hero = heroes[0]
	queue_redraw()


func home_for(_row: String,index: int,hostile: bool) -> Vector2:
	return Formation.home(simulation.tactics.enemies if hostile else simulation.actors,index,hostile)*Vector2(field_width,field_height)

func spawn_zone(hostile: bool) -> Rect2:
	var zone := Formation.zone(hostile)
	return Rect2(zone.position*Vector2(field_width,field_height),zone.size*Vector2(field_width,field_height))

func max_row_size() -> int:
	return maxi(Formation.max_stack(simulation.actors),Formation.max_stack(simulation.tactics.enemies))

func widget_size() -> Vector2:
	# Each plate fits inside one formation column, including at nine vs nine.
	return Vector2(clampf(field_width * 0.115, 54, 104), 27)

func place_widget(item: Dictionary, at: Vector2) -> void:
	var extent := widget_size()
	# Depth follows the owner, so nearer bodies occlude rear plates.
	item.root.z_index=int(at.y)+1
	item.panel.size = extent
	item.root.position = Vector2(clampf(at.x - extent.x * .5, 4, field_width - extent.x - 4), minf(at.y + 5, field_height - extent.y - 4))
	item.text.position = Vector2(3, 1)
	item.text.size = Vector2(extent.x - 6, 13)
	item.text.add_theme_font_size_override("font_size", 9 if extent.x < 80 else 10)
	item.health.position = Vector2(5, 16)
	item.health.size = Vector2(extent.x - 10, 4)
	item.energy.position = Vector2(5, 22)
	item.energy.size = Vector2(extent.x - 10, 3)

func hero_bounds(actor: AnimatedSprite2D) -> Rect2:
	var texture: Texture2D = actor.sprite_frames.get_frame_texture("idle", 0)
	if texture is MeshTexture:
		var bounds: AABB = texture.mesh.get_aabb()
		return Rect2(Vector2(bounds.position.x, bounds.position.y), Vector2(bounds.size.x, bounds.size.y))
	if texture is AtlasTexture: return Rect2(texture.margin.position, texture.region.size)
	return Rect2(Vector2.ZERO, texture.get_size())

func human_height() -> float:
	# Each vertical slot reserves a plate plus 8px. Scale depends on the viewport,
	# never on current party/enemy composition, avoiding size changes mid-run.
	var presence:=clampf(minf(field_height*.31,field_width*(.195 if field_width<700 else .18)),64,184)
	return minf(presence,maxf(32,field_height*.26-widget_size().y-8))


func normalize_hero(actor: AnimatedSprite2D, id: String) -> void:
	var bounds := hero_bounds(actor)
	var height := human_height() * preload("res://scripts/character_visuals.gd").height(id)
	actor.scale = Vector2(preload("res://scripts/character_visuals.gd").width(id),1) * (height / maxf(1, bounds.size.y))
	actor.offset = -Vector2(bounds.get_center().x, bounds.end.y)
	actor.set_meta("visual_height", height)
	if id=="scarlet" and actor.material is ShaderMaterial:actor.material.set_shader_parameter("ink_width",1.2/maxf(.01,actor.scale.y))



func fit_hero_in_view(actor:AnimatedSprite2D) -> void:
	var texture:Texture2D=actor.sprite_frames.get_frame_texture(actor.animation,actor.frame)
	if not texture is MeshTexture:return
	var bounds:AABB=texture.mesh.get_aabb()
	var corners:=PackedVector2Array()
	for point in [Vector2(bounds.position.x,bounds.position.y),Vector2(bounds.end.x,bounds.position.y),Vector2(bounds.position.x,bounds.end.y),Vector2(bounds.end.x,bounds.end.y)]:
		corners.append(actor.transform*(point+actor.offset))
	var left:=INF
	var right:=-INF
	var top:=INF
	var bottom:=-INF
	for point in corners:
		left=minf(left,point.x)
		right=maxf(right,point.x)
		top=minf(top,point.y)
		bottom=maxf(bottom,point.y)
	if right-left<field_width-4:actor.position.x+=maxf(0,2-left)-maxf(0,right-field_width+2)
	if bottom-top<field_height-4:actor.position.y+=maxf(0,2-top)-maxf(0,bottom-field_height+2)


func widget(at: Vector2,title: String,tint: Color,hostile:=false,unit_index:=-1) -> Dictionary:
	var group:=Node2D.new()
	group.z_index=900
	add_child(group)
	var panel:=Panel.new()
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var plate:=StyleBoxFlat.new()
	plate.bg_color=Color("102a24")
	plate.border_color=Color("8c7043")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel",plate)
	group.add_child(panel)
	var text:=Label.new()
	text.text=title
	text.clip_text=true
	text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_color",Color("f5e8c3"))
	panel.add_child(text)
	var bars:Array[ProgressBar]=[]
	for index in 2:
		var bar:=ProgressBar.new()
		bar.show_percentage=false
		bar.position=Vector2(8,20 if index==0 else 28)
		bar.size=Vector2(64,5 if index==0 else 3)
		var bg:=StyleBoxFlat.new()
		bg.bg_color=Color("091a19")
		bg.set_corner_radius_all(2)
		var fill:=bg.duplicate()
		fill.bg_color=tint if index==0 else Color("76b8e9")
		bar.add_theme_stylebox_override("background",bg)
		bar.add_theme_stylebox_override("fill",fill)
		panel.add_child(bar)
		bars.append(bar)
	var item:={"root":group,"panel":panel,"text":text,"health":bars[0],"energy":bars[1],"hostile":hostile,"index":unit_index,"badges":{}}
	place_widget(item,at)
	return item

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
		if data.has("secret_id"):
			model=AnimatedSprite2D.new()
			model.set_script(Enemy)
			model.secret_id=data.secret_id
			model.sprite_frames=preload("res://scripts/secret_enemy_art.gd").frames(data.secret_id)
			model.body_height=400
			model.illustrated=true
		elif simulation.expedition:
			model = AnimatedSprite2D.new()
			model.set_script(Enemy)
			model.sprite_frames = Biomes.frames(int(data.biome), int(data.variant))
			model.body_height = model.sprite_frames.get_frame_texture("idle", 0).get_image().get_used_rect().size.y
			model.illustrated = true
			model.biome_id = int(data.biome)
			model.variant_id = int(data.variant)
			model.flip_h = false
		else: model = Enemy.warm(stage).instantiate()
		model.regular_height = human_height() * (Biomes.height_factor(int(data.biome), int(data.variant))*(0.72 if ExpeditionContent.is_boss(simulation.stage,simulation.phase) and not data.boss else 1.0) if simulation.expedition else 1.0)
		model.boss_height = human_height() * (1.25 if data.has("secret_id") else 1.40 if simulation.expedition else 1.22)
		add_child(model)
		var home := home_for(str(data.row), index, true)
		model.advance(0, data.boss, 0, data.interval)
		model.position = home
		model.z_index = int(home.y)
		foes.append(model)
		foe_homes.append(home)
		foe_widgets.append(widget(home, ("★ " if data.boss else "") + str(TaleCatalog.CLASSES[data["class"]].name), Color("dd9691"),true,index))
		data["death_left"] = 0.0
		data["was_alive"] = true
	if not foes.is_empty():
		enemy = foes[0]
	fit_field(Vector2(field_width,field_height))
	sync_health(simulation.actors)
	if is_instance_valid(attack_warmup):attack_warmup.queue_free()
	attack_warmup=preload("res://scripts/combat_warmup.gd").new()
	add_child(attack_warmup)
	attack_warmup.start(heroes+foes,simulation.actors.map(func(a):return a.id))

func warming_attacks() -> bool:
	return is_instance_valid(attack_warmup) and attack_warmup.busy

func attack(index: int = 0, target: int = -1, ultimate := false) -> bool:
	if is_action_busy():
		return false
	if index < 0 or index >= tracks.size() or not tracks[index].alive or tracks[index].time >= 0 or target < 0 or target >= foes.size():
		return false
	var actor: AnimatedSprite2D = heroes[index]
	tracks[index].time = 0.0
	tracks[index].duration = maxf(1.7 if ultimate else 1.12, actor.get_animation_duration("attack") * (1.40 if ultimate else 1.20))
	var id:String=simulation.actors[index].id
	var fresh:bool=ultimate and simulation.expedition and UltVFX.supported(id)
	tracks[index]["fresh_ult"]=fresh
	if fresh:
		tracks[index].duration=UltVFX.duration(id)
		tracks[index]["effect_targets"]=UltVFX.Rules.targets(simulation.tactics,index,target)
		tracks[index]["ally_targets"]=UltVFX.Rules.allies(simulation,index) if id=="rapunzel" else []
	if ultimate:
		intro_left = 0.55
		if is_instance_valid(feedback): feedback.announce_ultimate(simulation.actors[index].id)
	tracks[index].hit = false
	tracks[index].target = target
	tracks[index].ultimate = ultimate
	var animation:String=UltVFX.pose_animation(id) if fresh else "attack"
	actor.reset_pose_motion()
	actor.show_animation(animation)
	actor.seek_animation(animation,0)
	if ultimate and is_instance_valid(atmosphere):atmosphere.ultimate_started(index,id)
	attack_started.emit(index)
	return true


func set_animation(id: String) -> void:
	for index in heroes.size():
		if tracks[index].alive:
			heroes[index].show_animation(id)


func reset_effects() -> void:
	if is_instance_valid(atmosphere):atmosphere.clear()
	walking = false
	intro_left = 0.0
	bursts.clear()
	enemy_impacts.clear()
	enemy_areas.clear()
	enemy_track.time = -1.0
	hit_stop = 0.0
	for item in numbers:
		item.node.queue_free()
	numbers.clear()
	effects.clear()
	for index in tracks.size():
		if simulation.actors[index].ult_pending:
			if simulation.expedition and simulation.actors[index].id=="alice":simulation.actors[index].card_charge+=4
			else:simulation.actors[index].energy += simulation.tactics.Rules.cost(simulation.actors[index])
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
		unit_widgets[index].root.visible = actors[index].hp > 0
		HealthDisplay.update(unit_widgets[index].health,actors[index])
		unit_widgets[index].energy.max_value = 4 if simulation.expedition and actors[index].id=="alice" else maxf(1,simulation.tactics.Rules.cost(actors[index]))
		unit_widgets[index].energy.value = actors[index].get("card_charge",0) if simulation.expedition and actors[index].id=="alice" else actors[index].energy
		sync_conditions(unit_widgets[index],actors[index],index,false)
		unit_widgets[index].text.text = ("%s/%s" if unit_widgets[index].panel.size.x<90 else "%s/%s PV") % [compact_hp(actors[index].hp),compact_hp(HealthDisplay.capacity(actors[index]))]
		if actors[index].id=="alice":unit_widgets[index].text.text=CharacterEffects.SUITS[int(actors[index].get("suit",0))%4]+" "+unit_widgets[index].text.text
	for index in foes.size():
		var data: Dictionary = simulation.tactics.enemies[index]
		foes[index].visible = enemy_visible and (data.hp > 0 or data.get("death_left", 0) > 0)
		foe_widgets[index].root.visible = enemy_visible and data.hp > 0
		HealthDisplay.update(foe_widgets[index].health,data)
		foe_widgets[index].energy.visible = false
		sync_conditions(foe_widgets[index],data,index,true)
		foe_widgets[index].text.text = ("%s/%s" if foe_widgets[index].panel.size.x<90 else "%s/%s PV") % [compact_hp(data.hp),compact_hp(HealthDisplay.capacity(data))]



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
	if is_instance_valid(atmosphere):
		atmosphere.frozen=frozen
		atmosphere.reduced_motion=reduced_motion
	if is_instance_valid(feedback): feedback.frozen = frozen
	var dt := 0.0 if frozen or hit_stop > 0 or intro_left > 0 else minf(delta, 0.25) * speed
	if not frozen: intro_left = maxf(0, intro_left - delta)
	if walking and dt > 0:
		travel_progress = minf(1, travel_progress + dt / 2.8)
		backdrop.position.x=-12 if reduced_motion else -12-12*travel_progress
	if not walking: backdrop.position.x=-12
	entrance_left = maxf(0, entrance_left - dt)
	if not frozen:
		hit_stop = maxf(0, hit_stop - delta * speed)
	clock += dt
	for index in heroes.size():
		var actor: AnimatedSprite2D = heroes[index]
		actor.z_index = int(actor.position.y)
		var track: Dictionary = tracks[index]
		var hero_id: String=simulation.actors[index].id
		if track.time<0 and not walking and track.alive:
			actor.position=track.home
			if hero_id in ["ariel","aladin","peter"]: actor.position.y-=human_height()*0.1+(0.0 if reduced_motion else sin(clock*2.5+index)*human_height()*0.025)
		actor.speed_scale = 0.0 if frozen or hit_stop > 0 or intro_left > 0 or not track.alive else speed
		track.hurt = maxf(0, track.hurt - dt)
		if track.alive:
			actor.modulate = Enemy.hurt_color(track.hurt)
		if walking and track.alive:
			actor.position = track.home + Vector2(-90 * (1.0 - travel_progress), 0)
			if simulation.actors[index].id in ["ariel","aladin","peter"]:actor.position.y-=human_height()*0.1
		actor.z_index = int(actor.position.y)
		if track.time < 0 or dt <= 0:
			continue
		track.time += dt
		var phase: float = clampf(track.time / track.duration, 0, 1)
		var target: int = track.target
		if target >= 0 and target < simulation.tactics.enemies.size() and simulation.tactics.enemies[target].hp <= 0 and not track.hit:
			track.target = simulation.tactics.target_for(index)
			target = track.target
		var impact: float = UltVFX.impact(hero_id) if track.get("fresh_ult",false) else actor.impact_ratio
		if track.get("fresh_ult",false):
			UltVFX.pose(self,index,phase)
		else:
			var visual_phase:=phase
			if track.ultimate and hero_id in ["mulan","joao"] and phase<impact: visual_phase=fposmod(phase/impact*(3.0 if hero_id=="mulan" else 5.0),1.0)
			if track.ultimate and hero_id=="puss":visual_phase=1.0-phase
			actor.seek_animation("attack",visual_phase*actor.get_animation_duration("attack"))
			if actor.is_melee_attack() and not (actor.is_hair_attack() and track.ultimate):
				if target >= 0:
					var contact := foe_homes[target] + Vector2(-62, 8)
					var dash := smoothstep(0, 1, phase / maxf(0.1, impact * 0.65)) if phase < impact else (1.0 - smoothstep(impact, 1, phase))
					if track.ultimate and hero_id in ["mulan","joao"] and phase<impact: dash=0.3+sin(fposmod(phase/impact*(3.0 if hero_id=="mulan" else 5.0),1.0)*PI)*0.7
					actor.position = track.home.lerp(contact, dash)
					if track.ultimate and hero_id=="mulan" and phase>impact*0.65 and phase<impact:actor.position.y-=sin((phase-impact*0.65)/(impact*0.35)*PI)*human_height()*0.7
					if track.ultimate and hero_id=="puss" and not reduced_motion:actor.rotation=TAU*smoothstep(0.15,impact,phase) if phase<impact else 0.0
		if not track.hit and phase >= impact:
			track.hit = true
			if track.get("fresh_ult",false) and is_instance_valid(atmosphere):atmosphere.impact(hero_id)
			# Emit before starting recovery: the controller applies exactly one result.
			attack_hit.emit(index)
			if not is_instance_valid(actor):
				return
		if track.time >= track.duration:
			track.time = -1.0
			actor.rotation=0.0
			actor.scale=actor.get_meta("battle_scale")
			actor.position = track.home
			if track.alive:
				actor.show_animation("idle")
		fit_hero_in_view(actor)
		actor.z_index = int(actor.position.y)
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
			foes[index].z_index = int(foes[index].position.y)
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
	for impact in enemy_impacts: impact.left -= dt
	enemy_impacts = enemy_impacts.filter(func(impact): return impact.left > 0)
	if dt > 0:
		queue_redraw()
		vfx.queue_redraw()


func _draw() -> void:
	for track in tracks:
		draw_set_transform(track.home, 0, Vector2(1, 0.23))
		draw_circle(Vector2.ZERO, human_height()*0.24, Color("0a151b", 0.5), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	for at in foe_homes:
		draw_set_transform(at, 0, Vector2(1, 0.23))
		draw_circle(Vector2.ZERO, human_height()*0.24, Color("0a151b", 0.5), true, -1, true)
	draw_set_transform(Vector2.ZERO)


func draw_combat_effects(canvas: Node2D) -> void:
	UltVFX.draw(self,canvas)
	for index in tracks.size():
		var track: Dictionary = tracks[index]
		if track.get("fresh_ult",false) or track.time < 0 or track.hit or track.target < 0 or track.target >= foe_homes.size():
			continue
		var phase: float = track.time / track.duration
		var id: String=simulation.actors[index].id
		if CharacterEffects.IDS.has(id):
			if not track.ultimate: CharacterEffects.basic(self,canvas,index,phase)
			elif id in ["mulan","puss","joao"] and phase>0.16:CharacterEffects.stamp(canvas,id,heroes[index].position+Vector2(human_height()*0.3,-human_height()*0.5),Vector2.ONE*human_height()*1.25,phase/heroes[index].impact_ratio,true)
			continue
		var release: float = heroes[index].impact_ratio * 0.45
		if phase < release:
			continue
		var t := clampf((phase - release) / maxf(0.01, heroes[index].impact_ratio - release), 0, 1)
		var from := heroes[index].position + Vector2(15, -65)
		var to := foe_homes[track.target] + Vector2(0, -60)
		var tint: Color = TaleCatalog.HEROES[simulation.actors[index].id].color
		if heroes[index].is_melee_attack():
			if phase > heroes[index].impact_ratio * 0.65:
				canvas.draw_arc(to, 25 if not track.ultimate else 48, -1.8, 1.2, 18, tint, 3, true)
		else:
			var point := from.lerp(to, t)
			if heroes[index].attack_style == 0:
				point.y -= sin(t * PI) * 50
				canvas.draw_circle(point, 9, Color("242127"), true, -1, true)
				canvas.draw_line(point + Vector2(3, -8), point + Vector2(7, -14), tint, 3, true)
			elif heroes[index].attack_style == 2:
				canvas.draw_circle(point - Vector2(3, 0), 6, Color("dc3f56"), true, -1, true)
				canvas.draw_circle(point + Vector2(3, 0), 6, Color("e95062"), true, -1, true)
				canvas.draw_line(point + Vector2(0, -5), point + Vector2(2, -10), Color("b4c793"), 2)
			elif heroes[index].attack_style == 5:
				var direction := (to - from).normalized()
				for bolt in (3 if track.ultimate else 1):
					var at := point + Vector2(0, (bolt - (1 if track.ultimate else 0)) * 9)
					canvas.draw_line(at - direction * 24, at, Color("eee5cf"), 3, true)
			elif heroes[index].attack_style == 7:
				canvas.draw_set_transform(point, t * TAU, Vector2.ONE)
				canvas.draw_rect(Rect2(-6, -9, 12, 18), Color("f9edce"))
				canvas.draw_circle(Vector2.ZERO, 3, Color("d94764"))
				canvas.draw_set_transform(Vector2.ZERO)
			elif heroes[index].attack_style == 9:
				canvas.draw_line(from.lerp(to, maxf(0, t - 0.12)), point, Color("ed6f3b"), 7, true)
				canvas.draw_circle(point, 5, Color("ffe2a0"), true, -1, true)
			elif heroes[index].attack_style == 11:
				canvas.draw_arc(point, 9, 0, TAU, 20, tint, 3, true)
				canvas.draw_circle(point, 4, Color("e7fff5"), true, -1, true)
			else:
				canvas.draw_line(from.lerp(to, maxf(0, t - 0.18)), point, tint, 6, true)
		if track.ultimate:
			canvas.draw_arc(to, 32 + t * 16, 0, TAU, 32, Color(tint, 0.65), 3, true)
	if enemy_track.time >= 0 and not enemy_track.get("support", false) and enemy_track.target >= 0:
		var index: int = enemy_track.index
		var phase: float = enemy_track.time / enemy_track.duration
		if phase >= 0.2 and phase < 0.55 and simulation.tactics.enemies[index]["class"] in ["mage", "ranger"]:
			var from := foe_homes[index] + Vector2(0, -75)
			var to: Vector2 = tracks[enemy_track.target].home + Vector2(0, -65)
			var t := clampf((phase - 0.2) / 0.35, 0, 1)
			var point := from.lerp(to, t)
			var tint: Color = Biomes.COLORS[simulation.current_biome() if simulation.expedition else Biomes.biome(stage)]
			if simulation.tactics.enemies[index]["class"] == "ranger":
				var direction := (to - from).normalized()
				canvas.draw_line(point - direction * 30, point, Color("fbe5b1"), 4, true)
				canvas.draw_line(point, point - direction.rotated(0.55) * 12, tint, 3, true)
				canvas.draw_line(point, point - direction.rotated(-0.55) * 12, tint, 3, true)
			else:
				canvas.draw_line(from.lerp(to, maxf(0, t - 0.2)), point, Color(tint, 0.7), 8, true)
				canvas.draw_circle(point, 13, Color(tint, 0.3), true, -1, true)
				canvas.draw_circle(point, 7, Color("fff2da"), true, -1, true)
	for area in enemy_areas:
		var tint := Color(Biomes.COLORS[simulation.current_biome() if simulation.expedition else Biomes.biome(stage)], minf(1, area.left * 2))
		var radius: float = 26 + (1.0 - area.left) * 42
		canvas.draw_set_transform(area.at, 0, Vector2(1, 0.35))
		canvas.draw_arc(Vector2.ZERO, radius, 0, TAU, 30, tint, 4, true)
		for point in 6:
			var dir := Vector2.from_angle(point * TAU / 6)
			canvas.draw_line(dir * 10, dir * radius, tint, 3, true)
		canvas.draw_set_transform(Vector2.ZERO)
	for burst in bursts: draw_burst(canvas, burst)
	for index in simulation.actors.size():
		var actor:Dictionary=simulation.actors[index]
		if actor.hp<=0 or actor.id!="peter":continue
		for flame in int(actor.get("spirit_flames",0)):
			var angle:=flame*TAU/3.0+(0.0 if reduced_motion else clock*1.8)
			var at:Vector2=heroes[index].position+Vector2(0,-human_height()*0.5)+Vector2.from_angle(angle)*human_height()*0.48
			CharacterEffects.stamp(canvas,"peter",at,Vector2.ONE*human_height()*0.33,0.0,false)
	if walking:
		for step in 9:
			var x := fposmod(step * 83.0 - clock * 90.0, field_width)
			canvas.draw_line(Vector2(x, field_height * 0.9), Vector2(x + 23, field_height * 0.9), Color("d6be88", 0.18), 2)
	for item in effects:
		canvas.draw_line(item.from, item.to, Color(item.color, item.time / item.duration), 3, true)
	for index in foe_homes.size():
		var foe: Dictionary = simulation.tactics.enemies[index]
		if not enemy_visible or foe.hp <= 0 or not foe.has("binds"): continue
		for at in simulation.actors.size():
			if simulation.actors[at].id == foe.binds and simulation.actors[at].hp > 0:
				canvas.draw_line(foe_homes[index] + Vector2(0, -80), tracks[at].home + Vector2(0, -70), Color("c885b8", 0.55), 2, true)

	for impact in enemy_impacts:
		var progress: float = 1.0 - impact.left / 0.85
		var texture := EnemyArt.frame(int(impact.biome), progress)
		var extent := Vector2.ONE * human_height() * 1.15
		canvas.draw_texture_rect(texture, Rect2(impact.at - extent * 0.5, extent), false, Color(1, 1, 1, minf(1, impact.left * 4)))


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
		if simulation.expedition and not simulation.journey.is_empty():
			backdrop.material.set_shader_parameter("arena_aspect",backdrop.size.x/backdrop.size.y)
			backdrop.material.set_shader_parameter("source_aspect",backdrop.texture.get_size().aspect())
	for index in heroes.size():
		normalize_hero(heroes[index], str(simulation.actors[index].id))
		heroes[index].set_meta("battle_scale",heroes[index].scale)
		heroes[index].position *= ratio
		tracks[index].home = home_for(simulation.actors[index].row, index, false)
		if tracks[index].time < 0:
			heroes[index].position = tracks[index].home
		place_widget(unit_widgets[index],tracks[index].home)
	for index in foes.size():
		foes[index].regular_height = human_height() * (Biomes.height_factor(int(simulation.tactics.enemies[index].biome), int(simulation.tactics.enemies[index].variant))*(0.72 if ExpeditionContent.is_boss(simulation.stage,simulation.phase) and not simulation.tactics.enemies[index].boss else 1.0) if simulation.expedition else 1.0)
		foes[index].boss_height = human_height() * (1.25 if simulation.tactics.enemies[index].has("secret_id") else 1.40 if simulation.expedition else 1.22)
		foe_homes[index] = home_for(simulation.tactics.enemies[index].row, index, true)
		foes[index].position = foe_homes[index]
		place_widget(foe_widgets[index],foe_homes[index])
	queue_redraw()


func is_action_busy() -> bool:
	if warming_attacks():return true
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
	text.position = at + Vector2(-80, -110)
	text.position.x = clampf(text.position.x, 6, field_width - 166)
	text.size = Vector2(160, 44)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 13 if message.length() > 12 else 15 if message.contains("ESCUDO") else (18 if message.begins_with("+") else 22))
	text.add_theme_color_override("font_color", tint)
	text.add_theme_color_override("font_outline_color", Color("101321"))
	text.add_theme_constant_override("outline_size", 5)
	text.z_index = 1500
	add_child(text)
	numbers.append({"node": text, "left": 1.35})


func present_result(result: Dictionary, hostile: bool, attacker: int) -> void:
	if hostile and result.get("blocked_spirit",false):
		var guarded:int=result.get("blocked_target",result.get("target",-1))
		if guarded>=0:
			bursts.append({"id":"peter","spirit_return":true,"from":tracks[guarded].home+Vector2(0,-human_height()*.5),"at":foe_homes[attacker]+Vector2(0,-human_height()*.5),"left":.65,"duration":.65})
	if hostile and not result.get("non_attack", false) and not result.get("blocked_spirit",false):
		for target in result.get("targets", [result.get("target", -1)]):
			if target >= 0 and target < tracks.size():
				enemy_impacts.append({"at": tracks[target].home + Vector2(0, -human_height() * 0.45), "biome": simulation.current_biome() if simulation.expedition else Biomes.biome(stage), "left": 0.85})
	if hostile and simulation.tactics.enemies[attacker]["class"] == "mage" and not result.get("non_attack", false):
		for target in result.get("targets", [result.get("target", -1)]):
			if target >= 0 and target<tracks.size(): enemy_areas.append({"at": tracks[target].home, "left": 1.0})
	if result.get("ultimate", false) and not hostile:
		ultimate_effect(attacker, result)
	if result.get("non_attack", false):
		damage_number("SUPORTE", foe_homes[attacker] if hostile else tracks[attacker].home, Color("b1c5f6"))
		return
	var targets: Array = result.get("targets", [result.target])
	for target in targets:
		if target<0 or (target>=tracks.size() if hostile else target>=foe_homes.size()):continue
		var at: Vector2 = tracks[target].home if hostile else foe_homes[target]
		var amount: float = float(result.get("target_damage", {}).get(target, result.damage))
		var text := "ESQUIVA" if result.get("target_evaded", {}).get(target, result.evaded) else ("CRÍTICO  %d" % int(amount) if result.get("critical", false) else str(int(amount)))
		if amount>0 or result.get("evaded",false):damage_number(text, at, Color("f8d38c") if not hostile else Color("ffb5b4"))
		elif not hostile and result.get("ultimate",false):
			var id:String=simulation.actors[attacker].id
			if id=="aladin":damage_number("SONO" if target in result.get("status_targets",[]) else "RESISTIU",at,Color("c5b0ef"))
			elif id=="maria":damage_number("MALDIÇÃO −20%" if target in result.get("status_targets",[]) else "RESISTIU",at,Color("c5b0ef"))
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
	if simulation.expedition and UltVFX.supported(id) and tracks[index].get("fresh_ult",false) and tracks[index].time>=0:
		tracks[index]["effect_targets"]=result.get("targets",[])
		return
	var points: Array[Vector2] = []
	for at in result.get("targets", []): points.append(foe_homes[at] + Vector2(0, -human_height() * 0.5))
	if id=="rapunzel":
		points.clear()
		for track in tracks:
			if track.alive: points.append(track.home + Vector2(0, -human_height() * 0.5))
	if id in ["ariel","aladin","peter"]:points.assign([tracks[index].home+Vector2(0,-human_height()*0.5)])
	if id=="matches":points.append(tracks[index].home+Vector2(0,-human_height()*0.5))
	for at in points:
		bursts.append({"id": id, "from": tracks[index].home + Vector2(0, -human_height() * 0.5), "at": at, "left": 1.5, "duration": 1.5,"suit":simulation.actors[index].get("suit",0)})
	if not reduced_motion: hit_stop = 0.10
	if is_instance_valid(vfx): vfx.queue_redraw()

func draw_burst(canvas: Node2D, burst: Dictionary) -> void:
	if burst.get("spirit_return",false):
		var t:float=1-burst.left/burst.duration
		UltVFX.stamp(canvas,"peter",Vector2(burst.from).lerp(burst.at,smoothstep(0,.80,t)),Vector2.ONE*human_height()*.65,t,minf(1,(1-t)*6))
		return
	if CharacterEffects.IDS.has(str(burst.id)):
		CharacterEffects.burst(self,canvas,burst)
		return
	var t: float = 1 - burst.left / burst.duration
	var at: Vector2 = burst.at if reduced_motion else Vector2(burst.from).lerp(burst.at, smoothstep(0, 0.65, t))
	var extent := Vector2.ONE * human_height() * (1.25 if str(burst.id) == "alice" else 1.15)
	var texture := UltimateArt.frame(str(burst.id), t)
	canvas.draw_texture_rect(texture, Rect2(at - extent * 0.5, extent), false, Color(1, 1, 1, minf(1, (1 - t) * 5)))


func compact_hp(value: float) -> String:
	if value >= 1000000: return "%.1fm" % (value / 1000000.0)
	if value >= 10000: return "%.0fk" % (value / 1000.0)
	return str(ceili(value))

func passive_effect(event:Dictionary) -> void:
	if str(event.get("hero",""))!="matches" or str(event.get("kind",""))!="passive":return
	for index in simulation.actors.size():
		if simulation.actors[index].id=="matches":
			var targets:Array=[]
			for at in simulation.tactics.enemies.size():
				if simulation.tactics.enemies[at].hp>0:targets.append(at)
			ultimate_effect(index,{"targets":targets})

func sync_conditions(item: Dictionary, data: Dictionary, index: int, hostile: bool) -> void:
	var visible_conditions:=preload("res://scripts/status_art.gd").active(data,hostile)
	for kind in item.badges.keys():
		if not visible_conditions.has(kind):
			item.badges[kind].queue_free()
			item.badges.erase(kind)
	var slot := 0
	for kind in visible_conditions:
		if not item.badges.has(kind):
			var badge:=Button.new()
			badge.set_script(preload("res://scripts/status_badge.gd"))
			badge.pressed.connect(func(): status_requested.emit(index,hostile))
			item.panel.add_child(badge)
			item.badges[kind]=badge
		var badge: Button=item.badges[kind]
		badge.configure(kind,visible_conditions[kind][0],visible_conditions[kind][1])
		if widget_size().x < 80 and kind in ["poison","burn","bleed"]:
			badge.text = " %d" % ceili(visible_conditions[kind][0])
			badge.add_theme_font_size_override("font_size",8)
		var badge_width: float = (widget_size().x - 2) * .5
		badge.position=Vector2((slot%2) * (badge_width + 2), 29+floori(slot/2.0)*19)
		badge.size=Vector2(badge_width, 17)
		slot+=1
