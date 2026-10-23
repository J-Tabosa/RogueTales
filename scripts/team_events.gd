extends RefCounted
## Team-aware encounters. Absent characters never speak or reveal locked names.
const EVENTS := {
	"gingerbread": {"title": "A casa ainda cheira a açúcar", "pair": ["joao", "maria"], "body": "Uma casa de doces reaparece entre árvores de papel. Há marcas de unhas na porta do forno.", "lines": ["Eu conheço esse cheiro. Vamos sair com tudo que ela roubou.", "Desta vez, quem escolhe a receita sou eu."], "choice": "Preparar a receita dos caçadores", "reward": "João recebe Presa exposta; Maria recebe Receita inesgotável.", "upgrades": ["skill:joao:hunt", "skill:maria:keep"]},
	"powder_shop": {"title": "Uma faísca entre amigas", "pair": ["scarlet", "matches"], "body": "O vendedor de pavios exige que ninguém acenda nada perto da bancada. A placa já está chamuscada.", "lines": ["Eu só queria um pavio mais comprido. Por segurança, claro.", "Comprido? Isso aqui precisa é de companhia!"], "choice": "Misturar as duas pólvoras", "reward": "Scarlet recebe Pavio compartilhado; Vendedora recebe Combustível proibido.", "upgrades": ["skill:scarlet:spread", "skill:matches:fuel"]},
	"bottled_tide": {"title": "O mar dentro da lâmpada", "pair": ["ariel", "aladin"], "body": "Uma garrafa canta na areia. Do lado de dentro, um pequeno mar tenta lembrar o próprio nome.", "lines": ["Tem uma voz presa aí. Eu não vou deixá-la sozinha.", "Eu conheço essa sensação. Vamos abrir espaço para ela."], "choice": "Unir a canção e o desejo", "reward": "Cure 30% dos PV do grupo e recupere 40 de energia de ULT.", "upgrades": []},
	"tower_rope": {"title": "Um salto até a janela", "pair": ["rapunzel", "puss"], "body": "Um baú repousa no alto de uma torre quebrada. A escada termina muito antes da janela.", "lines": ["Uma trança, um nó... só falta alguém que não tenha medo de altura.", "Medo? Eu só estava calculando o peso da espada."], "choice": "Subir com fios e botas", "reward": "Receba uma Capa do crepúsculo e cure 20% dos PV do grupo.", "upgrades": ["armor"]},
	"lost_patrol": {"title": "A patrulha que perdeu a sombra", "pair": ["mulan", "peter"], "body": "Soldados sem rosto repetem uma marcha. Suas sombras seguem na direção contrária.", "lines": ["Eles esqueceram por quem estão lutando. Dá para quebrar essa ordem.", "Eu cuido das sombras. Você conversa com o resto."], "choice": "Atacar por dois lados", "reward": "Mulan recebe Segundo movimento; Peter recebe Sombra gêmea.", "upgrades": ["skill:mulan:quick", "skill:peter:double"]},
	"apple_tea": {"title": "Chá para quem não dorme", "pair": ["alice", "snow_white"], "body": "Uma mesa posta flutua sobre um lago de tinta. No bule, um perfume de maçã disfarça algo amargo.", "lines": ["Se a xícara começar a falar, eu quero ouvir a versão dela.", "Pode ouvir. Mas deixa que eu provo a primeira gota."], "choice": "Servir a mistura impossível", "reward": "Alice recebe Rainha de copas; Branca recebe Receita concentrada.", "upgrades": ["skill:alice:heart", "skill:snow_white:stack"]}
}

static func alive_ids(owner) -> Array[String]:
	var ids: Array[String] = []
	for actor in owner.actors:
		if actor.hp > 0: ids.append(actor.id)
	return ids

static func available(owner) -> Array[String]:
	var result: Array[String] = []
	var ids := alive_ids(owner)
	for key in EVENTS:
		var pair: Array = EVENTS[key].pair
		if not owner.seen_events.has(key) and (ids.has(pair[0]) or ids.has(pair[1])): result.append(key)
	result.append_array(preload("res://scripts/secret_encounters.gd").available(owner))
	return result

static func can_pair(owner, key: String) -> bool:
	if not EVENTS.has(key): return false
	var ids := alive_ids(owner)
	return ids.has(EVENTS[key].pair[0]) and ids.has(EVENTS[key].pair[1])

static func dialogue(owner, key: String) -> Array[Dictionary]:
	if not has_event(key): return []
	var data: Dictionary = event(key)
	if key.begins_with("secret_"): return [{"speaker":"narrator","text":data.body},{"speaker":key.trim_prefix("secret_"),"text":data.lines[0]}]
	var lines: Array[Dictionary] = [{"speaker": "narrator", "text": data.body}]
	var ids := alive_ids(owner)
	for index in 2:
		if ids.has(data.pair[index]): lines.append({"speaker": data.pair[index], "text": data.lines[index]})
	return lines

static func resolve(owner, choice: String) -> bool:
	var key: String = owner.pending_event
	if key.begins_with("secret_"):
		var id:=key.trim_prefix("secret_")
		if owner.interlude!="event" or not preload("res://scripts/secret_encounters.gd").eligible(owner,id) or choice not in ["challenge","leave"]: return false
		owner.seen_events.append(key)
		if not owner.events_discovered.has(key): owner.events_discovered.append(key)
		owner.active_secret=id if choice=="challenge" else ""
		owner.pending_event=""
		owner.interlude=""
		owner.route_offers.clear()
		return true
	if owner.interlude != "event" or not EVENTS.has(key) or choice not in ["supplies", "rest", "pair"]: return false
	if choice == "pair" and not can_pair(owner, key): return false
	if choice == "supplies": owner.run_gold += 30
	elif choice == "rest": owner.restore_party(0.25, true)
	else:
		for id in EVENTS[key].upgrades:
			if not owner.apply_relic(str(id)): owner.run_gold += 15
		if key == "bottled_tide":
			owner.restore_party(0.30)
			for actor in owner.actors:
				if actor.hp > 0: actor.energy = minf(100, actor.energy + 40)
		elif key == "tower_rope": owner.restore_party(0.20)
	owner.seen_events.append(key)
	if not owner.events_discovered.has(key): owner.events_discovered.append(key)
	owner.pending_event = ""
	owner.interlude = ""
	owner.route_offers.clear()
	return true

static func has_event(key: String) -> bool:
	return EVENTS.has(key) or (key.begins_with("secret_") and preload("res://scripts/secret_encounters.gd").DATA.has(key.trim_prefix("secret_")))
static func event(key: String) -> Dictionary:
	return EVENTS.get(key,preload("res://scripts/secret_encounters.gd").event(key))
