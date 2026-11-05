extends RefCounted
## Read-only presentation: real maximum HP and a separate bounded shield segment.
static func capacity(data:Dictionary) -> float:
	return maxf(1,float(data.max_hp)+maxf(0,float(data.get("shield",0))))
static func tint(data:Dictionary) -> Color:return TaleTheme.c("bar_health")
static func readout(label:Label) -> void:
	label.set_meta("bar_readout",true)
	label.set_meta("theme_text_role","bar_text")
	label.add_theme_font_override("font",TaleTheme.NUMERIC)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_constant_override("outline_size",2)
	label.add_theme_constant_override("shadow_offset_y",1)
	label.add_theme_color_override("font_color",TaleTheme.c("bar_text"))
	label.add_theme_color_override("font_outline_color",TaleTheme.c("bar_outline"))
	label.add_theme_color_override("font_shadow_color",TaleTheme.c("bar_outline"))
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
static func shield_icon(label:Label) -> void:
	if label.has_node("ShieldIcon"):return
	var icon:=preload("res://scripts/shield_icon.gd").new()
	icon.name="ShieldIcon"
	icon.position=Vector2(2,5)
	icon.size=Vector2(16,16)
	label.add_child(icon)
static func update(bar:ProgressBar,data:Dictionary) -> void:
	bar.set_meta("health_bar",true)
	var color:=TaleTheme.c("bar_enemy" if bar.get_meta("hostile",false) else "bar_health")
	var fill:=bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill==null or fill.bg_color!=color:
		fill=StyleBoxFlat.new()
		fill.bg_color=color
		bar.add_theme_stylebox_override("fill",fill)
	var shield:=maxf(0,float(data.get("shield",0)))
	var total:=capacity(data)
	bar.max_value=total
	bar.tooltip_text="%d / %d · Escudo %d"%[ceili(data.hp),ceili(data.max_hp),ceili(shield)]
	var segment:=bar.get_node_or_null("ShieldSegment") as ColorRect
	if segment==null:
		segment=ColorRect.new()
		segment.name="ShieldSegment"
		segment.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_child(segment)
	segment.color=TaleTheme.c("bar_shield")
	segment.visible=shield>0 and data.hp>0
	var start:=clampf(float(data.hp)/total,0,1)
	var fraction:=clampf(shield/total,0,1-start)
	var target:=[maxf(0,float(data.hp))+shield,start,fraction,bar.size]
	if bar.get_meta("display_target",[])==target:return
	var initialized:=bar.has_meta("display_target")
	bar.set_meta("display_target",target)
	var old=bar.get_meta("display_tween") if bar.has_meta("display_tween") else null
	if old is Tween and old.is_valid():old.kill()
	if initialized and bar.is_inside_tree():
		var tween:=bar.create_tween().set_parallel(true)
		tween.tween_property(bar,"value",target[0],.2)
		tween.tween_property(segment,"position",Vector2(bar.size.x*start,1),.2)
		tween.tween_property(segment,"size",Vector2(bar.size.x*fraction,maxf(0,bar.size.y-2)),.2)
		bar.set_meta("display_tween",tween)
	else:
		bar.value=target[0]
		segment.position=Vector2(bar.size.x*start,1)
		segment.size=Vector2(bar.size.x*fraction,maxf(0,bar.size.y-2))
