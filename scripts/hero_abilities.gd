extends RefCounted
## The twelve run kits. PP is an internal ready charge with a six-second cooldown.
const Content = preload("res://scripts/expedition_content.gd")
const Synergies = preload("res://scripts/team_synergies.gd")

static func has(actor: Dictionary, key: String) -> bool:
	return Content.has(actor, key)

static func heal(owner, ally: Dictionary, amount: float, source := "") -> float:
	if ally.hp <= 0: return 0.0
	var restored := minf(amount, ally.max_hp - ally.hp)
	ally.hp += restored
	if source == "rapunzel": owner.unlock_stats.healing += restored
	return restored

static func weakest(owner, except := "") -> Dictionary:
	var chosen := {}
	for ally in owner.actors:
		if ally.hp > 0 and ally.id != except and (chosen.is_empty() or ally.hp / ally.max_hp < chosen.hp / chosen.max_hp): chosen = ally
	return chosen

static func shield_group(owner, fraction: float) -> void:
	for ally in owner.actors:
		if ally.hp > 0: ally.shield = minf(ally.max_hp, ally.shield + ally.max_hp * fraction)

static func extra(tactics, at: int, amount: float, magic: bool, damages: Dictionary) -> void:
	if at < 0 or at >= tactics.enemies.size() or tactics.enemies[at].hp <= 0: return
	var result: Dictionary = tactics.deal(tactics.enemies[at], amount, magic, true)
	damages[at] = float(damages.get(at, 0.0)) + float(result.damage)

static func ignite(enemy: Dictionary, strength: float, duration := 5.0, source := "") -> void:
	if enemy.hp <= 0: return
	enemy.burn = maxf(enemy.burn, strength)
	enemy.burn_left = maxf(enemy.burn_left, duration)
	if not source.is_empty(): enemy["burn_owner"] = source

static func poison(enemy: Dictionary, strength: float) -> void:
	if enemy.hp <= 0: return
	enemy.poison = minf(strength * 4, enemy.poison + strength)
	enemy.poison_left = 5.0

