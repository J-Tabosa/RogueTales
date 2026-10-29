extends Node
## Prepare and draw attack resources before the controller permits an action.
static var prepared:Dictionary={}
var busy:=false
var jobs:Array[Dictionary]=[]
var cursor:=0
var settle:=0
var viewport:SubViewport
var batch:Node2D
func start(models:Array,ids:Array) -> void:
	viewport=SubViewport.new()
	viewport.size=Vector2i(64,64)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	batch=Node2D.new()
	viewport.add_child(batch)
	for model in models:
		var old_animation:StringName=model.animation
		var old_frame:int=model.frame
		var old_progress:float=model.frame_progress
		for animation in model.sprite_frames.get_animation_names():
			for frame in model.sprite_frames.get_frame_count(animation):
				model.animation=animation
				model.frame=frame
				if model.has_method("sync_alpha"):model.sync_alpha()
				add_texture(model.sprite_frames.get_frame_texture(animation,frame),model.material)
		model.animation=old_animation
		model.set_frame_and_progress(old_frame,old_progress)
		if model.has_method("sync_alpha"):model.sync_alpha()
	for id in ids:
		for frame in 6:
			if preload("res://scripts/character_effects.gd").IDS.has(id):add_texture(preload("res://scripts/character_effects.gd").frame(id,frame/6.0,false))
			add_texture(preload("res://scripts/ultimate_art.gd").frame(id,frame/6.0))
	for biome in 8:add_texture(preload("res://scripts/enemy_art.gd").frame(biome,0))
	busy=not jobs.is_empty()
	if not busy:viewport.queue_free()
func add_texture(texture:Texture2D,source_material:Material=null) -> void:
	var key:=str(texture.get_instance_id())+":"+str(source_material.shader.get_instance_id() if source_material is ShaderMaterial else 0)
	if prepared.has(key) or jobs.any(func(job):return job.key==key):return
	jobs.append({"key":key,"texture":texture,"material":source_material.duplicate() if source_material!=null else null})
func _process(_delta:float) -> void:
	if not busy:return
	if settle>0:
		settle-=1
		return
	for child in batch.get_children():child.free()
	if cursor>=jobs.size():
		for job in jobs:prepared[job.key]=job.texture
		jobs.clear()
		viewport.queue_free()
		busy=false
		return
	for index in range(cursor,mini(cursor+12,jobs.size())):
		var job:Dictionary=jobs[index]
		var sprite:=Sprite2D.new()
		sprite.texture=job.texture
		sprite.material=job.material
		sprite.centered=false
		var bounds:=Rect2(Vector2.ZERO,job.texture.get_size())
		if job.texture is MeshTexture:
			var volume:AABB=job.texture.mesh.get_aabb()
			bounds=Rect2(Vector2(volume.position.x,volume.position.y),Vector2(volume.size.x,volume.size.y))
		sprite.scale=Vector2.ONE*(48.0/maxf(1,maxf(bounds.size.x,bounds.size.y)))
		sprite.position=Vector2(8,8)-bounds.position*sprite.scale
		batch.add_child(sprite)
	cursor=mini(cursor+12,jobs.size())
	settle=2
