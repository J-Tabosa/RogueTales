extends RefCounted
## Exact authored routes from the four-season scenario package. A prefix cannot cross into another route.
const WORLD_COUNT=8
const SEASONS=["spring","summer","autumn","winter"]
const LABELS={"spring":"Primavera","summer":"Verão","autumn":"Outono","winter":"Inverno"}
const NODES={
	"FlorestaPrimavera": {
		"name": "Floresta de Primavera",
		"depth": 1,
		"season": "spring",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FlorestaPrimavera.png"
	},
	"FlorestaVerao": {
		"name": "Floresta de Verão",
		"depth": 1,
		"season": "summer",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FlorestaVerao.png"
	},
	"FlorestaOutono": {
		"name": "Floresta de Outono",
		"depth": 1,
		"season": "autumn",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FlorestaOutono.png"
	},
	"FlorestaInverno": {
		"name": "Floresta de Inverno",
		"depth": 1,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FlorestaInverno.png"
	},
	"BosqueNoturno": {
		"name": "Bosque Noturno",
		"depth": 2,
		"season": "spring",
		"biome": 0,
		"weather": "rain",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/BosqueNoturno.png"
	},
	"Pomar": {
		"name": "Pomar",
		"depth": 2,
		"season": "spring",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "scarlet",
		"texture": "res://assets/worlds/Pomar.png"
	},
	"CamposDeGirassois": {
		"name": "Campos de Girassóis",
		"depth": 2,
		"season": "summer",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CamposDeGirassois.png"
	},
	"CamposVerdejantes": {
		"name": "Campos Verdejantes",
		"depth": 2,
		"season": "summer",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CamposVerdejantes.png"
	},
	"PlantacaoDeAboboras": {
		"name": "Plantação de Abóboras",
		"depth": 2,
		"season": "autumn",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PlantacaoDeAboboras.png"
	},
	"VilarejoAgricola": {
		"name": "Vilarejo Agrícola",
		"depth": 2,
		"season": "autumn",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/VilarejoAgricola.png"
	},
	"CavernasDeMineracao": {
		"name": "Cavernas de Mineração",
		"depth": 2,
		"season": "winter",
		"biome": 2,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "snow_white",
		"texture": "res://assets/worlds/CavernasDeMineracao.png"
	},
	"PeDaMontanha": {
		"name": "Pé da Montanha",
		"depth": 2,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PeDaMontanha.png"
	},
	"BosqueEncantado": {
		"name": "Bosque Encantado",
		"depth": 3,
		"season": "spring",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/BosqueEncantado.png"
	},
	"Mangue": {
		"name": "Mangue",
		"depth": 3,
		"season": "spring",
		"biome": 6,
		"weather": "rain",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Mangue.png"
	},
	"Recanto": {
		"name": "Recanto",
		"depth": 3,
		"season": "spring",
		"biome": 0,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Recanto.png"
	},
	"CampoDeBatalha": {
		"name": "Campo de Batalha",
		"depth": 3,
		"season": "summer",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "mulan",
		"texture": "res://assets/worlds/CampoDeBatalha.png"
	},
	"EstradaReal": {
		"name": "Estrada Real",
		"depth": 3,
		"season": "summer",
		"biome": 1,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/EstradaReal.png"
	},
	"Savana": {
		"name": "Savana",
		"depth": 3,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Savana.png"
	},
	"InteriorDoMoinho": {
		"name": "Interior do Moinho",
		"depth": 3,
		"season": "autumn",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/InteriorDoMoinho.png"
	},
	"PracaDoVilarejo": {
		"name": "Praça do Vilarejo",
		"depth": 3,
		"season": "autumn",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PracaDoVilarejo.png"
	},
	"CavernasGelidas": {
		"name": "Cavernas Gélidas",
		"depth": 3,
		"season": "winter",
		"biome": 2,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CavernasGelidas.png"
	},
	"Montanha": {
		"name": "Montanha",
		"depth": 3,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Montanha.png"
	},
	"BeiraMar": {
		"name": "Beira-Mar",
		"depth": 4,
		"season": "spring",
		"biome": 3,
		"weather": "sun",
		"floor": [
			0.65,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/BeiraMar.png"
	},
	"IgrejaDestruida": {
		"name": "Igreja Destruída",
		"depth": 4,
		"season": "spring",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/IgrejaDestruida.png"
	},
	"RuinasEnraizadas": {
		"name": "Ruínas Enraizadas",
		"depth": 4,
		"season": "spring",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/RuinasEnraizadas.png"
	},
	"Canion": {
		"name": "Cânion",
		"depth": 4,
		"season": "summer",
		"biome": 7,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Canion.png"
	},
	"PonteParaOCastelo": {
		"name": "Ponte para o Castelo",
		"depth": 4,
		"season": "summer",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "puss",
		"texture": "res://assets/worlds/PonteParaOCastelo.png"
	},
	"TerraDosCaidos": {
		"name": "Terra dos Caídos",
		"depth": 4,
		"season": "summer",
		"biome": 6,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/TerraDosCaidos.png"
	},
	"TerrasAridas": {
		"name": "Terras Áridas",
		"depth": 4,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/TerrasAridas.png"
	},
	"CampoDeEspantalhos": {
		"name": "Campo de Espantalhos",
		"depth": 4,
		"season": "autumn",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CampoDeEspantalhos.png"
	},
	"CemiterioAntigo": {
		"name": "Cemitério Antigo",
		"depth": 4,
		"season": "autumn",
		"biome": 6,
		"weather": "rain",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CemiterioAntigo.png"
	},
	"PoraoDoMoinho": {
		"name": "Porão do Moinho",
		"depth": 4,
		"season": "autumn",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PoraoDoMoinho.png"
	},
	"CavernasProfundas": {
		"name": "Cavernas Profundas",
		"depth": 4,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CavernasProfundas.png"
	},
	"CidadeFria": {
		"name": "Cidade Fria",
		"depth": 4,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "matches",
		"texture": "res://assets/worlds/CidadeFria.png"
	},
	"Cume": {
		"name": "Cume",
		"depth": 4,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.65,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Cume.png"
	},
	"CavernasDeCogumelos": {
		"name": "Cavernas de Cogumelos",
		"depth": 5,
		"season": "spring",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CavernasDeCogumelos.png"
	},
	"PatioDoCastelo": {
		"name": "Pátio do Castelo",
		"depth": 5,
		"season": "spring",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PatioDoCastelo.png"
	},
	"Praia": {
		"name": "Praia",
		"depth": 5,
		"season": "spring",
		"biome": 3,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Praia.png"
	},
	"CasteloDoReiDourado": {
		"name": "Castelo do Rei Dourado",
		"depth": 5,
		"season": "summer",
		"biome": 1,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CasteloDoReiDourado.png"
	},
	"Deserto": {
		"name": "Deserto",
		"depth": 5,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Deserto.png"
	},
	"ValeDaRocha": {
		"name": "Vale da Rocha",
		"depth": 5,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/ValeDaRocha.png"
	},
	"CasaDeDoces": {
		"name": "Casa de Doces (interior)",
		"depth": 5,
		"season": "autumn",
		"biome": 0,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CasaDeDoces.png"
	},
	"CriptaEsquecida": {
		"name": "Cripta Esquecida",
		"depth": 5,
		"season": "autumn",
		"biome": 5,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CriptaEsquecida.png"
	},
	"FlorestaRetorcida": {
		"name": "Floresta Retorcida",
		"depth": 5,
		"season": "autumn",
		"biome": 0,
		"weather": "rain",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FlorestaRetorcida.png"
	},
	"JardimDasEstatuas": {
		"name": "Jardim das Estátuas",
		"depth": 5,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/JardimDasEstatuas.png"
	},
	"LagoCongelado": {
		"name": "Lago Congelado",
		"depth": 5,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.65,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/LagoCongelado.png"
	},
	"PontoVulcanico": {
		"name": "Ponto Vulcânico",
		"depth": 5,
		"season": "winter",
		"biome": 4,
		"weather": "embers",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/PontoVulcanico.png"
	},
	"CasteloDaRainhaVermelha": {
		"name": "Castelo da Rainha Vermelha",
		"depth": 6,
		"season": "spring",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "alice",
		"texture": "res://assets/worlds/CasteloDaRainhaVermelha.png"
	},
	"EnseadaEscondida": {
		"name": "Enseada Escondida",
		"depth": 6,
		"season": "spring",
		"biome": 3,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/EnseadaEscondida.png"
	},
	"NavioPirata": {
		"name": "Navio Pirata",
		"depth": 6,
		"season": "spring",
		"biome": 3,
		"weather": "none",
		"floor": [
			0.65,
			0.98
		],
		"meeting": "peter",
		"texture": "res://assets/worlds/NavioPirata.png"
	},
	"Oceano": {
		"name": "Oceano",
		"depth": 6,
		"season": "spring",
		"biome": 3,
		"weather": "none",
		"floor": [
			0.65,
			0.98
		],
		"meeting": "ariel",
		"texture": "res://assets/worlds/Oceano.png"
	},
	"CarcereDePrincesa": {
		"name": "Cárcere de Princesa",
		"depth": 6,
		"season": "summer",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "rapunzel",
		"texture": "res://assets/worlds/CarcereDePrincesa.png"
	},
	"EsgotosDaCidade": {
		"name": "Esgotos da Cidade",
		"depth": 6,
		"season": "summer",
		"biome": 6,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/EsgotosDaCidade.png"
	},
	"Oasis": {
		"name": "Oásis",
		"depth": 6,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/Oasis.png"
	},
	"FornoDaBruxa": {
		"name": "Forno da Bruxa",
		"depth": 6,
		"season": "autumn",
		"biome": 0,
		"weather": "embers",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FornoDaBruxa.png"
	},
	"MansaoAbandonada": {
		"name": "Mansão Abandonada",
		"depth": 6,
		"season": "autumn",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/MansaoAbandonada.png"
	},
	"CasteloDaRainhaAzul": {
		"name": "Castelo da Rainha Azul",
		"depth": 6,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CasteloDaRainhaAzul.png"
	},
	"ChaleAconchegante": {
		"name": "Chalé Aconchegante",
		"depth": 6,
		"season": "winter",
		"biome": 1,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/ChaleAconchegante.png"
	},
	"ForjaAntiga": {
		"name": "Forja Antiga",
		"depth": 6,
		"season": "winter",
		"biome": 4,
		"weather": "embers",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/ForjaAntiga.png"
	},
	"IlhaMaldita": {
		"name": "Ilha Maldita",
		"depth": 7,
		"season": "spring",
		"biome": 6,
		"weather": "rain",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/IlhaMaldita.png"
	},
	"CidadeAndante": {
		"name": "Cidade Andante (Caravanas)",
		"depth": 7,
		"season": "summer",
		"biome": 7,
		"weather": "sun",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "aladin",
		"texture": "res://assets/worlds/CidadeAndante.png"
	},
	"FundosDoCastelo": {
		"name": "Fundos do Castelo",
		"depth": 7,
		"season": "summer",
		"biome": 6,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/FundosDoCastelo.png"
	},
	"BosqueDasCinzas": {
		"name": "Bosque das Cinzas",
		"depth": 7,
		"season": "autumn",
		"biome": 4,
		"weather": "embers",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/BosqueDasCinzas.png"
	},
	"ValeDaAurora": {
		"name": "Vale da Aurora",
		"depth": 7,
		"season": "winter",
		"biome": 2,
		"weather": "snow",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/ValeDaAurora.png"
	},
	"CasteloDoAutor": {
		"name": "Castelo do Autor",
		"depth": 8,
		"season": "shared",
		"biome": 5,
		"weather": "none",
		"floor": [
			0.6,
			0.98
		],
		"meeting": "",
		"texture": "res://assets/worlds/CasteloDoAutor.png"
	}
}
const PATHS={
	"spring": [
		[
			"FlorestaPrimavera",
			"BosqueNoturno",
			"BosqueEncantado",
			"RuinasEnraizadas",
			"CavernasDeCogumelos",
			"EnseadaEscondida",
			"IlhaMaldita",
			"CasteloDoAutor"
		],
		[
			"FlorestaPrimavera",
			"BosqueNoturno",
			"Mangue",
			"BeiraMar",
			"Praia",
			"NavioPirata",
			"IlhaMaldita",
			"CasteloDoAutor"
		],
		[
			"FlorestaPrimavera",
			"BosqueNoturno",
			"Mangue",
			"BeiraMar",
			"Praia",
			"Oceano",
			"IlhaMaldita",
			"CasteloDoAutor"
		],
		[
			"FlorestaPrimavera",
			"Pomar",
			"Recanto",
			"IgrejaDestruida",
			"PatioDoCastelo",
			"CasteloDaRainhaVermelha",
			"IlhaMaldita",
			"CasteloDoAutor"
		]
	],
	"summer": [
		[
			"FlorestaVerao",
			"CamposVerdejantes",
			"CampoDeBatalha",
			"TerraDosCaidos",
			"ValeDaRocha",
			"EsgotosDaCidade",
			"FundosDoCastelo",
			"CasteloDoAutor"
		],
		[
			"FlorestaVerao",
			"CamposVerdejantes",
			"Savana",
			"Canion",
			"ValeDaRocha",
			"EsgotosDaCidade",
			"FundosDoCastelo",
			"CasteloDoAutor"
		],
		[
			"FlorestaVerao",
			"CamposVerdejantes",
			"Savana",
			"TerrasAridas",
			"Deserto",
			"Oasis",
			"CidadeAndante",
			"CasteloDoAutor"
		],
		[
			"FlorestaVerao",
			"CamposDeGirassois",
			"EstradaReal",
			"PonteParaOCastelo",
			"CasteloDoReiDourado",
			"CarcereDePrincesa",
			"CidadeAndante",
			"CasteloDoAutor"
		]
	],
	"autumn": [
		[
			"FlorestaOutono",
			"PlantacaoDeAboboras",
			"InteriorDoMoinho",
			"PoraoDoMoinho",
			"CasaDeDoces",
			"FornoDaBruxa",
			"BosqueDasCinzas",
			"CasteloDoAutor"
		],
		[
			"FlorestaOutono",
			"PlantacaoDeAboboras",
			"InteriorDoMoinho",
			"CampoDeEspantalhos",
			"FlorestaRetorcida",
			"MansaoAbandonada",
			"BosqueDasCinzas",
			"CasteloDoAutor"
		],
		[
			"FlorestaOutono",
			"VilarejoAgricola",
			"PracaDoVilarejo",
			"CampoDeEspantalhos",
			"FlorestaRetorcida",
			"MansaoAbandonada",
			"BosqueDasCinzas",
			"CasteloDoAutor"
		],
		[
			"FlorestaOutono",
			"VilarejoAgricola",
			"PracaDoVilarejo",
			"CemiterioAntigo",
			"CriptaEsquecida",
			"MansaoAbandonada",
			"BosqueDasCinzas",
			"CasteloDoAutor"
		]
	],
	"winter": [
		[
			"FlorestaInverno",
			"PeDaMontanha",
			"Montanha",
			"CidadeFria",
			"LagoCongelado",
			"ChaleAconchegante",
			"ValeDaAurora",
			"CasteloDoAutor"
		],
		[
			"FlorestaInverno",
			"PeDaMontanha",
			"Montanha",
			"Cume",
			"JardimDasEstatuas",
			"CasteloDaRainhaAzul",
			"ValeDaAurora",
			"CasteloDoAutor"
		],
		[
			"FlorestaInverno",
			"CavernasDeMineracao",
			"CavernasGelidas",
			"Cume",
			"JardimDasEstatuas",
			"CasteloDaRainhaAzul",
			"ValeDaAurora",
			"CasteloDoAutor"
		],
		[
			"FlorestaInverno",
			"CavernasDeMineracao",
			"CavernasGelidas",
			"CavernasProfundas",
			"JardimDasEstatuas",
			"CasteloDaRainhaAzul",
			"ValeDaAurora",
			"CasteloDoAutor"
		],
		[
			"FlorestaInverno",
			"CavernasDeMineracao",
			"CavernasGelidas",
			"CavernasProfundas",
			"PontoVulcanico",
			"ForjaAntiga",
			"ValeDaAurora",
			"CasteloDoAutor"
		]
	]
}
static var textures:Dictionary={}
static func start(rng:RandomNumberGenerator) -> Dictionary:
	var season:String=SEASONS[rng.randi_range(0,3)]
	return {"format":1,"season":season,"path":[PATHS[season][0][0]]}
static func valid(data:Dictionary) -> bool:
	if not PATHS.has(str(data.get("season",""))) or not data.get("path") is Array:return false
	var prefix:Array=data.path
	if prefix.is_empty() or prefix.size()>WORLD_COUNT:return false
	for route in PATHS[data.season]:
		if route.slice(0,prefix.size())==prefix:return true
	return false
static func restore(data:Variant) -> Dictionary:
	if not data is Dictionary or not valid(data):return {}
	return {"format":1,"season":str(data.season),"path":data.path.duplicate()}
static func next_maps(data:Dictionary) -> Array[String]:
	var result:Array[String]=[]
	if not valid(data):return result
	var prefix:Array=data.path
	for route in PATHS[data.season]:
		if route.size()>prefix.size() and route.slice(0,prefix.size())==prefix:
			var id:String=route[prefix.size()]
			if not result.has(id):result.append(id)
	return result
static func select(data:Dictionary,id:String) -> bool:
	if not next_maps(data).has(id):return false
	data.path.append(id)
	return true
static func current(data:Dictionary,stage:int) -> Dictionary:
	if not valid(data) or stage<0 or stage>=data.path.size():return {}
	return NODES[str(data.path[stage])]
static func texture(id:String) -> Texture2D:
	if not NODES.has(id):return null
	if not textures.has(id):
		# Keep at most three full-resolution scenery textures resident on mobile.
		if textures.size()>=3:textures.erase(textures.keys()[0])
		textures[id]=load(NODES[id].texture)
	return textures[id]
