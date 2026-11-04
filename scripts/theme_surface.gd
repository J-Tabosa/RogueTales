extends Control
## Transparent, replaceable ornaments. This node never participates in input/layout.
var frame_only := false
var backdrop := false
var wash: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("theme_decoration", true)
	resized.connect(queue_redraw)
	update_theme()

func update_theme() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([TaleTheme.c("background").lerp(TaleTheme.c("surface_top"), .25) if backdrop else TaleTheme.c("surface_top"), TaleTheme.c("background" if backdrop else "surface")])
	wash = GradientTexture2D.new()
	wash.gradient = gradient
	wash.width = 16
	wash.height = 128
	wash.fill_from = Vector2.ZERO
	wash.fill_to = Vector2(1, 1)
	queue_redraw()

func _draw() -> void:
	if size.x < 4 or size.y < 4: return
	var full := Rect2(Vector2.ZERO, size)
	if not frame_only and wash != null:
		draw_texture_rect(wash, full, false)
		var grain := TaleTheme.asset("surface_texture")
		if grain != null: draw_texture_rect(grain, full, true, TaleTheme.c("ornament", .035))
		if size.y >= 140 and size.x >= 160:
			var rosette := TaleTheme.asset("mandala_watermark")
			var extent := minf(size.x * .82, size.y * .92)
			if rosette != null: draw_texture_rect(rosette, Rect2(size * .5 - Vector2.ONE * extent * .5, Vector2.ONE * extent), false, TaleTheme.c("ornament", .045 if backdrop else .035))
	if backdrop: return
	if not frame_only:
		draw_rect(full.grow(-1), TaleTheme.c("border"), false, 2)
		draw_rect(full.grow(-4), TaleTheme.c("ornament", .42), false, 1)
		draw_line(Vector2(7, 6), Vector2(size.x - 7, 6), TaleTheme.c("accent", .12), 1)
	var frame := TaleTheme.asset("button_frame" if get_parent() is Button else "panel_frame")
	if frame != null:
		# Draw a 9-slice with immutable 18 px corners; only edge strips stretch.
		var source := frame.get_size()
		var margin := minf(18, minf(size.x, size.y) * .25)
		var dx := [0.0, margin, size.x - margin, size.x]
		var dy := [0.0, margin, size.y - margin, size.y]
		var sx := [0.0, source.x * .1875, source.x * .8125, source.x]
		var sy := [0.0, source.y * .1875, source.y * .8125, source.y]
		for y in 3:
			for x in 3:
				if x == 1 and y == 1: continue
				draw_texture_rect_region(frame, Rect2(dx[x], dy[y], dx[x+1]-dx[x], dy[y+1]-dy[y]), Rect2(sx[x], sy[y], sx[x+1]-sx[x], sy[y+1]-sy[y]), TaleTheme.c("ornament", .65))
	if size.x >= 180 and size.y >= 100 and not get_parent() is PanelContainer:
		var corner := TaleTheme.asset("corner_filigrane")
		var d := minf(27, size.y * .15)
		if corner != null:
			for i in 4:
				var at := Vector2(6 if i % 2 == 0 else size.x-6, 6 if i < 2 else size.y-6)
				draw_set_transform(at, 0, Vector2(1 if i%2==0 else -1, 1 if i<2 else -1))
				draw_texture_rect(corner, Rect2(0, 0, d, d), false, TaleTheme.c("ornament", .48))
			draw_set_transform(Vector2.ZERO)
