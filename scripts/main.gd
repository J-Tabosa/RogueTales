extends Control
## Screens and orchestration. Rules: run.gd; progression: campaign.gd; content: catalog.gd.
const Arena = preload("res://scripts/arena.gd")
const HERO_SCENES = TaleCatalog.HERO_SCENES
const GOLD := Color("e9c488")
const MUTED := Color("96a4b4")
const INK := Color("101823")
@export var save_path := TaleCampaign.SAVE_PATH
var campaign: TaleCampaign
var run: IdleRun
var state := "menu"
var selected_hero := "scarlet"
var viewed_stage := 0
var paused := false
var game_speed := 1.0
var cooldowns: Array[float] = []
var enemy_timer := 0.0
var travel_timer := 0.0
var hud_timer := 0.0
var debug_enabled := false
var debug_panel: Control
var content: Control
var page: Control
var overlay: Control
var arena: Node2D
var enemy_hp: ProgressBar
var enemy_label: Label
var log_label: Label
var stage_label: Label
var speed_button: Button
var ally_bars: Array[ProgressBar] = []
var ally_labels: Array[Label] = []
var ally_clocks: Array[ProgressBar] = []
var frame_label: Label
var story_stage := 0
var story_mode := "intro"
var story_line := 0
var story_archive := false
var story_lines: Array = []


func _ready() -> void:
	campaign = TaleCampaign.new()
	campaign.load_from(save_path)
	game_speed = campaign.speed
	content = Control.new()
	content.size = Vector2(540, 960)
	add_child(content)
	resized.connect(center_content)
	center_content()
	get_tree().auto_accept_quit = false
	show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and campaign != null:
		campaign.save_to(save_path)
		get_tree().quit()


func center_content() -> void:
	if content != null:
		content.position = (size - Vector2(540, 960)) * 0.5


func box(color: Color, border := Color("34404f"), radius := 16) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left = 14
	result.content_margin_right = 14
	return result


func panel(parent: Node, rect: Rect2, color := INK) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func label(
	parent: Node, text: String, rect: Rect2, font_size := 18, color := Color("eeeae2")
) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Establish wrap width before text shapes its minimum size.
	node.position = rect.position
	node.size = rect.size
	node.text = text
	parent.add_child(node)
	return node


func button(
	parent: Node, text: String, rect: Rect2, callback: Callable, primary := false
) -> Button:
	var node := Button.new()
	node.clip_text = true
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 19)
	node.add_theme_color_override("font_color", Color("191a22") if primary else Color("eeeae2"))
	node.add_theme_color_override("font_hover_color", Color("191a22") if primary else Color.WHITE)
	node.add_theme_color_override("font_pressed_color", Color("191a22") if primary else Color.WHITE)
	node.add_theme_stylebox_override("normal", box(GOLD if primary else Color("1b2735")))
	node.add_theme_stylebox_override(
		"hover", box(Color("f5d69e") if primary else Color("2d3b4d"), GOLD)
	)
	node.add_theme_stylebox_override(
		"pressed", box(Color("c4a16a") if primary else Color("121c29"), GOLD)
	)
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node


func bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.add_theme_stylebox_override("background", box(Color("080f18"), Color("34404f"), 5))
	node.add_theme_stylebox_override("fill", box(color, color, 5))
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node


func clear_page() -> void:
	if is_instance_valid(debug_panel):
		debug_panel.queue_free()
	debug_panel = null
	for node in content.get_children():
		content.remove_child(node)
		node.queue_free()
	page = Control.new()
	page.size = Vector2(540, 960)
	content.add_child(page)
	overlay = null
	arena = null
	var bg := ColorRect.new()
	bg.color = Color("090f18")
	bg.size = Vector2(540, 960)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)
	panel(page, Rect2(-70, -100, 650, 255), Color("111e2a"))


func header(title: String, subtitle: String) -> void:
	label(page, "ROGUETALES / O ÚLTIMO FIO", Rect2(24, 24, 390, 28), 14, GOLD)
	button(page, "Opções", Rect2(423, 22, 93, 40), show_settings).add_theme_font_size_override(
		"font_size", 15
	)
	label(page, title, Rect2(24, 68, 492, 53), 30)
	label(page, subtitle, Rect2(24, 126, 492, 42), 16, MUTED)


func navigation(active: String) -> void:
	var entries: Array = [
		["menu", "Início", show_menu],
		["map", "Mapa", show_map],
		["party", "Equipe", show_party],
		["upgrade", "Melhorias", show_upgrades],
		["journal", "Diário", show_journal]
	]
	for index in entries.size():
		var item: Array = entries[index]
		var node := button(
			page, item[1], Rect2(24 + index * 100, 884, 92, 54), item[2], active == item[0]
		)
		node.add_theme_font_size_override("font_size", 14)


func make_arena(y: float, ids: Array = [], target_stage: int = 0) -> void:
	arena = Node2D.new()
	arena.set_script(Arena)
	var chosen: Array = ids if not ids.is_empty() else campaign.party
	for id in chosen:
		arena.party_scenes.append(HERO_SCENES[id])
	arena.stage = target_stage
	arena.reduced_motion = campaign.reduced_motion
	var viewport := Control.new()
	viewport.position = Vector2(24, y)
	viewport.size = Vector2(492, 340)
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(viewport)
	viewport.add_child(arena)
	arena.attack_hit.connect(on_attack_hit)


