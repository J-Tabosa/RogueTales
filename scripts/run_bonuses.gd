extends RefCounted
## Run-only bonuses. Values are exact, additive and independent of gear/base stats.
const Gear=preload("res://scripts/equipment.gd")
const RARITIES=["Comum","Incomum","Raro","Épico","Lendário","Mítico"]
const WEIGHTS=[40,28,18,9,4,1]
const MODE_WEIGHTS=[70,30]
const COLORS=["858b94","50b86a","5097ee","ac6bef","ef9c39","ee5555"]
const NAMES={"magic_damage":"Dano Mágico","physical_damage":"Dano Físico","physical_defense":"Defesa Física","magic_defense":"Defesa Mágica","attacks":"Quantidade de Ataques","mana_hit":"Mana por Acerto","mana_turn":"Mana por Turno","max_hp":"Vida Máxima","crit":"Chance Crítica","crit_multiplier":"Dano Crítico","evasion":"Esquiva","initiative":"Iniciativa","healing":"Aumento de Cura","spread":"Espalhamento"}
const UNIQUE={"magic_damage":[5,8,12,16,20,25],"physical_damage":[5,8,12,16,20,25],"physical_defense":[8,12,17,23,29,35],"magic_defense":[8,12,17,23,29,35],"attacks":[0,0,1,1,2,3],"mana_hit":[5,7,10,13,16,20],"mana_turn":[2,3,4,6,8,10],"max_hp":[20,30,45,60,80,100],"crit":[10,15,20,30,40,50],"crit_multiplier":[5,10,20,30,40,50],"evasion":[5,7,10,13,16,20],"initiative":[5,8,12,16,20,25],"healing":[5,8,12,16,20,25],"spread":[0,0,1,1,2,3]}
const GROUP={"magic_damage":[3,4,6,8,10,13],"physical_damage":[3,4,6,8,10,13],"physical_defense":[4,6,9,12,15,18],"magic_defense":[4,6,9,12,15,18],"attacks":[0,0,0,0,1,1],"mana_hit":[3,4,5,7,8,10],"mana_turn":[1,2,2,3,4,5],"max_hp":[10,15,23,30,40,50],"crit":[5,8,10,15,20,25],"crit_multiplier":[3,5,10,15,20,25],"evasion":[3,4,5,7,8,10],"initiative":[3,4,6,8,10,13],"healing":[3,4,6,8,10,13]}
const PERCENT=["magic_damage","physical_damage","healing","crit","crit_multiplier","evasion"]

static func total(a:Dictionary,key:String) -> float:
	return float(a.get("bonus_totals",{}).get(key,0))

static func chance(a:Dictionary) -> float:return clampf(float(a.get("crit",0))+total(a,"crit"),0,1)
static func critical_multiplier(a:Dictionary) -> float:return float(a.get("crit_multiplier",2))+total(a,"crit_multiplier")
static func evasion(a:Dictionary) -> float:return clampf(float(a.get("evasion",0))+total(a,"evasion"),0,.8)
static func attacks(a:Dictionary) -> int:return maxi(1,int(a.get("attacks",1))+int(total(a,"attacks")))
static func mana_hit(a:Dictionary) -> float:return float(a.get("mana_hit",0))+total(a,"mana_hit")
static func mana_turn(a:Dictionary) -> float:return float(a.get("mana_turn",0))+total(a,"mana_turn")

static func compatible(a:Dictionary,key:String) -> bool:
	var id:String=str(a.get("id",""))
	match key:
		"spread":return false # Damage, target selection and kit interactions await author decision.
		"physical_damage","magic_damage":return float(a.get(key,0))>0
		"mana_hit":return id not in ["alice","aladin","rapunzel"]
		"mana_turn":return id not in ["alice","aladin"] and a.has("mana_turn")
		"crit","crit_multiplier":return id!="rapunzel" and (float(a.get("physical_damage",0))+float(a.get("magic_damage",0))>0) and (key=="crit" or chance(a)>0)
		"healing":return id in ["ariel","alice"] or id=="matches" and int(a.get("blessing_index",-1))==2 or id!="rapunzel" and float(a.get("leech",0))>0 or float(Gear.effects(a).get("drain",0))>0 or float(Gear.effects(a).get("kill_heal",0))>0
	return NAMES.has(key)

