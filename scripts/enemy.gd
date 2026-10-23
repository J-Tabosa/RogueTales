extends AnimatedSprite2D
## Editable per-chapter scenes. Arena owns the clock, so pause and 2x stay in sync.
static var scene_cache: Dictionary = {}
const SCENES = [
	"res://scenes/enemies/chapter_01.tscn",
	"res://scenes/enemies/chapter_02.tscn",
	"res://scenes/enemies/chapter_03.tscn",
	"res://scenes/enemies/chapter_04.tscn",
	"res://scenes/enemies/chapter_05.tscn",
	"res://scenes/enemies/chapter_06.tscn",
	"res://scenes/enemies/chapter_07.tscn",
	"res://scenes/enemies/chapter_08.tscn"
]
@export var regular_height := 200.0
@export var boss_height := 255.0
var idle_clock := 0.0
var hurt_left := 0.0
var dot_cooldown := 0.0
var strike_left := 0.0
var illustrated := false
var body_height := 210.0


static func warm(chapter: int) -> PackedScene:
	chapter = [0, 1, 2, 3, 4, 5, 6, 7, 2, 1, 4, 7][clampi(chapter, 0, TaleCatalog.FINAL_CHAPTER)]
	if not scene_cache.has(chapter):
		if scene_cache.size() >= 2:
			scene_cache.erase(scene_cache.keys()[0])
		scene_cache[chapter] = load(SCENES[chapter])
	return scene_cache[chapter]


func _ready() -> void:
	pause()
	centered = false
	z_index = 296
	position = Vector2(402, 296)


func hurt(continuous := false) -> void:
	if continuous and dot_cooldown > 0:
		return
	hurt_left = 0.24
	dot_cooldown = 0.6
	modulate = Color("ff4545")


func reset_damage() -> void:
	hurt_left = 0.0
	dot_cooldown = 0.0
	strike_left = 0.0
	modulate = Color.WHITE


func advance(dt: float, is_boss: bool, windup: float, interval: float) -> void:
	idle_clock += dt
	hurt_left = maxf(0, hurt_left - dt)
	dot_cooldown = maxf(0, dot_cooldown - dt)
	modulate = hurt_color(hurt_left)
	var prefix := "boss_" if is_boss else ""
	var strike := prefix + "attack"
	var fps := maxf(0.1, sprite_frames.get_animation_speed(strike))
	var anticipation := (
		(sprite_frames.get_frame_duration(strike, 0) + sprite_frames.get_frame_duration(strike, 1))
		/ fps
	)
	var recovery := animation_duration(strike) - anticipation
	var start := 1.0 - minf(0.85, anticipation / maxf(interval, 0.1))
	if strike_left > 0:
		seek(strike, anticipation + recovery - strike_left)
		strike_left = maxf(0, strike_left - dt)
	elif visible and windup >= start:
		seek(strike, clampf((windup - start) / (1.0 - start), 0, 0.999) * anticipation)
	else:
		seek(prefix + "idle", idle_clock)
	var canvas := sprite_frames.get_frame_texture(animation, frame).get_size()
	offset = Vector2(-160, -304) if illustrated else Vector2(-canvas.x * 0.5, -canvas.y)
	scale = Vector2.ONE * ((boss_height if is_boss else regular_height) / (body_height if illustrated else canvas.y))


func begin_strike(is_boss: bool) -> void:
	var id := "boss_attack" if is_boss else "attack"
	var fps := maxf(0.1, sprite_frames.get_animation_speed(id))
	var anticipation := (
		(sprite_frames.get_frame_duration(id, 0) + sprite_frames.get_frame_duration(id, 1)) / fps
	)
	strike_left = maxf(0, animation_duration(id) - anticipation)
	seek(id, anticipation)


static func hurt_color(left: float) -> Color:
	return Color("ff4545") if left > 0 and fmod(0.24 - left, 0.12) < 0.085 else Color.WHITE


func animation_duration(id: String) -> float:
	var total := 0.0
	for index in sprite_frames.get_frame_count(id):
		total += sprite_frames.get_frame_duration(id, index)
	return total / maxf(0.1, sprite_frames.get_animation_speed(id))


func seek(id: String, seconds: float) -> void:
	var fps := maxf(0.1, sprite_frames.get_animation_speed(id))
	var remaining := fposmod(seconds, animation_duration(id)) * fps
	animation = id
	for index in sprite_frames.get_frame_count(id):
		var duration := sprite_frames.get_frame_duration(id, index)
		if remaining < duration:
			set_frame_and_progress(index, remaining / duration)
			return
		remaining -= duration
