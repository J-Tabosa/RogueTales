extends SceneTree
## Full presentation lifecycle: readable feedback and impact/recovery before rewards.
const SAVE := "user://idle_feedback_isolated.json"
const Flow = preload("res://scripts/battle_flow.gd")
var game: Control
var captures := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): captures = arg.trim_prefix("--screenshots=")
	call_deferred("checks")

func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(captures)
	root.get_texture().get_image().save_png(captures.path_join(name + ".png"))

func step(seconds: float) -> void:
	for tick in ceili(seconds / 0.05):
		game._process(0.05)
		if is_instance_valid(game.arena): game.arena._process(0.05)
		if is_instance_valid(game.feedback): game.feedback._process(0.05)

func prepare(ids: Array, stage := 4) -> void:
	game.campaign.checkpoint.clear()
	game.run = IdleRun.new()
	assert(game.run.start_expedition(game.campaign, ids[0], "vigor"))
	for id in ids.slice(1):
		game.run.pending_choice = true
		game.run.offers.assign(["ally:" + id, "heart", "power"])
		assert(game.run.recruit(game.campaign, id))
	game.run.stage = stage
	game.run.wave = 2 if ExpeditionContent.is_boss(stage) else 0
	game.run.rooms_cleared = stage
	game.enter_encounter()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.spawn_enemy()
	assert(game.state == "encounter_intro")
	step(1.2)
	assert(game.state == "battle")
	for foe in game.run.tactics.enemies:
		foe.hp = 10000
		foe.max_hp = 10000
		foe.evasion = 0
	game.run.tactics.sync_totals()

