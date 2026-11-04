class_name TaleTheme
extends Node
## One palette, one native Godot Theme and one adapter for dynamically built screens.
## No gameplay timers, art textures or formation geometry are changed here.
const BODY = preload("res://assets/fonts/renaissance/Lora.ttf")
const HEADING = preload("res://assets/fonts/renaissance/Cinzel.ttf")
const PALETTES = {
	"dark": {
		"background": "07253f", "surface": "0b304b", "surface_top": "123e58",
		"secondary": "3c95a9", "button": "17465f", "hover": "205971", "pressed": "092e49",
		"border": "3c95a9", "accent": "aceaf1", "text": "ffffff", "muted": "d2edf2",
		"disabled": "97b6c3", "ornament": "aceaf1", "shadow": "031524",
		"track": "041c30", "progress": "aceaf1", "selection": "3c95a9",
		"physical": "ffffff", "magical": "aceaf1",
		"health_full": "aceaf1", "health_high": "8fd9e4", "health_half": "71c4d3",
		"health_low": "55adbf", "health_critical": "3c95a9"
	},
	"light": {
		"background": "e5d0a1", "surface": "ddbd82", "surface_top": "e8cea0",
		"secondary": "ddbd82", "button": "ddbd82", "hover": "ead3a9", "pressed": "ceb078",
		"border": "99723c", "accent": "684921", "text": "3b2414", "muted": "5b3d23",
		"disabled": "735434", "ornament": "a27632", "shadow": "8c693c",
		"track": "c3a36d", "progress": "684921", "selection": "c4a069",
		"physical": "3b2414", "magical": "684921",
		"health_full": "684921", "health_high": "78572c", "health_half": "886536",
		"health_low": "987440", "health_critical": "a7834d"
	}
}
static var mode := "dark"
static var generation := 0
static var styles: Dictionary = {}
static var assets: Dictionary = {}
var host: Control
var applying := false
var pending: Dictionary = {}

static func c(token: String, alpha := 1.0) -> Color:
	var result := Color(PALETTES[mode].get(token, PALETTES[mode].text))
	result.a = alpha
	return result

static func set_mode(value: String) -> void:
	mode = value if PALETTES.has(value) else "dark"
	RenderingServer.set_default_clear_color(c("background"))
	generation += 1
	styles.clear()

static func rarity(index: int) -> Color:
	return c("ornament").lerp(c("text"), clampf(index / 6.0, 0, 1) * .25)

static func asset(key: String) -> Texture2D:
	if not assets.has(key):
		var base := "res://assets/ui/themes/shared/" + key
		var path := base + ".png" if ResourceLoader.exists(base + ".png") else base + ".svg"
		assets[key] = load(path) if ResourceLoader.exists(path) else null
	return assets[key]

