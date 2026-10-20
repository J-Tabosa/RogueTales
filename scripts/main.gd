extends Control
## Small prototype: UI and battle orchestration. Run data lives in run.gd.
const Arena = preload("res://scripts/arena.gd")
const GOLD := Color("e9c488")
const MUTED := Color("96a4b4")
const INK := Color("101823")
var run: IdleRun
var state := "menu"
var paused := false
var game_speed := 1.0
var hero_timer := 0.0
var enemy_timer := 0.0
var travel_timer := 0.0
var best := 0
var wins := 0
var content: Control
var page: Control
var overlay: Control
var arena: Node2D
var hero_hp: ProgressBar
var enemy_hp: ProgressBar
var stage_label: Label
var enemy_label: Label
var life_label: Label
var stats_label: Label
var log_label: Label
var relic_label: Label
var route_label: Label
var pause_button: Button
var speed_button: Button
var frame_label: Label


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://progress.cfg") == OK:
		best = int(config.get_value("progress", "best", 0))
		wins = int(config.get_value("progress", "wins", 0))
	content = Control.new()
	content.size = Vector2(540, 960)
	add_child(content)
	resized.connect(center_content)
	center_content()
	show_menu()


func center_content() -> void:
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
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func button(
	parent: Node, text: String, rect: Rect2, callback: Callable, primary := false
) -> Button:
	var node := Button.new()
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
	node.position = rect.position
	node.size = rect.size
	node.show_percentage = false
	node.add_theme_stylebox_override("background", box(Color("080f18"), Color("34404f"), 5))
	node.add_theme_stylebox_override("fill", box(color, color, 5))
	parent.add_child(node)
	return node


func clear_page() -> void:
	for node in content.get_children():
		content.remove_child(node)
		node.queue_free()
	page = Control.new()
	content.add_child(page)
	overlay = null


func make_arena(y: float) -> void:
	arena = Node2D.new()
	arena.set_script(Arena)
	var viewport := Control.new()
	viewport.position = Vector2(24, y)
	viewport.size = Vector2(492, 340)
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(viewport)
	viewport.add_child(arena)
	arena.bomb_hit.connect(on_bomb_hit)


func show_menu() -> void:
	state = "menu"
	paused = false
	clear_page()
	label(page, "ROGUETALES", Rect2(24, 26, 492, 30), 17, GOLD)
	label(page, "Era uma vez…\numa explosão.", Rect2(24, 65, 492, 117), 42)
	label(page, "IDLE RPG  /  UMA NOVA JORNADA A CADA RUN", Rect2(24, 193, 492, 28), 14, MUTED)
	make_arena(247)
	arena.enemy_visible = true
	label(page, "SCARLET · A BOMBARDEIRA", Rect2(40, 255, 420, 25), 14, GOLD)
	panel(page, Rect2(24, 610, 492, 102))
	label(page, "Você escolhe. Ela luta.", Rect2(42, 624, 456, 29), 22)
	label(
		page,
		"3 fases • chefes • relíquias aleatórias\nCombate automático, escolhas entre as fases.",
		Rect2(42, 658, 456, 45),
		17,
		MUTED
	)
	label(
		page,
		"RECORDE  %d / 9       EXPEDIÇÕES VENCIDAS  %d" % [best, wins],
		Rect2(24, 738, 492, 30),
		15,
		GOLD
	)
	button(page, "Começar expedição   →", Rect2(24, 791, 492, 62), start_run, true)
	button(page, "Testar sprites", Rect2(24, 867, 492, 52), show_preview)


func start_run() -> void:
	run = IdleRun.new()
	game_speed = 1.0
	paused = false
	clear_page()
	label(page, "ROGUETALES", Rect2(24, 22, 300, 26), 17, GOLD)
	button(page, "Menu", Rect2(407, 23, 109, 44), show_menu)
	stage_label = label(page, "", Rect2(24, 73, 492, 39), 26)
	route_label = label(page, "", Rect2(24, 121, 492, 38), 17, GOLD)
	enemy_label = label(page, "", Rect2(24, 162, 492, 29), 18)
	enemy_hp = bar(page, Rect2(24, 197, 492, 10), Color("d27583"))
	make_arena(221)
	panel(page, Rect2(24, 582, 492, 137))
	label(page, "SCARLET", Rect2(42, 595, 245, 26), 20, GOLD)
	life_label = label(page, "", Rect2(320, 595, 175, 26), 17)
	hero_hp = bar(page, Rect2(42, 633, 456, 12), Color("78c5a5"))
	stats_label = label(page, "", Rect2(42, 660, 456, 42), 16, MUTED)
	relic_label = label(page, "", Rect2(24, 735, 492, 44), 16, GOLD)
	log_label = label(page, "", Rect2(24, 787, 492, 45), 18, MUTED)
	pause_button = button(page, "Pausar", Rect2(24, 853, 236, 56), toggle_pause)
	speed_button = button(page, "Velocidade  1×", Rect2(280, 853, 236, 56), toggle_speed)
	label(page, "COMBATE AUTOMÁTICO  •  ESC PARA PAUSAR", Rect2(24, 925, 492, 22), 13, MUTED)
	begin_travel()


