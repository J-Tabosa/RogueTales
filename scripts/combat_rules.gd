extends RefCounted
## Turn-based combat. Floating-point PV/mana are intentional; only presentation rounds.
const Data=preload("res://scripts/roster_data.gd")
const Gear=preload("res://scripts/equipment.gd")
const Layout=preload("res://scripts/formation_layout.gd")
const STATE_KEYS=["shadows","shadow_boost","shadow_thieves","lost_shadows","suit","previous_suit","card_charge","mark_id","wishes","wish_extra","resurrections","gato_stage","alice_stage","immortal_turns","escape_evasion","shield_parts","shield","statuses","own_turn","boon_feats","energy","mana","guardian_spirits"]

static func boon(a:Dictionary,n:int) -> bool:
	return int(a.get("blessing_index",-1))==n

static func actor(owner,id:String) -> Dictionary:
	for a in owner.actors:
		if a.id==id:return a
	return {}

static func power(a:Dictionary,magic:bool) -> float:
	var value:float=float(a.get("magic_damage" if magic else "physical_damage",a.get("damage",0)))
	value*=float(a.get("damage",1))/maxf(.001,float(a.get("legacy_damage_base",a.get("damage",1))))
	if a.get("id","")=="puss" and not magic:value*=1.0+clampf(1.0-float(a.hp)/maxf(1,a.max_hp),0,1)
	if a.get("id","")=="snow_white" and not magic and boon(a,1):value*=1.0+defense(a,false)*.005
	if a.get("id","")=="aladin" and magic:value*=1.0+wishes_left(a)*(.20 if boon(a,0) else .10)
	if has_status(a,"curse"):value*=.8
	return value

static func defense(a:Dictionary,magic:bool) -> float:
	var value:float=float(a.get("magic_defense",0)) if magic else float(a.get("physical_defense",0))+float(a.get("armor",0))-float(Data.BASE.get(str(a.get("id","")),{}).get("physical_defense",0))
	if magic:
		for part in a.get("shield_parts",[]):
			if float(part.value)>0:value+=float(part.get("magic_bonus",0))
	if has_status(a,"curse"):value*=.8
	return maxf(0,value)

static func cost(a:Dictionary) -> float:
	return maxf(0,float(a.get("mana_max",100))-(30 if a.id=="scarlet" and boon(a,0) else 0))

static func resource(a:Dictionary) -> String:
	if a.id=="alice":return "%d / 4 cartas"%int(a.get("card_charge",0))
	if a.id=="aladin":return "%d desejos"%wishes_left(a)
	return "%s / %s mana"%[str(snappedf(float(a.get("energy",0)),.1)),str(cost(a))]

static func ready(a:Dictionary) -> bool:
	if a.id=="aladin":return false
	if a.id=="alice":return int(a.get("card_charge",0))>=4
	return float(a.get("energy",0))>=cost(a)

static func mana(a:Dictionary,amount:float) -> void:
	if a.id in ["alice","aladin"]:a.energy=0.0
	else:a.energy=maxf(0,float(a.get("energy",0))+amount)

static func has_status(a:Dictionary,kind:String) -> bool:
	for s in a.get("statuses",[]):
		if s.kind==kind and int(s.get("turns",0))!=0:return true
	return false

static func immune(a:Dictionary,kind:String) -> bool:
	if a.get("id","")=="aladin" and boon(a,1) and wishes_left(a)>0:return true
	if a.get("id","")=="snow_white" and boon(a,2) and kind in ["burn","poison","bleed"]:return true
	if a.get("immune_all",false) or a.get("immune_"+kind,false):return true
	if a.get("immune_control",false) and kind in ["bubble","hangover","sleep"]:return true
	return a.get("immunities",[]).has(kind)

static func status(a:Dictionary,kind:String,source:String,turns:int,potency:=0.0,stacks:=1,cap:=1,permanent:=false,tactics=null) -> bool:
	if a.hp<=0 or immune(a,kind):return false
	if not a.has("statuses"):a.statuses=[]
	for s in a.statuses:
		# Controls and bleed never stack. Damage effects retain ownership per source.
		if s.kind==kind and (s.source==source or kind in ["bubble","hangover","bleed","sleep"]):
			s.turns=turns
			s["applied_turn"]=int(a.get("own_turn",0))
			s.potency=potency
			s.stacks=mini(cap,int(s.stacks)+stacks) if cap>1 else 1
			s.permanent=bool(s.get("permanent",false)) or permanent
			status_fields(a)
			record_condition(tactics,source,kind)
			return true
	a.statuses.append({"kind":kind,"source":source,"turns":turns,"potency":potency,"stacks":mini(stacks,cap),"permanent":permanent,"applied_turn":int(a.get("own_turn",0))})
	status_fields(a)
	record_condition(tactics,source,kind)
	return true

static func record_condition(tactics,source:String,kind:String) -> void:
	if tactics==null or kind not in ["burn","poison","bleed","curse","sleep","bubble","hangover","antiheal","shield_break"]:return
	var a:=actor(tactics.run(),source.trim_prefix("item_"))
	if a.is_empty() or a.id!="alice":return
	var round_id:int=int(tactics.round_number)
	if int(a.get("condition_round",-1))!=round_id:
		a.condition_round=round_id
		a.round_conditions=[]
	if not a.round_conditions.has(kind):a.round_conditions.append(kind)
	if a.round_conditions.size()>=2 and not a.get("boon_feats",{}).get("two_conditions",false):
		feat(a,"two_conditions")
		tactics.notify(a.id,"Chapeleira Maluca desbloqueada","Aplicou duas condições diferentes na mesma rodada","achievement")

