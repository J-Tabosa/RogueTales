extends RefCounted
## Compatibility entry points; consolidated mechanics live in combat_rules.gd.
const Rules=preload("res://scripts/combat_rules.gd")
static func attack(tactics,index:int,requested:int) -> Dictionary:
	return Rules.attack(tactics,index,requested)
static func incoming(tactics,index:int,requested:=-1,area:=false) -> Dictionary:
	return Rules.incoming(tactics,index,requested,area)
static func deaths(tactics) -> void:
	Rules.deaths(tactics)
static func heal(_owner,ally:Dictionary,amount:float,_source:="") -> float:
	return Rules.heal(ally,amount).healed
