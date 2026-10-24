extends ScrollContainer
## Allow a finger drag starting on a card to scroll instead of activating that card.
var finger:=-1
var start:=Vector2.ZERO
var previous:=Vector2.ZERO
var dragging:=false
var suppress_mouse_release:=false
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():return
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*event.position):
			suppress_mouse_release=false
			finger=event.index
			start=event.position
			previous=start
			dragging=false
		elif not event.pressed and event.index==finger:
			if dragging:
				suppress_mouse_release=true
				get_viewport().gui_release_focus()
				get_viewport().set_input_as_handled()
			finger=-1
			dragging=false
	elif event is InputEventScreenDrag and event.index==finger:
		if not dragging and event.position.distance_to(start)>10:dragging=true
		if dragging:
			var movement:Vector2=event.position-previous
			var scale_factor:Vector2=get_global_transform_with_canvas().get_scale()
			if horizontal_scroll_mode!=SCROLL_MODE_DISABLED:scroll_horizontal-=roundi(movement.x/scale_factor.x)
			if vertical_scroll_mode!=SCROLL_MODE_DISABLED:scroll_vertical-=roundi(movement.y/scale_factor.y)
			get_viewport().gui_release_focus()
			get_viewport().set_input_as_handled()
		previous=event.position

	elif event is InputEventMouseButton and not event.pressed and suppress_mouse_release:
		get_viewport().set_input_as_handled()
		suppress_mouse_release=false
