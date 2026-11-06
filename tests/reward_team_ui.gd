extends SceneTree
var game: Control
var destination := ""

func _initialize() -> void: call_deferred("checks")

func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas()*(button.size*.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	game.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		game.get_viewport().push_input(event,true)
	await process_frame

func capture(title: String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(title+".png"))

func field(card: Control, key: String) -> Control:
	return card.get_children().filter(func(n): return n.has_meta("card_"+key))[0]

func check_offer_text(node: Node, card: Control) -> void:
	for child in node.get_children():
		if child is Label:
			assert(card.get_global_rect().encloses(child.get_global_rect()),"Reward text remains inside its option")
		check_offer_text(child,card)

func checks() -> void:
	Engine.max_fps = 60
	if not OS.get_cmdline_user_args().is_empty():
		destination = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://reward_team_ui_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign = preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode = "windowed"
	game.campaign.window_mode_selected = true
	game.apply_window_mode()
	for frame in 8: await process_frame
	for dimensions in [Vector2i(1920,1080),Vector2i(1366,768),Vector2i(1280,720),Vector2i(390,844)]:
		game.get_window().size = dimensions
		game.get_window().content_scale_size = dimensions
		for frame in 4: await process_frame
		game.center_content()
		for mode in ["dark","light"]:
			game.campaign.checkpoint.clear()
			game.run = IdleRun.new()
			assert(game.run.start_expedition(game.campaign,"rapunzel","blessing:rapunzel:0"))
			game.run.party_capacity = 5
			for id in ["aladin","snow_white","alice","matches"]:
				game.run.pending_choice = true
				game.run.offers.assign(["ally:"+id,"heart","power"])
				assert(game.run.recruit(game.campaign,id))
			game.run.interlude = ""
			game.run.run_gold = 245
			game.enter_encounter()
			game.spawn_enemy()
			game.arena.reset_effects()
			game.arena.set_process(false)
			game.feedback.set_process(false)
			game.arena.enemy_visible = true
			game.arena.entrance_left = 0
			game.arena.walking = false
			game.run.actors[0].hp = 463
			game.run.actors[0].max_hp = 580
			game.run.actors[0].shield = 118
			game.run.actors[0].energy = 1
			game.run.actors[2].hp = 0
			game.run.actors[2].shield = 0
			game.ui_theme.switch_to(mode)
			game.update_hud()
			game.feedback.enqueue({"hero":"rapunzel","kind":"passive","title":"Casulo de Seda","detail":"Escudos para a equipe"})
			game.feedback._process(.3)
			for frame in 5: await process_frame
			game.relayout_battle()
			game.update_hud()
			assert(not game.action_label.visible,"Only stage and passive remain above the battle")
			var arena_rect: Rect2 = game.battle_viewport.get_rect()
			var gold_rect: Rect2 = game.page.get_node("BattleGoldBox").get_rect()
			assert(arena_rect.encloses(gold_rect) and gold_rect.position.x<40,"Gold overlays the upper left of the arena")
			assert(arena_rect.encloses(game.reward_return.get_rect()) and game.reward_return.position.x>arena_rect.get_center().x,"Reward button overlays the upper right")
			assert(gold_rect.end.y<game.battle_viewport.position.y+game.feedback.ribbon.position.y,"Passive stays below the gold")
			if game.desktop:
				assert(arena_rect.size==Vector2(984,726) and game.hero_deck_scroll.position.x>arena_rect.end.x,"Arena reaches its new edges without entering the narrower manager")
			for card in game.ult_buttons:
				for key in ["hp","mana","info","items","face","name","ult","status"]:
					assert(Rect2(Vector2.ZERO,card.size).encloses(field(card,key).get_rect()),key+" fits its team card")
				assert(not field(card,"hp").get_rect().intersects(field(card,"mana").get_rect()))
				if game.desktop:
					for key in ["name","ult"]:
						var text: Label = field(card,key)
						assert(text.get_theme_font("font").get_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,-1,text.get_theme_font_size("font_size")).x<=text.size.x,"Narrow cards keep the complete character and ability names")
				for key in ["hp_bar","mana_bar"]:
					var edge: Panel = field(card,key).get_node("BarOutline")
					assert(edge.get_theme_stylebox("panel").border_color==Color.BLACK and edge.get_theme_stylebox("panel").border_width_left==2,"Manager bars retain a black 2px border in both themes")
			var first: Control = game.ult_buttons[0]
			assert(field(first,"hp").text=="463 / 580","Shields do not inflate the maximum HP label")
			assert(not field(first,"hp").get_rect().intersects(field(first,"shield").get_rect()),"Shield count has its own space")
			assert(field(first,"hp").get_theme_font_size("font_size")>=14)
			await capture("battle-%s-%dx%d"%[mode,dimensions.x,dimensions.y])
			await click(field(first,"info"))
			assert(is_instance_valid(game.overlay) and game.overlay.has_meta("character_inspector"),"Diamond still opens character information")
			game.close_character_information()
			await process_frame
			game.run.interlude = "reward"
			game.run.pending_choice = true
			game.run.offers.assign(["bonus:700:initiative:group:1","bonus:701:physical_defense:unique:3","bonus:702:initiative:unique:1"])
			game.show_relics()
			for frame in 6: await process_frame
			var sheet: Control = game.overlay
			assert((sheet.board.position+sheet.board.size*.5-sheet.size*.5).length()<1,"Reward is centered")
			assert(Rect2(Vector2.ZERO,sheet.size).encloses(sheet.board.get_rect()),"Reward stays within the screen")
			assert(sheet.find_child("RewardTitle",true,false).horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER)
			assert(sheet.find_child("RewardSubtitle",true,false).text=="Escolha uma melhoria")
			assert(sheet.choices.get_child_count()==3)
			for card in sheet.choices.get_children():
				assert(card.find_children("*","Label",true,false).size()==3,"Each reward keeps its rarity, title and description")
				check_offer_text(card,card)
			assert(sheet.find_child("RewardTitle",true,false).get_rect().end.y<=48,"Title never expands over the choices")
			await capture("reward-%s-%dx%d"%[mode,dimensions.x,dimensions.y])
			var before: Dictionary = game.run.to_checkpoint().duplicate(true)
			await click(sheet.find_child("BackWithoutReward",true,false))
			assert(game.overlay==null and game.reward_return.visible,"Back dismisses the sheet and offers a return button")
			assert(game.paused and game.run.to_checkpoint()==before,"Back never applies, rerolls or discards the reward")
			await capture("battle-choice-%s-%dx%d"%[mode,dimensions.x,dimensions.y])
			await click(game.reward_return)
			assert(game.overlay!=null and game.run.to_checkpoint()==before,"Reopen preserves the same offers")
			game.dismiss_reward()
			await process_frame
	game.queue_free()
	await process_frame
	print("REWARD / TEAM UI PASS: 4 resolutions, 2 themes, cards, HP/shield separation, info click, centered reward, back/reopen without mutation")
	quit()
