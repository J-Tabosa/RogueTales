class_name ExpeditionContent
extends RefCounted
## Data for runs. Permanent training never changes these starting kits.
const RECRUIT_CHANCE := 0.25
const BOSSES := [3, 7, 11]
const BLESSINGS := {
	"vigor": {"name": "Coração indomável", "detail": "+25% de PV nesta run.", "cost": 0},
	"fury": {"name": "Primeira faísca", "detail": "+18% de dano nesta run.", "cost": 0},
	"echo": {"name": "Eco do destino", "detail": "Comece com 40 de ULT; +3 de energia por acerto.", "cost": 0},
	"thorns": {"name": "Espelho partido", "detail": "Devolva 25% do dano recebido. Requer chegar à fase 4.", "cost": 80},
	"mercy": {"name": "Uma última página", "detail": "Uma vez por run, o protagonista revive com 35% dos PV. Requer chegar à fase 8.", "cost": 140}
}
const KITS := {
	"scarlet": ["Carga de pólvora", "Aplica fogo e pólvora. A terceira carga explode no alvo e respinga nos demais.", "Estilhaços úteis", "Um crítico ativa a passiva e recupera 20 de ULT."],
	"rapunzel": ["Trança vital", "Ataca e cura o aliado vivo mais ferido em 8% dos PV máximos.", "Laço de resgate", "Ao deixar um aliado abaixo de 45% dos PV, ativa a passiva para curá-lo e protegê-lo."],
	"snow_white": ["Maçã amarga", "Aplica veneno acumulável. Acertar um alvo já envenenado também drena vida.", "Semente maldita", "Ao derrotar um alvo envenenado, ativa a passiva para transferir o veneno."],
	"mulan": ["Três movimentos", "O terceiro acerto causa +80% de dano e atinge os outros inimigos da frente.", "Aparo de jade", "Uma guarda com a passiva pronta devolve um corte e concede escudo a Mulan."],
	"ariel": ["Maré que volta", "Cada terceiro acerto cura 12% dos PV de todos os aliados vivos.", "Corrente de retorno", "Ao ferir um aliado abaixo de 50% dos PV, ativa a passiva para curá-lo e atrasar os inimigos."],
	"joao": ["Marca da caçada", "Marca a presa. Seus próximos acertos na mesma presa causam +40% de dano.", "Fogo de cobertura", "Após um aliado acertar sua presa, ativa a passiva para disparar uma flecha adicional."],
	"maria": ["Receita roubada", "Alterna entre aplicar veneno e consumi-lo numa estocada que recupera vida.", "Gota de revanche", "Ao sofrer dano, ativa a passiva para envenenar o agressor."],
	"alice": ["Baralho impossível", "Alterna quatro naipes: dano, cura, escudo e uma segunda carta em outro alvo.", "Carta na manga", "Ao sofrer dano, ativa a passiva para avançar um naipe e ganhar 25 de ULT."],
	"puss": ["Peso do crepúsculo", "Alterna um golpe de preparação com um corte de 240% na vanguarda.", "Guarda das botas", "Se um aliado abaixo de 45% dos PV for atacado, ativa a passiva para receber o golpe."],
	"matches": ["Fósforo vivo", "Incendeia a retaguarda. O fogo fica mais forte em alvos já incendiados.", "Incêndio em cadeia", "Quando um inimigo incendiado cai, ativa a passiva para espalhar fogo aos sobreviventes."],
	"peter": ["Lâmina sem sombra", "Consome até três sombras; cada uma acrescenta 60% de dano ao golpe.", "Reflexo do outro lado", "Uma esquiva ativa a passiva, cria uma sombra e responde com um contra-ataque."],
	"aladin": ["Desejo rotativo", "Alterna entre dano de 170%, escudo para o grupo e cura para o grupo.", "Lâmpada de reserva", "Quando um escudo aliado se rompe, ativa a passiva para recuperar energia para o grupo."]
}
## Each option changes an actual mechanic. One copy per hero per run.
const MUTATIONS := {
	"scarlet": [["spread", "Pavio compartilhado", "A explosão espalha queimadura a todos."], ["quick", "Pólvora instável", "A pólvora explode com duas cargas."], ["shelter", "Abrigo de fumaça", "Cada explosão concede 12% de escudo ao grupo."]],
	"rapunzel": [["twin", "Trança dupla", "A cura ativa também alcança um segundo aliado."], ["barrier", "Fios de abrigo", "Sua cura ativa também concede 8% de escudo."], ["rescue", "Ninguém fica para trás", "O resgate reage abaixo de 65% dos PV e cura o dobro."]],
	"snow_white": [["stack", "Receita concentrada", "O veneno aplicado ganha o dobro de intensidade."], ["harvest", "Colheita vermelha", "Drenar um alvo envenenado cura também o aliado mais ferido."], ["seed", "Pomar proibido", "Semente maldita transfere o veneno a todos os sobreviventes."]],
	"mulan": [["quick", "Segundo movimento", "O combo acontece a cada dois acertos."], ["dragon", "Rastro de jade", "O combo alcança também a retaguarda."], ["guard", "Estandarte protetor", "Seu aparo concede escudo também aos aliados."]],
	"ariel": [["quick", "Maré curta", "A cura coletiva acontece a cada dois acertos."], ["tide", "Ressaca abissal", "Uma cura coletiva também atrasa os inimigos."], ["overflow", "Espuma protetora", "A cura coletiva também concede 10% de escudo."]],
	"joao": [["hunt", "Presa exposta", "A marca também amplifica em 20% o dano dos aliados."], ["pierce", "Virote atravessado", "O disparo de cobertura ignora armadura."], ["relay", "Caçada sem pausa", "Ao abater a presa, a marca passa ao próximo alvo."]],
	"maria": [["feast", "Banquete da bruxa", "Consumir veneno cura também o grupo."], ["keep", "Receita inesgotável", "A estocada consome metade do veneno, preservando o restante."], ["toxic", "Antídoto às avessas", "A revanche também aplica veneno aos outros inimigos."]],
	"alice": [["double", "Mão impossível", "A carta extra acerta todos os outros inimigos."], ["heart", "Rainha de copas", "O naipe de cura alcança todos os aliados."], ["wild", "Coringa", "A cada ciclo completo, recarrega a passiva e ganha 25 mana."]],
	"puss": [["sweep", "Corte do horizonte", "O golpe carregado alcança ambas as linhas."], ["ready", "Lâmina desperta", "Começa cada combate com o golpe pesado pronto."], ["nine", "Mais uma vida", "Uma vez nesta run, sobrevive a um golpe fatal com 30% dos PV."]],
	"matches": [["spread", "Cidade em chamas", "Cada acerto espalha parte do fogo a outro inimigo."], ["fuel", "Combustível proibido", "Incêndios em cadeia também causam dano imediato."], ["ash", "Da cinza ao pavio", "Um inimigo incendiado derrotado concede 25 de ULT."]],
	"peter": [["double", "Sombra gêmea", "Cada reação de esquiva cria duas sombras."], ["veil", "Véu do Nunca", "Consumir sombras concede +20% de esquiva por 4 s."], ["keep", "Sombra teimosa", "Após um golpe com sombras, conserva uma delas."]],
	"aladin": [["generous", "Desejo generoso", "Os desejos de cura e escudo têm efeito dobrado."], ["storm", "Tempestade das dunas", "O desejo de ataque atinge um segundo inimigo."], ["reserve", "Reserva do gênio", "A quebra de escudo também reconstrói 8% de escudo no grupo."]]
}
const ROUTES := {
	"team_event": {"title": "Um encontro nas margens", "detail": "Sua equipe encontra uma página especial. Quem está no grupo muda o diálogo e as opções."},
	"battle": {"title": "Pela trilha", "detail": "Combate comum. Preserve suas forças e avance."},
	"elite": {"title": "Caçadores de tinta", "detail": "Inimigos +35% PV e +15% dano. Vitória: +25 ouro e +10% dano ao grupo."},
	"camp": {"title": "Fogueira nas margens", "detail": "Pague 18 ouro: cure 30% dos PV e levante um aliado com 20%. Depois, avance."},
	"shop": {"title": "Mercador de histórias", "detail": "Gaste o ouro desta run em relíquias e suprimentos antes de avançar."},
	"spring": {"title": "Fonte esquecida", "detail": "Cure 20% dos PV do grupo; perca 12 de ouro da run. Depois, avance."},
	"curse": {"title": "A página proibida", "detail": "+18% de dano, mas −10% de PV máximos nesta run. Depois, avance."},
	"cache": {"title": "Um baú, uma emboscada", "detail": "Ganhe 35 ouro agora; o próximo combate será uma elite."}
}

static func offer(id: String) -> Dictionary:
	var parts := id.split(":")
	if parts.size() != 3 or parts[0] != "skill" or not MUTATIONS.has(parts[1]):
		return {}
	for entry in MUTATIONS[parts[1]]:
		if entry[0] == parts[2]:
			return {"id": id, "title": entry[1], "detail": entry[2], "owner": parts[1]}
	return {}

static func has(actor: Dictionary, mutation: String) -> bool:
	return actor.get("mutations", []).has(mutation)

static func is_boss(stage: int) -> bool:
	return BOSSES.has(stage)