func portrait(parent: Node, id: String, at: Vector2, factor: float = 0.68) -> void:
	var actor: AnimatedSprite2D = HERO_SCENES[id].instantiate()
	actor.position = at
	actor.scale *= factor
	parent.add_child(actor)
	actor.idle_sway_amplitude = 0 if campaign.reduced_motion else 2


func scroll_area(y: float, height: float, total: float) -> Control:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, y)
	scroll.size = Vector2(492, height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	page.add_child(scroll)
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(476, total)
	scroll.add_child(inner)
	return inner


func persist() -> void:
	campaign.save_to(save_path)


func show_menu() -> void:
	state = "menu"
	paused = false
	clear_page()
	header(
		"O próximo capítulo é seu.",
		"CAMPANHA  %d / 8     •     OURO  %d" % [campaign.cleared.size(), campaign.gold]
	)
	var next := mini(campaign.cleared.size(), 7)
	make_arena(188, [], next)
	label(
		page, "FORMAÇÃO ATIVA  ·  %d / 3" % campaign.party.size(), Rect2(40, 200, 440, 24), 14, GOLD
	)
	label(
		page,
		"Oito agulhas prendem os reinos.\nSeis vozes podem reescrever o fim.",
		Rect2(24, 543, 492, 64),
		22
	)
	var title := (
		"Continuar história  →"
		if campaign.pending_story >= 0
		else (
			"Retomar expedição  →"
			if not campaign.checkpoint.is_empty()
			else "Abrir mapa da campanha  →"
		)
	)
	button(page, title, Rect2(24, 629, 492, 62), continue_journey, true)
	button(page, "Organizar equipe", Rect2(24, 709, 236, 54), show_party)
	button(page, "Melhorar princesas", Rect2(280, 709, 236, 54), show_upgrades)
	label(
		page,
		"%d princesas recrutadas  •  progresso automático" % campaign.unlocked.size(),
		Rect2(24, 789, 492, 33),
		16,
		MUTED
	)
	if not campaign.save_error.is_empty():
		label(page, campaign.save_error, Rect2(24, 827, 492, 36), 15, Color("ed9a9c"))
	navigation("menu")


func continue_journey() -> void:
	if campaign.pending_story >= 0:
		show_story(campaign.pending_story, "outro")
		return
	if not campaign.checkpoint.is_empty():
		resume_checkpoint()
		return
	show_map()


func show_map() -> void:
	state = "map"
	clear_page()
	header(
		"Os oito reinos",
		"%d de 8 agulhas desfeitas • escolha um capítulo" % campaign.cleared.size()
	)
	for index in 8:
		var data: Dictionary = TaleCatalog.STAGES[index]
		var x: float = 24 + (index % 2) * 252
		var y: float = 190 + floori(index / 2.0) * 164
		var open := campaign.can_play(index)
		panel(page, Rect2(x, y, 240, 150), Color(data.sky) if open else Color("111721"))
		label(
			page,
			(
				"%02d  /  %s"
				% [
					index + 1,
					(
						"CONCLUÍDO"
						if campaign.cleared.has(index)
						else ("DISPONÍVEL" if open else "BLOQUEADO")
					)
				]
			),
			Rect2(x + 14, y + 9, 212, 24),
			12,
			data.color if open else MUTED
		)
		label(
			page, data.name, Rect2(x + 14, y + 38, 212, 55), 20, Color("eeeae2") if open else MUTED
		)
		var node := button(
			page,
			"Revisitar" if campaign.cleared.has(index) else "Entrar  →",
			Rect2(x + 14, y + 103, 212, 36),
			show_chapter.bind(index),
			open and not campaign.cleared.has(index)
		)
		node.add_theme_font_size_override("font_size", 15)
		node.disabled = not open
	navigation("map")


func show_chapter(index: int) -> void:
	if not campaign.can_play(index):
		return
	viewed_stage = index
	state = "chapter"
	clear_page()
	var data: Dictionary = TaleCatalog.STAGES[index]
	header("Capítulo %02d" % (index + 1), data.name)
	make_arena(185, [], index)
	arena.enemy_visible = true
	arena.boss = true
	label(page, data.short, Rect2(24, 548, 492, 44), 26, GOLD)
	label(page, "Dois encontros e um chefe: " + str(data.boss), Rect2(24, 601, 492, 66), 19, MUTED)
	var reward := 100 + index * 35 if not campaign.cleared.has(index) else 35 + index * 12
	var info := "Recompensa: %d ouro • relíquias válidas neste capítulo" % reward
	if not str(data.recruit).is_empty() and not campaign.unlocked.has(data.recruit):
		info += "\nRecrutamento: " + str(TaleCatalog.HEROES[data.recruit].name)
	label(page, info, Rect2(24, 679, 492, 66), 17)
	if campaign.checkpoint.is_empty():
		button(page, "Começar capítulo  →", Rect2(24, 776, 492, 60), start_stage.bind(index), true)
	else:
		button(
			page, "Retomar expedição em andamento", Rect2(24, 759, 492, 52), resume_checkpoint, true
		)
		(
			button(page, "Abandonar expedição", Rect2(24, 821, 492, 42), request_abandon)
			. add_theme_font_size_override("font_size", 16)
		)
	navigation("map")


func start_stage(index: int) -> void:
	if not campaign.can_play(index) or not campaign.checkpoint.is_empty():
		return
	if campaign.pending_story >= 0:
		show_story(campaign.pending_story, "outro")
		return
	viewed_stage = index
	show_story(index, "intro")


func show_story(index: int, mode: String, line: int = 0, archive: bool = false) -> void:
	story_stage = index
	story_mode = mode
	story_line = line
	story_archive = archive
	story_lines = TaleCatalog.STAGES[index].intro.duplicate(true)
	if mode == "outro":
		story_lines = TaleCatalog.STAGES[index].outro.duplicate(true)
	elif archive:
		story_lines.append_array(TaleCatalog.STAGES[index].outro.duplicate(true))
	state = "story"
	clear_page()
	label(
		page,
		(
			"CAPÍTULO %02d  /  %s"
			% [
				index + 1,
				"MEMÓRIAS" if archive else ("DESFECHO" if mode == "outro" else "O ÚLTIMO FIO")
			]
		),
		Rect2(24, 28, 492, 32),
		15,
		GOLD
	)
	label(page, TaleCatalog.STAGES[index].name, Rect2(24, 82, 492, 73), 31)
	var speaker: String = story_lines[line][0]
	var actors: Array = campaign.party.duplicate()
	for id in TaleCatalog.HEROES:
		if TaleCatalog.HEROES[id].name == speaker:
			actors = [id]
	make_arena(180, actors, index)
	if actors.size() == 1:
		arena.heroes[0].position.x = 246
	panel(page, Rect2(24, 540, 492, 257))
	label(page, speaker, Rect2(44, 558, 452, 35), 21, GOLD)
	label(page, story_lines[line][1], Rect2(44, 605, 452, 166), 23)
	button(
		page,
		(
			"Próxima  →"
			if line < story_lines.size() - 1
			else (
				"Voltar ao diário"
				if archive
				else ("Entrar no combate" if mode == "intro" else "Guardar esta memória")
			)
		),
		Rect2(24, 821, 492, 60),
		advance_story,
		true
	)
	(
		button(
			page,
			"Pular diálogo" if not archive else "Fechar memória",
			Rect2(24, 895, 360, 40),
			finish_story
		)
		. add_theme_font_size_override("font_size", 16)
	)
	label(page, "%d / %d" % [line + 1, story_lines.size()], Rect2(431, 899, 85, 30), 16, MUTED)


func advance_story() -> void:
	if story_line < story_lines.size() - 1:
		show_story(story_stage, story_mode, story_line + 1, story_archive)
	else:
		finish_story()


func finish_story() -> void:
	if story_archive:
		show_journal()
	elif story_mode == "intro":
		begin_chapter_combat(story_stage)
	elif campaign.choices.has(str(story_stage)):
		if story_stage == 7:
			show_ending()
		else:
			show_map()
	else:
		show_memory_choice()


func show_memory_choice() -> void:
	state = "memory"
	clear_page()
	header("O que fica deste capítulo?", "Uma escolha permanente para a formação inteira.")
	make_arena(184, [], story_stage)
	label(page, "As páginas mudam com o que vocês levam adiante.", Rect2(24, 551, 492, 88), 26)
	button(
		page,
		"Esperança compartilhada\n+5 PV máximos para cada princesa",
		Rect2(24, 674, 492, 78),
		save_memory.bind("hope"),
		true
	)
	button(
		page,
		"Coragem para reescrever\n+1 de dano para cada princesa",
		Rect2(24, 772, 492, 78),
		save_memory.bind("power")
	)


func save_memory(choice: String) -> void:
	if state != "memory" or not campaign.choose_memory(story_stage, choice):
		return
	persist()
	if story_stage == 7:
		show_ending()
	else:
		show_map()


func show_party() -> void:
	state = "party"
	clear_page()
	header("Companheiras de jornada", "Até 3 em combate. A vanguarda recebe os ataques primeiro.")
	var names: PackedStringArray = []
	for id in campaign.party:
		names.append(TaleCatalog.HEROES[id].name)
	label(page, "ORDEM: " + "  /  ".join(names), Rect2(24, 178, 492, 46), 16, GOLD)
	var inner := scroll_area(238, 630, 6 * 181)
	var index := 0
	for id in TaleCatalog.HEROES:
		var data: Dictionary = TaleCatalog.HEROES[id]
		var y := index * 181.0
		var owned := campaign.unlocked.has(id)
		panel(inner, Rect2(0, y, 476, 169))
		if owned:
			portrait(inner, id, Vector2(78, y + 148), 0.62)
		label(inner, data.name, Rect2(133, y + 12, 325, 32), 22, data.color if owned else MUTED)
		label(
			inner,
			data.role if owned else "Recrutada ao concluir o capítulo %d" % index,
			Rect2(133, y + 48, 325, 38),
			16,
			MUTED
		)
		if owned:
			var equipped := campaign.party.has(id)
			var action := button(
				inner,
				"Retirar" if equipped else "Adicionar",
				Rect2(133, y + 108, 153, 44),
				toggle_member.bind(id),
				equipped
			)
			action.add_theme_font_size_override("font_size", 16)
			action.disabled = (
				not campaign.checkpoint.is_empty()
				or (not equipped and campaign.party.size() >= 3)
				or (equipped and campaign.party.size() == 1)
			)
			var front := button(
				inner, "Vanguarda", Rect2(300, y + 108, 158, 44), promote_member.bind(id)
			)
			front.add_theme_font_size_override("font_size", 16)
			front.disabled = (
				not equipped or campaign.party[0] == id or not campaign.checkpoint.is_empty()
			)
		else:
			label(inner, "A história abre o próximo caminho.", Rect2(133, y + 102, 325, 46), 16)
		index += 1
	if not campaign.checkpoint.is_empty():
		label(
			page,
			"Formação bloqueada durante a expedição.",
			Rect2(24, 218, 492, 26),
			14,
			Color("dfb48a")
		)
	navigation("party")


func toggle_member(id: String) -> void:
	if campaign.toggle_party(id):
		persist()
		show_party()


func promote_member(id: String) -> void:
	if campaign.promote(id):
		persist()
		show_party()


func show_upgrades() -> void:
	state = "upgrade"
	clear_page()
	if not campaign.unlocked.has(selected_hero):
		selected_hero = "scarlet"
	header(
		"Poderes de cada conto",
		"OURO  %d  •  melhorias permanentes  •  máximo nível 5" % campaign.gold
	)
	var i := 0
	for id in TaleCatalog.HEROES:
		var node := button(
			page,
			TaleCatalog.HEROES[id].name,
			Rect2(24 + (i % 3) * 168, 180 + floori(i / 3.0) * 49, 156, 42),
			select_upgrade_hero.bind(id),
			id == selected_hero
		)
		node.add_theme_font_size_override("font_size", 14)
		node.disabled = not campaign.unlocked.has(id)
		i += 1
	var data: Dictionary = TaleCatalog.HEROES[selected_hero]
	portrait(page, selected_hero, Vector2(108, 430), 0.90)
	label(page, data.name, Rect2(210, 294, 306, 39), 26, data.color)
	label(page, data.role, Rect2(210, 337, 306, 45), 17, MUTED)
	var stats := TaleCatalog.hero_stats(
		selected_hero, campaign.levels[selected_hero], campaign.choices
	)
	label(
		page,
		(
			"%d PV  •  %d dano\n%.2fs por ataque"
			% [int(stats.max_hp), int(stats.damage), stats.interval]
		),
		Rect2(210, 389, 306, 58),
		17
	)
	label(
		page,
		(
			"Conclua ou abandone a expedição para melhorar."
			if not campaign.checkpoint.is_empty()
			else data.bio
		),
		Rect2(24, 451, 492, 57),
		15,
		MUTED
	)
	for branch in 3:
		var y := 521 + branch * 114
		var rank: int = campaign.levels[selected_hero][branch]
		panel(page, Rect2(24, y, 492, 103))
		label(page, data.skills[branch][0], Rect2(40, y + 9, 306, 27), 19, data.color)
		label(page, data.skills[branch][1], Rect2(40, y + 39, 295, 47), 15, MUTED)
		var cost := campaign.upgrade_cost(selected_hero, branch)
		label(page, "NV %d / 5" % rank, Rect2(363, y + 10, 139, 26), 14, GOLD)
		var buy := button(
			page,
			"Máximo" if rank == 5 else "%d ouro  +" % cost,
			Rect2(350, y + 46, 150, 44),
			buy_upgrade.bind(branch),
			true
		)
		buy.add_theme_font_size_override("font_size", 16)
		buy.disabled = rank >= 5 or campaign.gold < cost or not campaign.checkpoint.is_empty()
	navigation("upgrade")


func select_upgrade_hero(id: String) -> void:
	if not campaign.unlocked.has(id):
		return
	selected_hero = id
	show_upgrades()


func buy_upgrade(branch: int) -> void:
	if campaign.buy_upgrade(selected_hero, branch):
		persist()
		show_upgrades()


func show_journal() -> void:
	state = "journal"
	clear_page()
	header("Páginas recuperadas", "Releia os encontros e as escolhas da campanha.")
	if campaign.cleared.has(7):
		button(page, "Reler o epílogo", Rect2(24, 179, 492, 48), show_ending, true)
	var inner := scroll_area(
		241 if campaign.cleared.has(7) else 183,
		625 if campaign.cleared.has(7) else 683,
		maxf(200, campaign.journal.size() * 139)
	)
	if campaign.journal.is_empty():
		label(
			inner,
			"O livro ainda está em branco.\nConclua o primeiro capítulo para registrar sua jornada.",
			Rect2(18, 40, 440, 140),
			23,
			MUTED
		)
	for i in campaign.journal.size():
		var entry: Dictionary = campaign.journal[i]
		var index := int(entry.stage)
		var y := i * 139
		panel(inner, Rect2(0, y, 476, 125))
		label(inner, "%02d  •  %s" % [index + 1, entry.title], Rect2(14, y + 9, 448, 44), 20)
		var memory: String = campaign.choices.get(str(index), "")
		label(
			inner,
			(
				"Memória: "
				+ (
					"Esperança"
					if memory == "hope"
					else ("Coragem" if memory == "power" else "A escolher")
				)
			),
			Rect2(14, y + 62, 272, 40),
			15,
			MUTED
		)
		(
			button(
				inner,
				"Reler",
				Rect2(332, y + 65, 130, 44),
				show_story.bind(index, "intro", 0, true)
			)
			. add_theme_font_size_override("font_size", 16)
		)
	navigation("journal")


func show_settings() -> void:
	# Entered from navigation screens; combat has a separate pause menu.
	if state in ["battle", "travel", "choice"]:
		toggle_pause()
		return
	state = "settings"
	clear_page()
	header("Seu jeito de jogar", "As preferências também são salvas automaticamente.")
	panel(page, Rect2(24, 201, 492, 177))
	label(page, "Movimento reduzido", Rect2(42, 217, 456, 34), 23)
	label(
		page,
		"Diminui balanços, ombros e textos flutuantes.\nOs quadros essenciais de ataque continuam visíveis.",
		Rect2(42, 263, 456, 59),
		17,
		MUTED
	)
	(
		button(
			page,
			"Ativado" if campaign.reduced_motion else "Desativado",
			Rect2(320, 326, 178, 40),
			toggle_motion
		)
		. add_theme_font_size_override("font_size", 16)
	)
	panel(page, Rect2(24, 402, 492, 154))
	label(page, "Velocidade de combate", Rect2(42, 419, 456, 34), 23)
	label(
		page,
		"Acelera o combate e respeita o tempo das animações.",
		Rect2(42, 462, 285, 68),
		17,
		MUTED
	)
	button(page, "%d×" % int(campaign.speed), Rect2(352, 479, 146, 50), change_default_speed, true)
	button(page, "Como jogar", Rect2(24, 590, 492, 56), show_help)
	button(page, "Créditos", Rect2(24, 664, 492, 56), show_credits)
	label(
		page,
		"Progresso salvo neste dispositivo.\nUma expedição é retomada no início do encontro atual.",
		Rect2(24, 759, 492, 70),
		17,
		MUTED
	)
	navigation("")


func toggle_motion() -> void:
	campaign.reduced_motion = not campaign.reduced_motion
	persist()
	show_settings()


func change_default_speed() -> void:
	campaign.speed = 2.0 if campaign.speed == 1.0 else 1.0
	persist()
	show_settings()


func show_help() -> void:
	state = "help"
	clear_page()
	header("Como jogar", "Você escolhe o caminho. Elas conduzem o combate.")
	var text := "1. Avance no mapa e conclua os três encontros de cada capítulo. O último é um chefe.\n\n2. Recrute princesas na história e leve até três. A primeira da lista é a vanguarda: ela recebe os ataques até cair.\n\n3. Gaste ouro em melhorias próprias de cada heroína. Repita capítulos para conseguir mais ouro.\n\n4. Entre encontros, escolha uma relíquia. Ela dura só até o fim da expedição atual.\n\n5. No desfecho, guarde uma memória: esperança dá vida; coragem aumenta dano.\n\nESC pausa o combate. Mouse ou toque controlam os botões. O progresso é salvo automaticamente."
	label(page, text, Rect2(30, 195, 480, 610), 20)
	button(page, "Voltar às opções", Rect2(24, 843, 492, 62), show_settings, true)


func show_credits() -> void:
	state = "credits"
	clear_page()
	header("Quem escreve este conto", "ROGUETALES • O ÚLTIMO FIO")
	label(
		page,
		"Criação e direção\nJoão Victor Tabosa\n\nDesenvolvimento\nGodot 4.7 • GDScript\n\nArte das heroínas\nReferências fornecidas pelo autor; sprites de teste geradas com ImageGen. Cinderela usa poses provisórias da referência.\n\nHistória\nUm encontro original inspirado nos contos clássicos.\n\nObrigado por chegar até esta página.",
		Rect2(36, 194, 468, 590),
		22
	)
	button(page, "Voltar ao início", Rect2(24, 843, 492, 62), show_menu, true)


func show_ending() -> void:
	if not campaign.cleared.has(7):
		show_map()
		return
	state = "ending"
	clear_page()
	var hope := 0
	for choice in campaign.choices.values():
		if choice == "hope":
			hope += 1
	label(page, "EPÍLOGO  /  O ÚLTIMO FIO", Rect2(24, 38, 492, 36), 16, GOLD)
	label(page, "Uma página em branco.", Rect2(24, 110, 492, 100), 39)
	make_arena(242, [], 7)
	var ending := (
		"Elas deixaram um lugar à mesa para a Costureira. O futuro continuava incerto, mas já não precisava ser solitário."
		if hope >= 4
		else "Elas entregaram a pena a cada reino. Nenhuma mão voltaria a decidir o destino de todas. Até a Costureira teria de escrever o próprio caminho."
	)
	label(page, ending, Rect2(24, 605, 492, 161), 23)
	button(page, "Ver créditos", Rect2(24, 799, 492, 58), show_credits, true)
	button(page, "Continuar explorando", Rect2(24, 878, 492, 54), show_map)


func begin_chapter_combat(index: int) -> void:
	if not campaign.can_play(index) or not campaign.checkpoint.is_empty():
		return
	run = IdleRun.new()
	run.setup(campaign, index)
	campaign.checkpoint = run.to_checkpoint()
	persist()
	build_battle()
	begin_travel()


func resume_checkpoint() -> void:
	if campaign.checkpoint.is_empty():
		show_map()
		return
	run = IdleRun.new()
	run.restore(campaign, campaign.checkpoint)
	if not run.alive():
		campaign.checkpoint.clear()
		persist()
		show_menu()
		return
	build_battle()
	if run.pending_choice:
		show_relics()
	else:
		begin_travel()


func build_battle() -> void:
	state = "travel"
	paused = false
	game_speed = campaign.speed
	clear_page()
	ally_bars.clear()
	ally_labels.clear()
	ally_clocks.clear()
	cooldowns.clear()
	stage_label = label(
		page,
		"%02d / 08   %s" % [run.stage + 1, TaleCatalog.STAGES[run.stage].name],
		Rect2(24, 21, 492, 70),
		25
	)
	enemy_label = label(page, "", Rect2(24, 106, 492, 47), 18, MUTED)
	enemy_hp = bar(page, Rect2(24, 164, 492, 12), Color("d27a91"))
	make_arena(196, [], run.stage)
	arena.speed = game_speed
	arena.sync_health(run.actors)
	for index in run.actors.size():
		var actor: Dictionary = run.actors[index]
		var data: Dictionary = TaleCatalog.HEROES[actor.id]
		var y := 553 + index * 67
		panel(page, Rect2(24, y, 492, 58))
		ally_labels.append(label(page, "", Rect2(38, y + 4, 463, 29), 16, data.color))
		ally_bars.append(bar(page, Rect2(38, y + 38, 350, 8), data.color))
		ally_clocks.append(bar(page, Rect2(402, y + 38, 99, 8), GOLD))
		cooldowns.append(0.15 + index * 0.28)
	log_label = label(page, "", Rect2(24, 764, 492, 64), 18, MUTED)
	button(page, "Pausar", Rect2(24, 847, 236, 56), toggle_pause)
	speed_button = button(
		page, "Velocidade %d×" % int(game_speed), Rect2(280, 847, 236, 56), toggle_speed
	)
	label(page, "COMBATE AUTOMÁTICO  •  ESC PARA PAUSAR", Rect2(24, 925, 492, 22), 13, MUTED)
	update_hud()


func begin_travel() -> void:
	state = "travel"
	travel_timer = 1.1
	arena.reset_effects()
	arena.walking = true
	arena.enemy_visible = false
	arena.boss = run.wave == 2
	arena.set_animation("walk")
	arena.sync_health(run.actors)
	log_label.text = "Seguindo para o encontro %d de 3…" % (run.wave + 1)
	update_hud()


func spawn_enemy() -> void:
	run.spawn_enemy()
	state = "battle"
	arena.walking = false
	arena.enemy_visible = true
	arena.set_animation("idle")
	enemy_timer = run.enemy_interval()
	for index in cooldowns.size():
		cooldowns[index] = 0.15 + index * 0.28
	log_label.text = "CHEFE À VISTA" if run.wave == 2 else "A formação encontrou resistência."
	update_hud()


func _process(delta: float) -> void:
	if state == "preview":
		update_preview()
		return
	if paused or run == null or state not in ["travel", "battle"]:
		return
	var dt := minf(delta, 0.25) * game_speed
	if state == "travel":
		travel_timer -= dt
		if travel_timer <= 0:
			spawn_enemy()
	elif state == "battle":
		run.tick_status(dt)
		if run.enemy_hp <= 0:
			resolve_enemy()
			return
		for index in run.actors.size():
			if run.actors[index].hp <= 0:
				continue
			cooldowns[index] -= dt
			if cooldowns[index] <= 0 and arena.attack(index):
				var duration: float = arena.heroes[index].get_animation_duration("attack")
				cooldowns[index] = maxf(float(run.actors[index].interval), duration + 0.06)
		enemy_timer -= dt
		arena.enemy_windup = 1.0 - enemy_timer / run.enemy_interval()
		if enemy_timer <= 0:
			enemy_timer += run.enemy_interval()
			var hit := run.hit_party()
			if not hit.is_empty():
				arena.hurt(hit.target)
				float_text(
					"−%d" % int(hit.damage) if hit.damage > 0 else "ESCUDO",
					Vector2(160, 407),
					Color("ef9baf")
				)
				arena.sync_health(run.actors)
			if not run.alive():
				finish_defeat()
				return
	hud_timer -= delta
	if hud_timer <= 0:
		update_hud()
		hud_timer = 0.08


func on_attack_hit(index: int) -> void:
	if state != "battle" or paused or run == null:
		return
	var hit := run.hit_enemy(index)
	if hit.is_empty():
		return
	float_text(("CRIT " if hit.critical else "") + str(int(hit.damage)), Vector2(343, 389), GOLD)
	if not str(hit.message).is_empty():
		log_label.text = TaleCatalog.HEROES[run.actors[index].id].name + " · " + str(hit.message)
	if run.enemy_hp <= 0:
		resolve_enemy()
	else:
		update_hud()


func resolve_enemy() -> void:
	if state != "battle":
		return
	state = "resolving"
	run.kills += 1
	arena.reset_effects()
	arena.enemy_visible = false
	campaign.gold += 3 + run.stage * 2
	if run.wave == 2:
		var result := campaign.complete_stage(run.stage)
		persist()
		show_victory(result)
	else:
		run.wave += 1
		run.pending_choice = true
		run.roll_offers()
		campaign.checkpoint = run.to_checkpoint()
		persist()
		show_relics()


func update_hud() -> void:
	if run == null or not is_instance_valid(enemy_label):
		return
	enemy_label.text = (
		("CHEFE · " if run.wave == 2 else "ENCONTRO %d / 3 · " % (run.wave + 1))
		+ str(
			(
				TaleCatalog.STAGES[run.stage].boss
				if run.wave == 2
				else TaleCatalog.STAGES[run.stage].enemy
			)
		)
	)
	if run.poison_left > 0:
		enemy_label.text += "  [veneno]"
	if run.burn_left > 0:
		enemy_label.text += "  [brasa]"
	enemy_hp.max_value = maxf(1, run.enemy_max)
	enemy_hp.value = run.enemy_hp if state == "battle" else 0
	for index in mini(run.actors.size(), ally_labels.size()):
		var actor: Dictionary = run.actors[index]
		ally_labels[index].text = (
			"%s%s    %d / %d PV%s"
			% [
				"◇ " if index == 0 else "",
				TaleCatalog.HEROES[actor.id].name,
				int(actor.hp),
				int(actor.max_hp),
				(
					"  +%d escudo" % int(actor.shield)
					if actor.shield > 0
					else ("  • caída" if actor.hp <= 0 else "")
				)
			]
		)
		ally_bars[index].max_value = actor.max_hp
		ally_bars[index].value = actor.hp
		ally_clocks[index].max_value = maxf(
			float(actor.interval), arena.heroes[index].get_animation_duration("attack") + 0.06
		)
		ally_clocks[index].value = (
			ally_clocks[index].max_value - maxf(0, cooldowns[index]) if actor.hp > 0 else 0
		)


func float_text(text: String, at: Vector2, color: Color) -> void:
	if campaign.reduced_motion:
		return
	var node := label(page, text, Rect2(at, Vector2(140, 36)), 21, color)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "position:y", at.y - 33, 0.6)
	tween.tween_property(node, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(node.queue_free)


func modal(title: String, subtitle: String) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.size = Vector2(540, 960)
	content.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.96)
	shade.size = Vector2(540, 960)
	overlay.add_child(shade)
	label(overlay, title, Rect2(32, 166, 476, 98), 32, GOLD)
	label(overlay, subtitle, Rect2(32, 278, 476, 100), 19, MUTED)