static func status_fields(a:Dictionary) -> void:
	for k in ["burn","poison","bleed","burn_left","poison_left","bleed_left","curse_left","sleep_turns","bubble_turns","hangover_turns"]:a[k]=0.0
	for s in a.get("statuses",[]):
		var duration:float=99.0 if int(s.turns)<0 else float(s.turns)
		if s.kind in ["burn","poison","bleed"]:
			a[s.kind]+=float(s.potency)*int(s.stacks)
			a[s.kind+"_left"]=maxf(a[s.kind+"_left"],duration)
		elif s.kind=="curse":a.curse_left=maxf(a.curse_left,duration)
		elif s.kind in ["sleep","bubble","hangover"]:a[s.kind+"_turns"]=maxf(a[s.kind+"_turns"],duration)
	a["hair_guard"]=a.get("shield_parts",[]).any(func(p):return p.get("source","")=="silk" and float(p.value)>0)

static func cleanse(a:Dictionary,one:=false) -> void:
	var removed:=false
	var keep:Array=[]
	for s in a.get("statuses",[]):
		if s.get("permanent",false) or (one and removed):keep.append(s)
		else:removed=true
	a.statuses=keep
	for k in ["hostile_burn","hostile_poison","hostile_dot_left","hindered_rounds"]:a[k]=0
	a["sealed"]=false
	status_fields(a)

static func sync_shield(a:Dictionary) -> void:
	if not a.has("shield_parts"):a.shield_parts=[]
	var tracked:=0.0
	for p in a.shield_parts:tracked+=maxf(0,float(p.value))
	# Legacy/item sources can still add shield through their shared scalar.
	var extra:float=float(a.get("shield",0))-tracked
	if extra>.001:a.shield_parts.append({"source":"other","owner":"","value":extra,"turns":5,"magic_bonus":0.0})
	a.shield=maxf(tracked, float(a.get("shield",0)))

static func shield(a:Dictionary,amount:float,source:Dictionary,kind:="other",magic_bonus:=0.0) -> float:
	if a.hp<=0 or amount<=0:return 0
	sync_shield(a)
	if has_status(a,"shield_break") or has_status(a,"curse") and a.get("curse_break",false):amount*=.5
	var sum:=0.0
	for p in a.shield_parts:
		if p.source==kind:sum+=float(p.value)
	if kind in ["silk","foam"]:amount=minf(amount,maxf(0,float(a.max_hp)*(.30 if kind=="silk" else .15)-sum))
	if amount<=0:return 0
	a.shield_parts.append({"source":kind,"owner":str(source.get("id","")),"value":amount,"turns":-1 if kind=="silk" and boon(source,2) else 5,"magic_bonus":magic_bonus})
	a.shield+=amount
	if kind=="silk" and float(a.shield)>=200:feat(source,"shield_200")
	status_fields(a)
	return amount

static func consume_shield(tactics,a:Dictionary,raw:float,bonus:float,hostile:bool) -> Dictionary:
	sync_shield(a)
	var before:float=a.shield
	var silk_before:=false
	for p in a.shield_parts:
		if p.source=="silk" and float(p.value)>0:silk_before=true
	# Exclusive shield damage is spent first and cannot spill into HP.
	var exclusive:=minf(before,raw*maxf(0,bonus))
	var normal:=minf(maxf(0,before-exclusive),raw)
	var left:=exclusive+normal
	for p in a.shield_parts:
		var absorbed:=minf(float(p.value),left)
		p.value-=absorbed
		left-=absorbed
		if p.value<=0 and absorbed>0 and p.source=="silk" and hostile:
			var silk:=actor(tactics.run(),str(p.owner))
			if not silk.is_empty() and boon(silk,1):
				var turn:int=int(silk.get("own_turn",0))
				if int(a.get("silk_break_turn",-1))!=turn:
					a["silk_break_turn"]=turn
					mana(silk,10)
					tactics.notify(silk.id,"Fios Resistentes","+10 mana")
	a.shield_parts=a.shield_parts.filter(func(p):return float(p.value)>.0001)
	a.shield=maxf(0,before-exclusive-normal)
	status_fields(a)
	return {"absorbed":exclusive+normal,"hp_damage":raw-normal,"broken":before>0 and a.shield<=.0001,"before":before,"silk_before":silk_before}

static func hurt(tactics,a:Dictionary,physical:float,magic:float,real:=0.0,certain:=false,source:Dictionary={},shield_bonus:=0.0,ignore_defense:=0.0,reduction:=1.0,direct:=true) -> Dictionary:
	var empty:={"damage":0.0,"absorbed":0.0,"evaded":false,"critical":false,"guarded":false,"shield_broken":false}
	if a.hp<=0 or physical+magic+real<=0:return empty
	var evade:float=1.0 if a.get("escape_evasion",false) else minf(.8,maxf(0,float(a.get("evasion",0))))
	if not certain and tactics.run().rng.randf()<evade:
		empty.evaded=true
		if a.get("id","")=="peter" and direct:
			a.shadows=mini(3,int(a.get("shadows",0))+1)
			tactics.notify(a.id,"Sombras do Nunca","Esquiva: +1 sombra")
		return empty
	var raw:float=physical*100/(100+defense(a,false)*(1-ignore_defense))+magic*100/(100+defense(a,true))+real
	if a.get("guarded_by_banner",false):raw*=.6
	sync_shield(a)
	if a.shield_parts.any(func(p):return p.source=="silk" and float(p.value)>0):raw*=.9
	raw=maxf(1,raw*reduction)
	var hostile:bool=not source.is_empty() and str(source.get("id","")).begins_with("enemy_") or str(source.get("id","")).begins_with("secret_")
	var predicted_absorbed:=minf(raw,maxf(0,float(a.shield)-minf(float(a.shield),raw*shield_bonus)))
	# Alice's replacement is resolved before the fatal hit is applied.
	if direct and raw-predicted_absorbed>=float(a.hp) and a.get("id","")=="alice" and boon(a,2) and int(a.get("alice_stage",-1))!=int(tactics.run().stage):
		for ally in tactics.run().actors:
			if ally.id!=a.id and ally.hp>0 and ally.row=="back":
				a.alice_stage=tactics.run().stage
				a.escape_evasion=true
				var row:String=a.row
				a.row=ally.row
				ally.row=row
				var redirected:=hurt(tactics,ally,physical,magic,real,certain,source,shield_bonus,ignore_defense,reduction,true)
				redirected["redirect_id"]=ally.id
				tactics.notify(a.id,"Escapada Mágica","Trocou com "+str(TaleCatalog.HEROES[ally.id].name))
				return redirected
	var defended:=consume_shield(tactics,a,raw,shield_bonus,hostile)
	var damage:float=minf(float(a.hp),defended.hp_damage)
	if a.get("immortal_turns",0)>0:damage=minf(damage,maxf(0,float(a.hp)-1))
	a.hp=maxf(0,float(a.hp)-damage)
	if tactics.run().actor_ids().has(str(a.get("id",""))):tactics.damage_received+=damage
	empty.merge({"damage":damage,"absorbed":defended.absorbed,"shield_broken":defended.broken,"shield_before":defended.before,"silk_before":defended.silk_before},true)
	if not source.is_empty():a["last_source"]=source.id
	if direct and a.get("id","")=="peter":
		if int(a.get("shadows",0))>0:
			a.shadows-=1
			a.lost_shadows=int(a.get("lost_shadows",0))+1
			if not source.is_empty():
				if not a.has("shadow_thieves"):a.shadow_thieves={}
				a.shadow_thieves[source.id]=int(tactics.get("round_number"))
			if boon(a,1):cleanse(a,true)
	survive(tactics,a)
	return empty

