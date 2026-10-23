extends ScrollContainer
## Handle real touchscreen drags before child Buttons consume the release.
var finger := -1
var start := Vector2.ZERO
var previous := Vector2.ZERO
var swiping := false
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and get_global_rect().has_point(event.position):
			finger=event.index
			start=event.position
			previous=start
			swiping=false
		elif not event.pressed and event.index==finger:
			if swiping:
				get_viewport().set_input_as_handled()
				_cancel_buttons(self)
			finger=-1
	elif event is InputEventScreenDrag and event.index==finger:
		if event.position.distance_to(start)>12: swiping=true
		if swiping:
			scroll_horizontal-=roundi((event.position.x-previous.x)/maxf(.01,get_global_transform().get_scale().x))
			_cancel_buttons(self)
			get_viewport().set_input_as_handled()
		previous=event.position
func _cancel_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton: child.set_pressed_no_signal(false)
		_cancel_buttons(child)
