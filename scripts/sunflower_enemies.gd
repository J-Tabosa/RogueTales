extends RefCounted
## The second summer map has its own roster and a summoning boss.
const MAP := "CamposDeGirassois"
const BIOME_NAME := "Campos de Girassóis"
const WORKER := "sunflower_worker"
const QUEEN := "sunflower_queen"
const COMMON := [WORKER, "sunflower_drone", "sunflower_wasp"]
const SUMMON := "sunflower_summon"
const MANA_COST := 120.0
const MANA_PER_HIT := 30.0
const MAX_CASTS := 3
const DESCRIPTION := "A Rainha Abelha abre a luta invocando 2 ou 3 operárias. A ferroada da investida envenena e recarrega sua mana. Ela pode invocar até 3 vezes por combate."
const Formation = preload("res://scripts/formation_layout.gd")
## Name, class, health, damage, physical defense, magic defense, initiative, poison per turn.
const DATA := {
	WORKER: ["Abelha Operária", "vanguard", 139.0, 17.0, 1.8, 1.9, 50.0, 2.0],
	"sunflower_drone": ["Zangão", "vanguard", 198.0, 22.0, 3.0, 2.4, 40.0, 0.0],
	"sunflower_wasp": ["Vespa", "assassin", 104.0, 21.0, 0.9, 1.4, 70.0, 4.0],
	QUEEN: ["Rainha Abelha", "mage", 920.0, 29.0, 3.8, 5.2, 46.0, 6.0]
}

static func matches(owner) -> bool:
	return owner.expedition and owner.active_secret.is_empty() and owner.journey.get("path", []).size() > owner.stage and owner.journey.path[owner.stage] == MAP

static func profiles() -> Dictionary:
	var result := {}
	for id in DATA:
		var spec: Array = DATA[id]
		result[id] = {
			"id": id, "tipo": "Chefe" if id == QUEEN else "Comum", "bioma": BIOME_NAME,
			"nome": spec[0], "classe": spec[1], "vida_base": spec[2], "ataque_base": spec[3],
			"def_fisica_base": spec[4], "def_magica_base": spec[5], "iniciativa": spec[6],
			"qtd_ataques": 1, "esquiva": 0.0, "intervalo_visual": 3.0
		}
	return result

static func spawn(owner, edited: Dictionary) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var defaults := profiles()
	if ExpeditionContent.is_boss(owner.stage, owner.phase):
		units.append(make_unit(owner, QUEEN, edited.get(QUEEN, defaults[QUEEN]), units))
		return units
	var count: int = owner.rng.randi_range(1, ExpeditionContent.enemy_limit(owner.stage, owner.endless))
	for i in count:
		var id: String = COMMON[owner.rng.randi_range(0, COMMON.size() - 1)]
		units.append(make_unit(owner, id, edited.get(id, defaults[id]), units))
	return units

static func make_unit(owner, id: String, stats: Dictionary, units: Array[Dictionary], summoned := false) -> Dictionary:
	var row := "middle" if id == "sunflower_wasp" else "front"
	var preferences := [row, "front" if row == "middle" else "middle", "back"]
	for candidate in preferences:
		if units.filter(func(foe): return foe.row == candidate).size() < Formation.MAX_PER_ROW:
			row = candidate
			break
	var depth: int = maxi(0, owner.rooms_cleared - 6) if owner.endless else 0
	var growth := (1 + depth * .05) * pow(1.045, mini(depth, 120)) * (1 + maxi(0, depth - 120) * .08)
	var hp := float(stats.vida_base) * growth * (1.35 if owner.room_kind == "elite" else 1.0) * (.58 if summoned else 1.0)
	var damage := float(stats.ataque_base) * (1 + depth * .85 / 13) * (1.15 if owner.room_kind == "elite" else 1.0) * (.72 if summoned else 1.0)
	var slot := units.size()
	var unit := {
		"id": "enemy_%d" % slot, "sunflower_id": id, "balance_id": id, "name": stats.nome,
		"class": stats.classe, "category": "beast", "range": "short", "flying": true, "row": row,
		"hp": hp, "max_hp": hp, "damage": damage, "armor": float(stats.def_fisica_base),
		"magic_defense": float(stats.def_magica_base), "initiative": float(stats.iniciativa),
		"attacks": int(stats.qtd_ataques), "evasion": float(stats.esquiva), "interval": float(stats.intervalo_visual),
		"boss": id == QUEEN, "biome": owner.current_biome(), "variant": 0, "slot": slot,
		"action_count": 0, "intent": {}, "summoned": summoned
	}
	if id == QUEEN:
		unit.merge({"mana": MANA_COST, "max_mana": MANA_COST, "casts": 0, "opens_combat": true})
	return unit

static func plan(foe: Dictionary, target: int) -> Dictionary:
	if foe.boss and int(foe.casts) < MAX_CASTS and float(foe.mana) >= MANA_COST:
		return {"key": SUMMON, "title": "Chamado da Colmeia", "glyph": "magic", "target": -1, "targets": [], "locked": false}
	var title: String = "Pancada" if foe.sunflower_id == "sunflower_drone" else "Ferroada"
	return {"key": "sunflower_strike", "title": title, "glyph": "sword", "target": target, "targets": [target] if target >= 0 else [], "locked": false}

static func execute(tactics, index: int, intent: Dictionary) -> Dictionary:
	var owner = tactics.run()
	var foe: Dictionary = tactics.enemies[index]
	if intent.key == SUMMON:
		foe.mana -= MANA_COST
		foe.casts += 1
		foe.opens_combat = false
		# Keep slots stable for the round queue and reserve at least two for each later cast.
		var reserved := (MAX_CASTS - int(foe.casts)) * 2
		var available := Formation.ROWS.size() * Formation.MAX_PER_ROW - int(tactics.enemies.size()) - reserved
		var count: int = owner.rng.randi_range(2, mini(3, available))
		var stats: Dictionary = tactics.EnemyBalance.profiles.get(WORKER, profiles()[WORKER])
		for i in count:
			var worker := make_unit(owner, WORKER, stats, tactics.enemies, true)
			tactics.Rules.initialize_enemy(worker)
			tactics.enemies.append(worker)
		tactics.sync_totals()
		return {"target": -1, "targets": [], "target_damage": {}, "damage": 0.0, "evaded": false,
			"enemy": index, "message": intent.title, "non_attack": true, "summoned": count}

	var hit: Dictionary = tactics.Rules.incoming(tactics, index, int(intent.target))
	if hit.is_empty() or hit.evaded or hit.get("blocked_spirit", false):
		return hit
	hit["message"] = intent.title
	var potency := float(DATA[foe.sunflower_id][7])
	if potency > 0:
		tactics.Rules.status(owner.actors[hit.target], "poison", foe.id, 2, potency)
	if foe.boss and int(foe.casts) < MAX_CASTS:
		foe.mana = minf(MANA_COST, float(foe.mana) + MANA_PER_HIT)
	return hit
