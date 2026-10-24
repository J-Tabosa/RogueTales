extends SceneTree
const Health=preload("res://scripts/health_display.gd")
const Rules=preload("res://scripts/ultimate_rules.gd")
func _initialize() -> void:call_deferred("checks")
func descendants(node:Node) -> Array[Node]:
	var result:Array[Node]=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func touch(point:Vector2,pressed:bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=0
	event.position=point
	event.pressed=pressed
	Input.parse_input_event(event)
	await process_frame
func checks() -> void:
	assert(TaleCatalog.HERO_TACTICS.joao["class"]=="assassin")
	assert(TaleCatalog.HERO_TACTICS.snow_white["class"]=="vanguard")
	assert(TaleCatalog.HERO_TACTICS.rapunzel["class"]=="vanguard")
	var bar:=ProgressBar.new()
	root.add_child(bar)
	bar.size=Vector2(240,8)
	var data:Dictionary={"hp":200.0,"max_hp":200.0,"shield":40.0}
	Health.update(bar,data)
	assert(bar.max_value==240 and bar.value==240 and data.max_hp==200)
	var segment:=bar.get_node("ShieldSegment") as ColorRect
	assert(segment.position.x==200 and segment.size.x==40 and segment.visible)
	data.shield=0
	Health.update(bar,data)
	assert(not segment.visible and bar.max_value==200)
	bar.queue_free()
	var account:=TaleCampaign.new()
	account.unlocked.assign(TaleCatalog.HEROES.keys())
	var run:=IdleRun.new()
	assert(run.start_expedition(account,"joao","vigor"))
	assert(run.actors[0].row=="middle")
	# A formation saved before the class migration may have four new assassins.
	var saved:Array=[]
	for id in ["joao","maria","peter","mulan","rapunzel","puss","scarlet","alice","ariel"]:
		var solo:=IdleRun.new()
		assert(solo.start_expedition(account,id,"vigor"))
		saved.append(solo.actors[0].duplicate(true))
	run.actors.assign(saved)
	run.tactics.bind(run,account)
	var counts:Dictionary={"front":0,"middle":0,"back":0}
	for actor in run.actors:
		counts[actor.row]+=1
		assert(counts[actor.row]<=3)
		if actor["class"]=="vanguard":assert(actor.row=="front")
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://mobile_fixes_isolated.json"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	for id in Rules.IDS:
		var portrait=game.face_portrait(game.page,id,Rect2(0,0,80,80))
		assert(portrait.get_meta("portrait_source")=="res://assets/ults_v2/%s_portrait.webp"%id)
		var face=portrait.get_child(0)
		assert(face.size==portrait.size and face.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	game.campaign=account
	game.run=IdleRun.new()
	assert(game.run.start_expedition(account,"scarlet","vigor"))
	game.run.run_gold=10000
	game.run.shop_stock.assign(["item:echo_bell","item:iron_guard","item:ember_ring","item:swift_boots"])
	game.run.interlude="shop"
	game.show_run_shop()
	await process_frame
	var scroll:ScrollContainer
	for child in descendants(game.page):
		if child is ScrollContainer:scroll=child;break
	assert(scroll!=null and scroll.get_script()==preload("res://scripts/touch_scroll.gd"))
	var gold:int=game.run.run_gold
	var point:=scroll.get_global_rect().get_center()
	await touch(point,true)
	var drag:=InputEventScreenDrag.new()
	drag.index=0
	drag.position=point-Vector2(0,130)
	drag.relative=Vector2(0,-130)
	Input.parse_input_event(drag)
	await process_frame
	await touch(drag.position,false)
	assert(scroll.scroll_vertical>40 and game.run.run_gold==gold,"Swipe must scroll without purchasing")
	assert(game.audio.music.stream is AudioStreamOggVorbis and game.audio.music.stream.loop)
	assert(game.audio.music.stream.get_length()>100)
	game.queue_free()
	await process_frame
	print("MOBILE COMBAT FIXES PASS: classes, nine-unit migration, shield capacity, current portraits, safe shop swipe, original looping music")
	quit()
