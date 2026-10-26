extends Control
## Screens and orchestration. Rules: run.gd; progression: campaign.gd; content: catalog.gd.
const GameAudio = preload("res://scripts/audio.gd")
const UISkin = preload("res://scripts/ui_skin.gd")
const Arena = preload("res://scripts/arena.gd")
const HERO_SCENES = TaleCatalog.HERO_SCENES
const GOLD := Color("f2d28e")
const MUTED := Color("aab3ca")
const INK := Color("0b2927")
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
var combat_flow: RefCounted
var debug_enabled := false
var debug_roster_all := false
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
var audio: Node
var idle_label: Label
var idle_button: Button
var idle_tick := 0.0
var auto_save_tick := 0.0
var farm_timer := -1.0
var farm_stage := -1
var story_body: Label
var story_visible := 0.0
var profile_name: LineEdit
var profile_avatar := "scarlet"
var profile_avatar_label: Label
var profile_avatar_buttons: Dictionary = {}
var logical_height := 960.0
var static_portraits: Dictionary = {}
var shared_boxes: Dictionary = {}
var loading_callback: Callable
var loading_elapsed := 0.0
var loading_frames := 0
var loading_stage := 0
var loading_bar: ProgressBar


func _ready() -> void:
	campaign = TaleCampaign.new()
	campaign.load_from(save_path)
	campaign.settle_idle(int(Time.get_unix_time_from_system()))
	install_controls_theme()
	audio = Node.new()
	audio.set_script(GameAudio)
	add_child(audio)
	apply_preferences()
	persist()
	game_speed = campaign.speed
	var background := UISkin.picture(self, UISkin.FOREST, Rect2(Vector2.ZERO, size), true)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new()
	content.size = Vector2(540, 960)
	add_child(content)
	resized.connect(center_content)
	center_content()
	get_tree().auto_accept_quit = false
	show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and campaign != null:
		campaign.settle_idle(int(Time.get_unix_time_from_system()))
		campaign.save_to(save_path)
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED and campaign != null:
		persist()
		Engine.max_fps = 5
		if is_instance_valid(audio) and is_instance_valid(audio.music):
			audio.music.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED and campaign != null:
		campaign.settle_idle(int(Time.get_unix_time_from_system()))
		apply_preferences()


func center_content(usable_override: Rect2 = Rect2()) -> void:
	if content == null:
		return
	var usable := Rect2(Vector2.ZERO, size)
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var window_size := Vector2(DisplayServer.window_get_size())
		if safe.size.x > 0 and safe.size.y > 0 and window_size.x > 0 and window_size.y > 0:
			var ratio := size / window_size
			usable = usable.intersection(
				Rect2(Vector2(safe.position) * ratio, Vector2(safe.size) * ratio)
			)
	if usable_override.has_area():
		usable = usable.intersection(usable_override)
	var factor := maxf(0.01, minf(usable.size.x / 540.0, usable.size.y / 960.0))
	logical_height = clampf(usable.size.y / factor, 960.0, 1280.0)
	content.size = Vector2(540, logical_height)
	content.scale = Vector2.ONE * factor
	content.position = usable.position + (usable.size - content.size * factor) * 0.5
	relayout_page()


func box(color: Color, border := Color("34404f"), radius := 16) -> StyleBoxFlat:
	var key := "%s:%s:%d" % [color.to_html(), border.to_html(), radius]
	if shared_boxes.has(key):
		return shared_boxes[key]
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left = 14
	result.content_margin_right = 14
	shared_boxes[key] = result
	return result


func panel(parent: Node, rect: Rect2, color := INK) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	UISkin.decorate(node)
	register_layout(node)
	return node


func label(
	parent: Node, text: String, rect: Rect2, font_size := 18, color := Color("eeeae2")
) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.03, 0.9))
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Establish wrap width before text shapes its minimum size.
	node.position = rect.position
	node.size = rect.size
	node.text = text
	parent.add_child(node)
	register_layout(node)
	return node


func button(
	parent: Node, text: String, rect: Rect2, callback: Callable, primary := false
) -> Button:
	var node := Button.new()
	node.clip_text = true
	node.custom_minimum_size.y = 44
	node.text = text
	node.position = rect.position
	node.size = Vector2(rect.size.x, maxf(44, rect.size.y))
	node.add_theme_font_size_override("font_size", 19)
	node.add_theme_color_override("font_color", GOLD if primary else Color("fff1d5"))
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_pressed_color", GOLD)
	node.add_theme_color_override("font_disabled_color", Color("7c998c"))
	node.add_theme_color_override("font_shadow_color", Color("051714"))
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.add_theme_stylebox_override(
		"normal",
		box(Color(1.0, 0.75, 0.3, 0.16) if primary else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8)
	)
	node.add_theme_stylebox_override("hover", box(Color(0.8, 1.0, 0.7, 0.12), GOLD, 8))
	node.add_theme_stylebox_override("pressed", box(Color(0.0, 0.06, 0.04, 0.3), GOLD, 8))
	node.add_theme_stylebox_override(
		"disabled", box(Color(0.01, 0.04, 0.03, 0.65), Color(0, 0, 0, 0), 8)
	)
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD))
	node.pressed.connect(
		func():
			if is_instance_valid(audio):
				audio.play_effect("click")
			callback.call()
	)
	parent.add_child(node)
	UISkin.decorate(node, true)
	register_layout(node)
	return node


func bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.add_theme_stylebox_override("background", box(Color("080f18"), Color("34404f"), 5))
	node.add_theme_stylebox_override("fill", box(color, color, 5))
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	register_layout(node)
	return node


func clear_page() -> void:
	if is_instance_valid(debug_panel):
		debug_panel.queue_free()
	debug_panel = null
	for node in content.get_children():
		content.remove_child(node)
		node.queue_free()
	page = Control.new()
	page.size = Vector2(540, logical_height)
	page.clip_contents = true
	content.add_child(page)
	if state != "loading":
		loading_callback = Callable()
	overlay = null
	arena = null
	var bg := ColorRect.new()
	bg.color = Color("041d1b", 0.77)
	bg.size = Vector2(540, 960)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)
	register_layout(bg, "fill")


