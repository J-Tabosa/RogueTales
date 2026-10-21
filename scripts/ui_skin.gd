class_name TaleSkin
extends RefCounted
## Generated artwork, shared textures and native nine-patch borders. No per-frame UI work.
const PANEL = preload("res://assets/ui/wood_panel.png")
const BUTTON = preload("res://assets/ui/wood_button.png")
const WALLET = preload("res://assets/ui/gold_wallet.png")
const LOGO = preload("res://assets/ui/logo.png")
const FOREST = preload("res://assets/ui/enchanted_forest.png")
const MAP = preload("res://assets/ui/world_map.png")
static var atlases: Dictionary = {}


static func artwork(key: String) -> Texture2D:
	if atlases.has(key):
		return atlases[key]
	var source: Texture2D
	var source_size: Vector2
	var region: Rect2
	match key:
		"button":
			source = BUTTON
			source_size = Vector2(2148, 732)
			region = Rect2(16, 102, 2116, 463)
		"wallet":
			source = WALLET
			source_size = Vector2(2057, 765)
			region = Rect2(16, 102, 2020, 532)
		"logo":
			source = LOGO
			source_size = Vector2(1983, 793)
			region = Rect2(0, 110, 1983, 560)
		_:
			return PANEL
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var ratio := source.get_size() / source_size
	atlas.region = Rect2(region.position * ratio, region.size * ratio)
	atlas.filter_clip = true
	atlases[key] = atlas
	return atlas


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


static func decorate(node: Control, button_style := false, frame_only := false) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.texture = artwork("button") if button_style else PANEL
	patch.draw_center = not frame_only
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.show_behind_parent = not frame_only
	var texture_size := patch.texture.get_size()
	# Scale the drawing coordinate system, preserving high-resolution source corners.
	# The border stays thin at any card size; the source PNG is never resampled in code.
	var factor := 0.075 if button_style else 0.065
	patch.scale = Vector2.ONE * factor
	patch.patch_margin_left = int(texture_size.x * (0.12 if button_style else 0.18))
	patch.patch_margin_right = patch.patch_margin_left
	patch.patch_margin_top = int(texture_size.y * (0.18 if button_style else 0.18))
	patch.patch_margin_bottom = patch.patch_margin_top
	node.add_child(patch)
	var fit := func(): patch.size = node.size / factor
	node.resized.connect(fit)
	fit.call()
	return patch
