extends SceneTree

const TRAVELERS := ["mogli", "aurora", "pinocchio"]
const Blessings := preload("res://scripts/hero_blessings.gd")
const UltimateArt := preload("res://scripts/ultimate_art.gd")
var game: Control

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://new_traveler_combat_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode = "windowed"
	game.campaign.window_mode_selected = true
	game.apply_window_mode()
	root.size = Vector2i(540, 960)
	root.content_scale_size = root.size
	await process_frame
	game.center_content()

	assert(UltimateArt.frame("unregistered_traveler", 0.0) == null)
	for id in TRAVELERS:
		assert(await start_expedition(id))
		assert(await fight_as(id, "protagonist"))

	assert(await start_expedition("scarlet"))
	game.run.party_capacity = ExpeditionContent.MAX_PARTY
	game.run.phase = 1
	for id in TRAVELERS:
		var offer: String = "ally:" + id
		game.run.pending_choice = true
		game.run.offers.assign([offer, "power", "heart"])
		game.show_relics()
		game.select_relic(offer)
		assert(game.state == "route_travel" and game.run.actor_ids().has(id))
		game.enter_encounter()
		assert(await fight_as(id, "recruit"))

	game.restore_checkpoint_now()
	assert(game.run.actor_ids() == ["scarlet", "mogli", "aurora", "pinocchio"])
	game.enter_encounter()
	assert(await fight_as("mogli", "checkpoint"))

	game.run.journey = {"format": 1, "season": "summer", "path": ["FlorestaVerao", "CamposDeGirassois"]}
	game.run.stage = 1
	game.run.phase = 0
	game.enter_encounter()
	assert(await fight_as("mogli", "Campos de Girassóis"))

	game.queue_free()
	await process_frame
	print("NEW TRAVELER COMBAT PASS: three protagonists, three recruits, restored Mogli, sunflower encounter, basics and ultimate effects")
	quit()

func start_expedition(id: String) -> bool:
	game.campaign.checkpoint.clear()
	game.selected_hero = id
	game.chosen_blessing = Blessings.id_for(id, 0)
	game.begin_expedition()
	assert(game.state == "loading")
	for frame in 240:
		if game.state != "loading": break
		await process_frame
		game.advance_loading(.06)
	assert(game.state == "travel" and game.run.actor_ids() == [id])
	return true

func fight_as(id: String, entry: String) -> bool:
	print("Checking %s as %s" % [id, entry])
	game.spawn_enemy()
	assert(game.state == "encounter_intro")
	for frame in 240:
		if not game.arena.warming_attacks(): break
		await process_frame
	assert(not game.arena.warming_attacks())
	var index: int = game.run.actor_ids().find(id)
	assert(index >= 0 and game.arena.heroes.size() == game.run.actors.size())
	for enemy in game.run.tactics.enemies:
		enemy.hp = 10000.0
		enemy.max_hp = enemy.hp
		enemy.evasion = 0.0
	var target: int = game.run.tactics.target_for(index)
	assert(target >= 0)
	var foe: Dictionary = game.run.tactics.enemies[target]
	game.run.tactics.sync_totals()
	game.state = "battle"
	game.arena.set_process(false)
	game.arena.speed = 1.0
	game.arena.entrance_left = 0.0

	var hp: float = foe.hp
	assert(game.arena.attack(index, target))
	assert(await advance_attack(index))
	assert(foe.hp < hp)

	game.run.actors[index].energy = game.run.tactics.Rules.cost(game.run.actors[index])
	var total_hp: float = game.run.enemy_hp
	assert(game.try_ultimate(index))
	assert(await advance_attack(index))
	assert(game.run.enemy_hp < total_hp)
	assert(not game.arena.bursts.is_empty())
	return true

func advance_attack(index: int) -> bool:
	for tick in 96:
		if game.arena.tracks[index].time < 0: break
		game.arena._process(.06)
		await process_frame
	assert(game.arena.tracks[index].hit and game.arena.tracks[index].time < 0)
	return true
