class_name TaleTheme
extends Node
## One palette, one native Godot Theme and one adapter for dynamically built screens.
## No gameplay timers, art textures or formation geometry are changed here.
const BODY = preload("res://assets/fonts/Nunito-Semibold.ttf")
const STRONG = preload("res://assets/fonts/Nunito-Extrabold.ttf")
const HEADING = preload("res://assets/fonts/renaissance/Cinzel.ttf")
const MANUSCRIPT = preload("res://assets/fonts/renaissance/Lora.ttf")
## Gameplay colors are semantic: changing the UI theme must never recolor them.
const RARITIES = ["858b94", "50b86a", "5097ee", "ac6bef", "ef9c39", "ee5555", "e6cb79"]
const SEMANTIC = {
	"health_full":"67cf85", "health_high":"c5e85a", "health_half":"f2d36b", "health_low":"f5a052", "health_critical":"ff6969",
	"mana":"8ab4f0", "mana_text":"a9c9ff", "shield":"8ddbee", "physical":"ff6969", "magical":"64c7ff", "true_damage":"ead9ff",
	"combat_surface":"102a24", "combat_border":"8c7043", "combat_text":"f5e8c3", "combat_track":"091a19", "damage_outline":"101321",
	"rarity_text":"fff4df", "rarity_disabled":"c5c8c2"
}
const PALETTES = {
	"dark": {
		"background": "07253f", "background_bottom":"031522", "surface": "10394b", "surface_top": "1c4f61", "surface_bottom":"092737",
		"card":"17485a", "card_top":"286175", "card_bottom":"103647", "well":"071f2c", "well_top":"103444", "well_bottom":"051a28",
		"secondary": "3c95a9", "button": "205468", "button_top":"316b7d", "primary":"225f70", "primary_top":"307b87", "hover": "30697d", "pressed": "0c3042",
		"border": "3c95a9", "accent": "aceaf1", "text": "ffffff", "muted": "d2edf2",
		"disabled": "97b6c3", "ornament": "aceaf1", "shadow": "031524",
		"track": "041c30", "progress": "aceaf1", "selection": "3c95a9"
	},
	"light": {
		"background": "e5d0a1", "background_bottom":"c7a36f", "surface": "ddbd82", "surface_top": "f5e7c9", "surface_bottom":"c9a772",
		"card":"ead1a1", "card_top":"faefd9", "card_bottom":"d9b67e", "well":"c5a670", "well_top":"dfc490", "well_bottom":"bea06b",
		"secondary": "ddbd82", "button": "d8b474", "button_top":"f2dab0", "primary":"c29a59", "primary_top":"dec18c", "hover": "ebcf98", "pressed": "c6a066",
		"border": "99723c", "accent": "684921", "text": "3b2414", "muted": "5b3d23",
		"disabled": "735434", "ornament": "a27632", "shadow": "8c693c",
		"track": "c3a36d", "progress": "684921", "selection": "c4a069"
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
	var result := Color(SEMANTIC.get(token, PALETTES[mode].get(token, PALETTES[mode].text)))
	result.a = alpha
	return result

static func set_mode(value: String) -> void:
	mode = value if PALETTES.has(value) else "dark"
	RenderingServer.set_default_clear_color(c("background"))
	generation += 1
	styles.clear()
	assets.clear()

static func rarity(index: int) -> Color:
	return Color(RARITIES[clampi(index,0,6)])

static func asset(key: String) -> Texture2D:
	if not assets.has(key):
		var path := "res://assets/ui/themes/%s/%s.png" % [mode,key]
		var colored := ResourceLoader.exists(path)
		if not colored: path = "res://assets/ui/themes/shared/%s.svg" % key
		var texture:Texture2D = load(path) if ResourceLoader.exists(path) else null
		# Atlas regions remove export padding without changing the source PNGs.
		var regions := {"section_divider":Rect2(96,208,1980,290), "horizontal_border":Rect2(0,196,2172,310), "corner_filigrane":Rect2(76,80,350,350)}
		if colored and regions.has(key):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = regions[key]
			atlas.filter_clip = true
			texture = atlas
		if texture != null: texture.set_meta("theme_colorized",colored)
		assets[key] = texture
	return assets[key]

static func asset_tint(key:String, alpha:=1.0) -> Color:
	var texture:=asset(key)
	return Color(1,1,1,alpha) if texture!=null and texture.get_meta("theme_colorized",false) else c("ornament",alpha)

static func is_manuscript(node: Node) -> bool:
	var current := node
	while current != null:
		if current.get_meta("manuscript_battle",false): return true
		current = current.get_parent()
	return false

static func manuscript_style(state: String) -> StyleBoxFlat:
	var key := "manuscript_"+state
	if styles.has(key): return styles[key]
	var style := flat("surface","border",0)
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(1 if state=="focus" else 0)
	style.border_color = c("accent")
	style.set_meta("theme_variant",key)
	styles[key] = style
	return style

static func rarity_of(node:Node) -> int:
	return int(node.get_meta("theme_rarity",node.get_meta("bonus_rarity",-1)))

static func has_dark_readout(node:Node) -> bool:
	var current:=node
	while current!=null:
		if current.get_meta("combat_readout",false) or rarity_of(current)>=0:return true
		current=current.get_parent()
	return false

static func text_color(node:Control) -> Color:
	if node.has_meta("theme_semantic_color"):return node.get_meta("theme_semantic_color")
	if node.has_meta("theme_text_role"):return c(str(node.get_meta("theme_text_role")))
	var current:Node=node
	while current!=null:
		if current.get_meta("combat_readout",false):return c("combat_text")
		if rarity_of(current)>=0:return c("rarity_text")
		current=current.get_parent()
	return c("text")

static func surface_role(node:Control) -> String:
	if node.get_meta("combat_readout",false):return "combat_surface"
	if node.has_meta("theme_surface_role"):return str(node.get_meta("theme_surface_role"))
	if node is PanelContainer:return "card"
	var parent:=node.get_parent()
	return "well" if parent is Panel or parent is Button else "surface"

static func surface_colors(node:Control) -> Array[Color]:
	var rank:=rarity_of(node)
	if rank>=0:return [rarity(rank).darkened(.70),rarity(rank).darkened(.82),rarity(rank).darkened(.90)]
	var role:=surface_role(node)
	if role=="combat_surface":return [c(role).lightened(.015),c(role),c(role).darkened(.08)]
	return [c(role+"_top"),c(role),c(role+"_bottom")]

static func flat(fill: String, edge := "border", radius := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = c(fill)
	style.border_color = c(edge)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(2)
	style.set_meta("theme_generation", generation)
	return style

static func button_style(state: String, active := false, square := false, rank:=-1) -> StyleBoxTexture:
	var key := "button_%s_%s_%d_%s" % [state, active, rank, square]
	if styles.has(key): return styles[key]
	var fill := "hover" if state == "hover" else "pressed" if state == "pressed" else "button"
	var edge := "accent" if state in ["hover", "focus"] or active else "border"
	var top:=c("button_top" if not active else "primary_top")
	var middle:=c("primary") if active and state=="normal" else c(fill)
	if state in ["hover","pressed"]:top=middle.lightened(.06)
	var border:=c(edge)
	if rank>=0:
		middle=rarity(rank).darkened(.68 if state=="hover" else .82)
		top=rarity(rank).darkened(.58 if state=="hover" else .72)
		border=rarity(rank).lightened(.25 if active or state=="focus" else 0)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><defs><linearGradient id="b" x2="0" y2="1"><stop stop-color="#%s"/><stop offset=".48" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="1" y="1" width="78" height="78" rx="7" fill="url(#b)" stroke="#%s" stroke-width="2"/><rect x="4.5" y="4.5" width="71" height="71" rx="4" fill="none" stroke="#%s" stroke-opacity=".42"/><path d="M9 7H71" stroke="#%s" stroke-opacity=".25"/></svg>' % [top.to_html(false), middle.to_html(false), middle.darkened(.12).to_html(false), border.to_html(false), border.to_html(false), border.lightened(.2).to_html(false)]
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
	style.set_meta("rarity_color",rarity(rank) if rank>=0 else Color.TRANSPARENT)
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
		result.set_stylebox(state, "CheckButton", button_style(state))
	for checked in [false,true]:
		var side:="checked" if checked else "unchecked"
		var knob_x:=44 if checked else 16
		var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32"><rect x="1" y="2" width="62" height="28" rx="14" fill="#%s" stroke="#%s" stroke-width="2"/><circle cx="%d" cy="16" r="10" fill="#%s"/><circle cx="%d" cy="16" r="5" fill="none" stroke="#%s" stroke-width="1.5"/></svg>'%[c("secondary" if checked else "well").to_html(false),c("border").to_html(false),knob_x,c("text").to_html(false),knob_x,c("background").to_html(false)]
		var icon_image:=Image.new()
		icon_image.load_svg_from_string(svg)
		var icon:=ImageTexture.create_from_image(icon_image)
		for suffix in ["","_disabled","_mirrored","_disabled_mirrored"]:result.set_icon(side+suffix,"CheckButton",icon)
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
		var title: bool = (node is Label and node.get_theme_font_size("font_size") >= 26 and not node.get_meta("combat_readout",false)) or node.get_meta("theme_heading", false)
		var face: Font = HEADING if title or (is_manuscript(node) and node.has_meta("card_name")) else MANUSCRIPT if is_manuscript(node) else STRONG if node is Button or node.get_theme_font_size("font_size")>=19 or node.has_meta("card_name") or node.has_meta("card_hp") else BODY
		if node.get_theme_font("font") != face: node.add_theme_font_override("font", face)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			color_override(node, key, text_color(node))
		color_override(node, "font_disabled_color", c("rarity_disabled") if has_dark_readout(node) else c("disabled"))
		color_override(node, "font_shadow_color", c("shadow", 0))
		# Damage labels over artwork keep their outline for contrast.
		color_override(node, "font_outline_color", c("damage_outline") if node.get_theme_constant("outline_size") > 0 else c("shadow", 0))
	if node is RichTextLabel:
		# BBCode damage/rarity colors convey game information and remain untouched.
		color_override(node, "default_color", text_color(node))
		if node.get_meta("combat_readout",false):
			var readout:=flat("combat_surface","combat_border",3)
			readout.set_border_width_all(0)
			readout.content_margin_left=4
			readout.content_margin_right=4
			readout.content_margin_top=1
			readout.content_margin_bottom=1
			style_override(node,"normal",readout)
		for key in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
			var body: Font = MANUSCRIPT if is_manuscript(node) else BODY
			if node.get_theme_font(key) != body: node.add_theme_font_override(key, body)
	if node is Button:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			style_override(node, state, manuscript_style(state) if node.has_meta("manuscript_role") else button_style(state, node.get_meta("primary", false) or node.get_meta("theme_active", false), node.has_meta("skill_info"),rarity_of(node)))
		ensure_surface(node, true)
	elif node is Panel or node is PanelContainer:
		# Preserve layout margins on PanelContainers and intentionally empty art frames.
		var old := node.get_theme_stylebox("panel")
		if old == null or old.get_meta("theme_generation", -1) != generation:
			var style := flat(surface_role(node))
			if node.has_meta("manuscript_role"):
				style.bg_color=Color.TRANSPARENT
				style.set_border_width_all(0)
			if node.get_meta("combat_readout",false):style.border_color=c("combat_border")
			if rarity_of(node)>=0:
				style.bg_color=rarity(rarity_of(node)).darkened(.82)
				style.border_color=rarity(rarity_of(node))
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
		var combat:=node.has_meta("health_bar") or node.has_meta("theme_bar_role")
		style_override(node, "background", flat("combat_track" if combat else "track", "border", 3))
		if not node.has_meta("health_bar"): style_override(node, "fill", flat(str(node.get_meta("theme_bar_role","progress")), str(node.get_meta("theme_bar_role","progress")), 3))
		if node.get_meta("manuscript_role","") == "bar":
			for key in ["background","fill"]:
				var style := node.get_theme_stylebox(key) as StyleBoxFlat
				if style != null and style.corner_radius_top_left != 0:
					style = style.duplicate()
					style.set_corner_radius_all(0)
					node.add_theme_stylebox_override(key,style)
			ensure_surface(node,true)
	elif node is ColorRect:
		if node.name == "ShieldSegment": node.color = c("shield")
		elif node.size.x >= 300 and node.size.y >= 400:
			if not node.has_meta("theme_shade_alpha"):node.set_meta("theme_shade_alpha",node.color.a)
			node.color = c("background", 1.0 if node.get_parent()==host.get("page") else float(node.get_meta("theme_shade_alpha")))
			if node.get_parent()==host.get("page"):ensure_surface(node,false,true)
		else: node.color = c("border", node.color.a)
	elif node is TextureRect and node.texture is GradientTexture2D:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([c("background", 0), c("background", .95)])
		node.texture.gradient = gradient
	if node.has_meta("theme_divider"):
		node.texture=asset("section_divider")
		node.modulate = asset_tint("section_divider",.85)
	if node.get_script() == preload("res://scripts/mobile_icon.gd"):
		node.tint = c(str(node.get_meta("theme_icon_role","accent")))
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