static func flat(fill: String, edge := "border", radius := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = c(fill)
	style.border_color = c(edge)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(2)
	style.set_meta("theme_generation", generation)
	return style

static func button_style(state: String, active := false, square := false) -> StyleBoxTexture:
	var key := "button_%s_%s_%s" % [state, active, square]
	if styles.has(key): return styles[key]
	var fill := "hover" if state == "hover" else "pressed" if state == "pressed" else "button"
	var edge := "accent" if state in ["hover", "focus"] or active else "border"
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><defs><linearGradient id="b" x2="0" y2="1"><stop stop-color="#%s"/><stop offset=".45" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="1" y="1" width="78" height="78" rx="7" fill="url(#b)" stroke="#%s" stroke-width="2"/><rect x="4.5" y="4.5" width="71" height="71" rx="4" fill="none" stroke="#%s" stroke-opacity=".42"/><path d="M9 7H71" stroke="#%s" stroke-opacity=".25"/></svg>' % [c(fill).lightened(.05).to_html(false), c(fill).to_html(false), c(fill).darkened(.06).to_html(false), c(edge).to_html(false), c("ornament").to_html(false), c("accent").to_html(false)]
	var image := Image.new()
	if square: svg = svg.replace('rx="7"', 'rx="0"').replace('rx="4"', 'rx="0"')
	image.load_svg_from_string(svg)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	style.texture_margin_left = 10
	style.texture_margin_right = 10
	style.texture_margin_top = 10
	style.texture_margin_bottom = 10
	style.set_content_margin_all(2)
	style.set_meta("theme_generation", generation)
	style.set_meta("theme_variant", key)
	styles[key] = style
	return style

static func native_theme() -> Theme:
	var result := Theme.new()
	result.default_font = BODY
	result.default_font_size = 16
	for type in ["Label", "Button", "LineEdit", "CheckButton", "CheckBox", "OptionButton"]:
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			result.set_color(key, type, c("text"))
		result.set_color("font_disabled_color", type, c("disabled"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		result.set_stylebox(state, "Button", button_style(state))
	result.set_color("default_color", "RichTextLabel", c("text"))
	result.set_color("font_color", "TooltipLabel", c("text"))
	result.set_stylebox("panel", "TooltipPanel", flat("surface"))
	for type in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", type, flat("track", "track", 3))
		for key in ["grabber", "grabber_highlight", "grabber_pressed"]:
			result.set_stylebox(key, type, flat("secondary", "ornament", 3))
	for type in ["HSlider", "VSlider"]:
		result.set_stylebox("slider", type, flat("track", "border", 3))
		for key in ["grabber_area", "grabber_area_highlight"]:
			result.set_stylebox(key, type, flat("secondary", "ornament", 3))
		var image := Image.create(18, 18, false, Image.FORMAT_RGBA8)
		image.fill(c("ornament"))
		var texture := ImageTexture.create_from_image(image)
		for key in ["grabber", "grabber_highlight", "grabber_disabled"]: result.set_icon(key, type, texture)
	return result

func install(root: Control, preference: String) -> void:
	host = root
	set_mode(preference)
	host.theme = native_theme()
	get_tree().node_added.connect(on_node_added)
	refresh()

func switch_to(preference: String) -> void:
	set_mode(preference)
	host.theme = native_theme()
	refresh()

func refresh() -> void:
	apply_branch(host)

func apply_branch(node: Node) -> void:
	if node is Control: apply_control(node)
	for child in node.get_children(): apply_branch(child)

func on_node_added(node: Node) -> void:
	if node is Control and host.is_ancestor_of(node):
		queue_control(node)

func queue_control(node: Control) -> void:
	if applying or pending.has(node.get_instance_id()): return
	pending[node.get_instance_id()] = true
	apply_later.call_deferred(weakref(node), node.get_instance_id())

func apply_later(reference: WeakRef, id: int) -> void:
	pending.erase(id)
	var node: Control = reference.get_ref()
	if is_instance_valid(node) and node.is_inside_tree() and not node.is_queued_for_deletion(): apply_control(node)

func color_override(node: Control, key: String, value: Color) -> void:
	if not node.has_theme_color_override(key) or node.get_theme_color(key) != value:
		node.add_theme_color_override(key, value)

func style_override(node: Control, key: String, style: StyleBox) -> void:
	var old := node.get_theme_stylebox(key)
	if old == null or old.get_meta("theme_generation", -1) != generation or old.get_meta("theme_variant", "") != style.get_meta("theme_variant", ""):
		node.add_theme_stylebox_override(key, style)

func apply_control(node: Control) -> void:
	# Shader-driven weather, impact and status layers belong to the scene artwork.
	if node.material != null: return
	if node.has_meta("theme_decoration"):
		if node.has_method("update_theme"): node.update_theme()
		return
	applying = true
	if node is Label or node is Button or node is LineEdit:
		var title: bool = (node is Label and node.get_theme_font_size("font_size") >= 20) or node.get_meta("theme_heading", false)
		var face: Font = HEADING if title else BODY
		if node.get_theme_font("font") != face: node.add_theme_font_override("font", face)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			color_override(node, key, c(str(node.get_meta("theme_text_role", "text"))))
		color_override(node, "font_disabled_color", c("disabled"))
		color_override(node, "font_shadow_color", c("shadow", 0))
		# Damage labels over artwork keep their outline for contrast.
		color_override(node, "font_outline_color", c("background") if node.get_theme_constant("outline_size") > 0 else c("shadow", 0))
	if node is RichTextLabel:
		if node.bbcode_enabled:
			var source: String = node.get_meta("theme_bbcode_source", node.text) if node.text == node.get_meta("theme_bbcode_result", "") else node.text
			node.set_meta("theme_bbcode_source", source)
			var pattern := RegEx.new()
			pattern.compile("\\[color=#[0-9a-fA-F]{6}\\]")
			var output := source
			for match_value in pattern.search_all(source):
				var old_color := match_value.get_string().substr(8, 6).to_lower()
				var role := "magical" if old_color in ["64c7ff", "aceaf1", "684921"] else "physical" if old_color in ["ff6969", "ffffff", "3b2414"] else "text"
				output = output.replace(match_value.get_string(), "[color=#%s]" % c(role).to_html(false))
			node.text = output
			node.set_meta("theme_bbcode_result", output)
		color_override(node, "default_color", c("text"))
		for key in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
			if node.get_theme_font(key) != BODY: node.add_theme_font_override(key, BODY)
	if node is Button:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			style_override(node, state, button_style(state, node.get_meta("primary", false) or node.get_meta("theme_active", false), node.has_meta("skill_info")))
		ensure_surface(node, true)
	elif node is Panel or node is PanelContainer:
		# Preserve layout margins on PanelContainers and intentionally empty art frames.
		var old := node.get_theme_stylebox("panel")
		if old == null or old.get_meta("theme_generation", -1) != generation:
			var style := flat("surface")
			if old != null:
				for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: style.set_content_margin(side, old.get_content_margin(side))
			if node.name == "GoldenArtFrame": style.bg_color.a = 0
			node.add_theme_stylebox_override("panel", style)
		ensure_surface(node, node.name == "GoldenArtFrame")
	elif node is LineEdit:
		for key in ["normal", "read_only"]: style_override(node, key, flat("surface"))
		style_override(node, "focus", flat("surface", "accent"))
		color_override(node, "caret_color", c("text"))
		color_override(node, "selection_color", c("selection"))
		color_override(node, "font_selected_color", c("text"))
	elif node is ProgressBar:
		style_override(node, "background", flat("track", "border", 3))
		if not node.has_meta("health_bar"): style_override(node, "fill", flat("progress", "progress", 3))
	elif node is ColorRect:
		if node.name == "ShieldSegment": node.color = c("secondary")
		elif node.size.x >= 300 and node.size.y >= 400:
			node.color = c("background", .93 if node.get_parent() != host.get("page") else 1.0)
			ensure_surface(node, false, true)
		else: node.color = c("border", node.color.a)
	elif node is TextureRect and node.texture is GradientTexture2D:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([c("background", 0), c("background", .95)])
		node.texture.gradient = gradient
	if node.has_meta("theme_divider"): node.modulate = c("ornament", .7)
	if node.get_script() == preload("res://scripts/mobile_icon.gd"):
		node.tint = c("accent")
		node.queue_redraw()
	if node.get_script() == preload("res://scripts/status_badge.gd") or node.get_script() == preload("res://scripts/sealed_blessing.gd"):
		node.queue_redraw()
	if node.has_node("ThemeSurface"): node.get_node("ThemeSurface").update_theme()
	if not node.has_meta("theme_watched"):
		node.set_meta("theme_watched", true)
		node.theme_changed.connect(queue_control.bind(node))
	applying = false

func ensure_surface(node: Control, frame_only := false, backdrop := false) -> void:
	if node.has_node("ThemeSurface"): return
	var surface := Control.new()
	surface.set_script(preload("res://scripts/theme_surface.gd"))
	surface.frame_only = frame_only
	surface.backdrop = backdrop
	surface.name = "ThemeSurface"
	surface.set_meta("theme_decoration", true)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(surface, false, Node.INTERNAL_MODE_FRONT)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
