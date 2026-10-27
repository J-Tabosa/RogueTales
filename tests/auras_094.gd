extends SceneTree
const Aura=preload("res://scripts/aura_art.gd")
class Layer extends Control:
	const Art=preload("res://scripts/aura_art.gd")
	var palette:="red"
	var time:=0.0
	var reduced:=false
	func _draw() -> void:
		Art.draw(self,Vector2(size.x*.5,171),132,palette,time,reduced)
class Backdrop extends Control:
	func _draw() -> void:
		for y in ceili(size.y/20.0):
			for x in ceili(size.x/20.0):
				draw_rect(Rect2(x*20,y*20,20,20),Color("193b35") if (x+y)%2==0 else Color("28483f"))
var layers:Array[Layer]=[]
var destination:=""
func _initialize() -> void:call_deferred("checks")
func capture(name:String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	picture.save_png(destination.path_join(name+".png"))
	return picture
func checks() -> void:
	assert(Aura.COLORS.size()==16 and Aura.NAMES.size()==16 and Aura.THEMES.size()==16)
	var unique:Dictionary={}
	for color in Aura.COLORS.values():unique[color.to_html()]=true
	assert(unique.size()==16)
	assert(Aura.canonical("vermelho")=="red" and Aura.canonical("turquesa")=="teal" and Aura.canonical("ROXO")=="purple")
	assert(Aura.BODY_ALPHA<.25 and Aura.CORE_ALPHA<.25 and Aura.GLOW_ALPHA<.05)
	for key in Aura.COLORS:assert(Aura.style_for(key) in Aura.STYLES)
	var account:=preload("res://tests/test_accounts.gd").legacy()
	var sim:=IdleRun.new()
	assert(sim.start_expedition(account,"scarlet","vigor"))
	sim.spawn_enemy()
	var arena=preload("res://scripts/tactical_arena.gd").new()
	arena.simulation=sim
	arena.party_scenes.assign([TaleCatalog.HERO_SCENES.scarlet])
	root.add_child(arena)
	arena.set_process(false)
	var fx=preload("res://scripts/combat_atmosphere.gd").new()
	fx.arena=arena
	root.add_child(fx)
	fx.set_process(false)
	for key in Aura.COLORS:
		fx.aura(0,key,.5)
		assert(fx.color_for(sim.actors[0],0)==key)
	fx.aura(0,"verde",.5,"spiral")
	assert(fx.aura_style(sim.actors[0],0,"green")=="spiral")
	fx.frozen=true
	var saved:float=fx.clock
	fx._process(1)
	assert(fx.clock==saved and fx.flashes.has(0))
	fx.frozen=false
	fx._process(.6)
	assert(fx.color_for(sim.actors[0],0).is_empty())
	sim.actors[0]["aura_color"]="turquesa"
	assert(fx.color_for(sim.actors[0],0)=="teal")
	sim.actors[0]["immortal_turns"]=1
	assert(fx.color_for(sim.actors[0],0)=="red")
	arena.queue_free()
	fx.queue_free()
	await process_frame
	if OS.get_cmdline_user_args().is_empty() or DisplayServer.get_name()=="headless":
		print("AURAS 094 PASS: 16 unique palettes, four original ribbon themes, translucent layers, aliases, timers, pause, protection and custom styles")
		quit()
		return
	destination=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(destination)
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(960,960)
	root.content_scale_size=Vector2i(960,960)
	var sheet:=Control.new()
	sheet.size=Vector2(960,960)
	root.add_child(sheet)
	var bg:=ColorRect.new()
	bg.color=Color("0d211e")
	bg.size=sheet.size
	sheet.add_child(bg)
	var title:=Label.new()
	title.text="ROGUETALES · 16 AURAS TRANSLÚCIDAS"
	title.position=Vector2(18,9)
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color("f2d28e"))
	sheet.add_child(title)
	var at:=0
	for key in Aura.COLORS:
		var tile:=Control.new()
		tile.position=Vector2(12+(at%4)*237,49+floori(at/4.0)*218)
		tile.size=Vector2(225,206)
		tile.clip_contents=true
		sheet.add_child(tile)
		var checker:=Backdrop.new()
		checker.size=tile.size
		tile.add_child(checker)
		var model:AnimatedSprite2D=TaleCatalog.HERO_SCENES.snow_white.instantiate()
		tile.add_child(model)
		model.set_process(false)
		var texture:MeshTexture=model.sprite_frames.get_frame_texture("idle",0)
		var bounds:AABB=texture.mesh.get_aabb()
		model.offset=-Vector2(bounds.position.x+bounds.size.x*.5,bounds.end.y)
		model.scale=Vector2.ONE*(116.0/bounds.size.y)
		model.position=Vector2(112.5,171)
		var layer:=Layer.new()
		layer.size=tile.size
		layer.palette=key
		tile.add_child(layer)
		layers.append(layer)
		var name:=Label.new()
		name.text=Aura.NAMES[key]
		name.position=Vector2(10,4)
		name.add_theme_font_size_override("font_size",15)
		name.add_theme_color_override("font_color",Aura.COLORS[key].lerp(Color.WHITE,.30))
		tile.add_child(name)
		var theme:=Label.new()
		theme.text={"flame":"CHAMA","orbit":"ÓRBITA","spiral":"ESPIRAL","tide":"CORRENTE"}[Aura.style_for(key)]
		theme.position=Vector2(10,183)
		theme.add_theme_font_size_override("font_size",11)
		theme.add_theme_color_override("font_color",Color("b8c5b8"))
		tile.add_child(theme)
		at+=1
	for frame in 48:
		for layer in layers:
			layer.time=frame/12.0
			layer.queue_redraw()
		await capture("frame-%02d"%frame)
	for layer in layers:
		layer.reduced=true
		layer.time=.3
		layer.queue_redraw()
	var one:=await capture("reduced-a")
	for layer in layers:
		layer.time=8.3
		layer.queue_redraw()
	var two:=await capture("reduced-b")
	assert(one.get_data()==two.get_data(),"Reduced-motion aura must remain still")
	print("AURAS VISUAL PASS: 16 moving translucent color themes; reduced-motion output stays still")
	quit()
