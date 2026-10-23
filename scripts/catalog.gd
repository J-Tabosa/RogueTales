class_name TaleCatalog
extends RefCounted
## Campaign content and balance. All text and numbers can be changed here.
const CHAPTER_COUNT := 12
const FINAL_CHAPTER := CHAPTER_COUNT - 1
const PARTY_LIMIT := 3
const NEW_HERO_IDS = ["joao", "maria", "alice", "puss", "matches", "peter", "aladin"]
const CLASSES = {
	"vanguard": {"name": "Vanguarda", "rule": "Ataca a frente; alcança a retaguarda quando a frente cai.", "evasion": 0.04},
	"ranger": {"name": "Atirador", "rule": "Prioriza a retaguarda; usa a frente se ela estiver vazia.", "evasion": 0.10},
	"mage": {"name": "Mago", "rule": "Alcança ambas as linhas; magia ignora 65% da armadura.", "evasion": 0.04},
	"assassin": {"name": "Assassino", "rule": "Avança à retaguarda mais ferida; 35% de esquiva.", "evasion": 0.35},
	"artificer": {"name": "Artilheira", "rule": "Alcança ambas as linhas e prioriza a menor armadura.", "evasion": 0.08}
}
const HERO_TACTICS = {
	"scarlet": {"class": "artificer", "row": "back", "ult": "Final explosivo", "detail": "Explode todos os inimigos (200%) e aplica queimadura."},
	"rapunzel": {"class": "assassin", "row": "front", "ult": "Coroa de fios", "detail": "Cura 35% dos PV e concede 20% de escudo a todas as aliadas vivas."},
	"snow_white": {"class": "ranger", "row": "back", "ult": "Maçã da sentença", "detail": "Disparo de 400% na retaguarda e veneno fortalecido."},
	"mulan": {"class": "vanguard", "row": "front", "ult": "Dragão de jade", "detail": "Corte de 320% na linha de frente e escudo de 35% para si."},
	"ariel": {"class": "mage", "row": "back", "ult": "Sinfonia abissal", "detail": "Maré de 160% em todos; cura 20% do grupo e desacelera por 5 s."},
	"joao": {"class": "assassin", "row": "back", "ult": "Caçada cruzada", "detail": "Rajada de 420% no alvo da retaguarda."},
	"maria": {"class": "assassin", "row": "front", "ult": "Receita da bruxa", "detail": "Estocada de 280% e veneno fortalecido por 6 s."},
	"alice": {"class": "mage", "row": "back", "ult": "Cortejo das cartas", "detail": "Cartas mágicas atingem todos os inimigos (200%)."},
	"puss": {"class": "vanguard", "row": "front", "ult": "Nove vidas, um corte", "detail": "Corte de 360% na vanguarda e escudo de 25% para si."},
	"matches": {"class": "ranger", "row": "back", "ult": "Último fósforo", "detail": "Disparo de 400% na retaguarda e queimadura por 5 s."},
	"peter": {"class": "assassin", "row": "front", "ult": "Passo do outro lado", "detail": "Estocada de 300% na retaguarda e +25% de esquiva por 5 s."},
	"aladin": {"class": "mage", "row": "back", "ult": "Três desejos", "detail": "Magia de 200% em todos; cura e escudo de 15% para o grupo."}
}
const HERO_SCENES = {
	"scarlet": preload("res://scenes/heroes/scarlet.tscn"),
	"rapunzel": preload("res://scenes/heroes/rapunzel.tscn"),
	"snow_white": preload("res://scenes/heroes/snow_white.tscn"),
	"mulan": preload("res://scenes/heroes/mulan.tscn"),
	"ariel": preload("res://scenes/heroes/ariel.tscn"),
	"joao": preload("res://scenes/heroes/joao.tscn"),
	"maria": preload("res://scenes/heroes/maria.tscn"),
	"alice": preload("res://scenes/heroes/alice.tscn"),
	"puss": preload("res://scenes/heroes/puss.tscn"),
	"matches": preload("res://scenes/heroes/matches.tscn"),
	"peter": preload("res://scenes/heroes/peter.tscn"),
	"aladin": preload("res://scenes/heroes/aladin.tscn"),
}
const HEROES = {
	"scarlet":
	{
		"name": "Scarlet",
		"role": "Explosão • queimadura",
		"hp": 200.0,
		"damage": 24.0,
		"interval": 1.7,
		"color": Color("edb17e"),
		"bio":
		"Uma cesta de pólvora e nenhuma vontade de seguir o caminho que escreveram para ela.",
		"skills":
		[
			["Pólvora refinada", "+18% de dano por nível"],
			["Pavio persistente", "+2 de queimadura/s por nível"],
			["Estilhaços", "+4% de chance crítica por nível"]
		]
	},
	"rapunzel":
	{
		"name": "Rapunzel",
		"role": "Suporte • cura",
		"hp": 180.0,
		"damage": 21.0,
		"interval": 1.9,
		"color": Color("c4a2ed"),
		"bio": "Seus fios não prendem mais ninguém. Agora são pontes para quem ficou para trás.",
		"skills":
		[
			["Trança restauradora", "+3 de cura ao grupo a cada 3 golpes"],
			["Raízes fortes", "+18 PV por nível"],
			["Laço protetor", "Inimigos causam −3% de dano por nível"]
		]
	},
	"snow_white":
	{
		"name": "Branca de Neve",
		"role": "Veneno • drenagem",
		"hp": 170.0,
		"damage": 22.0,
		"interval": 1.8,
		"color": Color("eaca82"),
		"bio": "Ela aprendeu a reconhecer venenos. E decidiu devolver alguns ao remetente.",
		"skills":
		[
			["Receita amarga", "+2 de veneno/s por nível"],
			["Colheita vermelha", "+16% de dano por nível"],
			["Doce antídoto", "+2 de autocura por acerto por nível"]
		]
	},
	"mulan":
	{
		"name": "Mulan",
		"role": "Vanguarda • combo",
		"hp": 245.0,
		"damage": 23.0,
		"interval": 1.6,
		"color": Color("9ed4c7"),
		"bio": "Um nome não empunha uma espada. Uma pessoa, sim. Mulan escolhe a própria batalha.",
		"skills":
		[
			["Armadura de jade", "+2 de armadura por nível"],
			["Terceiro corte", "Terceiro golpe ganha +20% de dano por nível"],
			["Passos da garça", "Intervalo de ataque −6% por nível"]
		]
	},
	"ariel":
	{
		"name": "Ariel",
		"role": "Maré • cura",
		"hp": 185.0,
		"damage": 22.0,
		"interval": 1.9,
		"color": Color("85dad4"),
		"bio": "Uma voz que atravessa o mar não vai se calar diante de uma página rasgada.",
		"skills":
		[
			["Canção das marés", "+4 de cura ao grupo a cada 3 golpes"],
			["Corrente contrária", "Intervalo inimigo +6% por nível"],
			["Tridente abissal", "+16% de dano por nível"]
		]
	},
	"joao": {
		"name": "João",
		"role": "Caçador de bruxas",
		"hp": 175.0,
		"damage": 24.0,
		"interval": 1.55,
		"color": Color("8dba8b"),
		"bio": "Um rastro de migalhas ensinou João a nunca perder a trilha. Agora a besta abre caminho para casa.",
		"skills": [["Mira de caçador", "+15% de dano por nível"], ["Olho da floresta", "+4% de chance crítica por nível"], ["Recarga ágil", "Intervalo de ataque −5% por nível"]]
	},
	"maria": {
		"name": "Maria",
		"role": "Lâmina e veneno",
		"hp": 180.0,
		"damage": 23.0,
		"interval": 1.55,
		"color": Color("dc826f"),
		"bio": "Maria não voltou da casa de doces de mãos vazias. A receita mudou de dona.",
		"skills": [["Fio afiado", "+16% de dano por nível"], ["Antídoto roubado", "+2 de autocura por acerto por nível"], ["Gota amarga", "+2 de veneno/s por nível"]]
	},
	"alice": {
		"name": "Alice",
		"role": "Cartomante do caos",
		"hp": 165.0,
		"damage": 25.0,
		"interval": 1.9,
		"color": Color("73c8d9"),
		"bio": "No País das Maravilhas, Alice aprendeu que toda regra pode ser embaralhada.",
		"skills": [["Ás impossível", "+16% de dano por nível"], ["Mão cheia", "+2 de energia por acerto por nível"], ["Casaco do Chapeleiro", "+16 PV por nível"]]
	},
	"puss": {
		"name": "Gato de Botas",
		"role": "Espada do crepúsculo",
		"hp": 250.0,
		"damage": 26.0,
		"interval": 1.9,
		"color": Color("e47b76"),
		"bio": "A espada parece grande demais. O Gato de Botas considera isso um problema dos inimigos.",
		"skills": [["Botas de ferro", "+2 de armadura por nível"], ["Nove vidas", "+20 PV por nível"], ["Peso da lâmina", "+18% de dano por nível"]]
	},
	"matches": {
		"name": "Vendedora de Fósforos",
		"short_name": "Vendedora",
		"role": "Fogo na retaguarda",
		"hp": 170.0,
		"damage": 22.0,
		"interval": 1.6,
		"color": Color("f1aa6b"),
		"bio": "Cada fósforo guarda uma visão. Ela decidiu acender um futuro que ninguém pudesse apagar.",
		"skills": [["Brasa teimosa", "+2 de queimadura/s por nível"], ["Faísca certeira", "+14% de dano por nível"], ["Caixa inesgotável", "+1 de energia por acerto por nível"]]
	},
	"peter": {
		"name": "Peter Pan",
		"role": "Assassino espectral",
		"hp": 175.0,
		"damage": 23.0,
		"interval": 1.45,
		"color": Color("84dbc3"),
		"bio": "Peter deixou a própria sombra atravessar o véu. Ela voltou com caminhos que só ele consegue seguir.",
		"skills": [["Sombra voraz", "+4% de chance crítica por nível"], ["Terra do Nunca", "+14 PV por nível"], ["Passo fantasma", "+2% de esquiva por nível"]]
	},
	"aladin": {
		"name": "Aladin",
		"role": "Desejos e proteção",
		"hp": 185.0,
		"damage": 24.0,
		"interval": 1.95,
		"color": Color("77d3cf"),
		"bio": "Aladin não pede um reino. Prefere um tapete, uma saída e companhia para a viagem.",
		"skills": [["Trama encantada", "A cada 3 acertos, escudo de 3 +2 por nível ao grupo"], ["Lâmpada desperta", "+16% de dano por nível"], ["Vento das dunas", "Intervalo de ataque −5% por nível"]]
	},
}
const UNLOCKS = {
	"snow_white":
	{"goal": 3, "detail": "Vença 3 runs após convocá-la como upgrade.", "unit": "runs vencidas"},
	"rapunzel":
	{
		"goal": 60,
		"detail": "Restaure 60 PV reais com a cura de Rapunzel nas runs.",
		"unit": "PV restaurados"
	},
	"mulan":
	{
		"goal": 8,
		"detail": "Acerte 8 Terceiros cortes com Mulan nas runs.",
		"unit": "combos acertados"
	},
	"ariel":
	{
		"goal": 2,
		"detail": "Vença 2 capítulos diferentes com Ariel viva na equipe.",
		"unit": "capítulos diferentes"
	},
	"joao": {"goal": 20, "detail": "Acerte 20 ataques básicos com João após a convocação nas runs.", "unit": "ataques acertados"},
	"maria": {"goal": 20, "detail": "Acerte 20 ataques básicos com Maria após a convocação nas runs.", "unit": "ataques acertados"},
	"alice": {"goal": 20, "detail": "Acerte 20 ataques básicos com Alice após a convocação nas runs.", "unit": "ataques acertados"},
	"puss": {"goal": 20, "detail": "Acerte 20 ataques básicos com Gato de Botas após a convocação nas runs.", "unit": "ataques acertados"},
	"matches": {"goal": 20, "detail": "Acerte 20 ataques básicos com Vendedora de Fósforos após a convocação nas runs.", "unit": "ataques acertados"},
	"peter": {"goal": 20, "detail": "Acerte 20 ataques básicos com Peter Pan após a convocação nas runs.", "unit": "ataques acertados"},
	"aladin": {"goal": 20, "detail": "Acerte 20 ataques básicos com Aladin após a convocação nas runs.", "unit": "ataques acertados"},
}
const STAGES = [
	{
		"name": "Bosque dos Sussurros",
		"short": "O primeiro fio",
		"enemy": "Lobo de tinta",
		"boss": "O Devorador de Trilhas",
		"hp": 52.0,
		"damage": 8.0,
		"color": Color("78bda0"),
		"sky": Color("142e2b"),
		"biome": 0,
		"intro":
		[
			[
				"Narradora",
				"Os finais desapareceram dos livros. Nas margens, uma assinatura: a Costureira."
			],
			["Scarlet", "Se ela quer um final obediente, escolheu a garota errada."],
			[
				"Voz na torre",
				"Ei, capuz vermelho! Pode cortar esse fio? Ele está apagando o bosque!"
			]
		],
		"outro":
		[
			["Rapunzel", "O bosque era a primeira agulha. Há outras onze prendendo os reinos."],
			["Scarlet", "Então derrubamos uma por uma. Vem comigo?"],
			["Rapunzel", "Com uma condição: ninguém fica preso no próprio conto de novo."]
		]
	},
	{
		"name": "Torre dos Ecos",
		"short": "Uma janela aberta",
		"enemy": "Marionete de seda",
		"boss": "A Guardiã da Janela",
		"hp": 92.0,
		"damage": 12.0,
		"color": Color("b4a1d5"),
		"sky": Color("26223c"),
		"biome": 1,
		"intro":
		[
			["Rapunzel", "A torre repete tudo que eu temia ouvir. Não respondam às vozes."],
			["Voz distante", "Sejam perfeitas. Fiquem quietas. Esperem ser salvas."],
			["Scarlet", "A minha resposta vem com pavio."]
		],
		"outro":
		[
			["Branca de Neve", "Eu seguia as raízes envenenadas. Todas passam por essa torre."],
			["Rapunzel", "Pode nos guiar até o pomar?"],
			["Branca de Neve", "Posso. Mas a fruta mais bonita costuma esconder a pior surpresa."]
		]
	},
	{
		"name": "Pomar do Espelho",
		"short": "O gosto da verdade",
		"enemy": "Espinho encantado",
		"boss": "O Espelho Faminto",
		"hp": 155.0,
		"damage": 17.0,
		"color": Color("cf83a0"),
		"sky": Color("302638"),
		"biome": 2,
		"intro":
		[
			[
				"Branca de Neve",
				"Esse espelho não mostra beleza. Mostra a pessoa que esperam que você seja."
			],
			["Espelho", "Uma princesa sozinha é tão fácil de dobrar."],
			["Scarlet", "Ainda bem que você não sabe contar."]
		],
		"outro":
		[
			[
				"Mulan",
				"Do outro lado do desfiladeiro, um exército sem rosto marcha pelo mesmo fio."
			],
			["Branca de Neve", "E você veio sozinha?"],
			["Mulan", "Vim buscar aliadas. Acho que encontrei."]
		]
	},
	{
		"name": "Desfiladeiro de Jade",
		"short": "Nomes na pedra",
		"enemy": "Soldado de papel",
		"boss": "O General Sem Nome",
		"hp": 210.0,
		"damage": 22.0,
		"color": Color("99c3b1"),
		"sky": Color("1c3036"),
		"biome": 3,
		"intro":
		[
			[
				"Mulan",
				"O general rouba os nomes dos soldados. Sem nome, ninguém lembra por que lutava."
			],
			["Rapunzel", "Vamos lembrar por eles."],
			["Mulan", "Fiquem atrás de mim. Essa ponte ainda vai ver um amanhecer."]
		],
		"outro":
		[
			[
				"Branca de Neve",
				"Os sinos pararam à meia-noite. O palácio está preso entre dois segundos."
			],
			["Mulan", "A ponte está segura. Seguimos juntas até o palácio."],
			["Branca de Neve", "Dessa vez, eu escolho a hora de partir."]
		]
	},
	{
		"name": "Palácio da Meia-noite",
		"short": "Depois da última badalada",
		"enemy": "Vigia de vidro",
		"boss": "O Relógio Partido",
		"hp": 280.0,
		"damage": 27.0,
		"color": Color("a4c9ed"),
		"sky": Color("202a43"),
		"biome": 4,
		"intro":
		[
			[
				"Branca de Neve",
				"O relógio conta arrependimentos, não horas. Quanto mais esperamos, mais forte ele fica."
			],
			["Scarlet", "Por mim, já deu meia-noite faz tempo."],
			["Uma voz do mar", "Quebrem o pêndulo! A próxima agulha está afogando a costa!"]
		],
		"outro":
		[
			["Ariel", "Minha voz abriu um caminho até aqui. O mar não consegue respirar."],
			["Branca de Neve", "Nos leve até ele. Ainda temos tempo."],
			["Ariel", "Então sigam a corrente. Eu seguro a maré."]
		]
	},
	{
		"name": "Santuário das Marés",
		"short": "Uma voz de volta",
		"enemy": "Caranguejo de tinta",
		"boss": "O Leviatã Silencioso",
		"hp": 350.0,
		"damage": 32.0,
		"color": Color("77cdd2"),
		"sky": Color("133441"),
		"biome": 5,
		"intro":
		[
			["Ariel", "A Costureira quer um oceano sem ondas. Um lugar onde nada muda."],
			["Rapunzel", "Uma torre pode ser feita de água também."],
			["Ariel", "Cantem comigo. Mesmo que a voz trema."]
		],
		"outro":
		[
			[
				"Ariel",
				"O mar voltou a contar histórias. Uma delas fala de uma forja sob a montanha."
			],
			["Mulan", "É onde fazem as agulhas."],
			["Scarlet", "Ótimo. Tenho uma discussão urgente com essa fábrica."]
		]
	},
	{
		"name": "Forja das Cinzas",
		"short": "O preço do fio",
		"enemy": "Brasa de carvão",
		"boss": "O Ferreiro de Destinos",
		"hp": 440.0,
		"damage": 37.0,
		"color": Color("ed9c72"),
		"sky": Color("3b242a"),
		"biome": 6,
		"intro":
		[
			[
				"Ferreiro",
				"Ela só queria proteger os finais. Um conto que nunca termina não perde ninguém."
			],
			["Branca de Neve", "E ninguém vive nele."],
			["Branca de Neve", "A última porta está aberta. Vamos terminar isso juntas."]
		],
		"outro":
		[
			["Rapunzel", "Sem a forja, os fios começaram a ceder. O livro original revela quem está puxando os fios."],
			["Mulan", "A Biblioteca do Último Fio."],
			["Scarlet", "Guardem um pouco de coragem. O nosso final ainda não foi escrito."]
		]
	},
	{
		"name": "Biblioteca do Último Fio",
		"short": "O índice roubado",
		"enemy": "Página sem rosto",
		"boss": "A Guardiã do Índice",
		"hp": 540.0,
		"damage": 43.0,
		"color": Color("c7a2e0"),
		"sky": Color("281f3b"),
		"biome": 7,
		"intro":
		[
			["Costureira", "Eu costurei cada perda. Cada despedida. E vocês desfizeram tudo."],
			["Ariel", "Você também costurou nossas vozes."],
			[
				"Scarlet",
				"Não queremos um final perfeito. Queremos poder escolher o próximo capítulo."
			]
		],
		"outro":
		[
			["Costureira", "E se a próxima página doer?"],
			["Rapunzel", "Então ninguém vai precisar lê-la sozinha."],
			[
				"Narradora",
				"O índice revelou quatro agulhas ocultas. O verdadeiro tear ainda espera além dos reinos."
			]
		]
	},
{
	"name": "Pântano dos Reflexos",
	"short": "Entre duas margens",
	"enemy": "Sombra do pomar",
	"boss": "A Rainha das Raízes",
	"hp": 610.0,
	"damage": 44.0,
	"color": Color("7dafa0"),
	"sky": Color("192d30"),
	"biome": 2,
	"intro": [
		[
			"Ariel",
			"Os espelhos desembocam neste pântano. A sombra escolhe quem fica para trás."
		],
		[
			"Mulan",
			"Arqueiros na retaguarda. Protejam quem está lançando magia."
		]
	],
	"outro": [
		[
			"Branca de Neve",
			"Nem todo reflexo merece uma resposta."
		],
		[
			"Rapunzel",
			"A trilha continua acima das nuvens."
		]
	]
},
{
	"name": "Observatório da Aurora",
	"short": "Estrelas que escolhem",
	"enemy": "Vigia celeste",
	"boss": "O Astrônomo Cego",
	"hp": 690.0,
	"damage": 49.0,
	"color": Color("a9a0d8"),
	"sky": Color("222d45"),
	"biome": 1,
	"intro": [
		[
			"Rapunzel",
			"As estrelas também foram costuradas. Só repetem a mesma noite."
		],
		[
			"Scarlet",
			"Vamos fazer uma constelação de estilhaços."
		]
	],
	"outro": [
		[
			"Ariel",
			"Há uma passagem onde a luz toca a areia."
		],
		[
			"Mulan",
			"Sigam a aurora. Eu cubro a frente."
		]
	]
},
{
	"name": "Dunas do Tempo",
	"short": "Nenhum passo perdido",
	"enemy": "Sentinela de vidro",
	"boss": "O Último Pêndulo",
	"hp": 780.0,
	"damage": 54.0,
	"color": Color("dbc38e"),
	"sky": Color("3a3232"),
	"biome": 4,
	"intro": [
		[
			"Branca de Neve",
			"A areia devolve todos os caminhos que não escolhemos."
		],
		[
			"Scarlet",
			"A gente só precisa escolher o próximo."
		]
	],
	"outro": [
		[
			"Mulan",
			"Onze agulhas. Uma porta."
		],
		[
			"Rapunzel",
			"Não importa o que houver do outro lado: vamos juntas."
		]
	]
},
{
	"name": "Coração do Tear",
	"short": "Autoras do amanhã",
	"enemy": "Fio sem destino",
	"boss": "A Costureira dos Finais",
	"hp": 900.0,
	"damage": 60.0,
	"color": Color("d2afd9"),
	"sky": Color("30263d"),
	"biome": 7,
	"intro": [
		[
			"Costureira",
			"Sem meus fios, nada impede a próxima perda."
		],
		[
			"Ariel",
			"Você pode pedir companhia. Não precisa aprisionar o mundo."
		],
		[
			"Scarlet",
			"Devolva a página. O final é nosso."
		]
	],
	"outro": [
		[
			"Costureira",
			"E se a próxima página doer?"
		],
		[
			"Rapunzel",
			"Então ninguém vai precisar lê-la sozinha."
		],
		[
			"Narradora",
			"As doze agulhas caíram. O livro abriu em branco: havia espaço para todos os amanhãs."
		]
	]
}
]
const RELICS = [
	{"id": "power", "title": "Pena de rebeldia", "detail": "+20% de dano para a formação"},
	{"id": "heart", "title": "Página de abrigo", "detail": "+25 PV máximos e cura 40 por aliada"},
	{"id": "haste", "title": "Ponteiro solto", "detail": "Intervalos de ataque −12%"},
	{"id": "critical", "title": "Olho de vidro", "detail": "+12% de chance crítica"},
	{"id": "leech", "title": "Fio de vida", "detail": "Cada acerto cura 3 PV da atacante"},
	{"id": "armor", "title": "Capa do crepúsculo", "detail": "+3 de armadura por aliada"},
]