static func attack(tactics, index: int, requested: int) -> Dictionary:
	var owner = tactics.run()
	if index < 0 or index >= owner.actors.size() or owner.actors[index].hp <= 0: return {}
	var actor: Dictionary = owner.actors[index]
	var valid: Array = tactics.eligible(actor, tactics.enemies)
	var target: int = requested if valid.has(requested) else tactics.target_for(index)
	if target < 0: return {}
	var foe: Dictionary = tactics.enemies[target]
	if actor.get("sealed", false): return basic(tactics, actor, target)
	var old_burn_owner: String = foe.get("burn_owner", "") if foe.burn_left > 0 else ""
	var number := int(actor.hits) + 1
	var critical: bool = owner.rng.randf() < actor.crit
	var amount: float = actor.damage * (2.0 if critical else 1.0)
	var magical: bool = actor["class"] in ["mage", "artificer"]
	var charged: bool = actor.get("charged", false)
	var shadows := int(actor.get("shadows", 0))
	var suit := int(actor.get("suit", 0)) % 4
	var wish := int(actor.get("wish", 0)) % 3
	var combo: bool = actor.id == "mulan" and number % (2 if has(actor, "quick") else 3) == 0
	var venom: float = foe.poison if foe.poison_left > 0 else 0.0
	if combo: amount *= 1.8
	if actor.id == "puss": amount *= 2.4 if charged else 0.65
	if actor.id == "joao" and foe.get("marked", false): amount *= 1.4
	if actor.id == "maria" and number % 2 == 0: amount += venom * 2.5
	if actor.id == "peter": amount *= 1.0 + shadows * 0.6
	if actor.id == "alice" and suit == 0: amount *= 1.5
	if actor.id == "aladin" and wish == 0: amount *= 1.7
	# João's optional mark benefits the other members as well.
	if actor.id != "joao" and foe.get("marked", false):
		for hunter in owner.actors:
			if hunter.id == "joao" and hunter.hp > 0 and has(hunter, "hunt"): amount *= 1.2
	var hit: Dictionary = tactics.deal(foe, amount, magical)
	hit.merge({"target": target, "targets": [target], "critical": critical, "message": "Esquiva" if hit.evaded else Content.KITS[actor.id][0]})
	var damages := {target: hit.damage}
	var healed := 0.0
	actor.energy = minf(100, actor.energy + (8.0 if hit.evaded else 18.0 + actor.energy_bonus))
	if hit.evaded:
		if foe["class"] == "assassin" and int(foe.get("pp", 0)) > 0:
			foe.pp -= 1
			hit["counter"] = tactics.deal(actor, foe.damage * 0.6, false, true).damage
	else:
		actor.hits = number
		if TaleCatalog.NEW_HERO_IDS.has(actor.id):
			if not owner.unlock_stats.has("new_hits"): owner.unlock_stats["new_hits"] = {}
			owner.unlock_stats.new_hits[actor.id] = int(owner.unlock_stats.new_hits.get(actor.id, 0)) + 1
		match str(actor.id):
			"scarlet":
				ignite(foe, actor.damage * 0.12, 5.0, "scarlet")
				foe["powder"] = int(foe.get("powder", 0)) + 1
				if foe.powder >= (2 if has(actor, "quick") else 3):
					foe.powder = 0
					extra(tactics, target, actor.damage, true, damages)
					for at in tactics.enemies.size():
						if at != target: extra(tactics, at, actor.damage * 0.45, true, damages)
						if has(actor, "spread"): ignite(tactics.enemies[at], actor.damage * 0.12, 5.0, "scarlet")
					if has(actor, "shelter"): shield_group(owner, 0.12)
					hit.message = "Explosão de pólvora"
				if critical and actor.pp > 0 and tactics.enemies.any(func(unit): return unit.hp > 0):
					actor.pp -= 1
					actor.energy = minf(100, actor.energy + 20)
					tactics.notify(actor.id, Content.KITS[actor.id][2], "+20 mana no acerto crítico")
			"rapunzel":
				var ally := weakest(owner)
				if not ally.is_empty():
					healed += heal(owner, ally, ally.max_hp * 0.08, "rapunzel")
					if has(actor, "barrier"): ally.shield = minf(ally.max_hp, ally.shield + ally.max_hp * 0.08)
					if has(actor, "twin"):
						var second := weakest(owner, ally.id)
						if not second.is_empty(): healed += heal(owner, second, second.max_hp * 0.08, "rapunzel")
			"snow_white":
				if venom > 0:
					healed += heal(owner, actor, actor.max_hp * 0.06)
					if has(actor, "harvest"):
						var ally := weakest(owner, actor.id)
						if not ally.is_empty(): healed += heal(owner, ally, ally.max_hp * 0.06)
				poison(foe, actor.damage * (0.20 if has(actor, "stack") else 0.10))
			"mulan":
				if combo:
					owner.unlock_stats.combos += 1
					var targets: Array = range(tactics.enemies.size()) if has(actor, "dragon") else tactics.eligible({"class": "vanguard"}, tactics.enemies)
					for at in targets:
						if at != target: extra(tactics, at, actor.damage * 0.8, false, damages)
					hit.message = "Combo de jade"
			"ariel":
				if number % (2 if has(actor, "quick") else 3) == 0:
					for ally in owner.actors: healed += heal(owner, ally, ally.max_hp * 0.12)
					if has(actor, "tide"): tactics.slow_left = maxf(tactics.slow_left, 4.0)
					if has(actor, "overflow"): shield_group(owner, 0.10)
			"joao":
				foe["marked"] = true
			"maria":
				if number % 2 == 0 and venom > 0:
					foe.poison *= 0.5 if has(actor, "keep") else 0.0
					if not has(actor, "keep"): foe.poison_left = 0
					healed += heal(owner, actor, actor.max_hp * 0.12)
					if has(actor, "feast"):
						for ally in owner.actors:
							if ally.id != actor.id: healed += heal(owner, ally, ally.max_hp * 0.08)
					hit.message = "Receita consumida"
				else: poison(foe, actor.damage * 0.14)
			"alice":
				if suit == 1:
					var ally := weakest(owner)
					if has(actor, "heart"):
						for member in owner.actors: healed += heal(owner, member, member.max_hp * 0.10)
					elif not ally.is_empty(): healed += heal(owner, ally, ally.max_hp * 0.15)
				elif suit == 2: shield_group(owner, 0.10)
				elif suit == 3:
					for at in tactics.enemies.size():
						if at != target and tactics.enemies[at].hp > 0:
							extra(tactics, at, actor.damage * 0.75, true, damages)
							if not has(actor, "double"): break
				actor.suit = (suit + 1) % 4
				if actor.suit == 0 and has(actor, "wild"):
					actor.pp = mini(2, actor.pp + 1)
					actor.energy = minf(100, actor.energy + 25)
				hit.message = ["Espadas", "Copas", "Ouros", "Paus"][suit]
			"puss":
				actor.charged = not charged
				if charged:
					var targets: Array = range(tactics.enemies.size()) if has(actor, "sweep") else tactics.eligible({"class": "vanguard"}, tactics.enemies)
					for at in targets:
						if at != target: extra(tactics, at, actor.damage * 1.2, false, damages)
					hit.message = "Corte do crepúsculo"
				else: hit.message = "Preparando a lâmina"
			"matches":
				ignite(foe, minf(actor.damage * 0.5, foe.burn + actor.damage * 0.13), 5.0, "matches")
				if has(actor, "spread"):
					for at in tactics.enemies.size():
						if at != target and tactics.enemies[at].hp > 0:
							ignite(tactics.enemies[at], actor.damage * 0.10, 5.0, "matches")
							break
			"peter":
				actor.shadows = 1 if shadows > 0 and has(actor, "keep") else 0
				if shadows > 0 and has(actor, "veil"):
					actor.evasion = minf(0.8, actor.base_evasion + 0.20)
					actor.evasion_left = 4.0
			"aladin":
				var factor := 2.0 if has(actor, "generous") else 1.0
				if wish == 0 and has(actor, "storm"):
					for at in tactics.enemies.size():
						if at != target and tactics.enemies[at].hp > 0:
							extra(tactics, at, actor.damage, true, damages)
							break
				elif wish == 1: shield_group(owner, 0.12 * factor)
				elif wish == 2:
					for ally in owner.actors: healed += heal(owner, ally, ally.max_hp * 0.10 * factor)
				actor.wish = (wish + 1) % 3
		healed += Synergies.after_attack(tactics, actor, target, {"burn_owner": old_burn_owner, "wish": wish, "charged": charged, "shadows": shadows, "suit": suit}, hit, damages)
		# João reacts only once per PP to another member's hit on his mark.
		if actor.id != "joao" and foe.get("marked", false) and foe.hp > 0:
			for hunter in owner.actors:
				if hunter.id == "joao" and hunter.hp > 0 and hunter.pp > 0:
					hunter.pp -= 1
					extra(tactics, target, hunter.damage * 0.6 + (foe.armor if has(hunter, "pierce") else 0), false, damages)
					hit["followup"] = true
					tactics.notify(hunter.id, Content.KITS[hunter.id][2], "Disparo extra na presa marcada")
					break
		if actor.leech > 0: healed += heal(owner, actor, actor.leech)
	hit["target_damage"] = damages
	hit.targets = damages.keys()
	hit.damage = 0.0
	for value in damages.values(): hit.damage += value
	hit["healed"] = healed
	for key in hit.get("synergies", []): hit.message += " · " + str(Synergies.PAIRS[key].name)
	deaths(tactics)
	tactics.sync_totals()
	return hit

