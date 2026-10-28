extends SceneTree
const Layout = preload("res://scripts/formation_layout.gd")
const Art = preload("res://scripts/character_effects.gd")
const Biomes = preload("res://scripts/biomes.gd")
func _initialize() -> void:call_deferred("checks")
func checks() -> void:
	for id in ["puss"]:
		var actor: AnimatedSprite2D=TaleCatalog.HERO_SCENES[id].instantiate()
		root.add_child(actor)
		actor.set_process(false)
		var count:=0
		for animation in ["idle","idle_blink","walk","attack"]:
			var frames:SpriteFrames=actor.sprite_frames
			assert(frames.get_frame_count(animation)=={"idle":4,"idle_blink":4,"walk":16,"attack":10}[animation])
			for index in frames.get_frame_count(animation):
				count+=1
				actor.seek_animation(animation,index/frames.get_animation_speed(animation))
				var texture:MeshTexture=frames.get_frame_texture(animation,index)
				assert(texture!=null and texture.base_texture.resource_path.ends_with(".jpg"))
				var bounds:=texture.mesh.get_aabb()
				assert(bounds.position.x>=2 and bounds.position.y>=2)
				assert(bounds.end.x<texture.image_size.x-2 and bounds.end.y<texture.image_size.y-2)
				var alpha:Texture2D=load(texture.base_texture.resource_path.get_basename()+"_alpha.png")
				assert(alpha.get_size()==texture.base_texture.get_size())
				assert(actor.material.get_shader_parameter("use_alpha_mask"))
		assert(count==34)
		var effect:=Art.frame("alice" if id=="snow_white" else id,0.5)
		assert(effect.get_image().get_pixel(0,0).a<0.02,"JPEG effects reconstruct their original alpha")
		actor.free()
	for id in preload("res://scripts/ultimate_rules.gd").IDS:
		var frames:SpriteFrames=load("res://assets/characters/%s/frames.tres"%id)
		for animation in ["idle","walk","attack","ultimate"]:
			var expected := 8 if animation in ["idle","walk"] else (16 if id=="scarlet" and animation=="ultimate" else 12)
			assert(frames.get_frame_count(animation)==expected)
			for at in frames.get_frame_count(animation):
				var texture:MeshTexture=frames.get_frame_texture(animation,at)
				assert(texture.base_texture.resource_path.ends_with(".webp") and texture.image_size==Vector2(768,768))
		assert(preload("res://scripts/ultimate_vfx.gd").frame(id,.5).get_image().get_pixel(0,0).a<.02)
	for world in 12:
		var scenery:=Biomes.scenery(world)
		assert(scenery.resource_path.ends_with(".jpg") and scenery.get_width()>=1500 and scenery.get_height()>=900)
	for row in Layout.ROWS:
		var units:Array=[{"row":row,"hp":1},{"row":row,"hp":1},{"row":row,"hp":1}]
		for index in 3:
			var home:=Layout.home(units,index,false)
			var opposite:=Layout.home(units,index,true)
			assert(Layout.zone(false).has_point(home) and Layout.zone(true).has_point(opposite))
			assert(is_equal_approx(home.x+opposite.x,1.0) and home.y==opposite.y)
			if index>0:assert(home.y>Layout.home(units,index-1,false).y)
		var first:=Layout.home(units,1,false)
		units[0].hp=0
		assert(Layout.home(units,1,false)==first,"Deaths never move the remaining formation")
	print("ART INTEGRATION PASS: 11 uploaded-roster WebP animations and legacy Gato mesh poses, lossless alpha, all effect atlases, 12 HD worlds, mirrored fixed 3-slot rows")
	quit()