static func survive(tactics,a:Dictionary) -> void:
	if a.get("id","")=="puss":
		if a.hp>0 and a.hp<=a.max_hp*.05:a["low_life"]=true
		if a.hp<=0 and boon(a,1) and int(a.get("gato_stage",-1))!=int(tactics.run().stage):
			a.hp=1.0
			a.gato_stage=tactics.run().stage
			a.immortal_turns=1
			tactics.notify(a.id,"Ainda Tenho Garras","Sobrevive com 1 PV até a próxima vez")
		if a.hp<=0 and boon(a,3) and int(a.get("resurrections",0))<9:
			var n:int=int(a.get("resurrections",0))
			a.resurrections=n+1
			if tactics.run().rng.randf()<1.0-.1*n:
				a.hp=a.max_hp*.2
				a.statuses=[]
				status_fields(a)
				tactics.notify(a.id,"O Gato de Botas","Retorno %d / 9"%(n+1))
	if a.hp<=0 and a.get("id","")==tactics.run().leader and tactics.run().blessing=="mercy" and not tactics.run().mercy_used:
		tactics.run().mercy_used=true
		a.hp=a.max_hp*.35

static func heal(a:Dictionary,amount:float) -> Dictionary:
	if a.hp<=0:return {"healed":0.0,"overflow":0.0}
	if has_status(a,"bleed") or has_status(a,"antiheal"):amount*=.5
	var actual:=minf(amount,maxf(0,float(a.max_hp)-a.hp))
	a.hp+=actual
	return {"healed":actual,"overflow":maxf(0,amount-actual)}

static func feat(a:Dictionary,key:String) -> void:
	if not a.has("boon_feats"):a.boon_feats={}
	a.boon_feats[key]=true

static func wishes_left(a:Dictionary) -> int:
	var used:Array=a.get("wishes",[])
	return maxi(0,3-used.size())+(1 if boon(a,2) and not a.get("wish_extra",false) else 0)

static func wish(owner,id:String) -> Dictionary:
	var a:=actor(owner,"aladin")
	if a.is_empty() or id not in ["wealth","life","death"]:return {}
	var used:Array=a.get("wishes",[]).duplicate()
	var repeat:bool=used.has(id)
	if repeat and (not boon(a,2) or a.get("wish_extra",false)):return {}
	if id=="death" and (owner.tactics==null or owner.enemy_hp<=0 or not owner.interlude.is_empty()):return {}
	var result:={"wish":id,"damage":0.0,"gold":0,"revived":[],"targets":[],"target_damage":{},"ultimate":true,"message":"3 Desejos","critical":false,"evaded":false,"target":-1}
	var magic:=power(a,true) # Snapshot before consuming the wish.
	if id=="wealth":
		result.gold=200*(int(owner.stage)+1)
		owner.run_gold+=result.gold
	elif id=="life":
		for ally in owner.actors:
			if ally.hp<=0:
				ally.hp=ally.max_hp
				result.revived.append(ally.id)
	elif id=="death":
		for at in owner.tactics.enemies.size():
			var foe:Dictionary=owner.tactics.enemies[at]
			if foe.hp<=0:continue
			var dealt:=0.0
			if foe.get("boss",false) and not foe.get("secondary_boss",false):
				dealt=hurt(owner.tactics,foe,0,magic*10,0,true,a).damage
			else:
				dealt=foe.hp
				foe.hp=0.0
				foe["last_source"]=a.id
			result.targets.append(at)
			result.target_damage[at]=dealt
			result.damage+=dealt
		deaths(owner.tactics)
		owner.tactics.sync_totals()
	if repeat:a.wish_extra=true
	else:used.append(id)
	a.wishes=used
	return result

