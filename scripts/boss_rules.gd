extends RefCounted
## Boss rules and deterministic enemy plans. No rendering and no random target rerolls.
const Abilities = preload("res://scripts/hero_abilities.gd")
const DESCRIPTIONS := {
	3: "Estandarte de ferro: reduz em 40% o dano recebido pelo General. Destrua o estandarte para interromper a próxima ação dele. O General alterna preparação e golpe na vanguarda.",
	7: "A Guardiã do Índice reimprime a última ULT usada pela equipe, com o poder dela. ULTs de cura e escudo também podem ser copiadas. Sem uma ULT registrada, prepara uma rajada mágica.",
	11: "A Costureira sela habilidades ativas com dois fios expostos. Destrua o fio ligado ao personagem para libertá-lo. Personagens selados ainda usam ataque básico e ULT. Os fios podem ser alcançados de ambas as linhas."
}

static func description(stage: int) -> String:
	return DESCRIPTIONS.get(stage, "")

static func setup(tactics) -> void:
	var owner = tactics.run()
	tactics.last_ultimate = {}
	for actor in owner.actors:
		actor["sealed"] = false
		actor["hindered_rounds"] = 0
		actor["hostile_burn"] = 0.0
		actor["hostile_poison"] = 0.0
		actor["hostile_dot_left"] = 0.0
	for foe in tactics.enemies:
		foe["action_count"] = 0
		foe["intent"] = {}
	if not ExpeditionContent.is_boss(owner.stage) or tactics.enemies.is_empty(): return
	var boss: Dictionary = tactics.enemies[0]
	boss["mechanic"] = owner.stage
	if owner.stage == 3 and tactics.enemies.size() > 1:
		boss["class"] = "vanguard"
		boss.row = "front"
		boss["guarded_by_banner"] = true
		tactics.enemies[1].name = "Estandarte de Ferro"
		tactics.enemies[1]["banner"] = true
		tactics.enemies[1].row = "back"
		tactics.enemies[1].damage = 0.0
		tactics.enemies[1].evasion = 0.0
	elif owner.stage == 11:
		for index in range(1, tactics.enemies.size()):
			var thread: Dictionary = tactics.enemies[index]
			thread.name = "Fio Rubro" if index == 1 else "Fio Violeta"
			thread["binds"] = owner.actors[(index - 1) % owner.actors.size()].id
			thread["exposed"] = true
			thread.row = "back"
			thread.evasion = 0.0
			thread.damage *= 0.6
	refresh(tactics)

static func refresh(tactics) -> void:
	var owner = tactics.run()
	for actor in owner.actors: actor["sealed"] = false
	for foe in tactics.enemies:
		if foe.hp > 0 and foe.has("binds"):
			for actor in owner.actors:
				if actor.id == foe.binds: actor.sealed = true
	if owner.stage == 3 and not tactics.enemies.is_empty():
		var boss: Dictionary = tactics.enemies[0]
		if boss.get("guarded_by_banner", false):
			var protected := false
			for foe in tactics.enemies:
				if foe.get("banner", false) and foe.hp > 0: protected = true
			if not protected:
				boss.guarded_by_banner = false
				boss["staggered"] = true
				boss["intent"] = {} # Banner destruction also interrupts a committed windup.

static func round_start(tactics) -> void:
	for actor in tactics.run().actors: actor.hindered_rounds = maxi(0, int(actor.get("hindered_rounds", 0)) - 1)

static func living(units: Array, row := "") -> Array[int]:
	var result: Array[int] = []
	for index in units.size():
		if units[index].hp > 0 and (row.is_empty() or units[index].row == row): result.append(index)
	return result

