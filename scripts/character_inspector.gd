extends Control
const Details=preload("res://scripts/combat_details.gd")
const SkillArt=preload("res://scripts/skill_art.gd")
const Preview=preload("res://scripts/skill_preview.gd")
const Content=preload("res://scripts/expedition_content.gd")
const InspectorSkin=preload("res://scripts/ui_skin.gd")
const Rules=preload("res://scripts/combat_rules.gd")
const Icon=preload("res://scripts/mobile_icon.gd")
const GOLD=Color("f2d28e")
var ui:Control
var actor:Dictionary
var built_size:=Vector2.ZERO
var board:Panel
var detail:PanelContainer
var pinned:=false
var detail_key:=""
func setup(owner_ui:Control,unit:Dictionary) -> void:
	ui=owner_ui
	actor=unit.duplicate(true)
	name="CharacterInspector"
	set_meta("character_inspector",true)
	z_index=3000
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(rebuild)
	rebuild()
func style() -> StyleBoxFlat:
	var result:=StyleBoxFlat.new()
	result.bg_color=Color("19332e")
	result.border_color=Color("796344")
	result.set_border_width_all(1)
	result.set_corner_radius_all(8)
	return result
func frame(parent:Node,rect:Rect2,tint:=Color("19332e")) -> Panel:
	var p:=Panel.new()
	p.position=rect.position
	p.size=rect.size
	var skin:=style()
	skin.bg_color=tint
	p.add_theme_stylebox_override("panel",skin)
	parent.add_child(p)
	return p
func text(parent:Node,value:String,rect:Rect2,points:int,color:=Color("eee9da")) -> Label:
	var l:=Label.new()
	l.text=value
	l.position=rect.position
	l.size=rect.size
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",points)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
func icon(parent:Node,glyph:String,at:Vector2,extent:=28.0,tint:=GOLD) -> void:
	var image:=Icon.new()
	image.glyph=glyph
	image.tint=tint
	image.position=at
	image.size=Vector2.ONE*extent
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
func _input(event:InputEvent) -> void:
	if not pinned or not is_instance_valid(detail):return
	var point:=Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		point=event.position
	elif event is InputEventScreenTouch and event.pressed:
		point=event.position
	else:return
	if detail.get_global_rect().has_point(point):return
	# Let the same information button toggle, or another information button switch.
	for button in find_children("SkillInfo*","Button",true,false):
		if button.get_global_rect().has_point(point):return
	hide_detail()
func hide_detail() -> void:
	if is_instance_valid(detail):
		# Detach immediately; a queued, still-interactive popup can swallow the next tap.
		if detail.get_parent()!=null:detail.get_parent().remove_child(detail)
		detail.queue_free()
	detail=null
	pinned=false
	detail_key=""
func show_detail(key:String,title:String,body:String,tap:=false) -> void:
	if tap and pinned and detail_key==key:
		hide_detail()
		return
	if pinned and not tap:return
	hide_detail()
	pinned=tap
	detail_key=key
	detail=PanelContainer.new()
	detail.name="SkillDescription"
	detail.z_index=20
	var extent:=Vector2(minf(board.size.x-32,470),minf(board.size.y-100,290))
	detail.position=Vector2(clampf(get_local_mouse_position().x-board.position.x+12,16,board.size.x-extent.x-16),board.size.y-extent.y-66)
	detail.size=extent
	detail.mouse_filter=Control.MOUSE_FILTER_STOP if tap else Control.MOUSE_FILTER_IGNORE
	var skin:=style()
	skin.bg_color=Color("0d252b")
	skin.border_color=Color("64c7ff")
	skin.set_content_margin_all(12)
	detail.add_theme_stylebox_override("panel",skin)
	board.add_child(detail)
	var column:=VBoxContainer.new()
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	detail.add_child(column)
	var close:=Button.new()
	close.mouse_filter=Control.MOUSE_FILTER_STOP if tap else Control.MOUSE_FILTER_IGNORE
	close.text=title+"   ×"
	close.custom_minimum_size.y=36
	close.pressed.connect(hide_detail)
	column.add_child(close)
	var content:=RichTextLabel.new()
	content.mouse_filter=Control.MOUSE_FILTER_STOP if tap else Control.MOUSE_FILTER_IGNORE
	content.text=body
	content.bbcode_enabled=false
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size",15)
	column.add_child(content)
