extends SceneTree
var game:Control
func _initialize() -> void:call_deferred("checks")
func checks() -> void:
	var c:=TaleCampaign.new()
	assert(c.speed==2)
	assert(TaleCampaign.next_speed(2)==3 and TaleCampaign.next_speed(3)==4 and TaleCampaign.next_speed(4)==2)
	assert(TaleCampaign.speed_label(2)==1 and TaleCampaign.speed_label(4)==3)
	c.load_data({"version":11,"speed":1})
	assert(c.speed==2)
	c.speed=4
	var restored:=TaleCampaign.new()
	restored.load_data(c.to_dict())
	assert(restored.speed==4)
	var today:=Time.get_date_string_from_system()
	assert(not c.claim_daily("battles",today))
	for i in 5:c.record_goal_combat(1,str(i),3,i==4,3,today)
	assert(c.daily.battles==5 and c.daily.enemies==15 and c.daily.bosses==1)
	c.record_goal_combat(1,"4",3,true,3,today)
	assert(c.daily.battles==5)
	var before:=c.gold
	for id in ["battles","enemies","bosses"]:
		assert(c.claim_daily(id,today))
		assert(not c.claim_daily(id,today))
	assert(c.gold-before==175)
	c.record_achievement_state({"party_capacity":5})
	assert(c.achievement_ready("capacity"))
	assert(c.claim_achievement("capacity") and not c.claim_achievement("capacity"))
	assert(c.save_to("user://goals_speed_progress_test.json"))
	assert(restored.load_from("user://goals_speed_progress_test.json"))
	assert(restored.claimed.has("capacity") and not restored.claim_daily("battles",today))
	restored.refresh_daily("2099-01-01")
	assert(restored.daily.battles==0 and restored.daily.claimed.is_empty())
	restored.record_goal_combat(2,"0",3,false,1,"2099-01-01")
	restored.refresh_daily("2098-12-31")
	assert(restored.daily.day=="2099-01-01" and not restored.claim_daily("enemies","2098-12-31"))
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://goals_speed_test.json"
	root.add_child(game)
	game.set_process(false)
	game.campaign=c
	game.campaign.window_mode="windowed"
	game.campaign.window_mode_selected=true
	game.apply_window_mode()
	for extent in [Vector2i(1280,800),Vector2i(360,640)]:
		game.get_window().size=extent
		game.get_window().content_scale_size=extent
		await process_frame
		game.center_content()
		for tab in ["daily","achievements"]:
			game.show_goals(tab)
			await process_frame
			assert(game.page.find_child("Claim_"+("battles" if tab=="daily" else "hero_win_scarlet"),true,false)!=null)
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				game.get_window().get_texture().get_image().save_png("/tmp/goals-"+tab+"-"+str(extent.x)+".png")
	for hero in ["scarlet","snow_white","rapunzel","aladin"]:
		var texture=preload("res://scripts/achievement_art.gd").texture({"hero":hero})
		assert(texture.resource_path=="res://assets/ui/achievement_heroes/"+hero+".png")
		game.campaign.party.assign([hero])
		game.show_menu()
		await process_frame
		assert(game.page.find_child("GoldenArtFrame",true,false)!=null)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			game.get_window().get_texture().get_image().save_png("/tmp/hero-menu-"+hero+".png")
	game.campaign=preload("res://tests/test_accounts.gd").legacy()
	game.run=IdleRun.new()
	assert(game.run.start_expedition(game.campaign,"scarlet","vigor"))
	game.enter_encounter()
	game.arena.set_process(false)
	game.feedback.set_process(false)
	game.state="battle_outro"
	game.finish_encounter_now()
	assert(game.campaign.daily.battles==1 and game.campaign.goals.battles==1)
	game.finish_encounter_now()
	assert(game.campaign.daily.battles==1)
	game.game_speed=2
	game.toggle_speed()
	assert(game.game_speed==3 and game.arena.speed==3 and game.speed_button.text=="Velocidade 2×")
	game.toggle_speed()
	assert(game.game_speed==4)
	game.toggle_speed()
	assert(game.game_speed==2)
	game.queue_free()
	await process_frame
	print("GOALS SPEED PASS: speed defaults/cycle/migration, daily events, receipts, claims, saves, rollover, backward clock, PC/mobile UI")
	quit()
