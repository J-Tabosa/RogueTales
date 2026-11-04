extends SceneTree
const Phase1=preload("res://scripts/phase1_enemies.gd")
const Balance=preload("res://scripts/enemy_balance.gd")
const Model=preload("res://scripts/enemy.gd")
const Arena=preload("res://scripts/tactical_arena.gd")
var failures:=0
var checks:=0

func _initialize() -> void:call_deferred("test")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)

func fixture(season:String) -> IdleRun:
	var campaign=preload("res://tests/test_accounts.gd").legacy()
	var run=IdleRun.new()
	check(run.start_expedition(campaign,"scarlet","blessing:scarlet:0"),"Create run")
	for map in Phase1.MAPS:
		if Phase1.MAPS[map]==season:run.journey={"format":1,"season":season,"path":[map]}
	run.room_kind="battle"
	return run

func test() -> void:
	Balance.reload_if_changed()
	check(Balance.last_error.is_empty(),"Delivered workbook accepts new profiles: "+Balance.last_error)
	var averages=Phase1.averages()
	check(is_equal_approx(averages.hp,215.8333333333) and is_equal_approx(averages.damage,22.4166666667),"Level-one reference uses all twelve unmodified kits")
	check(is_equal_approx(averages.initiative,46.6666666667),"Speed is initiative, not animation FPS")
	for season in ["spring","summer","autumn","winter"]:
		var run=fixture(season)
		var seen:={}
		for phase in [0,1,2,3,4,5]:
			run.phase=phase
			for seed_value in 40:
				run.rng.seed=seed_value
				run.spawn_enemy()
				var enemies=run.tactics.enemies
				check(enemies.size()==0 if phase==4 else enemies.size()==1 if phase==5 else enemies.size()==phase+1 if phase<3 else enemies.size() in [1,2,3],"Tutorial counts and solo boss: "+season)
				for foe in enemies:
					seen[foe.species_id]=true
					check(str(foe.species_id).begins_with(season+"_"),"No cross-season or old forest monster")
					check(foe.boss==(phase==5),"Boss never enters common pool")
					check(foe["class"]!="mage" and foe.evasion==0 and foe.attacks==1,"Physical forest roster, zero evasion, one basic")
					check(foe.category in ["beast","humanoid"],"Explicit category powers beast bonuses")
					check(is_equal_approx(foe.hp,Balance.profiles[foe.balance_id].vida_base*.85),"No duplicated boss/growth multiplier")
					check(is_equal_approx(foe.damage,Balance.profiles[foe.balance_id].ataque_base*.80),"No damage dilution by group")
					check(run.tactics.intent_for(foe.slot).key=="attack","Old boss/support magic cannot leak into forests")
		check(seen.size()==4,"All three commons and the correct boss reachable: "+season)
		# Other route nodes retain the original catalog and mechanics.
		run.journey.clear();run.phase=0;run.spawn_enemy()
		check(not run.tactics.enemies[0].has("species_id"),"Legacy and later-biome fallback retained")
	for id in Phase1.DATA:
		var d=Phase1.metadata(id)
		var frames=Phase1.frames(id)
		var expected=12 if id=="spring_boar" else 6 if id=="summer_falcon" else 8
		check(frames.get_frame_count("attack")==expected,"Exact imported attack count: "+id)
		check(frames.get_frame_count("idle")==4 if id in ["summer_falcon","winter_owl"] else frames.get_frame_count("idle")==1,"Loop count/static first frame: "+id)
		check(not frames.get_animation_loop("attack") and frames.get_animation_loop("idle"),"Attack once; idle loop")
		for anim in ["attack","idle"]:
			for n in frames.get_frame_count(anim):
				var image=frames.get_frame_texture(anim,n).get_image()
				var used=image.get_used_rect()
				check(image.get_size()==Vector2i(768,768),"Fixed canvas across idle/attack")
				check(used.position.x>=3 and used.position.y>=3 and used.end.x<=765 and used.end.y<=765,"No clipped art or FX: %s %s %d"%[id,anim,n])
				check(image.get_pixel(0,0).a==0 and image.get_pixel(767,767).a==0,"Real transparent alpha")
		var model=AnimatedSprite2D.new();model.set_script(Model)
		model.species_id=id;model.sprite_frames=frames
		model.species_anchor=Vector2(d.anchor[0],d.anchor[1]);model.body_height=d.reference_height
		root.add_child(model)
		model.advance(0,false,0,3)
		var scale_before=model.scale
		model.begin_strike(false)
		check(model.animation=="attack" and model.frame==0,"Attack starts at frame one")
		model.advance(model.animation_duration("attack")+.001,false,0,3)
		check(model.animation=="idle" and model.scale==scale_before,"Immediate idle, no final-frame hold or size change")
		model.queue_free()
	var owner=fixture("spring");owner.phase=5;owner.spawn_enemy()
	var before:float=owner.actors[0].hp
	owner.actors[0].evasion=0
	owner.actors[0].armor=0;owner.actors[0].physical_defense=0
	var power:float=owner.tactics.enemies[0].damage
	for part in 3:owner.tactics.phase1_impact(0,part,3)
	check(is_equal_approx(before-owner.actors[0].hp,power),"Bear damage distributed across three impact frames without tripling")
	check(owner.tactics.enemies[0].action_count==1,"Multiple impact frames still one attack action")
	var snake=fixture("summer");snake.phase=5;snake.spawn_enemy()
	var victim:Dictionary=snake.actors[0]
	victim.evasion=0;victim.hp=10000;victim.max_hp=10000
	var hit=snake.tactics.phase1_impact(0,0,1)
	check(hit.has("constricted") and snake.tactics.Rules.has_status(victim,"stun"),"Snake applies constriction stun")
	var turn=snake.tactics.Rules.start_turn(snake.tactics,victim)
	check(turn.skip and turn.attacks==0,"Stun always skips next action")
	snake.tactics.Rules.end_turn(victim)
	check(not snake.tactics.Rules.has_status(victim,"stun"),"Stun expires after one action")
	victim.immune_control=true
	check(not snake.tactics.Rules.status(victim,"stun","snake",1),"Control immunity respected")
	for id in Phase1.DATA:
		check(Phase1.animation_fps(id)<10,"All forest attacks slower")
		check(Phase1.animation_fps(id)<=4.5 if id in ["winter_owl","summer_falcon"] else true,"Flying attacks particularly readable")
	var Layout=preload("res://scripts/formation_layout.gd")
	for hostile in [false,true]:
		for row in Layout.ROWS:
			var units:Array=[{"row":row},{"row":row}]
			check(is_equal_approx(Layout.home(units,0,hostile).y,.53) and is_equal_approx(Layout.home(units,1,hostile).y,.79),"Two units use intermediate slots")
			units.append({"row":row})
			for at in 3:check(is_equal_approx(Layout.home(units,at,hostile).y,[.40,.66,.92][at]),"Three-unit slots unchanged")
			units.resize(1)
			check(is_equal_approx(Layout.home(units,0,hostile).y,.66),"Single unit remains centered")
	for id in Phase1.DATA:
		var sprite:=AnimatedSprite2D.new()
		sprite.set_script(Model)
		sprite.species_id=id;sprite.sprite_frames=Phase1.frames(id)
		sprite.regular_height=100;sprite.boss_height=125
		sprite.advance(0,Phase1.DATA[id][8],0,3)
		var image:=sprite.sprite_frames.get_frame_texture(sprite.animation,0).get_image()
		var bounds:=Phase1.visual_bounds(image)
		check(is_equal_approx(maxf(bounds.size.x,bounds.size.y)*sprite.scale.x,125.0 if Phase1.DATA[id][8] else 100.0),"Shared visible span; only bosses larger: "+id)
		sprite.free()
	var cleaned:Image=(load("res://assets/enemies/phase1/autumn_lumberjack/attack/01.png") as Texture2D).get_image()
	for point in [Vector2i(450,472),Vector2i(456,471)]:check(cleaned.get_pixelv(point).a<.04,"Arm/torso gap is transparent")
	print("PHASE1 ENEMIES: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