static func start_combat(tactics) -> void:
	for a in tactics.run().actors:
		a["condition_round"]=-1
		a["round_conditions"]=[]
		a["lost_shadows"]=0
		a["shadow_thieves"]={}
		a["counter_used"]=0
		a["intercept_used"]=false
		a["intercept_fail"]=0
		a["joke_used"]=false
		a["combo_bonus"]=0.0
		a["guardian_spirits"]=0
		# Only Silk's own shields persist; remaining lifetimes are retained.
		a.shield_parts=a.get("shield_parts",[]).filter(func(p):return p.get("source","")=="silk")
		a.shield=0.0
		for p in a.shield_parts:a.shield+=float(p.value)
		a.statuses=[]
		if a.id=="peter" and boon(a,0):a.shadows=maxi(1,int(a.get("shadows",0)))
		var e:=Gear.effects(a)
		if float(e.get("shield_start",0))>0:shield(a,a.max_hp*float(e.shield_start),a)
		status_fields(a)
	for foe in tactics.enemies:
		foe["initiative"]=50.0
		foe["attacks"]=1
		foe["magic_defense"]=float(foe.get("armor",0)) if foe.get("class","")=="vanguard" else 0.0
		foe["statuses"]=[]
		foe["shield_parts"]=[]
		foe["own_turn"]=0
		foe["category"]=category(foe)

static func category(foe:Dictionary) -> String:
	if foe.has("category"):return str(foe.category)
	var n:String=str(foe.get("name","")).to_lower()
	if "bruxa" in n or "feiticeir" in n:return "witch"
	if "lobo" in n or "besta" in n or "fera" in n:return "beast"
	return "other"

static func effective_initiative(a:Dictionary) -> float:
	return clampf(float(a.get("initiative",50))-(20 if has_status(a,"hangover") else 0),0,100)

static func start_turn(tactics,a:Dictionary) -> Dictionary:
	a.own_turn=int(a.get("own_turn",0))+1
	a["immortal_turns"]=0
	a["escape_evasion"]=false
	a["shadow_boost"]=false
	a["counter_used"]=0
	a["intercept_used"]=false
	a["joke_used"]=false
	a["combo_bonus"]=0.0
	a["turn_kills"]=[]
	a["basic_in_turn"]=0
	sync_shield(a)
	for p in a.shield_parts:
		if int(p.turns)>0:p.turns-=1
	a.shield_parts=a.shield_parts.filter(func(p):return int(p.turns)!=0)
	a.shield=0.0
	for p in a.shield_parts:a.shield+=float(p.value)
	var attacks:int=maxi(1,int(a.get("attacks",1)))
	if a.get("id","")=="matches" and boon(a,0):attacks+=1
	if a.get("id","")=="aladin" and boon(a,3) and wishes_left(a)==0:attacks+=2
	if a.get("id","")=="ariel":
		attacks+=int(a.get("next_attacks",0))
		a.next_attacks=0
	var skip:=false
	for s in a.get("statuses",[]):
		if s.kind=="curse" and tactics.run().rng.randf()<.25:
			s.turns=0
			for attached in a.statuses:
				if attached.source==s.source and attached.get("requires_curse",false):attached.turns=0
		if s.kind=="bubble":attacks=maxi(0,attacks-1)
		if s.kind=="sleep" and tactics.run().rng.randf()<.5:skip=true
		if s.kind in ["burn","poison","bleed"] and a.hp>0:
			var source:=actor(tactics.run(),str(s.source))
			if source.is_empty():source={"id":str(s.source)}
			var hit:=hurt(tactics,a,0,0,float(s.potency)*int(s.stacks),true,source,0,0,1,false)
			if a.hp<=0:
				a["dot_death"]=str(s.kind)
				if s.kind=="burn":a["died_burning"]=true
			if hit.damage>0:
				tactics.notify(str(source.id),{"burn":"Queimadura","poison":"Veneno","bleed":"Sangramento"}[s.kind],"%.1f dano no início da vez"%hit.damage,"status")
				var at:int=tactics.enemies.find(a)
				if at>=0:tactics.last_dot_targets.append(at)
	a.statuses=a.get("statuses",[]).filter(func(s):return int(s.turns)!=0)
	status_fields(a)
	deaths(tactics)
	if a.hp<=0:return {"attacks":0,"skip":true}
	if a.get("id","")=="matches" and boon(a,2):
		var strongest:=0.0
		for foe in tactics.enemies:strongest=maxf(strongest,float(foe.get("burn",0)) if foe.hp>0 else 0)
		heal(a,strongest*.5)
	if a.has("mana_turn"):mana(a,float(a.mana_turn))
	return {"attacks":0 if skip else attacks,"skip":skip}

static func critical(tactics,a:Dictionary) -> bool:
	return tactics.run().rng.randf()<clampf(float(a.get("crit",0)),0,1)

static func multiplier(a:Dictionary,foe:Dictionary,ultimate:bool) -> float:
	var e:=Gear.effects(a)
	var v:float=1.0+float(e.get("ult_mult" if ultimate else "attack_mult",0))
	if foe.hp/foe.max_hp<.35:v*=1.0+float(e.get("execute",0))
	if a.id=="scarlet":v*=1.0+.1*clampi(int(foe.get("powder",0)),0,10)
	if a.id=="scarlet" and boon(a,2) and category(foe)=="beast":v*=1.5
	if a.id in ["joao","maria"] and boon(a,1) and category(foe)=="witch":v*=1.5
	if a.id=="puss" and boon(a,2) and foe.get("boss",false):v*=1.25
	return v

static func strike(tactics,a:Dictionary,foe:Dictionary,p:float,m:float,r:=0.0,ult:=false,can_crit:=true,certain:=false) -> Dictionary:
	var crit:bool=can_crit and critical(tactics,a)
	var mult:float=multiplier(a,foe,ult)*(float(a.get("crit_multiplier",2)) if crit else 1.0)
	var hit:=hurt(tactics,foe,p*mult,m*mult,r*mult,certain,a,1.0 if a.id=="snow_white" else 0.0,.5 if a.id=="joao" and boon(a,0) else 0.0)
	hit.critical=crit and not hit.evaded
	if a.id=="snow_white" and boon(a,0) and hit.get("shield_broken",false):shield(a,float(hit.shield_before)*.5,a)
	return hit

