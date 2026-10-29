extends SceneTree
var game:Control
var destination:=""
func _initialize() -> void:call_deferred("checks")
func descendants(node:Node) -> Array[Node]:
	var result:Array[Node]=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result
func capture(title:String) -> void:
	if destination.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_window().get_texture().get_image().save_png(destination.path_join(title+".png"))
func checks() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		destination=OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(destination)
	var c:=TaleCampaign.new()
	var original:=c.to_dict().duplicate(true)
	for invalid in ["","500001","500,001","500.002","abc","500.001x"]:
		assert(not c.redeem_code(invalid).ok)
		assert(c.to_dict()==original,"Invalid input changes nothing")
	c.checkpoint={"untouched":true}
	var before_gold:=c.gold
	var before_blessings:=c.blessings_unlocked.duplicate()
	var valid:=c.redeem_code(" 500.001 ")
	assert(valid.ok and valid.added==TaleCatalog.HEROES.size())
	assert(c.unlocked.size()==TaleCatalog.HEROES.size() and c.party.size()==1)
	assert(c.gold==before_gold and c.blessings_unlocked==before_blessings and c.checkpoint=={"untouched":true})
	assert(c.redeem_code("500.001").added==0 and c.unlocked.size()==TaleCatalog.HEROES.size())
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://redemption_code_test.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=TaleCampaign.new()
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	await process_frame
	for extent in [Vector2i(540,960),Vector2i(1280,800)]:
		game.get_window().size=extent
		game.get_window().content_scale_size=extent
		await process_frame
		game.center_content()
		game.state="menu"
		game.show_settings()
		await process_frame
		var nodes:=descendants(game.page)
		var field:LineEdit=nodes.filter(func(n):return n.name=="RedemptionCode")[0]
		var feedback:Label=nodes.filter(func(n):return n.name=="RedemptionFeedback")[0]
		var submit:Button=nodes.filter(func(n):return n is Button and n.text=="Resgatar")[0]
		var section:Control=field.get_parent()
		var scroll:ScrollContainer=section.get_parent().get_parent()
		scroll.ensure_control_visible(section)
		await process_frame
		assert(section.size.x==476 and field.size.y>=48 and submit.size.y>=48)
		field.text="invalid"
		submit.pressed.emit()
		assert(feedback.text.begins_with("Código inválido"))
		field.text="500.001"
		field.text_submitted.emit(field.text)
		assert(game.campaign.unlocked.size()==TaleCatalog.HEROES.size())
		assert(field.text.is_empty() and not feedback.text.is_empty())
		var restored:=TaleCampaign.new()
		assert(restored.load_from(game.save_path))
		assert(restored.unlocked.size()==TaleCatalog.HEROES.size() and restored.gold==TaleCampaign.HERO_PRICE)
		await capture("settings-code-"+str(extent.x))
	# A failed write must not leave a grant that the UI claims is permanent.
	game.campaign=TaleCampaign.new()
	game.save_path="user://missing-code-dir-%d/save.json"%Time.get_ticks_usec()
	var entry:=LineEdit.new()
	var feedback:=Label.new()
	entry.text="500.001"
	game.redeem_settings_code(entry,feedback)
	assert(game.campaign.unlocked.is_empty() and feedback.text.contains("Não foi possível salvar"))
	game.debug_session=true
	game.redeem_settings_code(entry,feedback)
	assert(game.campaign.unlocked.is_empty() and feedback.text.contains("DEBUG"))
	entry.free()
	feedback.free()
	game.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute("user://redemption_code_test.json"+suffix)
	print("REDEMPTION CODES PASS: invalid input, free permanent unlock, idempotence, save/reload, untouched run/blessings, PC/mobile field, save failure rollback")
	quit()