static func useful(a:Dictionary,key:String,sign:=0) -> bool:
	if not compatible(a,key):return false
	match key:
		"crit":return chance(a)<1
		"evasion":return evasion(a)<.8
		"initiative":return sign<=0 or value(a,key)<100
	return true

static func parse(id:String) -> Dictionary:
	var p:=id.split(":")
	if p.size()!=5 or p[0]!="bonus" or not p[1].is_valid_int() or int(p[1])<=0 or not p[4].is_valid_int():return {}
	var rank:=int(p[4])
	var table:Dictionary=GROUP if p[3]=="group" else UNIQUE
	if p[3] not in ["unique","group"] or rank<0 or rank>=6 or not table.has(p[2]) or p[2]=="spread" or int(table[p[2]][rank])<=0:return {}
	return {"id":id,"attribute":p[2],"mode":p[3],"rarity":rank,"magnitude":int(table[p[2]][rank])}

static func amount_text(b:Dictionary) -> String:
	var key:String=b.attribute
	var amount:int=b.magnitude
	if key=="initiative":return "±%d"%amount
	return "+%d%s"%[amount," pp" if key in ["crit","crit_multiplier","evasion"] else "%" if key in ["physical_damage","magic_damage","healing"] else ""]

static func describe(id:String) -> Dictionary:
	var b:=parse(id)
	if b.is_empty():return {}
	b["title"]="%s · %s"%[NAMES[b.attribute],amount_text(b)]
	b["detail"]="Escolha um personagem. Até o fim da run." if b.mode=="unique" else "Equipe compatível e futuros recrutados. Até o fim da run."
	b["note"]="%s · %s"%["ÚNICO" if b.mode=="unique" else "DE GRUPO",RARITIES[b.rarity].to_upper()]
	b["bonus"]=true
	return b

static func tint(id:String) -> Color:
	var b:=parse(id)
	return Color(COLORS[int(b.rarity)]) if not b.is_empty() else Color(COLORS[0])

static func rarity(rng:RandomNumberGenerator) -> int:
	var ticket:=rng.randi_range(1,100)
	for i in WEIGHTS.size():
		ticket-=WEIGHTS[i]
		if ticket<=0:return i
	return 0

static func attributes(actors:Array,mode:String,rank:int) -> Array[String]:
	var table:Dictionary=GROUP if mode=="group" else UNIQUE
	var keys:Array[String]=[]
	for key in table:
		if key=="spread" or int(table[key][rank])<=0:continue
		if actors.any(func(a):return useful(a,key)):keys.append(key)
	return keys

static func roll(owner) -> String:
	var rank:=rarity(owner.rng)
	var mode:="unique" if owner.rng.randi_range(1,100)<=70 else "group"
	var keys:=attributes(owner.actors,mode,rank)
	# Explicit bounded fallback: preserve rarity, try other mode, then no offer.
	if keys.is_empty():
		mode="group" if mode=="unique" else "unique"
		keys=attributes(owner.actors,mode,rank)
	if keys.is_empty():return ""
	owner.bonus_serial+=1
	return "bonus:%d:%s:%s:%d"%[owner.bonus_serial,keys[owner.rng.randi_range(0,keys.size()-1)],mode,rank]

static func value(a:Dictionary,key:String) -> float:
	# Runtime load avoids a catalog/bonus/combat preload cycle.
	var rules=load("res://scripts/combat_rules.gd")
	match key:
		"physical_damage","magic_damage":return rules.power(a,key=="magic_damage")
		"physical_defense","magic_defense":return rules.defense(a,key=="magic_defense")
		"initiative":return rules.effective_initiative(a)
		"crit":return chance(a)*100
		"crit_multiplier":return critical_multiplier(a)
		"evasion":return evasion(a)*100
		"attacks":return attacks(a)
		"mana_hit":return mana_hit(a)
		"mana_turn":return mana_turn(a)
		"healing":return (1+total(a,key))*100
	return float(a.get(key,0))