func checks() -> void:
	root.content_scale_size = Vector2i(540, 960)
	root.size = Vector2i(540, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	game.set_process(false)
	game.campaign = TaleCampaign.new()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.auto_ult = false
	game.set_run_mode(true)
	assert(not game.chosen_endless)
	var locked := IdleRun.new()
	assert(not locked.start_expedition(game.campaign, "scarlet", "vigor", true))
	await capture("setup_mobile")
	prepare(["scarlet", "rapunzel", "mulan"])
	assert(not game.arena.foe_widgets[0].has("intent"))
	game.run.actors[0].hp = 78
	game.run.actors[0].energy = 62
	game.update_hud()
	assert(game.card_health[0].value == 78 and game.ult_meters[0].value == 62)
	assert(game.ult_buttons[0].get_children().any(func(child): return child is Label and child.text.contains("78 /")))
	assert(game.ult_buttons[0].get_children().any(func(child): return child is Label and child.text == "MANA 62 / 100"))
	# A real rescue creates a side ribbon and a persistent, inspectable log entry.
	game.run.actors[0].evasion = 0
	game.run.actors[0].row = "front"
	game.run.actors[2].row = "back"
	game.run.tactics.enemies[0]["class"] = "vanguard"
	game.run.tactics.enemies[0].damage = 15
	game.run.actors[1].pp = 1
	game.on_enemy_attack_hit(0)
	assert(game.feedback.ribbon.visible and game.feedback.ribbon_title.text == "Laço de resgate")
	assert(game.battle_history.any(func(line): return line.contains("Laço de resgate")))
	assert(game.battle_history.any(func(line): return line.contains("PV")))
	game.feedback._process(0.25)
	await capture("passive_mobile")
	game.show_battle_history()
	assert(game.paused and game.arena.frozen and game.feedback.frozen)
	var left: float = game.feedback.ribbon_left
	step(0.4)
	assert(game.feedback.ribbon_left == left)
	await capture("history_mobile")
	game.resume_battle()
	assert(not game.feedback.frozen)
	# Every ULT has a named cut-in and a nonempty impact effect, including support ULTs.
	for id in TaleCatalog.HEROES:
		prepare([id])
		if id == "mulan":
			game.game_speed = 2
			game.arena.speed = 2
		game.run.actors[0].energy = 100
		game.run.actors[0].hp *= 0.6
		assert(game.try_ultimate(0))
		assert(game.feedback.cutin.visible and game.arena.intro_left >= 1.3)
		var before: float = game.run.enemy_hp
		game.arena._process(0.25)
		assert(game.run.enemy_hp == before and game.arena.tracks[0].time == 0)
		game.feedback._process(0.3)
		if id == "scarlet": await capture("ultimate_cutin_mobile")
		for tick in 120:
			game.arena._process(0.05)
			game.feedback._process(0.05)
			if not game.arena.bursts.is_empty(): break
		assert(not game.arena.bursts.is_empty(), "Each ULT must render a visible impact")
		if id == "ariel": await capture("ultimate_impact_mobile")
	# Terminal damage waits for the complete swing/recovery, then the victory hold.
	prepare(["mulan"], 0)
	game.run.actors[0].crit = 0
	game.run.tactics.enemies[0].hp = 1
	game.run.tactics.enemies[0].armor = 0
	game.run.tactics.sync_totals()
	assert(game.arena.attack(0, 0))
	game.combat_flow.begin({"side": "ally", "index": 0})
	while not game.arena.tracks[0].hit:
		game.arena._process(0.05)
	assert(game.state == "battle" and game.arena.is_action_busy())
	game._process(0.1)
	assert(game.state == "battle", "Lethal impact must not cut the attack to rewards")
	for tick in 40:
		game.arena._process(0.05)
		if not game.arena.is_action_busy(): break
	game._process(0.05)
	assert(game.state == "battle_outro")
	game._process(0.6)
	assert(game.state == "battle_outro")
	game._process(0.7)
	assert(game.state == "choice" and is_instance_valid(game.overlay) and game.battle_view)
	assert(game.arena.frozen)
	await capture("reward_popup_mobile")
	var offer: String = game.run.offers.filter(func(key): return not key.begins_with("ally:"))[0]
	game.select_relic(offer)
	assert(game.state == "route_travel" and game.arena.walking)
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena._process(0.25)
	assert(game.arena.heroes[0].position.x < game.arena.tracks[0].home.x)
	await capture("walking_mobile")
	game._process(2.4)
	assert(game.state == "route" and game.arena.frozen)
	await capture("route_popup_mobile")
	game.select_route("battle")
	assert(game.state == "travel" and game.arena.walking)
	# The ordinary enemy gets a real attack even when heroes have fast cooldowns.
	prepare(["scarlet", "ariel", "rapunzel"], 8)
	var hp_before: float = game.run.actors.reduce(func(total, actor): return total + actor.hp, 0.0)
	step(12.0)
	assert(game.battle_history.any(func(line): return line.contains("→ Scarlet") or line.contains("→ Rapunzel") or line.contains("→ Ariel")))
	assert(game.run.actors.reduce(func(total, actor): return total + actor.hp, 0.0) < hp_before)
	# Pressure prevents an immortal healer loop against a surviving enemy formation.
	step(120)
	assert(game.state == "result", "A healer pair cannot sustain forever against a living formation")
	# Reactions cool down from their own use, not from the old global round boundary.
	prepare(["scarlet", "puss", "alice"], 8)
	var flow := Flow.new()
	flow.bind(game.run)
	game.run.actors[0].pp = 0
	flow.advance(0)
	flow.advance(5.9)
	assert(game.run.actors[0].pp == 0)
	flow.advance(0.2)
	assert(game.run.actors[0].pp == 1)
	game.run.actors[0].pp = 0
	flow.advance(0)
	flow.advance(5.8)
	assert(game.run.actors[0].pp == 0)
	flow.advance(0.3)
	assert(game.run.actors[0].pp == 1)
	var acted := {}
	for turn in 18:
		flow.advance(1.7)
		var entry: Dictionary = flow.next_action()
		if entry.is_empty(): continue
		acted[flow.entry_key(entry)] = true
		flow.begin(entry)
		assert(flow.next_action().is_empty())
		flow.complete()
	assert(acted.size() == 6, "Every living hero and enemy must get to act")
	# Complete normal run; the same build is converted only at its earned ending.
	prepare(["scarlet", "rapunzel"], 11)
	game.run.apply_relic("heart")
	game.run.apply_relic("power")
	game.run.apply_relic("power")
	game.run.actors[0].hp = 73
	for foe in game.run.tactics.enemies: foe.hp = 0
	game.run.tactics.sync_totals()
	game.resolve_enemy()
	game._process(1.3)
	assert(game.state == "result" and game.campaign.expedition_wins == 1)
	var damage: float = game.run.actors[0].damage
	var old_id: int = game.run.run_id
	game.continue_into_endless()
	assert(game.state == "choice" and game.run.endless and game.run.rooms_cleared == 12)
	assert(game.run.run_id != old_id and game.run.actors[0].hp == 73 and game.run.actors[0].damage == damage)
	assert(game.run.upgrade_count("power") == 2 and game.run.upgrade_count("heart") == 1)
	var resumed := IdleRun.new()
	resumed.restore(game.campaign, game.campaign.checkpoint)
	assert(resumed.endless and resumed.actors[0].hp == 73 and resumed.actors[0].damage == damage)
	assert(resumed.continuation_from == 12)
	game.run.pending_choice = true
	game.run.offers.assign(["ally:alice", "power", "heart"])
	assert(game.run.recruit(game.campaign, "alice"))
	assert(game.run.actors[2].damage == TaleCatalog.HEROES.alice.damage * 1.2 * 1.2)
	var continuation_reward: Dictionary = game.campaign.finish_expedition(game.run.to_checkpoint(), false)
	assert(continuation_reward.reward == 20 and game.campaign.expedition_wins == 1, "Only the new endless milestone pays; normal floors are already settled")
	# Desktop and narrow mobile layouts retain visible numeric bars.
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	prepare(["scarlet", "mulan", "alice"], 6)
	game.update_hud()
	game.run.tactics.notify("alice", "Carta na manga", "+25 mana")
	game.consume_feedback()
	game.feedback._process(0.3)
	await capture("battle_pc")
	assert(game.desktop and game.card_health[0].size.x == 172)
	root.content_scale_size = Vector2i(360, 800)
	root.size = Vector2i(360, 800)
	await process_frame
	game.center_content()
	await capture("battle_narrow_mobile")
	assert(not game.desktop and game.card_health[0].size.x == 144)
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("IDLE FEEDBACK PASS: 12 ULT cut-ins/VFX, passive ribbons/log/pause, numeric HP/mana, lethal recovery/hold/reward popup, walking/routes, real enemy threat, healer pressure, earned endless continuation/save/build and mobile/PC")
	quit()
