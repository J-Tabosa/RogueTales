extends RefCounted
static var cache: Dictionary={}
static func frames(id: String) -> SpriteFrames:
	if cache.has(id): return cache[id]
	var data: Dictionary=preload("res://scripts/secret_encounters.gd").DATA[id]
	var result: SpriteFrames=load("res://assets/secrets/%s_%d.tres"%[data.group,data.row]).duplicate(true)
	for animation in result.get_animation_names():
		for at in result.get_frame_count(animation):
			var texture: MeshTexture=result.get_frame_texture(animation,at)
			texture.base_texture=preload("res://scripts/jpeg_alpha.gd").texture("res://assets/secrets/%s.jpg"%data.group)
	cache[id]=result
	return result
