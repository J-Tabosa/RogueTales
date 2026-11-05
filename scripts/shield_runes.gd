extends RefCounted
## Live vector sprites: no timer, tween, node or texture allocated per frame.
## Animation follows the arena clock, so pause and reduced motion are deterministic.
static func facet_points(feet: Vector2, height: float, clock: float, reduced: bool, side: int, index: int) -> PackedVector2Array:
	var h := maxf(12,height)
	var phase := 0.0 if reduced else clock*.85+float(index)*1.7+float(side)*.65
	var bob := 0.0 if reduced else sin(phase)*h*.028
	var spread := .31+float(index)*.052
	var at := feet+Vector2(float(side)*h*spread,-h*(.72-float(index)*.23)+bob)
	var lean := float(side)*h*.022*(0.0 if reduced else sin(phase*.7))
	var width := h*(.052 if index==0 else .035)
	var length := h*(.24 if index==0 else .14)
	return PackedVector2Array([at+Vector2(lean,-length*.6),at+Vector2(width,length*.03),at+Vector2(-lean,length*.6),at+Vector2(-width,-length*.06),at+Vector2(lean,-length*.6)])

static func rune_segments(at: Vector2, height: float, variant: int) -> PackedVector2Array:
	var h := height
	var points := PackedVector2Array([at+Vector2(0,-h),at+Vector2(0,h)])
	match variant%3:
		0:
			points.append_array(PackedVector2Array([at+Vector2(0,-h*.7),at+Vector2(h*.62,-h*.2),at+Vector2(0,h*.15),at+Vector2(h*.62,h*.8)]))
		1:
			points.append_array(PackedVector2Array([at+Vector2(0,-h*.6),at+Vector2(h*.6,0),at+Vector2(h*.6,0),at+Vector2(0,h*.6)]))
		_:
			points.append_array(PackedVector2Array([at+Vector2(-h*.55,-h*.35),at+Vector2(h*.55,h*.1),at+Vector2(-h*.55,h*.3),at+Vector2(h*.55,h*.75)]))
	return points

static func draw(canvas: Node2D, feet: Vector2, height: float, clock: float, reduced: bool, quality := true) -> void:
	var h := maxf(12,height)
	var tint := TaleTheme.c("shield")
	var light := tint.lerp(Color.WHITE,.55)
	for side in [-1,1]:
		for index in (3 if quality else 2):
			var points := facet_points(feet,h,clock,reduced,side,index)
			canvas.draw_colored_polygon(points.slice(0,4),Color(tint,.08))
			if quality: canvas.draw_polyline(points,Color(tint,.10),maxf(2,h*.027),true)
			canvas.draw_polyline(points,Color(light,.70),maxf(.8,h*.009),true)
			if index==0:
				var at := (points[0]+points[2])*.5
				# Glyphs drift independently within the shield facets.
				if not reduced: at += Vector2(sin(clock*.7+side),cos(clock*1.1+side))*h*.012
				var strokes := rune_segments(at,h*.052,0 if side<0 else 1)
				for n in range(0,strokes.size(),2):
					canvas.draw_line(strokes[n],strokes[n+1],Color(light,.88),maxf(.8,h*.008),true)
		var phase := 0.0 if reduced else clock*.75+float(side)
		var mote := feet+Vector2(float(side)*h*.27,-h*(.94+(.025*sin(phase) if not reduced else 0.0)))
		var r := h*.025
		canvas.draw_polyline(PackedVector2Array([mote+Vector2(0,-r),mote+Vector2(r*.6,0),mote+Vector2(0,r),mote-Vector2(r*.6,0),mote+Vector2(0,-r)]),Color(light,.75),1.0,true)
