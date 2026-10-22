extends Control
## Small vector UI icons, independent of device font glyph coverage.
var glyph := "home"
var tint := Color("e5c990")
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / 24.0)
	match glyph:
		"home":
			draw_polyline(PackedVector2Array([Vector2(3,11),Vector2(12,3),Vector2(21,11)]),tint,2,true)
			draw_polyline(PackedVector2Array([Vector2(5,10),Vector2(5,21),Vector2(19,21),Vector2(19,10)]),tint,2,true)
			draw_rect(Rect2(10,14,4,7),tint,false,1.5)
		"map":
			draw_polyline(PackedVector2Array([Vector2(4,20),Vector2(8,12),Vector2(16,14),Vector2(20,4)]),tint,2,true)
			for at in [Vector2(4,20),Vector2(8,12),Vector2(16,14),Vector2(20,4)]: draw_circle(at,2.5,tint)
		"heroes":
			draw_circle(Vector2(9,7),4,tint,false,1.8,true)
			draw_arc(Vector2(9,21),7,PI,TAU,16,tint,1.8,true)
			draw_arc(Vector2(17,7),3,-PI/2,PI/2,12,tint,1.8,true)
			draw_arc(Vector2(16,21),6,PI*1.45,TAU,12,tint,1.8,true)
		"book":
			draw_polyline(PackedVector2Array([Vector2(12,6),Vector2(4,4),Vector2(4,19),Vector2(12,21),Vector2(20,19),Vector2(20,4),Vector2(12,6),Vector2(12,21)]),tint,1.8,true)
		"profile":
			draw_circle(Vector2(12,7),4,tint,false,1.8,true)
			draw_arc(Vector2(12,22),9,PI,TAU,20,tint,1.8,true)
		"settings":
			draw_circle(Vector2(12,12),6,tint,false,2,true)
			draw_circle(Vector2(12,12),2,tint,false,1.7,true)
			for i in 8:
				var d:=Vector2.from_angle(i*TAU/8)
				draw_line(Vector2(12,12)+d*7,Vector2(12,12)+d*10,tint,2,true)
		"sword":
			draw_polyline(PackedVector2Array([Vector2(6,18),Vector2(16,4),Vector2(21,3),Vector2(20,8),Vector2(9,20)]),tint,2,true)
			draw_line(Vector2(3,14),Vector2(12,22),tint,2,true)
			draw_line(Vector2(2,22),Vector2(7,17),tint,3,true)
		"chest":
			draw_rect(Rect2(3,8,18,13),tint,false,2)
			draw_arc(Vector2(12,9),9,PI,TAU,16,tint,2,true)
			draw_line(Vector2(3,13),Vector2(21,13),tint,2)
			draw_rect(Rect2(10,11,4,5),tint)
		"shield":
			draw_polyline(PackedVector2Array([Vector2(12,2),Vector2(21,6),Vector2(19,16),Vector2(12,22),Vector2(5,16),Vector2(3,6),Vector2(12,2)]),tint,2,true)
		"magic", "mirror":
			draw_polyline(PackedVector2Array([Vector2(12,2),Vector2(20,12),Vector2(12,22),Vector2(4,12),Vector2(12,2)]),tint,2,true)
			draw_line(Vector2(7,17),Vector2(17,7),tint,1.5,true)
		"warning":
			draw_polyline(PackedVector2Array([Vector2(12,2),Vector2(22,21),Vector2(2,21),Vector2(12,2)]),tint,2,true)
			draw_line(Vector2(12,8),Vector2(12,14),tint,2,true)
			draw_circle(Vector2(12,18),1,tint)
		"bind":
			draw_arc(Vector2(8,12),5,-PI,PI*0.6,18,tint,2,true)
			draw_arc(Vector2(16,12),5,0,PI*1.6,18,tint,2,true)
		_:
			draw_circle(Vector2(12,12),8,tint,false,2,true)
