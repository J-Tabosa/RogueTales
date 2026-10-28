extends SceneTree
## Load every migrated animation and each dynamic UI/basic/Ultimate art path.
const HeroArt = preload("res://scripts/hero_art.gd")
const BasicFX = preload("res://scripts/character_effects.gd")
const UltimateFX = preload("res://scripts/ultimate_vfx.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/FRAME_LAYOUT.json"))
	assert(layout.heroes.size() == 11)
	for id in TaleCatalog.HERO_SCENES:
		var actor: AnimatedSprite2D = TaleCatalog.HERO_SCENES[id].instantiate()
		var path := "res://assets/characters/%s/frames.tres" % id
		assert(ResourceLoader.exists(path))
		var frames: SpriteFrames = load(path)
		assert(actor.sprite_frames.get_frame_count("idle") == frames.get_frame_count("idle"))
		for animation in ["idle", "idle_blink", "walk", "attack"]:
			assert(frames.has_animation(animation) and frames.get_frame_count(animation) > 0)
			for at in frames.get_frame_count(animation):
				var pose: MeshTexture = frames.get_frame_texture(animation, at)
				assert(pose != null and pose.base_texture != null)
				assert(pose.base_texture.resource_path.begins_with("res://assets/characters/%s/" % id))
		if layout.heroes.has(id):
			assert(frames.get_frame_count("idle") == 8 and frames.get_frame_count("attack") == 12)
			assert(frames.get_frame_count("ultimate") == (16 if id == "scarlet" else 12))
			for animation in ["idle", "walk", "attack", "ultimate"]:
				for at in frames.get_frame_count(animation):
					assert(frames.get_frame_texture(animation, at).get_size() == Vector2(768, 768))
			for at in 12:
				assert(UltimateFX.frame(id, float(at) / 12).get_image() != null)
		assert(HeroArt.body(id).texture != null and HeroArt.head(id) != null)
		actor.free()
	for id in BasicFX.IDS:
		for ultimate in [false, true]:
			for at in 6:
				assert(BasicFX.frame(id, float(at) / 6, ultimate).get_image() != null)
	var sources: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/sources.json"))
	for entry in sources:
		assert(FileAccess.file_exists("res://" + str(entry.output)))
		assert(entry.get("hero", "") == "puss" or entry.kind in ["effects", "arena", "secret"])
	print("CHARACTER ASSET PATHS PASS: 12 heroes, current meshes, fixed canvases, UI portraits, basic effects, Ultimate atlases and active rebuild manifest")
	quit()
