extends RefCounted
## Resolution-independent engraved frames. Every portrait uses the same geometry.
static func contour(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	var c := minf(cut, minf(rect.size.x, rect.size.y) * .3)
	return PackedVector2Array([p+Vector2(c,0),Vector2(e.x-c,p.y),Vector2(e.x,p.y+c),e-Vector2(0,c),e-Vector2(c,0),Vector2(p.x+c,e.y),Vector2(p.x,e.y-c),p+Vector2(0,c),p+Vector2(c,0)])

static func diamond(canvas: CanvasItem, at: Vector2, radius: float, tint: Color) -> void:
	canvas.draw_polyline(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius,0),at+Vector2(0,radius),at+Vector2(-radius,0),at+Vector2(0,-radius)]),tint,1.0,true)

static func frame(canvas: CanvasItem, extent: Vector2, role: String, owner: Control) -> void:
	if extent.x < 6 or extent.y < 6: return
	var full := Rect2(Vector2.ONE,extent-Vector2.ONE*2)
	var edge := TaleTheme.c("ornament",.85)
	var fine := TaleTheme.c("border",.65)
	var active: bool = owner is BaseButton and (owner.has_focus() or owner.is_hovered())
	if role == "chapter":
		canvas.draw_colored_polygon(contour(full,5).slice(0,8),TaleTheme.c("well",.72))
		canvas.draw_line(Vector2(8,extent.y-2),Vector2(extent.x-8,extent.y-2),fine,1.0,true)
		diamond(canvas,Vector2(extent.x*.5,extent.y-2),2.5,edge)
		if active:
			canvas.draw_polyline(contour(full.grow(-1),5),edge,1.0,true)
		return
	if role == "bar":
		# ProgressBar keeps the real semantic fill; only its engraved silhouette changes.
		var mask := TaleTheme.c("combat_surface")
		for flip_x in [false,true]:
			for flip_y in [false,true]:
				var at := Vector2(extent.x if flip_x else 0,extent.y if flip_y else 0)
				var direction := Vector2(-1 if flip_x else 1,-1 if flip_y else 1)
				canvas.draw_colored_polygon(PackedVector2Array([at,at+direction*Vector2(4,0),at+direction*Vector2(0,4)]),mask)
		canvas.draw_polyline(contour(full,4),edge,1.0,true)
		return
	if role != "portrait" and role != "arena":
		canvas.draw_colored_polygon(contour(full,6).slice(0,8),TaleTheme.c("combat_surface" if role=="plate" else "hover" if active else "surface",.96))
	canvas.draw_polyline(contour(full,6),edge,1.0,true)
	if minf(extent.x,extent.y) > 20:
		canvas.draw_polyline(contour(full.grow(-3),4),fine,1.0,true)
	if role == "portrait":
		for flip_x in [false,true]:
			for flip_y in [false,true]:
				var at := Vector2(extent.x-2 if flip_x else 2,extent.y-2 if flip_y else 2)
				var direction := Vector2(-1 if flip_x else 1,-1 if flip_y else 1)
				canvas.draw_polyline(PackedVector2Array([at+direction*Vector2(0,13),at+direction*Vector2(4,9),at+direction*Vector2(9,4),at+direction*Vector2(13,0)]),edge,1.0,true)
	elif role == "header":
		diamond(canvas,Vector2(extent.x*.5,3),3.0,edge)

static func leaf(canvas: CanvasItem, at: Vector2, angle: float, scale: float, tint: Color) -> void:
	var stem := Vector2.from_angle(angle) * scale
	var side := stem.orthogonal() * .35
	var tip := at+stem
	canvas.draw_polyline(PackedVector2Array([at,at+stem*.38+side,tip,at+stem*.55-side,at]),tint,1.0,true)
	canvas.draw_line(at,tip,tint,1.0,true)

static func folio(canvas: CanvasItem, extent: Vector2) -> void:
	if extent.x < 300 or extent.y < 200: return
	var edge := TaleTheme.c("ornament",.62)
	var fine := TaleTheme.c("border",.5)
	var margin := 9.0
	var bottom := extent.y-38.0
	for x in [margin,extent.x-margin]:
		canvas.draw_line(Vector2(x,48),Vector2(x,bottom-34),fine,1.0,true)
		canvas.draw_line(Vector2(x+3 if x<extent.x*.5 else x-3,56),Vector2(x+3 if x<extent.x*.5 else x-3,bottom-42),edge,.7,true)
	canvas.draw_line(Vector2(45,bottom),Vector2(extent.x-45,bottom),fine,1.0,true)
	diamond(canvas,Vector2(extent.x*.5,bottom),4.0,edge)
	for right in [false,true]:
		for lower in [false,true]:
			var origin := Vector2(extent.x-margin if right else margin,bottom if lower else margin)
			var direction := Vector2(-1 if right else 1,-1 if lower else 1)
			var vine := PackedVector2Array()
			for i in 17:
				var t := float(i)/16
				vine.append(origin+direction*Vector2(4+38*t,4+12*sin(t*PI*.5)))
			canvas.draw_polyline(vine,edge,1.0,true)
			for i in [3,7,11]:
				var at := vine[i]
				var angle := Vector2(direction.x,direction.y*(-.8 if i%2 else .8)).angle()
				leaf(canvas,at,angle,7,edge)
			var bloom := origin+direction*Vector2(10,23)
			for petal in 5:
				leaf(canvas,bloom,petal*TAU/5,5,edge)
			canvas.draw_circle(bloom,1.3,edge,true,-1,true)
