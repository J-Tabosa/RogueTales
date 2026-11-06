extends SceneTree
## Live-scene regression: bars, frame bounds, five-member scrolling and shield clocks.
const Runes = preload("res://scripts/shield_runes.gd")
const Health = preload("res://scripts/health_display.gd")
var game: Control
var destination := ""
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("test")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 4: await process_frame

func field(card: Control, key: String) -> Control:
	for child in card.get_children():
		if child.has_meta("card_"+key): return child
	return null

func capture(key: String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless": return
	await settle()
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(key+".png"))

func fixture(count: int) -> void:
	game.campaign.checkpoint.clear()
	game.run=IdleRun.new()
	check(game.run.start_expedition(game.campaign,"mulan","vigor"),"Start isolated expedition")
	game.run.party_capacity=5
	for id in ["rapunzel","snow_white","alice","aladin"].slice(0,count-1):
		game.run.pending_choice=true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		check(game.run.recruit(game.campaign,id),"Recruit "+id)
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.atmosphere.set_process(false)
	game.arena.entrance_left=0
	game.arena.intro_left=0
	game.arena.walking=false
	game.arena.frozen=true
	for i in game.run.actors.size():
		game.run.actors[i].hp=game.run.actors[i].max_hp*.73
		game.run.actors[i].shield=20+i*11
		game.run.actors[i].energy=10
	game.arena._process(0)
	game.update_hud()
	await settle()

func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var palettes: Dictionary=TaleTheme.PALETTES.duplicate(true)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://manuscript_combat_ui_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	for extent in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(360,640)]:
		game.get_window().size=extent
		game.get_window().content_scale_size=extent
		await settle()
		game.center_content()
		for mode in ["dark","light"]:
			game.campaign.ui_theme=mode
			game.ui_theme.switch_to(mode)
			await fixture(3)
			var before: Array=game.run.actors.duplicate(true)
			check(not game.action_label.visible,"No turn/victory strip above arena")
			check(not game.timeline.visible,"No turn timeline")
			var gold: Control=game.page.get_node("BattleGoldBox")
			check(gold.position.y>game.battle_viewport.position.y+game.battle_viewport.size.y*.8,"Gold moved into lower arena")
			check(game.battle_viewport.get_rect().encloses(gold.get_rect()),"Gold stays inside arena")
			check(Rect2(Vector2.ZERO,game.page.size).encloses(game.battle_viewport.get_rect()),"Arena remains inside safe layout")
			for i in game.ult_buttons.size():
				var card: Button=game.ult_buttons[i]
				var hp: ProgressBar=game.card_health[i]
				var mana: ProgressBar=game.ult_meters[i]
				check(card.size.y<=142,"Compact team chapter")
				check(hp.get_rect().encloses(field(card,"hp").get_rect()),"HP text is inside actual HP bar")
				check(mana.get_rect().encloses(field(card,"mana").get_rect()),"Mana text is inside actual mana bar")
				check(field(card,"face").get_meta("manuscript_role")=="portrait","Shared portrait frame")
				check(field(card,"hp").z_index>hp.z_index,"HP digits draw above shield segment and fill")
				check(hp.get_theme_stylebox("fill").bg_color==Health.tint(game.run.actors[i]),"HP range color retained")
				check(mana.get_theme_stylebox("fill").bg_color==TaleTheme.c("mana"),"Mana remains blue")
				for child in card.get_children():
					if child is Control and not child.get_meta("theme_decoration",false):
						check(Rect2(Vector2.ZERO,card.size).encloses(child.get_rect()),"Card child fits: "+str(child.name))
				var plate: Dictionary=game.arena.unit_widgets[i]
				check(plate.health.get_rect().encloses(plate.text.get_rect()),"In-battle HP digits are inside their bar")
				check(plate.energy.get_rect().encloses(plate.mana_text.get_rect()),"In-battle mana digits are inside their bar")
				check(plate.text.get_theme_font("font").resource_path.ends_with("Lora.ttf"),"Manuscript readout font")
			check(field(game.ult_buttons[0],"name").get_theme_font("font").resource_path.ends_with("Cinzel.ttf"),"Engraved name font")
			await capture("%s-%d"%(mode,extent.x))
			var at: Vector2=game.arena.heroes[0].position
			var height: float=game.arena.human_height()
			var clock: float=game.arena.clock
			var still:=Runes.facet_points(at,height,clock,false,1,0)
			game.arena._process(.1)
			check(is_equal_approx(clock,game.arena.clock),"Pause freezes live rune clock")
			check(still==Runes.facet_points(at,height,game.arena.clock,false,1,0),"Paused shield is stable")
			game.arena.frozen=false
			game.arena._process(.1)
			check(still!=Runes.facet_points(at,height,game.arena.clock,false,1,0),"Live arena advances floating shield")
			game.arena.frozen=true
			check(Runes.facet_points(at,height,0,true,1,0)==Runes.facet_points(at,height,99,true,1,0),"Reduced motion keeps the shield readable and stable")
			game.update_hud()
			check(game.run.actors==before,"Visual animation does not mutate combat state")
			var art: Texture2D=game.arena.backdrop.texture
			var hp_before: float=game.run.actors[0].hp
			game.toggle_ui_theme()
			await settle()
			check(game.arena.backdrop.texture==art and game.run.actors[0].hp==hp_before,"Live theme change preserves scene and combat")
			game.toggle_ui_theme()
			game.run.actors[0].shield=0
			game.update_hud()
			check(not field(game.ult_buttons[0],"shield").visible,"Consumed shield badge disappears")
		await fixture(5)
		if game.desktop:
			check(game.hero_deck.custom_minimum_size.y>game.hero_deck_scroll.size.y,"Five heroes remain reachable with vertical scrolling")
		else:
			check(game.hero_deck.custom_minimum_size.x>game.hero_deck_scroll.size.x,"Five heroes remain reachable with horizontal scrolling")
		check(field(game.ult_buttons[3],"mana").text.contains("cartas"),"Alice keeps card resource")
		check(field(game.ult_buttons[4],"mana").text.contains("desejos"),"Aladin keeps wishes resource")
		await capture("party-five-%d"%extent.x)
	check(TaleTheme.PALETTES==palettes,"Both original palettes are unchanged")
	game.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		var path: String="user://manuscript_combat_ui_isolated.json"+suffix
		if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MANUSCRIPT COMBAT UI: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