static func incoming(tactics, enemy_index: int, requested := -1) -> Dictionary:
	var owner = tactics.run()
	if enemy_index < 0 or enemy_index >= tactics.enemies.size() or tactics.enemies[enemy_index].hp <= 0: return {}
	var enemy: Dictionary = tactics.enemies[enemy_index]
	var target: int = requested if requested >= 0 and requested < owner.actors.size() and owner.actors[requested].hp > 0 else tactics.choose_target(enemy, owner.actors)
	if target < 0: return {}
	var protected := false
	if owner.actors[target].hp / owner.actors[target].max_hp < 0.45:
		for at in owner.actors.size():
			var guard: Dictionary = owner.actors[at]
			if at != target and guard.id == "puss" and guard.hp > 0 and guard.pp > 0:
				guard.pp -= 1
				target = at
				protected = true
				tactics.notify(guard.id, Content.KITS[guard.id][2], "Interceptou o golpe de um aliado")
				break
	var actor: Dictionary = owner.actors[target]
	var before_shield: float = actor.shield
	var focused: bool = enemy["class"] == "mage" and int(enemy.get("pp", 0)) > 0
	if focused: enemy.pp -= 1
	var hit: Dictionary = tactics.deal(actor, enemy.damage * tactics.pressure() * (0.75 if protected else 1.0) * (1.2 if focused else 1.0), enemy["class"] == "mage")
	if focused: hit["focused"] = true
	if not hit.evaded and actor.hp > 0 and enemy["class"] == "ranger" and int(enemy.get("pp", 0)) > 0:
		enemy.pp -= 1
		hit.damage += tactics.deal(actor, enemy.damage * tactics.pressure() * 0.25, false, true).damage
		hit["followup"] = true
	hit["target"] = target
	hit["enemy"] = enemy_index
	if protected: hit["guarded"] = true
	if hit.evaded and actor.id == "peter" and actor.pp > 0:
		actor.pp -= 1
		actor.shadows = mini(3, int(actor.get("shadows", 0)) + (2 if has(actor, "double") else 1))
		hit["counter"] = tactics.deal(enemy, actor.damage * 0.6, false, true).damage
		tactics.notify(actor.id, Content.KITS[actor.id][2], "Esquivou, criou sombra e contra-atacou")
	elif not hit.evaded:
		if actor.id == "mulan" and hit.get("guarded", false):
			tactics.notify(actor.id, Content.KITS[actor.id][2], "Aparou e devolveu o corte")
			hit["counter"] = tactics.deal(enemy, actor.damage * 0.45, false, true).damage
			actor.shield = minf(actor.max_hp, actor.shield + actor.max_hp * 0.10)
			if has(actor, "guard"): shield_group(owner, 0.08)
		elif actor.id == "maria" and actor.pp > 0:
			tactics.notify(actor.id, Content.KITS[actor.id][2], "Envenenou o agressor")
			actor.pp -= 1
			poison(enemy, actor.damage * 0.16)
			if has(actor, "toxic"):
				for foe in tactics.enemies:
					if foe != enemy: poison(foe, actor.damage * 0.10)
		elif actor.id == "alice" and actor.pp > 0:
			tactics.notify(actor.id, Content.KITS[actor.id][2], "Avançou o naipe e ganhou 25 mana")
			actor.pp -= 1
			actor.suit = (int(actor.get("suit", 0)) + 1) % 4
			actor.energy = minf(100, actor.energy + 25)
		if owner.blessing == "thorns" and hit.damage > 0:
			hit["counter"] = float(hit.get("counter", 0.0)) + tactics.deal(enemy, hit.damage * 0.25, true, true).damage
		# Survival effects happen once per run, before any rescue can heal the unit.
		if actor.hp <= 0 and actor.id == "puss" and has(actor, "nine") and not actor.get("nine_used", false):
			actor.nine_used = true
			tactics.notify(actor.id, "Nove vidas", "Voltou com 30% da vida")
			actor.hp = actor.max_hp * 0.30
		if actor.hp <= 0 and actor.id == owner.leader and owner.blessing == "mercy" and not owner.mercy_used:
			owner.mercy_used = true
			tactics.notify(actor.id, "Uma última página", "A bênção impediu a queda")
			actor.hp = actor.max_hp * 0.35
		if actor.hp > 0:
			for support in owner.actors:
				if support.hp <= 0 or support.pp <= 0: continue
				if support.id == "rapunzel" and actor.hp / actor.max_hp < (0.65 if has(support, "rescue") else 0.45):
					support.pp -= 1
					tactics.notify(support.id, Content.KITS[support.id][2], "Socorreu " + str(TaleCatalog.HEROES[actor.id].name))
					hit["support_heal"] = heal(owner, actor, actor.max_hp * (0.20 if has(support, "rescue") else 0.10), "rapunzel")
					actor.shield = minf(actor.max_hp, actor.shield + actor.max_hp * 0.08)
					break
				elif support.id == "ariel" and actor.hp / actor.max_hp < 0.50:
					support.pp -= 1
					tactics.notify(support.id, Content.KITS[support.id][2], "Socorreu " + str(TaleCatalog.HEROES[actor.id].name))
					hit["support_heal"] = heal(owner, actor, actor.max_hp * 0.08)
					tactics.slow_left = maxf(tactics.slow_left, 3.0)
					break
		if before_shield > 0 and actor.shield <= 0:
			for support in owner.actors:
				if support.id == "aladin" and support.hp > 0 and support.pp > 0:
					support.pp -= 1
					tactics.notify(support.id, Content.KITS[support.id][2], "+12 mana para a equipe")
					for ally in owner.actors:
						if ally.hp > 0: ally.energy = minf(100, ally.energy + 12)
					if has(support, "reserve"): shield_group(owner, 0.08)
					break
	actor.energy = minf(100, actor.energy + hit.damage / actor.max_hp * 80)
	deaths(tactics)
	tactics.sync_totals()
	return hit