static func result(target:int,message:String,ult:=false) -> Dictionary:
	return {"target":target,"targets":[],"target_damage":{},"damage":0.0,"healed":0.0,"evaded":false,"critical":false,"ultimate":ult,"message":message,"strikes":[],"status_targets":[],"ally_targets":[]}

static func append_hit(out:Dictionary,at:int,hit:Dictionary) -> void:
	if not out.targets.has(at):out.targets.append(at)
	out.target_damage[at]=float(out.target_damage.get(at,0))+float(hit.damage)
	out.damage+=float(hit.damage)
	out.critical=out.critical or hit.critical
	out.evaded=hit.evaded if out.strikes.is_empty() else out.evaded and hit.evaded
	out.strikes.append({"target":at,"damage":hit.damage,"critical":hit.critical,"evaded":hit.evaded,"ordinal":out.strikes.size()+1})

static func ignite(a:Dictionary,foe:Dictionary) -> void:
	if immune(foe,"burn"):return
	var coefficient:=1.0
	var cap:=2.0 if boon(a,1) else 1.5
	for s in foe.get("statuses",[]):
		if s.kind=="burn" and s.source==a.id:coefficient=minf(cap,float(s.get("coefficient",1))+.1)
	if status(foe,"burn",a.id,-1 if boon(a,1) else 2,power(a,true)*coefficient,1,1,boon(a,1)):
		for s in foe.statuses:
			if s.kind=="burn" and s.source==a.id:s["coefficient"]=coefficient

static func on_basic_hit(tactics,a:Dictionary,foe:Dictionary,out:Dictionary) -> void:
	mana(a,float(a.get("mana_hit",0))+float(a.get("energy_bonus",0))+float(Gear.effects(a).get("mana_hit",0)))
	if a.id=="scarlet":foe.powder=mini(10,int(foe.get("powder",0))+(2 if boon(a,3) else 1))
	elif a.id=="maria":status(foe,"poison",a.id,2,power(a,true)*.1,1,5 if boon(a,0) else 3)
	elif a.id=="matches":ignite(a,foe)
	elif a.id=="ariel":
		var ally:=weakest(tactics.run())
		if not ally.is_empty():
			var healed:=heal(ally,power(a,true)*.15)
			out.healed+=healed.healed
			if boon(a,0):shield(ally,healed.overflow,a,"foam")
	if float(a.get("leech",0))>0:out.healed+=heal(a,a.leech).healed

static func weakest(owner,exclude:Array=[]) -> Dictionary:
	var candidates:Array=[]
	for a in owner.actors:
		if a.hp>0 and not exclude.has(a.id):candidates.append(a)
	candidates.sort_custom(func(a,b):return a.hp/a.max_hp<b.hp/b.max_hp)
	return {} if candidates.is_empty() else candidates[0]

static func suit_effect(a:Dictionary,suit:int,out:Dictionary,owner,mult:=1.0) -> void:
	var double:=2.0 if boon(a,3) else 1.0
	if suit==0:owner.run_gold+=int(5*double*mult)
	elif suit==1:out.healed+=heal(a,out.damage*.1*double*mult).healed
	elif suit==2:shield(a,a.max_hp*.05*double*mult,a,"cards")

static func nearest(tactics,main:int,limit:int) -> Array[int]:
	var choices:Array[int]=[]
	for at in tactics.enemies.size():
		if at!=main and tactics.enemies[at].hp>0:choices.append(at)
	choices.sort_custom(func(a,b):return Layout.home(tactics.enemies,a,true).distance_squared_to(Layout.home(tactics.enemies,main,true))<Layout.home(tactics.enemies,b,true).distance_squared_to(Layout.home(tactics.enemies,main,true)))
	return choices.slice(0,limit)

