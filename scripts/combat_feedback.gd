extends Control
## Compact portrait notifications; timers remain readable at every combat speed.
const Type = preload("res://scripts/battle_typography.gd")
const RibbonSkin = preload("res://scripts/ui_skin.gd")
var frozen := false
var reduced_motion := false
var queue: Array[Dictionary] = []
var ribbon: Panel
var ribbon_name: Label
var ribbon_title: Label
var ribbon_detail: Label
var ribbon_face: TextureRect
var ribbon_left := 0.0
var ribbon_age := 0.0
var cutin: Panel
var cutin_name: Label
var cutin_title: Label
var cutin_face: TextureRect
var cutin_left := 0.0
var cutin_age := 0.0
var tint := Color.WHITE
static var banner_texture: Texture2D
func tag(parent: Node, at: Vector2, dims: Vector2, font: int, bold := false) -> Label:
	var node := Label.new()
	node.position = at
	node.size = dims
	node.add_theme_font_size_override("font_size", font)
	node.add_theme_color_override("font_color", Color("fff1d5"))
	Type.apply(node,bold)
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
func skin(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102d27",.98)
	style.border_color = color.lerp(Color("b99a56"),.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
func frame(parent: Panel) -> void:
	var path := "res://assets/ui/ability_ribbon.png"
	if banner_texture == null and ResourceLoader.exists(path):
		var source: Texture2D = load(path)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(source.get_image().get_used_rect())
		banner_texture = atlas
	if banner_texture == null:return
	var art := RibbonSkin.picture(parent,banner_texture,Rect2(Vector2.ZERO,parent.size))
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func face(parent: Panel) -> TextureRect:
	var holder := Panel.new()
	holder.position = Vector2(8,8)
	holder.size = Vector2(52,52)
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_stylebox_override("panel",skin(Color("a58d53")))
	parent.add_child(holder)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return art
func portrait(node: TextureRect,id: String) -> void:
	node.texture = preload("res://scripts/hero_art.gd").head(id)
	node.get_parent().set_meta("portrait_source",preload("res://scripts/hero_art.gd").source_path(id))
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2000
	ribbon = Panel.new()
	ribbon.size = Vector2(260,70)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.clip_contents=true
	add_child(ribbon)
	frame(ribbon)
	ribbon_face = face(ribbon)
	ribbon_name = tag(ribbon,Vector2(71,17),Vector2(175,18),10)
	ribbon_title = tag(ribbon,Vector2(71,36),Vector2(175,26),15,true)
	ribbon_detail = tag(ribbon,Vector2.ZERO,Vector2.ZERO,10)
	ribbon_detail.visible = false
	ribbon.visible = false
	cutin = Panel.new()
	cutin.size = Vector2(260,62)
	cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin.clip_contents=true
	add_child(cutin)
	frame(cutin)
	cutin_face = face(cutin)
	cutin_face.get_parent().position = Vector2(8,5)
	cutin_name = tag(cutin,Vector2(71,13),Vector2(175,18),10)
	cutin_title = tag(cutin,Vector2(71,29),Vector2(175,26),16,true)
	cutin.visible = false
func enqueue(event: Dictionary) -> void:
	queue.append(event.duplicate())
	if queue.size() > 8: queue.pop_front()
	if ribbon_left <= 0: next_ribbon()
func next_ribbon() -> void:
	if queue.is_empty():
		ribbon.visible = false
		return
	var event: Dictionary = queue.pop_front()
	var id := str(event.hero)
	tint = TaleCatalog.HEROES[id].color
	ribbon.add_theme_stylebox_override("panel",skin(tint))
	portrait(ribbon_face,id)
	ribbon_name.text = str(TaleCatalog.HEROES[id].get("short_name",TaleCatalog.HEROES[id].name)).to_upper()+" · "+("SINERGIA" if event.kind=="synergy" else "PASSIVA")
	ribbon_title.text = event.title
	ribbon_detail.text = event.detail
	ribbon_left = 2.15
	ribbon_age = 0
	ribbon.visible = true
	layout()
func announce_ultimate(id: String) -> void:
	cutin.add_theme_stylebox_override("panel",skin(TaleCatalog.HEROES[id].color))
	portrait(cutin_face,id)
	cutin_name.text = str(TaleCatalog.HEROES[id].get("short_name",TaleCatalog.HEROES[id].name)).to_upper()+" · ULT"
	cutin_title.text = TaleCatalog.HERO_TACTICS[id].ult
	cutin_left = 1.55
	cutin_age = 0
	cutin.visible = true
	layout()
func layout() -> void:
	if not is_instance_valid(ribbon): return
	var width := minf(260,size.x-24)
	ribbon.size = Vector2(width,70)
	ribbon.position = Vector2(12,46)
	if not reduced_motion:ribbon.position.x -= maxf(0,1.0-ribbon_age/.22)*(width+12)
	cutin.size = Vector2(width,62)
	cutin.position = Vector2(12,124 if ribbon.visible else 46)
	if not reduced_motion:cutin.position.x -= maxf(0,1.0-cutin_age/.18)*(width+12)
	for node in [ribbon_name,ribbon_title,cutin_name,cutin_title]:node.size.x=width-85
func _process(delta: float) -> void:
	if frozen:return
	ribbon_age += delta
	cutin_age += delta
	if ribbon_left > 0:
		ribbon_left -= delta
		if ribbon_left <= 0:next_ribbon()
	cutin_left = maxf(0,cutin_left-delta)
	cutin.visible = cutin_left > 0
	layout()