static func apply_actor(a:Dictionary,b:Dictionary) -> void:
	if not a.has("bonus_applied"):a.bonus_applied=[]
	if a.bonus_applied.has(b.id):return
	a.bonus_applied.append(b.id)
	if not compatible(a,b.attribute):return
	if not a.has("bonus_totals"):a.bonus_totals={}
	var gain:float=b.magnitude
	if b.attribute in PERCENT:gain/=100.0
	if b.attribute=="initiative":gain*=int(b.sign)
	a.bonus_totals[b.attribute]=total(a,b.attribute)+gain
	if b.attribute=="max_hp":
		a.max_hp+=gain
		if a.hp>0:a.hp+=gain

static func preview(a:Dictionary,b:Dictionary,sign:int) -> Dictionary:
	if not useful(a,b.attribute,sign):return {"eligible":false,"text":"Incompatível" if not compatible(a,b.attribute) else "No limite · sem ganho nesta direção"}
	var copy:=a.duplicate(true)
	var choice:=b.duplicate(true)
	choice.sign=sign
	apply_actor(copy,choice)
	var before:=value(a,b.attribute)
	var after:=value(copy,b.attribute)
	var suffix:="%" if b.attribute in ["crit","evasion","healing"] else ""
	var text:="%.1f%s → %.1f%s"%[before,suffix,after,suffix]
	if b.attribute=="max_hp":text="PV %.1f/%.1f → %.1f/%.1f"%[a.hp,a.max_hp,copy.hp,copy.max_hp]
	elif b.attribute=="crit_multiplier":text="×%.2f → ×%.2f"%[before,after]
	return {"eligible":true,"text":text,"before":before,"after":after,"gain":after-before}

static func acquire(owner,id:String,target:String,sign:int) -> bool:
	var b:=parse(id)
	if b.is_empty() or owner.bonus_history.any(func(entry):return entry.id==id):return false
	if b.attribute=="initiative" and sign not in [-1,1]:return false
	b["sign"]=sign if b.attribute=="initiative" else 1
	b["target"]=target if b.mode=="unique" else ""
	var recipients:Array=[]
	for a in owner.actors:
		if (b.mode=="group" or a.id==target) and useful(a,b.attribute,b.sign):recipients.append(a)
	if recipients.is_empty():return false
	# Group records nominal gains for compatible actors even if individually capped.
	for a in owner.actors:
		if b.mode=="group" or a.id==target:apply_actor(a,b)
	owner.bonus_history.append(b.duplicate(true))
	return true

static func recruit(owner,a:Dictionary) -> void:
	for b in owner.bonus_history:
		if b.mode=="group":apply_actor(a,b)

static func snapshot(owner) -> Dictionary:
	var states:={}
	for a in owner.actors:states[a.id]={"totals":a.get("bonus_totals",{}).duplicate(true),"applied":a.get("bonus_applied",[]).duplicate()}
	return {"format":1,"serial":owner.bonus_serial,"history":owner.bonus_history.duplicate(true),"actors":states,"legacy_preserved":not owner.relics.is_empty()}

static func restore(owner,data:Dictionary) -> void:
	owner.bonus_serial=maxi(0,int(data.get("serial",0)))
	owner.bonus_history.clear()
	for entry in data.get("history",[]):
		if not entry is Dictionary:continue
		var b:=parse(str(entry.get("id","")))
		if b.is_empty() or owner.bonus_history.any(func(old):return old.id==b.id):continue
		b["sign"]=-1 if int(entry.get("sign",1))<0 else 1
		b["target"]=str(entry.get("target",""))
		owner.bonus_history.append(b)
		owner.bonus_serial=maxi(owner.bonus_serial,int(str(b.id).split(":")[1]))
	for a in owner.actors:
		a["bonus_totals"]={}
		a["bonus_applied"]=[]
		var state:Dictionary=data.get("actors",{}).get(a.id,{})
		for key in state.get("totals",{}):
			var v:=float(state.totals[key])
			if NAMES.has(key) and is_finite(v):a.bonus_totals[key]=v if key=="initiative" else maxf(0,v)
		for id in state.get("applied",[]):
			if not parse(str(id)).is_empty() and not a.bonus_applied.has(id):a.bonus_applied.append(str(id))
	# No effects replayed: max/current HP already belong to the saved actor snapshot.
