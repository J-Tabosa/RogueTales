extends RefCounted
## Equipment hooks. Runtime load avoids a gear/bonus/combat preload cycle.
const Gear=preload("res://scripts/equipment.gd")

static func rules():return load("res://scripts/combat_rules.gd")
static func fx(a:Dictionary) -> Dictionary:return Gear.effects(a)
static func once(a:Dictionary,key:String) -> bool:
	var used:Dictionary=a.get("gear_used",{})
	if used.get(key,false):return false
	used[key]=true
	a.gear_used=used
	return true

static func start_combat(tactics) -> void:
	var r=rules()
	for a in tactics.run().actors:
		a["gear_used"]={}
		a["gear_first_turn"]=true
		a["gear_first_ult"]=true
		a["gear_refunded"]=false
		a["gear_thorns_serial"]=-1
		a["gear_initiative"]=[]
		a["gear_echo_pending"]=0.0
		a["gear_opening"]=true
		a["gear_hurt"]=false
		a["gear_evade_attacks"]=false
		a["gear_crit_ready"]=false
		a["gear_hunter_mark"]=""
		a["gear_time_used"]=false
		a["gear_copied_defenses"]=[]
		if fx(a).get("copy_defenses",false):
			var p:=0.0
			var m:=0.0
			for foe in tactics.enemies:
				p=maxf(p,r.defense(foe,false))
				m=maxf(m,r.defense(foe,true))
			a.gear_copied_defenses=[p,m]
	refresh_banner(tactics)

static func refresh_banner(tactics) -> void:
	for a in tactics.run().actors:
		a["gear_banner"]=tactics.run().actors.any(func(b):return b.hp>0 and b.row==a.row and fx(b).get("row_banner",false))

static func expire_source(tactics,a:Dictionary) -> void:
	for unit in tactics.run().actors+tactics.enemies:
		unit["gear_initiative"]=unit.get("gear_initiative",[]).filter(func(b):return b.owner!=a.id)
		unit.statuses=unit.get("statuses",[]).filter(func(s):return s.get("expires_owner","")!=a.id)
		rules().status_fields(unit)

static func start_turn(tactics,a:Dictionary) -> int:
	var r=rules()
	expire_source(tactics,a)
	refresh_banner(tactics)
	var e:=fx(a)
	var extra:=0
	if a.get("gear_hurt",false) and e.get("hurt_regen",0)>0:r.heal(a,a.max_hp*float(e.hurt_regen),a)
	a["gear_hurt"]=false
	a["gear_used"]={}
	a["gear_basic_crits"]=0
	if a.get("gear_first_turn",true):extra+=int(e.get("opening_attack",0))
	if a.get("gear_opening",false) and e.get("opening_quill",false):extra+=1
	if a.get("gear_evade_attacks",false):extra+=1+mini(4,int(floor(r.Bonuses.evasion(a)*100/20+.0001)))
	a["gear_evade_attacks"]=false
	a["gear_first_turn"]=false
	return extra

static func on_evade(tactics,a:Dictionary) -> void:
	var e:=fx(a)
	if e.get("evade_heal",0)>0 and once(a,"evade_heal"):rules().heal(a,a.max_hp*float(e.evade_heal),a)
	if e.get("evade_crit",false) and once(a,"evade_crit"):a["gear_crit_ready"]=true
	if e.get("evade_attacks",false) and once(a,"evade_attacks"):a["gear_evade_attacks"]=true

static func shield_added(a:Dictionary,amount:float,source:Dictionary,allow_overheal:=false) -> void:
	var e:=fx(source)
	if e.get("shield_heal",0)>0:rules().heal(a,amount*float(e.shield_heal),source,false)
	if e.get("shield_initiative",0)>0 and a.get("gear_was_unshielded",false):
		var buffs:Array=a.get("gear_initiative",[]).filter(func(b):return b.owner!=source.get("id",""))
		buffs.append({"owner":source.get("id",""),"value":float(e.shield_initiative)})
		a["gear_initiative"]=buffs

static func shield_broken(tactics,a:Dictionary,part:Dictionary) -> void:
	var source:Dictionary=rules().actor(tactics.run(),str(part.get("owner","")))
	if source.is_empty() or source.hp<=0:return
	var e:=fx(source)
	if e.get("broken_heal",0)>0 and once(source,"broken_"+str(a.id)):
		rules().heal(a,a.max_hp*float(e.broken_heal),source)
		rules().mana(source,float(e.get("broken_mana",0)))

