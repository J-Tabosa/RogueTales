extends SceneTree
## Whole-pose geometry on a fixed logical canvas. FX never change anatomical scale.
func _initialize() -> void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ults_v2/FRAME_LAYOUT.json"))
	for id in data.heroes:
		var frames:=SpriteFrames.new()
		frames.remove_animation("default")
		frames.resource_local_to_scene=true
		var hero:Dictionary=data.heroes[id]
		for animation in ["idle","idle_blink","walk","attack","ultimate"]:
			frames.add_animation(animation)
			frames.set_animation_loop(animation,animation in ["walk"])
			frames.set_animation_speed(animation,{"idle":4,"idle_blink":4,"walk":8,"attack":12,"ultimate":6}[animation])
			var source:String="idle" if animation in ["idle","idle_blink","walk"] else animation
			var texture:Texture2D=load("res://assets/ults_v2/%s_%s.webp"%[id,source])
			for at in hero[source].size():
				var index:int=int(hero.pose_order[at]) if animation=="ultimate" else at
				var item:Dictionary=hero[source][index]
				var r:Array=item.region
				var b:Array=item.local_bounds
				var vertices:=PackedVector3Array([Vector3(b[0],b[1],0),Vector3(b[0]+b[2],b[1],0),Vector3(b[0]+b[2],b[1]+b[3],0),Vector3(b[0],b[1]+b[3],0)])
				var uvs:=PackedVector2Array([Vector2(r[0],r[1]),Vector2(r[0]+r[2],r[1]),Vector2(r[0]+r[2],r[1]+r[3]),Vector2(r[0],r[1]+r[3])])
				for n in 4:uvs[n]/=texture.get_size()
				var arrays:=[]
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX]=vertices
				arrays[Mesh.ARRAY_TEX_UV]=uvs
				arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
				var mesh:=ArrayMesh.new()
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var pose:=MeshTexture.new()
				pose.base_texture=texture
				pose.mesh=mesh
				pose.image_size=Vector2(data.logical_size,data.logical_size)
				frames.add_frame(animation,pose)
		ResourceSaver.save(frames,"res://assets/ults_v2/%s_frames.tres"%id)
		var path:="res://scenes/heroes/%s.tscn"%id
		var scene:=FileAccess.get_file_as_string(path).replace("offset = Vector2(-256, -480)","offset = Vector2(-384, -608)")
		FileAccess.open(path,FileAccess.WRITE).store_string(scene)
		print("MESH FRAMES ",id)
	quit()
