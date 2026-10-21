extends SceneTree
const Arena = preload("res://scripts/arena.gd")


## Compares script update cost only: it does not measure rendered FPS or phone performance.
func _initialize() -> void:
	call_deferred("bench")


func bench() -> void:
	var arena := Node2D.new()
	arena.set_script(Arena)
	arena.party_scenes.assign(
		[
			TaleCatalog.HERO_SCENES.scarlet,
			TaleCatalog.HERO_SCENES.rapunzel,
			TaleCatalog.HERO_SCENES.mulan
		]
	)
	root.add_child(arena)
	arena.set_process(false)
	for hero in arena.heroes:
		hero.set_process(false)
	var begin := Time.get_ticks_usec()
	for frame in 10000:
		arena._process(1.0 / 60)
		for hero in arena.heroes:
			hero._process(1.0 / 60)
	print("IDLE_10000_STEPS_US=", Time.get_ticks_usec() - begin)
	begin = Time.get_ticks_usec()
	for frame in 10000:
		if frame % 180 == 0:
			for index in 3:
				arena.attack(index)
		arena._process(1.0 / 60)
		for hero in arena.heroes:
			hero._process(1.0 / 60)
	print("ATTACK_10000_STEPS_US=", Time.get_ticks_usec() - begin)
	arena.queue_free()
	await process_frame
	quit()
