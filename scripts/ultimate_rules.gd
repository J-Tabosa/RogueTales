extends RefCounted
const Rules=preload("res://scripts/combat_rules.gd")
const IDS=["scarlet","ariel","joao","maria","peter","mulan","snow_white","rapunzel","alice","matches"]
static func resource_ready(a:Dictionary) -> bool:return Rules.ready(a)
static func targets(tactics,index:int,requested:=-1) -> Array[int]:return Rules.ult_targets(tactics,index,requested)
static func execute(tactics,index:int,requested:=-1) -> Dictionary:return Rules.ultimate(tactics,index,requested)
static func line_targets(enemies:Array,target:int) -> Array[int]:
	var result:Array[int]=[]
	if target<0:return result
	var y:float=Rules.Layout.home(enemies,target,true).y
	for at in enemies.size():
		if enemies[at].hp>0 and absf(Rules.Layout.home(enemies,at,true).y-y)<.015:result.append(at)
	return result

static func allies(owner,_index:int) -> Array[int]:
	var out:Array[int]=[]
	for at in owner.actors.size():
		if owner.actors[at].hp>0:out.append(at)
	return out
