extends Control
## Small vector UI icons, independent of device font glyph coverage.
var glyph := "home"
var tint := Color("e5c990")
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / 24.0)
	match glyph:
		"crown":
			draw_polyline(PackedVector2Array([Vector2(4,19),Vector2(2,7),Vector2(8,12),Vector2(12,3),Vector2(16,12),Vector2(22,7),Vector2(20,19),Vector2(4,19)]),tint,2,true)
			draw_line(Vector2(5,22),Vector2(19,22),tint,2,true)
		"up":
			draw_polyline(PackedVector2Array([Vector2(5,12),Vector2(12,4),Vector2(19,12)]),tint,2,true)
			draw_line(Vector2(12,4),Vector2(12,22),tint,3,true)
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
		"lock":
			draw_arc(Vector2(12,10),5,PI,TAU,20,tint,2,true)
			draw_style_box(lock_plate(),Rect2(4,10,16,12))
			draw_circle(Vector2(12,15),1.8,Color("101c18"))
			draw_line(Vector2(12,15),Vector2(12,19),Color("101c18"),2,true)
		"heart":
			draw_colored_polygon(PackedVector2Array([Vector2(12,21),Vector2(3,12),Vector2(2,8),Vector2(4,4),Vector2(8,3),Vector2(12,7),Vector2(16,3),Vector2(20,4),Vector2(22,8),Vector2(21,12)]),tint)
		"skull":
			draw_circle(Vector2(12,10),8,tint)
			draw_rect(Rect2(7,14,10,7),tint)
			for x in [8.5,15.5]:draw_circle(Vector2(x,10),2.4,Color("14291f"))
			for x in [9,12,15]:draw_line(Vector2(x,18),Vector2(x,22),Color("14291f"),1.2,true)
		"bomb":
			bomb(Vector2(10,15),7)
		"blast_pair":
			bomb(Vector2(6,16),4.5)
			bomb(Vector2(17,10),4.5)
		"potion", "poison":
			draw_polyline(PackedVector2Array([Vector2(8,3),Vector2(16,3),Vector2(15,9),Vector2(21,17),Vector2(19,21),Vector2(5,21),Vector2(3,17),Vector2(9,9),Vector2(8,3)]),tint,1.7,true)
			draw_line(Vector2(6,16),Vector2(18,16),tint,3,true)
			draw_circle(Vector2(11,12),1,tint)
		"clock":
			draw_circle(Vector2(12,12),9,tint,false,1.8,true)
			draw_polyline(PackedVector2Array([Vector2(12,5),Vector2(12,12),Vector2(17,15)]),tint,2,true)
		"target":
			for radius in [4,8]:draw_circle(Vector2(12,12),radius,tint,false,1.5,true)
			draw_line(Vector2(12,1),Vector2(12,6),tint,1.5,true)
			draw_line(Vector2(18,12),Vector2(23,12),tint,1.5,true)
		"flame":
			draw_colored_polygon(PackedVector2Array([Vector2(12,1),Vector2(19,10),Vector2(22,16),Vector2(19,21),Vector2(7,22),Vector2(2,16),Vector2(5,8),Vector2(9,13)]),tint)
			draw_colored_polygon(PackedVector2Array([Vector2(12,11),Vector2(16,18),Vector2(12,21),Vector2(8,18)]),Color("15271d"))
		_:
			draw_circle(Vector2(12,12),8,tint,false,2,true)

func bomb(center: Vector2, radius: float) -> void:
	draw_circle(center,radius,tint)
	draw_arc(center+Vector2(radius*.5,-radius*1.15),radius*.55,PI,TAU*1.1,12,tint,1.4,true)
	var spark:=center+Vector2(radius,-radius*1.5)
	draw_line(spark-Vector2(2,2),spark+Vector2(2,2),tint,1.4,true)
	draw_line(spark-Vector2(-2,2),spark+Vector2(-2,2),tint,1.4,true)

func lock_plate() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=tint
	style.set_corner_radius_all(2)
	return style