func show_relics() -> void:
	state = "choice"
	arena.reset_effects()
	arena.frozen = true
	modal(
		"Uma página, três destinos.",
		"Encontro concluído! Escolha uma relíquia.\nO efeito dura até o fim deste capítulo."
	)
	for index in run.offers.size():
		for relic in TaleCatalog.RELICS:
			if relic.id != run.offers[index]:
				continue
			var node := button(
				overlay,
				relic.title + "\n" + relic.detail,
				Rect2(32, 402 + index * 112, 476, 92),
				select_relic.bind(str(relic.id)),
				index == 0
			)
			node.add_theme_font_size_override("font_size", 18)
	(
		button(overlay, "Salvar e voltar ao início", Rect2(32, 801, 476, 52), leave_battle)
		. add_theme_font_size_override("font_size", 17)
	)


func select_relic(id: String) -> void:
	if state != "choice" or not run.offers.has(id):
		return
	run.apply_relic(id)
	campaign.checkpoint = run.to_checkpoint()
	persist()
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	arena.frozen = false
	begin_travel()


func toggle_pause() -> void:
	if state not in ["battle", "travel"]:
		return
	if paused:
		resume_battle()
		return
	paused = true
	arena.frozen = true
	modal(
		"Uma pausa na jornada.",
		"O combate está parado. O progresso é retomado no início do encontro atual após sair."
	)
	button(overlay, "Continuar", Rect2(32, 418, 476, 60), resume_battle, true)
	button(overlay, "Salvar e voltar ao início", Rect2(32, 503, 476, 56), leave_battle)
	button(overlay, "Abandonar expedição", Rect2(32, 584, 476, 56), request_abandon)


