extends ProgressBar
## Reuses the UI grain; the Range remains a display of the existing combat data.
var health := false
var fill_color := Color.TRANSPARENT:
	set(value):
		fill_color = value
		queue_redraw()
var target_color := Color.TRANSPARENT
var color_tween: Tween

func _ready() -> void:
	set_meta("theme_decoration",true)
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)
	value_changed.connect(func(_value): queue_redraw())
	changed.connect(queue_redraw)
	update_theme()

func update_theme() -> void:
	for key in ["background","fill"]: add_theme_stylebox_override(key,StyleBoxEmpty.new())
	if not health: change_color(TaleTheme.c("mana"))
	queue_redraw()

static func health_color(percent: float) -> Color:
	if percent>.75: return TaleTheme.c("health_full")
	if percent>.50: return TaleTheme.c("health_high")
	if percent>.30: return TaleTheme.c("health_half")
	if percent>.15: return TaleTheme.c("health_low")
	return TaleTheme.c("health_critical")

func set_unit(actor: Dictionary) -> void:
	max_value = maxf(1,actor.max_hp)
	value = maxf(0,actor.hp)
	tooltip_text = "PV %d/%d"%[ceili(actor.hp),ceili(actor.max_hp)]
	change_color(health_color(float(actor.hp)/max_value))

func change_color(color: Color) -> void:
	if color==target_color: return
	target_color = color
	if is_instance_valid(color_tween): color_tween.kill()
	if fill_color.a==0 or not is_inside_tree(): fill_color=color
	else:
		color_tween = create_tween()
		color_tween.tween_property(self,"fill_color",color,.2)

static func shape(extent: Vector2) -> PackedVector2Array:
	var cut := extent.y*.45
	return PackedVector2Array([Vector2(0,extent.y*.5),Vector2(cut,0),Vector2(extent.x-cut,0),Vector2(extent.x,extent.y*.5),Vector2(extent.x-cut,extent.y),Vector2(cut,extent.y)])

func _draw() -> void:
	if size.x<=size.y or size.y<5: return
	var outer := shape(size)
	draw_colored_polygon(outer,TaleTheme.c("damage_outline").darkened(1))
	var contours := Geometry2D.offset_polygon(outer,-2,Geometry2D.JOIN_MITER)
	if contours.is_empty(): return
	var inner: PackedVector2Array = contours[0]
	draw_colored_polygon(inner,TaleTheme.c("combat_track"))
	var end := 2+(size.x-4)*clampf(ratio,0,1)
	if end<=2: return
	var crop := PackedVector2Array([Vector2(2,2),Vector2(end,2),Vector2(end,size.y-2),Vector2(2,size.y-2)])
	var grain := TaleTheme.asset("surface_texture")
	for polygon in Geometry2D.intersect_polygons(inner,crop):
		draw_colored_polygon(polygon,fill_color)
		if grain!=null:
			var uv := PackedVector2Array()
			for point in polygon: uv.append(point/128.0)
			draw_polygon(polygon,PackedColorArray([TaleTheme.c("damage_outline",.16).darkened(1)]),uv,grain)
