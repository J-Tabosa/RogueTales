extends RefCounted
## Optional detours between fights. Choices spell out the cost before committing.
const Rules := preload("res://scripts/combat_rules.gd")
const EVENTS := {
	"road_spring": {"title":"Fonte entre as raízes", "icon":"heart", "body":"Água clara brota entre as raízes. O grupo pode parar para recuperar o fôlego.", "options":[
		{"id":"heal","title":"Beber da fonte","detail":"Recupere 25% dos PV máximos de cada aliado vivo.","heal":0.25}
	]},
	"road_thorns": {"title":"O preço dos espinhos", "icon":"sword", "body":"Uma bolsa de moedas ficou presa no meio de um espinheiro que atravessa a trilha.", "options":[
		{"id":"cross","title":"Buscar a bolsa","detail":"+45 ouro. Aliados vivos perdem 12% dos PV máximos, sem cair.","gold":45,"hurt":0.12}
	]},
	"road_boulder": {"title":"A pedra gigante", "icon":"sword", "body":"Uma rocha desabou sobre a passagem. Sob ela, dá para ver a ponta de um baú.", "options":[
		{"id":"break","title":"Quebrar a pedra","detail":"Abra o baú e ganhe 55 ouro.","gold":55,"stat":"damage","threshold":50.0},
		{"id":"push","title":"Empurrar em equipe","detail":"+25 ouro. Aliados vivos perdem 10% dos PV máximos, sem cair.","gold":25,"hurt":0.10}
	]},
	"road_bridge": {"title":"A ponte sem corrimão", "icon":"shield", "body":"Uma ponte cedeu. Alguém precisa sustentar a viga enquanto o grupo recolhe os suprimentos.", "options":[
		{"id":"hold","title":"Sustentar a viga","detail":"Os suprimentos curam 20% dos PV máximos dos aliados vivos.","heal":0.20,"stat":"defense","threshold":20.0}
	]},
	"road_current": {"title":"Corrida contra a corrente", "icon":"clock", "body":"Um caixote de moedas desce o rio. Alguém tem de alcançá-lo antes da queda-d’água.", "options":[
		{"id":"catch","title":"Alcançar o caixote","detail":"Recupere o caixote e ganhe 50 ouro.","gold":50,"stat":"initiative","threshold":75.0}
	]},
	"road_rumpel": {"title":"Banca de Rumpelstiltskin", "icon":"book", "body":"“Toda vantagem tem um preço.” O negociante abre dois contratos e espera pela sua escolha.", "options":[
		{"id":"power","title":"Contrato da força","detail":"+18% de dano e −10% de PV máximos para a equipe nesta run, incluindo futuros aliados.","curse":true},
		{"id":"gold","title":"Contrato do ouro","detail":"+80 ouro. Aliados vivos perdem 15% dos PV máximos, sem cair.","gold":80,"hurt":0.15}
	]}
}

static func can_offer(owner) -> bool:
	return owner.expedition and owner.phase in [1, 2, 3] and not owner.needs_map() and owner.active_secret.is_empty()

static func roll(owner) -> String:
	if not can_offer(owner): return ""
	var keys: Array = EVENTS.keys().filter(func(key): return not owner.seen_road_events.has(key))
	if keys.is_empty():
		# Start another cycle and avoid repeating the last event at the boundary.
		keys = EVENTS.keys()
		keys.erase(owner.seen_road_events.back())
		owner.seen_road_events.clear()
	return keys[owner.rng.randi_range(0, keys.size() - 1)]

static func can_occur(owner, id: String) -> bool:
	return EVENTS.has(id) and can_offer(owner) and not owner.seen_road_events.has(id)

static func stat_value(actor: Dictionary, stat: String) -> float:
	match stat:
		"defense": return Rules.defense(actor, false)
		"initiative": return Rules.effective_initiative(actor)
		"damage":
			if actor.id == "rapunzel": return 0.0
			var preview := actor.duplicate()
			var amount := 0.0
			var attacks := Rules.Bonuses.attacks(actor)
			if actor.id == "matches" and Rules.boon(actor, 0): attacks += 1
			if actor.id == "aladin" and Rules.boon(actor, 3) and Rules.wishes_left(actor) == 0: attacks += 2
			for index in attacks:
				var parts := Rules.basic_components(preview)
				amount += parts[0] + parts[1] + parts[2]
				preview.hits = int(preview.get("hits", 0)) + 1
				preview.suit = (int(preview.get("suit", 0)) + 1) % 4
			return amount
	return 0.0

static func requirement(owner, option: Dictionary) -> Dictionary:
	var stat := str(option.get("stat", ""))
	if stat.is_empty(): return {"allowed":true, "text":""}
	var best := -1.0
	var hero := ""
	for actor in owner.actors:
		if actor.hp <= 0: continue
		var value := stat_value(actor, stat)
		if value > best:
			best = value
			hero = str(TaleCatalog.HEROES[actor.id].name)
	var threshold := float(option.threshold)
	var allowed := not hero.is_empty() and (best > threshold if stat == "damage" else best >= threshold)
	var name := str({"damage":"Dano-base por turno","defense":"Defesa física","initiative":"Iniciativa"}[stat])
	var text := "%s %s %d" % [name, ">" if stat == "damage" else "≥", int(threshold)]
	if not hero.is_empty(): text += " · %s: %.2f" % [hero, best]
	return {"allowed":allowed,"text":text}

static func resolve(owner, choice: String) -> bool:
	var key: String = owner.pending_event
	if owner.interlude != "event" or not can_occur(owner, key): return false
	if choice != "leave":
		var selected: Dictionary = {}
		for option in EVENTS[key].options:
			if option.id == choice:
				selected = option
				break
		if selected.is_empty() or not requirement(owner, selected).allowed: return false
		if selected.has("gold"): owner.run_gold += int(selected.gold)
		if selected.has("heal"): owner.restore_party(float(selected.heal))
		if selected.has("hurt"):
			for actor in owner.actors:
				if actor.hp > 0:
					actor.hp = maxf(minf(actor.hp, 1.0), actor.hp - actor.max_hp * float(selected.hurt))
		if selected.get("curse", false):
			owner.curse_count += 1
			owner.build_event("curse")
	owner.seen_road_events.append(key)
	owner.pending_event = ""
	owner.interlude = ""
	owner.route_offers.clear()
	return true
