extends RefCounted
## Run-only equipment: 27 general items, 12 villain utilities, two slots.
const SLOTS := 2
const FORMAT := 2
const CAPACITY_PRICES := [150,400]
const RARITIES := ["Comum","Incomum","Raro","Épico","Lendário","Mítico","Especial"]
const COLORS := ["858b94","50b86a","5097ee","ac6bef","ef9c39","ee5555","e6cb79"]
const WEIGHTS := [36,28,20,10,5,1]
const LEGACY := {"ember_pearl":"star_powder","winter_match":"blue_hourglass","venom_vial":"black_apple","hunters_lens":"hunter_glasses","tower_braid":"stone_heart","red_goblet":"absinthe_goblet","jade_seal":"enchanted_needle"}
const ITEMS := {
  "whetstone": {
    "title": "Pedra de Amolar",
    "rarity": 0,
    "cost": 70,
    "detail": "+20% de dano físico. O primeiro básico da sua vez causa 50% de dano físico adicional ao alvo principal.",
    "stats": {},
    "effects": {
      "physical_damage": 0.2,
      "first_physical": 0.5
    }
  },
  "scribbled_grimoire": {
    "title": "Grimório Rabiscado",
    "rarity": 0,
    "cost": 70,
    "detail": "+20% de dano mágico. A primeira ULT de cada combate causa 30% mais dano.",
    "stats": {},
    "effects": {
      "magic_damage": 0.2,
      "first_ult": 0.3
    }
  },
  "seven_league_boots": {
    "title": "Botas de Sete Léguas",
    "rarity": 0,
    "cost": 70,
    "detail": "+20 de iniciativa. Na primeira vez em cada combate, realiza um básico adicional.",
    "stats": {
      "initiative": 20
    },
    "effects": {
      "opening_attack": 1
    }
  },
  "clockwork": {
    "title": "Relógio Atrasado",
    "rarity": 0,
    "cost": 70,
    "detail": "−20 de iniciativa e +60 PV máximos. No início da sua vez, cura 5% dos PV máximos se recebeu dano desde a vez anterior.",
    "stats": {
      "initiative": -20,
      "hp": 60
    },
    "effects": {
      "hurt_regen": 0.05
    }
  },
  "blue_hourglass": {
    "title": "Ampulheta Azul",
    "rarity": 1,
    "cost": 110,
    "detail": "+10 de mana por acerto básico. Usar ULT recupera 15 de mana, uma vez por sua vez.",
    "stats": {},
    "effects": {
      "mana_hit": 10,
      "ult_mana": 15
    }
  },
  "enchanted_needle": {
    "title": "Agulha Encantada",
    "rarity": 1,
    "cost": 110,
    "detail": "+30% de escudos criados. Proteger um aliado sem escudo concede +10 de iniciativa até o início da próxima vez do portador.",
    "stats": {},
    "effects": {
      "shield_mult": 0.3,
      "shield_initiative": 10
    }
  },
  "leaf_cloak": {
    "title": "Manto de Folhas",
    "rarity": 1,
    "cost": 110,
    "detail": "+15 pp de esquiva. A primeira esquiva entre suas vezes cura 8% dos PV máximos.",
    "stats": {
      "evasion": 0.15
    },
    "effects": {
      "evade_heal": 0.08
    }
  },
  "shrapnel_bag": {
    "title": "Bolsa de Estilhaços",
    "rarity": 1,
    "cost": 110,
    "detail": "+1 alvo de espalhamento, com 40% do dano normal. Aplica efeitos do básico e gera mana.",
    "stats": {},
    "effects": {
      "spread_40": 1
    }
  },
  "wolf_fang": {
    "title": "Presa do Lobo",
    "rarity": 2,
    "cost": 170,
    "detail": "+20% de dano físico. Rouba 15% da vida sobre o dano físico dos básicos; 30% contra alvos abaixo de 30% dos PV.",
    "stats": {},
    "effects": {
      "physical_damage": 0.2,
      "physical_leech": 0.15
    }
  },
  "black_apple": {
    "title": "Maçã da Rainha",
    "rarity": 2,
    "cost": 170,
    "detail": "Básicos aplicam Veneno de 15% do dano mágico, real, por 2 turnos do alvo. Até 3 acúmulos próprios; reaplicar renova.",
    "stats": {},
    "effects": {
      "apple_poison": 0.15
    }
  },
  "mirror_shard": {
    "title": "Espelho Rachado",
    "rarity": 2,
    "cost": 170,
    "detail": "+20 de defesa mágica. Reflete como dano mágico 25% do dano mágico direto efetivamente recebido. Não reflete reflexos.",
    "stats": {
      "magic_defense": 20
    },
    "effects": {
      "magic_reflect": 0.25
    }
  },
  "echo_bell": {
    "title": "Sino dos Ecos",
    "rarity": 2,
    "cost": 170,
    "detail": "Repete o primeiro básico da sua vez com 60% do dano. Aplica efeitos e gera mana; se o alvo morrer, segue a prioridade.",
    "stats": {},
    "effects": {
      "echo": 0.6
    }
  },
  "full_tide_shell": {
    "title": "Concha da Maré Cheia",
    "rarity": 2,
    "cost": 170,
    "detail": "+30% de cura realizada. Metade da cura excedente vira escudo por até 5 turnos. Limite próprio: 20% dos PV máximos por alvo.",
    "stats": {},
    "effects": {
      "healing": 0.3,
      "overheal": 0.5
    }
  },
  "hunter_glasses": {
    "title": "Óculos do Caçador",
    "rarity": 2,
    "cost": 170,
    "detail": "+20 pp de crítico e +40 pp de dano crítico. Contra chefes, +15 pp de crítico.",
    "stats": {
      "crit": 0.2,
      "crit_multiplier": 0.4
    },
    "effects": {
      "boss_crit": 0.15
    }
  },
  "golden_spool": {
    "title": "Carretel de Ouro",
    "rarity": 3,
    "cost": 250,
    "detail": "Quando um escudo seu é quebrado por dano, cura o protegido em 10% dos PV máximos e ganha 15 mana. Uma ativação por protegido entre suas vezes.",
    "stats": {},
    "effects": {
      "broken_heal": 0.1,
      "broken_mana": 15
    }
  },
  "black_cat_boots": {
    "title": "Botas do Gato Preto",
    "rarity": 3,
    "cost": 250,
    "detail": "+20 pp de esquiva. A primeira esquiva entre suas vezes garante crítico no alvo principal do próximo básico. Não acumula.",
    "stats": {
      "evasion": 0.2
    },
    "effects": {
      "evade_crit": true
    }
  },
  "absinthe_goblet": {
    "title": "Cálice de Absinto",
    "rarity": 3,
    "cost": 250,
    "detail": "+30% de dano mágico. Contra alvos com Veneno ou Queimadura, básicos causam 40% de dano mágico adicional e curam 30% desse dano adicional.",
    "stats": {},
    "effects": {
      "magic_damage": 0.3,
      "status_magic": 0.4
    }
  },
  "stone_heart": {
    "title": "Coração de Pedra",
    "rarity": 3,
    "cost": 250,
    "detail": "+100 PV máximos. Cada 10% de vida perdida concede +4 às duas defesas, até +36. Acompanha a vida atual.",
    "stats": {
      "hp": 100
    },
    "effects": {
      "missing_defense": 4
    }
  },
  "star_powder": {
    "title": "Pólvora de Estrelas",
    "rarity": 3,
    "cost": 250,
    "detail": "+2 alvos de espalhamento a 50% do dano. Se só houver um inimigo vivo, o básico causa 60% mais dano nele.",
    "stats": {},
    "effects": {
      "spread_50": 2,
      "solo_basic": 0.6
    }
  },
  "giant_sword": {
    "title": "Espada do Gigante Caído",
    "rarity": 4,
    "cost": 380,
    "detail": "+50% de dano físico e −20 de iniciativa. Básicos causam dano físico adicional de 3% dos PV máximos do alvo; contra chefes, limitado a 150% do dano físico do portador por acerto.",
    "stats": {
      "initiative": -20
    },
    "effects": {
      "physical_damage": 0.5,
      "target_hp": 0.03
    }
  },
  "empty_lamp": {
    "title": "Lâmpada sem Gênio",
    "rarity": 4,
    "cost": 380,
    "detail": "+20 de mana por acerto básico. Devolve o custo integral da primeira ULT de cada combate. Não devolve desejos ou usos limitados.",
    "stats": {},
    "effects": {
      "mana_hit": 20,
      "refund_ult": true
    }
  },
  "thorn_dress": {
    "title": "Vestido de Espinhos",
    "rarity": 4,
    "cost": 380,
    "detail": "+30 às duas defesas. Ao receber ataque direto, retalia com dano físico de 12% dos seus PV máximos. Uma vez por ação recebida.",
    "stats": {
      "magic_defense": 30,
      "physical_defense": 30
    },
    "effects": {
      "thorns": 0.12
    }
  },
  "fate_scissors": {
    "title": "Tesoura do Destino",
    "rarity": 4,
    "cost": 380,
    "detail": "+25 pp de crítico. Críticos ignoram 40% da defesa correspondente e causam 50% mais dano exclusivo a escudos.",
    "stats": {
      "crit": 0.25
    },
    "effects": {
      "critical_penetration": 0.4,
      "critical_shield": 0.5
    }
  },
  "immortal_wolf_heart": {
    "title": "Coração do Lobo Imortal",
    "rarity": 5,
    "cost": 550,
    "detail": "+150 PV máximos. Uma vez por estágio, dano fatal deixa você com 1 PV e escudo de 50% dos PV máximos até a próxima vez. Não impede novos golpes fatais.",
    "stats": {
      "hp": 150
    },
    "effects": {
      "fatal_shield": 0.5
    }
  },
  "world_needle": {
    "title": "Agulha que Costura o Mundo",
    "rarity": 5,
    "cost": 550,
    "detail": "+40% de escudos criados. Criar escudo cura o beneficiário em 30% do valor efetivamente adicionado. Essa cura não produz escudos de excedente.",
    "stats": {},
    "effects": {
      "shield_mult": 0.4,
      "shield_heal": 0.3
    }
  },
  "hundred_mirrors_crown": {
    "title": "Coroa dos Cem Reflexos",
    "rarity": 5,
    "cost": 550,
    "detail": "+20 pp de esquiva. A primeira esquiva entre suas vezes concede +1 ataque na próxima vez. Nessa vez, +1 ataque por 20 pp de esquiva, até +4. Os ataques duram somente aquela vez.",
    "stats": {
      "evasion": 0.2
    },
    "effects": {
      "evade_attacks": true
    }
  },
  "author_quill": {
    "title": "Pena do Autor",
    "rarity": 5,
    "cost": 550,
    "detail": "Até o final da primeira vez de cada combate: +1 ataque, +15 mana por acerto básico e +30% de dano físico e mágico.",
    "stats": {},
    "effects": {
      "opening_quill": true
    }
  }
}
const TROPHIES := {
  "ariel": [
    "Tridente da Bruxa do Mar",
    {
      "dispel": true
    },
    "O primeiro básico da sua vez remove um efeito positivo temporário antes do dano. Se não houver, remove 50% do escudo atual. Não remove passivas ou características de chefes."
  ],
  "peter": [
    "Gancho do Capitão Pirata",
    {
      "hook": true
    },
    "O primeiro básico da sua vez alcança qualquer fileira e prioriza a menor porcentagem de vida. Não desloca o alvo."
  ],
  "scarlet": [
    "Pele de Lobo",
    {
      "wolf_hide": true
    },
    "Enquanto houver outro aliado elegível na mesma fileira, não é escolhido pela prioridade normal de ataques de alvo único. Não impede áreas, provocações ou alvos explícitos."
  ],
  "aladin": [
    "Areias do Tempo",
    {
      "time_sands": true
    },
    "Uma vez por combate, adie manualmente a próxima vez de um inimigo para o final da rodada. Mantém seus ataques. Use pelo painel deste equipamento; não interrompe ações."
  ],
  "snow_white": [
    "Espelho da Rainha Má",
    {
      "copy_defenses": true
    },
    "Ao começar o combate, copia separadamente a maior defesa física e mágica inimiga. Usa esses valores quando superiores aos próprios, até o fim do combate."
  ],
  "mulan": [
    "Estandarte do General do Oriente",
    {
      "row_banner": true
    },
    "Enquanto estiver vivo, aliados da mesma fileira são imunes a reduções de iniciativa e quantidade de ataques. Não impede Sono."
  ],
  "rapunzel": [
    "Tesoura da Falsa Mãe",
    {
      "steal_buff": true
    },
    "O primeiro básico da sua vez rouba um efeito positivo temporário, preservando a duração. Escudos transferem seu valor atual. Não rouba passivas ou características de chefes."
  ],
  "puss": [
    "Marca do Caçador de Recompensas",
    {
      "hunter_mark": true
    },
    "Marca o primeiro inimigo atingido. Ele não esquiva dos seus ataques e não recebe interceptações contra você. Marca até um dos dois morrer; depois pode marcar outro."
  ],
  "alice": [
    "Cetro da Rainha de Copas",
    {
      "heart_scepter": true
    },
    "O primeiro básico da sua vez aplica Corta Cura e Quebra Escudos: −50% às novas curas e escudos recebidos até o início da próxima vez do portador."
  ],
  "matches": [
    "Coração do Espírito de Gelo",
    {
      "ice_heart": true
    },
    "O primeiro básico da sua vez aplica Ressaca (−20 iniciativa) até o início da próxima vez do alvo. Se já estiver com Queimadura, aplica Bolha: 50% de chance de perder 1 ataque na próxima vez."
  ],
  "joao": [
    "Faca de Açúcar da Bruxa dos Doces",
    {
      "sugar_crit": 0.2,
      "sugar_attack": true
    },
    "+20 pp de crítico. Dois acertos críticos básicos na mesma vez concedem imediatamente um básico adicional. Máximo de uma ativação por sua vez."
  ],
  "maria": [
    "Caldeirão da Bruxa dos Doces",
    {
      "cauldron": true
    },
    "Uma vez por sua vez, ao acertar, consome um efeito positivo temporário do alvo. Se conseguir, ganha 10 mana e cura 10% dos próprios PV máximos. Não remove passivas ou características de chefes."
  ]
}
static func item_at(actor: Dictionary, index: int) -> String:
	var items: Array = actor.get("equipment", [])
	return str(items[index]) if index >= 0 and index < items.size() else ""
