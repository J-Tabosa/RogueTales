extends RefCounted
## The uploaded roster's ULT rules. Visuals consume these same target lists.
const Layout=preload("res://scripts/formation_layout.gd")
const Modifiers=preload("res://scripts/combat_modifiers.gd")
const IDS=["scarlet","ariel","aladin","joao","maria","peter","mulan","snow_white","rapunzel","alice","matches"]
const CURSE_DURATION=8.0
const HAIR_SHIELD=0.30
const MULTIPLIERS={"scarlet":2.2,"ariel":2.0,"joao":4.2,"mulan":3.2,"snow_white":8.0,"alice":2.2,"matches":2.0}

static func resource_ready(actor: Dictionary) -> bool:
	if actor.id=="alice":return int(actor.get("card_charge",0))>=4
	if actor.id=="peter" and int(actor.get("guardian_spirits",0))>=3:return false
	return float(actor.get("energy",0))>=100

static func line_targets(enemies: Array,target: int) -> Array[int]:
	var result:Array[int]=[]
	if target<0 or target>=enemies.size():return result
	var lane:float=Layout.home(enemies,target,true).y
	for at in enemies.size():
		if enemies[at].hp>0 and absf(Layout.home(enemies,at,true).y-lane)<0.015:result.append(at)
	return result

static func allies(owner,index: int) -> Array[int]:
	var result:Array[int]=[index]
	var choices:Array[int]=[]
	for at in owner.actors.size():
		if at!=index and owner.actors[at].hp>0:choices.append(at)
	choices.sort_custom(func(a,b):
		var left:float=owner.actors[a].hp/owner.actors[a].max_hp
		var right:float=owner.actors[b].hp/owner.actors[b].max_hp
		return a<b if is_equal_approx(left,right) else left<right)
	for at in choices.slice(0,2):result.append(at)
	return result

static func targets(tactics,index: int,requested := -1) -> Array[int]:
	var owner=tactics.run()
	var id:String=owner.actors[index].id
	var target:int=requested if requested>=0 and requested<tactics.enemies.size() and tactics.enemies[requested].hp>0 else tactics.target_for(index)
	var result:Array[int]=[]
	if target<0 or id in ["rapunzel","peter"]:return result
	if id=="alice":return line_targets(tactics.enemies,target)
	if id in ["joao","snow_white"]:return [target]
	if id=="mulan":return tactics.eligible({"class":"vanguard"},tactics.enemies)
	for at in tactics.enemies.size():
		if tactics.enemies[at].hp>0:result.append(at)
	return result

static func execute(tactics,index: int,requested := -1) -> Dictionary:
	var owner=tactics.run()
	var actor:Dictionary=owner.actors[index]
	actor.ult_pending=false
	var chosen:int=requested if requested>=0 and requested<tactics.enemies.size() and tactics.enemies[requested].hp>0 else tactics.target_for(index)
	var affected:Array[int]=targets(tactics,index,chosen)
	var result={"target":chosen,"targets":affected,"target_damage":{},"damage":0.0,"healed":0.0,"evaded":false,"critical":false,"ultimate":true,"message":str(TaleCatalog.HERO_TACTICS[actor.id].ult),"ally_targets":[],"status_targets":[],"strikes":[]}
	match str(actor.id):
		"rapunzel":
			result.ally_targets=allies(owner,index)
			for at in result.ally_targets:
				var ally:Dictionary=owner.actors[at]
				var factor:float=1.0+float(Modifiers.effects(actor).get("shield_mult",0))
				ally.shield=minf(ally.max_hp,ally.shield+ally.max_hp*HAIR_SHIELD*factor)
				ally["hair_guard"]=true
		"peter":
			actor["guardian_spirits"]=mini(3,int(actor.get("guardian_spirits",0))+1)
			result.ally_targets=[index]
			result["guardian_spirits"]=actor.guardian_spirits
		"aladin":
			for at in affected:
				if owner.rng.randf()<0.5:
					tactics.enemies[at]["sleep_turns"]=1
					tactics.enemies[at]["intent"]={}
					result.status_targets.append(at)
		"maria":
			for at in affected:
				tactics.enemies[at]["curse_left"]=CURSE_DURATION
				result.status_targets.append(at)
		_:
			for at in affected:
				var count:int=6 if actor.id=="joao" else 1
				var total:float=Modifiers.amount(actor,tactics.enemies[at],actor.damage*float(MULTIPLIERS.get(actor.id,1.0)),true)
				var amount:=0.0
				for hit_index in count:
					var dealt:Dictionary=tactics.deal(tactics.enemies[at],total/count,actor.id not in ["joao","mulan","snow_white"],true)
					amount+=dealt.damage
					result.strikes.append({"target":at,"damage":dealt.damage,"ordinal":hit_index+1})
				result.target_damage[at]=amount
				result.damage+=amount
				if actor.id=="scarlet":Modifiers.burn(tactics,actor,tactics.enemies[at],actor.damage*.12,4.0)
				if actor.id=="matches":Modifiers.burn(tactics,actor,tactics.enemies[at],actor.damage*.25,6.0)
			Modifiers.after(tactics,actor,affected,result.target_damage,true)
	# Defensive equipment and cleanses still work without turning support ULTs into attacks.
	if actor.id in ["rapunzel","peter","aladin","maria"]:Modifiers.after(tactics,actor,[],{},true)
	tactics.Abilities.deaths(tactics)
	tactics.BossRules.refresh(tactics)
	tactics.ultimate_serial+=1
	tactics.last_ultimate={"hero":str(actor.id),"serial":tactics.ultimate_serial}
	tactics.sync_totals()
	return result
