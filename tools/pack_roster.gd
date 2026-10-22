extends SceneTree
## Native Godot asset preparation. Source images remain unchanged.
func _initialize() -> void:
	var sheets: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	for sheet in sheets:
		var source := Image.load_from_file(sheet.source)
		source.convert(Image.FORMAT_RGBA8)
		var pixels := source.get_data()
		var ownership := FileAccess.get_file_as_bytes(sheet.mask)
		var atlas := Image.create(int(sheet.columns) * 360, 4 * 320, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var number := 0
		for frame in sheet.frames:
			number += 1
			var bounds: Array = frame.bounds
			var w := int(bounds[2])
			var h := int(bounds[3])
			var raw := PackedByteArray()
			raw.resize(w * h * 4)
			raw.fill(0)
			for y in h:
				for x in w:
					var at := (y + int(bounds[1])) * source.get_width() + x + int(bounds[0])
					if ownership[at] != number:
						continue
					var target := (y * w + x) * 4
					for channel in 4:
						raw[target + channel] = pixels[at * 4 + channel]
			var image := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, raw)
			# All frames share a 360 x 320 canvas with feet at (180, 290).
			# Use each animation's median body height, not per-pose height, to retain crouches.
			var heights: Array = []
			for other in sheet.frames:
				if sheet.kind == "walk" or int(other.row) == 0:
					heights.append(float(other.bounds[3]))
			heights.sort()
			var density: float = 210.0 / float(heights[heights.size() / 2])
			var widest := 0.0
			for other in sheet.frames:
				widest = maxf(widest, float(other.bounds[2]))
			density = minf(density, 338.0 / widest)
			image.resize(maxi(1, roundi(w * density)), maxi(1, roundi(h * density)), Image.INTERPOLATE_LANCZOS)
			var at := Vector2i(int(frame.col) * 360 + 180 - image.get_width() / 2, int(frame.row) * 320 + 290 - image.get_height())
			atlas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
		var path := "res://assets/%s/%s_atlas.png" % [sheet.hero, sheet.kind]
		assert(atlas.save_png(path) == OK)
		print("PACKED ", path, " ", sheet.frames.size(), " isolated source poses")
	quit()
