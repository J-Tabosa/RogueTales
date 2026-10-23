extends Control
const Details=preload("res://scripts/combat_details.gd")
const Content=preload("res://scripts/expedition_content.gd")
const InspectorSkin=preload("res://scripts/ui_skin.gd")
const GOLD=Color("f2d28e")
var ui: Control
var actor: Dictionary
var built_size:=Vector2.ZERO
func setup(owner_ui: Control,unit: Dictionary) -> void:
	ui=owner_ui
	actor=unit.duplicate(true)
	name="CharacterInspector"
	set_meta("character_inspector",true)
	z_index=3000
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(rebuild)
	rebuild()
func frame(parent: Node,rect: Rect2,tint:=Color("19332e")) -> Panel:
	var p:=Panel.new()
	p.position=rect.position
	p.size=rect.size
	var style:=StyleBoxFlat.new()
	style.bg_color=tint
	style.border_color=Color("796344")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p
func text(parent: Node,value: String,rect: Rect2,points: int,color:=Color("eee9da")) -> Label:
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
func rebuild() -> void:
	if ui==null or size.x<1 or size==built_size:return
	built_size=size
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade:=ColorRect.new()
	shade.color=Color(.015,.035,.035,.95)
	shade.size=size
	add_child(shade)
	var wide:=size.x>=900
	var bw:=minf(size.x-24,1120)
	var bh:=minf(size.y-24,930 if not wide else 760)
	var board:=frame(self,Rect2((size-Vector2(bw,bh))*.5,Vector2(bw,bh)),Color("102421"))
	InspectorSkin.decorate(board,false,true,.075)
	text(board,"FICHA DO VIAJANTE",Rect2(24,18,bw-90,22),12,GOLD)
	text(board,TaleCatalog.HEROES[actor.id].name,Rect2(24,43,bw-90,43),27 if wide else 24)
	text(board,TaleCatalog.hero_class_name(actor.id)+" · atributos desta run",Rect2(24,87,bw-48,27),13,Color("b8c6b5"))
	var close:=Button.new()
	close.text="×"
	close.position=Vector2(bw-66,24)
	close.size=Vector2(44,44)
	close.pressed.connect(ui.close_character_information)
	InspectorSkin.decorate(close,true,true,.04)
	board.add_child(close)
	var stats_w:=bw-374 if wide else bw-242
	var stats_h:=172.0 if wide else 272.0
	var art_x:=stats_w+38
	var art_w:=bw-art_x-24
	var art:=frame(board,Rect2(art_x,128,art_w,bh-202 if wide else stats_h),Color("24372e"))
	art.name="CharacterArt"
	InspectorSkin.decorate(art,false,true,.035)
	ui.banner_portrait(art,actor.id,Rect2(12,20,art_w-24,art.size.y-45),false)
	text(art,TaleCatalog.hero_class_name(actor.id),Rect2(8,art.size.y-29,art_w-16,22),11,GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var interval:float=maxf(1.5,actor.interval*1.25)*(1.3 if int(actor.get("hindered_rounds",0))>0 else 1.0)
	var cells:Array=[["VIDA","%d / %d"%[ceili(actor.hp),ceili(actor.max_hp)],"Escudo: %d"%ceili(actor.shield)],["MANA","%d / 100"%int(actor.energy),"+1,4/s · +%s/acerto"%Details.n(18+actor.energy_bonus)],["AUTO-ATAQUE",Details.n(actor.damage),"dano bruto"],["INTERVALO","%.2f s"%interval,"mínimo em 1×"],["ARMADURA",Details.n(actor.armor),"redução por golpe"],["CRÍTICO","%.0f%%"%(actor.crit*100),"2× dano"],["ESQUIVA","%.0f%%"%(float(actor.get("evasion",0))*100),"chance por golpe"],["CURA / ACERTO",Details.n(actor.leech),"PV recuperados"]]
	var cols:=4 if wide else 2
	var cw:=(stats_w-8*(cols-1))/cols
	var ch:=82.0 if wide else 62.0
	for i in cells.size():
		var cell:=frame(board,Rect2(24+(i%cols)*(cw+8),128+floori(i/float(cols))*(ch+8),cw,ch))
		cell.set_meta("stat",cells[i][0])
		text(cell,cells[i][0],Rect2(9,5,cw-18,16),10,GOLD)
		text(cell,cells[i][1],Rect2(9,22,cw-18,27),20 if wide else 17)
		text(cell,cells[i][2],Rect2(9,50 if wide else 44,cw-18,23 if wide else 16),10,Color("adbeaf"))
	var sy:=128+stats_h+14
	var scroll:=ScrollContainer.new()
	scroll.name="SkillScroll"
	scroll.position=Vector2(24,sy)
	scroll.size=Vector2(stats_w if wide else bw-48,bh-sy-88)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone=10
	board.add_child(scroll)
	var stack:=VBoxContainer.new()
	stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",10)
	scroll.add_child(stack)
	var skills:Array=[["AUTOMÁTICA",Content.KITS[actor.id][0],Details.active(actor)],["PASSIVA · RECARGA 6 s",Content.KITS[actor.id][2],Details.passive(actor)],["ULT · 100 MANA",TaleCatalog.HERO_TACTICS[actor.id].ult,Details.ultimate(actor)]]
	if actor.get("equipment",[]).any(func(id):return not str(id).is_empty()):
		var gear_lines:Array[String]=[]
		for id in actor.equipment:
			var item:=preload("res://scripts/equipment.gd").data(id)
			if not item.is_empty():gear_lines.append(item.title+" · "+item.detail)
		skills.append(["EQUIPAMENTOS","2 espaços por personagem","\n\n".join(gear_lines)])
	if not actor.get("blessing_effects",{}).is_empty() and ui.run!=null:
		var boon:=preload("res://scripts/hero_blessings.gd").data(ui.run.blessing)
		if not boon.is_empty():skills.append(["BÊNÇÃO DO PROTAGONISTA",boon.title,boon.detail])
	if not Details.conditions(actor).is_empty():skills.push_front(["CONDIÇÕES ATIVAS","Dano ao longo do tempo",Details.conditions(actor)])
	for skill in skills:
		var card:=PanelContainer.new()
		card.set_meta("skill",skill[0])
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("1c3430")
		style.border_color=Color("796344")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel",style)
		stack.add_child(card)
		var lines:=VBoxContainer.new()
		lines.add_theme_constant_override("separation",6)
		card.add_child(lines)
		for i in 3:
			var l:=text(lines,str(skill[i]),Rect2(),[10,19,15][i],GOLD if i==0 else Color("eee9da") if i==1 else Color("bbc9bb"))
			l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			l.custom_minimum_size.x=1
	text(board,"Buffs incluídos · dano antes de armadura e esquiva.",Rect2(24,bh-79,bw-48,24),11,Color("adbeaf"))
	var back:=Button.new()
	back.text="Voltar ao combate"
	back.position=Vector2(24,bh-54)
	back.size=Vector2(bw-48,42)
	back.pressed.connect(ui.close_character_information)
	back.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	InspectorSkin.decorate(back,true,false,.09)
	board.add_child(back)