func resume_battle() -> void:
	if not paused:
		return
	paused = false
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	if is_instance_valid(arena):
		arena.frozen = false


func leave_battle() -> void:
	persist()
	paused = false
	show_menu()


func request_abandon() -> void:
	modal(
		"Reagrupar no acampamento?",
		"As relíquias e o encontro atual serão perdidos. Ouro, recrutamentos e melhorias permanecem."
	)
	button(overlay, "Abandonar e voltar", Rect2(32, 429, 476, 60), abandon_expedition, true)
	button(overlay, "Cancelar", Rect2(32, 513, 476, 56), cancel_abandon)


func cancel_abandon() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	if paused:
		paused = false
		toggle_pause()


func abandon_expedition() -> void:
	campaign.checkpoint.clear()
	persist()
	run = null
	paused = false
	show_menu()


func toggle_speed() -> void:
	game_speed = 2.0 if game_speed == 1.0 else 1.0
	campaign.speed = game_speed
	persist()
	arena.speed = game_speed
	speed_button.text = "Velocidade %d×" % int(game_speed)


func show_victory(result: Dictionary) -> void:
	state = "result"
	clear_page()
	label(page, "CAPÍTULO CONCLUÍDO", Rect2(24, 34, 492, 40), 17, GOLD)
	label(page, TaleCatalog.STAGES[run.stage].name, Rect2(24, 98, 492, 104), 34)
	var recruited: String = result.get("recruit", "")
	make_arena(239, [recruited] if not recruited.is_empty() else [], run.stage)
	if not recruited.is_empty():
		arena.heroes[0].position.x = 246
	label(
		page,
		(
			(TaleCatalog.HEROES[recruited].name + " entrou para a equipe!")
			if not recruited.is_empty()
			else "Mais uma agulha desfeita."
		),
		Rect2(24, 605, 492, 66),
		27,
		GOLD
	)
	label(
		page,
		"+%d ouro  •  %d / 8 capítulos concluídos" % [int(result.reward), campaign.cleared.size()],
		Rect2(24, 691, 492, 46),
		19,
		MUTED
	)
	button(
		page,
		"Ler o desfecho  →" if result.first else "Voltar ao mapa",
		Rect2(24, 791, 492, 62),
		show_story.bind(run.stage, "outro") if result.first else show_map,
		true
	)