static func take_buff(tactics,a:Dictionary,foe:Dictionary,steal:=false,include_shield:=true) -> bool:
	var r=rules()
	# Explicit temporary positive statuses only; never intrinsic boss mechanics.
	for s in foe.get("positive_effects",[]):
		if int(s.get("turns",0))<=0 or not s.get("dispellable",true):continue
		foe.positive_effects.erase(s)
		if steal:
			if not a.has("positive_effects"):a.positive_effects=[]
			a.positive_effects.append(s.duplicate(true))
		return true
	if not include_shield:return false
	r.sync_shield(foe)
	for part in foe.get("shield_parts",[]):
		if float(part.value)<=0 or int(part.get("turns",0))<0:continue
		foe.shield_parts.erase(part)
		foe.shield=maxf(0,float(foe.shield)-float(part.value))
		if steal:
			r.sync_shield(a)
			var copied:Dictionary=part.duplicate(true)
			copied["source"]="stolen"
			copied["owner"]=str(a.id)
			copied["magic_bonus"]=0.0
			a.shield_parts.append(copied)
			a.shield+=float(copied.value)
		r.status_fields(a)
		r.status_fields(foe)
		return true
	return false

static func before_basic(tactics,a:Dictionary,foe:Dictionary,first:bool) -> void:
	if not first:return
	var e:=fx(a)
	var r=rules()
	if e.get("dispel",false) and not take_buff(tactics,a,foe,false,false):
		r.sync_shield(foe)
		var remove:float=float(foe.shield)*.5
		for p in foe.shield_parts:
			var n:=minf(remove,float(p.value))
			p.value-=n
			remove-=n
		foe.shield_parts=foe.shield_parts.filter(func(p):return float(p.value)>0)
		foe.shield=foe.shield_parts.reduce(func(n,p):return n+float(p.value),0.0)
		r.status_fields(foe)
	if e.get("steal_buff",false):take_buff(tactics,a,foe,true)

static func basic_strike(tactics,a:Dictionary,foe:Dictionary,p:float,m:float,real:float,first:bool,coefficient:=1.0) -> Dictionary:
	var r=rules()
	var e:=fx(a)
	var extra_magic:=0.0
	if first:p+=r.power(a,false)*float(e.get("first_physical",0))
	if e.get("target_hp",0)>0:
		var extra:float=foe.max_hp*float(e.target_hp)
		if foe.get("boss",false):extra=minf(extra,r.power(a,false)*1.5)
		p+=extra*coefficient
	if e.get("status_magic",0)>0 and (r.has_status(foe,"burn") or r.has_status(foe,"poison")):
		extra_magic=r.power(a,true)*float(e.status_magic)*coefficient
		m+=extra_magic
	var scale:=1.0
	if e.get("solo_basic",0)>0 and tactics.enemies.filter(func(f):return f.hp>0).size()==1:scale*=1+float(e.solo_basic)
	a["gear_force_crit"]=a.get("gear_crit_ready",false)
	a["gear_crit_ready"]=false
	var hit:Dictionary=r.strike(tactics,a,foe,p*scale,m*scale,real*scale)
	a["gear_force_crit"]=false
	if not hit.evaded and extra_magic>0:
		var actual:float=float(hit.get("magic_damage",0))*extra_magic/maxf(.001,m)
		r.heal(a,actual*.3,a)
	return hit

static func on_basic_hit(tactics,a:Dictionary,foe:Dictionary,hit:Dictionary,out:Dictionary,first:bool) -> void:
	var r=rules()
	var e:=fx(a)
	if e.get("apple_poison",0)>0:r.status(foe,"poison","item_"+str(a.id),2,r.power(a,true)*float(e.apple_poison),1,3,false,tactics)
	if e.get("hunter_mark",false):
		var marked:bool=tactics.enemies.any(func(f):return f.hp>0 and f.id==a.get("gear_hunter_mark",""))
		if not marked:a["gear_hunter_mark"]=foe.id
	if e.get("physical_leech",0)>0:
		var amount:float=float(hit.get("physical_damage",0))*float(e.physical_leech)*(2 if float(hit.get("target_hp_ratio",1))<.3 else 1)
		out.healed+=r.heal(a,amount,a).healed
	if e.get("sugar_attack",false) and hit.critical:
		a["gear_basic_crits"]=int(a.get("gear_basic_crits",0))+1
		if a.gear_basic_crits>=2 and once(a,"sugar_attack"):a["bonus_attacks"]=int(a.get("bonus_attacks",0))+1
	if first and e.get("heart_scepter",false):
		for kind in ["antiheal","shield_break"]:
			if r.status(foe,kind,"item_"+str(a.id),-1,0,1,1,false,tactics):
				for s in foe.statuses:
					if s.source=="item_"+str(a.id) and s.kind==kind:s["expires_owner"]=a.id
	if first and e.get("ice_heart",false):
		r.status(foe,"hangover",a.id,1,0,1,1,false,tactics)
		if r.has_status(foe,"burn") and r.status(foe,"bubble",a.id,1,0,1,1,false,tactics):
			for s in foe.statuses:
				if s.kind=="bubble" and s.source==a.id:s["chance"]=.5
	cauldron(tactics,a,foe,out)

