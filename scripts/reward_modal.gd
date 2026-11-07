extends Control
## A centered reward sheet; the frame grows around the unchanged choice cards.
var game: Control
var board: PanelContainer
var column: VBoxContainer
var choices: VBoxContainer
var scroll: ScrollContainer
var shade: ColorRect
var fine_frame: Panel
var choices_holder: Control
var background: Control
var ornament_frame: Control
var corner_details: Control

func setup(owner_ui: Control) -> void:
	game = owner_ui
	name = "RewardModal"
	set_meta("reward_modal", true)
	set_meta("theme_decoration", true)
	z_index = 3000
	shade = ColorRect.new()
	shade.set_meta("theme_decoration", true)
	shade.color = TaleTheme.c("damage_outline", .72)
	add_child(shade)
	background = preload("res://scripts/theme_surface.gd").new()
	background.name = "RewardSurface"
	background.surface_inset = 22
	background.artwork_frame = false
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(background)
	ornament_frame = preload("res://scripts/reward_frame.gd").new()
	ornament_frame.name = "RewardOrnamentalFrame"
	add_child(ornament_frame)
	board = PanelContainer.new()
	board.name = "RewardBoard"
	board.set_meta("theme_decoration",true)
	var style := StyleBoxEmpty.new()
	style.set_content_margin_all(22)
	board.add_theme_stylebox_override("panel", style)
	add_child(board)
	fine_frame = Panel.new()
	fine_frame.name = "RewardInnerFrame"
	fine_frame.set_meta("theme_decoration",true)
	fine_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(fine_frame)
	var inset := MarginContainer.new()
	for side in ["left","top","right","bottom"]: inset.add_theme_constant_override("margin_"+side,16)
	board.add_child(inset)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	inset.add_child(column)
	var header := Control.new()
	header.custom_minimum_size.y = 112
	column.add_child(header)
	var back: Button = game.button(header,"–",Rect2(0,12,44,44),game.dismiss_reward)
	back.name = "BackWithoutReward"
	back.tooltip_text = "Minimizar"
	back.accessibility_name = "Minimizar"
	back.add_theme_font_size_override("font_size",32)
	var bold := FontVariation.new()
	bold.base_font = TaleTheme.HEADING
	bold.variation_opentype = {"weight":700.0}
	var regular := FontVariation.new()
	regular.base_font = TaleTheme.HEADING
	regular.variation_opentype = {"weight":400.0}
	var title: Label = game.label(header,"Rodada vencida",Rect2(56,12,360,46),32)
	title.name = "RewardTitle"
	title.set_meta("theme_font",bold)
	title.add_theme_font_override("font",bold)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle: Label = game.label(header,"Escolha uma melhoria",Rect2(0,64,460,32),21)
	subtitle.name = "RewardSubtitle"
	subtitle.set_meta("theme_font",regular)
	subtitle.add_theme_font_override("font",regular)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.resized.connect(func():
		title.position = Vector2(56,12)
		title.size = Vector2(header.size.x-112,46)
		title.add_theme_font_size_override("font_size",28 if header.size.x<500 else 32)
		subtitle.position = Vector2(0,64)
		subtitle.size = Vector2(header.size.x,32)
		back.position = Vector2(header.size.x-52,12))
	choices_holder = Control.new()
	choices_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices_holder.resized.connect(layout_choices)
	column.add_child(choices_holder)
	scroll = ScrollContainer.new()
	scroll.name = "RewardChoices"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	choices_holder.add_child(scroll)
	choices = VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation",8)
	scroll.add_child(choices)
	var footer := MarginContainer.new()
	footer.add_theme_constant_override("margin_top",10)
	column.add_child(footer)
	var leave: Button = game.button(footer,"Salvar e sair",Rect2(0,0,300,44),game.leave_battle)
	leave.name = "SaveRewardAndExit"
	corner_details = preload("res://scripts/reward_frame.gd").new()
	corner_details.name = "RewardCornerDetails"
	corner_details.inner_corners_only = true
	add_child(corner_details)
	resized.connect(layout)
	update_theme()
	layout()

func update_theme() -> void:
	if not is_instance_valid(fine_frame): return
	# Refresh the tinted frame even when the general adapter skips shader nodes.
	ornament_frame.update_theme()
	var line := TaleTheme.flat("surface","ornament",8)
	line.draw_center = false
	line.set_content_margin_all(0)
	fine_frame.add_theme_stylebox_override("panel",line)
	layout.call_deferred()

func layout_choices() -> void:
	if not is_instance_valid(scroll): return
	# Reserve the scrollbar inside the new right-hand padding, outside the cards.
	var gutter := scroll.get_v_scroll_bar().get_combined_minimum_size().x
	scroll.size = Vector2(choices_holder.size.x+gutter,choices_holder.size.y)

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
	var card_width := minf(700,size.x-32)-44
	choices.custom_minimum_size.x = card_width
	var height := 76+112+24+54+maxi(0,choices.get_child_count()-1)*8
	for card in choices.get_children(): height += int(card.get_combined_minimum_size().y)
	board.size = Vector2(card_width+76,minf(height,size.y*.9))
	board.position = (size-board.size)*.5
	for decoration in [background,ornament_frame,corner_details]:
		decoration.position = board.position
		decoration.size = board.size
		decoration.queue_redraw()
	ornament_frame.available_space = Vector4(board.position.x,board.position.y,size.x-board.get_rect().end.x,size.y-board.get_rect().end.y)
	layout_choices()
