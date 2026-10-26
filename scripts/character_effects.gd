extends RefCounted
const AlphaArt = preload("res://scripts/jpeg_alpha.gd")
const IDS := ["mulan","aladin","ariel","puss","alice","matches","joao","maria","peter","rapunzel"]
const SUITS := ["♦","♥","♣","♠"]
static var frames: Dictionary = {}
static func frame(id: String,progress: float,ultimate:=false) -> Texture2D:
	var number := clampi(int(progress*6),0,5)
	var key := "%s:%d:%s" % [id,number,ultimate]
	if not frames.has(key):
		var source := AlphaArt.texture("res://assets/characters/%s/effects.jpg" % id)
		var cell := source.get_size()/Vector2(6,2)
		var atlas := AtlasTexture.new()
		atlas.atlas=source
		atlas.region=Rect2(Vector2(number,1 if ultimate else 0)*cell,cell)
		atlas.filter_clip=true
		frames[key]=atlas
	return frames[key]
static func stamp(canvas: Node2D,id: String,at: Vector2,extent: Vector2,progress: float,ultimate:=false,angle:=0.0,opacity:=1.0) -> void:
	canvas.draw_set_transform(at,angle)
	canvas.draw_texture_rect(frame(id,progress,ultimate),Rect2(-extent*0.5,extent),false,Color(1,1,1,opacity))
	canvas.draw_set_transform(Vector2.ZERO)
static func basic(arena,canvas: Node2D,index: int,phase: float) -> void:
	var track: Dictionary = arena.tracks[index]
	var id: String=arena.simulation.actors[index].id
	var height: float=arena.human_height()
	var impact: float=arena.heroes[index].impact_ratio
	if phase<0.18: return
	var t:=clampf((phase-0.18)/maxf(0.05,impact-0.18),0,1)
	var origin: Vector2=arena.heroes[index].position+Vector2(height*0.12,-height*0.55)
	var target: Vector2=arena.foe_homes[track.target]+Vector2(0,-height*0.45)
	if id in ["mulan","puss","joao","rapunzel"]:
		if t>0.5: stamp(canvas,id,target,Vector2.ONE*height*1.15,t)
	elif id=="matches":
		stamp(canvas,id,origin if t<0.45 else target,Vector2.ONE*height*1.3,t)
	else:
		stamp(canvas,id,origin.lerp(target,t),Vector2.ONE*height*(0.9 if id=="peter" else 0.7),t,false,(target-origin).angle() if id!="peter" else 0.0)
static func burst(arena,canvas: Node2D,item: Dictionary) -> void:
	var t: float=1.0-item.left/item.duration
	var id: String=item.id
	var h: float=arena.human_height()
	var extent:=Vector2.ONE*h*1.5
	var point: Vector2=item.at
	var opacity:=minf(1,(1-t)*5)
	if id=="aladin" or id=="ariel":
		point=Vector2(item.from).lerp(Vector2(arena.field_width*0.5,arena.field_height*0.56),smoothstep(0,0.65,t))
		extent=Vector2(arena.field_width*1.05,arena.field_height*(0.9 if id=="aladin" else 0.85))*lerpf(0.1,1.0,smoothstep(0,0.55,t))
		opacity*=0.65
	elif id=="maria":
		point=Vector2(item.from)+Vector2(0,-h*0.4) if t<0.3 else Vector2(item.from).lerp(item.at,(t-0.3)/0.7)
	elif id=="mulan": extent=Vector2(h*1.3,h*1.8)
	stamp(canvas,id,point,extent,t,true,0,opacity)
	if id=="alice":
		canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-10,8),SUITS[int(item.get("suit",0))%4],HORIZONTAL_ALIGNMENT_CENTER,30,24,Color("f9e9c9",opacity))
