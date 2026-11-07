extends Control
## Rotated frame artwork with a palette applied only in the dark theme.
const BAND := 22.0
const CORNER := 64.0
const CREST := Vector2(90,35)
const FOOT := 18.0
const TILE = preload("res://assets/ui/themes/shared/reward_frame/reward_frame_tile.png")
const ELBOW = preload("res://assets/ui/themes/shared/reward_frame/reward_frame_corner.png")
const CARDINAL = preload("res://assets/ui/themes/shared/reward_frame/reward_frame_cardinal.png")
const PALETTE_SHADER = preload("res://assets/ui/themes/shared/reward_frame/palette.gdshader")
var inner_corners_only := false
var available_space := Vector4.ZERO # Left, top, right, bottom, in logical units.

func _ready() -> void:
	set_meta("theme_decoration",true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(queue_redraw)
	update_theme()

func update_theme() -> void:
	if not inner_corners_only:
		if TaleTheme.mode == "dark":
			if material == null:
				var palette := ShaderMaterial.new()
				palette.shader = PALETTE_SHADER
				palette.set_shader_parameter("frame_shadow", TaleTheme.c("background"))
				palette.set_shader_parameter("frame_midtone", TaleTheme.c("secondary"))
				palette.set_shader_parameter("frame_highlight", TaleTheme.c("ornament"))
				material = palette
		else:
			material = null
	queue_redraw()

func paint_bounds() -> Rect2:
	if inner_corners_only: return Rect2(Vector2.ZERO,size)
	var reach := CREST.y-FOOT
	var left := clampf(available_space.x,0,reach)
	var top := clampf(available_space.y,0,reach)
	var right := clampf(available_space.z,0,reach)
	var bottom := clampf(available_space.w,0,reach)
	return Rect2(Vector2(-left,-top),size+Vector2(left+right,top+bottom))

func strip(origin: Vector2, angle: float, length: float) -> void:
	if length<=0: return
	draw_set_transform(origin,angle)
	var texel_scale := TILE.get_height()/BAND
	var pitch := TILE.get_width()/texel_scale
	var count := ceili(length/pitch)
	var first := (length-count*pitch)*.5
	for index in count:
		var start := first+index*pitch
		var a := maxf(0,start)
		var b := minf(length,start+pitch)
		var source := Rect2((a-start)*texel_scale,0,(b-a)*texel_scale,TILE.get_height())
		draw_texture_rect_region(TILE,Rect2(a,0,b-a,BAND),source)
	draw_set_transform(Vector2.ZERO)

func draw_inner_corners() -> void:
	var texture := TaleTheme.asset("panel_frame")
	if texture==null: return
	# Reuse the original upper-right acanthus in each theme.
	var source := Rect2(texture.get_width()*(1-350.0/1536),0,texture.get_width()*350.0/1536,texture.get_height()*330.0/1024)
	var tint := TaleTheme.asset_tint("panel_frame",.95)
	for index in 4:
		var right := index%2==1
		var bottom := index>=2
		var at := Vector2(size.x-26 if right else 26,size.y-26 if bottom else 26)
		draw_set_transform(at,0,Vector2(1 if right else -1,-1 if bottom else 1))
		draw_texture_rect_region(texture,Rect2(-14,-12,26,24),source,tint)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if size.x<4 or size.y<4: return
	if inner_corners_only:
		draw_inner_corners()
		return
	strip(Vector2(CORNER,0),0,size.x-2*CORNER)
	strip(Vector2(size.x,CORNER),PI*.5,size.y-2*CORNER)
	strip(Vector2(size.x-CORNER,size.y),PI,size.x-2*CORNER)
	strip(Vector2(0,size.y-CORNER),-PI*.5,size.y-2*CORNER)
	var corners := [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]
	var centers := [Vector2(size.x*.5,0),Vector2(size.x,size.y*.5),Vector2(size.x*.5,size.y),Vector2(0,size.y*.5)]
	var bounds := paint_bounds()
	var projection := [-bounds.position.y,bounds.end.x-size.x,bounds.end.y-size.y,-bounds.position.x]
	for index in 4:
		var angle := index*PI*.5
		draw_set_transform(corners[index],angle)
		draw_texture_rect(ELBOW,Rect2(Vector2.ZERO,Vector2.ONE*CORNER),false)
		# When the modal fills the width, tuck the crest into the existing padding.
		var shift: float = CREST.y-FOOT-projection[index]
		var at: Vector2 = centers[index]+Vector2(0,shift).rotated(angle)
		draw_set_transform(at,angle)
		draw_texture_rect(CARDINAL,Rect2(Vector2(-CREST.x*.5,FOOT-CREST.y),CREST),false)
	draw_set_transform(Vector2.ZERO)