static func attack(tactics,index:int,requested:int) -> Dictionary:
	var owner=tactics.run()
	if index<0 or index>=owner.actors.size() or owner.actors[index].hp<=0:return {}
	var a:Dictionary=owner.actors[index]
	var target:int=requested if tactics.eligible(a,tactics.enemies).has(requested) else tactics.target_for(index)
	var out:=result(target,Data.TEXT[a.id].basic)
	if a.id=="rapunzel" and not a.get("sealed",false):
		var selected:Array=[a]
		for n in (2 if boon(a,0) else 1):
			var ally:=weakest(owner,selected.map(func(x):return x.id))
			if not ally.is_empty():selected.append(ally)
		for ally in selected:
			shield(ally,power(a,true),a,"silk")
			out.ally_targets.append(owner.actors.find(ally))
		out["non_attack"]=true
		a.hits+=1
		return out
	if target<0:return {}
	var foe:Dictionary=tactics.enemies[target]
	if a.id=="matches" and boon(a,0) and int(a.get("basic_in_turn",0))==1:
		var other:=nearest(tactics,int(a.get("first_target",target)),1)
		if not other.is_empty():target=other[0];foe=tactics.enemies[target];out.target=target
	if int(a.get("basic_in_turn",0))==0:a.first_target=target
	a.basic_in_turn=int(a.get("basic_in_turn",0))+1
	a.hits+=1
	if a.id=="alice":
		a.card_charge=int(a.get("card_charge",0))+1
	var p:=power(a,false)
	var m:=power(a,true)
	var r:=0.0
	var suit:int=int(a.get("suit",0))%4
	match str(a.id):
		"scarlet","snow_white","joao","mulan","puss":m=0.0
		"alice":
			if suit==3:
				if p>=m:p+=power(a,false)*(.5*(2 if boon(a,3) else 1))
				else:m+=power(a,true)*(.5*(2 if boon(a,3) else 1))
		"matches":p=0.0;m*=.5
		_:p=0.0
	if a.id=="mulan":
		var combo:bool=int(a.hits)%(2 if boon(a,0) else 3)==0
		p*=1.0+(.5 if combo else 0)+float(a.get("combo_bonus",0))
		if combo:owner.unlock_stats.combos+=1
	if a.id=="joao" and a.get("mark_id","")==foe.id:p*=1.2
	if a.id=="aladin" and boon(a,3) and wishes_left(a)==0:r=m;m=0.0
	var hit:=strike(tactics,a,foe,p,m,r)
	append_hit(out,target,hit)
	if not hit.evaded:
		on_basic_hit(tactics,a,foe,out)
		if a.id=="joao":a.mark_id=foe.id
		if a.id=="mulan" and boon(a,3) and hit.critical:a.combo_bonus=minf(.2,float(a.get("combo_bonus",0))+.05)
	if a.id=="scarlet" and boon(a,1):
		for at in nearest(tactics,target,2):
			var secondary:=strike(tactics,a,tactics.enemies[at],power(a,false)*.5,0)
			append_hit(out,at,secondary)
			if not secondary.evaded:on_basic_hit(tactics,a,tactics.enemies[at],out)
	if a.id=="ariel":
		var visited:Array=[target]
		for bounce in (4 if boon(a,1) else 2):
			if owner.rng.randf()>=.5:break
			var next:=-1
			for at in tactics.enemies.size():
				if tactics.enemies[at].hp>0 and not visited.has(at):next=at;break
			if next<0:break
			visited.append(next)
			var bounced:=strike(tactics,a,tactics.enemies[next],0,power(a,true)*(.6 if bounce==0 else .4))
			append_hit(out,next,bounced)
			if not bounced.evaded:on_basic_hit(tactics,a,tactics.enemies[next],out)
		if out.targets.size()>=5:feat(a,"five_hits")
	if a.id=="peter":
		if boon(a,2) and int(a.get("shadow_thieves",{}).get(foe.id,-1))==int(tactics.get("round_number")) and owner.rng.randf()<.5:a.shadows=mini(3,int(a.get("shadows",0))+1)
		for n in int(a.get("shadows",0)):
			if foe.hp<=0:break
			var shadow:=strike(tactics,a,foe,0,power(a,true)*((.25 if boon(a,3) else .15)+(.15 if a.get("shadow_boost",false) else 0)),power(a,true)*(.15 if boon(a,3) else 0))
			append_hit(out,target,shadow)
	if a.id=="puss" and boon(a,0) and a.hp<=a.max_hp*.25:
		var other:=nearest(tactics,target,1)
		var at:int=target if other.is_empty() else other[0]
		if tactics.enemies[at].hp>0:
			var extra:=strike(tactics,a,tactics.enemies[at],power(a,false)*.5*(float(a.get("crit_multiplier",2)) if hit.critical else 1.0),0,0,false,false)
			append_hit(out,at,extra)
			if not extra.evaded:on_basic_hit(tactics,a,tactics.enemies[at],out)
	if a.id=="alice":
		if not hit.evaded:suit_effect(a,suit,out,owner)
		if boon(a,3) and not a.get("joke_used",false) and owner.rng.randf()<.1 and foe.hp>0:
			a.joke_used=true
			var jp:=p
			var jm:=m
			if int(a.get("previous_suit",(suit+3)%4))==3:
				if power(a,false)>=power(a,true):jp+=power(a,false)
				else:jm+=power(a,true)
			var joker:=strike(tactics,a,foe,jp,jm)
			var joker_out:=result(target,"Coringa")
			append_hit(joker_out,target,joker)
			if not joker.evaded:suit_effect(a,int(a.get("previous_suit",(suit+3)%4)),joker_out,owner)
			append_hit(out,target,joker)
			out.healed+=joker_out.healed
		a.previous_suit=suit
		a.suit=(suit+1)%4
	if a.id=="scarlet" and out.targets.size()>=9:feat(a,"nine_targets")
	item_after(tactics,a,out,false)
	deaths(tactics)
	tactics.sync_totals()
	return out

static func column_targets(tactics,target:int,next_column:=false) -> Array[int]:
	var found:Array[int]=[]
	if target<0:return found
	var rows:Array=["front","middle","back"]
	var row:String=tactics.enemies[target].row
	var allowed:Array=[row]
	if next_column and rows.find(row)<2:allowed.append(rows[rows.find(row)+1])
	for at in tactics.enemies.size():
		if tactics.enemies[at].hp>0 and allowed.has(tactics.enemies[at].row):found.append(at)
	return found

static func ult_targets(tactics,index:int,requested:int) -> Array[int]:
	var a:Dictionary=tactics.run().actors[index]
	var target:int=requested if requested>=0 and requested<tactics.enemies.size() and tactics.enemies[requested].hp>0 else tactics.target_for(index)
	if target<0:return []
	if a.id in ["rapunzel","peter","aladin"]:return []
	if a.id in ["snow_white","joao"]:return [target]
	if a.id=="alice":
		var list:Array[int]=[]
		var y:float=Layout.home(tactics.enemies,target,true).y
		for at in tactics.enemies.size():
			if tactics.enemies[at].hp>0 and absf(Layout.home(tactics.enemies,at,true).y-y)<.015:list.append(at)
		return list
	if a.id in ["mulan","puss"]:return column_targets(tactics,target,a.id=="mulan" and boon(a,1))
	var all:Array[int]=[]
	for at in tactics.enemies.size():
		if tactics.enemies[at].hp>0:all.append(at)
	return all