static func data(id: String) -> Dictionary:
	if ITEMS.has(id): return ITEMS[id].duplicate(true)
	var hero:=id.trim_prefix("trophy_")
	if id.begins_with("trophy_") and TROPHIES.has(hero):
		return {"title":TROPHIES[hero][0],"detail":TROPHIES[hero][2],"rarity":6,"cost":0,"effects":TROPHIES[hero][1].duplicate(),"trophy":hero}
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

static func migrate(id:String) -> String:
	return str(LEGACY.get(id,id))

static func tint(id:String) -> Color:
	return Color(COLORS[clampi(int(data(id).get("rarity",0)),0,6)])

static func rarity_name(id:String) -> String:
	return RARITIES[clampi(int(data(id).get("rarity",0)),0,6)]

static func roll(rng:RandomNumberGenerator,excluded:Array=[]) -> String:
	var ticket:=rng.randi_range(1,100)
	var rank:=0
	for i in WEIGHTS.size():
		ticket-=WEIGHTS[i]
		if ticket<=0:rank=i;break
	var pool:Array=ITEMS.keys().filter(func(id):return int(ITEMS[id].rarity)==rank and not excluded.has(id))
	if pool.is_empty():pool=ITEMS.keys().filter(func(id):return not excluded.has(id))
	return "" if pool.is_empty() else str(pool[rng.randi_range(0,pool.size()-1)])

