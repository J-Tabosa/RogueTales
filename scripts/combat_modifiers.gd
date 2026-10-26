extends RefCounted
## Legacy entry points share the consolidated turn-based implementation.
const Gear=preload("res://scripts/equipment.gd")
const Rules=preload("res://scripts/combat_rules.gd")
static func effects(a:Dictionary) -> Dictionary:return Gear.effects(a)
static func amount(a:Dictionary,foe:Dictionary,value:float,ultimate:=false) -> float:return value*Rules.multiplier(a,foe,ultimate)
static func burn(_tactics,a:Dictionary,foe:Dictionary,strength:float,_duration:=2.0,_stack:=false) -> void:
	var e:=Gear.effects(a)
	Rules.status(foe,"poison" if e.get("cold",false) else "burn",a.id,2,strength*(1.0+float(e.get("burn_mult",0))))
static func venom(a:Dictionary,foe:Dictionary,strength:float) -> void:
	Rules.status(foe,"poison",a.id,2,strength*(1.0+float(Gear.effects(a).get("poison_mult",0))),1,4)
static func after(tactics,a:Dictionary,targets:Array,damages:Dictionary,ultimate:=false) -> void:
	var out:=Rules.result(-1 if targets.is_empty() else int(targets[0]),"Equipamento",ultimate)
	out.targets=targets.duplicate()
	for at in targets:Rules.append_hit(out,int(at),{"damage":float(damages.get(at,0)),"critical":false,"evaded":false})
	Rules.item_after(tactics,a,out,ultimate)
	damages.merge(out.target_damage,true)
static func incoming(tactics,a:Dictionary,enemy:Dictionary,hit:Dictionary) -> void:
	var reflection:float=float(Gear.effects(a).get("reflect",0))
	if reflection>0 and float(hit.get("damage",0))>0:
		hit["counter"]=float(hit.get("counter",0))+Rules.hurt(tactics,enemy,0,float(hit.damage)*reflection,0,true,a,0,0,1,false).damage
