extends Control
const Gear=preload("res://scripts/equipment.gd")
var ui:Control
var hero_index:=0
var selected_slot:=0
var built_size:=Vector2.ZERO
func setup(owner_ui:Control,index:int) -> void:
	ui=owner_ui
	hero_index=clampi(index,0,ui.run.actors.size()-1)
	name="EquipmentPanel"
	z_index=4000
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(rebuild)
	rebuild()
func select_hero(index:int) -> void:
	hero_index=posmod(index,ui.run.actors.size())
	rebuild()
func select_slot(index:int) -> void:
	selected_slot=index
	rebuild()
func rebuild() -> void:
	if ui==null or size.x<1:return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade:=ColorRect.new()
	shade.color=Color(.02,.04,.04,.96)
	shade.size=size
	add_child(shade)
	var width:=minf(size.x-24,900)
	var height:=minf(size.y-24,930)
	var board:Panel=ui.panel(self,Rect2((size-Vector2(width,height))*.5,Vector2(width,height)))
	var a:Dictionary=ui.run.actors[hero_index]
	var editable:bool=ui.run.interlude in ["route","shop","reward","secret_reward"]
	ui.label(board,"BOLSA DA EXPEDIÇÃO · 2 ITENS POR VIAJANTE",Rect2(18,14,width-88,25),12,ui.GOLD)
	ui.button(board,"×",Rect2(width-62,12,44,40),ui.close_equipment)
	ui.face_portrait(board,a.id,Rect2(22,53,74,74))
	ui.label(board,TaleCatalog.HEROES[a.id].name,Rect2(110,55,width-134,34),24,ui.GOLD)
	ui.label(board,"%d/%d viajantes · %d ouro · %d itens"%[ui.run.actors.size(),ui.run.party_capacity,ui.run.run_gold,ui.run.inventory.size()],Rect2(110,94,width-134,38),13)
	ui.button(board,"‹ Anterior",Rect2(18,139,(width-48)/2,38),select_hero.bind(hero_index-1))
	ui.button(board,"Próximo ›",Rect2(30+(width-48)/2,139,(width-48)/2,38),select_hero.bind(hero_index+1))
	ui.label(board,"Toque num espaço e depois no item. Trocas só entre combates." if editable else "Combate pausado · equipe itens entre os encontros.",Rect2(18,185,width-36,43),13,ui.MUTED)
	for slot in Gear.SLOTS:
		var id:String=a.get("equipment",[])[slot] if slot<a.get("equipment",[]).size() else ""
		var data:=Gear.data(id)
		var card:Button=ui.button(board,"",Rect2(18+slot*(width-24)/2,235,(width-48)/2,80),select_slot.bind(slot),slot==selected_slot)
		card.set_meta("equipment_slot",slot)
		ui.label(card,"ESPAÇO %d"%(slot+1),Rect2(10,8,card.size.x-20,20),10,ui.GOLD)
		ui.label(card,str(data.get("title","Vazio")),Rect2(10,30,card.size.x-20,44),15)
	var scroll:=ScrollContainer.new()
	scroll.name="InventoryScroll"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.position=Vector2(18,329)
	scroll.size=Vector2(width-36,height-405)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(scroll)
	var list:=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	var unique:Array[String]=[]
	for id in ui.run.inventory:
		if not unique.has(id):unique.append(id)
	if unique.is_empty():
		var message:=Label.new()
		message.text="Sua bolsa está vazia.\nEncontre itens nas recompensas, no mercador e em duelos secretos."
		message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		message.custom_minimum_size=Vector2(width-58,130)
		list.add_child(message)
	for id in unique:
		var data:=Gear.data(id)
		var free:int=ui.run.inventory.count(id)-ui.run.equipped_count(id)
		var card:=Button.new()
		card.custom_minimum_size=Vector2(width-58,145)
		card.disabled=not editable or free<=0 or a.get("equipment",[]).has(id)
		card.set_meta("inventory_item",id)
		card.pressed.connect(ui.equip_from_panel.bind(hero_index,id,selected_slot))
		list.add_child(card)
		ui.label(card,data.title,Rect2(12,8,width-84,29),19,ui.GOLD)
		ui.label(card,data.detail,Rect2(12,43,width-84,72),14,ui.MUTED)
		ui.label(card,"%d disponíveis / %d cópias · %s"%[free,ui.run.inventory.count(id),"equipado neste herói" if a.get("equipment",[]).has(id) else "toque para equipar"],Rect2(12,117,width-84,21),11)
	var remove:Button=ui.button(board,"Remover do espaço %d"%(selected_slot+1),Rect2(18,height-63,(width-48)/2,44),ui.equip_from_panel.bind(hero_index,"",selected_slot))
	remove.disabled=not editable
	ui.button(board,"Concluir",Rect2(30+(width-48)/2,height-63,(width-48)/2,44),ui.close_equipment,true)
