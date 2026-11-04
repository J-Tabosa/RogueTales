extends SceneTree
## Register the imagegen-cleaned atlas without recoloring or editing its pixels.
## Crop eight equal cells and pad to the existing 768px runtime canvases.
func _initialize() -> void:
	var atlas:=Image.load_from_file("res://tools/art_sources/phase1/lumberjack_clean.png")
	for n in 8:
		var left:=roundi((n%4)*atlas.get_width()/4.0)
		var right:=roundi(((n%4)+1)*atlas.get_width()/4.0)
		var top:=roundi((n/4)*atlas.get_height()/2.0)
		var bottom:=roundi(((n/4)+1)*atlas.get_height()/2.0)
		var frame:=atlas.get_region(Rect2i(left,top,right-left,bottom-top))
		var used:=preload("res://scripts/phase1_enemies.gd").visual_bounds(frame)
		var canvas:=Image.create(768,768,false,Image.FORMAT_RGBA8)
		var offset:=Vector2i(384-frame.get_width()/2,640-used.end.y)
		canvas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),offset)
		assert(preload("res://scripts/phase1_enemies.gd").visual_bounds(canvas).end.y==640)
		canvas.save_png("res://assets/enemies/phase1/autumn_lumberjack/attack/%02d.png"%(n+1))
	quit()
