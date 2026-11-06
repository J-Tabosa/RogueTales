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
	for child in get_children():
		if not child.has_meta("card_hp_bar") and not child.has_meta("card_mana_bar"): continue
		var edge := child.get_node_or_null("BarOutline") as Panel
		if edge == null:
			edge = Panel.new()
			edge.name = "BarOutline"
			edge.set_meta("theme_decoration",true)
			edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			edge.z_index = 1
			child.add_child(edge)
			edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var border := TaleTheme.flat("combat_track","damage_outline",12)
		border.draw_center = false
		border.border_color = TaleTheme.c("damage_outline").darkened(1.0)
		border.set_border_width_all(2)
		border.set_content_margin_all(0)
		edge.add_theme_stylebox_override("panel",border)
	queue_redraw()

func layout_compact() -> void:
	for child in get_children():
		if child.has_meta("card_face"):
			child.position = Vector2(18,28)
			child.size = Vector2(64,64)
		elif child.has_meta("card_name"):
			child.position = Vector2(96,54)
			child.size = Vector2(size.x-108,34)
			preload("res://scripts/battle_typography.gd").fit_line(child,24,14,child.size)
		elif child.has_meta("card_hp") or child.has_meta("card_hp_bar") or child.has_meta("card_mana") or child.has_meta("card_mana_bar"):
			child.position = Vector2(12,110 if child.has_meta("card_hp") or child.has_meta("card_hp_bar") else 144)
			child.size = Vector2(size.x-24,26)
		elif child.has_meta("card_shield"):
			child.position = Vector2(size.x-62,110)
		elif child.has_meta("card_shield_icon"):
			child.position = Vector2(size.x-80,113)
		elif child.has_meta("card_items"):
			child.position = Vector2(14+int(child.get_meta("card_items"))*44,213)
			child.size = Vector2(36,36)
		elif child.has_meta("card_ult"):
			child.position = Vector2(12,178)
			child.size = Vector2(size.x-24,28)
			child.autowrap_mode = TextServer.AUTOWRAP_OFF
			child.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			preload("res://scripts/battle_typography.gd").fit_line(child,14,12,child.size)
		elif child.has_meta("card_status"):
			child.position = Vector2(108,220)
			child.size = Vector2(size.x-120,22)
			child.add_theme_font_size_override("font_size",14)

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
	var compact := size.x<300
	var portrait_size := 76 if compact else 88
	for inset in [0,4]:
		draw_polyline(outline(Rect2(12+inset,22+inset,portrait_size-inset*2,portrait_size-inset*2),9),border,1.5,true)
	draw_line(Vector2(102 if compact else 106,212 if compact else 123),Vector2(102 if compact else 106,size.y-23),TaleTheme.c("ornament",.7),1,true)
	# The information button shares this diamond instead of a second box.
	var center := Vector2(size.x-25,31)
	draw_polyline(PackedVector2Array([center+Vector2(0,-15),center+Vector2(15,0),center+Vector2(0,15),center+Vector2(-15,0),center+Vector2(0,-15)]),border,1.5,true)
	if has_focus():
		draw_polyline(outline(Rect2(2,11,size.x-4,size.y-22),9),TaleTheme.c("accent"),2,true)
