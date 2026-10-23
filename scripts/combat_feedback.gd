extends Control
## Side ability ribbons and ULT cut-ins. Timers use real seconds for readable 1x/2x.
var frozen := false
var reduced_motion := false
var queue: Array[Dictionary] = []
var ribbon: Panel
var ribbon_name: Label
var ribbon_title: Label
var ribbon_detail: Label
var ribbon_left := 0.0
var ribbon_age := 0.0
var cutin: Panel
var cutin_name: Label
var cutin_title: Label
var cutin_left := 0.0
var cutin_age := 0.0
var tint := Color.WHITE

func tag(parent: Node, at: Vector2, dims: Vector2, font: int) -> Label:
	var node := Label.new()
	node.position = at
	node.size = dims
	node.add_theme_font_size_override("font_size", font)
	node.add_theme_color_override("font_color", Color("fff1d5"))
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func skin(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("151d30", 0.97)
	style.border_color = color
	style.border_width_left = 5
	style.border_width_bottom = 1
	style.set_corner_radius_all(9)
	return style

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2000
	ribbon = Panel.new()
	ribbon.size = Vector2(280, 92)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ribbon)
	ribbon_name = tag(ribbon, Vector2(15, 7), Vector2(250, 20), 12)
	ribbon_title = tag(ribbon, Vector2(15, 29), Vector2(250, 26), 17)
	ribbon_detail = tag(ribbon, Vector2(15, 59), Vector2(250, 25), 12)
	ribbon.visible = false
	cutin = Panel.new()
	cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cutin)
	cutin_name = tag(cutin, Vector2(12, 6), Vector2(250, 18), 11)
	cutin_title = tag(cutin, Vector2(12, 26), Vector2(250, 28), 17)
	cutin_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cutin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	ribbon.add_theme_stylebox_override("panel", skin(tint))
	ribbon_name.text = str(TaleCatalog.HEROES[id].get("short_name", TaleCatalog.HEROES[id].name)).to_upper() + "  ·  " + ("SINERGIA" if event.kind == "synergy" else "PASSIVA")
	ribbon_title.text = event.title
	ribbon_detail.text = event.detail
	ribbon_left = 2.15
	ribbon_age = 0
	ribbon.visible = true

func announce_ultimate(id: String) -> void:
	cutin.add_theme_stylebox_override("panel", skin(TaleCatalog.HEROES[id].color))
	cutin_name.text = str(TaleCatalog.HEROES[id].name).to_upper() + "  ·  ULT"
	cutin_title.text = TaleCatalog.HERO_TACTICS[id].ult
	cutin_left = 1.55
	cutin_age = 0
	cutin.visible = true
	layout()

func layout() -> void:
	if not is_instance_valid(ribbon): return
	var width := minf(280, size.x - 24)
	ribbon.size.x = width
	ribbon.position = Vector2(size.x - width - 12, 56)
	if not reduced_motion: ribbon.position.x += maxf(0, 1.0 - ribbon_age / 0.22) * (width + 12)
	cutin.size = Vector2(minf(290, size.x * 0.46), 62)
	cutin.position = Vector2(12, 56)
	for node in [cutin_name, cutin_title]: node.size.x = cutin.size.x - 24
	cutin_title.add_theme_font_size_override("font_size", 16 if size.x < 600 else 18)
	if not reduced_motion: cutin.position.x -= maxf(0, 1.0 - cutin_age / 0.18) * (cutin.size.x + 12)

func _process(delta: float) -> void:
	if frozen: return
	ribbon_age += delta
	cutin_age += delta
	if ribbon_left > 0:
		ribbon_left -= delta
		if ribbon_left <= 0: next_ribbon()
	cutin_left = maxf(0, cutin_left - delta)
	cutin.visible = cutin_left > 0
	layout()
