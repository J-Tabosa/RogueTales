extends Control
const Gear = preload("res://scripts/equipment.gd")
const Art = preload("res://scripts/item_art.gd")
var ui: Control
var hero_index := 0
var selected_slot := 0
var selected_item := ""
var category := "all"
var mobile_tab := "appearance"
var inventory_offset := 0
func setup(owner_ui: Control, index: int, slot_index := 0) -> void:
	ui = owner_ui
	hero_index = clampi(index, 0, ui.run.actors.size() - 1)
	selected_slot = clampi(slot_index, 0, Gear.SLOTS - 1)
	selected_item = str(Gear.item_at(ui.run.actors[hero_index], selected_slot))
	mobile_tab = "description" if not selected_item.is_empty() else "appearance"
	name = "EquipmentPanel"
	z_index = 4000
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(rebuild)
	rebuild()
func select_hero(index: int) -> void:
	hero_index = posmod(index, ui.run.actors.size())
	selected_item = str(Gear.item_at(ui.run.actors[hero_index], selected_slot))
	rebuild()
func select_slot(index: int) -> void:
	selected_slot = index
	selected_item = str(Gear.item_at(ui.run.actors[hero_index], selected_slot))
	mobile_tab = "description" if not selected_item.is_empty() else "appearance"
	rebuild()
func select_item(id: String) -> void:
	selected_item = id
	mobile_tab = "description"
	rebuild()
func select_category(value: String) -> void:
	category = value
	inventory_offset = 0
	rebuild()
func select_tab(value: String) -> void:
	mobile_tab = value
	rebuild()
func plain_panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style := Art.plate()
	style.bg_color = color
	style.border_color = Color("52665a")
	node.add_theme_stylebox_override("panel", style)
	parent.add_child(node)
	return node
func text(parent: Node, value: String, rect: Rect2, font_size := 16, tint := Color("e8e5d8")) -> Label:
	var node: Label = ui.label(parent, value, rect, font_size, tint)
	node.clip_text = true
	return node
func editable() -> bool:
	return ui.run.interlude in ["route", "shop", "reward", "secret_reward"]
func rebuild() -> void:
	if ui == null or size.x < 1: return
	var old_scroll := find_child("InventoryScroll", true, false)
	if old_scroll != null: inventory_offset = old_scroll.scroll_vertical
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(.015, .03, .025, .91)
	shade.size = size
	add_child(shade)
	var wide := size.x >= 900
	var extent := Vector2(minf(size.x - 24, 1120), minf(size.y - 24, 736 if wide else 940))
	var board := plain_panel(self, Rect2((size - extent) * .5, extent), Color("122c26"))
	board.name = "EquipmentBoard"
	var width := extent.x
	var height := extent.y
	var actor: Dictionary = ui.run.actors[hero_index]
	text(board, "EQUIPAMENTOS", Rect2(22, 10, width - 90, 36), 22, ui.GOLD)
	text(board, "%d itens · %d ouro · %s" % [ui.run.inventory.size(), ui.run.run_gold, "trocas entre encontros" if editable() else "combate pausado · consulta"], Rect2(22, 49, width - 44, 23), 13, ui.MUTED)
	ui.button(board, "×", Rect2(width - 62, 12, 42, 44), ui.close_equipment)
	ui.face_portrait(board, actor.id, Rect2(22, 87, 58, 58))
	text(board, TaleCatalog.HEROES[actor.id].name, Rect2(91, 85, width - 280, 32), 21, ui.GOLD)
	text(board, "Espaço %d de 2" % (selected_slot + 1), Rect2(91, 119, width - 280, 23), 13, ui.MUTED)
	for index in Gear.SLOTS:
		var control := Art.slot(board, Gear.item_at(actor, index), Rect2(width - 178 + index * 57, 88, 48, 48), select_slot.bind(index), index == selected_slot)
		control.set_meta("equipment_slot", index)
	ui.button(board, "›", Rect2(width - 63, 88, 42, 44), select_hero.bind(hero_index + 1)).tooltip_text = "Próximo personagem"
	var body_y := 164.0
	if not wide:
		var tab_width := (width - 54) * .5
		ui.button(board, "Aparência", Rect2(22, 163, tab_width, 44), select_tab.bind("appearance"), mobile_tab == "appearance")
		ui.button(board, "Descrição", Rect2(32 + tab_width, 163, tab_width, 44), select_tab.bind("description"), mobile_tab == "description")
		body_y = 222
	var left_width := floorf((width - 54) * .55) if wide else width - 44
	var body_height := height - body_y - 24
	if wide or mobile_tab == "appearance": build_inventory(board, Rect2(22, body_y, left_width, body_height))
	if wide or mobile_tab == "description":
		var details_x := 32 + left_width if wide else 22.0
		build_description(board, Rect2(details_x, body_y, width - details_x - 22, body_height))
