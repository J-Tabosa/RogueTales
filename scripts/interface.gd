extends "res://scripts/main.gd"
## Mobile storybook presentation; progression/story orchestration stays in main.gd.
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
var timeline: Control
var action_label: Label
var timeline_key := ""
var roster_filter := "all"
const MobileIcon = preload("res://scripts/mobile_icon.gd")


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is TextureRect:
			child.modulate.a = 0.34
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
	page.get_child(0).color = Color("111624")
	center_content()


func panel(parent: Node, rect: Rect2, color := INK) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(Color("20263b"), Color("42465d"), 18))
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
	node.add_theme_stylebox_override("normal", box(Color("e7c78b") if primary else Color("2a3048"), Color("82705c") if primary else Color("50546a"), 14))
	node.add_theme_stylebox_override("hover", box(Color("f9deb0") if primary else Color("3b4260"), Color("a2bcaf"), 8))
	node.add_theme_stylebox_override("pressed", box(Color("9b946e"), GOLD, 8))
	node.add_theme_stylebox_override("disabled", box(Color("1c2234"), Color("353b51"), 14))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD, 8))
	node.pressed.connect(func():
		if is_instance_valid(audio):
			audio.play_effect("click")
		callback.call())
	parent.add_child(node)
	register_layout(node)
	return node


