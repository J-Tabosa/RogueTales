extends SceneTree
## Reproducible native Godot packing; source alpha is retained, never color-keyed.
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	DirAccess.make_dir_recursive_absolute("res://assets/biomes")
	DirAccess.make_dir_recursive_absolute("res://assets/effects")
	for key in manifest:
		var entry: Variant = manifest[key]
		var source := Image.load_from_file(str(entry.source) if entry is Dictionary else str(entry))
		assert(source != null)
		source.convert(Image.FORMAT_RGBA8)
		if str(key).begins_with("enemies_"):
			var atlas := Image.create(1280, 1920, false, Image.FORMAT_RGBA8)
			atlas.fill(Color.TRANSPARENT)
			var source_bytes := source.get_data()
			var ownership := FileAccess.get_file_as_bytes(entry.mask)
			var poses: Array[Image] = []
			for row in 6:
				poses.clear()
				var widest := 1.0
				var tallest := 1.0
				var idle_height := 1.0
				for col in 4:
					var info: Dictionary = entry.frames[row * 4 + col]
					var bounds: Array = info.bounds
					var w := int(bounds[2])
					var h := int(bounds[3])
					var raw := PackedByteArray()
					raw.resize(w * h * 4)
					raw.fill(0)
					for y in h:
						for x in w:
							var pixel := (y + int(bounds[1])) * source.get_width() + x + int(bounds[0])
							if ownership[pixel] != row * 4 + col + 1: continue
							for channel in 4: raw[(y * w + x) * 4 + channel] = source_bytes[pixel * 4 + channel]
					var pose := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, raw)
					clean_alpha(pose)
					if col == 0: idle_height = pose.get_height()
					widest = maxf(widest, pose.get_width())
					tallest = maxf(tallest, pose.get_height())
					poses.append(pose)
				var density := minf(minf(210.0 / idle_height, 304.0 / widest), 300.0 / tallest)
				for col in 4:
					var pose: Image = poses[col]
					pose.resize(maxi(1, roundi(pose.get_width() * density)), maxi(1, roundi(pose.get_height() * density)), Image.INTERPOLATE_LANCZOS)
					var at := Vector2i(col * 320 + 160 - pose.get_width() / 2, row * 320 + 304 - pose.get_height())
					atlas.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), at)
			assert(atlas.save_webp("res://assets/biomes/%s.webp" % key, true, 0.94) == OK)
		elif key == "biome_scenery":
			assert(source.save_webp("res://assets/biomes/scenery.webp", true, 0.94) == OK)
		else:
			clean_alpha(source)
			assert(source.save_webp("res://assets/effects/%s.webp" % key, true, 0.96) == OK)
		print("PACKED ", key)
	quit()

func clean_alpha(image: Image) -> void:
	var bytes := image.get_data()
	for index in range(3, bytes.size(), 4):
		if bytes[index] < 8: bytes[index] = 0
		elif bytes[index] > 247: bytes[index] = 255
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, bytes)
