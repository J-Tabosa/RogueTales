extends RefCounted
const HERO_IMAGES={
	"snow_white":preload("res://assets/ui/achievement_heroes/snow_white.png"),
	"scarlet":preload("res://assets/ui/achievement_heroes/scarlet.png"),
	"rapunzel":preload("res://assets/ui/achievement_heroes/rapunzel.png"),
	"aladin":preload("res://assets/ui/achievement_heroes/aladin.png"),
	"maria":preload("res://assets/ui/achievement_heroes/maria.png"),
	"matches":preload("res://assets/ui/achievement_heroes/matches.png"),
	"mulan":preload("res://assets/ui/achievement_heroes/mulan.png"),
	"ariel":preload("res://assets/ui/achievement_heroes/ariel.png"),
	"peter":preload("res://assets/ui/achievement_heroes/peter.png"),
	"alice":preload("res://assets/ui/achievement_heroes/alice.png"),
	"joao":preload("res://assets/ui/achievement_heroes/joao.png")
}
static var atlas:Texture2D
static func fitted_rect(texture:Texture2D,box:Rect2) -> Rect2:
	var extent:=texture.get_size()
	var fitted:=extent*minf(box.size.x/extent.x,box.size.y/extent.y)
	return Rect2(box.position+(box.size-fitted)*.5,fitted)
static func gold_frame(parent:Control,rect:Rect2) -> void:
	var frame:=Panel.new()
	frame.name="GoldenArtFrame"
	frame.position=rect.position
	frame.size=rect.size
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var skin:=StyleBoxFlat.new()
	skin.bg_color=Color.TRANSPARENT
	skin.border_color=Color("edc56e")
	skin.set_border_width_all(3)
	skin.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel",skin)
	parent.add_child(frame)
static func texture(task:Dictionary,concealed:=false) -> Texture2D:
	if not concealed and HERO_IMAGES.has(task.get("hero","")):return HERO_IMAGES[task.hero]
	if not concealed and task.has("hero"):return preload("res://scripts/hero_art.gd").head(task.hero)
	if atlas==null:atlas=load("res://assets/ui/achievements/atlas.png")
	var index:=13 if concealed else int(task.get("art",0))
	var cell:=Vector2(atlas.get_width()/4.0,1216.0/4.0)
	var result:=AtlasTexture.new()
	result.atlas=atlas
	result.region=Rect2(Vector2(index%4,index/4)*cell,cell)
	result.filter_clip=true
	return result
