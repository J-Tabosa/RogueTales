extends AnimatedSprite2D
## The scene owns textures, frame order, scale and FPS.
## Idle holds frame 0, then occasionally plays a blink or a short sway once.

enum IdleState { REST, BLINK, SWAY }
enum AttackStyle { BOMB, HAIR }

@export_group("Heroína")
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
var idle_rng := RandomNumberGenerator.new()


func _ready() -> void:
	idle_rng.randomize()
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