static func deaths(tactics) -> void:
	var owner = tactics.run()
	# A bounded scan also catches deaths caused by fire, poison, counters and ULTs.
	for pass_index in tactics.enemies.size():
		for foe in tactics.enemies:
			if foe.hp > 0 or foe.get("death_processed", false): continue
			foe["death_processed"] = true
			for actor in owner.actors:
				if actor.hp <= 0: continue
				if actor.id == "matches" and (foe.burn_left > 0 or foe.get("died_burning", false)):
					if has(actor, "ash"): actor.energy = minf(100, actor.energy + 25)
					if actor.pp > 0 and tactics.enemies.any(func(unit): return unit.hp > 0):
						actor.pp -= 1
						tactics.notify(actor.id, Content.KITS[actor.id][2], "Espalhou fogo aos sobreviventes")
						for survivor in tactics.enemies:
							if survivor.hp > 0:
								ignite(survivor, maxf(foe.burn, actor.damage * 0.12), 5.0, "matches")
								if has(actor, "fuel"): tactics.deal(survivor, actor.damage * 0.6, true, true)
				elif actor.id == "snow_white" and (foe.poison_left > 0 or foe.get("died_poisoned", false)) and actor.pp > 0 and tactics.enemies.any(func(unit): return unit.hp > 0):
					actor.pp -= 1
					tactics.notify(actor.id, Content.KITS[actor.id][2], "Transferiu o veneno da vítima")
					for survivor in tactics.enemies:
						if survivor.hp > 0:
							poison(survivor, maxf(foe.poison, actor.damage * 0.10))
							if not has(actor, "seed"): break
				elif actor.id == "joao" and foe.get("marked", false) and has(actor, "relay"):
					for survivor in tactics.enemies:
						if survivor.hp > 0:
							survivor["marked"] = true
							break

static func basic(tactics, actor: Dictionary, target: int) -> Dictionary:
	var critical: bool = tactics.run().rng.randf() < actor.crit
	var hit: Dictionary = tactics.deal(tactics.enemies[target], actor.damage * (2.0 if critical else 1.0), actor["class"] in ["mage", "artificer"])
	actor.energy = minf(100, actor.energy + (8 if hit.evaded else 18 + actor.energy_bonus))
	if not hit.evaded:
		actor.hits += 1
		if TaleCatalog.NEW_HERO_IDS.has(actor.id):
			if not tactics.run().unlock_stats.has("new_hits"): tactics.run().unlock_stats["new_hits"] = {}
			tactics.run().unlock_stats.new_hits[actor.id] = int(tactics.run().unlock_stats.new_hits.get(actor.id, 0)) + 1
		actor.hp = minf(actor.max_hp, actor.hp + actor.leech)
	hit.merge({"target": target, "targets": [target], "target_damage": {target: hit.damage}, "critical": critical, "message": "Ataque básico · habilidade selada"})
	deaths(tactics)
	tactics.sync_totals()
	return hit