func bind_detail(button:Button,key:String,title:String,body:String) -> void:
	button.mouse_entered.connect(func():show_detail(key,title,body))
	button.mouse_exited.connect(func():
		if not pinned:hide_detail())
	button.focus_entered.connect(func():show_detail(key,title,body))
	button.pressed.connect(func():show_detail(key,title,body,true))
func rebuild() -> void:
	if ui==null or size.x<1 or size==built_size:return
	built_size=size
	hide_detail()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade:=ColorRect.new()
	shade.color=Color(.015,.035,.035,.95)
	shade.size=size
	add_child(shade)
	var wide:=size.x>=900
	var bw:=minf(size.x-24,1120)
	var bh:=minf(size.y-24,760)
	board=frame(self,Rect2((size-Vector2(bw,bh))*.5,Vector2(bw,bh)),Color("102421"))
	InspectorSkin.decorate(board,false,true,.075)
	text(board,"FICHA DO VIAJANTE",Rect2(20,14,bw-90,20),11,GOLD)
	text(board,TaleCatalog.HEROES[actor.id].name,Rect2(20,38,bw-150,40),25 if wide else 21)
	text(board,TaleCatalog.hero_class_name(actor.id),Rect2(20,80,bw-160,24),13,Color("b8c6b5"))
	var close:=Button.new()
	close.text="×"
	close.position=Vector2(bw-62,16)
	close.size=Vector2(44,44)
	close.pressed.connect(ui.close_character_information)
	board.add_child(close)
	var stats_w:=bw-360 if wide else bw-40
	var stats:Array=[
		["AP","magic",Details.n(Rules.power(actor,true)),"Dano Mágico atual"],
		["AD","sword",Details.n(Rules.power(actor,false)),"Dano Físico atual"],
		["DEF","shield",Details.n(Rules.defense(actor,false)),"Defesa Física em pontos"],
		["RES","mirror",Details.n(Rules.defense(actor,true)),"Defesa Mágica em pontos"],
		["HP","heart","%d/%d"%[ceili(actor.hp),ceili(actor.max_hp)],"Vida atual / máxima · Escudo: "+Details.n(actor.shield)],
		["ESQ","heroes","%.0f%%"%(Rules.Bonuses.evasion(actor)*100),"Chance de esquiva · teto comum de 80%"],
		["QTD","blast_pair",str(Rules.Bonuses.attacks(actor)),"Ataques básicos por vez"],
		["MAN","potion",Rules.resource(actor),"Recurso · +%s por acerto · +%s por vez"%[Details.n(Rules.Bonuses.mana_hit(actor)),Details.n(Rules.Bonuses.mana_turn(actor))]],
		["CRIT","flame","×%.2f"%Rules.Bonuses.critical_multiplier(actor),"Multiplicador de dano crítico"],
		["TAXA","target","%.0f%%"%(Rules.Bonuses.chance(actor)*100),"Chance de acerto crítico"],
		["INI","clock","%.0f"%Rules.effective_initiative(actor),"Iniciativa · ordem de ação"]]
	var cols:=6 if wide else 4 if bw>=440 else 3
	var ch:=58.0 if wide else 48.0
	var cw:=(stats_w-6*(cols-1))/cols
	for i in stats.size():
		var stat:Array=stats[i]
		var cell:=Button.new()
		cell.position=Vector2(20+(i%cols)*(cw+6),116+floori(i/float(cols))*(ch+6))
		cell.size=Vector2(cw,ch)
		cell.set_meta("stat",stat[0])
		cell.add_theme_stylebox_override("normal",style())
		board.add_child(cell)
		icon(cell,stat[1],Vector2(6,5),19,Color("64c7ff") if stat[0]=="AP" else Color("ff6969") if stat[0]=="AD" else GOLD)
		text(cell,stat[0],Rect2(28,4,cw-31,19),10,GOLD)
		text(cell,stat[2],Rect2(6,25,cw-12,ch-25),12 if cw<100 else 15)
		bind_detail(cell,str(stat[0]),str(stat[0]),str(stat[3]))
	var sy:=116+ceili(stats.size()/float(cols))*(ch+6)+8
	var content_w:=stats_w if wide else (stats_w-12)*.60
	var art_rect:=Rect2(stats_w+32,116,bw-stats_w-52,bh-192) if wide else Rect2(32+content_w,sy,bw-content_w-52,bh-sy-74)
	var art:=frame(board,art_rect,Color("24372e"))
	art.name="CharacterArt"
	art.clip_contents=true
	ui.banner_portrait(art,actor.id,Rect2(6,6,art.size.x-12,art.size.y-12),false)
	var portrait:=art.get_node_or_null("HeroArt") as Sprite2D
	if portrait!=null:
		var bounds:Rect2=preload("res://scripts/hero_art.gd").body(actor.id).bounds
		portrait.position.x+=2*bounds.get_center().x*portrait.scale.x
		portrait.scale.x=-portrait.scale.x
	var scroll:=ScrollContainer.new()
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.name="SkillScroll"
	scroll.position=Vector2(20,sy)
	scroll.size=Vector2(content_w,bh-sy-74)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone=10
	board.add_child(scroll)
	var stack:=VBoxContainer.new()
	stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",8)
	scroll.add_child(stack)
	var skills:=PanelContainer.new()
	var skill_skin:=style()
	skill_skin.set_content_margin_all(8)
	skills.add_theme_stylebox_override("panel",skill_skin)
	stack.add_child(skills)
	var skill_column:=VBoxContainer.new()
	skill_column.add_theme_constant_override("separation",8)
	skills.add_child(skill_column)
	text(skill_column,"HABILIDADES",Rect2(),11,GOLD)
	var grid:=GridContainer.new()
	grid.name="AbilityGrid"
	grid.columns=1
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	skill_column.add_child(grid)
	var titles:Array=[Content.KITS[actor.id][0],Content.KITS[actor.id][2],TaleCatalog.HERO_TACTICS[actor.id].ult]
	for kind in 3:skill_card(grid,kind,str(titles[kind]),wide)
	var bonus_lines:Array[String]=[]
	for key in actor.get("bonus_totals",{}):
		var value:float=Rules.Bonuses.total(actor,key)
		if is_zero_approx(value):continue
		var percent:bool=key in Rules.Bonuses.PERCENT
		var suffix:=" pp" if key in ["crit","crit_multiplier","evasion"] else "%" if percent else ""
		bonus_lines.append("%s  %s%s%s"%[Rules.Bonuses.NAMES.get(key,key),"+" if value>0 else "",Details.n(value*100 if percent else value),suffix])
	info_card(stack,"BÔNUS DA RUN"," · ".join(bonus_lines) if not bonus_lines.is_empty() else "Nenhum bônus adquirido.")
	var gear_lines:Array[String]=[]
	for id in actor.get("equipment",[]):
		var item:=preload("res://scripts/equipment.gd").data(id)
		if not item.is_empty():gear_lines.append(item.title+" · "+item.detail)
	info_card(stack,"EQUIPAMENTOS · 2 ESPAÇOS","\n\n".join(gear_lines) if not gear_lines.is_empty() else "Nenhum equipamento.")
	if int(actor.get("blessing_index",-1))>=0 and ui.run!=null:
		var boon:=preload("res://scripts/hero_blessings.gd").data(ui.run.blessing)
		if not boon.is_empty():info_card(stack,"BÊNÇÃO · "+boon.title,boon.detail)
	if not Details.conditions(actor).is_empty():info_card(stack,"CONDIÇÕES ATIVAS",Details.conditions(actor))
	var back:=Button.new()
	back.text="Voltar ao combate"
	back.position=Vector2(20,bh-54)
	back.size=Vector2(bw-40,42)
	back.pressed.connect(ui.close_character_information)
	InspectorSkin.decorate(back,true,false,.09)
	board.add_child(back)
