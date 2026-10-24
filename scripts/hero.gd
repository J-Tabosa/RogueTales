extends AnimatedSprite2D
## The scene owns textures, frame order, scale and FPS.
## Idle holds frame 0, then occasionally plays a blink or a short sway once.

enum IdleState { REST, BLINK, SWAY }
enum AttackStyle { BOMB, HAIR, APPLE, SWORD, TIDE, CROSSBOW, DAGGER, CARDS, GREATSWORD, MATCH, SPIRIT, LAMP, CANE, GOBLET, PICKAXE }

@export_group("Personagem")
@export var hero_name := "Scarlet"
@export var hero_title := "A Bombardeira"
@export var attack_style: AttackStyle = AttackStyle.BOMB
@export_range(0.1, 0.95, 0.01) var impact_ratio := 0.92
@export var accent_color := Color("e9c488")
@export var return_to_idle := true
@export_group("Idle — pausas e variações")
@export var idle_variations_enabled := true
@export_range(1.0, 20.0, 0.5) var idle_min_wait := 4.0
@export_range(1.0, 20.0, 0.5) var idle_max_wait := 8.0
@export_range(0.0, 1.0, 0.05) var blink_chance := 0.7
@export_range(0.0, 8.0, 0.5) var idle_sway_amplitude := 2.0
@export_group("Walk — movimento dos ombros")
@export var walk_shoulders_enabled := true
@export_range(0.0, 16.0, 0.5) var shoulder_swing := 6.0
@export_range(0.0, 12.0, 0.5) var shoulder_roll := 4.0

var idle_state := IdleState.REST
var idle_wait_left := 0.0
var idle_event_elapsed := 0.0
var idle_phase := 0.0
var idle_weight := 0.0
var walk_weight := 0.0
var motion_sleeping := false
var idle_rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	idle_rng.randomize()
	frame_changed.connect(sync_alpha)
	animation_changed.connect(sync_alpha)
	sync_alpha()
	animation_finished.connect(_on_animation_finished)
	show_animation(String(animation))


func _on_animation_finished() -> void:
	if animation == &"attack":
		if return_to_idle:
			_enter_rest()
	elif is_idle_animation() and idle_state != IdleState.REST:
		_enter_rest()


func _enter_rest() -> void:
	idle_state = IdleState.REST
	idle_event_elapsed = 0.0
	# Pause only the saved frames. The idle timer keeps running in _process.
	play("idle")
	set_frame_and_progress(0, 0.0)
	pause()
	idle_wait_left = idle_rng.randf_range(
		minf(idle_min_wait, idle_max_wait), maxf(idle_min_wait, idle_max_wait)
	)


func _start_idle_variation(variation: IdleState) -> void:
	idle_state = variation
	idle_event_elapsed = 0.0
	var anim := "idle_blink" if variation == IdleState.BLINK else "idle"
	if not sprite_frames.has_animation(anim):
		idle_state = IdleState.SWAY
		anim = "idle"
	play(anim)
	set_frame_and_progress(0, 0.0)


func is_idle_animation() -> bool:
	return animation in [&"idle", &"idle_blink"]


func is_hair_attack() -> bool:
	return attack_style == AttackStyle.HAIR


func is_melee_attack() -> bool:
	return attack_style in [AttackStyle.HAIR, AttackStyle.SWORD, AttackStyle.DAGGER, AttackStyle.GREATSWORD, AttackStyle.CANE, AttackStyle.PICKAXE]


func get_weapon_label() -> String:
	match attack_style:
		AttackStyle.PICKAXE:
			return "Picareta quebra-mundo"
		AttackStyle.HAIR:
			return "Chicote de cabelo dourado"
		AttackStyle.APPLE:
			return "Maçãs encantadas"
		AttackStyle.SWORD:
			return "Lâmina da guerreira"
		AttackStyle.TIDE:
			return "Leque das marés"
		AttackStyle.CROSSBOW:
			return "Besta de caçador"
		AttackStyle.DAGGER:
			return "Adaga envenenada"
		AttackStyle.CARDS:
			return "Cartas do País das Maravilhas"
		AttackStyle.GREATSWORD:
			return "Espada do crepúsculo"
		AttackStyle.MATCH:
			return "Fósforos encantados"
		AttackStyle.SPIRIT:
			return "Adaga espectral"
		AttackStyle.CANE:
			return "Bengala de doces"
		AttackStyle.GOBLET:
			return "Taça de suco de uva"
		AttackStyle.LAMP:
			return "Lâmpada dos três desejos"
	return "Bombas à distância"


func is_idle_resting() -> bool:
	return is_idle_animation() and idle_state == IdleState.REST


func get_idle_state_label() -> String:
	match idle_state:
		IdleState.BLINK:
			return "Piscando"
		IdleState.SWAY:
			return "Balançando"
	return "Parada"


