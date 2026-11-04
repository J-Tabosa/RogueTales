class_name TaleSkin
extends RefCounted
## Shared artwork and theme decorations, with no per-frame UI traversal.
const FOREST = preload("res://assets/ui/enchanted_forest.png")
const MAP = preload("res://assets/ui/world_map.png")

static func picture(parent: Node, texture: Texture2D, rect: Rect2, cover := false) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if cover
		else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func background(parent: Control) -> Control:
	var node := Control.new()
	node.set_script(preload("res://scripts/theme_surface.gd"))
	node.backdrop = true
	node.set_meta("theme_decoration", true)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return node

static func divider(parent: Control, rect: Rect2) -> TextureRect:
	var node := picture(parent, TaleTheme.asset("section_divider"), rect)
	node.set_meta("theme_divider", true)
	node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.modulate = TaleTheme.asset_tint("section_divider", .85)
	return node

static func decorate(node: Control, _button_style := false, frame_only := false, _factor_override := 0.0) -> Control:
	if node.has_node("ThemeSurface"): return node.get_node("ThemeSurface")
	var surface := Control.new()
	surface.set_script(preload("res://scripts/theme_surface.gd"))
	surface.frame_only = frame_only or node is Button
	surface.name = "ThemeSurface"
	surface.set_meta("theme_decoration", true)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(surface, false, Node.INTERNAL_MODE_FRONT)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return surface
