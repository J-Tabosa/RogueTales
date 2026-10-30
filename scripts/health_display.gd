extends RefCounted
## Shields extend the visible capacity without changing the unit's actual maximum HP.
static func capacity(data:Dictionary) -> float:
	return float(data.max_hp)+maxf(0,float(data.get("shield",0)))
static func tint(data:Dictionary) -> Color:
	var ratio:=clampf(float(data.hp)/maxf(1,float(data.max_hp)),0,1)
	if ratio>.8:return Color("67cf85")
	if ratio>.6:return Color("c5e85a")
	if ratio>.4:return Color("f2d36b")
	if ratio>.2:return Color("f5a052")
	return Color("64b5ff")
static func update(bar:ProgressBar,data:Dictionary) -> void:
	var color:=tint(data)
	var fill:=bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill==null or fill.bg_color!=color:
		fill=fill.duplicate() if fill!=null else StyleBoxFlat.new()
		fill.bg_color=color
		bar.add_theme_stylebox_override("fill",fill)
	var shield:=maxf(0,float(data.get("shield",0)))
	var total:=maxf(1,capacity(data))
	bar.max_value=total
	bar.value=maxf(0,float(data.hp))+shield
	bar.tooltip_text="PV %d/%d · Escudo %d"%[ceili(data.hp),ceili(data.max_hp),ceili(shield)]
	var segment:=bar.get_node_or_null("ShieldSegment") as ColorRect
	if segment==null:
		segment=ColorRect.new()
		segment.name="ShieldSegment"
		segment.mouse_filter=Control.MOUSE_FILTER_IGNORE
		segment.color=Color("8ddbee")
		bar.add_child(segment)
	segment.position=Vector2(bar.size.x*maxf(0,data.hp)/total,0)
	segment.size=Vector2(bar.size.x*shield/total,bar.size.y)
	segment.visible=shield>0 and data.hp>0
