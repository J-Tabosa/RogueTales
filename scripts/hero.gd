extends AnimatedSprite2D
## The scene owns the textures, frame order, scale and FPS.
## Edit Scarlet's SpriteFrames in the inspector; nothing rebuilds them at runtime.

@export var return_to_idle := true


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	if not is_playing():
		play(animation)


func _on_animation_finished() -> void:
	if animation == &"attack" and return_to_idle:
		play("idle")


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
