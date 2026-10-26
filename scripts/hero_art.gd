extends RefCounted
## One artwork source for combat, selection, team sheets and ability portraits.
const Alpha=preload("res://scripts/jpeg_alpha.gd")
static var bodies:Dictionary={}
static var heads:Dictionary={}
static func source_path(id:String) -> String:
	return "res://assets/ults_v2/%s_idle.webp"%id if id!="puss" else "res://assets/characters/puss/display.jpg"
static func body(id:String) -> Dictionary:
	if bodies.has(id):return bodies[id]
	var model:AnimatedSprite2D=TaleCatalog.HERO_SCENES[id].instantiate()
	var texture:Texture2D=model.sprite_frames.get_frame_texture("idle",0)
	var bounds:Rect2
	if texture is MeshTexture:
		var mesh:AABB=texture.mesh.get_aabb()
		bounds=Rect2(Vector2(mesh.position.x,mesh.position.y),Vector2(mesh.size.x,mesh.size.y))
		if texture.base_texture.resource_path.ends_with(".jpg"):
			var repaired:MeshTexture=texture.duplicate()
			repaired.base_texture=Alpha.texture(texture.base_texture.resource_path)
			texture=repaired
	else:bounds=Rect2(Vector2.ZERO,texture.get_size())
	bodies[id]={"texture":texture,"bounds":bounds,"offset":-Vector2(bounds.get_center().x,bounds.end.y),"scale":model.scale,"source":source_path(id)}
	model.free()
	return bodies[id]
static func head(id:String) -> Texture2D:
	if heads.has(id):return heads[id]
	var data:=body(id)
	var texture:Texture2D=data.texture
	var source:Texture2D
	var region:Rect2
	if texture is MeshTexture:
		source=texture.base_texture
		var uv:PackedVector2Array=texture.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		var low:=Vector2(INF,INF)
		var high:=Vector2(-INF,-INF)
		for point in uv:
			low=low.min(point)
			high=high.max(point)
		region=Rect2(low*source.get_size(),(high-low)*source.get_size())
	else:
		source=texture
		region=Rect2(Vector2.ZERO,source.get_size())
	var focus:Vector2={"peter":Vector2(.65,.21),"aladin":Vector2(.60,.23),"puss":Vector2(.56,.20)}.get(id,Vector2(.55,.16))
	var edge:=minf(region.size.y*.40,region.size.x*.95)
	var origin:=region.position+region.size*focus-Vector2.ONE*edge*.5
	origin=origin.clamp(region.position,region.end-Vector2.ONE*edge)
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
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(face)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.set_meta("portrait_source",source_path(id))
	return face
