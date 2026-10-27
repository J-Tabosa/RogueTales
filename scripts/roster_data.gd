extends RefCounted
## Consolidated source of truth from the supplied MDs, 26/10/2026.
const BASE = {
	"scarlet": {
		"hp": 200.0,
		"physical_damage": 24.0,
		"magic_damage": 0.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.1,
		"crit_multiplier": 2.0,
		"evasion": 0.1,
		"mana_max": 120,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"alice": {
		"hp": 190.0,
		"physical_damage": 10.0,
		"magic_damage": 10.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 0,
		"mana_hit": 0,
		"mana_turn": 0
	},
	"snow_white": {
		"hp": 300.0,
		"physical_damage": 20.0,
		"magic_damage": 0.0,
		"physical_defense": 10.0,
		"magic_defense": 5.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 100,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"ariel": {
		"hp": 150.0,
		"physical_damage": 0.0,
		"magic_damage": 20.0,
		"physical_defense": 0.0,
		"magic_defense": 5.0,
		"initiative": 10.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 120,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"rapunzel": {
		"hp": 350.0,
		"physical_damage": 0.0,
		"magic_damage": 15.0,
		"physical_defense": 5.0,
		"magic_defense": 15.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 100,
		"mana_hit": 0,
		"mana_turn": 20
	},
	"mulan": {
		"hp": 200.0,
		"physical_damage": 30.0,
		"magic_damage": 0.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.2,
		"crit_multiplier": 2.0,
		"evasion": 0.2,
		"mana_max": 100,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"maria": {
		"hp": 180.0,
		"physical_damage": 0.0,
		"magic_damage": 25.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 10.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 150,
		"mana_hit": 15,
		"mana_turn": 0
	},
	"joao": {
		"hp": 190.0,
		"physical_damage": 20.0,
		"magic_damage": 0.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.25,
		"crit_multiplier": 2.0,
		"evasion": 0.15,
		"mana_max": 80,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"matches": {
		"hp": 150.0,
		"physical_damage": 0.0,
		"magic_damage": 20.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.1,
		"mana_max": 200,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"aladin": {
		"hp": 180.0,
		"physical_damage": 0.0,
		"magic_damage": 25.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.0,
		"crit_multiplier": 2.0,
		"evasion": 0.0,
		"mana_max": 0,
		"mana_hit": 0,
		"mana_turn": 0
	},
	"peter": {
		"hp": 170.0,
		"physical_damage": 0.0,
		"magic_damage": 20.0,
		"physical_defense": 0.0,
		"magic_defense": 0.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.15,
		"crit_multiplier": 3.0,
		"evasion": 0.25,
		"mana_max": 70,
		"mana_hit": 10,
		"mana_turn": 0
	},
	"puss": {
		"hp": 330.0,
		"physical_damage": 30.0,
		"magic_damage": 0.0,
		"physical_defense": 10.0,
		"magic_defense": 10.0,
		"initiative": 50.0,
		"attacks": 1.0,
		"crit": 0.1,
		"crit_multiplier": 2.0,
		"evasion": 0.05,
		"mana_max": 90,
		"mana_hit": 10,
		"mana_turn": 0
	}
}
const TEXT = {
	"scarlet": {
		"role": "Atiradora Caster física; retaguarda. Espalha pólvora e a consome em uma ult coletiva.",
		"basic": "Bombas Caseiras",
		"basic_text": "Bombas Caseiras: causa 100% do Dano Físico em um alvo. Pode critar. Não tem espalhamento natural na ficha final.",
		"passive": "Espalhando Pólvora",
		"passive_text": "Espalhando Pólvora: cada alvo acertado por um ataque recebe uma carga, até dez por alvo. Crítico não concede carga adicional naturalmente. Cada carga aumenta em 10% o dano da Scarlet contra aquele alvo, até +100%. A pólvora não explode automaticamente; desaparece no fim do combate.",
		"ult": "Detonação em Massa",
		"ult_text": "Detonação em Massa: custa 120 de mana, atinge todos os inimigos e consome as cargas de cada um. Dano físico por alvo = Dano Físico × 1,5 × (1 + 0,1 × cargas daquele alvo). Vai de 150% a 300%. Pode critar; não gera mana nem pólvora. Pode ocorrer durante a sequência sem consumir básicos restantes.\nCada alvo acertado pelo básico ou seu espalhamento concede dez de mana. Sem regeneração passiva. A mana permanece entre combates."
	},
	"alice": {
		"role": "Atiradora Híbrida de economia; retaguarda. A posição Vanguarda e os campos de dano puramente físico no JSON são limitações/erros de preenchimento, corrigidos pela conversa.",
		"basic": "4 Naipes",
		"basic_text": "4 Naipes: básico causa 100% do Dano Físico + 100% do Dano Mágico em um alvo e avança um naipe.",
		"passive": "Baralho Mágico",
		"passive_text": "Baralho Mágico: não usa mana. Cada básico executado concede uma carga em um contador único. A cada quatro cargas, consome quatro e ativa a ult, continuando os ataques restantes. Espalhamento não concede cargas extras. Contador e próximo naipe permanecem entre combates.",
		"ult": "Cortejo das Cartas",
		"ult_text": "Ouros: concede cinco de ouro por acerto. A função econômica é intencional.\nCopas: cura a própria Alice em 10% do dano causado.\nPaus: concede à própria Alice escudo de 5% da vida máxima.\nEspadas: acrescenta 50% do atributo ofensivo mais alto como dano daquele tipo. No empate, apenas um dos dois tipos recebe o bônus; o critério de desempate não foi especificado.\nCortejo das Cartas: causa 120% do Dano Físico + 120% do Dano Mágico por inimigo atravessado na linha horizontal do alvo. Não alimenta seu próprio contador. Básico e ult podem critar se Alice adquirir chance crítica."
	},
	"snow_white": {
		"role": "Soldado Tank Físico; vanguarda. Mineradora criada entre anões, especializada em romper escudos.",
		"basic": "Minerando",
		"basic_text": "Minerando: básico de 100% do Dano Físico em um alvo.",
		"passive": "Quebrando Barreiras",
		"passive_text": "Quebrando Barreiras: básicos causam +100% de dano contra escudos. O dano adicional exclusivo contra escudo não se transforma em dano à vida ao quebrá-lo. A ult também recebe esse benefício, apesar da descrição original usar o nome antigo Rompe-Barreiras.",
		"ult": "Partidora de Rochas",
		"ult_text": "Partidora de Rochas: 300% do Dano Físico em um alvo. Custo 100; dez de mana por acerto; zero por turno."
	},
	"ariel": {
		"role": "Maga Curandeira; retaguarda. Água ricocheteia para curar e preparar controle coletivo. Nome final Umi, substituindo Ariel nas descrições.",
		"basic": "Correntes Dançantes",
		"basic_text": "Correntes Dançantes: 100% do Dano Mágico no alvo inicial. Cada salto testa individualmente 50% de chance de continuar, até dois saltos naturais, de 60% e 40%. Falhar encerra a corrente. Não repete alvos naquele básico.",
		"passive": "Águas Curativas",
		"passive_text": "Águas Curativas: cada inimigo acertado pelo básico, inclusive por ricochete, cura o aliado vivo com menor porcentagem de vida em 15% do Dano Mágico. Reavalia o beneficiário após cada impacto. Cada acerto também gera dez de mana.",
		"ult": "Impacto de Onda",
		"ult_text": "Impacto de Onda: custa 120, causa 150% do Dano Mágico em todos os inimigos e tem 50% de chance individual de aplicar Bolha. Bolha remove um ataque da próxima vez do alvo, podendo chegar a zero, não acumula e respeita imunidades. A ult não gera mana nem ativa Águas Curativas."
	},
	"rapunzel": {
		"role": "Tank Suporte; vanguarda. Protege o grupo, reduz dano enquanto seus escudos existem e retalia contra agressores.",
		"basic": "Casulo de Seda",
		"basic_text": "Casulo de Seda: concede a si e ao outro aliado vivo com menor porcentagem de vida escudo de 100% do Dano Mágico. Enquanto Silk tiver escudo criado por ela, ataques inimigos que a acertam provocam retaliação de 50% do Dano Mágico. Inclui o golpe que quebra o escudo. Não é uma ação ofensiva direta.",
		"passive": "Fios Entrelaçados",
		"passive_text": "Fios Entrelaçados: aliados com escudos criados por Silk recebem 10% menos dano. Beneficia a própria Silk, não acumula e vale também no golpe que quebra a proteção.",
		"ult": "Torre de Cabelos",
		"ult_text": "Torre de Cabelos: concede a todos os aliados vivos, incluindo Silk, escudo de 200% do Dano Mágico e bônus de Defesa Mágica equivalente a 30% dos pontos de Defesa Mágica de Silk. O bônus dura enquanto o escudo da ult daquele beneficiário durar.\nEscudos próprios acumulam até 30% da vida máxima de cada beneficiário. Duração normal cinco turnos do beneficiário, por aplicação. Escudos permanecem entre combates; isso não renova sua duração.\nCusto da ult 100; ganha 20 de mana no início da própria vez e zero por acerto."
	},
	"mulan": {
		"role": "Assassina Física; meio. Combos, críticos e contra-ataques.",
		"basic": "Três Ataques",
		"basic_text": "Três Ataques: 100% do Dano Físico em um alvo; cada terceiro básico executado causa 150%. Contador permanece entre turnos e combates. Contra-ataques e ults não avançam o contador.",
		"passive": "Contra-Ataque",
		"passive_text": "Contra-Ataque: ao esquivar de ataque direto, responde com 60% do Dano Físico. Pode critar; não gera mana. Uma ativação entre suas próprias vezes, renovada no início da vez dela.",
		"ult": "Dragão de Jade",
		"ult_text": "Dragão de Jade: 250% do Dano Físico em toda a coluna escolhida. Pode alcançar as três colunas como Assassina; prioridade detalhada será criada depois. Para execução visual, prioriza o alvo central da coluna, sem precisar expor isso na descrição ao jogador.\nCusto 100; dez de mana por acerto de básico e zero por turno."
	},
	"maria": {
		"role": "Assassina Mágica; meio. Veneno de dano real e maldição coletiva. Não usar a antiga proposta de estocadas e consumo de veneno.",
		"basic": "Veneno Líquido",
		"basic_text": "Veneno Líquido: 100% do Dano Mágico em um alvo, podendo critar se adquirir chance. Aplica uma dose de veneno.",
		"passive": "Acumulando Toxinas",
		"passive_text": "Acumulando Toxinas: até três doses por alvo. Cada dose causa 10% do Dano Mágico como dano real no início da vez do alvo, durante dois turnos. Reaplicar renova a duração. Veneno não critica nem gera mana pelo dano periódico.",
		"ult": "Maldição de Bruxa",
		"ult_text": "Maldição de Bruxa: sem dano direto; tenta aplicar Maldição em todos os inimigos, com 75% de chance individual. Reduz Dano Físico, Dano Mágico e pontos das duas defesas em 20%, durante dois turnos de cada alvo. No início da própria vez, cada alvo tem 25% de chance de escapar antecipadamente.\nCusto 150; quinze de mana por acerto de básico e zero por turno."
	},
	"joao": {
		"role": "Assassino Físico; meio. Marca uma presa e executa uma sequência de estocadas com a bengala de doce.",
		"basic": "Perfuração de Açúcar",
		"basic_text": "Perfuração de Açúcar: 100% do Dano Físico em um alvo, podendo critar.",
		"passive": "Marca do Duelista",
		"passive_text": "Marca do Duelista: primeiro básico acertado marca o inimigo. Básicos seguintes contra essa presa causam 120%. Marca permanece até a presa morrer ou João trocar de alvo. Apenas básicos aplicam.",
		"ult": "Seis Saudações",
		"ult_text": "Seis Saudações: seis estocadas de 50% do Dano Físico, ou 70% por estocada contra presa marcada. Cada impacto pode critar ou ser esquivado individualmente. Não gera mana por acerto. Se o alvo morrer, os golpes restantes terminam, sem transferência.\nCusto 80; dez de mana por acerto de básico e zero por turno."
	},
	"matches": {
		"role": "Maga de Dano Contínuo; retaguarda. Aumenta a potência de uma queimadura, em vez de acumular doses separadas.",
		"basic": "Lançar Faíscas",
		"basic_text": "Lançar Faíscas: 50% do Dano Mágico em um alvo, aplicando Queimadura de 100% do Dano Mágico como dano real de fogo no início da vez do inimigo, por dois turnos.",
		"passive": "Incêndio Amador",
		"passive_text": "Incêndio Amador: impacto direto de básico ou ult contra alvo já incendiado acrescenta dez pontos percentuais do Dano Mágico à potência do fogo, até 150%, e renova a duração. Dano periódico e explosões não fortalecem a queimadura.",
		"ult": "Fogo de Dragão",
		"ult_text": "Fogo de Dragão: 250% do Dano Mágico em todos os inimigos e aplica a mesma queimadura inicial nos não incendiados; fortalece os já incendiados pela passiva. A ult não gera mana.\nQueimadura não critica nem gera mana pelo dano. Imunidade a fogo impede sua aplicação.\nCusto 200; dez de mana por acerto de básico e zero por turno."
	},
	"aladin": {
		"role": "Mago de Recursos; retaguarda. Sem ult convencional ou mana; três desejos manuais limitados pela run.",
		"basic": "Energia Genial",
		"basic_text": "Energia Genial: rajada de 100% do Dano Mágico em um alvo. Pode critar ao adquirir chance.",
		"passive": "Poder Engarrafado",
		"passive_text": "Poder Engarrafado: +10% de Dano Mágico por desejo disponível: +30%, +20%, +10%, zero. Conta desejos restantes, não desejos já gastos.",
		"ult": "3 Desejos — especial",
		"ult_text": "3 Desejos — especial: manual, sem mana, pode ser usado mesmo morto e fora de combate, inclusive no mercador. Um uso de cada opção por run, salvo a bênção de quarto desejo."
	},
	"peter": {
		"role": "Assassino Mágico; meio. Esquivas criam sombras ofensivas; ser acertado destrói suas sombras sem reduzir o dano recebido.",
		"basic": "Lâmina Sem Sombra",
		"basic_text": "Lâmina Sem Sombra: 100% do Dano Mágico no alvo. Cada sombra acompanha com um golpe separado de 15% do Dano Mágico. Atacar não consome sombras. Cada golpe calcula seu próprio crítico ×3. Golpes das sombras não geram mana ou novas cópias de ataques.",
		"passive": "Sombras do Nunca",
		"passive_text": "Passiva de sombras: cada esquiva de ataque direto concede uma sombra, até três. Cada impacto direto acertado remove uma sombra, se houver; Peter recebe o dano normalmente. Sombras não bloqueiam, não concedem redução e não são escudos. Dano periódico não gera ou remove sombras.",
		"ult": "A Hora das Sombras",
		"ult_text": "Ult em si mesmo — A Hora das Sombras: completa suas sombras até três e acrescenta quinze pontos percentuais ao coeficiente mágico de seus golpes, até o início da próxima vez. Sombras comuns passam de 15% a 30%. Custo 70; dez de mana por acerto do básico, zero por turno.\nEsquiva inicial 25%, teto comum 80%; chance crítica 15%, multiplicador ×3. Não criar ataques de acerto garantido para contornar a esquiva.\nSombras permanecem entre combates."
	},
	"puss": {
		"role": "Soldado Físico; vanguarda. Vida alta, espada gigante e dano baseado na porcentagem de vida perdida.",
		"basic": "Corte Brutal",
		"basic_text": "Corte Brutal: 100% do Dano Físico em um alvo; pode critar.",
		"passive": "Fúria do Pequeno Gigante",
		"passive_text": "Fúria do Pequeno Gigante: +1% de Dano Físico por 1% de vida máxima faltando. Recalcula com a vida atual; curar reduz o bônus. Não usa quantidade absoluta de PV perdidos.",
		"ult": "Matador de Gigantes",
		"ult_text": "Matador de Gigantes: 250% do Dano Físico em toda a coluna escolhida, usando o atributo aumentado pela passiva. Pode critar. Custo 90; dez de mana por acerto do básico e zero por turno; ult não gera mana."
	}
}
const BOONS = {
	"scarlet": [
		[
			"Pavio Curto",
			"Custo da ult reduzido em 30: de 120 para 90.",
			"Padrão."
		],
		[
			"Explosivo Fragmentado",
			"Básico também acerta os dois alvos mais próximos do alvo principal, com 50% do dano. Cada alvo recebe uma carga e concede dez de mana.",
			"Atingir nove inimigos com um básico, conforme JSON."
		],
		[
			"Inimiga de Bestas",
			"+50% de dano contra categoria Besta.",
			"Vencer o Lobo Mau secreto."
		],
		[
			"Chapeuzinho Vermelho",
			"Ult começa em 300%, chegando a 600% com dez cargas. Básicos aplicam duas cargas por alvo, mantendo dez de mana por acerto.",
			"Concluir a run com Scarlet como protagonista."
		]
	],
	"alice": [
		[
			"Full House",
			"Cada ult concede um básico adicional, que avança o naipe e o contador.",
			"Padrão."
		],
		[
			"Chapeleira Maluca",
			"Uma condição negativa é sorteada por ult e compartilhada entre os inimigos atingidos. Dura um turno, usa a potência padrão da condição e respeita chance de aplicação e imunidades individuais.",
			"Alice causar dois ou mais efeitos negativos na mesma rodada."
		],
		[
			"Escapada Mágica",
			"Uma vez por estágio, antes de um ataque fatal, troca com qualquer aliado vivo da retaguarda, que recebe o ataque. Alice ganha 100% de esquiva até sua próxima vez. Sem aliado elegível, não ativa.",
			"Vencer a Rainha de Copas secreta."
		],
		[
			"País das Maravilhas",
			"Dobra os efeitos especiais dos naipes. Cada ataque tem 10% de chance de lançar um Coringa, limitado a um por turno. O Coringa causa o dano do ataque e repete o efeito do naipe anterior; não avança naipe nem carrega a ult.",
			"Concluir run como protagonista."
		]
	],
	"snow_white": [
		[
			"Um Pouco pra Mim!",
			"Ao destruir um escudo, recebe 50% do valor que ele tinha imediatamente antes do golpe que o destruiu como escudo próprio.",
			"Padrão."
		],
		[
			"Duro e Afiado",
			"Cada dois pontos de Defesa Física concedem +1% de Dano Físico.",
			"Atingir 100 pontos de Defesa Física em uma run."
		],
		[
			"Constituição de Mineradora",
			"Imune a efeitos negativos que causem dano, como veneno e queimadura. Não é imunidade geral a controles sem dano.",
			"Vencer a Rainha Má secreta."
		],
		[
			"A Branca de Neve",
			"50% de chance de interceptar ataque de alvo único contra aliado da retaguarda ou Assassino. Não esquiva do golpe interceptado e recebe 20% menos dano, além das defesas normais. Após duas falhas consecutivas, a próxima tentativa é garantida. Sucesso zera falhas. Uma interceptação entre suas vezes, recuperada no início da própria vez. Não funciona em área.",
			"Concluir run como protagonista."
		]
	],
	"ariel": [
		[
			"Espuma Acolhedora",
			"100% da cura excedente vira escudo, até 15% da vida máxima do beneficiário em escudo desta bênção. Pode escolher aliado saudável se todos estiverem com vida cheia.",
			"Padrão."
		],
		[
			"Ondas Infinitas",
			"Dois ricochetes adicionais, de 40% do Dano Mágico cada. Também testam os 50%, não repetem alvos e ativam cura/mana por acerto.",
			"Atingir cinco inimigos no mesmo turno."
		],
		[
			"Voz das Profundezas",
			"Se a rolagem de aplicação de Bolha falhar, aplica Ressaca: −20 de Iniciativa na próxima vez do alvo. Respeita imunidade a controle.",
			"Vencer a Bruxa do Mar secreta."
		],
		[
			"A Princesa Sereia",
			"Aplicar Bolha concede um básico extra à próxima vez de Umi, até três guardados. Não aumenta permanentemente o atributo e não acrescenta ataques à sequência atual.",
			"Concluir run como protagonista."
		]
	],
	"rapunzel": [
		[
			"Trança Dupla",
			"Básico protege mais um aliado, além de Silk e do primeiro beneficiário.",
			"Padrão na proposta; falta registrar explicitamente na ficha."
		],
		[
			"Fios Resistentes",
			"Quebra de escudo criado por Silk por dano inimigo concede dez de mana a ela. Cada aliado pode ativar uma vez entre duas vezes de Silk.",
			"Manter 200 pontos de escudo simultâneos em um único personagem."
		],
		[
			"Esperando Para Sempre",
			"Seus escudos não expiram após cinco turnos; permanecem até quebrar, inclusive entre combates.",
			"Vencer a Falsa Mãe secreta."
		],
		[
			"Rapunzel",
			"Ult limpa todos os efeitos negativos do grupo e concede escudo de 300% do Dano Mágico, preservando o bônus defensivo da ult.",
			"Concluir run como protagonista."
		]
	],
	"mulan": [
		[
			"Dois Ataques",
			"Básico aprimorado a cada dois básicos.",
			"Padrão."
		],
		[
			"Fogos de Artifício",
			"Ult acerta também a coluna imediatamente atrás da original, com os mesmos 250%. Vanguarda + meio, ou meio + retaguarda; não propaga para uma terceira coluna.",
			"A própria Mulan eliminar duas colunas completas, com três inimigos cada, no mesmo turno."
		],
		[
			"Sem Correntes",
			"Até três contra-ataques entre suas vezes.",
			"Vencer o General do Leste secreto."
		],
		[
			"A Guerreira do Leste",
			"Cada crítico de básico acrescenta cinco pontos percentuais ao dano dos próximos básicos, até +20. Expira no início da próxima vez, sem renovar duração. Soma com o aprimorado: comum até 120%, aprimorado até 170%. O golpe que gera a carga usa o bônus anterior.",
			"Concluir run como protagonista."
		]
	],
	"maria": [
		[
			"Acumulando Ainda Mais Toxinas!",
			"Limite de veneno passa a cinco doses.",
			"Padrão."
		],
		[
			"Assassinos de Bruxas",
			"+50% de dano contra Bruxa ou Feiticeiro. Matar inimigo de qualquer categoria concede cinco de mana, inclusive morte por seu veneno.",
			"Vencer chefe Bruxa com João na equipe."
		],
		[
			"Uma Maldição Mais Forte",
			"Acrescenta Corta-Cura e Quebra-Escudos pela duração da Maldição.",
			"Vencer a Bruxa dos Doces secreta."
		],
		[
			"A Nova Bruxa",
			"Quando a própria Maria mata um inimigo envenenado, inclusive pelo veneno, transfere suas doses ao próximo alvo válido segundo sua prioridade, até três doses. Sem dano imediato; sem outro inimigo, as doses desaparecem.",
			"Concluir run como protagonista."
		]
	],
	"joao": [
		[
			"Doce Ponto Fraco",
			"Ignora 50% dos pontos de Defesa Física do alvo.",
			"Padrão."
		],
		[
			"Assassinos de Bruxas",
			"+50% de dano contra Bruxa ou Feiticeiro. Eliminar qualquer inimigo concede cinco de mana, inclusive por ult ou Sangramento.",
			"Vencer chefe Bruxa com Maria na equipe."
		],
		[
			"Marcado para Morrer",
			"Acertar seis estocadas no mesmo inimigo na mesma ult aplica Sangramento: 10% do Dano Físico como dano real no início da vez dele e Corta-Cura de 50%. Não acumula, critica ou gera mana pelo dano. Dura até a morte, mas pode ser limpo.",
			"Vencer a Bruxa dos Doces secreta."
		],
		[
			"O Caçador da Casa dos Doces",
			"Cada crítico da ult acrescenta uma estocada à execução, até três extras. Extras podem critar, mas não geram outras extras.",
			"Concluir run como protagonista."
		]
	],
	"matches": [
		[
			"Mais de uma Faísca",
			"+1 ataque, direcionado a outro inimigo. Sem outro alvo, repete o primeiro. Causa 50% do Dano Mágico e aplica/fortalece fogo, gerando mana normalmente.",
			"Padrão."
		],
		[
			"Queime até Virar Cinzas",
			"Seu fogo não expira nem pode ser limpo depois de aplicado. Imunidade ainda impede aplicar. Limite da potência passa a 200% do Dano Mágico.",
			"Vencer combate com ao menos três inimigos, todos mortos pela queimadura no início das próprias vezes."
		],
		[
			"A Chama da Vida",
			"No início da vez de Lume, havendo inimigo queimando, cura 50% da potência por turno da queimadura mais forte entre eles. Sujeita a Corta-Cura.",
			"Vencer o Elemental do Frio secreto."
		],
		[
			"A Vendedora de Fósforos",
			"Morte de inimigo incendiado provoca explosão de 50% do Dano Mágico contra os demais. Mortos pela explosão só continuam a cadeia se já estavam incendiados. Cada inimigo explode uma vez. Explosão mágica, sem crítico, sem aplicar fogo. Apenas mortes pelas explosões concedem dez de mana por abate.",
			"Concluir run como protagonista."
		]
	],
	"aladin": [
		[
			"Lâmpada Preciosa",
			"Passiva concede +20% de Dano Mágico por desejo restante, começando em +60%.",
			"Padrão."
		],
		[
			"Proteção ao Portador da Lâmpada",
			"Imune a todos os efeitos negativos enquanto restar algum desejo.",
			"Concluir run com Aladin na equipe sem gastar todos os desejos."
		],
		[
			"Essa É Por Conta da Casa",
			"Quarta carga livre para repetir uma das três opções, além do uso de cada desejo original. Conta na passiva: +40%, +30%, +20%, +10%, zero.",
			"Vencer O Rei do Deserto secreto."
		],
		[
			"Gênio Liberto",
			"Após gastar os três desejos, +2 ataques por turno e rajadas passam a dano real, escalando com Dano Mágico.",
			"Concluir run como protagonista."
		]
	],
	"peter": [
		[
			"O Menino e Sua Sombra",
			"Começa cada combate com uma sombra.",
			"Padrão."
		],
		[
			"Terra do Nunca",
			"Perder sombra por acerto inimigo também remove um efeito negativo, após o impacto.",
			"Perder três sombras por dano inimigo no mesmo combate e sobreviver."
		],
		[
			"Devolva Minha Sombra",
			"Ao atacar inimigo que removeu uma sombra dele naquela rodada, 50% de chance de recuperar uma sombra, até o limite três.",
			"Vencer o Capitão Gancho secreto."
		],
		[
			"Peter Pan",
			"Cada sombra causa 25% do Dano Mágico como dano mágico + 15% como dano real. Sob ult: 40% mágico + 15% real.",
			"Concluir run como protagonista."
		]
	],
	"puss": [
		[
			"Lâmina Desesperada",
			"Com 25% de vida ou menos, básicos acertam um segundo inimigo com 50% do dano do golpe principal. Sem segundo alvo, o golpe adicional atinge o primeiro.",
			"Padrão."
		],
		[
			"Ainda Tenho Garras",
			"Uma vez por estágio inteiro, dano fatal o deixa com um PV; sua vida não cai abaixo disso até o início da próxima vez. Não é imunidade a controle. Uso compartilhado entre as seis fases do estágio.",
			"Chegar a 5% da vida máxima ou menos e vencer o combate com o Gato vivo."
		],
		[
			"Pequeno, Mas Não Menor",
			"+25% de dano contra todos os chefes, incluindo secundários, de estágio e secretos.",
			"Vencer o Lobo Caçador de Recompensas."
		],
		[
			"O Gato de Botas",
			"Até nove retornos na run, com 20% da vida máxima. Chances sucessivas: 100%, 90%, 80%, 70%, 60%, 50%, 40%, 30%, 20%. Falha resulta em morte normal. Reviver preserva mana e limpa condições negativas. Ressurreição externa não reinicia as chances.",
			"Concluir run como protagonista."
		]
	]
}
