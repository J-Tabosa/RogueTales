extends RefCounted
static var cache := {}
static func frame(biome: int, progress: float) -> Texture2D:
	var pose := clampi(int(progress * 4), 0, 3)
	var key := "%d:%d" % [biome, pose]
	if not cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/effects/enemy_impacts.webp")
		var cell := atlas.atlas.get_size() / Vector2(4, 8)
		atlas.region = Rect2(Vector2(pose, biome) * cell, cell)
		atlas.filter_clip = true
		cache[key] = atlas
	return cache[key]
