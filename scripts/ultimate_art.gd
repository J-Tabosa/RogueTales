extends RefCounted
## Hand-inked, image-generated six-frame sequences. Movement uses the actual hit targets.
const GROUPS := {
	"scarlet": ["fables", 0], "rapunzel": ["fables", 1], "snow_white": ["fables", 2], "mulan": ["fables", 3],
	"ariel": ["wonders", 0], "joao": ["wonders", 1], "maria": ["wonders", 2], "alice": ["wonders", 3],
	"puss": ["legends", 0], "matches": ["legends", 1], "peter": ["legends", 2], "aladin": ["legends", 3]
}
static var textures: Dictionary = {}
static var frames: Dictionary = {}

static func frame(id: String, progress: float) -> Texture2D:
	var data: Array = GROUPS[id]
	var key: String = data[0]
	if not textures.has(key): textures[key] = load("res://assets/effects/ult_%s.webp" % key)
	var number := clampi(int(progress * 6), 0, 5)
	var cache_key := "%s:%d" % [id, number]
	if not frames.has(cache_key):
		var source: Texture2D = textures[key]
		var cell := source.get_size() / Vector2(6, 4)
		var texture := AtlasTexture.new()
		texture.atlas = source
		texture.filter_clip = true
		texture.region = Rect2(Vector2(number, data[1]) * cell, cell)
		frames[cache_key] = texture
	return frames[cache_key]
