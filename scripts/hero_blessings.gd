extends RefCounted
## Four paths per protagonist. Progress comes from actual participation, never purchases.
const PATHS := {
	"scarlet":[["Pavio curto","Queimaduras causam +30% de dano.",{"burn_mult":0.30}],["Mira da floresta","Acertos causam +30% de dano contra inimigos abaixo de 35% dos PV.",{"execute":0.30}],["Caçadora do lobo","Acertos reverberam 35% do dano em outro alvo.",{"chain":0.35}],["Pólvora viva","ULT causa +40% de dano e incendeia por 20% do dano/s, durante 5 s.",{"ult_mult":0.40,"fire":0.20}]],
	"rapunzel":[["Fio gentil","Curas feitas por Rapunzel são 20% maiores.",{"heal_mult":0.20}],["Trança protetora","Acertos concedem ao aliado mais ferido escudo de 5% dos PV dele.",{"shield_on_hit":0.05}],["Torre aberta","ULT remove fogo, veneno e selo dos aliados e concede escudo de 10% dos PV.",{"cleanse":true,"ult_group_shield":0.10}],["Cabelo dourado","Curas +40%; cada acerto dá +6 mana.",{"heal_mult":0.40,"mana_hit":6.0}]],
	"snow_white":[["Primeira fórmula","Veneno causado pela Branca causa +30% de dano.",{"poison_mult":0.30}],["Reação em cadeia","Acertos aplicam outra dose de veneno de 12% do dano/s por 5 s.",{"venom":0.12}],["Antídoto real","A Branca cura 12% dos próprios PV sempre que um inimigo morre.",{"kill_heal":0.12}],["Experimento final","ULT +40% de dano; veneno +50%.",{"ult_mult":0.40,"poison_mult":0.50}]],
	"mulan":[["Corte preciso","Ataques causam +15% de dano.",{"attack_mult":0.15}],["Disciplina de jade","Acertos dão +5 mana e escudo de 4% dos PV ao aliado mais ferido.",{"mana_hit":5.0,"shield_on_hit":0.04}],["General liberta","Contra-ataques causam +75% de dano.",{"counter_mult":0.75}],["Dragão desperto","ULT +50% de dano e escudo de 20% dos PV da Mulan.",{"ult_mult":0.50,"ult_shield":0.20}]],
	"ariel":[["Maré preguiçosa","Curas feitas por Ariel são 20% maiores.",{"heal_mult":0.20}],["Ressaca","Acertos atrasam ataques inimigos em 15% por 3 s.",{"slow":3.0}],["Maré livre","ULT concede escudo de 15% dos PV para todos os aliados.",{"ult_group_shield":0.15}],["Mar em ebulição","A água incendeia: acertos e ULT aplicam 20% do dano/s por 5 s.",{"fire":0.20}]],
	"joao":[["Bengala afiada","Ataques causam +15% de dano.",{"attack_mult":0.15}],["Herança rubra","Acertos reverberam 25% do dano em outro inimigo.",{"chain":0.25}],["Duelo do duque","+40% de dano contra alvos abaixo de 35% dos PV.",{"execute":0.40}],["Seis saudações","ULT +50% de dano e +6 mana por acerto.",{"ult_mult":0.50,"mana_hit":6.0}]],
	"maria":[["Safra venenosa","Veneno da Maria causa +30% de dano.",{"poison_mult":0.30}],["Brinde da casa","Cada acerto cura Maria em 8% do dano causado.",{"drain":0.08}],["Taça da condessa","Quando um inimigo morre, Maria recupera 12% dos próprios PV.",{"kill_heal":0.12}],["Banquete sombrio","A maldição concede escudo de 10% dos PV à equipe; ataques envenenam em 15% do dano/s por 5 s.",{"ult_group_shield":0.10,"venom":0.15}]],
	"alice":[["Carta na manga","Ataques causam +10% de dano. Alice continua sem mana.",{"attack_mult":0.10}],["Baralho duplo","Acertos reverberam 30% do dano em outro alvo.",{"chain":0.30}],["Queda da rainha","ULT +35% de dano e limpa condições negativas dos aliados.",{"ult_mult":0.35,"cleanse":true}],["Todos os naipes","ULT +50% de dano e ataques +15%. O cortejo continua a cada quatro ataques.",{"ult_mult":0.50,"attack_mult":0.15}]],
	"puss":[["Espada no ombro","Começa cada combate com escudo de 15% dos PV.",{"shield_start":0.15}],["Lâmina pesada","+30% de dano contra alvo abaixo de 35% dos PV; reflete 15% do dano recebido.",{"execute":0.30,"reflect":0.15}],["Dívida encerrada","A ULT dá escudo adicional de 30% dos PV do Gato.",{"ult_shield":0.30}],["Nove despedidas","ULT +50% de dano; mortes inimigas curam 8% dos PV do Gato.",{"ult_mult":0.50,"kill_heal":0.08}]],
	"matches":[["Fósforo teimoso","Queimaduras da Vendedora causam +50% de dano.",{"burn_mult":0.50}],["Calor amigo","Acertos dão ao aliado mais ferido escudo de 5% dos PV.",{"shield_on_hit":0.05}],["Brasa roubada","Queimaduras +80%; +5 mana por acerto.",{"burn_mult":0.80,"mana_hit":5.0}],["Uma chama chama outra","Se um aliado incendiar, a Vendedora faz um ataque extra de 60% do dano. Recarga 2 s; não encadeia outro ataque.",{"follow_burn":0.60}]],
	"peter":[["Sombra leve","Ataques causam +15% de dano.",{"attack_mult":0.15}],["Brincadeira azul","Contra-ataques causam +50% de dano; cada acerto dá +4 mana.",{"counter_mult":0.50,"mana_hit":4.0}],["Âncora partida","Inicia combates com escudo de 25% dos PV; ULT concede mais 20%.",{"shield_start":0.25,"ult_shield":0.20}],["Terra do nunca","Acertos reverberam 40% do dano e curam Peter em 8% do dano causado.",{"chain":0.40,"drain":0.08}]],
	"aladin":[["Primeiro desejo","Curas feitas por Aladin são 20% maiores.",{"heal_mult":0.20}],["Lâmpada generosa","Cada acerto dá +6 mana.",{"mana_hit":6.0}],["Areias livres","ULT concede escudo extra de 15% dos PV para a equipe e limpa condições negativas.",{"ult_group_shield":0.15,"cleanse":true}],["Desejo impossível","O desejo sonolento concede escudo de 15% dos PV à equipe; curas +40%.",{"ult_group_shield":0.15,"heal_mult":0.40}]]
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
		1:return int(p.get("rooms",0))>=12
		2:return bool(p.get("secret",false))
		3:return bool(p.get("win",false))
	return false
static func mission(campaign, id: String) -> String:
	var d:=data(id)
	if d.is_empty():return ""
	var p:Dictionary=campaign.hero_milestones.get(d.hero,{})
	match int(d.index):
		0:return "Disponível desde o início."
		1:return "Vença 12 fases com este personagem vivo: %d / 12."%mini(12,int(p.get("rooms",0)))
		2:return "Vença o chefe secreto deste personagem com ele vivo."
		3:return "Conclua os 12 mundos com este personagem vivo na equipe."
	return ""
static func record(campaign, owner: Dictionary, won:=false) -> Array[String]:
	var newly:Array[String]=[]
	for hero in PATHS:
		var before:Array[bool]=[]
		for i in 4:before.append(unlocked(campaign,id_for(hero,i)))
		var p:Dictionary=campaign.hero_milestones.get(hero,{"rooms":0,"secret":false,"win":false})
		# A per-run watermark makes checkpoint saves and terminal resolution idempotent.
		var key:="%d:%s"%[owner.get("run_id",0),hero]
		var current:=int(owner.get("hero_room_counts",{}).get(hero,0))
		var credited:=int(campaign.blessing_credit.get(key,0))
		p.rooms=mini(12,int(p.get("rooms",0))+maxi(0,current-credited))
		campaign.blessing_credit[key]=maxi(current,credited)
		if owner.get("secret_defeated",[]).has(hero) and owner.get("secret_survivors",[]).has(hero):p.secret=true
		if won and owner.get("hero_ids",[]).has(hero):
			for i in owner.get("hero_ids",[]).size():
				if owner.hero_ids[i]==hero and i<owner.get("health",[]).size() and owner.health[i]>0:p.win=true
		campaign.hero_milestones[hero]=p
		for i in range(1,4):
			if not before[i] and unlocked(campaign,id_for(hero,i)):newly.append(id_for(hero,i))
	# Old run watermarks can be pruned once a new run has started.
	for key in campaign.blessing_credit.keys():
		if int(str(key).get_slice(":",0))<int(owner.get("run_id",0)):campaign.blessing_credit.erase(key)
	return newly
