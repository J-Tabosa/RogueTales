extends ScrollContainer
## Own touch gestures from press to release. Native/emulated button releases
## must not turn a completed swipe into a selection and rebuild the carousel.
var finger:=-1
var start:=Vector2.ZERO
var previous:=Vector2.ZERO
var swiping:=false
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():return
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION and finger>=0:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and get_global_rect().has_point(event.position):
			finger=event.index
			start=event.position
			previous=start
			swiping=false
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==finger:
			get_viewport().set_input_as_handled()
			_cancel_buttons(self)
			var tap:bool=not swiping and event.position.distance_to(start)<=12 and get_global_rect().has_point(event.position)
			finger=-1
			if tap:_tap(self,event.position)
	elif event is InputEventScreenDrag and event.index==finger:
		if event.position.distance_to(start)>12:swiping=true
		if swiping:
			scroll_horizontal-=roundi((event.position.x-previous.x)/maxf(.01,get_global_transform().get_scale().x))
			_cancel_buttons(self)
		previous=event.position
		get_viewport().set_input_as_handled()
func _tap(node: Node,at: Vector2) -> bool:
	for child in node.get_children():
		if child is BaseButton and child.is_visible_in_tree() and not child.disabled and child.get_global_rect().has_point(at):
			child.pressed.emit()
			return true
		if _tap(child,at):return true
	return false
func _cancel_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:child.set_pressed_no_signal(false)
		_cancel_buttons(child)