static func cauldron(tactics,a:Dictionary,foe:Dictionary,out:Dictionary) -> void:
	var r=rules()
	if fx(a).get("cauldron",false) and not a.get("gear_used",{}).get("cauldron",false) and take_buff(tactics,a,foe):
		once(a,"cauldron")
		r.mana(a,10)
		out.healed+=r.heal(a,a.max_hp*.1,a).healed

static func after_basic(tactics,a:Dictionary,out:Dictionary,first:bool) -> void:
	var r=rules()
	var e:=fx(a)
	var main:int=int(out.target)
	var visited:Array=out.targets.duplicate()
	var spread:Array=[]
	for n in int(e.get("spread_40",0)):spread.append(.4)
	for n in int(e.get("spread_50",0)):spread.append(.5)
	for scale in spread:
		var at:=-1
		for candidate in r.nearest(tactics,main,tactics.enemies.size()):
			if not visited.has(candidate):at=candidate;break
		if at<0:break
		visited.append(at)
		var foe:Dictionary=tactics.enemies[at]
		var components:Array=a.get("gear_attack_components",[0.0,0.0,0.0])
		var hit:Dictionary=basic_strike(tactics,a,foe,float(components[0])*float(scale),float(components[1])*float(scale),float(components[2])*float(scale),false,float(scale))
		r.append_hit(out,at,hit)
		if not hit.evaded:
			r.on_basic_hit(tactics,a,foe,out)
			on_basic_hit(tactics,a,foe,hit,out,false)
			if a.id=="alice":
				var suit_out:Dictionary=r.result(at,"Naipe")
				suit_out.damage=hit.damage
				r.suit_effect(a,int(a.get("previous_suit",0)),suit_out,tactics.run())
				out.healed+=suit_out.healed
	if first and e.get("echo",0)>0:a["gear_echo_pending"]=float(e.echo)

static func after_ult(a:Dictionary) -> void:
	var e:=fx(a)
	var r=rules()
	if e.get("ult_mana",0)>0 and once(a,"ult_mana"):r.mana(a,float(e.ult_mana))
	if e.get("refund_ult",false) and not a.get("gear_refunded",false):
		a["gear_refunded"]=true
		r.mana(a,r.cost(a))
	a["gear_first_ult"]=false

static func on_damage(tactics,a:Dictionary,source:Dictionary,hit:Dictionary,direct:bool) -> void:
	if float(hit.damage)>0:a["gear_hurt"]=true
	if not direct or hit.evaded or source.is_empty() or float(source.get("hp",0))<=0:return
	var r=rules()
	var e:=fx(a)
	if e.get("magic_reflect",0)>0 and float(hit.get("magic_damage",0))>0:
		r.hurt(tactics,source,0,float(hit.magic_damage)*float(e.magic_reflect),0,true,a,0,0,1,false)
	if e.get("thorns",0)>0:
		var serial:int=int(tactics.get("enemy_action_serial"))
		if int(a.get("gear_thorns_serial",-1))!=serial:
			a["gear_thorns_serial"]=serial
			r.hurt(tactics,source,a.max_hp*float(e.thorns),0,0,true,a,0,0,1,false)

static func protect_fatal(tactics,a:Dictionary) -> void:
	var e:=fx(a)
	if a.hp<=0 and e.get("fatal_shield",0)>0 and int(a.get("gear_fatal_stage",-1))!=int(tactics.run().stage):
		a["gear_fatal_stage"]=int(tactics.run().stage)
		a.hp=1.0
		rules().shield(a,a.max_hp*float(e.fatal_shield),a,"fatal")
		for part in a.shield_parts:
			if part.source=="fatal":part.turns=1
		tactics.notify(a.id,"Coração do Lobo Imortal","1 PV e escudo até a próxima vez")
