extends Control
## Viewport modal: fixed header/footer and exactly one scrollable body.
const ModalSkin=preload("res://scripts/ui_skin.gd")
var board:Panel
var shade:ColorRect
var title_label:Label
var subtitle_label:Label
var scroll:ScrollContainer
var body:VBoxContainer
var footer:HBoxContainer
var legacy_host:Control
var legacy_canvas:Control
var options:GridContainer
var legacy:Array[Control]=[]
var ready_to_adopt:=false
var collecting:=false
var full_height:=false
func setup(title:String,subtitle:String) -> void:
	set_meta("viewport_modal",true)
	set_meta("manuscript_battle",true)
	z_index=3000
	mouse_filter=Control.MOUSE_FILTER_STOP
	shade=ColorRect.new()
	shade.color=TaleTheme.c("background",.88)
	shade.set_meta("theme_shade_alpha",.88)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board=Panel.new()
	board.name="ModalFrame"
	board.set_meta("manuscript_role","modal")
	add_child(board)
	ModalSkin.decorate(board,false,true)
	title_label=Label.new()
	title_label.text=title
	title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_override("font",TaleTheme.HEADING)
	title_label.set_meta("theme_heading",true)
	board.add_child(title_label)
	subtitle_label=Label.new()
	subtitle_label.text=subtitle
	subtitle_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size",14)
	board.add_child(subtitle_label)
	scroll=ScrollContainer.new()
	scroll.name="ModalBodyScroll"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	board.add_child(scroll)
	body=VBoxContainer.new()
	body.name="ModalBody"
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	footer=HBoxContainer.new()
	footer.name="ModalFooter"
	footer.add_theme_constant_override("separation",10)
	board.add_child(footer)
	resized.connect(layout)
	child_entered_tree.connect(adopt_later)
	ready_to_adopt=true
	layout()
func adopt_later(_node:Node) -> void:
	if not ready_to_adopt or collecting:return
	collecting=true
	collect_legacy.call_deferred()
func collect_legacy() -> void:
	collecting=false
	for child in get_children():
		if not child is Control or child==shade or child==board:continue
		if child is Button and child.get_meta("modal_option",false):
			if options==null:
				options=GridContainer.new()
				options.name="RewardOptions"
				options.add_theme_constant_override("h_separation",12)
				options.add_theme_constant_override("v_separation",12)
				body.add_child(options)
			child.reparent(options)
			child.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			child.custom_minimum_size=Vector2(1,160)
			var inset:=MarginContainer.new()
			inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,14)
			inset.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var column:=VBoxContainer.new()
			column.mouse_filter=Control.MOUSE_FILTER_IGNORE
			column.add_theme_constant_override("separation",8)
			var labels:Array[Node]=child.get_children().filter(func(n):return n is Label)
			child.add_child(inset)
			inset.add_child(column)
			for label in labels:
				label.reparent(column)
				label.custom_minimum_size=Vector2(1,0)
				label.add_theme_font_size_override("font_size",maxi(14,label.get_theme_font_size("font_size")))
				label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			child.resized.connect(func():child.custom_minimum_size.y=maxf(160,column.get_combined_minimum_size().y+28))
		elif child is BaseButton and child.position.y>=760:
			child.reparent(footer)
			child.custom_minimum_size=Vector2(1,48)
			child.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		else:
			if legacy_canvas==null:
				legacy_host=Control.new()
				legacy_host.name="LegacyBody"
				legacy_host.custom_minimum_size.x=1
				body.add_child(legacy_host)
				legacy_canvas=Control.new()
				legacy_host.add_child(legacy_canvas)
			child.set_meta("modal_source_rect",child.get_meta("base_rect",child.get_rect()))
			child.reparent(legacy_canvas)
			legacy.append(child)
	layout()
func layout() -> void:
	if board==null or size.x<1:return
	var width:=minf(920,size.x*.92)
	var inner:=width-40
	var large:=width>=700
	title_label.add_theme_font_size_override("font_size",26 if large else 21)
	title_label.position=Vector2(20,18)
	title_label.size=Vector2(inner,1)
	var title_h:=maxf(32,title_label.get_minimum_size().y)
	title_label.size.y=title_h
	subtitle_label.position=Vector2(20,24+title_h)
	subtitle_label.size=Vector2(inner,1)
	var subtitle_h:=maxf(24,subtitle_label.get_minimum_size().y)
	subtitle_label.size.y=subtitle_h
	var header_h:=title_h+subtitle_h+20
	var footer_h:=48.0 if footer.get_child_count()>0 else 0.0
	if options!=null:options.columns=3 if large else 1
	if legacy_canvas!=null:
		var top:=INF
		var bottom:=0.0
		for node in legacy:
			var rect:Rect2=node.get_meta("modal_source_rect")
			top=minf(top,rect.position.y)
			bottom=maxf(bottom,rect.end.y)
		var factor:=minf(1,inner/508.0)
		legacy_canvas.scale=Vector2.ONE*factor
		legacy_canvas.position=Vector2(maxf(0,(inner-508*factor)*.5),0)
		legacy_host.custom_minimum_size.y=(bottom-top+12)*factor
		for node in legacy:
			var rect:Rect2=node.get_meta("modal_source_rect")
			node.position=rect.position-Vector2(16,top)
			node.size=rect.size
	var natural:=body.get_combined_minimum_size().y+header_h+footer_h+64
	var height:=minf(size.y*.9,maxf(260,natural))
	if full_height:height=size.y*.9
	board.size=Vector2(width,height)
	board.position=(size-board.size)*.5
	scroll.position=Vector2(20,header_h+20)
	scroll.size=Vector2(inner,maxf(40,height-header_h-footer_h-56))
	footer.position=Vector2(20,height-footer_h-20)
	footer.size=Vector2(inner,footer_h)
	for child in footer.get_children():
		if child is Button:child.add_theme_font_size_override("font_size",16)
