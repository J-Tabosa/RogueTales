class_name ExpeditionContent
extends RefCounted
## Data for runs. Permanent training never changes these starting kits.
const WORLD_COUNT := 12
const PHASES_PER_WORLD := 6
const TOTAL_PHASES := 72
const WORLD_FORMAT := 2
const RECRUIT_CHANCE := 0.25
const BOSSES := [3, 7, 11]
const BLESSINGS := {
	"vigor": {"name": "Coração indomável", "detail": "+25% de PV nesta run.", "cost": 0},
	"fury": {"name": "Primeira faísca", "detail": "+18% de dano nesta run.", "cost": 0},
	"echo": {"name": "Eco do destino", "detail": "Comece com 40 de ULT; +3 de energia por acerto.", "cost": 0},
	"thorns": {"name": "Espelho partido", "detail": "Devolva 25% do dano recebido. Requer chegar à fase 4.", "cost": 80},
	"mercy": {"name": "Uma última página", "detail": "Uma vez por run, o protagonista revive com 35% dos PV. Requer chegar à fase 8.", "cost": 140}
}
const KITS = {
	"scarlet": [
		"Bombas Caseiras",
		"Bombas Caseiras: causa 100% do Dano Físico em um alvo. Pode critar. Não tem espalhamento natural na ficha final.",
		"Espalhando Pólvora",
		"Espalhando Pólvora: cada alvo acertado por um ataque recebe uma carga, até dez por alvo. Crítico não concede carga adicional naturalmente. Cada carga aumenta em 10% o dano da Scarlet contra aquele alvo, até +100%. A pólvora não explode automaticamente; desaparece no fim do combate."
	],
	"alice": [
		"4 Naipes",
		"4 Naipes: básico causa 100% do Dano Físico + 100% do Dano Mágico em um alvo e avança um naipe.",
		"Baralho Mágico",
		"Baralho Mágico: não usa mana. Cada básico executado concede uma carga em um contador único. A cada quatro cargas, consome quatro e ativa a ult, continuando os ataques restantes. Espalhamento não concede cargas extras. Contador e próximo naipe permanecem entre combates."
	],
	"snow_white": [
		"Minerando",
		"Minerando: básico de 100% do Dano Físico em um alvo.",
		"Quebrando Barreiras",
		"Quebrando Barreiras: básicos causam +100% de dano contra escudos. O dano adicional exclusivo contra escudo não se transforma em dano à vida ao quebrá-lo. A ult também recebe esse benefício, apesar da descrição original usar o nome antigo Rompe-Barreiras."
	],
	"ariel": [
		"Correntes Dançantes",
		"Correntes Dançantes: 100% do Dano Mágico no alvo inicial. Cada salto testa individualmente 50% de chance de continuar, até dois saltos naturais, de 60% e 40%. Falhar encerra a corrente. Não repete alvos naquele básico.",
		"Águas Curativas",
		"Águas Curativas: cada inimigo acertado pelo básico, inclusive por ricochete, cura o aliado vivo com menor porcentagem de vida em 15% do Dano Mágico. Reavalia o beneficiário após cada impacto. Cada acerto também gera dez de mana."
	],
	"rapunzel": [
		"Casulo de Seda",
		"Casulo de Seda: concede a si e ao outro aliado vivo com menor porcentagem de vida escudo de 100% do Dano Mágico. Enquanto Silk tiver escudo criado por ela, ataques inimigos que a acertam provocam retaliação de 50% do Dano Mágico. Inclui o golpe que quebra o escudo. Não é uma ação ofensiva direta.",
		"Fios Entrelaçados",
		"Passiva sem nome final: aliados com escudos criados por Silk recebem 10% menos dano. Beneficia a própria Silk, não acumula e vale também no golpe que quebra a proteção."
	],
	"mulan": [
		"Três Ataques",
		"Três Ataques: 100% do Dano Físico em um alvo; cada terceiro básico executado causa 150%. Contador permanece entre turnos e combates. Contra-ataques e ults não avançam o contador.",
		"Contra-Ataque",
		"Contra-Ataque: ao esquivar de ataque direto, responde com 60% do Dano Físico. Pode critar; não gera mana. Uma ativação entre suas próprias vezes, renovada no início da vez dela."
	],
	"maria": [
		"Veneno Líquido",
		"Veneno Líquido: 100% do Dano Mágico em um alvo, podendo critar se adquirir chance. Aplica uma dose de veneno.",
		"Acumulando Toxinas",
		"Acumulando Toxinas: até três doses por alvo. Cada dose causa 10% do Dano Mágico como dano real no início da vez do alvo, durante dois turnos. Reaplicar renova a duração. Veneno não critica nem gera mana pelo dano periódico."
	],
	"joao": [
		"Perfuração de Açúcar",
		"Perfuração de Açúcar: 100% do Dano Físico em um alvo, podendo critar.",
		"Marca do Duelista",
		"Marca do Duelista: primeiro básico acertado marca o inimigo. Básicos seguintes contra essa presa causam 120%. Marca permanece até a presa morrer ou João trocar de alvo. Apenas básicos aplicam."
	],
	"matches": [
		"Lançar Faíscas",
		"Lançar Faíscas: 50% do Dano Mágico em um alvo, aplicando Queimadura de 100% do Dano Mágico como dano real de fogo no início da vez do inimigo, por dois turnos.",
		"Incêndio Amador",
		"Incêndio Amador: impacto direto de básico ou ult contra alvo já incendiado acrescenta dez pontos percentuais do Dano Mágico à potência do fogo, até 150%, e renova a duração. Dano periódico e explosões não fortalecem a queimadura."
	],
	"aladin": [
		"Energia Genial",
		"Energia Genial: rajada de 100% do Dano Mágico em um alvo. Pode critar ao adquirir chance.",
		"Poder Engarrafado",
		"Poder Engarrafado: +10% de Dano Mágico por desejo disponível: +30%, +20%, +10%, zero. Conta desejos restantes, não desejos já gastos."
	],
	"peter": [
		"Lâmina Sem Sombra",
		"Básico — Lâmina Sem Sombra (nome proposto): 100% do Dano Mágico no alvo. Cada sombra acompanha com um golpe separado de 15% do Dano Mágico. Atacar não consome sombras. Cada golpe calcula seu próprio crítico ×3. Golpes das sombras não geram mana ou novas cópias de ataques.",
		"Sombras do Nunca",
		"Passiva de sombras: cada esquiva de ataque direto concede uma sombra, até três. Cada impacto direto acertado remove uma sombra, se houver; Peter recebe o dano normalmente. Sombras não bloqueiam, não concedem redução e não são escudos. Dano periódico não gera ou remove sombras."
	],
	"puss": [
		"Corte Brutal",
		"Básico — Corte Brutal (nome proposto): 100% do Dano Físico em um alvo; pode critar.",
		"Fúria do Pequeno Gigante",
		"Passiva — Fúria do Pequeno Gigante (nome proposto): +1% de Dano Físico por 1% de vida máxima faltando. Recalcula com a vida atual; curar reduz o bônus. Não usa quantidade absoluta de PV perdidos."
	]
}
## Obsolete mutations no longer enter the reward pool.
const MUTATIONS = {
	"scarlet": [],
	"alice": [],
	"snow_white": [],
	"ariel": [],
	"rapunzel": [],
	"mulan": [],
	"maria": [],
	"joao": [],
	"matches": [],
	"aladin": [],
	"peter": [],
	"puss": []
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

static func is_boss(stage: int, phase: int = -1) -> bool:
	return phase == PHASES_PER_WORLD - 1 if phase >= 0 else BOSSES.has(stage)

static func enemy_limit(stage: int, endless := false) -> int:
	# Stages are zero-based. Endless continues after the campaign, even when
	# its scenery cycles back to the first world.
	return 9 if endless else mini(9, (maxi(0, stage) + 1) * 3)

static func boss_rule(world: int) -> int:
	return [3, 3, 7, 3, 3, 7, 11, 7, 11, 7, 3, 11][clampi(world, 0, 11)]

static func location(data: Dictionary) -> Vector2i:
	var old := int(data.get("stage", 0))
	return Vector2i(clampi(old, 0, 11), clampi(int(data.get("phase", 0)), 0, 5)) if int(data.get("world_format", 1)) >= WORLD_FORMAT else Vector2i(clampi(old / 6, 0, 11), old % 6)

static func location_label(data: Dictionary) -> String:
	var at := location(data)
	return "Mundo %02d / 12 · Fase %d / 6" % [at.x + 1, at.y + 1]
