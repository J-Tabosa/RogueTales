extends Control
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_meta("theme_decoration",true)
func update_theme() -> void:queue_redraw()
func _draw() -> void:
	var points:=PackedVector2Array([Vector2(2,2),Vector2(8,1),Vector2(14,2),Vector2(13,10),Vector2(8,15),Vector2(3,10),Vector2(2,2)])
	draw_colored_polygon(points.slice(0,6),TaleTheme.c("bar_outline"))
	draw_polyline(points,TaleTheme.c("bar_text"),1.4,true)
