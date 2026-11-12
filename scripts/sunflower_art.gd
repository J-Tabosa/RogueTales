extends RefCounted
const ROOT := "res://assets/enemies/sunflowers/"
const CELL := 416
const ANCHOR := Vector2(207, 329)
const SPAN := 274.0
const WIND := preload(ROOT + "wind.webp")
const IMPACT := preload(ROOT + "impact.webp")
const STINGER := preload(ROOT + "stinger.webp")
## Idle count, attack count, contact frame (zero-based), projectile release frame.
const MOTION := {
	"worker": [4, 7, 5, 3],
	"drone": [4, 6, 3, -1],
	"wasp": [4, 7, 4, 2],
	"queen": [4, 6, 4, 2]
}
static var cache: Dictionary = {}
static var bounds_cache: Dictionary = {}

static func frames(id: String) -> SpriteFrames:
	var key := id.trim_prefix("sunflower_")
	if cache.has(key): return cache[key]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	var spec: Array = MOTION[key]
	var prefix := "boss_" if key == "queen" else ""
	add_animation(result, prefix + "idle", key + "_idle", int(spec[0]), 4.0, true)
	add_animation(result, prefix + "attack", key + "_attack", int(spec[1]), 7.0, false)
	if key == "queen": add_animation(result, "summon", "queen_summon", 6, 6.0, false)
	cache[key] = result
	return result

static func idle_bounds(id: String, boss: bool) -> Rect2:
	if not bounds_cache.has(id):
		var texture := frames(id).get_frame_texture("boss_idle" if boss else "idle", 0)
		bounds_cache[id] = Rect2(texture.get_image().get_used_rect())
	return bounds_cache[id]


static func add_animation(frames: SpriteFrames, name: String, file: String, count: int, fps: float, looped: bool) -> void:
	var atlas: Texture2D = load(ROOT + file + ".webp")
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looped)
	for i in count:
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2(i % 4, floori(i / 4.0)) * CELL, Vector2.ONE * CELL)
		texture.filter_clip = true
		frames.add_frame(name, texture)

static func timing(id: String, summoning: bool) -> Dictionary:
	if summoning: return {"animation": "summon", "contact": .5}
	var key := id.trim_prefix("sunflower_")
	var spec: Array = MOTION[key]
	return {
		"animation": "boss_attack" if key == "queen" else "attack",
		"contact": float(spec[2]) / float(spec[1]),
		"release": float(spec[3]) / float(spec[1]),
		"recovery": float(spec[2] + 1) / float(spec[1]),
		"approach": .72 if key == "wasp" else .94
	}

static func stamp(canvas: Node2D, texture: Texture2D, at: Vector2, width: float, rotation := 0.0, opacity := 1.0) -> void:
	var extent := texture.get_size() * width / texture.get_width()
	canvas.draw_set_transform(at, rotation)
	canvas.draw_texture_rect(texture, Rect2(-extent * .5, extent), false, Color(1, 1, 1, opacity))
	canvas.draw_set_transform(Vector2.ZERO)