static func plan(tactics, index: int) -> Dictionary:
	if index < 0 or index >= tactics.enemies.size(): return {}
	var foe: Dictionary = tactics.enemies[index]
	if foe.hp <= 0: return {}
	var stored: Dictionary = foe.get("intent", {})
	if stored.get("locked", false): return stored
	var owner = tactics.run()
	var target: int = tactics.choose_target(foe, owner.actors)
	var result := {"key": "attack", "title": "Ataque", "glyph": "sword", "target": target, "targets": [target] if target >= 0 else [], "power": 1.0, "magical": foe["class"] == "mage", "locked": false}
	if not foe.get("boss", false) and not foe.has("binds") and foe["class"] == "mage":
		result.merge({"key": "storm", "title": "Conjuração em área", "power": 0.68, "magical": true, "targets": living(owner.actors)}, true)
	if not foe.get("boss", false) and not foe.has("binds") and int(foe.get("action_count", 0)) % 3 == 2:
		match str(foe["class"]):
			"vanguard": result.merge({"key": "heavy", "title": "Investida brutal", "power": 1.45}, true)
			"ranger": result.merge({"key": "volley", "title": "Rajada certeira", "power": 1.35}, true)
			"mage": result.merge({"key": "storm", "title": "Pulso sombrio", "power": 0.85, "magical": true, "targets": living(owner.actors)}, true)
			"assassin": result.merge({"key": "ambush", "title": "Emboscada", "power": 1.55}, true)
	if foe.get("banner", false):
		result.merge({"key": "banner", "title": "Proteger General", "glyph": "shield", "targets": []}, true)
	elif foe.get("staggered", false):
		result.merge({"key": "stagger", "title": "Interrompido", "glyph": "warning", "targets": []}, true)
	elif foe.get("boss", false):
		match int(foe.get("mechanic", -1)):
			3:
				if int(foe.action_count) % 2 == 0: result.merge({"key": "prepare", "title": "Erguer a lâmina", "glyph": "warning", "targets": []}, true)
				else:
					var front := living(owner.actors, "front")
					result.merge({"key": "sweep", "title": "Avanço de Jade", "power": 1.75, "magical": false, "targets": front if not front.is_empty() else living(owner.actors)}, true)
			7:
				if not tactics.last_ultimate.is_empty():
					var id: String = tactics.last_ultimate.hero
					result.merge({"key": "copy", "title": "Reimprimir: " + str(TaleCatalog.HERO_TACTICS[id].ult), "glyph": "mirror", "copy": id, "serial": tactics.last_ultimate.serial, "targets": copy_targets(tactics, id)}, true)
				else: result.merge({"key": "ink", "title": "Rajada de Tinta", "glyph": "magic", "power": 1.25, "magical": true}, true)
			11:
				if int(foe.action_count) % 2 == 0: result.merge({"key": "pull", "title": "Puxar os Fios", "glyph": "bind", "targets": living(owner.actors)}, true)
				else: result.merge({"key": "stitch", "title": "Costura Cruel", "glyph": "magic", "power": 1.8, "magical": true}, true)
	if not result.targets.is_empty(): result.target = result.targets[0]
	foe.intent = result
	return result

static func copy_targets(tactics, id: String) -> Array[int]:
	var units: Array = tactics.run().actors
	if id == "rapunzel": return []
	if id in ["scarlet", "alice", "ariel", "aladin"]: return living(units)
	var row: String = "front" if id in ["mulan", "puss"] else "back"
	var targets := living(units, row)
	if targets.is_empty(): targets = living(units)
	return targets if id in ["mulan", "puss"] else targets.slice(0, 1)

