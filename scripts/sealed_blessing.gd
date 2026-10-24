extends Control
## An opaque seal, rather than a cosmetic overlay on readable locked effects.
func _draw() -> void:
	var plate:=StyleBoxFlat.new()
	plate.bg_color=Color("080f10")
	plate.border_color=Color("4f5143")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(10)
	draw_style_box(plate,Rect2(Vector2.ZERO,size))
	for edge in [18.0,size.y-18]:
		for i in range(1,int(size.x/17.0)):
			var center:=Vector2(i*17,edge+sin(i*.7)*3)
			draw_set_transform(center,-.32 if i%2==0 else .32,Vector2(1.4,.65))
			draw_arc(Vector2.ZERO,6,0,TAU,16,Color("50564f"),1.8,true)
	draw_set_transform(Vector2.ZERO)
