extends Control
## A compact, centered reward sheet; only the choices scroll on short viewports.
var game: Control
var board: PanelContainer
var column: VBoxContainer
var choices: VBoxContainer
var scroll: ScrollContainer
var shade: ColorRect

func setup(owner_ui: Control) -> void:
	game = owner_ui
	name = "RewardModal"
	set_meta("reward_modal", true)
	z_index = 3000
	shade = ColorRect.new()
	shade.set_meta("theme_decoration", true)
	shade.color = TaleTheme.c("damage_outline", .72)
	add_child(shade)
	board = PanelContainer.new()
	board.name = "RewardBoard"
	board.set_meta("theme_radius", 16)
	var style := TaleTheme.flat("surface", "ornament", 16)
	style.set_content_margin_all(22)
	board.add_theme_stylebox_override("panel", style)
	add_child(board)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	board.add_child(column)
	var header := Control.new()
	header.custom_minimum_size.y = 88
	column.add_child(header)
	var back: Button = game.button(header,"‹",Rect2(0,0,44,44),game.dismiss_reward)
	back.name = "BackWithoutReward"
	back.tooltip_text = "Voltar sem escolher · a recompensa continua disponível"
	back.add_theme_font_size_override("font_size",32)
	var title: Label = game.label(header,"Rodada vencida",Rect2(48,0,360,46),32)
	title.name = "RewardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle: Label = game.label(header,"Escolha uma melhoria",Rect2(0,48,460,32),21)
	subtitle.name = "RewardSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.resized.connect(func():
		title.position = Vector2(48,0)
		title.size = Vector2(header.size.x-96,46)
		title.add_theme_font_size_override("font_size",28 if header.size.x<500 else 32)
		subtitle.position = Vector2(0,48)
		subtitle.size = Vector2(header.size.x,32))
	scroll = ScrollContainer.new()
	scroll.name = "RewardChoices"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	choices = VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation",8)
	scroll.add_child(choices)
	var leave: Button = game.button(column,"Salvar e sair",Rect2(0,0,300,44),game.leave_battle)
	leave.name = "SaveRewardAndExit"
	resized.connect(layout)
	layout()

func add_offer(note: String, title: String, detail: String, callback: Callable) -> Button:
	var card: Button = game.button(choices,"",Rect2(0,0,400,110),callback)
	card.custom_minimum_size.y = 110
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,14)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,8)
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation",4)
	margin.add_child(body)
	game.label(body,note,Rect2(0,0,372,20),12)
	game.label(body,title,Rect2(0,0,372,32),23)
	game.label(body,detail,Rect2(0,0,372,38),16)
	body.minimum_size_changed.connect(func():
		card.custom_minimum_size.y = maxf(110,body.get_combined_minimum_size().y+16)
		layout.call_deferred())
	layout.call_deferred()
	return card

func layout() -> void:
	if not is_instance_valid(board): return
	var margin: Vector2 = game.content.position / game.content.scale
	shade.position = -margin
	shade.size = game.size / game.content.scale
	shade.color = TaleTheme.c("damage_outline",.72)
	var height := 44+88+24+44+maxi(0,choices.get_child_count()-1)*8
	for card in choices.get_children(): height += int(card.get_combined_minimum_size().y)
	board.size = Vector2(minf(700,size.x-32),minf(height,size.y*.9))
	board.position = (size-board.size)*.5
