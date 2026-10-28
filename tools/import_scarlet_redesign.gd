extends SceneTree
## Deterministic chroma/atlas import. Only Scarlet's supplied paintings are used.
const OUT := "res://assets/characters/scarlet/"
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 2, "Pass the inspected sheet manifest and output metadata")
	var sheets: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var hero := {}
	for sheet in sheets:
		var source := Image.load_from_file(sheet.source)
		assert(source != null)
		source.convert(Image.FORMAT_RGBA8)
		var ownership := FileAccess.get_file_as_bytes(sheet.mask)
		var atlas := Image.create(2048, 512 * int(sheet.rows), false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var meta := []
		for at in sheet.frames.size():
			var item: Dictionary = sheet.frames[at]
			var b: Array = item.bounds
			var crop := Image.create(int(b[2]), int(b[3]), false, Image.FORMAT_RGBA8)
			crop.fill(Color.TRANSPARENT)
			for y in crop.get_height():
				for x in crop.get_width():
					var point := Vector2i(int(b[0]) + x, int(b[1]) + y)
					if ownership[point.y * source.get_width() + point.x] != at + 1: continue
					var color := source.get_pixelv(point)
					# The costumes have no green: suppress chroma spill at AA edges.
					color.g = minf(color.g, maxf(color.r, color.b))
					crop.set_pixel(x, y, color)
			var scale_factor := float(sheet.scale)
			crop.resize(maxi(1, roundi(crop.get_width() * scale_factor)), maxi(1, roundi(crop.get_height() * scale_factor)), Image.INTERPOLATE_LANCZOS)
			var local := Vector2i(roundi(256 + (float(b[0]) - float(item.foot[0])) * scale_factor), roundi(480 + (float(b[1]) - float(item.foot[1])) * scale_factor))
			assert(Rect2i(2, 2, 508, 508).encloses(Rect2i(local, crop.get_size())), "Complete pose must fit the padded cell")
			var cell := Vector2i(at % 4, at / 4) * 512
			atlas.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), cell + local)
			var used := Rect2i(local, crop.get_size())
			meta.append({"region": [cell.x + used.position.x, cell.y + used.position.y, used.size.x, used.size.y], "local_bounds": [384 + used.position.x - 256, 608 + used.position.y - 480, used.size.x, used.size.y], "anchor": [256, 480], "scale": 1, "removed": []})
		assert(atlas.save_webp(OUT + str(sheet.kind) + ".webp", false) == OK)
		hero[sheet.kind] = meta
		print("SCARLET ", sheet.kind, ": ", meta.size(), " whole poses, constant scale ", sheet.scale)
	hero.pose_order = range(16)
	var metadata := FileAccess.open(args[1], FileAccess.WRITE)
	assert(metadata != null)
	metadata.store_string(JSON.stringify(hero, "  ", false) + "\n")
	metadata.close()
	var portrait := Image.load_from_file("res://tools/art_sources/scarlet_20261028/portrait.png")
	assert(portrait != null and portrait.get_height() >= 1400)
	assert(portrait.save_webp(OUT + "portrait.webp", false) == OK)
	quit()
