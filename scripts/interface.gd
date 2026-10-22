extends "res://scripts/main.gd"
## Minimal presentation; progression/story orchestration stays in main.gd.
const TacticalArena = preload("res://scripts/tactical_arena.gd")
var battle_view := false
var desktop := false
var logical_width := 540.0
var desktop_shell: Control
var battle_nodes: Array[Control] = []
var ult_buttons: Array[Button] = []
var ult_meters: Array[ProgressBar] = []
var battle_viewport: Control
var auto_button: Button
var power_label: Label
var reset_confirm: Button


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is TextureRect:
			child.modulate.a = 0.08
	apply_window_mode()


func center_content(usable_override: Rect2 = Rect2()) -> void:
	if content == null:
		return
	desktop = size.x / maxf(1, size.y) >= 1.28
	if battle_view and desktop:
		logical_width = 1280.0
		logical_height = 800.0
		var factor := minf(size.x / logical_width, size.y / logical_height)
		content.size = Vector2(logical_width, logical_height)
		content.scale = Vector2.ONE * factor
		content.position = (size - content.size * factor) * 0.5
		relayout_page()
	else:
		logical_width = 540.0
		super.center_content(usable_override)
	update_desktop_shell()


func clear_page() -> void:
	battle_view = state in ["travel", "battle"] and run != null and run.tactics != null
	battle_nodes.clear()
	ult_buttons.clear()
	ult_meters.clear()
	super.clear_page()
	page.get_child(0).color = Color("131c23")
	center_content()


func panel(parent: Node, rect: Rect2, color := INK) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(Color("1c2931"), Color("34434a"), 9))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	register_layout(node)
	return node


func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary := false) -> Button:
	var node := Button.new()
	node.text = text
	node.clip_text = true
	node.position = rect.position
	node.size = Vector2(rect.size.x, maxf(44, rect.size.y))
	node.custom_minimum_size.y = 44
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_color_override("font_color", Color("172124") if primary else Color("e3e9e8"))
	node.add_theme_color_override("font_disabled_color", Color("84918f"))
	node.add_theme_stylebox_override("normal", box(Color("cbb988") if primary else Color("24333b"), Color("43534f"), 8))
	node.add_theme_stylebox_override("hover", box(Color("dfcea2") if primary else Color("344b50"), Color("a2bcaf"), 8))
	node.add_theme_stylebox_override("pressed", box(Color("9b946e"), GOLD, 8))
	node.add_theme_stylebox_override("disabled", box(Color("1b272e"), Color("2c3b41"), 8))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD, 8))
	node.pressed.connect(func():
		if is_instance_valid(audio):
			audio.play_effect("click")
		callback.call())
	parent.add_child(node)
	register_layout(node)
	return node