func build_inventory(parent: Node, rect: Rect2) -> void:
	var pane := plain_panel(parent, rect, Color("1a332c"))
	pane.name = "AppearancePane"
	var width := rect.size.x
	text(pane, "APARÊNCIA", Rect2(14, 10, width - 28, 23), 12, ui.GOLD)
	var filters := [["all", "Todos"], ["gear", "Itens"], ["trophy", "Troféus"]]
	var filter_width := (width - 36) / 3.0
	for index in filters.size():
		var control: Button = ui.button(pane, filters[index][1], Rect2(10 + index * (filter_width + 8), 40, filter_width, 44), select_category.bind(filters[index][0]), category == filters[index][0])
		control.add_theme_font_size_override("font_size", 14)
		control.set_meta("item_filter", filters[index][0])
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.position = Vector2(10, 98)
	scroll.size = Vector2(width - 20, rect.size.y - 112)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pane.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = maxi(2, floori((width - 30) / 100))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var unique: Array[String] = []
	for id in ui.run.inventory:
		if not unique.has(id) and (category == "all" or (category == "trophy") == id.begins_with("trophy_")): unique.append(id)
	for id in unique:
		var data := Gear.data(id)
		var width_per_tile := floorf((width - 30 - (grid.columns - 1) * 8) / grid.columns)
		var tile := Art.slot(grid, id, Rect2(0, 0, width_per_tile, 120), select_item.bind(id), id == selected_item)
		tile.custom_minimum_size = Vector2(width_per_tile, 120)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.set_meta("inventory_item", id)
		var art: TextureRect = tile.get_meta("item_picture")
		art.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		art.offset_left = 7
		art.offset_top = 5
		art.offset_right = -7
		art.offset_bottom = 86
		text(tile, data.title, Rect2(6, 86, width_per_tile - 12, 30), 11)
		var quantity := text(tile, "×%d" % ui.run.inventory.count(id), Rect2(width_per_tile - 35, 5, 29, 18), 11, ui.GOLD)
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if ui.run.actors[hero_index].equipment.has(id): text(tile, "✓", Rect2(6, 5, 22, 20), 16, ui.GOLD)
	if unique.is_empty(): text(pane, "Nenhum item nesta categoria.\nEncontre equipamentos nas recompensas,\nno mercador e em duelos secretos.", Rect2(18, 114, width - 36, 150), 16, ui.MUTED)
	scroll.set_deferred("scroll_vertical", inventory_offset)
func build_description(parent: Node, rect: Rect2) -> void:
	var pane := plain_panel(parent, rect, Color("213a31"))
	pane.name = "DescriptionPane"
	pane.clip_contents = true
	var width := rect.size.x
	var height := rect.size.y
	text(pane, "DESCRIÇÃO", Rect2(16, 10, width - 32, 23), 12, ui.GOLD)
	if selected_item.is_empty():
		text(pane, "Escolha um equipamento", Rect2(22, 90, width - 44, 68), 25, ui.GOLD)
		text(pane, "Selecione uma arte na bolsa para ver seus efeitos e equipar neste espaço.", Rect2(22, 175, width - 44, 110), 18, ui.MUTED)
		return
	var data := Gear.data(selected_item)
	var art_height := minf(170, height * .30)
	Art.picture(pane, selected_item, Rect2(24, 35, width - 48, art_height))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18, 43 + art_height)
	scroll.size = Vector2(width - 36, height - art_height - 122)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	pane.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	scroll.add_child(stack)
	for line in [[data.title, 24, ui.GOLD], ["TROFÉU DE CHEFE SECRETO" if data.has("trophy") else "EQUIPAMENTO", 11, Color("cbb5db")], [data.detail, 17, Color("eee8d6")]]:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		stack.add_child(label)
	var owners: Array[String] = []
	for actor in ui.run.actors:
		if actor.equipment.has(selected_item): owners.append(TaleCatalog.HEROES[actor.id].name)
	var free: int = ui.run.inventory.count(selected_item) - ui.run.equipped_count(selected_item)
	var status := Label.new()
	status.text = "%d cópia(s) disponível(is)" % free
	if not owners.is_empty(): status.text += "\nEquipado: " + ", ".join(owners)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", ui.MUTED)
	stack.add_child(status)
	var actor: Dictionary = ui.run.actors[hero_index]
	var equipped_here: bool = Gear.item_at(actor, selected_slot) == selected_item
	var action: Button = ui.button(pane, "Equipado" if equipped_here else "Equipar · espaço %d" % (selected_slot + 1), Rect2(14, height - 63, width - 88, 46), ui.equip_from_panel.bind(hero_index, selected_item, selected_slot), true)
	action.name = "EquipSelectedItem"
	action.disabled = not editable() or free <= 0 or actor.equipment.has(selected_item)
	var remove: Button = ui.button(pane, "−", Rect2(width - 63, height - 63, 49, 46), ui.equip_from_panel.bind(hero_index, "", selected_slot))
	remove.tooltip_text = "Remover equipamento deste espaço"
	remove.disabled = not editable() or str(Gear.item_at(actor, selected_slot)).is_empty()
