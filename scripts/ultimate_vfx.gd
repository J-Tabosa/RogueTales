extends RefCounted
## Frame animation and travel share the exact targets and impact clock of the rules.
const Rules = preload("res://scripts/ultimate_rules.gd")
static var atlases: Dictionary = {}
static func supported(id: String) -> bool:
	return id in Rules.IDS
static func duration(id: String) -> float:
	return 2.9 if id=="snow_white" else 2.7 if id in ["scarlet","joao","matches"] else 2.5
static func impact(id: String) -> float:
	return {"joao":.80,"snow_white":.66,"rapunzel":.58,"maria":.62,"peter":.60,"aladin":.72}.get(id,.72)
static func frame(id: String,progress: float) -> Texture2D:
	var number:=clampi(int(progress*12),0,11)
	var key:="%s:%d"%[id,number]
	if not atlases.has(key):
		var sheet:Texture2D=load("res://assets/ults_v2/%s_fx.webp"%id)
		var tex:=AtlasTexture.new()
		tex.atlas=sheet
		tex.region=Rect2(Vector2(number%4,number/4)*512,Vector2.ONE*512)
		tex.filter_clip=true
		atlases[key]=tex
	return atlases[key]
static func stamp(canvas:Node2D,id:String,at:Vector2,extent:Vector2,progress:float,opacity:=1.0,angle:=0.0) -> void:
	canvas.draw_set_transform(at,angle)
	canvas.draw_texture_rect(frame(id,progress),Rect2(-extent*.5,extent),false,Color(1,1,1,clampf(opacity,0,1)))
	canvas.draw_set_transform(Vector2.ZERO)
static func center(arena,targets:Array) -> Vector2:
	var point:=Vector2.ZERO
	for at in targets:point+=arena.foe_homes[at]
	return point/maxi(1,targets.size())
static func pose(arena,index:int,phase:float) -> void:
	var track:Dictionary=arena.tracks[index]
	var actor=arena.heroes[index]
	var id:String=arena.simulation.actors[index].id
	var hit:=impact(id)
	actor.seek_animation("ultimate",phase*actor.get_animation_duration("ultimate"))
	actor.position=track.home
	actor.scale=actor.get_meta("battle_scale")
	if id in ["joao","mulan","snow_white"] and track.target>=0:
		var contact:Vector2=arena.foe_homes[track.target]+Vector2(-arena.human_height()*.48,3)
		var dash:=smoothstep(.10,.26,phase) if phase<hit else 1.0-smoothstep(hit+.05,1.0,phase)
		actor.position=Vector2(track.home).lerp(contact,dash)
		if id=="mulan" and not arena.reduced_motion:
			# Turn around the body's center while keeping her feet on the floor.
			actor.scale.x*=cos(TAU*3*smoothstep(.20,hit,phase)) if phase<hit else 1.0
	elif id=="ariel":
		var destination:=center(arena,track.effect_targets)+Vector2(-arena.human_height()*.2,0)
		var ride:=smoothstep(.18,hit,phase) if phase<hit else 1.0-smoothstep(hit+.12,1.0,phase)
		actor.position=Vector2(track.home).lerp(destination,ride)