func header(title: String, subtitle: String) -> void:
	label(page, "ROGUETALES", Rect2(24, 14, 220, 27), 15, GOLD)
	label(page, "%s  ouro" % format_gold(campaign.gold), Rect2(262, 14, 164, 27), 15, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button(page, "⚙", Rect2(454, 8, 62, 44), show_settings)
	label(page, title, Rect2(24, 66, 492, 55), 30)
	label(page, subtitle, Rect2(24, 126, 492, 42), 16, MUTED)


func show_menu() -> void:
	state = "menu"
	paused = false
	farm_timer = -1.0
	clear_page()
	header("Seu próximo conto.", "Capítulo %02d / 12  ·  %d heroínas" % [mini(campaign.cleared.size() + 1, 12), campaign.unlocked.size()])
	label(page, "FORMAÇÃO", Rect2(24, 192, 492, 30), 13, MUTED)
	var count := campaign.party.size()
	for index in count:
		var id: String = campaign.party[index]
		var x := 270.0 + (index - (count - 1) * 0.5) * 148
		portrait(page, id, Vector2(x, 442), 0.72)
		var name_tag := label(page, TaleCatalog.HEROES[id].name, Rect2(x - 73, 451, 146, 28), 15)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var role_tag := label(page, TaleCatalog.CLASSES[TaleCatalog.HERO_TACTICS[id]["class"]].name, Rect2(x - 73, 481, 146, 24), 12, MUTED)
		role_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(page, "PROVISÕES", Rect2(24, 554, 292, 28), 13, MUTED)
	idle_label = label(page, "", Rect2(24, 592, 306, 58), 18)
	idle_button = button(page, "Coletar", Rect2(366, 590, 150, 52), show_idle_rewards, true)
	update_idle_display()
	var title := "Continuar história" if campaign.pending_story >= 0 else ("Retomar expedição" if not campaign.checkpoint.is_empty() else "Batalhar  →")
	button(page, title, Rect2(24, 698, 492, 64), continue_journey, true)
	button(page, "Formação", Rect2(24, 790, 236, 48), show_party)
	button(page, "Heróis", Rect2(280, 790, 236, 48), show_heroes)
	navigation("menu")


func show_map() -> void:
	state = "map"
	clear_page()
	header("Campanha", "%d / 12 capítulos concluídos" % campaign.cleared.size())
	var inner := scroll_area(190, 676, 1056)
	for index in TaleCatalog.CHAPTER_COUNT:
		var data: Dictionary = TaleCatalog.STAGES[index]
		var x := (index % 2) * 244.0
		var y := floori(index / 2.0) * 174.0
		var open := campaign.can_play(index)
		var done := campaign.cleared.has(index)
		var card := button(inner, "", Rect2(x, y, 232, 158), show_chapter.bind(index), open and not done)
		card.disabled = not open
		label(card, "%02d  %s" % [index + 1, "✓" if done else ("" if open else "· bloqueado")], Rect2(14, 10, 204, 23), 14, Color("172124") if open and not done else GOLD)
		label(card, data.name, Rect2(14, 43, 204, 62), 20, Color("172124") if open and not done else Color("e3e9e8"))
		label(card, "Revisitar" if done else ("Entrar →" if open else "Conclua o anterior"), Rect2(14, 119, 204, 25), 13, Color("303c36") if open and not done else MUTED)
	inner.get_parent().set_deferred("scroll_vertical", int(maxf(0, floori(mini(11, campaign.cleared.size()) / 2.0) * 174 - 120)))
	navigation("map")


func show_party() -> void:
	state = "party"
	clear_page()
	header("Formação", "Até 3 aliadas · mantenha pelo menos uma na vanguarda.")
	label(page, "VANGUARDA", Rect2(270, 183, 246, 28), 13, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(page, "RETAGUARDA", Rect2(24, 183, 246, 28), 13, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for side in ["back", "front"]:
		var ids: Array[String] = []
		for id in campaign.party:
			if campaign.row_for(id) == side:
				ids.append(id)
		for slot in ids.size():
			var x := (132.0 if side == "back" else 396.0) + (slot - (ids.size() - 1) * 0.5) * 73
			portrait(page, ids[slot], Vector2(x, 365), 0.44)
	var inner := scroll_area(402, 463, TaleCatalog.HEROES.size() * 145)
	var index := 0
	for id in TaleCatalog.HEROES:
		var y := index * 145.0
		var owned := campaign.unlocked.has(id)
		var equipped := campaign.party.has(id)
		var profile: Dictionary = TaleCatalog.HERO_TACTICS[id]
		panel(inner, Rect2(0, y, 476, 133))
		label(inner, TaleCatalog.HEROES[id].name, Rect2(14, y + 8, 250, 29), 20)
		label(inner, TaleCatalog.CLASSES[profile["class"]].name, Rect2(14, y + 39, 275, 24), 14, MUTED)
		var join := button(inner, "Retirar" if equipped else ("Adicionar" if owned else "Ver requisito"), Rect2(305, y + 14, 156, 44), toggle_member.bind(id) if owned else show_unlock_details.bind(id), equipped)
		join.disabled = owned and (not campaign.checkpoint.is_empty() or (not equipped and campaign.party.size() >= 3) or (equipped and campaign.party.size() == 1))
		var row := campaign.row_for(id)
		var formation := button(inner, ("Frente → Fundo" if row == "front" else "Fundo → Frente") if equipped else "Fora da formação", Rect2(14, y + 76, 447, 44), switch_row.bind(id))
		formation.add_theme_font_size_override("font_size", 15)
		formation.disabled = not equipped or not campaign.checkpoint.is_empty()
		index += 1
	navigation("heroes")


func switch_row(id: String) -> void:
	if campaign.set_row(id, "back" if campaign.row_for(id) == "front" else "front"):
		persist()
		show_party()
	else:
		modal("Mantenha a linha de frente", "Coloque outra aliada na vanguarda antes de mover esta para a retaguarda.")
		button(overlay, "Voltar à formação", Rect2(32, 461, 476, 56), show_party, true)


func show_hero_details(id: String) -> void:
	super.show_hero_details(id)
	if state != "hero":
		return
	for child in page.get_children():
		if child is Label and child.has_meta("base_rect") and is_equal_approx(child.get_meta("base_rect").position.y, 422):
			child.queue_free()
	button(page, "Classe e ULT  ·  " + str(TaleCatalog.HERO_TACTICS[id].ult), Rect2(24, 430, 492, 44), show_tactical_details.bind(id)).add_theme_font_size_override("font_size", 16)


func show_tactical_details(id: String) -> void:
	var profile: Dictionary = TaleCatalog.HERO_TACTICS[id]
	var job: Dictionary = TaleCatalog.CLASSES[profile["class"]]
	modal(str(TaleCatalog.HEROES[id].name) + " · " + str(job.name), str(job.rule))
	label(overlay, str(profile.ult), Rect2(32, 410, 476, 40), 26, GOLD)
	label(overlay, str(profile.detail) + "\n\nA ULT carrega ao lutar, acertar e sofrer dano. Toque no retrato ou use 1–3 no PC. Pode ativar o uso automático.", Rect2(32, 470, 476, 207), 20)
	button(overlay, "Voltar à heroína", Rect2(32, 746, 476, 56), show_hero_details.bind(id), true)


func build_battle() -> void:
	run.enable_tactics(campaign)
	state = "travel"
	paused = false
	game_speed = campaign.speed
	clear_page()
	cooldowns.clear()
	ally_bars.clear()
	ally_labels.clear()
	ally_clocks.clear()
	stage_label = label(page, "%02d / 12   %s" % [run.stage + 1, TaleCatalog.STAGES[run.stage].name], Rect2(20, 10, 412, 53), 20)
	battle_place(stage_label, Rect2(20, 10, 412, 53), Rect2(24, 12, 830, 43))
	var pause := button(page, "Ⅱ", Rect2(), toggle_pause)
	battle_place(pause, Rect2(454, 14, 66, 44), Rect2(1186, 14, 68, 44))
	enemy_label = label(page, "", Rect2(), 12, MUTED)
	battle_place(enemy_label, Rect2(20, 65, 500, 28), Rect2(24, 63, 1050, 25))
	power_label = label(page, "", Rect2(), 14, GOLD)
	battle_place(power_label, Rect2(20, 94, 500, 24), Rect2(970, 87, 280, 30))
	battle_viewport = Control.new()
	battle_viewport.clip_contents = true
	page.add_child(battle_viewport)
	battle_place(battle_viewport, Rect2(0, 126, 540, 535), Rect2(24, 112, 910, 590))
	arena = Node2D.new()
	arena.set_script(TacticalArena)
	arena.simulation = run
	arena.stage = run.stage
	arena.speed = game_speed
	arena.reduced_motion = campaign.reduced_motion
	arena.high_quality = campaign.high_quality
	for id in run.actor_ids():
		arena.party_scenes.append(HERO_SCENES[id])
	battle_viewport.add_child(arena)
	arena.attack_hit.connect(on_attack_hit)
	arena.attack_started.connect(on_attack_started)
	for index in run.actors.size():
		cooldowns.append(0.15 + index * 0.28)
		var actor: Dictionary = run.actors[index]
		var card := button(page, "", Rect2(), try_ultimate.bind(index))
		var slot := int(index)
		battle_place(card, Rect2(16 + slot * 174, 0, 160, 142), Rect2(958, 142 + slot * 164, 296, 146), "deck")
		portrait(card, actor.id, Vector2(38, 73), 0.33)
		var portrait_sprite := card.get_child(card.get_child_count() - 1) as Sprite2D
		portrait_sprite.set_meta("card_portrait", true)
		var name_tag := label(card, str(TaleCatalog.HEROES[actor.id].name), Rect2(63, 9, 88, 43), 14)
		name_tag.set_meta("card_name", true)
		var ult_tag := label(card, str(TaleCatalog.HERO_TACTICS[actor.id].ult), Rect2(8, 76, 144, 34), 12, GOLD)
		ult_tag.set_meta("card_ult", true)
		var status := label(card, "", Rect2(8, 109, 144, 19), 11, MUTED)
		status.set_meta("card_status", true)
		var meter := bar(card, Rect2(8, 133, 144, 5), GOLD)
		ult_meters.append(meter)
		ult_buttons.append(card)
	log_label = label(page, "", Rect2(), 14, MUTED)
	battle_place(log_label, Rect2(20, 0, 500, 41), Rect2(24, 716, 910, 40), "log")
	auto_button = button(page, "", Rect2(), toggle_auto_ult)
	battle_place(auto_button, Rect2(16, 0, 246, 46), Rect2(958, 658, 296, 46), "bottom")
	speed_button = button(page, "%d×" % int(game_speed), Rect2(), toggle_speed)
	battle_place(speed_button, Rect2(278, 0, 246, 46), Rect2(958, 720, 296, 46), "bottom")
	relayout_battle()
	update_hud()


func battle_place(node: Control, mobile: Rect2, pc: Rect2, kind := "fixed") -> void:
	node.set_meta("mobile_rect", mobile)
	node.set_meta("pc_rect", pc)
	node.set_meta("battle_kind", kind)
	battle_nodes.append(node)


func relayout_battle() -> void:
	if not battle_view:
		return
	for node in battle_nodes:
		if not is_instance_valid(node):
			continue
		var rect: Rect2 = node.get_meta("pc_rect" if desktop else "mobile_rect")
		if not desktop:
			match str(node.get_meta("battle_kind")):
				"deck": rect.position.y = logical_height - 230
				"log": rect.position.y = logical_height - 288
				"bottom": rect.position.y = logical_height - 67
			if node == battle_viewport:
				rect.size.y = logical_height - 420
		node.position = rect.position
		node.size = rect.size
	for card in ult_buttons:
		for child in card.get_children():
			if child.has_meta("card_portrait"):
				child.position = Vector2(56, 128) if desktop else Vector2(38, 73)
				child.scale = static_portraits[run.actors[ult_buttons.find(card)].id].scale * (0.54 if desktop else 0.33)
			elif child.has_meta("card_name"):
				child.position = Vector2(111, 15) if desktop else Vector2(63, 9)
				child.size = Vector2(172, 43) if desktop else Vector2(88, 43)
				child.add_theme_font_size_override("font_size", 20 if desktop else 14)
			elif child.has_meta("card_ult"):
				child.position = Vector2(111, 66) if desktop else Vector2(8, 76)
				child.size = Vector2(172, 39) if desktop else Vector2(144, 34)
			elif child.has_meta("card_status"):
				child.position = Vector2(111, 105) if desktop else Vector2(8, 109)
			elif child is ProgressBar:
				child.position = Vector2(111, 133) if desktop else Vector2(8, 133)
				child.size.x = 172 if desktop else 144
	if is_instance_valid(arena) and arena.get_script() == TacticalArena:
		arena.fit_field(battle_viewport.size)
	if is_instance_valid(overlay):
		overlay.position.x = (logical_width - 540) * 0.5


func update_hud() -> void:
	if not battle_view or run == null or run.tactics == null:
		return
	if not is_instance_valid(enemy_label):
		return
	var living := 0
	for foe in run.tactics.enemies:
		if foe.hp > 0:
			living += 1
	enemy_label.text = "ENCONTRO %d / 3   ·   %s" % [run.wave + 1, "CHEFE" if run.wave == 2 else "ESCARAMUÇA"]
	power_label.text = "%d aliadas   ×   %d inimigos" % [run.actors.filter(func(unit): return unit.hp > 0).size(), living]
	for index in mini(ult_buttons.size(), run.actors.size()):
		var actor: Dictionary = run.actors[index]
		ult_meters[index].value = actor.energy
		for child in ult_buttons[index].get_children():
			if child.has_meta("card_status"):
				child.text = "Caída" if actor.hp <= 0 else ("Em ação" if actor.ult_pending else ("ULT pronta" if actor.energy >= 100 else "%d%%" % int(actor.energy)))
		ult_buttons[index].disabled = paused or state != "battle" or actor.hp <= 0 or actor.energy < 100 or actor.ult_pending or arena.tracks[index].time >= 0
		ult_buttons[index].tooltip_text = "%s · %d%%\n%s" % [TaleCatalog.HERO_TACTICS[actor.id].ult, int(actor.energy), TaleCatalog.HERO_TACTICS[actor.id].detail]
	if is_instance_valid(auto_button):
		auto_button.text = "ULT automática: " + ("ON" if campaign.auto_ult else "OFF")
	arena.sync_health(run.actors)


func register_layout(node: Control, kind := "auto") -> void:
	if battle_view and node.get_parent() == page:
		return
	super.register_layout(node, kind)


func relayout_page() -> void:
	if battle_view:
		if is_instance_valid(page):
			page.size = Vector2(logical_width, logical_height)
			if page.get_child_count() > 0:
				page.get_child(0).size = page.size
		relayout_battle()
		if is_instance_valid(overlay):
			for child in overlay.get_children():
				if child is Control:
					place_control(child)
	else:
		super.relayout_page()


func modal(title: String, subtitle: String) -> void:
	super.modal(title, subtitle)
	overlay.position.x = (logical_width - 540.0) * 0.5
	var shade: ColorRect = overlay.get_child(0)
	shade.remove_meta("base_rect")
	shade.position.x = -overlay.position.x
	shade.size = Vector2(logical_width, logical_height)
	shade.color = Color(0.035, 0.06, 0.08, 0.96)


func toggle_auto_ult() -> void:
	campaign.auto_ult = not campaign.auto_ult
	persist()
	update_hud()


func show_settings() -> void:
	super.show_settings()
	var scroll: ScrollContainer
	for child in page.get_children():
		if child is ScrollContainer:
			scroll = child
	if scroll == null:
		return
	var inner: Control = scroll.get_child(0)
	inner.custom_minimum_size.y = 1770
	button(inner, "ULT automática: " + ("ON" if campaign.auto_ult else "OFF"), Rect2(0, 1430, 476, 52), settings_auto_ult)
	button(inner, "Tela cheia / Janela  ·  F11", Rect2(0, 1500, 476, 52), toggle_fullscreen).disabled = OS.has_feature("mobile")
	var reset := button(inner, "Resetar conta deste dispositivo", Rect2(0, 1600, 476, 56), request_reset)
	reset.add_theme_color_override("font_color", Color("ecaaa3"))


func settings_auto_ult() -> void:
	campaign.auto_ult = not campaign.auto_ult
	persist()
	show_settings()


func request_reset() -> void:
	modal("Recomeçar do zero?", "Isso apaga neste dispositivo: ouro, EXP, heroínas, capítulos, conquistas, formação, preferências e saves de recuperação. Você recomeça com a Chapeuzinho. Esta ação não pode ser desfeita.")
	reset_confirm = button(overlay, "Apagar progresso e recomeçar", Rect2(32, 500, 476, 60), confirm_reset)
	reset_confirm.add_theme_color_override("font_color", Color("ecaaa3"))
	button(overlay, "Cancelar", Rect2(32, 590, 476, 56), show_settings, true)


func confirm_reset() -> void:
	if not TaleCampaign.reset_account(save_path):
		modal("Não foi possível resetar", "Não foi possível substituir o save e a cópia de recuperação. Tente novamente.")
		button(overlay, "Voltar", Rect2(32, 500, 476, 56), show_settings)
		return
	run = null
	campaign = TaleCampaign.new()
	campaign.load_from(save_path)
	paused = false
	selected_hero = "scarlet"
	debug_enabled = false
	apply_preferences()
	apply_window_mode()
	show_menu()


func apply_window_mode() -> void:
	if OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if campaign.window_mode == "fullscreen" else DisplayServer.WINDOW_MODE_WINDOWED)


func toggle_fullscreen() -> void:
	campaign.window_mode = "windowed" if campaign.window_mode == "fullscreen" else "fullscreen"
	apply_window_mode()
	persist()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		if state in ["battle", "travel"] and not event.ctrl_pressed:
			if key == KEY_SPACE:
				toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if key in [KEY_1, KEY_2, KEY_3]:
				try_ultimate(int(key - KEY_1))
				get_viewport().set_input_as_handled()
				return
			if key == KEY_A:
				toggle_auto_ult()
				get_viewport().set_input_as_handled()
				return
	super._input(event)


func update_desktop_shell() -> void:
	if is_instance_valid(desktop_shell):
		desktop_shell.queue_free()
		desktop_shell = null
	if not desktop or battle_view or campaign == null or not is_instance_valid(page):
		return
	var factor := content.scale.x
	var extra: float = (size.x - content.size.x * factor) / factor * 0.5
	if extra < 210:
		return
	desktop_shell = Control.new()
	desktop_shell.position = Vector2(content.position.x - 215 * factor, content.position.y)
	desktop_shell.scale = Vector2.ONE * factor
	add_child(desktop_shell)
	label(desktop_shell, "ROGUETALES", Rect2(0, 52, 190, 40), 22, GOLD)
	label(desktop_shell, "O ÚLTIMO FIO", Rect2(0, 98, 190, 26), 12, MUTED)
	var links := [["Início", show_menu], ["Campanha", show_map], ["Heróis", show_heroes], ["Formação", show_party], ["Perfil", show_profile], ["Configurações", show_settings]]
	for index in links.size():
		button(desktop_shell, links[index][0], Rect2(0, 192 + index * 67, 187, 48), links[index][1])
	var right := 770.0
	label(desktop_shell, "SUA JORNADA", Rect2(right, 190, 190, 35), 16, GOLD)
	label(desktop_shell, "%02d / 12 capítulos\n\n%d heroínas\n\nNível de conta %d" % [campaign.cleared.size(), campaign.unlocked.size(), campaign.player_level], Rect2(right, 247, 190, 210), 18, MUTED)
	label(desktop_shell, "NO COMBATE\n\n1–3  ULT\nEspaço  Pausa\nA  ULT automática\nF11  Tela cheia", Rect2(right, 528, 190, 240), 15, MUTED)