static func detach(actor:Dictionary) -> void:
	var applied:Dictionary=actor.get("equipment_applied",{})
	if applied.is_empty():return
	# Old saves used multiplicative damage/interval and different field names.
	if not applied.has("format"):
		actor.damage/=maxf(.001,float(applied.get("damage",1)))
		actor.interval/=maxf(.001,float(applied.get("interval",1)))
		actor.max_hp=maxf(1,actor.max_hp-float(applied.get("hp",0)))
		for key in ["armor","crit","leech","energy_bonus","initiative"]:actor[key]=float(actor.get(key,0))-float(applied.get(key,0))
	else:
		for key in applied:
			if key!="format":actor[key]=float(actor.get(key,0))-float(applied[key])
	actor["equipment_applied"]={}

static func attach(actor:Dictionary) -> void:
	var applied:Dictionary={"format":FORMAT}
	for id in actor.get("equipment",[]):
		var stats:Dictionary=data(str(id)).get("stats",{}).duplicate()
		if effects(actor).get("sugar_crit",0)>0 and id=="trophy_joao":stats["crit"]=float(stats.get("crit",0))+.2
		for key in stats:
			var field:String="max_hp" if key=="hp" else str(key)
			applied[field]=float(applied.get(field,0))+float(stats[key])
	for key in applied:
		if key!="format":actor[key]=float(actor.get(key,0))+float(applied[key])
	actor["equipment_applied"]=applied