static func hero_stats(
	id: String, levels: Array, choices: Dictionary, hero_level: int = 1
) -> Dictionary:
	var data: Dictionary = HEROES[id]
	var result := {
		"id": id,
		"max_hp": float(data.hp),
		"damage": float(data.damage),
		"interval": float(data.interval),
		"crit": 0.08,
		"armor": 0.0,
		"leech": 0.0,
		"ranks": levels.duplicate(),
		"hits": 0,
		"shield": 0.0,
		"class": HERO_TACTICS[id]["class"],
		"row": HERO_TACTICS[id].row,
		"evasion": CLASSES[HERO_TACTICS[id]["class"]].evasion,
		"energy": 0.0,
		"energy_bonus": 0.0
	}
	for choice in choices.values():
		if choice == "hope":
			result.max_hp += 5.0
		elif choice == "power":
			result.damage += 1.0
	match id:
		"scarlet":
			result.damage *= 1.0 + levels[0] * 0.18
			result.crit += levels[2] * 0.04
		"rapunzel":
			result.max_hp += levels[1] * 18.0
		"snow_white":
			result.damage *= 1.0 + levels[1] * 0.16
			result.leech = 1.0 + levels[2] * 2
		"mulan":
			result.armor = 2.0 + levels[0] * 2
			result.interval *= pow(0.94, levels[2])
		"ariel":
			result.damage *= 1.0 + levels[2] * 0.16
		"joao":
			result.damage *= 1.0 + levels[0] * 0.15
			result.crit += levels[1] * 0.04
			result.interval *= pow(0.95, levels[2])
		"maria":
			result.damage *= 1.0 + levels[0] * 0.16
			result.leech = levels[1] * 2.0
		"alice":
			result.damage *= 1.0 + levels[0] * 0.16
			result.energy_bonus = levels[1] * 2.0
			result.max_hp += levels[2] * 16.0
		"puss":
			result.armor = 3.0 + levels[0] * 2.0
			result.max_hp += levels[1] * 20.0
			result.damage *= 1.0 + levels[2] * 0.18
		"matches":
			result.damage *= 1.0 + levels[1] * 0.14
			result.energy_bonus = float(levels[2])
		"peter":
			result.crit += levels[0] * 0.04
			result.max_hp += levels[1] * 14.0
			result.evasion = minf(0.55, result.evasion + levels[2] * 0.02)
		"aladin":
			result.damage *= 1.0 + levels[1] * 0.16
			result.interval *= pow(0.95, levels[2])
	result.max_hp *= 1.0 + 0.06 * (clampi(hero_level, 1, 30) - 1)
	result.damage *= 1.0 + 0.04 * (clampi(hero_level, 1, 30) - 1)
	result["hp"] = result.max_hp
	return result


static func offer_data(id: String) -> Dictionary:
	if id.begins_with("skill:"):
		return ExpeditionContent.offer(id)
	if id.begins_with("ally:"):
		var hero_id := id.trim_prefix("ally:")
		if HEROES.has(hero_id):
			return {
				"id": id,
				"hero": hero_id,
				"title": "Convocar " + str(HEROES[hero_id].name),
				"detail": "Luta ao seu lado até o fim desta run."
			}
	for relic in RELICS:
		if relic.id == id:
			return relic
	return {}


static func hero_class_name(id: String) -> String:
	var job: String = HERO_TACTICS[id]["class"]
	if id not in ["joao","puss","peter","aladin"]:
		if job == "mage": return "Maga"
		if job == "assassin": return "Assassina"
		if job == "ranger": return "Atiradora"
	return str(CLASSES[job].name)
