extends RefCounted
## One cached texture per generated item, shared by slots and inventory.
const Gear = preload("res://scripts/equipment.gd")
static var textures: Dictionary = {}
static func equipped(actor: Dictionary, index: int) -> String:
	return Gear.item_at(actor, index)
static func texture(id: String) -> Texture2D:
	if id.is_empty(): return null
	if not textures.has(id):
		var path := "res://assets/items/%s.%s" % [id,"svg" if id=="travelers_page" else "png"]
		textures[id] = load(path) if ResourceLoader.exists(path) else null
	return textures[id]
static func item_plate(id:String,selected:=false) -> StyleBoxFlat:
	var style:=plate(selected,id.begins_with("trophy_"))
	if not id.is_empty():
		style.bg_color=Gear.tint(id).darkened(.73)
		style.border_color=Gear.tint(id).lightened(.2 if selected else 0)
	return style
static func plate(selected := false, trophy := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("49374d") if trophy else Color("263b35")
	style.border_color = Color("f1d18a") if selected else Color("8a8064")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(2)
	return style
static func picture(parent: Node, id: String, rect: Rect2) -> TextureRect:
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = texture(id)
	art.position = rect.position
	art.size = rect.size
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art
static func slot(parent: Node, id: String, rect: Rect2, callback: Callable, selected := false) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, item_plate(id,selected or state != "normal"))
	button.add_theme_color_override("font_color", Color("b4bba7"))
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	parent.add_child(button)
	var art := picture(button, id, Rect2(Vector2(3, 3), rect.size - Vector2(6, 6)))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 3
	art.offset_top = 3
	art.offset_right = -3
	art.offset_bottom = -3
	button.set_meta("item_picture", art)
	refresh(button, id)
	button.add_theme_stylebox_override("normal", item_plate(id,selected))
	return button
static func refresh(button: Button, id: String) -> void:
	if button.get_meta("item_id", "__unset") == id: return
	button.set_meta("item_id", id)
	button.text = "+" if id.is_empty() else ""
	button.tooltip_text = (Gear.rarity_name(id)+" · " if not id.is_empty() else "")+Gear.data(id).get("title", "Espaço vazio · escolher equipamento")
	button.get_meta("item_picture").texture = texture(id)
	button.add_theme_stylebox_override("normal", item_plate(id))