func begin_travel() -> void:
	state = "travel"
	travel_timer = 1.4
	arena.stage = run.stage
	arena.boss = run.wave == 2
	arena.enemy_visible = false
	arena.reset_effects()
	arena.walking = true
	arena.set_animation("walk")
	log_label.text = "Avançando para o próximo encontro…"
	update_hud()


func spawn_enemy() -> void:
	run.spawn_enemy()
	arena.walking = false
	arena.set_animation("idle")
	arena.enemy_visible = true
	state = "battle"
	hero_timer = 0.25
	enemy_timer = 2.0
	log_label.text = "Chefe à vista!" if run.wave == 2 else "Scarlet encontrou um inimigo."
	update_hud()


func _process(delta: float) -> void:
	if state == "preview":
		frame_label.text = (
			"Quadro %02d / %02d  •  %s"
			% [
				arena.hero.frame + 1,
				arena.hero.sprite_frames.get_frame_count(arena.hero.animation),
				arena.hero.animation
			]
		)
		return
	if paused:
		return
	var dt := delta * game_speed
	if state == "travel":
		travel_timer -= dt
		if travel_timer <= 0:
			spawn_enemy()
	elif state == "battle":
		hero_timer -= dt
		enemy_timer -= dt
		if hero_timer <= 0:
			hero_timer += maxf(run.interval, arena.hero.get_animation_duration("attack") + 0.05)
			arena.attack()
		if enemy_timer <= 0:
			enemy_timer += 2.0
			var amount := run.hit_hero()
			float_text("−%d" % int(amount), Vector2(90, 433), Color("ed9a9c"))
			update_hud()
			if run.hp <= 0:
				finish_run(false)


func on_bomb_hit() -> void:
	if state != "battle":
		return
	var hit := run.hit_enemy()
	float_text(("CRÍTICO " if hit.critical else "") + str(int(hit.damage)), Vector2(309, 410), GOLD)
	if run.enemy_hp <= 0:
		run.kills += 1
		arena.enemy_visible = false
		if run.wave == 2:
			if run.stage == 2:
				finish_run(true)
			else:
				show_relics()
		else:
			run.wave += 1
			begin_travel()
	update_hud()


func update_hud() -> void:
	stage_label.text = str(run.stage + 1) + " · " + IdleRun.STAGES[run.stage].name
	route_label.text = "01 BOSQUE   /   02 RUÍNAS   /   03 CALDEIRA"
	enemy_label.text = (
		("CHEFE · " + str(IdleRun.STAGES[run.stage].boss))
		if run.wave == 2
		else str(IdleRun.STAGES[run.stage].enemy)
	)
	enemy_label.text += "   •   %d / 3" % (run.wave + 1)
	enemy_hp.max_value = maxf(1, run.enemy_max)
	enemy_hp.value = run.enemy_hp if state == "battle" else 0
	hero_hp.max_value = run.max_hp
	hero_hp.value = run.hp
	life_label.text = "%d / %d PV" % [int(run.hp), int(run.max_hp)]
	stats_label.text = (
		"DANO %d    INTERVALO %.2fs    CRÍTICO %d%%\nARMADURA %d    CURA / ACERTO %d"
		% [int(run.damage), run.interval, int(run.crit * 100), int(run.armor), int(run.leech)]
	)
	relic_label.text = (
		"RELÍQUIAS %d   •   INIMIGOS DERROTADOS %d / 9" % [run.relics.size(), run.kills]
	)


