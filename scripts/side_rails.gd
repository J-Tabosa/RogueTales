extends Control
## Fixed top/bottom flowers; only the separate center double rule stretches.
const FLOWER=preload("res://assets/ui/themes/shared/rail_flower.png")
const RULE=preload("res://assets/ui/themes/shared/rail_rule.svg")
const TINT=preload("res://assets/ui/themes/shared/ornament_tint.gdshader")
var flowers:Array[TextureRect]=[]
static func width_for(view_width:float) -> float:return clampf(view_width*.04,48,84)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_meta("theme_decoration",true)
	z_index=2000
	var region:=FLOWER.get_image().get_used_rect()
	var art:=AtlasTexture.new()
	art.atlas=FLOWER
	art.region=region
	for i in 4:
		var flower:=TextureRect.new()
		flower.texture=art
		flower.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		flower.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flower.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var tint:=ShaderMaterial.new()
		tint.shader=TINT
		flower.material=tint
		add_child(flower)
		flowers.append(flower)
	resized.connect(update_theme)
	update_theme()
func update_theme() -> void:
	var width:=width_for(size.x)
	var height:=(width-8)*1.25
	for i in flowers.size():
		flowers[i].position=Vector2(4 if i<2 else size.x-width+4,12 if i%2==0 else size.y-height-12)
		flowers[i].size=Vector2(width-8,height)
		flowers[i].flip_v=i%2==1
		flowers[i].material.set_shader_parameter("theme_tint",TaleTheme.c("ornament"))
	queue_redraw()
func _draw() -> void:
	var width:=width_for(size.x)
	var height:=(width-8)*1.25
	for x in [0.0,size.x-width]:
		draw_rect(Rect2(x,0,width,size.y),TaleTheme.c("background"))
		draw_rect(Rect2(x+1,1,width-2,size.y-2),TaleTheme.c("border",.55),false,1)
		draw_texture_rect(RULE,Rect2(x+width*.5-3,height+16,6,maxf(0,size.y-2*height-32)),false,TaleTheme.c("border"))
