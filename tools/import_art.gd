extends SceneTree
const ANCHOR := Vector2(1400,1400)
const CANVAS := Vector2(2800,1600)
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	var sheets: Array=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if args[1]=="convert":
		for sheet in sheets:
			var source:=Image.load_from_file("res://"+str(sheet.source))
			assert(source!=null,str(sheet))
			var output: String="res://"+str(sheet.output)
			DirAccess.make_dir_recursive_absolute(output.get_base_dir())
			if sheet.kind!="arena":
				source.convert(Image.FORMAT_RGBA8)
				var data:=source.get_data()
				var alpha:=PackedByteArray()
				alpha.resize(source.get_width()*source.get_height())
				for at in alpha.size():alpha[at]=data[at*4+3]
				var mask:=Image.create_from_data(source.get_width(),source.get_height(),false,Image.FORMAT_L8,alpha)
				assert(mask.save_png(output.get_basename()+"_alpha.png")==OK)
			source.convert(Image.FORMAT_RGB8)
			assert(source.save_jpg(output,0.97)==OK)
		quit()
		return
	var heroes: Dictionary={}
	for sheet in sheets:
		if sheet.kind in ["effects","arena"]:continue
		var id: String=sheet.hero
		if not heroes.has(id):
			var frames:=SpriteFrames.new()
			frames.remove_animation("default")
			for name in ["idle","idle_blink","walk","attack"]:
				frames.add_animation(name)
				frames.set_animation_speed(name,{"idle":2,"idle_blink":12,"walk":12,"attack":10}[name])
				frames.set_animation_loop(name,name=="walk")
			heroes[id]=frames
		var source: Texture2D=load("res://"+str(sheet.output))
		var ownership:=FileAccess.get_file_as_bytes(sheet.mask)
		var heights:Array=[]
		for f in sheet.frames.slice(0,4):heights.append(float(f.bounds[3]))
		heights.sort()
		var density:=400.0/float(heights[heights.size()/2])
		if sheet.kind=="attack":density=400.0/maxf(sheet.frames[0].bounds[3],sheet.frames[-1].bounds[3])
		var poses:Array[Texture2D]=[]
		for at in sheet.frames.size():
			var b:Array=sheet.frames[at].bounds
			var bitmap:=BitMap.new()
			bitmap.create(Vector2i(b[2],b[3]))
			for y in int(b[3]):
				for x in int(b[2]):
					if ownership[(y+int(b[1]))*source.get_width()+x+int(b[0])]==at+1:bitmap.set_bit(x,y,true)
			poses.append(mesh_texture(source,bitmap.opaque_to_polygons(Rect2i(0,0,b[2],b[3]),0.8),Vector2(b[0],b[1]),Vector2(-float(b[2])*0.5,-float(b[3])),density))
		var frames: SpriteFrames=heroes[id]
		if sheet.kind=="actions":
			for at in 4:frames.add_frame("idle",poses[at])
			for at in 4:frames.add_frame("idle_blink",poses[at+4])
		elif sheet.kind=="motion":
			var walk_count:int=sheet.walk_count
			if walk_count==16:
				for at in 16:frames.add_frame("walk",poses[at])
			for at in 10:frames.add_frame("attack",poses[walk_count+at])
		else:
			var count:int=16 if sheet.kind=="walk" else 10
			for at in count:frames.add_frame(sheet.kind,poses[mini(at,poses.size()-1)])
	for id in heroes:
		assert(ResourceSaver.save(heroes[id],"res://assets/characters/%s/frames.tres"%id)==OK)
		print("Integrated native frames: ",id)
	quit()
func mesh_texture(source: Texture2D,polygons: Array,region: Vector2,origin: Vector2,density: float) -> MeshTexture:
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for polygon in polygons:
		var triangles:=Geometry2D.triangulate_polygon(polygon)
		if triangles.is_empty():continue
		var first:=vertices.size()
		for point in polygon:
			var at: Vector2=ANCHOR+(point+origin)*density
			assert(at.x>=2 and at.x<=CANVAS.x-2 and at.y>=2 and at.y<=CANVAS.y-2,"Pose exceeds padded canvas")
			vertices.append(Vector3(at.x,at.y,0))
			uvs.append((region+point)/source.get_size())
		for index in triangles:indices.append(first+index)
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var texture:=MeshTexture.new()
	texture.base_texture=source
	texture.mesh=mesh
	texture.image_size=CANVAS
	return texture
