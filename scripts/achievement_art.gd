extends RefCounted
static var atlas:Texture2D
static func texture(task:Dictionary,concealed:=false) -> Texture2D:
	if not concealed and task.has("hero"):return preload("res://scripts/hero_art.gd").head(task.hero)
	if atlas==null:atlas=load("res://assets/ui/achievements/atlas.png")
	var index:=13 if concealed else int(task.get("art",0))
	var cell:=Vector2(atlas.get_width()/4.0,1216.0/4.0)
	var result:=AtlasTexture.new()
	result.atlas=atlas
	result.region=Rect2(Vector2(index%4,index/4)*cell,cell)
	result.filter_clip=true
	return result