func finish_defeat() -> void:
	state = "defeat"
	arena.reset_effects()
	arena.frozen = true
	campaign.checkpoint.clear()
	persist()
	modal(
		"O conto ainda não acabou.",
		"A formação caiu. O ouro conquistado permanece. Tente outra formação ou invista em melhorias."
	)
	button(overlay, "Melhorar princesas", Rect2(32, 421, 476, 60), show_upgrades, true)
	button(overlay, "Organizar equipe", Rect2(32, 505, 476, 56), show_party)
	button(
		overlay,
		"Tentar o capítulo novamente",
		Rect2(32, 585, 476, 56),
		show_chapter.bind(run.stage)
	)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and (event.physical_keycode == KEY_B or event.keycode == KEY_B):
			toggle_debug()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(debug_panel):
			debug_panel.queue_free()
			debug_panel = null
		elif state == "preview":
			show_menu()
		elif state in ["battle", "travel"]:
			toggle_pause()
		elif state not in ["choice", "memory", "story", "result"]:
			show_menu()
		get_viewport().set_input_as_handled()


func toggle_debug() -> void:
	debug_enabled = not debug_enabled
	if not debug_enabled:
		if is_instance_valid(debug_panel):
			debug_panel.queue_free()
			debug_panel = null
		if state == "preview":
			show_menu()
		return
	show_debug_panel()


