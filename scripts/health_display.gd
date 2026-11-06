extends RefCounted
## Shields extend the visible capacity without changing the unit's actual maximum HP.
static func capacity(data:Dictionary) -> float:
	return float(data.max_hp)+maxf(0,float(data.get("shield",0)))
static func tint(data:Dictionary) -> Color:
	var ratio:=clampf(float(data.hp)/maxf(1,float(data.max_hp)),0,1)
	if ratio>.8:return TaleTheme.c("health_full")
	if ratio>.6:return TaleTheme.c("health_high")
	if ratio>.4:return TaleTheme.c("health_half")
	if ratio>.2:return TaleTheme.c("health_low")
	return TaleTheme.c("health_critical")
static func update(bar:ProgressBar,data:Dictionary) -> void:
	bar.set_meta("health_bar",true)
	var color:=tint(data)
	var fill:=bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill==null or fill.bg_color!=color or fill.border_color!=color:
		fill=fill.duplicate() if fill!=null else StyleBoxFlat.new()
		fill.bg_color=color
		fill.border_color=color
		fill.set_corner_radius_all(int(bar.get_meta("theme_radius",3)))
		bar.add_theme_stylebox_override("fill",fill)
	var shield:=maxf(0,float(data.get("shield",0)))
	var total:=maxf(1,capacity(data))
	bar.max_value=total
	bar.value=maxf(0,float(data.hp))+shield
	bar.tooltip_text="PV %d/%d · Escudo %d"%[ceili(data.hp),ceili(data.max_hp),ceili(shield)]
	var segment:=bar.get_node_or_null("ShieldSegment") as Panel
	if segment==null:
		segment=Panel.new()
		segment.name="ShieldSegment"
		segment.set_meta("theme_decoration",true)
		segment.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_child(segment)
	if segment.get_theme_stylebox("panel").get_meta("theme_generation",-1)!=TaleTheme.generation:
		var shield_style:=TaleTheme.flat("shield","combat_border",int(bar.get_meta("theme_radius",3)))
		shield_style.set_content_margin_all(0)
		shield_style.set_border_width_all(0)
		segment.add_theme_stylebox_override("panel",shield_style)
	segment.position=Vector2(bar.size.x*maxf(0,data.hp)/total,0)
	segment.size=Vector2(bar.size.x*shield/total,bar.size.y)
	segment.visible=shield>0 and data.hp>0
