extends Button
## Presentation only: input and combat state remain owned by interface.gd.
const SERIF = preload("res://assets/fonts/renaissance/Lora.ttf")
const RULE = preload("res://assets/ui/team_card_rule.svg")

func _ready() -> void:
	set_meta("theme_decoration", true)
	resized.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	update_theme()

func update_theme() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxEmpty.new()
		style.set_meta("theme_generation",TaleTheme.generation)
		add_theme_stylebox_override(state, style)
		for child in get_children():
			if child.has_meta("card_info"):
				child.add_theme_stylebox_override(state,style)
				child.add_theme_color_override("font_color",TaleTheme.c("text"))
	queue_redraw()

static func outline(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([p+Vector2(cut,0), Vector2(e.x-cut,p.y), Vector2(e.x,p.y+cut), e-Vector2(0,cut), e-Vector2(cut,0), Vector2(p.x+cut,e.y), Vector2(p.x,e.y-cut), p+Vector2(0,cut), p+Vector2(cut,0)])

func _draw() -> void:
	var border := TaleTheme.c("ornament")
	var fill := TaleTheme.c("card_bottom" if not is_hovered() or disabled else "card")
	draw_colored_polygon(outline(Rect2(1,10,size.x-2,size.y-20),9),fill)
	var grain := TaleTheme.asset("surface_texture")
	if grain != null:
		draw_texture_rect(grain,Rect2(10,19,size.x-20,size.y-38),true,TaleTheme.asset_tint("surface_texture",.06))
	for inset in [1,4]:
		draw_polyline(outline(Rect2(inset,10+inset-1,size.x-inset*2,size.y-18-inset*2),9),border,1,true)
	for y in [0,size.y-10]:
		draw_texture_rect(RULE,Rect2(10,y,size.x-20,10),false,border)
	for inset in [0,4]:
		draw_polyline(outline(Rect2(12+inset,22+inset,88-inset*2,88-inset*2),9),border,1.5,true)
	draw_line(Vector2(106,123),Vector2(106,size.y-23),TaleTheme.c("ornament",.7),1,true)
	# The information button shares this diamond instead of a second box.
	var center := Vector2(size.x-25,31)
	draw_polyline(PackedVector2Array([center+Vector2(0,-15),center+Vector2(15,0),center+Vector2(0,15),center+Vector2(-15,0),center+Vector2(0,-15)]),border,1.5,true)
	if has_focus():
		draw_polyline(outline(Rect2(2,11,size.x-4,size.y-22),9),TaleTheme.c("accent"),2,true)