func _process(delta: float) -> void:
	# Pausing and 1×/2× affect both the occasional gestures and shoulder motion.
	if speed_scale <= 0.0:
		return
	var dt := delta * speed_scale
	var sway_target := 0.0
	if is_idle_animation():
		if idle_state == IdleState.REST:
			if idle_variations_enabled:
				idle_wait_left -= dt
				if idle_wait_left <= 0.0:
					var choice := (
						IdleState.BLINK if idle_rng.randf() < blink_chance else IdleState.SWAY
					)
					_start_idle_variation(choice)
		else:
			idle_event_elapsed += dt
			if idle_state == IdleState.SWAY:
				var duration := get_animation_duration("idle")
				var progress := clampf(idle_event_elapsed / duration, 0.0, 1.0)
				idle_phase = progress * TAU
				# A single gentle gesture, with zero movement at both ends.
				sway_target = sin(progress * PI)
	# Long resting idles only tick their gesture timer, without submitting unchanged uniforms.
	if (
		sway_target == 0.0
		and animation != &"walk"
		and idle_weight < 0.0001
		and walk_weight < 0.0001
	):
		if not motion_sleeping:
			idle_weight = 0.0
			walk_weight = 0.0
			var resting_material := material as ShaderMaterial
			if resting_material != null:
				resting_material.set_shader_parameter("idle_weight", 0.0)
				resting_material.set_shader_parameter("walk_weight", 0.0)
			motion_sleeping = true
		return
	motion_sleeping = false
	var blend := 1.0 - exp(-dt * 14.0)
	idle_weight = lerpf(idle_weight, sway_target, blend)
	var walk_target := 1.0 if animation == &"walk" and walk_shoulders_enabled else 0.0
	walk_weight = lerpf(walk_weight, walk_target, blend)
	var motion_material := material as ShaderMaterial
	if motion_material == null:
		return
	motion_material.set_shader_parameter("idle_weight", idle_weight)
	motion_material.set_shader_parameter("idle_phase", idle_phase)
	motion_material.set_shader_parameter("idle_sway_amplitude", idle_sway_amplitude)
	motion_material.set_shader_parameter("walk_weight", walk_weight)
	motion_material.set_shader_parameter("shoulder_swing", shoulder_swing)
	motion_material.set_shader_parameter("shoulder_roll", shoulder_roll)
	if animation == &"walk":
		# Derive phase from the actual frame, so the shoulders follow the steps.
		var count := maxi(1, sprite_frames.get_frame_count("walk"))
		var phase := (float(frame) + frame_progress) / float(count) * TAU
		motion_material.set_shader_parameter("walk_phase", phase)


func show_animation(anim: String) -> void:
	if animation == StringName(anim) and is_playing() and anim == "walk":
		return
	if not sprite_frames.has_animation(anim):
		return
	if anim == "idle":
		_enter_rest()
	elif anim == "idle_blink":
		_start_idle_variation(IdleState.BLINK)
	else:
		idle_state = IdleState.REST
		idle_event_elapsed = 0.0
		play(anim)


func get_animation_duration(anim: String) -> float:
	var fps := sprite_frames.get_animation_speed(anim)
	if fps <= 0.0:
		return INF
	var duration := 0.0
	for index in sprite_frames.get_frame_count(anim):
		duration += sprite_frames.get_frame_duration(anim, index) / fps
	return duration


func seek_animation(anim: String, elapsed: float) -> void:
	# The arena owns attack time: visual frames, hit and recovery share one clock.
	if not sprite_frames.has_animation(anim):
		return
	if animation != StringName(anim):
		show_animation(anim)
	pause()
	var fps := sprite_frames.get_animation_speed(anim)
	var count := sprite_frames.get_frame_count(anim)
	var remaining := maxf(0.0, elapsed) * fps
	for index in count:
		var duration := sprite_frames.get_frame_duration(anim, index)
		if remaining < duration or index == count - 1:
			set_frame_and_progress(index, clampf(remaining / duration, 0, 0.999))
			return
		remaining -= duration

func sync_alpha() -> void:
	if sprite_frames==null or not sprite_frames.has_animation(animation):return
	var texture: Texture2D=sprite_frames.get_frame_texture(animation,frame)
	if not texture is MeshTexture:return
	# MeshTexture's padded logical canvas is larger than its real silhouette.
	# Supply the actual local drawing bounds for canvas clipping on resized views.
	var volume: AABB=texture.mesh.get_aabb()
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(),true,Rect2(Vector2(volume.position.x,volume.position.y)+offset,Vector2(volume.size.x,volume.size.y)).grow(24))
	var path: String=texture.base_texture.resource_path
	var shader_material:=material as ShaderMaterial
	if shader_material==null:return
	var alpha_path:=path.get_basename()+"_alpha.png"
	var enabled:=path.ends_with(".jpg") and ResourceLoader.exists(alpha_path)
	shader_material.set_shader_parameter("use_alpha_mask",enabled)
	shader_material.set_shader_parameter("frame_anchor",Vector2(1400,1400) if enabled else Vector2(360,580))
	if enabled:shader_material.set_shader_parameter("alpha_mask",load(alpha_path))
