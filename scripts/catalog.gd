class_name TaleCatalog
extends RefCounted
## Campaign content and balance. All text and numbers can be changed here.
const HERO_SCENES = {
	"scarlet": preload("res://scenes/heroes/scarlet.tscn"),
	"rapunzel": preload("res://scenes/heroes/rapunzel.tscn"),
	"snow_white": preload("res://scenes/heroes/snow_white.tscn"),
	"mulan": preload("res://scenes/heroes/mulan.tscn"),
	"cinderella": preload("res://scenes/heroes/cinderella.tscn"),
	"ariel": preload("res://scenes/heroes/ariel.tscn"),
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
	"cinderella":
	{
		"name": "Cinderela",
		"role": "Barreira • crítico",
		"hp": 175.0,
		"damage": 25.0,
		"interval": 1.8,
		"color": Color("b6d8f2"),
		"bio":
		"O relógio já não decide quando ela deve partir. Seus cristais protegem as novas companheiras.",
		"skills":
		[
			["Carruagem de cristal", "+8 de escudo a cada aliada por encontro"],
			["Prisma afiado", "+18% de dano por nível"],
			["Meia-noite", "+4% de chance crítica por nível"]
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
			["Corrente contrária", "Inimigos atacam 6% mais devagar por nível"],
			["Tridente abissal", "+16% de dano por nível"]
		]
	},
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
		"recruit": "rapunzel",
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
			["Rapunzel", "Minha torre era a primeira agulha. Há outras sete prendendo os reinos."],
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
		"recruit": "snow_white",
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
		"recruit": "mulan",
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
		"recruit": "cinderella",
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
				"Cinderela",
				"Os sinos pararam à meia-noite. Meu reino está preso entre dois segundos."
			],
			["Mulan", "Seu escudo de cristal segurou a ponte. Você vem conosco."],
			["Cinderela", "Dessa vez, eu escolho a hora de partir."]
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
		"recruit": "ariel",
		"intro":
		[
			[
				"Cinderela",
				"O relógio conta arrependimentos, não horas. Quanto mais esperamos, mais forte ele fica."
			],
			["Scarlet", "Por mim, já deu meia-noite faz tempo."],
			["Uma voz do mar", "Quebrem o pêndulo! A próxima agulha está afogando a costa!"]
		],
		"outro":
		[
			["Ariel", "Minha voz abriu um caminho até aqui. O mar não consegue respirar."],
			["Cinderela", "Nos leve até ele. Ainda temos tempo."],
			["Ariel", "Então sigam a corrente. Eu seguro a maré."]
		]
	},
	{
		"name": "Santuário das Marés",
		"short": "Uma voz de volta",
		"enemy": "Afogado de tinta",
		"boss": "O Leviatã Silencioso",
		"hp": 350.0,
		"damage": 32.0,
		"color": Color("77cdd2"),
		"sky": Color("133441"),
		"biome": 5,
		"recruit": "",
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
		"recruit": "",
		"intro":
		[
			[
				"Ferreiro",
				"Ela só queria proteger os finais. Um conto que nunca termina não perde ninguém."
			],
			["Branca de Neve", "E ninguém vive nele."],
			["Cinderela", "A última porta está aberta. Vamos terminar isso juntas."]
		],
		"outro":
		[
			["Rapunzel", "Sem a forja, os fios começaram a ceder. Só falta o livro original."],
			["Mulan", "A Biblioteca do Último Fio."],
			["Scarlet", "Guardem um pouco de coragem. O nosso final ainda não foi escrito."]
		]
	},
	{
		"name": "Biblioteca do Último Fio",
		"short": "Autoras do amanhã",
		"enemy": "Página sem rosto",
		"boss": "A Costureira dos Finais",
		"hp": 540.0,
		"damage": 43.0,
		"color": Color("c7a2e0"),
		"sky": Color("281f3b"),
		"biome": 7,
		"recruit": "",
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
				"As oito agulhas caíram. Pela primeira vez, o livro abriu numa página em branco."
			]
		]
	},
]
const RELICS = [
	{"id": "power", "title": "Pena de rebeldia", "detail": "+20% de dano para a formação"},
	{"id": "heart", "title": "Página de abrigo", "detail": "+25 PV máximos e cura 40 por aliada"},
	{"id": "haste", "title": "Ponteiro solto", "detail": "Intervalos de ataque −12%"},
	{"id": "critical", "title": "Olho de vidro", "detail": "+12% de chance crítica"},
	{"id": "leech", "title": "Fio de vida", "detail": "Cada acerto cura 3 PV da atacante"},
	{"id": "armor", "title": "Capa do crepúsculo", "detail": "+3 de armadura por aliada"},
]


static func hero_stats(id: String, levels: Array, choices: Dictionary) -> Dictionary:
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
		"shield": 0.0
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
		"cinderella":
			result.damage *= 1.0 + levels[1] * 0.18
			result.crit += levels[2] * 0.04
		"ariel":
			result.damage *= 1.0 + levels[2] * 0.16
	result["hp"] = result.max_hp
	return result
