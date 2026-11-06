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

func layout_fields() -> void:
	var compact := size.x<300
	var portrait_width := clampf(size.x*.28,64,100)
	var left := portrait_width+20
	var width := size.x-left-10
	var shield_space := 42.0 if get_meta("shield_present",false) else 0.0
	var item_size := 20.0 if compact else 40.0
	var min_font := maxi(13,ceili(13.0/maxf(.1,get_global_transform_with_canvas().get_scale().x)))
	var text_left := left+item_size*2+12
	var row_y := 106.0 if compact else 115.0
	var row_height := maxf(item_size,min_font*1.5)
	for child in get_children():
		if child.has_meta("card_face"):
			child.position = Vector2(12,20)
			child.size = Vector2(portrait_width,size.y-40)
			var art: TextureRect = child.get_node("CurrentHeroFace")
			var source: AtlasTexture = preload("res://scripts/hero_art.gd").head(get_meta("hero_id"))
			var crop := source.region
			if compact:
				var body: Dictionary = preload("res://scripts/hero_art.gd").body(get_meta("hero_id"))
				crop.position.y = minf(crop.position.y,body.bounds.position.y)
			crop.size.y = minf(source.atlas.get_height()-crop.position.y,crop.size.x*child.size.y/child.size.x)
			if art.get_meta("card_crop",Rect2())!=crop:
				var portrait := AtlasTexture.new()
				portrait.atlas = source.atlas
				portrait.region = crop
				portrait.filter_clip = true
				art.texture = portrait
				art.set_meta("card_crop",crop)
		elif child.has_meta("card_info"):
			child.custom_minimum_size = Vector2(26,26)
			child.position = Vector2(size.x-35,15)
			child.size = Vector2(26,26)
		elif child.has_meta("card_name"):
			child.position = Vector2(left,12)
			child.size = Vector2(width-30,30)
			preload("res://scripts/battle_typography.gd").fit_line(child,23,13,child.size)
		elif child.has_meta("card_hp") or child.has_meta("card_hp_bar"):
			child.position = Vector2(left,44)
			child.size = Vector2(width-shield_space,25 if compact else 30)
		elif child.has_meta("card_mana") or child.has_meta("card_mana_bar"):
			child.position = Vector2(left,75 if compact else 80)
			child.size = Vector2(width,20 if compact else 24)
		elif child.has_meta("card_shield"):
			child.position = Vector2(size.x-38,44)
			child.size = Vector2(30,25 if compact else 30)
		elif child.has_meta("card_shield_icon"):
			child.position = Vector2(size.x-51,47.5 if compact else 50)
			child.size = Vector2(13,18)
		elif child.has_meta("card_items"):
			child.position = Vector2(left+int(child.get_meta("card_items"))*(item_size+4),row_y+(row_height-item_size)*.5)
			child.add_theme_font_size_override("font_size",12 if compact else 16)
			child.size = Vector2.ONE*item_size
		elif child.has_meta("card_ult"):
			child.visible = false
		elif child.has_meta("card_status"):
			child.position = Vector2(text_left,row_y)
			child.size = Vector2(size.x-text_left-10,row_height)
			child.add_theme_font_size_override("font_size",min_font)
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
	var portrait_width := clampf(size.x*.28,64,100)
	for inset in [0,4]:
		draw_polyline(outline(Rect2(8+inset,16+inset,portrait_width+8-inset*2,size.y-32-inset*2),8),border,1.5,true)
	var compact := size.x<300
	var divider := portrait_width+20+(20 if compact else 40)*2+7
	var row_y := 106.0 if compact else 115.0
	var row_height := maxf(20 if compact else 40,maxi(13,ceili(13.0/maxf(.1,get_global_transform_with_canvas().get_scale().x)))*1.5)
	draw_line(Vector2(divider,row_y),Vector2(divider,row_y+row_height),TaleTheme.c("ornament",.7),1,true)
	var center := Vector2(size.x-22,28)
	draw_polyline(PackedVector2Array([center+Vector2(0,-12),center+Vector2(12,0),center+Vector2(0,12),center+Vector2(-12,0),center+Vector2(0,-12)]),border,1.5,true)
	if has_focus():
		draw_polyline(outline(Rect2(2,11,size.x-4,size.y-22),9),TaleTheme.c("accent"),2,true)
