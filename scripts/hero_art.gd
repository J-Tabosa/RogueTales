extends RefCounted
## HD UI art is independent of the small combat animation cells.
const Alpha=preload("res://scripts/jpeg_alpha.gd")
const FOCUS={"scarlet":Vector2(.50,.16),"rapunzel":Vector2(.58,.15),"snow_white":Vector2(.55,.15),"mulan":Vector2(.57,.15),"ariel":Vector2(.54,.16),"joao":Vector2(.55,.16),"maria":Vector2(.55,.15),"alice":Vector2(.56,.16),"matches":Vector2(.65,.18),"peter":Vector2(.73,.22),"aladin":Vector2(.61,.21),"puss":Vector2(.60,.19)}
static var bodies:Dictionary={}
static var heads:Dictionary={}
static func source_path(id:String) -> String:
	var restored:="res://assets/portraits_hd/%s.png"%id
	if ResourceLoader.exists(restored):return restored
	return "res://assets/ults_v2/%s_portrait.webp"%id if id!="puss" else "res://assets/characters/puss/display.jpg"
static func body(id:String) -> Dictionary:
	if bodies.has(id):return bodies[id]
	var path:=source_path(id)
	var texture:Texture2D=Alpha.texture(path) if path.ends_with(".jpg") else load(path)
	var used:Rect2=Rect2(texture.get_image().get_used_rect())
	var model:AnimatedSprite2D=TaleCatalog.HERO_SCENES[id].instantiate()
	bodies[id]={"texture":texture,"bounds":used,"offset":-Vector2(used.get_center().x,used.end.y),"scale":model.scale,"source":path}
	model.free()
	return bodies[id]
static func head(id:String) -> Texture2D:
	if heads.has(id):return heads[id]
	var data:=body(id)
	var source:Texture2D=data.texture
	var extent:=source.get_size()
	var edge:=minf(extent.x*.52,extent.y*.34)
	var focus:Vector2=FOCUS.get(id,Vector2(.55,.16))
	var origin:=extent*focus-Vector2.ONE*edge*.5
	origin=origin.clamp(Vector2.ZERO,extent-Vector2.ONE*edge)
	var crop:=AtlasTexture.new()
	crop.atlas=source
	crop.region=Rect2(origin,Vector2.ONE*edge)
	crop.filter_clip=true
	heads[id]=crop
	return crop
static func place_head(parent:Control,id:String) -> TextureRect:
	var face:=TextureRect.new()
	face.name="CurrentHeroFace"
	face.texture=head(id)
	face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(face)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.set_meta("portrait_source",source_path(id))
	return face