static func ultimate(tactics,index:int,requested:int) -> Dictionary:
	var owner=tactics.run()
	var a:Dictionary=owner.actors[index]
	a.ult_pending=false
	var target:int=requested if requested>=0 and requested<tactics.enemies.size() and tactics.enemies[requested].hp>0 else tactics.target_for(index)
	var out:=result(target,Data.TEXT[a.id].ult,true)
	var targets:=ult_targets(tactics,index,target)
	if a.id=="rapunzel":
		var magic_bonus:=defense(a,true)*.3
		for ally in owner.actors:
			if ally.hp<=0:continue
			if boon(a,3):cleanse(ally)
			shield(ally,power(a,true)*(3 if boon(a,3) else 2),a,"silk",magic_bonus)
			out.ally_targets.append(owner.actors.find(ally))
	elif a.id=="peter":
		a.shadows=3
		a.shadow_boost=true
		out.ally_targets=[index]
	elif a.id=="maria":
		out.targets=targets
		for at in targets:
			if owner.rng.randf()<.75 and status(tactics.enemies[at],"curse",a.id,2):
				out.status_targets.append(at)
				if boon(a,2):
					status(tactics.enemies[at],"antiheal",a.id,2)
					status(tactics.enemies[at],"shield_break",a.id,2)
					for attached in tactics.enemies[at].statuses:
						if attached.source==a.id and attached.kind in ["antiheal","shield_break"]:attached["requires_curse"]=true
	elif a.id=="joao" and target>=0:
		var foe:Dictionary=tactics.enemies[target]
		var count:=6
		var landed:=0
		var n:=0
		while n<count and foe.hp>0:
			var hit:=strike(tactics,a,foe,power(a,false)*(.7 if a.get("mark_id","")==foe.id else .5),0,0,true)
			append_hit(out,target,hit)
			if not hit.evaded:landed+=1
			if n<6 and hit.critical and boon(a,3):count=mini(9,count+1)
			n+=1
		if landed>=6 and boon(a,2):status(foe,"bleed",a.id,-1,power(a,false)*.1)
	else:
		var condition:String=["burn","poison","sleep","curse","antiheal","shield_break"][owner.rng.randi_range(0,5)] if a.id=="alice" and boon(a,1) else ""
		for at in targets:
			var foe:Dictionary=tactics.enemies[at]
			var p:=0.0
			var m:=0.0
			match str(a.id):
				"scarlet":
					p=power(a,false)*(3.0 if boon(a,3) else 1.5)
				"alice":p=power(a,false)*1.2;m=power(a,true)*1.2
				"snow_white":p=power(a,false)*3
				"ariel":m=power(a,true)*1.5
				"mulan","puss":p=power(a,false)*2.5
				"matches":m=power(a,true)*2.5
			var hit:=strike(tactics,a,foe,p,m,0,true)
			if a.id=="scarlet":foe.powder=0
			append_hit(out,at,hit)
			if not hit.evaded:
				if a.id=="matches":ignite(a,foe)
				if a.id=="ariel":
					if owner.rng.randf()<.5:
						if status(foe,"bubble",a.id,1):
							out.status_targets.append(at)
							if boon(a,3):a.next_attacks=mini(3,int(a.get("next_attacks",0))+1)
					elif boon(a,2):status(foe,"hangover",a.id,1)
				if not condition.is_empty():
					var chance:=.75 if condition=="curse" else 1.0
					if owner.rng.randf()<chance:status(foe,condition,a.id,1,power(a,true)*(1.0 if condition=="burn" else .1) if condition in ["burn","poison"] else 0,1,1,false,tactics)
		if a.id=="alice" and boon(a,0):a["bonus_attacks"]=int(a.get("bonus_attacks",0))+1
	item_after(tactics,a,out,true)
	deaths(tactics)
	tactics.BossRules.refresh(tactics)
	tactics.ultimate_serial+=1
	tactics.last_ultimate={"hero":a.id,"serial":tactics.ultimate_serial}
	tactics.sync_totals()
	return out

static func incoming(tactics,enemy_index:int,requested:=-1,area:=false) -> Dictionary:
	var owner=tactics.run()
	if enemy_index<0 or enemy_index>=tactics.enemies.size():return {}
	var foe:Dictionary=tactics.enemies[enemy_index]
	if foe.hp<=0:return {}
	var target:int=requested if requested>=0 and requested<owner.actors.size() and owner.actors[requested].hp>0 else tactics.choose_target(foe,owner.actors)
	if target<0:return {}
	var intercepted:=false
	if not area:
		var victim:Dictionary=owner.actors[target]
		if victim.row=="back" or victim["class"]=="assassin":
			for at in owner.actors.size():
				var snow:Dictionary=owner.actors[at]
				if at==target or snow.hp<=0 or snow.id!="snow_white" or not boon(snow,3) or snow.get("intercept_used",false):continue
				if int(snow.get("intercept_fail",0))>=2 or owner.rng.randf()<.5:
					snow.intercept_fail=0;snow.intercept_used=true
					target=at;intercepted=true
					tactics.notify(snow.id,"A Branca de Neve","Interceptou um ataque")
				else:snow.intercept_fail=int(snow.get("intercept_fail",0))+1
				break
	var a:Dictionary=owner.actors[target]
	var damage:float=float(foe.damage)*( .8 if has_status(foe,"curse") else 1.0)
	var magical:bool=foe["class"]=="mage"
	var hit:=hurt(tactics,a,0 if magical else damage,damage if magical else 0,0,intercepted,foe,0,0,.8 if intercepted else 1.0)
	if hit.has("redirect_id"):
		target=owner.actor_ids().find(hit.redirect_id)
		a=owner.actors[target]
	hit.merge({"target":target,"targets":[target],"target_damage":{target:hit.damage},"enemy":enemy_index,"guarded":intercepted},true)
	if hit.evaded and a.id=="mulan" and int(a.get("counter_used",0))<(3 if boon(a,2) else 1):
		a.counter_used=int(a.get("counter_used",0))+1
		var counter:=strike(tactics,a,foe,power(a,false)*.6,0,0,false,true)
		hit["counter"]=counter.damage
		tactics.notify(a.id,"Contra-Ataque","%.1f dano"%counter.damage)
	if not hit.evaded and a.id=="rapunzel" and hit.get("silk_before",false):
		var counter:=strike(tactics,a,foe,0,power(a,true)*.5,0,false,false)
		hit["counter"]=counter.damage
		tactics.notify(a.id,"Casulo de Seda","Retaliação: %.1f"%counter.damage)
	var reflection:float=float(Gear.effects(a).get("reflect",0))
	if reflection>0 and float(hit.damage)>0:hit["counter"]=float(hit.get("counter",0))+hurt(tactics,foe,0,float(hit.damage)*reflection,0,true,a,0,0,1,false).damage
	deaths(tactics)
	tactics.sync_totals()
	return hit

