extends Control
## Theme-colored PNG artwork is drawn unchanged; gameplay colors stay independent.
const Manuscript = preload("res://scripts/manuscript_art.gd")
var frame_only := false
var backdrop := false
var wash: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_meta("theme_decoration", true)
	resized.connect(queue_redraw)
	update_theme()

func update_theme() -> void:
	var colors:Array[Color]
	if backdrop:
		colors=[TaleTheme.c("background").lerp(TaleTheme.c("surface_top"),.18),TaleTheme.c("background"),TaleTheme.c("background_bottom")]
	else:colors=TaleTheme.surface_colors(get_parent())
	var gradient := Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.48,1])
	gradient.colors=PackedColorArray(colors)
	wash=GradientTexture2D.new()
	wash.gradient=gradient
	wash.width=32
	wash.height=128
	wash.fill_from=Vector2.ZERO
	wash.fill_to=Vector2(.35,1)
	queue_redraw()

func _draw() -> void:
	if size.x<4 or size.y<4:return
	var full:=Rect2(Vector2.ZERO,size)
	var parent:=get_parent() as Control
	var rank:=TaleTheme.rarity_of(parent)
	var readout:bool=parent.get_meta("combat_readout",false)
	if parent.has_meta("manuscript_role"):
		Manuscript.frame(self,size,str(parent.get_meta("manuscript_role")),parent)
		return
	if not frame_only and wash!=null:
		draw_texture_rect(wash,full,false)
		if not readout:
			var grain:=TaleTheme.asset("surface_texture")
			if grain!=null:
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE*.38)
				draw_texture_rect(grain,Rect2(Vector2.ZERO,size/.38),true,TaleTheme.asset_tint("surface_texture",.13 if backdrop else .09))
				draw_set_transform(Vector2.ZERO)
		if size.y>=180 and size.x>=200 and rank<0 and not readout:
			var rosette:=TaleTheme.asset("mandala_watermark")
			var extent:=minf(size.x*.80,size.y*.86)
			if rosette!=null:draw_texture_rect(rosette,Rect2(size*.5-Vector2.ONE*extent*.5,Vector2.ONE*extent),false,TaleTheme.asset_tint("mandala_watermark",.055 if backdrop else .045))
	if backdrop:return
	if rank>=0:
		var tint:=TaleTheme.rarity(rank)
		draw_rect(full.grow(-1),tint,false,2)
		if size.y>40:draw_rect(full.grow(-4),Color(tint,.38),false,1)
		return
	if readout:return
	if parent is Button:return
	# Only intentional framed content has a border; generic columns stay open.
	if parent.name == "GoldenArtFrame" or parent.get_meta("visual_frame",false):
		Manuscript.frame(self,size,"arena",parent)
