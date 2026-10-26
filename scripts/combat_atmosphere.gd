extends Control
## Restrained, reusable visual feedback; never changes combat rules.
const StatusArt=preload("res://scripts/status_art.gd")
const COLORS={"red":Color("f04c54"),"blue":Color("66c7ef"),"purple":Color("b581ed"),"green":Color("83dc95"),"gold":Color("f7cb68")}
var arena
var frozen:=false
var reduced_motion:=false
var clock:=0.0
var wave_left:=0.0
var wave_duration:=1.1
var shake_left:=0.0
var shake_duration:=.18
var shake_strength:=0.0
var shake_offset:=Vector2.ZERO
var flashes:Dictionary={}
var wave:ColorRect
func _ready() -> void:
	name="CombatAtmosphere"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	z_index=1100
	wave=ColorRect.new()
	wave.name="BlueWave"
	wave.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader_material:=ShaderMaterial.new()
	shader_material.shader=preload("res://assets/fx/blue_wave.gdshader")
	wave.material=shader_material
	add_child(wave)
	wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave.hide()
func clear() -> void:
	wave_left=0
	shake_left=0
	shake_offset=Vector2.ZERO
	flashes.clear()
	if is_instance_valid(wave):wave.hide()
	queue_redraw()
func shake(strength:=1.6) -> void:
	if reduced_motion:return
	shake_strength=minf(2.0,maxf(0,strength))
	shake_left=shake_duration
func blue_wave() -> void:
	wave_left=wave_duration
	if is_instance_valid(wave):wave.show()
func aura(index:int,color:String,duration:=1.5) -> void:
	flashes[index]={"color":color,"until":clock+duration}
	queue_redraw()
func ultimate_started(index:int,id:String) -> void:
	if id in ["snow_white","matches"]:aura(index,"red",1.8)
	elif id in ["maria","aladin"]:aura(index,"purple",1.5)
	elif id in ["ariel","rapunzel","peter"]:aura(index,"blue",1.6)
func impact(id:String) -> void:
	if id=="ariel":blue_wave()
	if id in ["snow_white","matches","mulan"]:shake(1.7 if id=="snow_white" else 1.2)
func color_for(data:Dictionary,index:=-1) -> String:
	if StatusArt.protected(data) or bool(data.get("enraged",false)) or float(data.get("rage_left",0))>0:return "red"
	if float(data.get("curse_left",0))>0:return "purple"
	if not str(data.get("aura_color","")).is_empty():return str(data.aura_color)
	if flashes.has(index) and float(flashes[index].until)>clock:return str(flashes[index].color)
	return ""
func _process(delta:float) -> void:
	if frozen:return
	clock+=delta
	wave_left=maxf(0,wave_left-delta)
	shake_left=maxf(0,shake_left-delta)
	shake_offset=Vector2.ZERO
	if shake_left>0 and not reduced_motion:
		var weight:=shake_left/shake_duration
		shake_offset=Vector2(sin(clock*83),cos(clock*69)*.6)*shake_strength*weight
	if is_instance_valid(arena):arena.position=shake_offset
	if is_instance_valid(wave):
		wave.visible=wave_left>0
		var shader_material:=wave.material as ShaderMaterial
		shader_material.set_shader_parameter("progress",1.0-wave_left/wave_duration)
		shader_material.set_shader_parameter("opacity",sin(PI*wave_left/wave_duration)*.27)
		shader_material.set_shader_parameter("reduced_motion",reduced_motion)
	for index in flashes.keys():
		if flashes[index].until<=clock:flashes.erase(index)
	queue_redraw()
func draw_aura(feet:Vector2,height:float,color:Color) -> void:
	var pulse:=1.0 if reduced_motion else 1.0+sin(clock*3.0)*.035
	var profile:=PackedVector2Array([Vector2(0,-1.05),Vector2(-.20,-.86),Vector2(-.32,-.99),Vector2(-.29,-.57),Vector2(-.43,-.70),Vector2(-.30,-.24),Vector2(-.37,-.10),Vector2(-.18,.035),Vector2(0,.07),Vector2(.18,.035),Vector2(.37,-.10),Vector2(.30,-.24),Vector2(.43,-.70),Vector2(.29,-.57),Vector2(.32,-.99),Vector2(.20,-.86)])
	for n in profile.size():profile[n]=feet+profile[n]*height*pulse
	draw_colored_polygon(profile,Color(color,.10))
	profile.append(profile[0])
	draw_polyline(profile,Color(color,.42),1.4,true)
	for side in [-1,1]:
		var drift:=0.0 if reduced_motion else fposmod(clock*.24,1.0)
		var at:=feet+Vector2(side*height*.30,-height*(.2+drift*.65))
		draw_line(at,at+Vector2(-side*height*.04,-height*.10),Color(color,.40),2,true)
func _draw() -> void:
	if not is_instance_valid(arena) or arena.simulation==null:return
	for index in arena.heroes.size():
		var data:Dictionary=arena.simulation.actors[index]
		if data.hp<=0:continue
		var color:=color_for(data,index)
		if color.is_empty():continue
		var model:AnimatedSprite2D=arena.heroes[index]
		draw_aura(arena.position+model.position,float(model.get_meta("visual_height",arena.human_height())),COLORS.get(color,COLORS.purple))
	for index in arena.foes.size():
		var data:Dictionary=arena.simulation.tactics.enemies[index]
		if data.hp<=0 or not arena.enemy_visible:continue
		var color:=color_for(data)
		if not color.is_empty():draw_aura(arena.position+arena.foes[index].position,arena.human_height(),COLORS.get(color,COLORS.purple))
