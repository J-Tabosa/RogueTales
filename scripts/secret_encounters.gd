extends RefCounted
## Optional one-enemy trials. Keys and rewards survive saves, once per hero/run.
const Biomes=preload("res://scripts/biomes.gd")
const DATA := {
 "scarlet":{"name":"Lobo Mau","biomes":[0],"group":"a","row":0,"class":"assassin","effect":"heavy","line":"Esse uivo eu reconheço. Hoje a floresta vai ouvir a minha resposta.","body":"Pegadas enormes desviam da trilha. O Lobo Mau espera sozinho sob uma capa rasgada.","reward":"Scarlet: +25% de dano e +10 pontos percentuais de crítico."},
 "snow_white":{"name":"Rainha Má","biomes":[0,6],"group":"a","row":1,"class":"mage","effect":"poison","line":"Ela ainda usa aquela fórmula velha? Vou precisar de uma amostra.","body":"Um pomar de maçãs negras cresce ao redor de um laboratório abandonado. A rainha guarda a última fórmula.","reward":"Branca: +25% de dano e +4 mana por acerto."},
 "rapunzel":{"name":"Falsa Mãe","biomes":[1,5],"group":"a","row":2,"class":"vanguard","effect":"drain","line":"Eu não volto para aquela janela. E ninguém mais vai ficar presa lá.","body":"Uma corrente dourada fecha a passagem até a torre. A carcereira afia sua tesoura.","reward":"Rapunzel: +25% de PV máximos e +4 de armadura."},
 "mulan":{"name":"General do Leste","biomes":[2],"group":"a","row":3,"class":"vanguard","effect":"heavy","line":"Um general sem soldados ainda precisa responder pelos próprios atos.","body":"No passo congelado, uma bandeira antiga anuncia um duelo. O general veio sem escolta.","reward":"Mulan: +20 de Iniciativa e crítico +10 pontos percentuais."},
 "ariel":{"name":"Bruxa do Mar","biomes":[3],"group":"b","row":0,"class":"mage","effect":"slow","line":"Eu ia tirar uma soneca. Mas com essa água suja não dá.","body":"As ondas escurecem ao redor de uma concha partida. Uma bruxa tomou para si a correnteza.","reward":"Ariel: +15% de dano e +8 mana por acerto."},
 "joao":{"name":"Bruxa dos Doces","biomes":[1],"group":"b","row":1,"class":"vanguard","effect":"heavy","line":"Hoje a faca de açúcar vai cortar o seu feitiço.","body":"O cheiro de caramelo leva até uma casa de doces. A bruxa afia uma faca de açúcar ao lado do forno.","reward":"João: +25% de dano e crítico +10 pontos percentuais."},
 "maria":{"name":"Bruxa dos Doces","biomes":[1],"group":"b","row":2,"class":"mage","effect":"poison","line":"Eu conheço o veneno por trás desse cheiro de doce.","body":"Uma poção borbulha entre doces enfeitiçados. A Bruxa dos Doces protege seu caldeirão.","reward":"Maria: +25% de dano e +4 PV de cura por acerto."},
 "alice":{"name":"Rainha de Copas","biomes":[1,5],"group":"b","row":3,"class":"ranger","effect":"drain","line":"Pode ficar com a coroa. Eu só quero embaralhar as regras.","body":"Cartas gigantes fecham um corredor do castelo. A Rainha de Copas propõe uma última mão.","reward":"Alice: +15% de dano híbrido."},
 "puss":{"name":"Lobo Caçador de Recompensas","biomes":[1,7],"group":"c","row":0,"class":"vanguard","effect":"heavy","line":"Nove vidas não são uma dívida. Venha cobrar de perto.","body":"Uma lâmina risca nove marcas no chão. O carrasco aguarda apenas o gato.","reward":"Gato: +25% de PV máximos e +20% de dano."},
 "matches":{"name":"Espírito de Gelo","biomes":[4],"group":"c","row":1,"class":"mage","effect":"slow","line":"Eu já conheço esse frio. Desta vez, a chama não vai se apagar.","body":"A geada cobre uma rua abandonada. Um espírito de gelo tenta apagar a última chama.","reward":"Vendedora: +25% de dano e +3 de armadura."},
 "peter":{"name":"Capitão Gancho","biomes":[0,3,6],"group":"c","row":2,"class":"assassin","effect":"drain","line":"Uma âncora não prende quem esqueceu como cair. Vamos brincar de novo?","body":"Uma âncora atravessa a névoa. O capitão espectral veio buscar uma sombra que nunca lhe pertenceu.","reward":"Peter: +20% de dano e +10 pontos percentuais de esquiva."},
 "aladin":{"name":"O Rei do Deserto","biomes":[7,5],"group":"c","row":3,"class":"mage","effect":"slow","line":"Três desejos e ele escolheu mandar nos outros. Que desperdício.","body":"Uma ampulheta derrama areia violeta contra o vento. O vizir oferece uma troca impossível pela lâmpada.","reward":"Aladin: +20% de PV máximos."}
}
static func eligible(owner, id: String) -> bool:
	if not owner.expedition or not DATA.has(id) or owner.secret_defeated.has(id) or not owner.active_secret.is_empty(): return false
	if not DATA[id].biomes.has(owner.current_biome()): return false
	for actor in owner.actors:
		if actor.id==id and actor.hp>0: return true
	return false