func float_text(text: String, at: Vector2, color: Color) -> void:
	var node := label(page, text, Rect2(at, Vector2(200, 40)), 23, color)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "position:y", at.y - 45, 0.7)
	tween.tween_property(node, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(node.queue_free)


func modal(title: String, subtitle: String) -> void:
	overlay = Control.new()
	overlay.size = Vector2(540, 960)
	content.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.94)
	shade.size = Vector2(540, 960)
	overlay.add_child(shade)
	label(overlay, title, Rect2(32, 190, 476, 65), 35, GOLD)
	label(overlay, subtitle, Rect2(32, 266, 476, 62), 18, MUTED)


func show_relics() -> void:
	state = "choice"
	arena.reset_effects()
	modal(
		"Uma página, três destinos.",
		"Fase concluída! Escolha uma relíquia.\nA melhoria vale até o fim desta expedição."
	)
	var choices := IdleRun.RELICS.duplicate(true)
	choices.shuffle()
	for i in 3:
		var relic: Dictionary = choices[i]
		var node := button(
			overlay,
			relic.title + "\n" + relic.detail,
			Rect2(32, 361 + i * 117, 476, 97),
			select_relic.bind(str(relic.id))
		)
		node.add_theme_font_size_override("font_size", 18)


func select_relic(id: String) -> void:
	if state != "choice":
		return
	run.apply_relic(id)
	run.stage += 1
	run.wave = 0
	content.remove_child(overlay)
	overlay.queue_free()
	overlay = null
	begin_travel()


func finish_run(victory: bool) -> void:
	state = "result"
	arena.reset_effects()
	best = maxi(best, run.kills)
	if victory:
		wins += 1
	var config := ConfigFile.new()
	config.set_value("progress", "best", best)
	config.set_value("progress", "wins", wins)
	config.save("user://progress.cfg")
	modal(
		"Fim do conto." if victory else "A cesta ficou vazia.",
		(
			"Três fases vencidas!"
			if victory
			else "Scarlet caiu. Uma nova tentativa traz novas escolhas."
		)
	)
	label(
		overlay,
		(
			"%d / 9 inimigos derrotados\n%d relíquias coletadas\nRecorde: %d / 9"
			% [run.kills, run.relics.size(), best]
		),
		Rect2(32, 363, 476, 130),
		23
	)
	button(overlay, "Nova expedição", Rect2(32, 545, 476, 62), start_run, true)
	button(overlay, "Tela inicial", Rect2(32, 626, 476, 58), show_menu)


func toggle_pause() -> void:
	if state not in ["battle", "travel"]:
		return
	paused = not paused
	arena.frozen = paused
	pause_button.text = "Continuar" if paused else "Pausar"


func toggle_speed() -> void:
	game_speed = 2.0 if game_speed == 1.0 else 1.0
	arena.speed = game_speed
	speed_button.text = "Velocidade  %d×" % int(game_speed)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == "preview":
			show_menu()
		else:
			toggle_pause()


func show_preview() -> void:
	clear_page()
	state = "preview"
	label(page, "LABORATÓRIO DE SPRITES", Rect2(24, 30, 492, 35), 23, GOLD)
	label(page, "Veja os quadros dentro da própria Godot.", Rect2(24, 81, 492, 36), 19, MUTED)
	make_arena(200)
	arena.hero.position.x = 246
	frame_label = label(page, "", Rect2(24, 558, 492, 40), 20, GOLD)
	button(page, "Idle · 10", Rect2(24, 624, 150, 58), preview_anim.bind("idle"))
	button(page, "Walk · 6", Rect2(195, 624, 150, 58), preview_anim.bind("walk"))
	button(page, "Ataque · 10", Rect2(366, 624, 150, 58), preview_anim.bind("attack"))
	var slider := HSlider.new()
	slider.position = Vector2(24, 733)
	slider.size = Vector2(492, 36)
	slider.min_value = 0.25
	slider.max_value = 2.0
	slider.step = 0.25
	slider.value = 1.0
	slider.value_changed.connect(func(value: float): arena.speed = value)
	page.add_child(slider)
	label(page, "VELOCIDADE DA ANIMAÇÃO  0,25× — 2×", Rect2(24, 696, 492, 30), 16, MUTED)
	button(page, "Tela inicial", Rect2(24, 850, 492, 60), show_menu)


func preview_anim(anim: String) -> void:
	arena.reset_effects()
	arena.preview = false
	arena.set_animation(anim)
	# Loop attack only here, without dealing damage.
	arena.hero.sprite_frames.set_animation_loop("attack", anim == "attack")
