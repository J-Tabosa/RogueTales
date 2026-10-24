extends SceneTree
const SAVE := "user://roster_isolated.json"
const JOBS := {"joao": "vanguard", "maria": "assassin", "alice": "ranger", "puss": "vanguard", "matches": "mage", "peter": "assassin", "aladin": "mage"}

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	assert(TaleCatalog.HEROES.size() == 12 and TaleCatalog.HERO_SCENES.size() == 12)
	var scarlet: AnimatedSprite2D = TaleCatalog.HERO_SCENES.scarlet.instantiate()
	var campaign := TaleCampaign.new()
	campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	for id in JOBS:
		var actor: AnimatedSprite2D = TaleCatalog.HERO_SCENES[id].instantiate()
		root.add_child(actor)
		actor.set_process(false)
		assert(actor.hero_name == TaleCatalog.HEROES[id].name)
		assert(TaleCatalog.HERO_TACTICS[id]["class"] == JOBS[id])
		assert(TaleCatalog.HEROES[id].skills.size() == 3)
		for anim in ["idle", "idle_blink", "walk", "attack"]:
			var source_regions := {}
			assert(actor.sprite_frames.get_frame_count(anim) == ({"idle":4,"idle_blink":4,"walk":16,"attack":10}[anim] if id=="puss" else scarlet.sprite_frames.get_frame_count(anim)))
			assert(actor.sprite_frames.get_animation_speed(anim)>0)
			for frame in actor.sprite_frames.get_frame_count(anim):
				var texture: Texture2D = actor.sprite_frames.get_frame_texture(anim, frame)
				var key: String
				if texture is MeshTexture:
					assert(texture.mesh.get_aabb().size.y > 0)
					key = str(texture.base_texture.resource_path) + str(texture.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV])
				else:
					assert(texture.get_size().is_equal_approx(Vector2(512,512)))
					assert(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region))
					key = str(texture.atlas.resource_path) + str(texture.region)
				assert(not source_regions.has(key), "Each frame has its own source art")
				source_regions[key] = true
			actor.seek_animation(anim, 0.2)
			assert(actor.animation == StringName(anim))
			assert(source_regions.size() == actor.sprite_frames.get_frame_count(anim))
		actor.free()
		campaign.party.assign([id, "scarlet"])
		var run := IdleRun.new()
		run.setup(campaign, 8)
		run.enable_tactics(campaign)
		run.spawn_enemy()
		run.drafted.append(id)
		for foe in run.tactics.enemies:
			foe.hp = 10000.0
			foe.max_hp = 10000.0
			foe.evasion = 0.0
		var hit := run.hit_enemy(0)
		assert(hit.damage > 0 and run.unlock_stats.new_hits[id] == 1)
		assert(run.tactics.enemies[hit.target].row == ("front" if id in ["puss","joao","matches","aladin"] else "back"))
		if id == "maria":
			assert(run.tactics.enemies[hit.target].poison_left == 4)
		if id == "matches":
			assert(run.tactics.enemies[hit.target].burn_left == 3)
		if id == "aladin":
			run.hit_enemy(0)
			run.hit_enemy(0)
			assert(run.actors[1].shield > 0)
		for ally in run.actors:
			ally.hp = ally.max_hp * 0.5
		run.actors[0].energy = 100
		assert(run.tactics.reserve_ultimate(0) and not run.tactics.reserve_ultimate(0))
		var ult: Dictionary = run.tactics.ultimate(0)
		assert((ult.damage > 0 or id=="peter") and run.tactics.ultimate(0).is_empty())
		if id in ["alice", "aladin"]:
			assert(ult.targets.size() == 3)
		if id == "puss":
			assert(run.actors[0].shield > 0 and run.tactics.enemies[ult.target].row == "front")
		if id == "peter":
			assert(run.actors[0].spirit_flames==3 and run.actors[0].shield>0)
		if id == "aladin":
			assert(ult.healed > 0 and run.actors[1].shield > 0)
		if id == "maria":
			assert(run.tactics.enemies[ult.target].poison_left == 6)
		if id == "matches":
			assert(run.tactics.enemies[ult.target].burn_left == 5)
		var checkpoint := run.to_checkpoint()
		var resumed := IdleRun.new()
		resumed.restore(campaign, checkpoint)
		assert(resumed.unlock_stats.new_hits[id] == run.unlock_stats.new_hits[id])
		# A guest's 20-hit requirement survives separate runs and cannot be credited twice.
		var fresh := TaleCampaign.new()
		for hits in [19, 1]:
			var data := {"run_id": fresh.new_run_id(), "drafted": [id], "unlock_stats": {"new_hits": {id: hits}}}
			fresh.resolve_run(data, false)
			var before := fresh.unlock_amount(id)
			assert(fresh.resolve_run(data, false).is_empty() and fresh.unlock_amount(id) == before)
		assert(fresh.unlocked.has(id))
		assert(fresh.save_to(SAVE))
		var loaded := TaleCampaign.new()
		assert(loaded.load_from(SAVE) and loaded.unlock_amount(id) == 20 and loaded.unlocked.has(id))
	scarlet.free()
	# Old accounts acquire valid zero progress, levels and rows for all seven additions.
	var legacy := TaleCampaign.new()
	legacy.load_data({"schema": 4, "gold": 987, "unlocked": ["scarlet", "mulan"], "party": ["scarlet", "mulan"], "unlock_progress": {"mulan": 7}})
	assert(legacy.gold == 987 and legacy.unlock_amount("mulan") == 7)
	for id in JOBS:
		assert(legacy.unlock_amount(id) == 0 and legacy.hero_levels[id] == 1 and legacy.levels[id].size() == 3)
	var game: Control = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = campaign
	game.edit_profile()
	assert(game.profile_avatar_buttons.size() == 12)
	var scrolls: Array = game.overlay.find_children("*", "ScrollContainer", true, false)
	assert(scrolls.size() == 1)
	game.select_avatar("aladin")
	assert(game.profile_avatar == "aladin")
	game.debug_enabled = true
	game.show_preview()
	game.choose_preview("peter")
	game.preview_anim("idle_blink")
	assert(game.arena.heroes[0].animation == &"idle_blink")
	game.queue_free()
	await process_frame
	for path in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NEW ROSTER PASS: 7 classes, 238 distinct frame regions matching Scarlet, unique ULT effects, guest progress/checkpoints, legacy accounts, 12 avatars and four-animation lab")
	quit()
