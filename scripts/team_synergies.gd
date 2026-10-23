extends RefCounted
## Every pair has a real, conditional follow-up. One activation per pair per round.
const PAIRS := {
	"hunters": {"name": "Caçadores de Bruxas", "heroes": ["joao", "maria"], "detail": "Maria acerta a presa marcada: João ativa a combinação num disparo de 80% e renova o veneno."},
	"powder": {"name": "Pavio Compartilhado", "heroes": ["scarlet", "matches"], "detail": "Uma atinge o fogo da outra: a parceira ativa a combinação para detonar duas parcelas de queimadura."},
	"tide": {"name": "Maré dos Desejos", "heroes": ["ariel", "aladin"], "detail": "Aladin cura ou protege o grupo: Ariel ativa a combinação e acrescenta escudo de 8% e 12 de energia."},
	"threads": {"name": "Fios de Ferro", "heroes": ["rapunzel", "puss"], "detail": "O corte carregado do Gato faz Rapunzel ativar a combinação para curá-lo em 6% e proteger o grupo em 10%."},
	"dance": {"name": "Jade e Sombra", "heroes": ["mulan", "peter"], "detail": "Peter consome sombras: Mulan ativa a combinação para acrescentar um corte de 70% na vanguarda."},
	"tea": {"name": "Chá das Maçãs", "heroes": ["alice", "snow_white"], "detail": "Copas ou Paus atingem veneno: Branca ativa a combinação, destila duas parcelas de veneno e cura 5% do grupo."}
}

static func member(owner, id: String) -> Dictionary:
	for actor in owner.actors:
		if actor.id == id and actor.hp > 0: return actor
	return {}

static func available(owner) -> Array[String]:
	var ids: Array[String] = []
	for key in PAIRS:
		if not member(owner, PAIRS[key].heroes[0]).is_empty() and not member(owner, PAIRS[key].heroes[1]).is_empty(): ids.append(key)
	return ids

static func bonus(tactics, target: int, amount: float, magic: bool, damages: Dictionary) -> void:
	if target < 0 or target >= tactics.enemies.size() or tactics.enemies[target].hp <= 0: return
	var actual: float = tactics.deal(tactics.enemies[target], amount, magic, true).damage
	damages[target] = float(damages.get(target, 0.0)) + actual

static func after_attack(tactics, actor: Dictionary, target: int, context: Dictionary, hit: Dictionary, damages: Dictionary) -> float:
	var owner = tactics.run()
	var healed := 0.0
	for key in available(owner):
		if tactics.synergy_used.has(key): continue
		var supporter := {}
		var foe: Dictionary = tactics.enemies[target]
		match key:
			"hunters":
				if actor.id == "maria" and foe.get("marked", false) and foe.hp > 0: supporter = member(owner, "joao")
			"powder":
				if actor.id in ["scarlet", "matches"] and context.get("burn_owner", "") == ("matches" if actor.id == "scarlet" else "scarlet") and foe.hp > 0:
					supporter = member(owner, "matches" if actor.id == "scarlet" else "scarlet")
			"tide":
				if actor.id == "aladin" and int(context.get("wish", 0)) in [1, 2]: supporter = member(owner, "ariel")
			"threads":
				if actor.id == "puss" and context.get("charged", false): supporter = member(owner, "rapunzel")
			"dance":
				if actor.id == "peter" and int(context.get("shadows", 0)) > 0: supporter = member(owner, "mulan")
			"tea":
				if actor.id == "alice" and int(context.get("suit", 0)) in [1, 3] and foe.poison_left > 0 and foe.hp > 0: supporter = member(owner, "snow_white")
		if supporter.is_empty() or int(supporter.get("pp", 0)) <= 0: continue
		supporter.pp -= 1
		tactics.synergy_used[key] = true
		tactics.notify(supporter.id, PAIRS[key].name, "Combinação com " + str(TaleCatalog.HEROES[actor.id].name), "synergy")
		if not owner.synergies_seen.has(key): owner.synergies_seen.append(key)
		owner.synergy_activations += 1
		if not hit.has("synergies"): hit["synergies"] = []
		hit.synergies.append(key)
		match key:
			"hunters":
				bonus(tactics, target, supporter.damage * 0.8, false, damages)
				hit["followup"] = true
				if foe.poison > 0: foe.poison_left = maxf(foe.poison_left, 5.0)
			"powder":
				bonus(tactics, target, maxf(foe.burn * 2, actor.damage * 0.7), true, damages)
				foe.burn_left = maxf(0, foe.burn_left - 1.0)
			"tide":
				for ally in owner.actors:
					if ally.hp > 0:
						ally.shield = minf(ally.max_hp, ally.shield + ally.max_hp * 0.08)
						ally.energy = minf(100, ally.energy + 12)
			"threads", "tea":
				if key == "tea": bonus(tactics, target, foe.poison * 2, true, damages)
				for ally in owner.actors:
					if ally.hp <= 0: continue
					var actual := minf(ally.max_hp - ally.hp, ally.max_hp * (0.06 if key == "threads" and ally.id == "puss" else (0.05 if key == "tea" else 0.0)))
					ally.hp += actual
					healed += actual
					if key == "threads":
						ally.shield = minf(ally.max_hp, ally.shield + ally.max_hp * 0.10)
						owner.unlock_stats.healing += actual
			"dance":
				for at in tactics.eligible({"class": "vanguard"}, tactics.enemies): bonus(tactics, at, supporter.damage * 0.7, false, damages)
	return healed
