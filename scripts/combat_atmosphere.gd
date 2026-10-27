extends Control
## Restrained, reusable visual feedback; never changes combat rules.
const StatusArt=preload("res://scripts/status_art.gd")
const AuraArt=preload("res://scripts/aura_art.gd")
const COLORS=AuraArt.COLORS
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
var weather:ColorRect
var fire:ColorRect
var weather_mode:=0
var weather_clock:=0.0
var burn_left:=0.0
var burn_duration:=1.2
func _ready() -> void:
	name="CombatAtmosphere"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	z_index=1100
	weather=shader_layer("Weather",preload("res://assets/fx/weather.gdshader"))
	var climate:String=str(arena.simulation.current_map().get("weather","none")) if is_instance_valid(arena) and arena.simulation.expedition else "none"
	weather_mode=int({"none":0,"snow":1,"rain":2,"sun":3,"embers":4}.get(climate,0))
	weather.material.set_shader_parameter("weather_mode",weather_mode)
	weather.visible=weather_mode>0
	fire=shader_layer("FireScreen",preload("res://assets/fx/fire_screen.gdshader"))
	fire.hide()
	wave=ColorRect.new()
	wave.name="BlueWave"
	wave.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader_material:=ShaderMaterial.new()
	shader_material.shader=preload("res://assets/fx/blue_wave.gdshader")
	wave.material=shader_material
	add_child(wave)
	wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave.hide()
func shader_layer(title:String,shader:Shader) -> ColorRect:
	var layer:=ColorRect.new()
	layer.name=title
	layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mat:=ShaderMaterial.new();mat.shader=shader;layer.material=mat
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer
func clear() -> void:
	wave_left=0
	shake_left=0
	shake_offset=Vector2.ZERO
	flashes.clear()
	burn_left=0
	if is_instance_valid(fire):fire.hide()
	if is_instance_valid(wave):wave.hide()
	queue_redraw()
func shake(strength:=1.6) -> void:
	if reduced_motion:return
	shake_strength=minf(2.0,maxf(0,strength))
	shake_left=shake_duration
func blue_wave() -> void:
	wave_left=wave_duration
	if is_instance_valid(wave):wave.show()
func burn_screen() -> void:
	burn_left=burn_duration
	if is_instance_valid(fire):fire.show()
func aura(index:int,color:String,duration:=1.5,style:="") -> void:
	flashes[index]={"color":AuraArt.canonical(color),"until":clock+duration,"style":style}
	queue_redraw()
func ultimate_started(index:int,id:String) -> void:
	if id in ["snow_white","matches"]:aura(index,"red",1.8)
	elif id in ["maria","aladin"]:aura(index,"purple",1.5)
	elif id in ["ariel","rapunzel","peter"]:aura(index,"blue",1.6)
func impact(id:String) -> void:
	if id=="ariel":blue_wave()
	if id=="matches":burn_screen()
	if id in ["snow_white","matches","mulan"]:shake(1.7 if id=="snow_white" else 1.2)
func color_for(data:Dictionary,index:=-1) -> String:
	if StatusArt.protected(data) or bool(data.get("enraged",false)) or float(data.get("rage_left",0))>0:return "red"
	if float(data.get("curse_left",0))>0:return "purple"
	if not str(data.get("aura_color","")).is_empty():return AuraArt.canonical(str(data.aura_color))
	if flashes.has(index) and float(flashes[index].until)>clock:return str(flashes[index].color)
	return ""
func _process(delta:float) -> void:
	if frozen:return
	clock+=delta
	if not reduced_motion:weather_clock+=minf(delta,.1)
	if is_instance_valid(weather):
		weather.material.set_shader_parameter("clock",weather_clock)
		weather.material.set_shader_parameter("aspect",size.x/maxf(1,size.y))
		weather.material.set_shader_parameter("layers",3 if is_instance_valid(arena) and arena.high_quality else 1)
		weather.material.set_shader_parameter("strength",.40 if reduced_motion else .65)
	burn_left=maxf(0,burn_left-delta)
	if is_instance_valid(fire):
		fire.visible=burn_left>0
		fire.material.set_shader_parameter("progress",1.0-burn_left/burn_duration)
		fire.material.set_shader_parameter("opacity",sin(PI*burn_left/burn_duration)*(.16 if reduced_motion else .29))
		fire.material.set_shader_parameter("reduced_motion",reduced_motion)
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
func aura_style(data:Dictionary,index:int,palette:String) -> String:
	var requested:String=str(data.get("aura_style",""))
	if requested.is_empty() and flashes.has(index) and float(flashes[index].until)>clock:requested=str(flashes[index].get("style",""))
	return AuraArt.style_for(palette,requested)
func draw_aura(feet:Vector2,height:float,color:Color,style:="flame") -> void:
	AuraArt.draw_tinted(self,feet,height,color,clock,reduced_motion,style)
func _draw() -> void:
	if not is_instance_valid(arena) or arena.simulation==null:return
	for index in arena.heroes.size():
		var data:Dictionary=arena.simulation.actors[index]
		if data.hp<=0:continue
		var color:=color_for(data,index)
		if color.is_empty():continue
		var model:AnimatedSprite2D=arena.heroes[index]
		draw_aura(arena.position+model.position,float(model.get_meta("visual_height",arena.human_height())),COLORS.get(color,COLORS.purple),aura_style(data,index,color))
	for index in arena.foes.size():
		var data:Dictionary=arena.simulation.tactics.enemies[index]
		if data.hp<=0 or not arena.enemy_visible:continue
		var color:=color_for(data)
		if not color.is_empty():draw_aura(arena.position+arena.foes[index].position,arena.human_height(),COLORS.get(color,COLORS.purple),aura_style(data,-1,color))