func info_card(stack:VBoxContainer,title:String,body:String) -> void:
	var card:=PanelContainer.new()
	card.set_meta("skill",title)
	var skin:=style()
	skin.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel",skin)
	stack.add_child(card)
	var column:=VBoxContainer.new()
	card.add_child(column)
	text(column,title,Rect2(),11,GOLD)
	var value:=text(column,body,Rect2(),14)
	value.custom_minimum_size.x=1
	value.size_flags_horizontal=Control.SIZE_EXPAND_FILL

func skill_card(grid:GridContainer,kind:int,title:String,wide:bool) -> void:
	var data:=Preview.preview(actor,kind)
	var card:=PanelContainer.new()
	card.name="Skill%d"%kind
	card.set_meta("skill",["AUTOMÁTICA","PASSIVA","ESPECIAL"][kind])
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.custom_minimum_size=Vector2(1,100)
	var skin:=style()
	skin.bg_color=Color("122d28")
	skin.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel",skin)
	grid.add_child(card)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	card.add_child(row)
	var picture:=TextureRect.new()
	picture.name="AbilityPicture"
	picture.texture=SkillArt.texture(actor.id,kind)
	picture.custom_minimum_size=Vector2(64,64) if wide else Vector2(52,52)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var lines:=VBoxContainer.new()
	lines.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	lines.custom_minimum_size.x=1
	lines.add_theme_constant_override("separation",5)
	row.add_child(lines)
	var name_label:=text(lines,title+" · "+["Básico","Passiva","Especial" if actor.id=="aladin" else "Habilidade"][kind],Rect2(),16 if wide else 14)
	name_label.custom_minimum_size.x=1
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var short_text:=text(lines,Preview.SHORT[actor.id][kind],Rect2(),13 if wide else 12,Color("b8c6b5"))
	short_text.name="AbilityDescription"
	short_text.custom_minimum_size.x=1
	short_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var summary:=RichTextLabel.new()
	summary.name="AbilitySummary"
	summary.bbcode_enabled=true
	summary.text=data.summary
	summary.fit_content=true
	summary.scroll_active=false
	summary.custom_minimum_size.x=1
	summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	summary.mouse_filter=Control.MOUSE_FILTER_IGNORE
	summary.add_theme_font_size_override("normal_font_size",13)
	lines.add_child(summary)
	var info:=Button.new()
	info.name="SkillInfo%d"%kind
	info.text="i"
	info.tooltip_text="Ver descrição e cálculo"
	info.set_meta("skill_info",kind)
	info.custom_minimum_size=Vector2(44,44)
	info.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var info_style:=style()
	info_style.bg_color=Color("102c31")
	info_style.border_color=Color("64c7ff")
	info_style.set_corner_radius_all(0)
	info_style.set_content_margin_all(0)
	for state in ["normal","hover","pressed","focus"]:info.add_theme_stylebox_override(state,info_style)
	info.add_theme_color_override("font_color",Color("64c7ff"))
	info.add_theme_font_size_override("font_size",20)
	info.pressed.connect(func():show_detail("skill%d"%kind,title,data.detail,true))
	var info_margin:=MarginContainer.new()
	info_margin.name="InfoMargin"
	info_margin.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for edge in ["left","right","top","bottom"]:info_margin.add_theme_constant_override("margin_"+edge,5)
	row.add_child(info_margin)
	info_margin.add_child(info)