static func execute(tactics, index: int) -> Dictionary:
	var owner = tactics.run()
	var intent := plan(tactics, index).duplicate(true)
	if intent.is_empty() or not owner.alive(): return {}
	var foe: Dictionary = tactics.enemies[index]
	foe.action_count = int(foe.get("action_count", 0)) + 1
	foe.intent = {}
	if intent.key == "attack": return Abilities.incoming(tactics, index, int(intent.target))
	var targets: Array[int] = []
	for at in intent.targets:
		if at >= 0 and at < owner.actors.size() and owner.actors[at].hp > 0: targets.append(at)
	var fallback: int = tactics.choose_target(foe, owner.actors)
	if targets.is_empty() and not intent.key in ["banner", "prepare", "stagger"] and intent.get("copy", "") != "rapunzel" and fallback >= 0: targets.append(fallback)
	var result := {"target": fallback, "targets": targets, "target_damage": {}, "damage": 0.0, "evaded": false, "critical": false, "enemy": index, "message": intent.title, "non_attack": false}
	if intent.key in ["banner", "prepare", "stagger"]:
		result.non_attack = true
		if intent.key == "prepare": foe["shield"] = minf(foe.max_hp * 0.12, float(foe.get("shield", 0)) + foe.max_hp * 0.06)
		if intent.key == "stagger": foe.staggered = false
	elif intent.key == "pull":
		result.non_attack = true
		var threads := 0
		for unit in tactics.enemies:
			if unit.hp > 0 and unit.has("binds"): threads += 1
		for at in targets: owner.actors[at].energy = maxf(0, owner.actors[at].energy - 12)
		foe.hp = minf(foe.max_hp, foe.hp + foe.max_hp * 0.04 * threads)
	elif intent.key == "copy":
		var id: String = intent.copy
		var multiplier: float = {"scarlet": 2.0, "snow_white": 4.0, "mulan": 3.2, "ariel": 1.6, "joao": 4.2, "maria": 2.8, "alice": 2.0, "puss": 3.6, "peter": 3.0, "matches": 4.0, "aladin": 2.0}.get(id, 1.0)
		for at in targets:
			var hit := strike(tactics, foe, at, multiplier * 0.65, id in ["scarlet", "alice", "ariel", "aladin"], result)
			if hit.is_empty() or hit.evaded: continue
			var actual: int = hit.target
			if id in ["scarlet", "matches", "snow_white", "maria"]:
				owner.actors[actual]["hostile_burn" if id in ["scarlet", "matches"] else "hostile_poison"] = foe.damage * 0.10
				owner.actors[actual].hostile_dot_left = 4.0
			if id == "ariel": owner.actors[actual].hindered_rounds = 2
		if id in ["rapunzel", "ariel", "aladin"]: foe.hp = minf(foe.max_hp, foe.hp + foe.max_hp * (0.35 if id == "rapunzel" else (0.20 if id == "ariel" else 0.15)))
		if id in ["rapunzel", "mulan", "puss", "aladin"]: foe["shield"] = minf(foe.max_hp, float(foe.get("shield", 0)) + foe.max_hp * {"rapunzel": 0.20, "mulan": 0.35, "puss": 0.25, "aladin": 0.15}[id])
		if id == "peter": foe.evasion = minf(0.6, foe.evasion + 0.15)
		if targets.is_empty(): result.non_attack = true
		# A ULT used during the windup stays available for the next action.
		if tactics.last_ultimate.get("serial", -1) == intent.get("serial", -2): tactics.last_ultimate = {}
	else:
		for at in targets: strike(tactics, foe, at, float(intent.power), bool(intent.magical), result)
	Abilities.deaths(tactics)
	if not result.target_damage.is_empty():
		result.targets = result.target_damage.keys()
		result.target = result.targets[0]
		result.evaded = result.get("target_evaded", {}).values().all(func(value): return value)
	refresh(tactics)
	tactics.sync_totals()
	return result

static func strike(tactics, foe: Dictionary, at: int, power: float, magic: bool, result: Dictionary) -> Dictionary:
	# Reuse survival, support, counter and interception reactions for boss skills.
	var old_damage: float = foe.damage
	var old_class: String = foe["class"]
	foe.damage = old_damage * power
	foe["class"] = "mage" if magic else "vanguard"
	var hit: Dictionary = Abilities.incoming(tactics, int(foe.get("slot", 0)), at)
	foe.damage = old_damage
	foe["class"] = old_class
	if not hit.is_empty():
		if not result.has("target_evaded"): result["target_evaded"] = {}
		if not result.has("target_guarded"): result["target_guarded"] = {}
		result.target_evaded[hit.target] = hit.evaded
		result.target_guarded[hit.target] = hit.get("guarded", false)
		if not result.has("target_heal"): result["target_heal"] = {}
		result.target_heal[hit.target] = float(result.target_heal.get(hit.target, 0)) + float(hit.get("support_heal", 0))
		result.target_damage[hit.target] = float(result.target_damage.get(hit.target, 0)) + hit.damage
		result.damage += hit.damage
		for key in ["counter", "support_heal"]:
			if hit.has(key): result[key] = float(result.get(key, 0)) + hit[key]
	return hit
