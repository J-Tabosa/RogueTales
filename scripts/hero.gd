extends AnimatedSprite2D
## The scene owns the textures, frame order, scale and FPS.
## Edit Scarlet's SpriteFrames in the inspector; nothing rebuilds them at runtime.

@export var return_to_idle := true
@export_group("Idle — movimento suave")
@export var smooth_idle := true
@export_range(1.5, 8.0, 0.1) var idle_cycle_seconds := 3.6
@export_range(0.0, 12.0, 0.5) var breath_amplitude := 4.0
@export_range(0.0, 20.0, 0.5) var cloth_amplitude := 8.0

var idle_phase := 0.0
var idle_weight := 0.0


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	if not is_playing():
		play(animation)


func _on_animation_finished() -> void:
	if animation == &"attack" and return_to_idle:
		play("idle")


func _process(delta: float) -> void:
	# Use the same clock as the sprite: pausing and 1×/2× also affect breathing.
	if speed_scale <= 0.0 or not is_playing():
		return
	var idle_material := material as ShaderMaterial
	if idle_material == null:
		return
	var dt := delta * speed_scale
	idle_phase = fmod(idle_phase + dt * TAU / idle_cycle_seconds, TAU)
	var target := 1.0 if smooth_idle and animation == &"idle" else 0.0
	idle_weight = lerpf(idle_weight, target, 1.0 - exp(-dt * 12.0))
	idle_material.set_shader_parameter("idle_weight", idle_weight)
	idle_material.set_shader_parameter("motion_phase", idle_phase)
	idle_material.set_shader_parameter("breath_amplitude", breath_amplitude)
	idle_material.set_shader_parameter("cloth_amplitude", cloth_amplitude)


func show_animation(anim: String) -> void:
	if sprite_frames.has_animation(anim):
		play(anim)


func get_animation_duration(anim: String) -> float:
	var fps := sprite_frames.get_animation_speed(anim)
	if fps <= 0.0:
		return INF
	var duration := 0.0
	for index in sprite_frames.get_frame_count(anim):
		duration += sprite_frames.get_frame_duration(anim, index) / fps
	return duration