static func available(owner) -> Array[String]:
	var keys: Array[String]=[]
	for id in DATA:
		if eligible(owner,id) and not owner.seen_events.has("secret_"+id): keys.append("secret_"+id)
	return keys
static func event(key: String) -> Dictionary:
	var id:=key.trim_prefix("secret_")
	if not DATA.has(id): return {}
	return {"title":"Desafio secreto · "+str(DATA[id].name),"body":DATA[id].body,"pair":[id,id],"lines":[DATA[id].line],"reward":DATA[id].reward,"choice":"Aceitar o duelo"}
static func spawn(owner) -> Dictionary:
	var id: String=owner.active_secret
	var data: Dictionary=DATA[id]
	var depth: int=(owner.rooms_cleared if owner.endless else owner.stage*6+owner.phase)+12
	var health: float=86.0*(1.0+depth*.05)*pow(1.045,mini(depth,120))*1.5*(1.0+maxi(0,depth-120)*.08)
	return {"id":"secret_"+id,"secret_id":id,"name":data.name,"class":data["class"],"row":"front","hp":health,"max_hp":health,"damage":(13.0+depth*.85)*1.32,"armor":2+float(depth)/10,"evasion":0.0,"boss":true,"interval":2.9,"timer":2.0,"burn":0.0,"burn_left":0.0,"poison":0.0,"poison_left":0.0,"biome":owner.current_biome(),"variant":5,"slot":0,"action_count":0,"intent":{}}
static func reward(owner) -> void:
	var id: String=owner.active_secret
	if not DATA.has(id) or owner.secret_defeated.has(id): return
	owner.secret_defeated.append(id)
	for a in owner.actors:
		if a.id!=id: continue
		preload("res://scripts/equipment.gd").detach(a)
		match id:
			"scarlet","joao":
				a.damage*=1.25
				a.crit=minf(.95,a.crit+.10)
			"snow_white":
				a.damage*=1.25
				a.energy_bonus+=4
			"rapunzel":
				a.max_hp*=1.25
				a.armor+=4
			"mulan":
				a.initiative=minf(100,a.initiative+20)
				a.crit=minf(.95,a.crit+.10)
			"ariel","alice":
				a.damage*=1.15
				a.energy_bonus+=8
			"maria":
				a.damage*=1.25
				a.leech+=4
			"puss":
				a.max_hp*=1.25
				a.damage*=1.2
			"matches":
				a.damage*=1.25
				a.armor+=3
			"peter":
				a.damage*=1.2
				a.base_evasion=minf(.8,a.base_evasion+.1)
				a.evasion=a.base_evasion
			"aladin":
				a.max_hp*=1.2
				a.energy_bonus+=8
		preload("res://scripts/equipment.gd").attach(a)
		if a.hp>0: a.hp=minf(a.max_hp,a.hp+a.max_hp*.25)
	owner.run_gold+=75+owner.stage*5
	owner.last_room_score=600
	owner.score+=600
	owner.kills+=1
	owner.pending_secret_reward=id
	owner.active_secret=""
	owner.interlude="secret_reward"
