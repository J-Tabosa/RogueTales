extends RefCounted
## Run-only equipment. Each physical copy occupies one slot on one hero.
const SLOTS := 2
const CAPACITY_PRICES := [150,400,900,1500,2200,3000]
const ITEMS := {
	"ember_pearl":{"title":"Pérola da maré ardente","detail":"Ataques e ULTs aplicam queimadura de 18% do dano no início da vez do alvo, por 2 turnos. A água de Ariel também incendeia.","cost":120,"effects":{"fire":0.18}},
	"winter_match":{"title":"Fósforo de inverno","detail":"Converte as queimaduras do portador em veneno de igual potência. Seus acertos atrasam ataques inimigos em 20 de Iniciativa na próxima vez.","cost":110,"effects":{"cold":true,"slow":3.0}},
	"venom_vial":{"title":"Frasco de maçã negra","detail":"Acertos aplicam veneno de 12% do dano por turno por 2 turnos, acumulando até 4 aplicações.","cost":95,"effects":{"venom":0.12}},
	"hunters_lens":{"title":"Lente de caçadora","detail":"+12 pontos percentuais de crítico e +15% de dano.","cost":100,"stats":{"damage":1.15,"crit":0.12}},
	"tower_braid":{"title":"Laço da torre","detail":"+40 PV máximos e +4 pontos de Defesa Física. Equipar preserva os PV atuais, sem curar.","cost":85,"stats":{"hp":40.0,"armor":4.0}},
	"clockwork":{"title":"Relógio sem ponteiros","detail":"+15 de Iniciativa e +4 mana por acerto elegível.","cost":115,"stats":{"initiative":15.0,"energy":4.0}},
	"mirror_shard":{"title":"Espelho rachado","detail":"Começa cada combate com escudo de 20% dos PV. Reflete 20% do dano recebido.","cost":100,"effects":{"shield_start":0.20,"reflect":0.20}},
	"echo_bell":{"title":"Sino dos ecos","detail":"Cada acerto causa uma reverberação de 30% do dano em outro inimigo. Não gera outra reverberação.","cost":140,"effects":{"chain":0.30}},
	"red_goblet":{"title":"Taça do último brinde","detail":"+4 PV por acerto; derrotar um inimigo recupera 6% dos PV do portador.","cost":90,"stats":{"leech":4.0},"effects":{"kill_heal":0.06}},
	"jade_seal":{"title":"Selo do dragão","detail":"ULT causa +25% de dano e concede ao portador escudo de 15% dos PV máximos.","cost":130,"effects":{"ult_mult":0.25,"ult_shield":0.15}}
}
const TROPHIES := {
	"scarlet":["Presa do Lobo Mau",{"fire":0.15,"execute":0.30}],
	"snow_white":["Fórmula da rainha",{"poison_mult":0.50,"venom":0.10}],
	"rapunzel":["Chave da torre",{"heal_mult":0.30,"shield_start":0.15}],
	"mulan":["Insígnia de jade",{"ult_mult":0.35,"counter_mult":0.50}],
	"ariel":["Concha da maré negra",{"fire":0.18,"heal_mult":0.20}],
	"joao":["Selo do duque",{"execute":0.40,"chain":0.20}],
	"maria":["Taça da condessa",{"poison_mult":0.40,"kill_heal":0.10}],
	"alice":["Coroa de copas",{"ult_mult":0.30,"chain":0.25}],
	"puss":["Nona marca",{"reflect":0.25,"shield_start":0.25}],
	"matches":["Brasa real",{"burn_mult":0.50,"fire":0.15}],
	"peter":["Âncora sem peso",{"counter_mult":0.50,"shield_start":0.20}],
	"aladin":["Areia do vizir",{"heal_mult":0.30,"ult_shield":0.25}]
}
static func item_at(actor: Dictionary, index: int) -> String:
	var items: Array = actor.get("equipment", [])
	return str(items[index]) if index >= 0 and index < items.size() else ""
static func data(id: String) -> Dictionary:
	if ITEMS.has(id): return ITEMS[id].duplicate(true)
	var hero:=id.trim_prefix("trophy_")
	if id.begins_with("trophy_") and TROPHIES.has(hero):
		return {"title":TROPHIES[hero][0],"detail":effect_text(TROPHIES[hero][1]),"cost":0,"effects":TROPHIES[hero][1].duplicate(),"trophy":hero}
	return {}
static func offer(id: String) -> Dictionary:
	if not id.begins_with("item:"):return {}
	var item:=data(id.trim_prefix("item:"))
	if not item.is_empty():item.merge({"id":id,"item":id.trim_prefix("item:")})
	return item
static func effect_text(effects: Dictionary) -> String:
	var parts:Array[String]=[]
	var names:Dictionary={"fire":"Queimadura / s por 5 s","venom":"Veneno / s por 5 s","execute":"Dano extra contra alvo com menos de 35% dos PV","poison_mult":"Dano de veneno extra","burn_mult":"Dano de queimadura extra","heal_mult":"Cura extra","shield_start":"Escudo ao iniciar combate","ult_mult":"Dano de ULT extra","counter_mult":"Dano de contra-ataque extra","chain":"Reverberação em outro alvo","reflect":"Dano refletido","kill_heal":"Cura ao derrotar inimigo","ult_shield":"Escudo ao usar ULT"}
	for key in effects:
		parts.append("%s: +%d%%"%[names.get(key,key),roundi(float(effects[key])*100)])
	return ". ".join(parts)+"."
static func effects(actor: Dictionary) -> Dictionary:
	var result:Dictionary=actor.get("blessing_effects",{}).duplicate()
	for id in actor.get("equipment",[]):
		for key in data(id).get("effects",{}):
			var value:Variant=data(id).effects[key]
			result[key]=true if value is bool else float(result.get(key,0.0))+float(value)
	return result
static func detach(actor: Dictionary) -> void:
	var a:Dictionary=actor.get("equipment_applied",{})
	if a.is_empty():return
	actor.damage/=a.damage
	actor.interval/=a.interval
	actor.max_hp=maxf(1,actor.max_hp-a.hp)
	for key in ["armor","crit","leech","energy_bonus","initiative"]:actor[key]-=float(a.get(key,0))
	actor["equipment_applied"]={}
static func attach(actor: Dictionary) -> void:
	var a:Dictionary={"damage":1.0,"interval":1.0,"hp":0.0,"armor":0.0,"crit":0.0,"leech":0.0,"energy_bonus":0.0,"initiative":0.0}
	for id in actor.get("equipment",[]):
		var s:Dictionary=data(id).get("stats",{})
		a.damage*=float(s.get("damage",1.0))
		a.interval*=float(s.get("interval",1.0))
		a.hp+=float(s.get("hp",0.0))
		for key in ["armor","crit","leech","initiative"]:a[key]+=float(s.get(key,0.0))
		a.energy_bonus+=float(s.get("energy",0.0))
	a.initiative=minf(a.initiative,100-float(actor.get("initiative",50)))
	a.crit=minf(a.crit,0.95-actor.crit)
	a.interval=maxf(0.65,actor.interval*a.interval)/actor.interval
	actor.damage*=a.damage
	actor.interval*=a.interval
	actor.max_hp+=a.hp
	for key in ["armor","crit","leech","energy_bonus","initiative"]:actor[key]+=a[key]
	actor["equipment_applied"]=a
