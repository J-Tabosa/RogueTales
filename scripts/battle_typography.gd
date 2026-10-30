extends RefCounted
const BODY = preload("res://assets/fonts/goldman/Goldman-Regular.ttf")
const STRONG = preload("res://assets/fonts/goldman/Goldman-Bold.ttf")
static func font(bold := false) -> Font:
	return STRONG if bold else BODY
static func apply(node: Control, bold := false) -> void:
	node.add_theme_font_override("font",font(bold))
	node.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
	node.add_theme_constant_override("outline_size",0)

static func fit_line(node: Label, preferred: int, minimum := 9, bounds := Vector2.ZERO) -> void:
	# Measure the actual font; changing resolutions or the number of gold digits
	# must not push the label beyond the interior of its frame.
	var extent:Vector2=bounds if bounds.x>0 else node.size
	var key:="%s:%s:%d"%[node.text,extent,preferred]
	if node.get_meta("line_fit","")==key:
		node.size=extent
		return
	node.set_meta("line_fit",key)
	var face := node.get_theme_font("font")
	var point_size := preferred
	while point_size > minimum and (face.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x > extent.x - 2 or face.get_height(point_size) > extent.y):
		point_size -= 1
	node.add_theme_font_size_override("font_size",point_size)
	# A label enlarged by its previous font does not shrink automatically when
	# the font changes. Restore its intended box after shaping the smaller font.
	node.size=extent