func header(title: String, subtitle: String) -> void:
	face_portrait(page, campaign.avatar, Rect2(24, 12, 48, 48))
	label(page, campaign.player_name, Rect2(84, 12, 220, 25), 16)
	label(page, "VIAJANTE · NÍVEL %d" % campaign.player_level, Rect2(84, 36, 236, 22), 10, MUTED)
	panel(page, Rect2(332, 14, 112, 42))
	label(page, "%s G" % format_gold(campaign.gold), Rect2(340, 18, 96, 32), 14, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := button(page, "", Rect2(458, 12, 58, 48), show_settings)
	icon(settings, "settings", Rect2(17, 12, 24, 24))
	label(page, title, Rect2(24, 80, 492, 48), 30)
	label(page, subtitle, Rect2(24, 133, 492, 31), 14, MUTED)

func show_menu() -> void:
	state = "menu"
	paused = false
	farm_timer = -1.0
	clear_page()
	header("Entre contos e destinos.", "Sua próxima página começa aqui.")
	var chapter := mini(campaign.cleared.size(), TaleCatalog.FINAL_CHAPTER)
	var hero_card := panel(page, Rect2(20, 184, 500, 405))
	hero_card.clip_contents = true
	UISkin.picture(hero_card, preload("res://assets/ui/storybook_battle.png"), Rect2(2, 2, 496, 401), true).modulate = Color(0.70, 0.76, 0.91)
	gradient(hero_card, Rect2(2, 2, 496, 401), Color(0.07,0.09,0.17,0.08), Color("101522"))
	label(hero_card, "CAPÍTULO %02d / 12" % (chapter + 1), Rect2(22, 16, 300, 28), 12, GOLD)
	button(hero_card, "Editar", Rect2(376, 14, 102, 44), show_party)
	for index in campaign.party.size():
		var id: String = campaign.party[index]
		var x := 250.0 + (index - (campaign.party.size() - 1) * 0.5) * 142
		portrait_fitted(hero_card, id, Vector2(x, 282), 190)
	label(hero_card, "A JORNADA CONTINUA", Rect2(24, 291, 452, 23), 11, GOLD)
	label(hero_card, TaleCatalog.STAGES[chapter].name, Rect2(24, 319, 452, 60), 27)
	var title := "Continuar história" if campaign.pending_story >= 0 else ("Retomar expedição" if not campaign.checkpoint.is_empty() else "Entrar em batalha")
	var play := button(page, title + "   →", Rect2(24, 612, 492, 66), continue_journey, true)
	play.add_theme_font_size_override("font_size", 22)
	panel(page, Rect2(24, 704, 492, 116))
	icon(page, "chest", Rect2(42, 724, 34, 34))
	label(page, "PROVISÕES DO ACAMPAMENTO", Rect2(91, 716, 248, 24), 11, GOLD)
	idle_label = label(page, "", Rect2(91, 746, 240, 51), 15)
	idle_button = button(page, "Coletar", Rect2(354, 743, 144, 52), show_idle_rewards)
	update_idle_display()
	label(page, "%d / 12 contos concluídos   ·   %d / 12 personagens" % [campaign.cleared.size(), campaign.unlocked.size()], Rect2(24, 840, 492, 25), 12, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	header("Formação", "Até 3 aliados · mantenha pelo menos uma na vanguarda.")
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
		label(inner, TaleCatalog.hero_class_name(id), Rect2(14, y + 39, 275, 24), 14, MUTED)
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
	modal(str(TaleCatalog.HEROES[id].name) + " · " + TaleCatalog.hero_class_name(id), str(job.rule))
	label(overlay, str(profile.ult), Rect2(32, 410, 476, 40), 26, GOLD)
	label(overlay, str(profile.detail) + "\n\nA ULT carrega ao lutar, acertar e sofrer dano. Toque no retrato ou use 1–3 no PC. Pode ativar o uso automático.", Rect2(32, 470, 476, 207), 20)
	button(overlay, "Voltar ao personagem", Rect2(32, 746, 476, 56), show_hero_details.bind(id), true)


func build_battle() -> void:
	combat_flow = null
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
	battle_place(enemy_label, Rect2(20, 58, 500, 20), Rect2(24, 63, 1050, 25))
	power_label = label(page, "", Rect2(), 14, GOLD)
	battle_place(power_label, Rect2(20, 81, 500, 20), Rect2(970, 87, 280, 30))
	battle_viewport = Control.new()
	battle_viewport.clip_contents = true
	page.add_child(battle_viewport)
	battle_place(battle_viewport, Rect2(0, 166, 540, 490), Rect2(24, 140, 910, 560))
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
	arena.enemy_attack_hit.connect(on_enemy_attack_hit)
	timeline = Control.new()
	page.add_child(timeline)
	battle_place(timeline, Rect2(20, 108, 500, 44), Rect2(24, 89, 910, 44))
	timeline_key = ""
	var action_panel := panel(page, Rect2())
	battle_place(action_panel, Rect2(24,174,492,38), Rect2(40,148,878,40))
	action_panel.modulate.a = 0.94
	action_label = label(page, "Preparando encontro", Rect2(34,175,472,36), 13, GOLD)
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_place(action_label, Rect2(34,175,472,36), Rect2(54,149,850,38))
	for index in run.actors.size():
		cooldowns.append(0.15 + index * 0.28)
		var actor: Dictionary = run.actors[index]
		var card := button(page, "", Rect2(), try_ultimate.bind(index))
		var slot := int(index)
		battle_place(card, Rect2(16 + slot * 174, 0, 160, 148), Rect2(958, 142 + slot * 164, 296, 146), "deck")
		var face := face_portrait(card, actor.id, Rect2(12,12,48,48))
		face.set_meta("card_face",true)
		var name_tag := label(card, str(TaleCatalog.HEROES[actor.id].get("short_name", TaleCatalog.HEROES[actor.id].name)), Rect2(63, 9, 88, 43), 14)
		name_tag.set_meta("card_name", true)
		var ult_tag := label(card, str(TaleCatalog.HERO_TACTICS[actor.id].ult), Rect2(10, 82, 140, 35), 12, GOLD)
		ult_tag.set_meta("card_ult", true)
		var status := label(card, "", Rect2(10, 116, 140, 19), 11, MUTED)
		status.set_meta("card_status", true)
		var meter := bar(card, Rect2(10, 138, 140, 5), GOLD)
		ult_meters.append(meter)
		ult_buttons.append(card)
	for empty_slot in range(run.actors.size(), TaleCatalog.PARTY_LIMIT):
		var placeholder := panel(page,Rect2())
		battle_place(placeholder,Rect2(16+empty_slot*174,0,160,148),Rect2(958,142+empty_slot*164,296,146),"deck")
		icon(placeholder,"heroes",Rect2(16,18,28,28),Color("747e9b"))
		label(placeholder,"Companheiro",Rect2(12,61,136,24),13,MUTED)
		label(placeholder,"Convocação entre encontros",Rect2(12,91,136,40),11,Color("858fa9"))
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
				rect.size.y = logical_height - 470
		node.position = rect.position
		node.size = rect.size
	for card in ult_buttons:
		for child in card.get_children():
			if child.has_meta("card_face"):
				child.position = Vector2(16,18) if desktop else Vector2(12,12)
				child.size = Vector2(82,82) if desktop else Vector2(48,48)
			elif child.has_meta("card_name"):
				child.position = Vector2(111, 15) if desktop else Vector2(63, 9)
				child.size = Vector2(172, 43) if desktop else Vector2(88, 43)
				child.add_theme_font_size_override("font_size", 20 if desktop else 14)
			elif child.has_meta("card_ult"):
				child.position = Vector2(111, 66) if desktop else Vector2(10, 82)
				child.size = Vector2(172, 39) if desktop else Vector2(144, 34)
			elif child.has_meta("card_status"):
				child.position = Vector2(111, 105) if desktop else Vector2(10, 116)
			elif child is ProgressBar:
				child.position = Vector2(111, 133) if desktop else Vector2(10, 138)
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
	power_label.text = "%d aliados   ×   %d inimigos" % [run.actors.filter(func(unit): return unit.hp > 0).size(), living]
	for index in mini(ult_buttons.size(), run.actors.size()):
		var actor: Dictionary = run.actors[index]
		ult_meters[index].value = actor.energy
		for child in ult_buttons[index].get_children():
			if child.has_meta("card_status"):
				child.text = "Caída" if actor.hp <= 0 else ("Na fila" if actor.get("ult_queued", false) else ("Em ação" if actor.ult_pending else ("TOQUE · ULT" if actor.energy >= 100 else "%dAP %dPP · %d%%" % [actor.get("ap",0),actor.get("pp",0),int(actor.energy)])))
		ult_buttons[index].disabled = paused or state != "battle" or actor.hp <= 0 or actor.energy < 100 or actor.ult_pending or actor.get("ult_queued", false) or arena.tracks[index].time >= 0
		ult_buttons[index].tooltip_text = "%s · %d%%\n%s" % [TaleCatalog.HERO_TACTICS[actor.id].ult, int(actor.energy), TaleCatalog.HERO_TACTICS[actor.id].detail]
	if is_instance_valid(auto_button):
		auto_button.text = "AUTO ULT  " + ("ON" if campaign.auto_ult else "OFF")
	if is_instance_valid(action_label) and is_instance_valid(log_label):
		action_label.text = log_label.text
	refresh_timeline()
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
	button(inner, "AUTO ULT  " + ("ON" if campaign.auto_ult else "OFF"), Rect2(0, 1430, 476, 52), settings_auto_ult)
	button(inner, "Tela cheia / Janela  ·  F11", Rect2(0, 1500, 476, 52), toggle_fullscreen).disabled = OS.has_feature("mobile")
	var reset := button(inner, "Resetar conta deste dispositivo", Rect2(0, 1600, 476, 56), request_reset)
	reset.add_theme_color_override("font_color", Color("ecaaa3"))


func settings_auto_ult() -> void:
	campaign.auto_ult = not campaign.auto_ult
	persist()
	show_settings()


func request_reset() -> void:
	modal("Recomeçar do zero?", "Isso apaga neste dispositivo: ouro, EXP, personagens, capítulos, conquistas, formação, preferências e saves de recuperação. Você recomeça com a Chapeuzinho. Esta ação não pode ser desfeita.")
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
	label(desktop_shell, "%02d / 12 capítulos\n\n%d personagens\n\nNível de conta %d" % [campaign.cleared.size(), campaign.unlocked.size(), campaign.player_level], Rect2(right, 247, 190, 210), 18, MUTED)
	label(desktop_shell, "NO COMBATE\n\n1–3  ULT\nEspaço  Pausa\nA  ULT automática\nF11  Tela cheia", Rect2(right, 528, 190, 240), 15, MUTED)


func icon(parent: Node, glyph: String, rect: Rect2, tint := GOLD) -> Control:
	var node := Control.new()
	node.set_script(MobileIcon)
	node.glyph = glyph
	node.tint = tint
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	register_layout(node)
	return node


func gradient(parent: Node, rect: Rect2, top: Color, bottom: Color) -> void:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([top, bottom])
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_from = Vector2(0,0)
	texture.fill_to = Vector2(0,1)
	UISkin.picture(parent, texture, rect).stretch_mode = TextureRect.STRETCH_SCALE


func face_portrait(parent: Node, id: String, rect: Rect2) -> Control:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var slot := Panel.new()
	slot.position = rect.position
	slot.size = rect.size
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", box(Color("30354c"), Color(TaleCatalog.HEROES[id].color, 0.65), 13))
	parent.add_child(slot)
	register_layout(slot)
	var bounds: Rect2 = Rect2(data.bounds)
	var focuses := {"scarlet":Vector2(0.58,0.18),"rapunzel":Vector2(0.57,0.18),"snow_white":Vector2(0.52,0.17),"mulan":Vector2(0.5,0.17),"ariel":Vector2(0.52,0.16),"joao":Vector2(0.52,0.17),"maria":Vector2(0.58,0.18),"alice":Vector2(0.58,0.30),"puss":Vector2(0.53,0.38),"matches":Vector2(0.58,0.22),"peter":Vector2(0.58,0.24),"aladin":Vector2(0.35,0.25)}
	var extent := Vector2.ONE * bounds.size.y * 0.34
	var center: Vector2 = bounds.position + bounds.size * focuses.get(id,Vector2(0.5,0.2))
	var face := Sprite2D.new()
	face.texture = data.texture
	face.centered = false
	face.offset = -(center-extent*0.5)
	slot.add_child(face)
	var fit := func():
		face.position = Vector2.ZERO
		face.scale = slot.size/extent
	slot.resized.connect(fit)
	fit.call()
	return slot


func portrait_fitted(parent: Node, id: String, at: Vector2, height: float) -> void:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var actual: float = data.bounds.size.y * data.scale.y
	portrait(parent,id,at,height/maxf(1,actual))


func navigation(active: String) -> void:
	panel(page, Rect2(16, 882, 508, 68))
	var entries: Array = [["menu", "Início", "home", show_menu], ["map", "Contos", "map", show_map], ["heroes", "Heróis", "heroes", show_heroes], ["journal", "Diário", "book", show_journal], ["profile", "Perfil", "profile", show_profile]]
	for index in entries.size():
		var entry: Array = entries[index]
		var selected: bool = active == entry[0]
		var item := button(page, "", Rect2(22 + index * 100, 887, 96, 58), entry[3])
		item.add_theme_stylebox_override("normal", box(Color("383346") if selected else Color(0,0,0,0), Color(0,0,0,0), 12))
		icon(item, entry[2], Rect2(37, 6, 22, 22), GOLD if selected else Color("8e98b3"))
		label(item, entry[1], Rect2(0, 32, 96, 22), 11, GOLD if selected else MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_heroes() -> void:
	state = "heroes"
	clear_page()
	header("Personagens", "%d / 12 recrutados · escolha quem escreverá seu conto." % campaign.unlocked.size())
	button(page, "Todos", Rect2(24, 182, 154, 48), filter_roster.bind("all"), roster_filter == "all")
	button(page, "Recrutados", Rect2(188, 182, 158, 48), filter_roster.bind("owned"), roster_filter == "owned")
	button(page, "Formação", Rect2(356, 182, 160, 48), show_party)
	var ids: Array = TaleCatalog.HEROES.keys().filter(func(id): return roster_filter == "all" or campaign.unlocked.has(id))
	var inner := scroll_area(247, 620, ceili(ids.size()/2.0)*284)
	for index in ids.size():
		var id: String = ids[index]
		var data: Dictionary = TaleCatalog.HEROES[id]
		var owned := campaign.unlocked.has(id)
		var x := (index % 2) * 244.0
		var y := floori(index/2.0) * 284
		var card := button(inner, "", Rect2(x,y,232,272), show_hero_details.bind(id) if owned else show_unlock_details.bind(id))
		card.add_theme_stylebox_override("normal", box(Color("252a40") if owned else Color("1c2233"), Color(data.color, 0.55 if owned else 0.22), 18))
		gradient(card, Rect2(2,2,228,180), Color(data.color,0.17), Color(data.color,0))
		label(card, "NÍVEL %02d" % campaign.hero_levels[id] if owned else "VÍNCULO A DESCOBRIR", Rect2(14,10,204,24), 10, data.color)
		portrait_fitted(card, id, Vector2(116,183), 156)
		label(card, data.get("short_name", data.name), Rect2(14,187,204,34), 19, Color("f0e9dc") if owned else MUTED)
		label(card, TaleCatalog.hero_class_name(id), Rect2(14,225,204,22), 12, data.color)
		var progress := bar(card, Rect2(14,254,204,5), data.color)
		progress.max_value = 30 if owned else TaleCatalog.UNLOCKS[id].goal
		progress.value = campaign.hero_levels[id] if owned else campaign.unlock_amount(id)
	navigation("heroes")


func filter_roster(value: String) -> void:
	roster_filter = value
	show_heroes()


func refresh_timeline() -> void:
	if combat_flow == null or not is_instance_valid(timeline):
		return
	var upcoming: Array = combat_flow.preview()
	var key := str(combat_flow.round_number) + str(upcoming) + str(combat_flow.active)
	if key == timeline_key:
		return
	timeline_key = key
	for child in timeline.get_children():
		child.queue_free()
	var tag := label(timeline, "RODADA %02d" % combat_flow.round_number, Rect2(0,0,94,44), 11, GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for at in mini(5, upcoming.size()):
		var entry: Dictionary = upcoming[at]
		var unit: Dictionary = combat_flow.unit(entry)
		var x := 104 + at * 79.0
		var tint := Color("e7c78b") if entry.side == "ally" else Color("e59aab")
		if entry.side == "ally":
			face_portrait(timeline, unit.id, Rect2(x,3,34,36))
		else:
			icon(timeline, "sword", Rect2(x,8,26,26), tint)
		label(timeline, "%dAP" % unit.ap, Rect2(x+38,8,36,24), 10, tint)


func install_controls_theme() -> void:
	super.install_controls_theme()
	for control in ["VScrollBar","HScrollBar"]:
		for state_name in ["scroll","grabber","grabber_highlight","grabber_pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0,0,0,0) if state_name == "scroll" else Color("666a84")
			style.set_corner_radius_all(3)
			style.content_margin_left = 2
			style.content_margin_right = 2
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			theme.set_stylebox(state_name,control,style)