func header(title: String, subtitle: String) -> void:
	UISkin.picture(page, UISkin.artwork("logo"), Rect2(24, 15, 183, 51))
	UISkin.picture(page, UISkin.artwork("wallet"), Rect2(225, 17, 188, 50))
	label(page, format_gold(campaign.gold), Rect2(282, 28, 113, 25), 17, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(page, "Opções", Rect2(423, 22, 93, 40), show_settings).add_theme_font_size_override(
		"font_size", 15
	)
	label(page, title, Rect2(24, 68, 492, 53), 30)
	label(page, subtitle, Rect2(24, 126, 492, 42), 16, MUTED)


func navigation(active: String) -> void:
	var entries: Array = [
		["menu", "Início", show_menu],
		["map", "Mapa", show_map],
		["heroes", "Heróis", show_heroes],
		["journal", "Diário", show_journal],
		["profile", "Perfil", show_profile]
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
	arena.high_quality = campaign.high_quality
	var viewport := Control.new()
	viewport.position = Vector2(24, y)
	viewport.size = Vector2(492, 340)
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(viewport)
	viewport.add_child(arena)
	var rim := UISkin.decorate(viewport, false, true)
	rim.z_index = 800
	arena.attack_hit.connect(on_attack_hit)
	arena.attack_started.connect(on_attack_started)


func cache_portrait(id: String) -> void:
	if static_portraits.has(id):return
	var data:=preload("res://scripts/hero_art.gd").body(id)
	static_portraits[id]={"texture":data.texture,"scale":data.scale,"offset":data.offset,"centered":false,"bounds":data.bounds,"source":data.source}


func portrait(parent: Node, id: String, at: Vector2, factor: float = 0.68) -> void:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var actor := Sprite2D.new()
	actor.texture = data.texture
	actor.offset = data.offset
	actor.centered = data.centered
	actor.scale = data.scale * factor
	actor.position = at
	actor.texture_filter = texture_filter
	parent.add_child(actor)
	if parent == overlay:
		actor.set_meta("portrait_base", at)
		actor.position.y += (logical_height - 960.0) * 0.5


func scroll_area(y: float, height: float, total: float) -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.position = Vector2(24, y)
	scroll.size = Vector2(492, height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	page.add_child(scroll)
	register_layout(scroll, "scroll")
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(476, total)
	scroll.add_child(inner)
	return inner


func persist() -> void:
	campaign.settle_idle(int(Time.get_unix_time_from_system()))
	campaign.save_to(save_path)


func show_menu() -> void:
	state = "menu"
	paused = false
	farm_timer = -1.0
	clear_page()
	header(
		"O próximo capítulo é seu.",
		"CAMPANHA  %d / 12     •     OURO  %d" % [campaign.cleared.size(), campaign.gold]
	)
	var next := mini(campaign.cleared.size(), TaleCatalog.FINAL_CHAPTER)
	make_arena(188, [], next)
	label(
		page, "FORMAÇÃO ATIVA  ·  %d / 3" % campaign.party.size(), Rect2(40, 200, 440, 24), 14, GOLD
	)
	label(page, "Cinco vozes. Um novo destino.", Rect2(24, 543, 492, 48), 27)
	panel(page, Rect2(24, 607, 492, 101))
	label(page, "BAÚ DO ACAMPAMENTO", Rect2(40, 615, 295, 24), 14, GOLD)
	idle_label = label(page, "", Rect2(40, 646, 295, 51), 16, MUTED)
	idle_button = button(page, "Coletar", Rect2(352, 637, 148, 49), show_idle_rewards, true)
	idle_button.add_theme_font_size_override("font_size", 17)
	update_idle_display()
	var title := (
		"Continuar história  →"
		if campaign.pending_story >= 0
		else (
			"Retomar expedição  →"
			if not campaign.checkpoint.is_empty()
			else "Abrir mapa da campanha  →"
		)
	)
	button(page, title, Rect2(24, 731, 492, 58), continue_journey, true)
	(
		button(page, "Heróis e evolução", Rect2(24, 808, 236, 48), show_heroes)
		. add_theme_font_size_override("font_size", 16)
	)
	if not campaign.save_error.is_empty():
		label(page, campaign.save_error, Rect2(24, 855, 492, 26), 13, Color("ed9a9c"))
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
	header("Os doze reinos", "%d de 12 agulhas desfeitas • siga o caminho" % campaign.cleared.size())
	var inner := scroll_area(184, 684, 1000)
	var art := UISkin.picture(inner, UISkin.MAP, Rect2(0, 0, 476, 1000))
	art.stretch_mode = TextureRect.STRETCH_SCALE
	var route := Curve2D.new()
	for index in TaleCatalog.CHAPTER_COUNT:
		route.add_point(
			Vector2(63 if index % 2 == 0 else 421, 65 + index * 120),
			Vector2(0, -54),
			Vector2(0, 54)
		)
	var line := Line2D.new()
	line.points = route.tessellate()
	line.width = 5
	line.default_color = Color("f7df9e", 0.8)
	line.antialiased = true
	inner.add_child(line)
	for index in TaleCatalog.CHAPTER_COUNT:
		var data: Dictionary = TaleCatalog.STAGES[index]
		var y := 18 + index * 120.0
		var open := campaign.can_play(index)
		var done := campaign.cleared.has(index)
		var x := 107.0 if index % 2 == 0 else 14.0
		var card := button(
			inner, "", Rect2(x, y, 355, 103), show_chapter.bind(index), open and not done
		)
		card.disabled = not open
		label(card, data.name, Rect2(25, 11, 305, 52), 20, Color("fff2d3") if open else MUTED)
		label(
			card,
			(
				"Concluído • revisitar"
				if done
				else ("Entrar no capítulo  →" if open else "Conclua o capítulo anterior")
			),
			Rect2(25, 70, 305, 23),
			14,
			GOLD if open else MUTED
		)
		var badge := button(
			inner,
			"%02d" % (index + 1),
			Rect2(34 if index % 2 == 0 else 392, y + 20, 58, 58),
			show_chapter.bind(index),
			open
		)
		badge.disabled = not open
		badge.add_theme_font_size_override("font_size", 19)
	inner.get_parent().set_deferred(
		"scroll_vertical", int(maxf(0, mini(campaign.cleared.size(), TaleCatalog.FINAL_CHAPTER) * 120 - 95))
	)
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
	var info := "Recompensa: %d ouro\nEntre encontros: relíquias ou convites de heroínas." % reward
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
	if campaign.auto_repeat and campaign.cleared.has(index):
		load_chapter(index)
	else:
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
		arena.set_home(0, Vector2(246, arena.heroes[0].position.y))
	var dialogue_panel := panel(page, Rect2(24, 540, 492, 257))
	register_layout(dialogue_panel, "grow")
	label(page, speaker, Rect2(44, 558, 452, 35), 21, GOLD)
	story_body = label(page, story_lines[line][1], Rect2(44, 605, 452, 166), 23)
	register_layout(story_body, "grow")
	story_visible = 0.0
	story_body.visible_characters = -1 if campaign.text_speed == 0 else 0
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
	if (
		is_instance_valid(story_body)
		and story_body.visible_characters >= 0
		and story_body.visible_characters < story_body.get_total_character_count()
	):
		story_visible = story_body.get_total_character_count()
		story_body.visible_characters = -1
		return
	if story_line < story_lines.size() - 1:
		show_story(story_stage, story_mode, story_line + 1, story_archive)
	else:
		finish_story()


func finish_story() -> void:
	if story_archive:
		show_journal()
	elif story_mode == "intro":
		load_chapter(story_stage)
	elif campaign.choices.has(str(story_stage)):
		if story_stage == TaleCatalog.FINAL_CHAPTER:
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
	if story_stage == TaleCatalog.FINAL_CHAPTER:
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
	var inner := scroll_area(238, 630, TaleCatalog.HEROES.size() * 181)
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
			data.role if owned else campaign.unlock_text(id),
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
			(
				button(
					inner,
					"Ver requisito",
					Rect2(133, y + 108, 325, 44),
					show_unlock_details.bind(id)
				)
				. add_theme_font_size_override("font_size", 16)
			)
		index += 1
	if not campaign.checkpoint.is_empty():
		label(
			page,
			"Formação bloqueada durante a expedição.",
			Rect2(24, 218, 492, 26),
			14,
			Color("dfb48a")
		)
	navigation("heroes")


func toggle_member(id: String) -> void:
	if campaign.toggle_party(id):
		persist()
		show_party()


func promote_member(id: String) -> void:
	if campaign.promote(id):
		persist()
		show_party()


func show_upgrades() -> void:
	if not campaign.unlocked.has(selected_hero):
		selected_hero = "scarlet"
	show_hero_details(selected_hero)


func select_upgrade_hero(id: String) -> void:
	if not campaign.unlocked.has(id):
		return
	selected_hero = id
	show_upgrades()


func buy_upgrade(branch: int) -> void:
	if campaign.buy_upgrade(selected_hero, branch):
		audio.play_effect("upgrade")
		persist()
		show_hero_details(selected_hero)


func show_journal() -> void:
	state = "journal"
	clear_page()
	header("Páginas recuperadas", "Releia os encontros e as escolhas da campanha.")
	if campaign.cleared.has(TaleCatalog.FINAL_CHAPTER):
		button(page, "Reler o epílogo", Rect2(24, 179, 492, 48), show_ending, true)
	var inner := scroll_area(
		241 if campaign.cleared.has(TaleCatalog.FINAL_CHAPTER) else 183,
		625 if campaign.cleared.has(TaleCatalog.FINAL_CHAPTER) else 683,
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
	if state in ["battle", "travel", "choice"]:
		toggle_pause()
		return
	state = "settings"
	clear_page()
	header("Configurações", "Áudio, imagem e preferências salvas neste dispositivo.")
	var inner := scroll_area(184, 686, 1440)
	setting_slider(inner, "Volume da música", 0, campaign.music_volume, set_music_volume)
	setting_slider(inner, "Volume dos efeitos", 133, campaign.effects_volume, set_effects_volume)
	panel(inner, Rect2(0, 266, 476, 134))
	label(inner, "Qualidade de imagem", Rect2(17, 278, 442, 31), 22)
	label(inner, "1080 × 1920 • sprites com filtragem suave", Rect2(17, 314, 442, 27), 14, MUTED)
	(
		button(
			inner, "Alta", Rect2(17, 352, 212, 38), set_quality.bind(true), campaign.high_quality
		)
		. add_theme_font_size_override("font_size", 16)
	)
	(
		button(
			inner,
			"Leve",
			Rect2(247, 352, 212, 38),
			set_quality.bind(false),
			not campaign.high_quality
		)
		. add_theme_font_size_override("font_size", 16)
	)
	panel(inner, Rect2(0, 415, 476, 113))
	label(inner, "Fluidez / bateria", Rect2(17, 427, 442, 31), 21)
	(
		button(inner, "60 FPS", Rect2(17, 475, 212, 40), set_fps.bind(60), campaign.fps_limit == 60)
		. add_theme_font_size_override("font_size", 16)
	)
	(
		button(
			inner, "30 FPS", Rect2(247, 475, 212, 40), set_fps.bind(30), campaign.fps_limit == 30
		)
		. add_theme_font_size_override("font_size", 16)
	)
	panel(inner, Rect2(0, 542, 476, 114))
	label(inner, "Velocidade dos diálogos", Rect2(17, 554, 442, 31), 21)
	for index in 3:
		var value: int = [0, 24, 48][index]
		(
			button(
				inner,
				["Instantâneo", "Calmo", "Rápido"][index],
				Rect2(17 + index * 150, 604, 142, 40),
				set_text_speed.bind(value),
				campaign.text_speed == value
			)
			. add_theme_font_size_override("font_size", 14)
		)
	panel(inner, Rect2(0, 670, 476, 112))
	label(inner, "Movimento reduzido", Rect2(17, 682, 442, 31), 21)
	(
		button(
			inner,
			"Ativado" if campaign.reduced_motion else "Desativado",
			Rect2(17, 730, 442, 40),
			toggle_motion,
			campaign.reduced_motion
		)
		. add_theme_font_size_override("font_size", 16)
	)
	panel(inner, Rect2(0, 796, 476, 112))
	label(inner, "Velocidade de combate", Rect2(17, 808, 442, 31), 21)
	(
		button(
			inner, "%d×" % int(campaign.speed), Rect2(17, 856, 442, 40), change_default_speed, true
		)
		. add_theme_font_size_override("font_size", 16)
	)
	panel(inner, Rect2(0, 922, 476, 145))
	label(inner, "Patrulha automática", Rect2(17, 934, 442, 31), 21)
	label(
		inner,
		"Escolhe upgrades e convites; substitui o 3º espaço.\nPara ao perder ou ao sair do combate.",
		Rect2(17, 974, 442, 43),
		14,
		MUTED
	)
	(
		button(
			inner,
			"Ativada" if campaign.auto_repeat else "Desativada",
			Rect2(17, 1021, 442, 36),
			toggle_auto_repeat,
			campaign.auto_repeat
		)
		. add_theme_font_size_override("font_size", 16)
	)
	button(inner, "Como jogar", Rect2(0, 1090, 476, 50), show_help)
	button(inner, "Diário e história", Rect2(0, 1153, 476, 50), show_journal)
	button(inner, "Créditos", Rect2(0, 1216, 476, 50), show_credits)
	setting_slider(inner, "Vozes de ataque", 1283, campaign.voice_volume, set_voice_volume)
	navigation("profile")


func toggle_motion() -> void:
	campaign.reduced_motion = not campaign.reduced_motion
	persist()
	show_settings()


func change_default_speed() -> void:
	campaign.speed = float(int(campaign.speed) % 3 + 1)
	persist()
	show_settings()


func show_help() -> void:
	state = "help"
	clear_page()
	header("Como jogar", "Um conto para progredir no seu ritmo.")
	var inner := scroll_area(186, 646, 1250)
	var text := "1. CAMPANHA\nAvance pelos doze capítulos. Cada um tem dois encontros e um chefe.\n\n2. FORMAÇÃO\nVocê começa só com Scarlet, a Chapeuzinho. Entre encontros, escolha convites temporários de heroínas. Cumpra o requisito de cada uma para desbloqueá-la permanentemente; acompanhe em Heróis. Leve até três em duas linhas. Vanguarda mira a frente, atiradoras miram o fundo, magia alcança ambas e assassinas têm alta esquiva.\n\n3. EVOLUÇÃO\nGanhe ouro e EXP nos combates. Na tela Heróis, treine níveis até 30 e melhore três habilidades por princesa.\n\n4. ACAMPAMENTO\nDepois do capítulo 1, recursos acumulam mesmo com o jogo fechado, por até oito horas. Colete no baú da tela inicial.\n\n5. PATRULHA AUTOMÁTICA\nAtive nas configurações para repetir capítulos concluídos e escolher upgrades e convites automaticamente. Com a equipe cheia, a convidada substitui o terceiro espaço. A patrulha para ao perder ou sair.\n\n6. MEMÓRIAS\nEntre encontros, escolha relíquias temporárias. No desfecho, esperança aumenta vida; coragem aumenta dano permanentemente.\n\nCONTROLES\nMouse ou toque usam os botões. ESC ou Espaço pausa o combate. ULTs carregam lutando; toque nos retratos ou use 1–3 no PC. A alterna ULT automática e F11 alterna tela cheia. Progresso e preferências são salvos automaticamente."
	label(inner, text, Rect2(18, 10, 440, 1230), 19)
	button(page, "Voltar às configurações", Rect2(24, 843, 492, 62), show_settings, true)


func show_credits() -> void:
	state = "credits"
	clear_page()
	header("Quem escreve este conto", "ROGUETALES • O ÚLTIMO FIO")
	label(
		page,
		"Criação e direção\nJoão Victor Tabosa\n\nDesenvolvimento\nGodot 4.7 • GDScript\n\nArte das heroínas\nReferências fornecidas pelo autor; sprites de teste geradas com ImageGen.\n\nHistória\nUm encontro original inspirado nos contos clássicos.\n\nObrigado por chegar até esta página.",
		Rect2(36, 194, 468, 590),
		22
	)
	button(page, "Voltar ao início", Rect2(24, 843, 492, 62), show_menu, true)


func show_ending() -> void:
	if not campaign.cleared.has(TaleCatalog.FINAL_CHAPTER):
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
	make_arena(242, [], TaleCatalog.FINAL_CHAPTER)
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
	run.enable_tactics(campaign)
	campaign.checkpoint = run.to_checkpoint()
	persist()
	build_battle()
	begin_travel()


func resume_checkpoint() -> void:
	if campaign.checkpoint.is_empty():
		show_map()
		return
	show_loading(restore_checkpoint_now, int(campaign.checkpoint.stage))


func restore_checkpoint_now() -> void:
	if campaign.checkpoint.is_empty():
		show_map()
		return
	run = IdleRun.new()
	run.restore(campaign, campaign.checkpoint)
	run.enable_tactics(campaign)
	if not run.alive():
		campaign.checkpoint.clear()
		persist()
		show_menu()
		return
	campaign.checkpoint = run.to_checkpoint()
	persist()
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
		"%02d / 12   %s" % [run.stage + 1, TaleCatalog.STAGES[run.stage].name],
		Rect2(24, 21, 492, 70),
		25
	)
	enemy_label = label(page, "", Rect2(24, 106, 492, 47), 18, MUTED)
	enemy_hp = bar(page, Rect2(24, 164, 492, 12), Color("d27a91"))
	make_arena(196, run.actor_ids(), run.stage)
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
	travel_timer = 2.8
	arena.travel_progress = 0.0
	arena.reset_effects()
	arena.walking = true
	arena.enemy_visible = false
	arena.boss = run.wave == 2
	arena.set_animation("walk")
	arena.sync_health(run.actors)
	current_action("A equipe segue pela trilha…")
	update_hud()


func spawn_enemy() -> void:
	run.spawn_enemy()
	if run.tactics != null:
		combat_flow = preload("res://scripts/battle_flow.gd").new()
		combat_flow.bind(run)
		arena.sync_enemies()
	state = "battle"
	arena.walking = false
	arena.enemy_visible = true
	arena.set_animation("idle")
	enemy_timer = run.enemy_interval()
	for index in cooldowns.size():
		cooldowns[index] = 0.15 + index * 0.28
	current_action("CHEFE À VISTA" if run.wave == 2 else "Inimigos surgem no caminho")
	push_battle_log("Encontro iniciado")
	arena.entrance_left = 1.0
	update_hud()


func _process(delta: float) -> void:
	if campaign == null:
		return
	campaign.play_seconds += minf(delta, 1.0)
	idle_tick -= delta
	auto_save_tick -= delta
	if idle_tick <= 0:
		idle_tick = 1.0
		campaign.settle_idle(int(Time.get_unix_time_from_system()))
		if state == "menu":
			update_idle_display()
	if auto_save_tick <= 0:
		auto_save_tick = 30.0
		persist()
	if state == "loading":
		advance_loading(delta)
		return
	if state == "story" and is_instance_valid(story_body) and campaign.text_speed > 0:
		story_visible += delta * campaign.text_speed
		story_body.visible_characters = int(story_visible)
	if state == "result" and farm_timer >= 0:
		farm_timer -= delta
		if farm_timer <= 0:
			farm_timer = -1
			load_chapter(farm_stage)
		return
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
		if run.tactics != null:
			process_tactical_combat(dt)
		else:
			run.tick_status(dt)

	hud_timer -= delta
	if hud_timer <= 0:
		update_hud()
		hud_timer = 0.08


func on_attack_started(index: int) -> void:
	if state == "battle" and not paused and run != null:
		audio.play_attack(run.actors[index].id)


func on_attack_hit(index: int) -> void:
	if state != "battle" or paused or run == null:
		return
	var resources: Array = run.actors.map(func(actor): return {"hp": actor.hp, "shield": actor.shield})
	var hit: Dictionary
	if run.tactics != null:
		var track: Dictionary = arena.tracks[index]
		hit = run.tactics.ultimate(index, track.target) if track.ultimate else run.hit_enemy(index, track.target)
		if not hit.is_empty():
			for target in hit.get("targets", []):
				if not hit.get("evaded", false) and hit.get("target_damage",{}).get(target,hit.damage)>0:
					arena.hurt_enemy(target)
	else:
		hit = run.hit_enemy(index)
		if not hit.is_empty():
			arena.enemy.hurt()
	if hit.is_empty():
		return
	if run.tactics != null:
		arena.present_result(hit, false, index)
	if hit.damage>0:audio.play_effect("explosion" if run.actors[index].id == "scarlet" else "hit")
	if not str(hit.message).is_empty():
		current_action(TaleCatalog.HEROES[run.actors[index].id].name)
	record_result(hit, false, index, resources)
	consume_feedback()
	update_hud()


func resolve_enemy() -> void:
	if state != "battle":
		return
	state = "resolving"
	run.kills += 1
	arena.reset_effects()
	arena.enemy_visible = false
	campaign.record_enemy(run.stage, run.actor_ids())
	if run.wave == 2:
		var new_heroes := campaign.resolve_run(run.to_checkpoint(), true)
		var result := campaign.complete_stage(run.stage, run.actor_ids())
		result["unlocks"] = new_heroes
		persist()
		show_victory(result)
	else:
		run.wave += 1
		run.pending_choice = true
		run.roll_offers(campaign)
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
				(
					str(TaleCatalog.HEROES[actor.id].name)
					+ (" ✦" if not campaign.unlocked.has(actor.id) else "")
				),
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
	overlay.z_index = 1000
	overlay.size = Vector2(540, logical_height)
	content.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.96)
	shade.size = Vector2(540, 960)
	overlay.add_child(shade)
	register_layout(shade, "fill")
	label(overlay, title, Rect2(32, 166, 476, 98), 32, GOLD)
	label(overlay, subtitle, Rect2(32, 278, 476, 100), 19, MUTED)


func show_relics() -> void:
	state = "choice"
	if campaign.auto_repeat and campaign.cleared.has(run.stage):
		select_relic(run.offers[0], 2 if run.actors.size() == 3 else -1)
		return
	arena.reset_effects()
	arena.frozen = true
	if arena.feedback != null: arena.feedback.frozen = true
	modal(
		"Uma página, três destinos.",
		"Escolha uma relíquia ou convoque uma heroína.\nO upgrade vale até o fim desta run."
	)
	for index in run.offers.size():
		var offer := TaleCatalog.offer_data(run.offers[index])
		if offer.is_empty():
			continue
		var card := button(
			overlay, "", Rect2(32, 390 + index * 125, 476, 114), select_relic.bind(str(offer.id))
		)
		label(card, offer.title, Rect2(16, 7, 444, 29), 21, GOLD)
		label(card, offer.detail, Rect2(16, 40, 444, 35), 16)
		var note := "Relíquia da run"
		if offer.has("hero"):
			note = campaign.unlock_text(offer.hero)
			if run.actors.size() == 3:
				note += " • escolher substituição"
		label(card, note, Rect2(16, 82, 444, 24), 13, MUTED)
	(
		button(overlay, "Salvar e voltar ao início", Rect2(32, 801, 476, 52), leave_battle)
		. add_theme_font_size_override("font_size", 17)
	)


func select_relic(id: String, replace_index: int = -1) -> void:
	if state != "choice" or not run.offers.has(id):
		return
	var offer := TaleCatalog.offer_data(id)
	if offer.is_empty():
		return
	var applied := false
	if offer.has("hero"):
		if run.actors.size() == 3 and replace_index < 0:
			show_recruit_replacement(id)
			return
		applied = run.recruit(campaign, offer.hero, replace_index)
	else:
		applied = run.apply_relic(id)
	if not applied:
		return
	campaign.checkpoint = run.to_checkpoint()
	persist()
	build_battle()
	begin_travel()


func show_recruit_replacement(id: String) -> void:
	state = "replacement"
	var offer := TaleCatalog.offer_data(id)
	modal(
		"Quem abre espaço?",
		(
			str(TaleCatalog.HEROES[offer.hero].name)
			+ " entra no lugar de uma aliada só nesta run. A formação permanente é preservada."
		)
	)
	for index in run.actors.size():
		var actor: Dictionary = run.actors[index]
		button(
			overlay,
			(
				"Substituir "
				+ str(TaleCatalog.HEROES[actor.id].name)
				+ "\n%d / %d PV" % [int(actor.hp), int(actor.max_hp)]
			),
			Rect2(32, 402 + index * 109, 476, 90),
			confirm_replacement.bind(id, index)
		)
	button(overlay, "Voltar às opções", Rect2(32, 778, 476, 52), show_relics)


func confirm_replacement(id: String, index: int) -> void:
	if state != "replacement":
		return
	state = "choice"
	select_relic(id, index)


func toggle_pause() -> void:
	if state not in ["battle", "travel", "route_travel", "encounter_intro", "battle_outro"]:
		return
	if paused:
		resume_battle()
		return
	paused = true
	arena.frozen = true
	if arena.feedback != null: arena.feedback.frozen = true
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
		if arena.feedback != null: arena.feedback.frozen = false


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
	if not campaign.checkpoint.is_empty():
		campaign.resolve_run(campaign.checkpoint, false)
	campaign.checkpoint.clear()
	persist()
	run = null
	paused = false
	show_menu()


func toggle_speed() -> void:
	game_speed = float(int(game_speed) % 3 + 1)
	campaign.speed = game_speed
	persist()
	arena.speed = game_speed
	speed_button.text = "Velocidade %d×" % int(game_speed)


func show_victory(result: Dictionary) -> void:
	state = "result"
	audio.play_effect("win")
	farm_timer = 2.0 if not result.first and campaign.auto_repeat else -1.0
	farm_stage = run.stage
	clear_page()
	label(page, "CAPÍTULO CONCLUÍDO", Rect2(24, 34, 492, 40), 17, GOLD)
	label(page, TaleCatalog.STAGES[run.stage].name, Rect2(24, 98, 492, 104), 34)
	var unlocked_now: Array = result.get("unlocks", [])
	make_arena(
		239, unlocked_now.slice(0, 3) if not unlocked_now.is_empty() else run.actor_ids(), run.stage
	)
	if unlocked_now.size() == 1:
		arena.set_home(0, Vector2(246, arena.heroes[0].position.y))
	label(
		page,
		(
			("Desbloqueio permanente: " + hero_names(unlocked_now))
			if not unlocked_now.is_empty()
			else "Mais uma agulha desfeita."
		),
		Rect2(24, 605, 492, 66),
		27,
		GOLD
	)
	label(
		page,
		"+%d ouro  •  %d / 12 capítulos concluídos" % [int(result.reward), campaign.cleared.size()],
		Rect2(24, 691, 492, 46),
		19,
		MUTED
	)
	label(page, run_unlock_summary(), Rect2(24, 741, 492, 42), 14, GOLD)
	button(
		page,
		(
			"Ler o desfecho  →"
			if result.first
			else ("Parar patrulha e voltar" if campaign.auto_repeat else "Voltar ao mapa")
		),
		Rect2(24, 791, 492, 62),
		show_story.bind(run.stage, "outro") if result.first else show_map,
		true
	)


func finish_defeat() -> void:
	state = "defeat"
	arena.reset_effects()
	arena.frozen = true
	var unlocked_now := campaign.resolve_run(run.to_checkpoint(), false)
	campaign.checkpoint.clear()
	campaign.total_defeats += 1
	audio.play_effect("loss")
	persist()
	modal(
		"O conto ainda não acabou.",
		(
			"Ouro, EXP e requisitos cumpridos permanecem. "
			+ (
				"Desbloqueio: " + hero_names(unlocked_now)
				if not unlocked_now.is_empty()
				else "Convites e relíquias terminam nesta run."
			)
		)
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
		if is_instance_valid(overlay) and overlay.has_meta("character_inspector"):
			call("close_character_information")
		elif is_instance_valid(debug_panel):
			debug_panel.queue_free()
			debug_panel = null
		elif state == "preview":
			show_menu()
		elif state in ["battle", "travel", "route_travel", "encounter_intro", "battle_outro"]:
			toggle_pause()
		elif state == "replacement":
			show_relics()
		elif state not in ["choice", "memory", "story", "result", "loading"]:
			show_menu()
		get_viewport().set_input_as_handled()


func hero_revealed(id: String) -> bool:
	return campaign.unlocked.has(id) or (debug_enabled and debug_roster_all)

func reveal_debug_roster() -> void:
	if not debug_enabled:return
	debug_roster_all=not debug_roster_all
	show_heroes()

func toggle_debug() -> void:
	debug_enabled = not debug_enabled
	if not debug_enabled:
		debug_roster_all=false
		if state in ["heroes","hero_details"]:show_heroes()
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
	debug_panel.z_index = 2000
	debug_panel.size = Vector2(540, 960)
	debug_panel.position.x=maxf(0,(content.size.x-540)*.5)
	content.add_child(debug_panel)
	panel(debug_panel, Rect2(24, 96, 492, 420), Color("273044"))
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
	lab.disabled = (
		state
		in ["battle","travel","route_travel","encounter_intro","battle_outro","choice","replacement","story","memory","result","loading"]
	)

	var reveal:=button(debug_panel,"Ocultar personagens DEBUG" if debug_roster_all else "Revelar todos os personagens",Rect2(40,315,460,56),reveal_debug_roster,true)
	reveal.disabled=lab.disabled
	label(debug_panel,"Temporário · não altera os desbloqueios salvos.",Rect2(40,386,460,44),13,MUTED)
	button(debug_panel,"Desativar DEBUG",Rect2(40,448,460,48),toggle_debug)

func show_preview() -> void:
	if not debug_enabled:
		return
	state = "preview"
	clear_page()
	header("Laboratório de animações", "FERRAMENTAS ATIVAS • CTRL+B PARA DESATIVAR")
	var chooser := scroll_area(180, 100, ceili(HERO_SCENES.size() / 3.0) * 49)
	var index := 0
	for id in HERO_SCENES:
		var node := button(
			chooser,
			TaleCatalog.HEROES[id].name,
			Rect2((index % 3) * 160, floori(index / 3.0) * 49, 150, 42),
			choose_preview.bind(id),
			selected_hero == id
		)
		node.add_theme_font_size_override("font_size", 14)
		index += 1
	make_arena(295, [selected_hero])
	arena.set_home(0, Vector2(246, arena.heroes[0].position.y))
	frame_label = label(page, "", Rect2(24, 649, 492, 43), 18, GOLD)
	for i in 4:
		var anim: String = ["idle", "idle_blink", "walk", "attack"][i]
		(
			button(page, anim, Rect2(24 + i * 126, 711, 114, 48), preview_anim.bind(anim))
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


func show_heroes() -> void:
	state = "heroes"
	clear_page()
	header("Heróis", "%d / %d permanentes  •  %d ouro" % [campaign.unlocked.size(), TaleCatalog.HEROES.size(), campaign.gold])
	(
		button(
			page,
			"Formação · %d / 3" % campaign.party.size(),
			Rect2(24, 180, 236, 48),
			show_party,
			true
		)
		. add_theme_font_size_override("font_size", 17)
	)
	(
		button(page, "Evoluir personagem", Rect2(280, 180, 236, 48), show_upgrades)
		. add_theme_font_size_override("font_size", 17)
	)
	var inner := scroll_area(247, 620, TaleCatalog.HEROES.size() * 237)
	var row := 0
	for id in TaleCatalog.HEROES:
		var data: Dictionary = TaleCatalog.HEROES[id]
		var owned := campaign.unlocked.has(id)
		var y := row * 237.0
		panel(inner, Rect2(0, y, 476, 224))
		portrait(inner, id, Vector2(75, y + 190), 0.64)
		label(inner, data.name, Rect2(136, y + 12, 325, 32), 22, data.color)
		label(inner, data.role, Rect2(136, y + 49, 325, 30), 15, MUTED)
		if owned:
			label(
				inner,
				(
					"NÍVEL %d / 30%s"
					% [
						campaign.hero_levels[id],
						"  •  na formação" if campaign.party.has(id) else ""
					]
				),
				Rect2(136, y + 87, 325, 28),
				14,
				GOLD
			)
			(
				button(
					inner,
					"Ver atributos e evoluir  →",
					Rect2(136, y + 145, 325, 44),
					show_hero_details.bind(id)
				)
				. add_theme_font_size_override("font_size", 16)
			)
		else:
			label(inner, TaleCatalog.UNLOCKS[id].detail, Rect2(136, y + 82, 325, 54), 16)
			label(inner, campaign.unlock_text(id), Rect2(136, y + 139, 325, 23), 13, GOLD)
			(
				button(
					inner,
					"Ver requisito  →",
					Rect2(136, y + 167, 325, 29),
					show_unlock_details.bind(id)
				)
				. add_theme_font_size_override("font_size", 14)
			)
		row += 1
	navigation("heroes")


func show_unlock_details(id: String) -> void:
	if not TaleCatalog.UNLOCKS.has(id):
		return
	modal(str(TaleCatalog.HEROES[id].name), str(TaleCatalog.UNLOCKS[id].detail))
	portrait(overlay, id, Vector2(143, 681), 0.9)
	label(
		overlay,
		"Convocação como upgrade entre encontros.\n\nUma run tem dois encontros e um chefe. O vínculo é salvo ao encerrar a run.\n\nApós desbloquear, pode começar na sua formação.",
		Rect2(266, 400, 242, 279),
		17,
		MUTED
	)
	var progress := bar(overlay, Rect2(32, 715, 476, 12), TaleCatalog.HEROES[id].color)
	progress.max_value = TaleCatalog.UNLOCKS[id].goal
	progress.value = progress.max_value if campaign.unlocked.has(id) else campaign.unlock_amount(id)
	label(overlay, campaign.unlock_text(id), Rect2(32, 740, 476, 31), 18, GOLD)
	button(overlay, "Voltar aos heróis", Rect2(32, 803, 476, 54), show_heroes, true)


func hero_names(ids: Array) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(TaleCatalog.HEROES[id].name)
	return ", ".join(names)


func run_unlock_summary() -> String:
	var lines := PackedStringArray()
	for id in run.drafted:
		if campaign.unlocked.has(id):
			continue
		lines.append(str(TaleCatalog.HEROES[id].name) + ": " + campaign.unlock_text(id))
	return "\n".join(lines)


func show_hero_details(id: String) -> void:
	if not campaign.unlocked.has(id):
		return
	selected_hero = id
	state = "hero"
	clear_page()
	var data: Dictionary = TaleCatalog.HEROES[id]
	header(data.name, "HERÓIS  /  %s  •  %d ouro" % [data.role, campaign.gold])
	portrait(page, id, Vector2(118, 399), 1.0)
	label(
		page, "NÍVEL %d / 30" % campaign.hero_levels[id], Rect2(253, 180, 263, 33), 23, data.color
	)
	var stats := TaleCatalog.hero_stats(
		id, campaign.levels[id], campaign.choices, campaign.hero_levels[id]
	)
	label(
		page,
		(
			"%d PV  •  %d dano\n%.2fs entre ataques"
			% [int(stats.max_hp), int(stats.damage), stats.interval]
		),
		Rect2(253, 225, 263, 62),
		18
	)
	var xp_bar := bar(page, Rect2(253, 304, 263, 10), data.color)
	xp_bar.max_value = campaign.hero_next_xp(id)
	xp_bar.value = campaign.hero_xp[id]
	label(
		page,
		"EXP %d / %d" % [campaign.hero_xp[id], campaign.hero_next_xp(id)],
		Rect2(253, 318, 263, 26),
		14,
		MUTED
	)
	var train := button(
		page,
		(
			"Nível máximo"
			if campaign.hero_levels[id] >= 30
			else "Subir nível · %d ouro" % campaign.hero_level_cost(id)
		),
		Rect2(253, 354, 263, 49),
		train_hero,
		true
	)
	train.add_theme_font_size_override("font_size", 16)
	train.disabled = not campaign.can_level_hero(id)
	label(
		page,
		"Conclua a expedição para treinar." if not campaign.checkpoint.is_empty() else data.bio,
		Rect2(24, 422, 492, 56),
		15,
		MUTED
	)
	for branch in 3:
		var y := 493 + branch * 112
		var rank: int = campaign.levels[id][branch]
		panel(page, Rect2(24, y, 492, 102))
		label(page, data.skills[branch][0], Rect2(40, y + 9, 295, 28), 19, data.color)
		label(page, data.skills[branch][1], Rect2(40, y + 42, 290, 47), 14, MUTED)
		label(page, "HABILIDADE %d / 5" % rank, Rect2(349, y + 8, 152, 28), 12, GOLD)
		var buy := button(
			page,
			"Máximo" if rank >= 5 else "%d ouro  +" % campaign.upgrade_cost(id, branch),
			Rect2(350, y + 47, 150, 44),
			buy_upgrade.bind(branch),
			true
		)
		buy.add_theme_font_size_override("font_size", 16)
		buy.disabled = (
			rank >= 5
			or campaign.gold < campaign.upgrade_cost(id, branch)
			or not campaign.checkpoint.is_empty()
		)
	button(page, "← Coleção", Rect2(24, 838, 236, 38), show_heroes).add_theme_font_size_override(
		"font_size", 16
	)
	navigation("heroes")


func train_hero() -> void:
	if campaign.level_hero(selected_hero):
		audio.play_effect("upgrade")
		persist()
		show_hero_details(selected_hero)


func show_profile() -> void:
	state = "profile"
	clear_page()
	header("Perfil", "Sua jornada, suas conquistas e suas companheiras.")
	panel(page, Rect2(24, 181, 492, 223))
	portrait(page, campaign.avatar, Vector2(103, 384), 0.83)
	label(page, campaign.player_name, Rect2(207, 198, 294, 37), 27, GOLD)
	label(page, "AVENTUREIRO · NÍVEL %d" % campaign.player_level, Rect2(207, 242, 294, 30), 16)
	var xp_bar := bar(page, Rect2(207, 281, 291, 9), GOLD)
	xp_bar.max_value = campaign.player_next_xp()
	xp_bar.value = campaign.player_xp
	label(
		page,
		"EXP %d / %d" % [campaign.player_xp, campaign.player_next_xp()],
		Rect2(207, 299, 291, 28),
		14,
		MUTED
	)
	(
		button(page, "Editar perfil", Rect2(207, 341, 291, 43), edit_profile)
		. add_theme_font_size_override("font_size", 16)
	)
	label(
		page,
		(
			"%d VITÓRIAS   %d INIMIGOS   %d / 12 CAPÍTULOS"
			% [campaign.total_wins, campaign.total_kills, campaign.cleared.size()]
		),
		Rect2(24, 420, 492, 35),
		15,
		GOLD
	)
	var inner := scroll_area(469, 397, TaleCampaign.ACHIEVEMENTS.size() * 128 + 100)
	for index in TaleCampaign.ACHIEVEMENTS.size():
		var item: Dictionary = TaleCampaign.ACHIEVEMENTS[index]
		var y := index * 128.0
		panel(inner, Rect2(0, y, 476, 115))
		label(inner, item.title, Rect2(14, y + 9, 448, 31), 21)
		label(inner, item.detail, Rect2(14, y + 48, 287, 52), 15, MUTED)
		var done := campaign.claimed.has(item.id)
		var collect := button(
			inner,
			"Coletado" if done else "+%d ouro" % item.reward,
			Rect2(319, y + 55, 142, 43),
			claim_milestone.bind(str(item.id)),
			not done
		)
		collect.add_theme_font_size_override("font_size", 16)
		collect.disabled = done or not campaign.achievement_ready(item.id)
	label(
		inner,
		(
			"OURO GANHO %d  •  OURO INVESTIDO %d\nTEMPO EM JOGO %dh %02dmin  •  DERROTAS %d"
			% [
				campaign.total_gold,
				campaign.total_spent,
				int(campaign.play_seconds / 3600),
				int(campaign.play_seconds / 60) % 60,
				campaign.total_defeats
			]
		),
		Rect2(14, TaleCampaign.ACHIEVEMENTS.size() * 128, 448, 75),
		14,
		MUTED
	)
	navigation("profile")


func edit_profile() -> void:
	profile_avatar = campaign.avatar
	profile_avatar_label = null
	profile_avatar_buttons.clear()
	modal("Seu nome no conto.", "Escolha seu nome e um personagem recrutado para o retrato.")
	profile_name = LineEdit.new()
	profile_name.position = Vector2(32, 395)
	profile_name.size = Vector2(476, 58)
	profile_name.max_length = 20
	profile_name.text = campaign.player_name
	profile_name.add_theme_font_size_override("font_size", 23)
	profile_name.add_theme_stylebox_override("normal", box(Color("092a25"), GOLD, 9))
	profile_name.add_theme_stylebox_override("focus", box(Color("10392f"), GOLD, 9))
	overlay.add_child(profile_name)
	register_layout(profile_name)
	var avatar_scroll := ScrollContainer.new()
	avatar_scroll.position = Vector2(32, 477)
	avatar_scroll.size = Vector2(476, 165)
	avatar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(avatar_scroll)
	register_layout(avatar_scroll)
	var avatar_grid := Control.new()
	avatar_grid.custom_minimum_size = Vector2(456, ceili(campaign.unlocked.size() / 2.0) * 57)
	avatar_scroll.add_child(avatar_grid)
	var index := 0
	for id in campaign.unlocked:
		var choice := button(
			avatar_grid,
			TaleCatalog.HEROES[id].name,
			Rect2((index % 2) * 233, floori(index / 2.0) * 57, 220, 46),
			select_avatar.bind(id)
		)
		choice.add_theme_font_size_override("font_size", 16)
		profile_avatar_buttons[id] = choice
		index += 1
	select_avatar(profile_avatar)
	button(overlay, "Salvar perfil", Rect2(32, 713, 476, 58), save_profile, true)
	button(overlay, "Cancelar", Rect2(32, 788, 476, 46), show_profile)


func select_avatar(id: String) -> void:
	if not campaign.unlocked.has(id):
		return
	profile_avatar = id
	for candidate in profile_avatar_buttons:
		var choice: Button = profile_avatar_buttons[candidate]
		choice.add_theme_stylebox_override(
			"normal", box(Color("123d32"), GOLD if candidate == id else Color("426957"))
		)
		choice.add_theme_color_override("font_color", GOLD if candidate == id else Color("eeeae2"))
	if is_instance_valid(profile_avatar_label):
		profile_avatar_label.text = "Retrato: " + str(TaleCatalog.HEROES[id].name)
	else:
		profile_avatar_label = label(
			overlay,
			"Retrato: " + str(TaleCatalog.HEROES[id].name),
			Rect2(32, 654, 476, 33),
			17,
			GOLD
		)


func save_profile() -> void:
	var nickname := profile_name.text.strip_edges()
	if nickname.is_empty():
		nickname = "Viajante"
	campaign.player_name = nickname.substr(0, 20)
	if campaign.unlocked.has(profile_avatar):
		campaign.avatar = profile_avatar
	persist()
	show_profile()


func claim_milestone(id: String) -> void:
	if campaign.claim_achievement(id):
		audio.play_effect("achievement")
		persist()
		show_profile()


func show_idle_rewards() -> void:
	campaign.settle_idle(int(Time.get_unix_time_from_system()))
	var reward := campaign.idle_reward()
	if reward.gold <= 0:
		return
	modal(
		"O acampamento prosperou.",
		(
			"Recursos acumulados em %dh %02dmin.\nA experiência vai para os integrantes da formação."
			% [int(reward.seconds / 3600), int(reward.seconds / 60) % 60]
		)
	)
	label(
		overlay,
		"+%d OURO\n+%d EXP PARA A FORMAÇÃO" % [reward.gold, reward.xp],
		Rect2(32, 410, 476, 132),
		28,
		GOLD
	)
	button(overlay, "Coletar recursos", Rect2(32, 594, 476, 62), claim_idle_rewards, true)
	button(overlay, "Guardar para depois", Rect2(32, 680, 476, 52), show_menu)


func claim_idle_rewards() -> void:
	var reward := campaign.claim_idle(int(Time.get_unix_time_from_system()))
	if not reward.is_empty():
		audio.play_effect("upgrade")
		persist()
	show_menu()


func setting_slider(
	parent: Node, title: String, y: float, value: float, callback: Callable
) -> void:
	panel(parent, Rect2(0, y, 476, 119))
	label(parent, title, Rect2(17, y + 12, 442, 30), 21)
	var slider := HSlider.new()
	slider.position = Vector2(17, y + 65)
	slider.size = Vector2(442, 36)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.value_changed.connect(callback)
	parent.add_child(slider)


func set_music_volume(value: float) -> void:
	campaign.music_volume = value
	audio.apply_volume(value, campaign.effects_volume, campaign.voice_volume)
	persist()


func set_effects_volume(value: float) -> void:
	campaign.effects_volume = value
	audio.apply_volume(campaign.music_volume, value, campaign.voice_volume)
	persist()


func set_quality(value: bool) -> void:
	campaign.high_quality = value
	apply_preferences()
	persist()
	show_settings()


func set_fps(value: int) -> void:
	campaign.fps_limit = value
	apply_preferences()
	persist()
	show_settings()


func set_text_speed(value: int) -> void:
	campaign.text_speed = value
	persist()
	show_settings()


func toggle_auto_repeat() -> void:
	campaign.auto_repeat = not campaign.auto_repeat
	persist()
	if state == "chapter":
		show_chapter(viewed_stage)
	else:
		show_settings()


func apply_preferences() -> void:
	Engine.max_fps = campaign.fps_limit
	texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if campaign.high_quality
		else CanvasItem.TEXTURE_FILTER_LINEAR
	)
	if is_instance_valid(arena):
		arena.high_quality = campaign.high_quality
	if is_instance_valid(audio):
		audio.apply_volume(campaign.music_volume, campaign.effects_volume, campaign.voice_volume)


func update_idle_display() -> void:
	if not is_instance_valid(idle_label):
		return
	var reward := campaign.idle_reward()
	idle_label.text = (
		"%d ouro  •  %d EXP\n%s"
		% [
			reward.gold,
			reward.xp,
			"Até 8h de acúmulo" if campaign.idle_rate() > 0 else "Libere concluindo o capítulo 1"
		]
	)
	if is_instance_valid(idle_button):
		idle_button.disabled = reward.gold <= 0


func format_gold(amount: int) -> String:
	if amount >= 1000000:
		return "%.1f M" % (amount / 1000000.0)
	if amount >= 10000:
		return "%.1f mil" % (amount / 1000.0)
	return str(amount)


func register_layout(node: Control, kind := "auto") -> void:
	var parent := node.get_parent()
	if parent != page and parent != overlay:
		return
	if not node.has_meta("base_rect"):
		node.set_meta("base_rect", Rect2(node.position, node.size))
	if kind == "auto":
		kind = "center" if parent == overlay else ("bottom" if node.position.y >= 780 else "fixed")
	node.set_meta("layout_kind", kind)
	place_control(node)


func place_control(node: Control) -> void:
	if not node.has_meta("base_rect"):
		return
	var base: Rect2 = node.get_meta("base_rect")
	var extra := logical_height - 960.0
	node.position = base.position
	node.size = base.size
	match str(node.get_meta("layout_kind", "fixed")):
		"fill":
			node.size = Vector2(540, logical_height)
		"bottom":
			node.position.y += extra
		"center":
			node.position.y += extra * 0.5
		"scroll", "grow":
			node.size.y += extra


func relayout_page() -> void:
	if not is_instance_valid(page):
		return
	page.size = Vector2(540, logical_height)
	for child in page.get_children():
		if child is Control:
			place_control(child)
	if is_instance_valid(overlay):
		overlay.size = Vector2(540, logical_height)
		for child in overlay.get_children():
			if child is Control:
				place_control(child)
			elif child is Sprite2D and child.has_meta("portrait_base"):
				child.position = (
					child.get_meta("portrait_base") + Vector2(0, (logical_height - 960.0) * 0.5)
				)


func load_chapter(index: int) -> void:
	if not campaign.can_play(index) or not campaign.checkpoint.is_empty():
		return
	show_loading(begin_chapter_combat.bind(index), index)


func show_loading(callback: Callable, index: int) -> void:
	if state == "loading":
		return
	state = "loading"
	paused = false
	clear_page()
	loading_callback = callback
	loading_elapsed = 0.0
	loading_frames = 0
	loading_stage = index
	var veil := page.get_child(0) as ColorRect
	veil.color = Color("041d1b", 0.24)
	var logo := UISkin.picture(page, UISkin.artwork("logo"), Rect2(30, 245, 480, 164))
	register_layout(logo, "center")
	var subtitle := label(page, "O ÚLTIMO FIO", Rect2(32, 414, 476, 37), 23, GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	register_layout(subtitle, "center")
	var title := label(
		page,
		"%02d  •  %s" % [index + 1, TaleCatalog.STAGES[index].name],
		Rect2(48, 518, 444, 72),
		25
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	register_layout(title, "center")
	var frame := panel(page, Rect2(48, 622, 444, 46))
	register_layout(frame, "center")
	loading_bar = bar(page, Rect2(72, 639, 396, 12), GOLD)
	register_layout(loading_bar, "center")
	loading_bar.max_value = 100
	loading_bar.value = 10
	var caption := label(
		page, "Abrindo caminho entre os contos…", Rect2(32, 690, 476, 40), 17, MUTED
	)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	register_layout(caption, "center")


func advance_loading(delta: float) -> void:
	loading_elapsed += minf(delta, 0.25)
	loading_frames += 1
	if loading_frames == 2:
		Arena.Enemy.warm(loading_stage)
	if is_instance_valid(loading_bar):
		loading_bar.value = minf(95, 15 + loading_elapsed * 250)
	# A short transition yields presentation frames; it never pretends to download data.
	var duration := 0.12 if campaign.reduced_motion else 0.3
	if loading_frames >= 2 and loading_elapsed >= duration:
		var callback := loading_callback
		loading_callback = Callable()
		if callback.is_valid():
			callback.call()


func install_controls_theme() -> void:
	theme = Theme.new()
	for control in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", control, box(Color("07241e"), Color("214b3a"), 5))
		theme.set_stylebox("grabber", control, box(Color("b8a465"), Color("526b42"), 5))
		theme.set_stylebox("grabber_highlight", control, box(GOLD, GOLD, 5))
		theme.set_stylebox("grabber_pressed", control, box(Color("90c393"), GOLD, 5))
	theme.set_stylebox("slider", "HSlider", box(Color("07241e"), Color("426957"), 4))
	theme.set_stylebox("grabber_area", "HSlider", box(Color("7bba8a"), GOLD, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(GOLD, GOLD, 4))


func set_voice_volume(value: float) -> void:
	campaign.voice_volume = value
	audio.apply_volume(campaign.music_volume, campaign.effects_volume, value)
	persist()


func process_tactical_combat(dt: float) -> void:
	if arena.hit_stop > 0 or arena.intro_left > 0: return
	if not run.alive():
		if not arena.is_action_busy(): finish_defeat()
		return
	if run.enemy_hp <= 0:
		if not arena.is_action_busy(): resolve_enemy()
		return
	run.tick_status(dt)
	consume_feedback()
	for target in run.tactics.last_dot_targets:
		arena.hurt_enemy(target, true)
	if run.enemy_hp <= 0:
		if not arena.is_action_busy(): resolve_enemy()
		return
	if combat_flow == null:
		return
	combat_flow.advance(dt)
	if not combat_flow.active.is_empty():
		if not arena.is_action_busy():
			combat_flow.complete()
		return
	if arena.is_action_busy():
		return
	combat_flow.waiting -= dt
	if combat_flow.waiting > 0:
		return
	combat_flow.auto_ult=campaign.auto_ult
	var entry: Dictionary = combat_flow.next_action()
	if entry.is_empty():
		return
	var index: int = entry.index
	if entry.side == "ally":
		var ultimate: bool = entry.get("ultimate", false) or ((campaign.auto_ult or (run.expedition and run.actors[index].id=="alice")) and run.tactics.ultimate_ready(index))
		var target: int = run.tactics.target_for(index)
		if arena.attack(index, target, ultimate):
			if ultimate and not run.tactics.reserve_ultimate(index):
				arena.reset_effects()
				return
			entry["ultimate"] = ultimate
			combat_flow.begin(entry)
			current_action(TaleCatalog.HEROES[run.actors[index].id].name)
	else:
		var intent: Dictionary = run.tactics.commit_intent(index) if run.expedition else {}
		if intent.get("key","")=="sleep":
			combat_flow.begin(entry)
			var skipped:Dictionary=run.hit_party(index)
			arena.damage_number("SONO · TURNO PERDIDO",arena.foe_homes[index]+Vector2(0,-arena.human_height()),Color("c5a4f1"))
			push_battle_log(str(run.tactics.enemies[index].name)+" perdeu o turno por Sono")
			combat_flow.complete()
			update_hud()
			return
		var target: int = int(intent.target) if not intent.is_empty() else run.tactics.choose_target(run.tactics.enemies[index], run.actors)
		if arena.begin_enemy_attack(index, target):
			arena.enemy_track["support"] = str(intent.get("key", "")) in ["prepare", "banner", "stagger", "pull"] or (intent.get("key") == "copy" and intent.get("copy") == "rapunzel")
			combat_flow.begin(entry)
			current_action(str(run.tactics.enemies[index].name))
	update_hud()


func on_enemy_attack_hit(index: int) -> void:
	if state != "battle" or paused or run == null:
		return
	var resources: Array = run.actors.map(func(actor): return {"hp": actor.hp, "shield": actor.shield})
	var hit: Dictionary = run.hit_party(index)
	if hit.is_empty():
		return
	if not hit.get("non_attack", false):
		arena.enemy_strike(index, hit.target)
		if hit.damage > 0:
			for target in hit.get("targets", [hit.target]):
				if float(hit.get("target_damage", {}).get(target, hit.damage)) > 0: arena.hurt(target)
	arena.present_result(hit, true, index)
	if not hit.get("non_attack", false): audio.play_effect("hit")
	record_result(hit, true, index, resources)
	consume_feedback()
	arena.sync_health(run.actors)
	update_hud()


func try_ultimate(index: int) -> bool:
	if state != "battle" or paused or run == null or run.tactics == null or index < 0 or index >= run.actors.size():
		return false
	var actor: Dictionary = run.actors[index]
	if actor.id=="aladin":
		call("show_wishes")
		return true
	if actor.hp <= 0 or not run.tactics.ultimate_ready(index) or actor.ult_pending or actor.get("ult_queued", false) or arena.tracks[index].time >= 0:
		return false
	if arena.is_action_busy():
		if combat_flow == null or not combat_flow.queue_ultimate(index):
			return false
		update_hud()
		return true
	var target: int = run.tactics.target_for(index)
	if not arena.attack(index, target, true):
		return false
	if not run.tactics.reserve_ultimate(index):
		arena.tracks[index].time = -1.0
		return false
	if combat_flow != null:
		combat_flow.begin({"side": "ally", "index": index, "manual": true, "ultimate": true})
	current_action(str(TaleCatalog.HEROES[actor.id].name))
	update_hud()
	return true


func current_action(message: String) -> void:
	if is_instance_valid(log_label): log_label.text = message

func push_battle_log(message: String) -> void:
	if is_instance_valid(log_label): log_label.text = message

func consume_feedback() -> void:
	pass

func record_result(_hit: Dictionary, _hostile: bool, _index: int, _before: Array) -> void:
	pass
