extends RefCounted
const Gear=preload("res://scripts/equipment.gd")
static func effects(actor: Dictionary) -> Dictionary:
	return Gear.effects(actor)
static func amount(actor: Dictionary, foe: Dictionary, value: float, ultimate:=false) -> float:
	var e:=effects(actor)
	value*=1.0+float(e.get("ult_mult" if ultimate else "attack_mult",0.0))
	if foe.hp/foe.max_hp<0.35:value*=1.0+float(e.get("execute",0.0))
	return value
static func burn(tactics,actor: Dictionary,foe: Dictionary,strength: float,duration:=5.0,stack:=false) -> void:
	if foe.hp<=0:return
	var e:=effects(actor)
	strength*=1.0+float(e.get("burn_mult",0.0))
	if e.get("cold",false):
		foe.poison=minf(strength*4,foe.poison+strength)
		foe.poison_left=maxf(foe.poison_left,duration)
		foe["poison_owner"]=actor.id
		return
	foe.burn=minf(actor.damage*0.5*(1.0+float(e.get("burn_mult",0.0))),foe.burn+strength) if stack else maxf(foe.burn,strength)
	foe.burn_left=maxf(foe.burn_left,duration)
	foe["burn_owner"]=actor.id
	# One bounded extra hit. This does not call attack/burn and cannot recurse.
	for supporter in tactics.run().actors:
		if supporter.id==actor.id or supporter.hp<=0:continue
		var follow:=float(effects(supporter).get("follow_burn",0.0))
		if follow<=0 or float(supporter.get("burn_follow_ready",0.0))>tactics.elapsed:continue
		supporter["burn_follow_ready"]=tactics.elapsed+2.0
		var hit:Dictionary=tactics.deal(foe,supporter.damage*follow,true,true)
		tactics.notify(supporter.id,"Uma chama chama outra","Ataque extra: %d de dano"%roundi(hit.damage))
static func venom(actor: Dictionary,foe: Dictionary,strength: float) -> void:
	if foe.hp<=0:return
	strength*=1.0+float(effects(actor).get("poison_mult",0.0))
	foe.poison=minf(strength*4,foe.poison+strength)
	foe.poison_left=5.0
	foe["poison_owner"]=actor.id
static func after(tactics,actor: Dictionary,targets: Array,damages: Dictionary,ultimate:=false) -> void:
	var e:=effects(actor)
	var total:=0.0
	for value in damages.values():total+=float(value)
	for at in targets.duplicate():
		if at<0 or at>=tactics.enemies.size():continue
		var foe:Dictionary=tactics.enemies[at]
		if foe.hp<=0:continue
		if float(e.get("fire",0))>0:burn(tactics,actor,foe,actor.damage*float(e.fire))
		if float(e.get("venom",0))>0:venom(actor,foe,actor.damage*float(e.venom))
		if float(e.get("slow",0))>0:foe["item_slow_left"]=maxf(float(foe.get("item_slow_left",0)),float(e.slow))
	if not ultimate and not targets.is_empty() and float(e.get("chain",0))>0:
		for at in tactics.enemies.size():
			if targets.has(at) or tactics.enemies[at].hp<=0:continue
			var hit:Dictionary=tactics.deal(tactics.enemies[at],actor.damage*float(e.chain),true,true)
			damages[at]=float(damages.get(at,0.0))+float(hit.damage)
			tactics.notify(actor.id,"Reverberação","%d de dano em outro inimigo"%roundi(hit.damage))
			break
	if not ultimate:
		actor.energy=0.0 if actor.id=="alice" else minf(100,actor.energy+float(e.get("mana_hit",0)))
		actor.hp=minf(actor.max_hp,actor.hp+total*float(e.get("drain",0)))
		if float(e.get("shield_on_hit",0))>0:
			var weakest:Dictionary={}
			for ally in tactics.run().actors:
				if ally.hp>0 and (weakest.is_empty() or ally.hp/ally.max_hp<weakest.hp/weakest.max_hp):weakest=ally
			if not weakest.is_empty():weakest.shield=minf(weakest.max_hp,weakest.shield+weakest.max_hp*float(e.shield_on_hit))
	else:
		actor.shield=minf(actor.max_hp,actor.shield+actor.max_hp*float(e.get("ult_shield",0)))
		for ally in tactics.run().actors:
			if ally.hp<=0:continue
			ally.shield=minf(ally.max_hp,ally.shield+ally.max_hp*float(e.get("ult_group_shield",0)))
			if e.get("cleanse",false):
				for key in ["hostile_burn","hostile_poison","hostile_dot_left"]:ally[key]=0.0
				ally["sealed"]=false
static func incoming(tactics,actor: Dictionary,enemy: Dictionary,hit: Dictionary) -> void:
	var e:=effects(actor)
	var counter:=float(hit.get("counter",0))
	var extra:=counter*float(e.get("counter_mult",0))+float(hit.damage)*float(e.get("reflect",0))
	if extra>0 and enemy.hp>0:
		var result:Dictionary=tactics.deal(enemy,extra,true,true)
		hit["counter"]=counter+float(result.damage)
		tactics.notify(actor.id,"Retaliação","%d de dano extra"%roundi(result.damage))
