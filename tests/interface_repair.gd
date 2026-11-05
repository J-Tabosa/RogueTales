extends SceneTree
var game: Control
var checks:=0
var failures:=0
var destination:=""
var stage:=3
func _initialize() -> void: call_deferred("run_checks")
func verify(value:bool,message:String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)
func settle() -> void:
	for i in 5: await process_frame
func capture(key:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await settle()
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(key+".png"))
func run_checks() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():
		destination=args[0]
		DirAccess.make_dir_recursive_absolute(destination)
	if args.size()>1:stage=int(args[1])
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://interface_repair_isolated.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	Engine.max_fps=60
	await settle()
	for extent in [Vector2i(1920,1080),Vector2i(1366,768),Vector2i(1280,720),Vector2i(390,844)]:
		game.get_window().size=extent
		game.get_window().content_scale_size=extent
		await settle()
		for mode in ["dark","light"]:
			game.campaign.ui_theme=mode
			game.ui_theme.switch_to(mode)
			game.show_menu()
			await settle()
			game.center_content()
			var rail:=preload("res://scripts/side_rails.gd").width_for(game.size.x)
			var safe:=Rect2(rail,0,game.size.x-rail*2,game.size.y)
			verify(safe.encloses(Rect2(game.content.position,game.content.size*game.content.scale)),"Content stays between rails")
			if is_instance_valid(game.desktop_shell):
				for child in game.desktop_shell.get_children():
					if child is Control:
						var rect:=Rect2(child.global_position,child.size*child.get_global_transform().get_scale())
						verify(safe.encloses(rect),"Menu column stays between rails: "+child.name)
			await capture("stage1-%s-%d"%[mode,extent.x])
			if stage>=2:await battle_checks(mode,extent)
			if stage>=3:await modal_checks(mode,extent)
	print("INTERFACE REPAIR stage %d: %d checks, %d failures"%[stage,checks,failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func fixture() -> void:
	Engine.max_fps=60
	seed(725)
	game.campaign.checkpoint.clear()
	game.run=IdleRun.new()
	verify(game.run.start_expedition(game.campaign,"mulan","vigor"),"Start isolated expedition")
	game.run.party_capacity=5
	for id in ["rapunzel","aladin"]:
		game.run.pending_choice=true
		game.run.offers.assign(["ally:"+id,"heart","power"])
		verify(game.run.recruit(game.campaign,id),"Recruit "+id)
	game.enter_encounter()
	game.spawn_enemy()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.arena.atmosphere.set_process(false)
	game.arena.entrance_left=0
	game.arena.intro_left=0
	game.arena.walking=false
	game.arena.frozen=true
	game.arena.enemy_visible=true
	for i in game.run.actors.size():
		game.run.actors[i].hp=game.run.actors[i].max_hp*.73
		game.run.actors[i].shield=118 if i==0 else 0
		game.run.actors[i].energy=10
	game.arena._process(0)
	game.update_hud()
	await settle()
func descendants(node:Node) -> Array[Node]:
	var result:Array[Node]=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func battle_checks(mode:String,extent:Vector2i) -> void:
	await fixture()
	var before:Array=game.run.actors.duplicate(true)
	for card in game.ult_buttons:
		for child in card.get_children():
			if child is Control and not child.get_meta("theme_decoration",false):
				verify(Rect2(Vector2.ZERO,card.size).encloses(child.get_rect()),"Card child is inside frame: "+child.name)
			if child is Label and child.get_meta("bar_readout",false):
				verify(child.get_theme_font_size("font_size")*game.content.scale.x>=13.99,"Real displayed digits >=14px")
				verify(child.get_theme_color("font_color")==TaleTheme.c("bar_text"),"Bar contrast text")
				verify(child.get_theme_constant("outline_size")>=2,"Bar contrast outline")
	verify(not game.action_label.visible and not game.timeline.visible,"No turn strip")
	verify(game.run.actors==before,"HUD preserves combat state")
	for i in game.arena.unit_widgets.size():
		var w:Dictionary=game.arena.unit_widgets[i]
		verify(w.root.get_parent()==game.arena.heroes[i],"Ally HUD owned by sprite")
		verify(w.health.get_theme_stylebox("fill").bg_color==TaleTheme.c("bar_health"),"Allied fill is solid green")
		verify(w.text.text.contains(str(ceili(game.run.actors[i].max_hp))),"HUD prints real HP maximum")
	await capture("battle-%s-%d"%[mode,extent.x])
	if extent.x in [1280,390]:
		for shielded in [false,true]:
			game.run.actors[0].shield=118 if shielded else 0
			game.run.tactics.enemies[0].shield=39 if shielded else 0
			game.update_hud()
			await create_timer(.25).timeout
			var w:Dictionary=game.arena.foe_widgets[0]
			verify(w.root.get_parent()==game.arena.foes[0],"Enemy HUD owned by sprite")
			verify(w.health.get_theme_stylebox("fill").bg_color==TaleTheme.c("bar_enemy"),"Enemy fill is solid red")
			verify(w.shield.visible==shielded,"Enemy shield visibility")
			if shielded:
				var in_arena:Transform2D=game.arena.global_transform.affine_inverse()*w.shield.get_global_transform()
				verify(Rect2(Vector2.ZERO,game.battle_viewport.size).encloses(in_arena*Rect2(Vector2.ZERO,w.shield.size)),"Enemy shield badge stays in arena")
			verify(not w.text.visible,"Regular foe digits hidden until interaction")
			var segment:ColorRect=w.health.get_node("ShieldSegment")
			verify(Rect2(Vector2.ZERO,w.health.size).encloses(segment.get_rect()),"Shield segment bounded")
			await capture("bars-%s-%d-shield-%s"%[mode,extent.x,shielded])
			w.health.mouse_entered.emit()
			verify(w.text.visible,"Hover exposes enemy HP")
			if shielded:await capture("enemy-info-%s-%d"%[mode,extent.x])
			w.health.mouse_exited.emit()
		game.run.tactics.enemies[0].boss=true
		game.arena.foes[0].advance(0,true,0,game.run.tactics.enemies[0].interval)
		game.arena.fit_field(game.battle_viewport.size,44)
		game.update_hud()
		verify(game.arena.foe_widgets[0].text.visible,"Boss HP is always visible")
		await capture("boss-%s-%d"%[mode,extent.x])

func modal_checks(mode:String,extent:Vector2i) -> void:
	await fixture()
	game.show_character_information(2)
	await settle()
	var inspector:Control=game.overlay
	var shell:Control=inspector.shell
	verify(inspector.get_parent()==game,"Inspector is attached to viewport root")
	verify(shell.board.size.x<=minf(920,game.size.x*.92)+1,"Modal width is bounded")
	verify(shell.board.size.y<=game.size.y*.90+1,"Modal height is bounded")
	verify(shell.board.position.distance_to((game.size-shell.board.size)*.5)<1,"Modal is centered on viewport")
	verify(shell.scroll.size.y>0,"Modal scroll body has positive height")
	verify(shell.body.get_combined_minimum_size().x<=shell.scroll.size.x+1,"No horizontal overflow in sheet")
	var art:TextureRect=inspector.find_child("CharacterArt",true,false)
	verify(art.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Portrait uses contain")
	await capture("sheet-%s-%d"%[mode,extent.x])
	var info:Button=inspector.find_child("SkillInfo2",true,false)
	shell.scroll.ensure_control_visible(info)
	await settle()
	info.pressed.emit()
	await settle()
	verify(inspector.detail!=null and inspector.detail.get_meta("inline_information",false),"Ability detail expands in the skill row")
	verify(shell.body.is_ancestor_of(inspector.detail),"Ability detail stays inside scrolling body")
	await capture("sheet-info-%s-%d"%[mode,extent.x])
	inspector.hide_detail()
	game.close_character_information()
	game.run.pending_choice=true
	game.run.offers.assign(["heart","power","haste"])
	game.show_relics()
	await settle()
	shell=game.overlay
	shell.layout()
	await settle()
	verify(shell.get_parent()==game,"Reward modal is attached to viewport root")
	verify(shell.board.position.distance_to((game.size-shell.board.size)*.5)<1,"Reward modal is centered")
	verify(shell.options.get_child_count()==3,"Three reward options")
	var widths:Array[float]=[]
	for option in shell.options.get_children():widths.append(option.size.x)
	verify(absf(widths[0]-widths[1])<=1 and absf(widths[1]-widths[2])<=1,"Reward options have equal width: "+str(widths))
	verify(shell.body.get_combined_minimum_size().x<=shell.scroll.size.x+1,"Reward options have no horizontal overflow")
	await capture("reward-%s-%d"%[mode,extent.x])
	game.overlay.queue_free()
	game.overlay=null
	await settle()
