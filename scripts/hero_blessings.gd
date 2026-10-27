extends RefCounted
## Four paths per protagonist. Progress comes from actual participation, never purchases.
const Roster=preload("res://scripts/roster_data.gd")
const PATHS = {
	"scarlet": [
		[
			"Pavio Curto",
			"Custo da ult reduzido em 30: de 120 para 90.",
			{
				"path": 0
			}
		],
		[
			"Explosivo Fragmentado",
			"Básico também acerta os dois alvos mais próximos do alvo principal, com 50% do dano. Cada alvo recebe uma carga e concede dez de mana.",
			{
				"path": 1
			}
		],
		[
			"Inimiga de Bestas",
			"+50% de dano contra categoria Besta.",
			{
				"path": 2
			}
		],
		[
			"Chapeuzinho Vermelho",
			"Ult começa em 300%, chegando a 600% com dez cargas. Básicos aplicam duas cargas por alvo, mantendo dez de mana por acerto.",
			{
				"path": 3
			}
		]
	],
	"alice": [
		[
			"Full House",
			"Cada ult concede um básico adicional, que avança o naipe e o contador.",
			{
				"path": 0
			}
		],
		[
			"Chapeleira Maluca",
			"Uma condição negativa é sorteada por ult e compartilhada entre os inimigos atingidos. Dura um turno, usa a potência padrão da condição e respeita chance de aplicação e imunidades individuais.",
			{
				"path": 1
			}
		],
		[
			"Escapada Mágica",
			"Uma vez por estágio, antes de um ataque fatal, troca com qualquer aliado vivo da retaguarda, que recebe o ataque. Alice ganha 100% de esquiva até sua próxima vez. Sem aliado elegível, não ativa.",
			{
				"path": 2
			}
		],
		[
			"País das Maravilhas",
			"Dobra os efeitos especiais dos naipes. Cada ataque tem 10% de chance de lançar um Coringa, limitado a um por turno. O Coringa causa o dano do ataque e repete o efeito do naipe anterior; não avança naipe nem carrega a ult.",
			{
				"path": 3
			}
		]
	],
	"snow_white": [
		[
			"Um Pouco pra Mim!",
			"Ao destruir um escudo, recebe 50% do valor que ele tinha imediatamente antes do golpe que o destruiu como escudo próprio.",
			{
				"path": 0
			}
		],
		[
			"Duro e Afiado",
			"Cada dois pontos de Defesa Física concedem +1% de Dano Físico.",
			{
				"path": 1
			}
		],
		[
			"Constituição de Mineradora",
			"Imune a efeitos negativos que causem dano, como veneno e queimadura. Não é imunidade geral a controles sem dano.",
			{
				"path": 2
			}
		],
		[
			"A Branca de Neve",
			"50% de chance de interceptar ataque de alvo único contra aliado da retaguarda ou Assassino. Não esquiva do golpe interceptado e recebe 20% menos dano, além das defesas normais. Após duas falhas consecutivas, a próxima tentativa é garantida. Sucesso zera falhas. Uma interceptação entre suas vezes, recuperada no início da própria vez. Não funciona em área.",
			{
				"path": 3
			}
		]
	],
	"ariel": [
		[
			"Espuma Acolhedora",
			"100% da cura excedente vira escudo, até 15% da vida máxima do beneficiário em escudo desta bênção. Pode escolher aliado saudável se todos estiverem com vida cheia.",
			{
				"path": 0
			}
		],
		[
			"Ondas Infinitas",
			"Dois ricochetes adicionais, de 40% do Dano Mágico cada. Também testam os 50%, não repetem alvos e ativam cura/mana por acerto.",
			{
				"path": 1
			}
		],
		[
			"Voz das Profundezas",
			"Se a rolagem de aplicação de Bolha falhar, aplica Ressaca: −20 de Iniciativa na próxima vez do alvo. Respeita imunidade a controle.",
			{
				"path": 2
			}
		],
		[
			"A Princesa Sereia",
			"Aplicar Bolha concede um básico extra à próxima vez de Umi, até três guardados. Não aumenta permanentemente o atributo e não acrescenta ataques à sequência atual.",
			{
				"path": 3
			}
		]
	],
	"rapunzel": [
		[
			"Trança Dupla",
			"Básico protege mais um aliado, além de Silk e do primeiro beneficiário.",
			{
				"path": 0
			}
		],
		[
			"Fios Resistentes",
			"Quebra de escudo criado por Silk por dano inimigo concede dez de mana a ela. Cada aliado pode ativar uma vez entre duas vezes de Silk.",
			{
				"path": 1
			}
		],
		[
			"Esperando Para Sempre",
			"Seus escudos não expiram após cinco turnos; permanecem até quebrar, inclusive entre combates.",
			{
				"path": 2
			}
		],
		[
			"Rapunzel",
			"Ult limpa todos os efeitos negativos do grupo e concede escudo de 300% do Dano Mágico, preservando o bônus defensivo da ult.",
			{
				"path": 3
			}
		]
	],
	"mulan": [
		[
			"Dois Ataques",
			"Básico aprimorado a cada dois básicos.",
			{
				"path": 0
			}
		],
		[
			"Fogos de Artifício",
			"Ult acerta também a coluna imediatamente atrás da original, com os mesmos 250%. Vanguarda + meio, ou meio + retaguarda; não propaga para uma terceira coluna.",
			{
				"path": 1
			}
		],
		[
			"Sem Correntes",
			"Até três contra-ataques entre suas vezes.",
			{
				"path": 2
			}
		],
		[
			"A Guerreira do Leste",
			"Cada crítico de básico acrescenta cinco pontos percentuais ao dano dos próximos básicos, até +20. Expira no início da próxima vez, sem renovar duração. Soma com o aprimorado: comum até 120%, aprimorado até 170%. O golpe que gera a carga usa o bônus anterior.",
			{
				"path": 3
			}
		]
	],
	"maria": [
		[
			"Acumulando Ainda Mais Toxinas!",
			"Limite de veneno passa a cinco doses.",
			{
				"path": 0
			}
		],
		[
			"Assassinos de Bruxas",
			"+50% de dano contra Bruxa ou Feiticeiro. Matar inimigo de qualquer categoria concede cinco de mana, inclusive morte por seu veneno.",
			{
				"path": 1
			}
		],
		[
			"Uma Maldição Mais Forte",
			"Acrescenta Corta-Cura e Quebra-Escudos pela duração da Maldição.",
			{
				"path": 2
			}
		],
		[
			"A Nova Bruxa",
			"Quando a própria Maria mata um inimigo envenenado, inclusive pelo veneno, transfere suas doses ao próximo alvo válido segundo sua prioridade, até três doses. Sem dano imediato; sem outro inimigo, as doses desaparecem.",
			{
				"path": 3
			}
		]
	],
	"joao": [
		[
			"Doce Ponto Fraco",
			"Ignora 50% dos pontos de Defesa Física do alvo.",
			{
				"path": 0
			}
		],
		[
			"Assassinos de Bruxas",
			"+50% de dano contra Bruxa ou Feiticeiro. Eliminar qualquer inimigo concede cinco de mana, inclusive por ult ou Sangramento.",
			{
				"path": 1
			}
		],
		[
			"Marcado para Morrer",
			"Acertar seis estocadas no mesmo inimigo na mesma ult aplica Sangramento: 10% do Dano Físico como dano real no início da vez dele e Corta-Cura de 50%. Não acumula, critica ou gera mana pelo dano. Dura até a morte, mas pode ser limpo.",
			{
				"path": 2
			}
		],
		[
			"O Caçador da Casa dos Doces",
			"Cada crítico da ult acrescenta uma estocada à execução, até três extras. Extras podem critar, mas não geram outras extras.",
			{
				"path": 3
			}
		]
	],
	"matches": [
		[
			"Mais de uma Faísca",
			"+1 ataque, direcionado a outro inimigo. Sem outro alvo, repete o primeiro. Causa 50% do Dano Mágico e aplica/fortalece fogo, gerando mana normalmente.",
			{
				"path": 0
			}
		],
		[
			"Queime até Virar Cinzas",
			"Seu fogo não expira nem pode ser limpo depois de aplicado. Imunidade ainda impede aplicar. Limite da potência passa a 200% do Dano Mágico.",
			{
				"path": 1
			}
		],
		[
			"A Chama da Vida",
			"No início da vez de Lume, havendo inimigo queimando, cura 50% da potência por turno da queimadura mais forte entre eles. Sujeita a Corta-Cura.",
			{
				"path": 2
			}
		],
		[
			"A Vendedora de Fósforos",
			"Morte de inimigo incendiado provoca explosão de 50% do Dano Mágico contra os demais. Mortos pela explosão só continuam a cadeia se já estavam incendiados. Cada inimigo explode uma vez. Explosão mágica, sem crítico, sem aplicar fogo. Apenas mortes pelas explosões concedem dez de mana por abate.",
			{
				"path": 3
			}
		]
	],
	"aladin": [
		[
			"Lâmpada Preciosa",
			"Passiva concede +20% de Dano Mágico por desejo restante, começando em +60%.",
			{
				"path": 0
			}
		],
		[
			"Proteção ao Portador da Lâmpada",
			"Imune a todos os efeitos negativos enquanto restar algum desejo.",
			{
				"path": 1
			}
		],
		[
			"Essa É Por Conta da Casa",
			"Quarta carga livre para repetir uma das três opções, além do uso de cada desejo original. Conta na passiva: +40%, +30%, +20%, +10%, zero.",
			{
				"path": 2
			}
		],
		[
			"Gênio Liberto",
			"Após gastar os três desejos, +2 ataques por turno e rajadas passam a dano real, escalando com Dano Mágico.",
			{
				"path": 3
			}
		]
	],
	"peter": [
		[
			"O Menino e Sua Sombra",
			"Começa cada combate com uma sombra.",
			{
				"path": 0
			}
		],
		[
			"Terra do Nunca",
			"Perder sombra por acerto inimigo também remove um efeito negativo, após o impacto.",
			{
				"path": 1
			}
		],
		[
			"Devolva Minha Sombra",
			"Ao atacar inimigo que removeu uma sombra dele naquela rodada, 50% de chance de recuperar uma sombra, até o limite três.",
			{
				"path": 2
			}
		],
		[
			"Peter Pan",
			"Cada sombra causa 25% do Dano Mágico como dano mágico + 15% como dano real. Sob ult: 40% mágico + 15% real.",
			{
				"path": 3
			}
		]
	],
	"puss": [
		[
			"Lâmina Desesperada",
			"Com 25% de vida ou menos, básicos acertam um segundo inimigo com 50% do dano do golpe principal. Sem segundo alvo, o golpe adicional atinge o primeiro.",
			{
				"path": 0
			}
		],
		[
			"Ainda Tenho Garras",
			"Uma vez por estágio inteiro, dano fatal o deixa com um PV; sua vida não cai abaixo disso até o início da próxima vez. Não é imunidade a controle. Uso compartilhado entre as seis fases do estágio.",
			{
				"path": 1
			}
		],
		[
			"Pequeno, Mas Não Menor",
			"+25% de dano contra todos os chefes, incluindo secundários, de estágio e secretos.",
			{
				"path": 2
			}
		],
		[
			"O Gato de Botas",
			"Até nove retornos na run, com 20% da vida máxima. Chances sucessivas: 100%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%. Falha resulta em morte normal. Reviver preserva mana e limpa condições negativas. Ressurreição externa não reinicia as chances.",
			{
				"path": 3
			}
		]
	]
}
static func id_for(hero: String, index: int) -> String:
	return "blessing:%s:%d"%[hero,index]
