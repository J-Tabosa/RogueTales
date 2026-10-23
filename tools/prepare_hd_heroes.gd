extends SceneTree
var packed := {}
func _initialize() -> void:
	var sheets: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	for hero in ["alice", "rapunzel"]:
		var path := "res://assets/%s/%s" % [hero, "frames.tres" if hero == "alice" else "rapunzel_frames.tres"]
		var frames: SpriteFrames = load(path).duplicate(true)
		var idle: Texture2D = frames.get_frame_texture("idle", 0)
		var bounds: Rect2
		if idle is MeshTexture:
			var aabb: AABB = idle.mesh.get_aabb()
			bounds = Rect2(Vector2(aabb.position.x, aabb.position.y), Vector2(aabb.size.x, aabb.size.y))
		else: bounds = Rect2(idle.margin.position, idle.region.size)
		var baseline := Vector2(bounds.get_center().x, bounds.end.y)
		var density := 400.0 / bounds.size.y
		for animation in frames.get_animation_names():
			for index in frames.get_frame_count(animation):
				var old: Texture2D = frames.get_frame_texture(animation, index)
				if old is MeshTexture:
					var arrays: Array = old.mesh.surface_get_arrays(0)
					var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					for at in vertices.size():
						var point := Vector2(360, 580) + (Vector2(vertices[at].x, vertices[at].y) - baseline) * density
						vertices[at] = Vector3(point.x, point.y, 0)
					arrays[Mesh.ARRAY_VERTEX] = vertices
					var mesh := ArrayMesh.new()
					mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
					var texture := MeshTexture.new()
					texture.base_texture = old.base_texture
					texture.mesh = mesh
					texture.image_size = Vector2(1000, 600)
					frames.set_frame(animation, index, texture)
				else:
					var points := PackedVector2Array([Vector2.ZERO, Vector2(old.region.size.x, 0), old.region.size, Vector2(0, old.region.size.y)])
					frames.set_frame(animation, index, mesh_texture(old.atlas, [points], old.region.position, old.margin.position - baseline, density))
		for sheet in sheets:
			if sheet.hero != hero: continue
			var texture: Texture2D = load(sheet.source)
			var ownership := FileAccess.get_file_as_bytes(sheet.mask)
			var heights: Array = []
			for frame in sheet.frames: heights.append(float(frame.bounds[3]))
			heights.sort()
			var scale := 400.0 / float(heights[heights.size() / 2])
			var poses: Array[Texture2D] = []
			for index in sheet.frames.size():
				var b: Array = sheet.frames[index].bounds
				var bitmap := BitMap.new()
				bitmap.create(Vector2i(b[2], b[3]))
				for y in int(b[3]):
					for x in int(b[2]):
						if ownership[(y + int(b[1])) * int(texture.get_width()) + x + int(b[0])] == index + 1: bitmap.set_bit(x, y, true)
				var polygons := bitmap.opaque_to_polygons(Rect2i(0, 0, b[2], b[3]), 1.5)
				poses.append(mesh_texture(texture, polygons, Vector2(b[0], b[1]), Vector2(-float(b[2]) * 0.5, -float(b[3])), scale))
			var animation: String = sheet.kind
			var opening: Texture2D = frames.get_frame_texture("attack", 0)
			frames.clear(animation)
			if hero == "alice" and animation == "attack": frames.add_frame(animation, opening)
			for pose in poses: frames.add_frame(animation, pose)
		assert(ResourceSaver.save(frames, path) == OK)
		print("HD native mesh frames saved: ", hero)
	var impact := Image.load_from_file("res://assets/effects/enemy_impacts.png")
	if impact != null: impact.save_webp("res://assets/effects/enemy_impacts.webp", true, 0.96)
	quit()

func mesh_texture(source: Texture2D, polygons: Array, region: Vector2, origin: Vector2, density: float) -> MeshTexture:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for polygon in polygons:
		var triangles := Geometry2D.triangulate_polygon(polygon)
		if triangles.is_empty(): continue
		var first := vertices.size()
		for point in polygon:
			var at: Vector2 = Vector2(360, 580) + (point + origin) * density
			vertices.append(Vector3(at.x, at.y, 0))
			uvs.append((region + point) / source.get_size())
		for index in triangles: indices.append(first + index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var texture := MeshTexture.new()
	texture.mesh = mesh
	texture.base_texture = source
	texture.image_size = Vector2(1000, 600)
	return texture