static func item_after(tactics,a:Dictionary,out:Dictionary,ult:bool) -> void:
	var e:=Gear.effects(a)
	for at in out.targets.duplicate():
		if at<0 or at>=tactics.enemies.size():continue
		var foe:Dictionary=tactics.enemies[at]
		if foe.hp<=0 or not out.strikes.any(func(s):return int(s.target)==at and not s.evaded):continue
		if float(e.get("fire",0))>0:status(foe,"poison" if e.get("cold",false) else "burn","item_"+str(a.id),2,maxf(power(a,true),power(a,false))*float(e.fire),1,1,false,tactics)
		if float(e.get("venom",0))>0:status(foe,"poison","item_"+str(a.id),2,maxf(power(a,true),power(a,false))*float(e.venom),1,4,false,tactics)
		if e.get("slow",0):status(foe,"hangover",a.id,1,0,1,1,false,tactics)
	if not ult and not out.targets.is_empty() and float(e.get("chain",0))>0:
		var choices:=nearest(tactics,int(out.target),1)
		if not choices.is_empty():
			var at:int=choices[0]
			var chained:=strike(tactics,a,tactics.enemies[at],power(a,false)*float(e.chain),power(a,true)*float(e.chain))
			append_hit(out,at,chained)
			if not chained.evaded:
				on_basic_hit(tactics,a,tactics.enemies[at],out)
				if a.id=="alice":
					var suit_out:=result(at,"Naipe")
					suit_out.damage=chained.damage
					suit_effect(a,int(a.get("previous_suit",0)),suit_out,tactics.run())
					out.healed+=suit_out.healed
	if ult:
		shield(a,a.max_hp*float(e.get("ult_shield",0)),a)
		for ally in tactics.run().actors:
			if ally.hp>0:shield(ally,ally.max_hp*float(e.get("ult_group_shield",0)),a)
	if float(e.get("drain",0))>0:out.healed+=heal(a,out.damage*float(e.drain)).healed

static func deaths(tactics) -> void:
	var owner=tactics.run()
	for pass_index in tactics.enemies.size()+1:
		var processed:=false
		for foe in tactics.enemies:
			if foe.hp>0 or foe.get("death_processed",false):continue
			processed=true
			foe.death_processed=true
			var killer:=actor(owner,str(foe.get("last_source","")).trim_prefix("item_"))
			if not killer.is_empty():
				if killer.id in ["joao","maria"] and boon(killer,1):mana(killer,5)
				if not killer.has("turn_kills"):killer.turn_kills=[]
				killer.turn_kills.append(str(foe.id))
				if killer.id=="mulan":
					var full:=0
					for row in ["front","middle","back"]:
						var column:Array=tactics.enemies.filter(func(f):return f.row==row)
						if column.size()==3 and column.all(func(f):return killer.turn_kills.has(str(f.id))):full+=1
					if full>=2:feat(killer,"two_columns")
			for a in owner.actors:
				if a.hp>0:heal(a,a.max_hp*float(Gear.effects(a).get("kill_heal",0)))
				if a.id=="maria" and boon(a,3) and not killer.is_empty() and killer.id==a.id:
					for s in foe.get("statuses",[]):
						if s.kind=="poison" and s.source==a.id:
							var next:int=tactics.choose_target(a,tactics.enemies)
							if next>=0:status(tactics.enemies[next],"poison",a.id,2,float(s.potency),mini(3,int(s.stacks)),3)
				if a.id=="matches" and boon(a,3) and (float(foe.get("burn",0))>0 or foe.get("died_burning",false)) and not foe.get("exploded",false):
					foe.exploded=true
					for survivor in tactics.enemies:
						if survivor.hp<=0:continue
						var hit:=strike(tactics,a,survivor,0,power(a,true)*.5,0,false,false,false)
						if hit.damage>0 and survivor.hp<=0:mana(a,10)
			if foe.get("dot_death","")=="burn":
				owner.unlock_stats["burn_deaths"]=int(owner.unlock_stats.get("burn_deaths",0))+1
		if not processed:break

static func finish_combat(owner) -> void:
	var feats:Dictionary=owner.unlock_stats.get("boon_feats",{})
	for a in owner.actors:
		if a.hp>0 and a.id=="puss" and (a.get("low_life",false) or a.hp<=a.max_hp*.05):feat(a,"low_life_win")
		if a.hp>0 and a.id=="peter" and int(a.get("lost_shadows",0))>=3:feat(a,"three_shadows")
		if a.id=="matches" and owner.tactics!=null and owner.tactics.enemies.size()>=3 and owner.tactics.enemies.all(func(f):return f.get("dot_death","")=="burn"):feat(a,"all_burn")
		if a.id=="snow_white" and defense(a,false)>=100:feat(a,"defense_100")
		if a.id in ["joao","maria"] and owner.actor_ids().has("maria" if a.id=="joao" else "joao") and owner.tactics!=null and owner.tactics.enemies.any(func(f):return f.get("boss",false) and category(f)=="witch"):feat(a,"witch_siblings")
		var own:Dictionary=feats.get(a.id,{})
		own.merge(a.get("boon_feats",{}),true)
		feats[a.id]=own
	owner.unlock_stats.boon_feats=feats

static func end_turn(a:Dictionary) -> void:
	for s in a.get("statuses",[]):
		if int(s.turns)>0 and int(s.get("applied_turn",-1))<int(a.get("own_turn",0)):s.turns-=1
	a.statuses=a.get("statuses",[]).filter(func(s):return int(s.turns)!=0)
	status_fields(a)