static func data(id: String) -> Dictionary:
	var parts:=id.split(":")
	if parts.size()!=3 or parts[0]!="blessing" or not PATHS.has(parts[1]) or not parts[2].is_valid_int():return {}
	var i:=int(parts[2])
	if i<0 or i>3:return {}
	return {"id":id,"hero":parts[1],"index":i,"title":PATHS[parts[1]][i][0],"detail":PATHS[parts[1]][i][1],"effects":PATHS[parts[1]][i][2].duplicate()}
static func unlocked(campaign, id: String) -> bool:
	var d:=data(id)
	if d.is_empty():return false
	var p:Dictionary=campaign.hero_milestones.get(d.hero,{})
	match int(d.index):
		0:return true
		1:return bool(p.get("feat",false))
		2:return bool(p.get("secret",false))
		3:return bool(p.get("win",false))
	return false
static func mission(_campaign,id:String) -> String:
	var d:=data(id)
	if d.is_empty():return ""
	return Roster.BOONS[d.hero][int(d.index)][2]
static func record(campaign, owner: Dictionary, won:=false) -> Array[String]:
	var newly:Array[String]=[]
	for hero in PATHS:
		var before:Array[bool]=[]
		for i in 4:before.append(unlocked(campaign,id_for(hero,i)))
		var p:Dictionary=campaign.hero_milestones.get(hero,{"rooms":0,"secret":false,"win":false,"feat":false})
		if not p.has("feat"):p["feat"]=false
		# A per-run watermark makes checkpoint saves and terminal resolution idempotent.
		var key:="%d:%s"%[owner.get("run_id",0),hero]
		var current:=int(owner.get("hero_room_counts",{}).get(hero,0))
		var credited:=int(campaign.blessing_credit.get(key,0))
		p.rooms=mini(12,int(p.get("rooms",0))+maxi(0,current-credited))
		campaign.blessing_credit[key]=maxi(current,credited)
		if owner.get("secret_defeated",[]).has(hero) and owner.get("secret_survivors",[]).has(hero):p.secret=true
		if hero in ["joao","maria"] and owner.get("secret_defeated",[]).any(func(id):return id in ["joao","maria"]) and owner.get("hero_ids",[]).has(hero):
			var at:int=owner.hero_ids.find(hero)
			if at<owner.get("health",[]).size() and float(owner.health[at])>0:p.secret=true
		if won and owner.get("leader","")==hero:p.win=true
		var feats:Dictionary=owner.get("unlock_stats",{}).get("boon_feats",{}).get(hero,{}).duplicate()
		feats.merge(owner.get("ability_state",{}).get(hero,{}).get("boon_feats",{}),true)
		var conditions:Dictionary={"scarlet":"nine_targets","snow_white":"defense_100","rapunzel":"shield_200","mulan":"two_columns","ariel":"five_hits","joao":"witch_siblings","maria":"witch_siblings","alice":"two_conditions","puss":"low_life_win","matches":"all_burn","peter":"three_shadows"}
		if feats.get(conditions.get(hero,""),false):p["feat"]=true
		if won and hero=="aladin" and owner.get("hero_ids",[]).has(hero):
			var state:Dictionary=owner.get("ability_state",{}).get(hero,{})
			if state.get("wishes",[]).size()<3:p["feat"]=true
		campaign.hero_milestones[hero]=p
		for i in range(1,4):
			if not before[i] and unlocked(campaign,id_for(hero,i)):newly.append(id_for(hero,i))
	# Old run watermarks can be pruned once a new run has started.
	for key in campaign.blessing_credit.keys():
		if int(str(key).get_slice(":",0))<int(owner.get("run_id",0)):campaign.blessing_credit.erase(key)
	return newly