func show_debug_panel() -> void:
	if not debug_enabled:
		return
	if is_instance_valid(debug_panel):
		debug_panel.queue_free()
	debug_panel = Control.new()
	debug_panel.size = Vector2(540, 960)
	content.add_child(debug_panel)
	panel(debug_panel, Rect2(24, 96, 492, 248), Color("273044"))
	label(debug_panel, "DEBUG  •  CTRL+B PARA DESATIVAR", Rect2(40, 112, 460, 32), 17, GOLD)
	label(
		debug_panel,
		(
			"Godot %s  •  %d FPS\nTela: %s  •  checkpoint: %s"
			% [
				Engine.get_version_info().string,
				int(Engine.get_frames_per_second()),
				state,
				"sim" if not campaign.checkpoint.is_empty() else "não"
			]
		),
		Rect2(40, 153, 460, 69),
		16
	)
	var lab := button(
		debug_panel, "Laboratório de animações", Rect2(40, 245, 460, 56), show_preview, true
	)
	lab.disabled = state in ["battle", "travel", "choice", "story", "memory", "result"]


func show_preview() -> void:
	if not debug_enabled:
		return
	state = "preview"
	clear_page()
	header("Laboratório de animações", "FERRAMENTAS ATIVAS • CTRL+B PARA DESATIVAR")
	var index := 0
	for id in HERO_SCENES:
		var node := button(
			page,
			TaleCatalog.HEROES[id].name,
			Rect2(24 + (index % 3) * 168, 183 + floori(index / 3.0) * 49, 156, 42),
			choose_preview.bind(id),
			selected_hero == id
		)
		node.add_theme_font_size_override("font_size", 14)
		index += 1
	make_arena(295, [selected_hero])
	arena.heroes[0].position.x = 246
	frame_label = label(page, "", Rect2(24, 649, 492, 43), 18, GOLD)
	for i in 3:
		var anim: String = ["idle", "walk", "attack"][i]
		(
			button(page, anim, Rect2(24 + i * 168, 711, 156, 48), preview_anim.bind(anim))
			. add_theme_font_size_override("font_size", 17)
		)
	var slider := HSlider.new()
	slider.position = Vector2(24, 805)
	slider.size = Vector2(492, 36)
	slider.min_value = 0.25
	slider.max_value = 2.0
	slider.step = 0.25
	slider.value = 1.0
	slider.value_changed.connect(func(value: float): arena.speed = value)
	page.add_child(slider)
	label(page, "VELOCIDADE 0,25× — 2×", Rect2(24, 769, 492, 30), 15, MUTED)
	button(page, "Voltar ao início", Rect2(24, 878, 492, 54), show_menu)


func choose_preview(id: String) -> void:
	if not debug_enabled or not HERO_SCENES.has(id):
		return
	selected_hero = id
	show_preview()


func preview_anim(anim: String) -> void:
	if not debug_enabled or state != "preview":
		return
	arena.reset_effects()
	if anim == "attack":
		arena.preview = true
		arena.attack()
	else:
		arena.set_animation(anim)


func update_preview() -> void:
	if not is_instance_valid(arena) or not is_instance_valid(frame_label):
		return
	var actor: AnimatedSprite2D = arena.heroes[0]
	frame_label.text = (
		"%s  •  %02d / %02d"
		% [
			actor.get_idle_state_label() if actor.is_idle_animation() else String(actor.animation),
			actor.frame + 1,
			actor.sprite_frames.get_frame_count(actor.animation)
		]
	)
