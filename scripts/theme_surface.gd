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

func frame_png(rect:Rect2) -> void:
	var texture:=TaleTheme.asset("panel_frame")
	if texture==null:return
	var source:=texture.get_size()
	var margin:=minf(28 if rect.size.y>=120 else 14,minf(rect.size.x,rect.size.y)*.26)
	var dx:=[rect.position.x,rect.position.x+margin,rect.end.x-margin,rect.end.x]
	var dy:=[rect.position.y,rect.position.y+margin,rect.end.y-margin,rect.end.y]
	# Source corner reservations include the full acanthus arms in the generated PNG.
	var sx:=[0.0,source.x*350/1536,source.x*(1-350.0/1536),source.x]
	var sy:=[0.0,source.y*330/1024,source.y*(1-330.0/1024),source.y]
	for y in 3:
		for x in 3:
			if x==1 and y==1:continue
			draw_texture_rect_region(texture,Rect2(dx[x],dy[y],dx[x+1]-dx[x],dy[y+1]-dy[y]),Rect2(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y]),TaleTheme.asset_tint("panel_frame",.95))

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
	if backdrop:
		if TaleTheme.is_manuscript(parent):
			Manuscript.folio(self,size)
			return
		if size.x>700:
			var corner:=TaleTheme.asset("corner_filigrane")
			if corner!=null:
				for i in 4:
					var at:=Vector2(12 if i%2==0 else size.x-12,12 if i<2 else size.y-12)
					draw_set_transform(at,0,Vector2(1 if i%2==0 else -1,1 if i<2 else -1))
					draw_texture_rect(corner,Rect2(0,0,76,76),false,TaleTheme.asset_tint("corner_filigrane",.30))
				draw_set_transform(Vector2.ZERO)
		var strip:=TaleTheme.asset("horizontal_border")
		if strip!=null:
			draw_set_transform(Vector2(0,size.y-9),0,Vector2.ONE*.028)
			draw_texture_rect(strip,Rect2(0,0,size.x/.028,strip.get_height()),true,TaleTheme.asset_tint("horizontal_border",.3))
			draw_set_transform(Vector2.ZERO)
		return
	if rank>=0:
		var tint:=TaleTheme.rarity(rank)
		draw_rect(full.grow(-1),tint,false,2)
		if size.y>40:draw_rect(full.grow(-4),Color(tint,.38),false,1)
		return
	if readout:return
	if parent is Button:
		if parent.get_meta("primary",false) and size.x>=180:frame_png(full)
		return
	if size.x>=180 and size.y>=100 or parent.name=="GoldenArtFrame":frame_png(full)
	elif size.y>=30:
		draw_rect(full.grow(-3),TaleTheme.c("ornament",.28),false,1)
	if not frame_only and size.y>=50:
		draw_line(Vector2(7,size.y-5),Vector2(size.x-7,size.y-5),TaleTheme.c("shadow",.25),2)
