extends Button
## Compact native symbols plus generated bleeding and curse art.
var condition := "poison"
var rate := 0.0
var remaining := 0.0
func configure(kind: String, amount: float, seconds: float) -> void:
	condition=kind
	rate=amount
	remaining=seconds
	text="  %.1f"%amount if kind in ["poison","burn","bleed"] else ""
	tooltip_text=preload("res://scripts/status_art.gd").description(kind,amount,seconds)
	add_theme_font_size_override("font_size",9)
	add_theme_color_override("font_color",Color("b8ed89") if kind=="poison" else Color("ffd099"))
	var plate:=StyleBoxFlat.new()
	plate.bg_color=Color("13261f")
	plate.border_color=Color("887147")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(3)
	plate.content_margin_left=12
	plate.content_margin_right=2
	add_theme_stylebox_override("normal",plate)
	queue_redraw()
func _draw() -> void:
	var generated:Texture2D=preload("res://scripts/status_art.gd").texture(condition)
	if generated!=null:
		draw_texture_rect(generated,Rect2(1,1,14,14),false)
		return
	if condition in ["sleep","immortal"]:
		if condition=="sleep":draw_string(ThemeDB.fallback_font,Vector2(4,12),"Z",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c5b0ef"))
		else:draw_arc(Vector2(8,8),5,0,TAU,12,Color("f6a0a5"),2,true)
		return
	if condition=="poison":
		draw_circle(Vector2(7,6),4,Color("9ddd66"))
		draw_rect(Rect2(4,8,6,4),Color("9ddd66"))
		draw_circle(Vector2(5.5,6),1.2,Color("18301d"))
		draw_circle(Vector2(8.5,6),1.2,Color("18301d"))
		draw_line(Vector2(6,10),Vector2(6,12),Color("18301d"))
		draw_line(Vector2(8,10),Vector2(8,12),Color("18301d"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(7,1),Vector2(11,8),Vector2(10,12),Vector2(4,12),Vector2(2,8),Vector2(4,4),Vector2(5,7)]),Color("f69b43"))
		draw_colored_polygon(PackedVector2Array([Vector2(7,6),Vector2(9,10),Vector2(7,12),Vector2(5,10)]),Color("ffe5a0"))
