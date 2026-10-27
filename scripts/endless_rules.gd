extends RefCounted
## Compact endless progression: no growing replay history, no finite offer pool.
const KEYS := ["max_hp", "damage", "interval", "crit", "armor", "leech", "energy_bonus", "evasion", "base_evasion", "physical_damage", "magic_damage", "magic_defense", "physical_defense", "initiative", "attacks", "mana_max", "mana_hit", "mana_turn", "crit_multiplier", "legacy_damage_base"]

static func template() -> Dictionary:
	return {"hp_scale": 1.0, "hp_flat": 0.0, "damage_scale": 1.0, "interval_scale": 1.0, "crit_flat": 0.0, "armor_flat": 0.0, "leech_flat": 0.0, "initiative_flat":0.0, "attacks_flat":0}

static func safe(value: float, minimum := 0.0) -> float:
	return clampf(value, minimum, 1.0e100) if is_finite(value) else minimum

static func health_scale(depth: int) -> float:
	return safe(pow(1.15, mini(depth, 60)) * (1.0 + maxi(0, depth - 60) * 0.15), 1.0)

static func apply_template(owner, actor: Dictionary) -> void:
	var data: Dictionary = owner.team_template
	actor.max_hp = safe(actor.max_hp * data.hp_scale + data.hp_flat, 1.0)
	actor.hp = actor.max_hp
	actor.damage = safe(actor.damage * data.damage_scale, 1.0)
	actor.initiative=minf(100,float(actor.get("initiative",50))+float(data.get("initiative_flat",0)))
	actor.attacks=maxi(1,int(actor.get("attacks",1))+int(data.get("attacks_flat",0)))
	actor.crit = minf(0.95, actor.crit + data.crit_flat)
	actor.armor = safe(actor.armor + data.armor_flat)
	actor.leech = safe(actor.leech + data.leech_flat)
	for key in owner.relics:
		if key.begins_with("skill:"): owner.apply_relic_to_actor(actor, key)

static func add_upgrade(owner, id: String) -> bool:
	var item := TaleCatalog.offer_data(id)
	if item.is_empty() or item.has("hero") or item.has("bonus"): return false
	if item.has("owner") and (not owner.actor_ids().has(item.owner) or owner.upgrade_count(id) > 0): return false
	var copies: int = owner.upgrade_count(id)
	owner.upgrade_counts[id] = copies + 1
	if not owner.relics.has(id): owner.relics.append(id)
	if item.has("owner"):
		for actor in owner.actors: owner.apply_relic_to_actor(actor, id)
		return true
	var factor := 1.0
	var amount := 0.0
	match id:
		"power":
			factor = 1.0 + 0.2 / (1.0 + copies * 0.08)
			owner.team_template.damage_scale = safe(owner.team_template.damage_scale * factor, 0.001)
		"heart": owner.team_template.hp_flat = safe(owner.team_template.hp_flat + 25)
		"haste":
			amount=10.0
			owner.team_template.initiative_flat+=amount
		"critical":
			amount = 0.12 / (1.0 + copies * 0.10)
			owner.team_template.crit_flat += amount
		"armor":
			amount = 3.0 / (1.0 + copies * 0.12)
			owner.team_template.armor_flat = safe(owner.team_template.armor_flat + amount)
		"leech":
			amount = 3.0 / (1.0 + copies * 0.08)
			owner.team_template.leech_flat = safe(owner.team_template.leech_flat + amount)
	for actor in owner.actors:
		match id:
			"power": actor.damage = safe(actor.damage * factor, 1.0)
			"heart":
				actor.max_hp = safe(actor.max_hp + 25, 1.0)
				if actor.hp > 0: actor.hp = minf(actor.max_hp, actor.hp + 40)
			"haste": actor.initiative=minf(100,float(actor.get("initiative",50))+amount)
			"critical": actor.crit = minf(0.95, actor.crit + amount)
			"armor": actor.armor = safe(actor.armor + amount)
			"leech": actor.leech = safe(actor.leech + amount)
	return true

static func event(owner, key: String) -> void:
	if key == "curse":
		owner.team_template.hp_scale *= 0.9
		owner.team_template.hp_flat *= 0.9
	var factor := 1.18 if key == "curse" else 1.10
	owner.team_template.damage_scale = safe(owner.team_template.damage_scale * factor, 0.001)
	for actor in owner.actors:
		actor.damage = safe(actor.damage * factor, 1.0)
		if key == "curse":
			actor.max_hp = safe(actor.max_hp * 0.9, 1.0)
			actor.hp = minf(actor.hp, actor.max_hp)

static func snapshot(owner) -> Dictionary:
	var stats := {}
	for actor in owner.actors:
		var data := {"mutations": actor.get("mutations", []).duplicate()}
		for key in KEYS: data[key] = actor[key]
		stats[actor.id] = data
	return {"template": owner.team_template.duplicate(), "counts": owner.upgrade_counts.duplicate(), "stats": stats}

static func restore(owner, data: Dictionary) -> void:
	owner.team_template = template()
	owner.upgrade_counts.clear()
	var stored_template: Variant = data.get("template", {})
	if stored_template is Dictionary:
		for key in owner.team_template:
			if stored_template.has(key): owner.team_template[key] = float(stored_template[key]) if key=="initiative_flat" and is_finite(float(stored_template[key])) else safe(float(stored_template[key]))
	var counts: Variant = data.get("counts", {})
	if counts is Dictionary:
		for key in counts:
			if not TaleCatalog.offer_data(str(key)).is_empty(): owner.upgrade_counts[key] = clampi(int(counts[key]), 0, 2147483647)
	var saved: Variant = data.get("stats", {})
	for actor in owner.actors:
		var stats: Variant = saved.get(actor.id, {}) if saved is Dictionary else {}
		if not stats is Dictionary: continue
		for key in KEYS:
			if stats.has(key): actor[key] = float(stats[key]) if key=="initiative" and is_finite(float(stats[key])) else safe(float(stats[key]), 1.0 if key in ["max_hp", "damage"] else 0.0)
		actor.interval = maxf(0.65, actor.interval)
		actor.crit = clampf(actor.crit, 0, 0.95)
		actor.mutations.clear()
		for key in stats.get("mutations", []):
			var mutation := ExpeditionContent.offer("skill:%s:%s" % [actor.id, key])
			if not mutation.is_empty() and not actor.mutations.has(key): actor.mutations.append(key)


static func promote(owner) -> void:
	# Replay only the global modifiers into the recruit template. Existing actors stay exact.
	owner.team_template = template()
	owner.upgrade_counts.clear()
	for key in owner.build_history:
		match key:
			"event:curse":
				owner.team_template.hp_scale *= 0.9
				owner.team_template.hp_flat *= 0.9
				owner.team_template.damage_scale *= 1.18
			"event:elite": owner.team_template.damage_scale *= 1.10
			_:
				owner.upgrade_counts[key] = int(owner.upgrade_counts.get(key, 0)) + 1
				match key:
					"power": owner.team_template.damage_scale *= 1.2
					"heart": owner.team_template.hp_flat += 25
					"haste": owner.team_template.interval_scale *= 0.88
					"critical": owner.team_template.crit_flat += 0.12
					"armor": owner.team_template.armor_flat += 3
					"leech": owner.team_template.leech_flat += 3
	var unique: Array[String] = []
	for key in owner.relics:
		if not unique.has(key): unique.append(key)
	owner.relics = unique
	owner.build_history.clear()
