extends RefCounted
const CORNER=preload("res://assets/ui/themes/shared/frame_corner.svg")
const DIAMOND=preload("res://assets/ui/themes/shared/frame_diamond.svg")
## Resolution-independent engraved frames. Every portrait uses the same geometry.
static func contour(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	var c := minf(cut, minf(rect.size.x, rect.size.y) * .3)
	return PackedVector2Array([p+Vector2(c,0),Vector2(e.x-c,p.y),Vector2(e.x,p.y+c),e-Vector2(0,c),e-Vector2(c,0),Vector2(p.x+c,e.y),Vector2(p.x,e.y-c),p+Vector2(0,c),p+Vector2(c,0)])

static func diamond(canvas: CanvasItem, at: Vector2, radius: float, tint: Color) -> void:
	canvas.draw_texture_rect(DIAMOND,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false,tint)

static func frame(canvas: CanvasItem, extent: Vector2, role: String, owner: Control) -> void:
	if extent.x < 6 or extent.y < 6: return
	var full := Rect2(Vector2.ONE,extent-Vector2.ONE*2)
	var edge := TaleTheme.c("ornament",.85)
	var fine := TaleTheme.c("border",.65)
	var active: bool = owner is BaseButton and (owner.has_focus() or owner.is_hovered())
	if role == "info":
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(extent.x*.5,1),Vector2(extent.x-1,extent.y*.5),Vector2(extent.x*.5,extent.y-1),Vector2(1,extent.y*.5)]),TaleTheme.c("hover" if active else "surface"))
		diamond(canvas,extent*.5,minf(extent.x,extent.y)*.47,edge)
		return
	if role == "chapter":
		canvas.draw_colored_polygon(contour(full,9).slice(0,8),TaleTheme.c("surface"))
		canvas.draw_polyline(contour(full,9),edge,1.0,true)
		canvas.draw_polyline(contour(full.grow(-4),7),fine,1.0,true)
		for y in [7.0,extent.y-7]:
			canvas.draw_line(Vector2(18,y),Vector2(extent.x*.5-10,y),edge,1.0,true)
			canvas.draw_line(Vector2(extent.x*.5+10,y),Vector2(extent.x-18,y),edge,1.0,true)
			diamond(canvas,Vector2(extent.x*.5,y),4,edge)
		canvas.draw_line(Vector2(87,118),Vector2(87,156),fine,1.0,true)
		return
	if role == "bar":
		# ProgressBar keeps the real semantic fill; only its engraved silhouette changes.
		var mask := TaleTheme.c("combat_surface" if owner.get_parent().get_meta("combat_readout",false) else "surface")
		var cut:=minf(10,extent.y*.3)
		for flip_x in [false,true]:
			for flip_y in [false,true]:
				var at := Vector2(extent.x if flip_x else 0,extent.y if flip_y else 0)
				var direction := Vector2(-1 if flip_x else 1,-1 if flip_y else 1)
				canvas.draw_colored_polygon(PackedVector2Array([at,at+direction*Vector2(cut,0),at+direction*Vector2(0,cut)]),mask)
		canvas.draw_polyline(contour(full,cut),edge,1.0,true)
		return
	if role == "button":
		var state:="well" if owner is BaseButton and owner.disabled else "pressed" if owner is BaseButton and owner.is_pressed() else "hover" if active else "surface"
		canvas.draw_colored_polygon(contour(full,10).slice(0,8),TaleTheme.c(state))
		var texture:=TaleTheme.asset("surface_texture")
		if texture!=null:canvas.draw_texture_rect(texture,full.grow(-9),false,TaleTheme.asset_tint("surface_texture",.045))
	if role != "portrait" and role != "arena" and role != "button" and not owner is BaseButton:
		canvas.draw_colored_polygon(contour(full,6).slice(0,8),TaleTheme.c("combat_surface" if role=="plate" else "hover" if active else "surface",.96))
	canvas.draw_polyline(contour(full,10 if role=="button" else 6),edge,1.0,true)
	if minf(extent.x,extent.y) > 20:
		canvas.draw_polyline(contour(full.grow(-4),7 if role=="button" else 4),fine,1.0,true)
	if role=="button" and owner.has_meta("auto_indicator"):
		var on:bool=owner.get_meta("auto_indicator")
		var box:=Rect2(extent.x-29,extent.y*.5-7,14,14)
		canvas.draw_rect(box,TaleTheme.c("bar_health" if on else "well"))
		canvas.draw_rect(box,edge,false,1)
	if role in ["portrait","modal"]:
		for flip_x in [false,true]:
			for flip_y in [false,true]:
				var at := Vector2(extent.x-2 if flip_x else 2,extent.y-2 if flip_y else 2)
				var direction := Vector2(-1 if flip_x else 1,-1 if flip_y else 1)
				var extent_corner:=12.0 if role=="modal" else 16.0
				canvas.draw_set_transform(at,0,direction)
				canvas.draw_texture_rect(CORNER,Rect2(Vector2.ONE,Vector2.ONE*extent_corner),false,edge)
				canvas.draw_set_transform(Vector2.ZERO)
	elif role == "header":
		diamond(canvas,Vector2(extent.x*.5,3),3.0,edge)

static func leaf(canvas: CanvasItem, at: Vector2, angle: float, scale: float, tint: Color) -> void:
	var stem := Vector2.from_angle(angle) * scale
	var side := stem.orthogonal() * .35
	var tip := at+stem
	canvas.draw_polyline(PackedVector2Array([at,at+stem*.38+side,tip,at+stem*.55-side,at]),tint,1.0,true)
	canvas.draw_line(at,tip,tint,1.0,true)
