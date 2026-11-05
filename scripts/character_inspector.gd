extends Control
const Details=preload("res://scripts/combat_details.gd")
const SkillArt=preload("res://scripts/skill_art.gd")
const Preview=preload("res://scripts/skill_preview.gd")
const Content=preload("res://scripts/expedition_content.gd")
const InspectorSkin=preload("res://scripts/ui_skin.gd")
const Rules=preload("res://scripts/combat_rules.gd")
const Icon=preload("res://scripts/mobile_icon.gd")
var GOLD: Color:
	get: return TaleTheme.c("accent")
var ui:Control
var actor:Dictionary
var built_size:=Vector2.ZERO
var board:Panel
var detail:PanelContainer
var pinned:=false
var detail_key:=""
var detail_hosts:Dictionary={}
var shell:Control
func setup(owner_ui:Control,unit:Dictionary) -> void:
	ui=owner_ui
	actor=unit.duplicate(true)
	name="CharacterInspector"
	set_meta("character_inspector",true)
	set_meta("viewport_modal",true)
	z_index=3000
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(rebuild)
	rebuild()
func style() -> StyleBoxFlat:
	var result:=StyleBoxFlat.new()
	result.bg_color=TaleTheme.c("surface")
	result.border_color=TaleTheme.c("border")
	result.set_border_width_all(1)
	result.set_corner_radius_all(8)
	return result
func frame(parent:Node,rect:Rect2,tint:=TaleTheme.c("surface")) -> Panel:
	var p:=Panel.new()
	p.position=rect.position
	p.size=rect.size
	var skin:=style()
	skin.bg_color=tint
	p.add_theme_stylebox_override("panel",skin)
	parent.add_child(p)
	return p
func text(parent:Node,value:String,rect:Rect2,points:int,color:=TaleTheme.c("text")) -> Label:
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
func icon(parent:Node,glyph:String,at:Vector2,extent:=28.0,tint:= TaleTheme.c("accent")) -> void:
	var image:=Icon.new()
	image.glyph=glyph
	image.tint=tint
	if tint==TaleTheme.c("physical"):image.set_meta("theme_icon_role","physical")
	elif tint==TaleTheme.c("magical"):image.set_meta("theme_icon_role","magical")
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
	if not tap:return
	if pinned and detail_key==key:
		hide_detail()
		return
	hide_detail()
	if not detail_hosts.has(key):return
	pinned=true
	detail_key=key
	detail=PanelContainer.new()
	detail.name="SkillDescription"
	detail.set_meta("inline_information",true)
	var skin:=style()
	skin.set_content_margin_all(10)
	detail.add_theme_stylebox_override("panel",skin)
	detail_hosts[key].add_child(detail)
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.custom_minimum_size.x=1
	detail.add_child(column)
	var close:=Button.new()
	close.text=title+"   ×"
	close.custom_minimum_size=Vector2(1,36)
	close.clip_text=true
	close.pressed.connect(hide_detail)
	column.add_child(close)
	var content:=RichTextLabel.new()
	content.name="InlineDescription"
	content.text=body
	content.bbcode_enabled=false
	content.fit_content=true
	content.scroll_active=false
	content.custom_minimum_size.x=1
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size",14)
	column.add_child(content)
	reveal_detail.call_deferred()
func reveal_detail() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(detail):shell.scroll.ensure_control_visible(detail)
func bind_detail(button:Button,key:String,title:String,body:String) -> void:
	button.pressed.connect(func():show_detail(key,title,body,true))
