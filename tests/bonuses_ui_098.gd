extends "res://tests/rules_095.gd"
const B=preload("res://scripts/run_bonuses.gd")
var game
var destination:=""
func capture(name:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(name+".png"))
func send_event(event:InputEvent) -> void:
	game.get_viewport().push_input(event,true)
func mouse_at(point:Vector2,pressed:bool,emulated:=false) -> void:
	var event:=InputEventMouseButton.new()
	event.position=point;event.global_position=point
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.device=InputEvent.DEVICE_ID_EMULATION if emulated else 0
	send_event(event)
func touch_at(point:Vector2,pressed:bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.position=point;event.index=0;event.pressed=pressed
	send_event(event)
func click(control:Control,local:Vector2,touch:=false) -> void:
	var point:=control.get_global_transform_with_canvas()*local
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
	send_event(motion)
	if touch:touch_at(point,true)
	mouse_at(point,true,touch)
	if touch:touch_at(point,false)
	mouse_at(point,false,touch)
	await process_frame
func descendants(node:Node) -> Array[Node]:
	var out:Array[Node]=[]
	for child in node.get_children():out.append(child);out.append_array(descendants(child))
	return out
func find_button(text:String) -> Button:
	for n in descendants(game.overlay):
		if n is Button and n.text==text:return n
	return null
func recipient(id:String) -> Button:
	for n in descendants(game.overlay):
		if n is Button and n.get_meta("bonus_recipient","")==id:return n
	return null
func prepare(id:String) -> void:
	game.run.interlude="reward";game.run.pending_choice=true
	game.run.offers.assign([id,"item:clockwork","item:stone_heart"])
	game.show_relics()
	await process_frame
func test() -> void:
	if not OS.get_cmdline_user_args().is_empty():destination=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(destination)
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://bonuses098_isolated.json"
	root.add_child(game);game.set_process(false)
	game.campaign=TaleCampaign.new();game.campaign.unlocked.assign(TaleCatalog.HEROES.keys())
	game.campaign.window_mode="windowed";game.campaign.window_mode_selected=true
	game.apply_window_mode();await process_frame;await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent;game.get_window().content_scale_size=extent
		await process_frame;game.center_content()
		game.run=make(["scarlet","alice","aladin","rapunzel","ariel","snow_white","mulan","peter","matches"])
		game.run.party_capacity=9
		for a in game.run.actors:game.run.tactics.configure_actor(a,a.row)
		game.run.tactics.ensure_front()
		game.build_battle();game.spawn_enemy();game.arena.reset_effects();game.arena.set_process(false)
		game.arena.entrance_left=0;game.arena.intro_left=0;game.arena.enemy_visible=true
		game.run.actors[0].initiative=10
		game.run.actors[0].hp=50
		var id:="bonus:700:initiative:unique:5"
		await prepare(id)
		var offers:Array=game.run.offers.duplicate()
		var card:Button=descendants(game.overlay).filter(func(n):return n is Button and n.has_meta("bonus_rarity"))[0]
		check(card.get_meta("bonus_rarity")==5 and card.get_meta("rarity_color")==Color(B.COLORS[5]),"Mythic reward red")
		await click(card,card.size*.5,extent.x==540)
		check(game.state=="bonus_choice" and game.run.actors[0].initiative==10,"Open preview only via actual tap")
		var confirm:Button=game.overlay.find_child("ConfirmBonus",true,false)
		check(confirm.disabled,"No confirmation until target and sign chosen")
		await click(recipient("scarlet"),Vector2(180,35),extent.x==540)
		check(game.run.bonus_history.is_empty() and game.overlay.find_child("ConfirmBonus",true,false).disabled,"Choose recipient still needs direction")
		var later:Button=game.overlay.find_child("BonusLater",true,false)
		await click(later,later.size*.5,extent.x==540)
		check(descendants(game.overlay).any(func(n):return n is Label and "−" in n.text or n is Label and "-15.0" in n.text),"Negative preview shown")
		check(not game.overlay.find_child("ConfirmBonus",true,false).disabled,"Direction enables final confirmation")
		await capture("bonus-negative-%d"%extent.x)
		await click(find_button("Voltar sem escolher"),Vector2(150,22),extent.x==540)
		check(game.state=="choice" and game.run.offers==offers and game.run.bonus_history.is_empty(),"Cancel keeps original offers and stats")
		game.select_relic(id)
		game.show_bonus_selection(id,"reward","scarlet",-1)
		await process_frame
		confirm=game.overlay.find_child("ConfirmBonus",true,false)
		await click(confirm,confirm.size*.5,extent.x==540)
		check(game.run.bonus_history.size()==1 and R.effective_initiative(game.run.actors[0])==-15,"Final tap atomic signed application")
		game.confirm_bonus_selection(id,"reward","scarlet",-1)
		check(game.run.bonus_history.size()==1,"Double confirmation ignored")
		var saved:Dictionary=game.campaign.checkpoint
		check(saved.bonuses.history.size()==1,"UI persisted bonus before leaving reward")
		id="bonus:701:mana_turn:group:4"
		game.run.actors[1].hp=0
		await prepare(id)
		game.select_relic(id)
		await process_frame
		check(not game.overlay.find_child("ConfirmBonus",true,false).disabled,"Group needs no individual recipient")
		check(descendants(recipient("alice")).any(func(n):return n is Label and "Incompatível" in n.text),"No-mana incompatible shown with dead state")
		check(descendants(recipient("rapunzel")).any(func(n):return n is Label and "24.0" in n.text),"Silk group mana preview")
		await capture("bonus-group-%d"%extent.x)
		# Touch-scroll the actual list to reach all nine recipients.
		var scroll:ScrollContainer=game.overlay.find_child("BonusRecipients",true,false)
		var point:Vector2=scroll.get_global_transform_with_canvas()*Vector2(220,120)
		touch_at(point,true);mouse_at(point,true,true)
		var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=point-Vector2(0,95);drag.relative=Vector2(0,-95)
		send_event(drag);touch_at(drag.position,false);mouse_at(drag.position,false,true)
		await process_frame
		check(scroll.scroll_vertical>0,"Bonus recipient list scrolls by touch")
		game.confirm_bonus_selection(id,"reward","",1)
		check(B.total(game.run.actors[1],"mana_turn")==0 and B.total(game.run.actors[3],"mana_turn")==4,"Group compatible actors only")
		for rarity in 6:
			id="bonus:%d:max_hp:unique:%d"%[800+rarity,rarity]
			await prepare(id)
			card=descendants(game.overlay).filter(func(n):return n is Button and n.has_meta("bonus_rarity"))[0]
			check(card.get_meta("rarity_color")==Color(B.COLORS[rarity]),"Each rarity card background")
			check((card.get_theme_stylebox("normal") as StyleBoxFlat).bg_color==Color(B.COLORS[rarity]).darkened(.72),"Color used as actual background")
			if extent.x==540:await capture("rarity-%d"%rarity)
		game.run.interlude="shop";game.run.run_gold=100;game.run.shop_stock.assign(["bonus:900:max_hp:unique:0"])
		game.show_run_shop();await process_frame
		game.buy_run_supply("bonus:900:max_hp:unique:0");await process_frame
		check(game.run.run_gold==100 and game.state=="bonus_choice","Shop preview does not charge")
		game.cancel_bonus_selection("shop")
		check(game.state=="shop" and game.run.run_gold==100,"Shop cancel no mutation")
		game.buy_run_supply("bonus:900:max_hp:unique:0")
		game.confirm_bonus_selection("bonus:900:max_hp:unique:0","shop","scarlet",1)
		check(game.run.run_gold==68 and game.state=="shop","Shop atomic confirm returns to merchant")
		game.show_run_build();await capture("bonus-build-%d"%extent.x)
	game.queue_free();await process_frame
	print("BONUSES UI 098 ","PASS" if failures==0 else "FAIL"," · ",checks," checks")
	quit(1 if failures>0 else 0)
