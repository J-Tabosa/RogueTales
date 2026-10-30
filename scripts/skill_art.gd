extends RefCounted
## Twelve authored square cells per atlas; same hero order in each sheet.
const ORDER=["scarlet","alice","snow_white","ariel","rapunzel","mulan","maria","joao","matches","aladin","peter","puss"]
const SHEETS=[preload("res://assets/ui/skills/basic.png"),preload("res://assets/ui/skills/passive.png"),preload("res://assets/ui/skills/ultimate.png")]
static var cache:Dictionary={}
static func texture(id:String,kind:int) -> Texture2D:
	var index:=ORDER.find(id)
	if index<0 or kind<0 or kind>=SHEETS.size():return null
	var key:="%s:%d"%[id,kind]
	if not cache.has(key):
		var atlas:=AtlasTexture.new()
		atlas.atlas=SHEETS[kind]
		var cell:Vector2=atlas.atlas.get_size()/Vector2(4,3)
		atlas.region=Rect2(Vector2(index%4,index/4)*cell,cell)
		atlas.filter_clip=true
		cache[key]=atlas
	return cache[key]
