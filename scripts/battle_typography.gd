extends RefCounted
const BODY = preload("res://assets/fonts/Nunito-Semibold.ttf")
const STRONG = preload("res://assets/fonts/Nunito-Extrabold.ttf")
static func font(bold := false) -> Font:
	return STRONG if bold else BODY
static func apply(node: Control, bold := false) -> void:
	node.add_theme_font_override("font",font(bold))
	node.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
	node.add_theme_constant_override("outline_size",0)