static func draw(arena,canvas:Node2D) -> void:
	var h:float=arena.human_height()
	for index in arena.tracks.size():
		var track:Dictionary=arena.tracks[index]
		var id:String=arena.simulation.actors[index].id
		if track.time<0 or not track.get("fresh_ult",false):continue
		var p:float=clampf(track.time/track.duration,0,1)
		var hit:=impact(id)
		var flight:=smoothstep(.20,hit,p)
		var tail:=minf(1,(1-p)*6)
		var origin:Vector2=track.home+Vector2(0,-h*.62)
		var targets:Array=track.get("effect_targets",[])
		var aim:Vector2=center(arena,targets)+Vector2(0,-h*.45)
		match id:
			"scarlet":
				for at in targets:
					var to:Vector2=arena.foe_homes[at]+Vector2(0,-h*.4)
					var point:=origin.lerp(to,flight)-Vector2(0,sin(flight*PI)*h*1.25)
					var anim:=lerpf(0,.42,flight) if p<hit else lerpf(.43,1.0,(p-hit)/(1-hit))
					stamp(canvas,id,point,Vector2.ONE*h*(.62 if p<hit else 1.25),anim,tail)
			"ariel":
				var point:=origin.lerp(aim,flight)+Vector2(0,h*.10)
				stamp(canvas,id,point,Vector2(h*2.4,h*1.6),p,tail*.85)
				if p>=hit:
					for at in targets:stamp(canvas,id,arena.foe_homes[at]+Vector2(0,-h*.30),Vector2.ONE*h,p,tail*.55)
			"aladin":
				for at in targets:
					var point:=origin.lerp(arena.foe_homes[at]+Vector2(0,-h*.48),flight)
					stamp(canvas,id,point,Vector2.ONE*h*lerpf(.5,1.5,flight),p,tail*.8)
			"maria":
				stamp(canvas,id,origin+Vector2(0,-h*.62),Vector2.ONE*h*.95,p,tail)
				if p>.25:
					for at in targets:
						var to:Vector2=arena.foe_homes[at]+Vector2(0,-h*.6)
						stamp(canvas,id,origin.lerp(to,flight),Vector2.ONE*h*.75,p,tail*.7)
			"peter":
				stamp(canvas,id,origin+Vector2(h*.30,-h*.15),Vector2.ONE*h*.70,p,tail)
			"joao":
				if p>=.24 and p<hit:
					var pulse:=fposmod((p-.24)/(.56/6),1.0)
					var from:Vector2=arena.heroes[index].position+Vector2(h*.18,-h*.52)
					stamp(canvas,id,from.lerp(aim,pulse),Vector2(h*1.3,h*.58),pulse,tail)
			"mulan":
				if p>.20:
					for at in targets:
						var from:Vector2=arena.heroes[index].position+Vector2(0,-h*.5)
						var to:Vector2=arena.foe_homes[at]+Vector2(0,-h*.45)
						stamp(canvas,id,from.lerp(to,flight),Vector2(h*1.6,h*.9),fposmod(p*3,1),tail)
			"snow_white":
				# The pose atlas already contains the eye glint on her actual eye.
				if p>=hit and not targets.is_empty():
					ground_stamp(canvas,id,arena.foe_homes[targets[0]],Vector2(h*1.8,h*1.2),lerpf(.25,1,(p-hit)/(1-hit)),tail)
			"rapunzel":
				for at in track.get("ally_targets",[]):
					var from:Vector2=track.home+Vector2(0,-h*.10)
					var to:Vector2=arena.tracks[at].home+Vector2(0,-h*.08)
					var end:=from.lerp(to,flight)
					stamp(canvas,id,(from+end)*.5,Vector2(maxf(h*.7,from.distance_to(end)+h*.45),h*.7),p,tail*.85,(to-from).angle())
					if p>=hit:stamp(canvas,id,to+Vector2(0,-h*.4),Vector2.ONE*h,p,tail*.6)
			"alice":
				if not targets.is_empty():
					var left:=INF
					var right:=-INF
					for at in targets:
						left=minf(left,arena.foe_homes[at].x-h*.45)
						right=maxf(right,arena.foe_homes[at].x+h*.60)
					var point:=Vector2(lerpf(origin.x,right,flight),aim.y)
					if p<.24:point=origin
					stamp(canvas,id,point,Vector2(h*2.3,h*.95),p,tail)
			"matches":
				if p<.30:
					var point:=origin+Vector2.from_angle(p*TAU*7)*h*.48
					stamp(canvas,id,point,Vector2.ONE*h*.8,p,1)
				else:
					stamp(canvas,id,origin.lerp(aim,flight),Vector2(h*2.2,h*1.4),p,tail)
					if p>=hit:
						for at in targets:stamp(canvas,id,arena.foe_homes[at]+Vector2(0,-h*.45),Vector2.ONE*h*.95,p,tail*.65)
	# Protection stays visible until its corresponding mechanic is consumed.
	for index in arena.simulation.actors.size():
		var actor:Dictionary=arena.simulation.actors[index]
		if actor.hp<=0:continue
		var home:Vector2=arena.heroes[index].position
		if actor.id=="peter":
			for spirit in int(actor.get("guardian_spirits",0)):
				var angle:float=spirit*TAU/3.0+(0.0 if arena.reduced_motion else arena.clock*1.2)
				stamp(canvas,"peter",home+Vector2(0,-h*.55)+Vector2.from_angle(angle)*h*.48,Vector2.ONE*h*.43,fposmod(arena.clock*.65+spirit*.23,1))
		if float(actor.get("shield",0))>0:
			shield_bubble(canvas,home,float(arena.heroes[index].get_meta("visual_height",h)),arena.clock,arena.reduced_motion)
		if actor.get("hair_guard",false) and actor.shield>0:
			stamp(canvas,"rapunzel",home+Vector2(0,-h*.28),Vector2(h*.95,h*.80),.76+sin(arena.clock*2)*.06,.30)
	for at in arena.foe_homes.size():
		var foe:Dictionary=arena.simulation.tactics.enemies[at]
		if foe.hp<=0 or not arena.enemy_visible:continue
		if float(foe.get("shield",0))>0:shield_bubble(canvas,arena.foe_homes[at],h,arena.clock,arena.reduced_motion)
		if int(foe.get("sleep_turns",0))>0:
			stamp(canvas,"aladin",arena.foe_homes[at]+Vector2(0,-h*.68),Vector2.ONE*h*.7,fposmod(arena.clock*.4,1),.5)
		if float(foe.get("curse_left",0))>0:
			stamp(canvas,"maria",arena.foe_homes[at]+Vector2(0,-h*.85),Vector2.ONE*h*.45,fposmod(arena.clock*.4,1),.65)

static var ground_regions:Dictionary={}
static func ground_stamp(canvas:Node2D,id:String,feet:Vector2,extent:Vector2,progress:float,opacity:float) -> void:
	var texture:=frame(id,progress)
	var key:="%s:%d"%[id,clampi(int(progress*12),0,11)]
	if not ground_regions.has(key):ground_regions[key]=texture.get_image().get_used_rect()
	var region:Rect2=ground_regions[key]
	var anchor:=Vector2(region.get_center().x,region.end.y)/512.0*extent
	canvas.draw_texture_rect(texture,Rect2(feet-anchor,extent),false,Color(1,1,1,opacity))
static func shield_bubble(canvas:Node2D,feet:Vector2,height:float,clock:float,reduced:bool) -> void:
	var pulse:=1.0 if reduced else 1.0+sin(clock*2.2)*.018
	var radius:=height*.50*pulse
	canvas.draw_set_transform(feet+Vector2(0,-height*.52),0,Vector2(.72,1))
	canvas.draw_circle(Vector2.ZERO,radius,Color("8ddbee",.075),true,-1,true)
	canvas.draw_arc(Vector2.ZERO,radius,0,TAU,48,Color("bceffc",.40),1.5,true)
	canvas.draw_set_transform(Vector2.ZERO)