func rebuild() -> void:
	if ui==null or size.x<1 or size==built_size:return
	built_size=size
	hide_detail()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	detail_hosts.clear()
	shell=preload("res://scripts/modal_shell.gd").new()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup("Ficha do Viajante",TaleCatalog.HEROES[actor.id].name+" · "+TaleCatalog.hero_class_name(actor.id))
	shell.scroll.name="SkillScroll"
	shell.full_height=true
	shell.layout()
	board=shell.board
	var wide:=size.x>=900
	var top:=HBoxContainer.new()
	top.name="AttributesAndPortrait"
	top.add_theme_constant_override("separation",12)
	shell.body.add_child(top)
	var stats_column:=VBoxContainer.new()
	stats_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stats_column.custom_minimum_size.x=1
	top.add_child(stats_column)
	var attributes:=GridContainer.new()
	attributes.name="Attributes"
	attributes.columns=4 if wide else 3
	attributes.add_theme_constant_override("h_separation",6)
	attributes.add_theme_constant_override("v_separation",6)
	stats_column.add_child(attributes)
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
	for stat in stats:
		var cell:=Button.new()
		cell.set_meta("stat",stat[0])
		cell.custom_minimum_size=Vector2(1,64)
		cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		attributes.add_child(cell)
		var inset:=MarginContainer.new()
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inset.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,5)
		cell.add_child(inset)
		var column:=VBoxContainer.new()
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		inset.add_child(column)
		text(column,stat[0],Rect2(),11,GOLD)
		var value:=text(column,stat[2],Rect2(),14 if wide else 12)
		value.custom_minimum_size.x=1
		detail_hosts[str(stat[0])]=stats_column
		bind_detail(cell,str(stat[0]),str(stat[0]),str(stat[3]))
	var source:Dictionary=preload("res://scripts/hero_art.gd").body(actor.id)
	var texture:=AtlasTexture.new()
	texture.atlas=source.texture
	texture.region=source.bounds
	texture.filter_clip=true
	var portrait:=TextureRect.new()
	portrait.name="CharacterArt"
	portrait.texture=texture
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size=Vector2(250,300) if wide else Vector2(90,240)
	portrait.flip_h=true
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	top.add_child(portrait)
	var grid:=GridContainer.new()
	grid.name="AbilityGrid"
	grid.columns=1
	grid.add_theme_constant_override("v_separation",10)
	shell.body.add_child(grid)
	var titles:Array=[Content.KITS[actor.id][0],Content.KITS[actor.id][2],TaleCatalog.HERO_TACTICS[actor.id].ult]
	for kind in 3:skill_card(grid,kind,str(titles[kind]),wide)
	var bonus_lines:Array[String]=[]
	for key in actor.get("bonus_totals",{}):
		var value:float=Rules.Bonuses.total(actor,key)
		if is_zero_approx(value):continue
		var percent:bool=key in Rules.Bonuses.PERCENT
		var suffix:=" pp" if key in ["crit","crit_multiplier","evasion"] else "%" if percent else ""
		bonus_lines.append("%s  %s%s%s"%[Rules.Bonuses.NAMES.get(key,key),"+" if value>0 else "",Details.n(value*100 if percent else value),suffix])
	info_card(shell.body,"BÔNUS DA RUN"," · ".join(bonus_lines) if not bonus_lines.is_empty() else "Nenhum bônus adquirido.")
	var gear_lines:Array[String]=[]
	for id in actor.get("equipment",[]):
		var item:=preload("res://scripts/equipment.gd").data(id)
		if not item.is_empty():gear_lines.append(item.title+" · "+item.detail)
	info_card(shell.body,"EQUIPAMENTOS · 2 ESPAÇOS","\n\n".join(gear_lines) if not gear_lines.is_empty() else "Nenhum equipamento.")
	if int(actor.get("blessing_index",-1))>=0 and ui.run!=null:
		var boon:=preload("res://scripts/hero_blessings.gd").data(ui.run.blessing)
		if not boon.is_empty():info_card(shell.body,"BÊNÇÃO · "+boon.title,boon.detail)
	if not Details.conditions(actor).is_empty():info_card(shell.body,"CONDIÇÕES ATIVAS",Details.conditions(actor))
	var back:=Button.new()
	back.text="Voltar ao combate"
	back.custom_minimum_size=Vector2(1,48)
	back.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	back.pressed.connect(ui.close_character_information)
	shell.footer.add_child(back)
	shell.layout()
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
	skin.bg_color=TaleTheme.c("surface")
	skin.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel",skin)
	grid.add_child(card)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	card.add_child(row)
	var picture:=TextureRect.new()
	picture.name="AbilityPicture"
	picture.texture=SkillArt.texture(actor.id,kind)
	picture.custom_minimum_size=Vector2(64,64) if wide else Vector2(36,36)
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
	var short_text:=text(lines,Preview.SHORT[actor.id][kind],Rect2(),13 if wide else 12,TaleTheme.c("muted"))
	short_text.name="AbilityDescription"
	short_text.custom_minimum_size.x=1
	short_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var summary:=RichTextLabel.new()
	summary.name="AbilitySummary"
	summary.set_meta("combat_readout",true)
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
	info.custom_minimum_size=Vector2(32,32)
	info.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var info_style:=style()
	info_style.bg_color=TaleTheme.c("surface")
	info_style.border_color=TaleTheme.c("magical")
	info_style.set_corner_radius_all(0)
	info_style.set_content_margin_all(0)
	for state in ["normal","hover","pressed","focus"]:info.add_theme_stylebox_override(state,info_style)
	info.add_theme_color_override("font_color",TaleTheme.c("magical"))
	info.add_theme_font_size_override("font_size",20)
	detail_hosts["skill%d"%kind]=lines
	info.pressed.connect(func():show_detail("skill%d"%kind,title,data.detail,true))
	var info_margin:=MarginContainer.new()
	info_margin.name="InfoMargin"
	info_margin.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for edge in ["left","right","top","bottom"]:info_margin.add_theme_constant_override("margin_"+edge,5)
	row.add_child(info_margin)
	info_margin.add_child(info)
