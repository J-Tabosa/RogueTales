extends RefCounted
## The saved Excel workbook is the balance source; reload only between encounters.
const Table = preload("res://scripts/xlsx_table.gd")
const Biomes = preload("res://scripts/biomes.gd")
const Secrets = preload("res://scripts/secret_encounters.gd")
const PATH := "res://data/inimigos.xlsx"
const NUMBERS := ["vida_base", "ataque_base", "def_fisica_base", "def_magica_base", "iniciativa", "qtd_ataques", "esquiva", "intervalo_visual"]
static var profiles: Dictionary = {}
static var fingerprint := ""
static var last_error := ""
static var original_profiles: Dictionary = {}

static func profile(id: String, kind: String, biome: String, name: String, job: String, health: float, attack: float, armor: float, interval: float) -> Dictionary:
	return {"id": id, "tipo": kind, "bioma": biome, "nome": name, "classe": job, "vida_base": health, "ataque_base": attack, "def_fisica_base": armor, "def_magica_base": armor if job == "vanguard" else 0.0, "iniciativa": 50.0, "qtd_ataques": 1, "esquiva": 0.0, "intervalo_visual": interval}

static func defaults() -> Dictionary:
	if not original_profiles.is_empty(): return original_profiles
	var result := {}
	for biome in Biomes.KEYS.size():
		for variant in 6:
			var id := "biome_%s_%d" % [Biomes.KEYS[biome], variant]
			var job: String = Biomes.CLASSES[variant]
			result[id] = profile(id, "Comum", Biomes.NAMES[biome], Biomes.ENEMIES[biome][variant], job, 86.0 * 0.72 * float(Biomes.HP[variant]), 13.0 * float(Biomes.POWER[variant]), 1.0 if job == "vanguard" else 0.0, Biomes.INTERVALS[variant])
	for rule in [3, 7, 11]:
		var id := "boss_%d" % rule
		var variant := 0 if rule == 3 else (3 if rule == 7 else 5)
		result[id] = profile(id, "Chefe", "Conforme o mapa", TaleCatalog.STAGES[rule].boss, "vanguard" if rule == 3 else "mage", 86.0 * 1.5 * 0.70, 13.0 * 1.2, 1.0 if rule == 3 else 0.0, Biomes.INTERVALS[variant])
	for hero in Secrets.DATA:
		var id := "secret_" + str(hero)
		result[id] = profile(id, "Secreto", ", ".join(Secrets.DATA[hero].biomes.map(func(b): return Biomes.NAMES[b])), Secrets.DATA[hero].name, Secrets.DATA[hero]["class"], 86.0 * 1.5, 13.0 * 1.32, 2.0, 2.9)
	original_profiles = result
	return original_profiles

static func source_path() -> String:
	if not OS.has_feature("editor") and OS.has_feature("pc"):
		var external := OS.get_executable_path().get_base_dir().path_join("inimigos.xlsx")
		if FileAccess.file_exists(external): return external
	return PATH

static func validate(table: Dictionary) -> Dictionary:
	if table.has("error"): return table
	for key in ["id", "nome", "classe"] + NUMBERS:
		if not table.headers.has(key): return {"error": "Coluna obrigatória ausente: " + key}
	var original := defaults()
	var result := {}
	for row in table.records:
		var id := str(row.id.value).strip_edges()
		if id.is_empty():
			if row.values().any(func(cell): return not str(cell.value).is_empty()): return {"error": "Linha preenchida sem id."}
			continue
		if not original.has(id): return {"error": "ID não cadastrado no jogo: " + id}
		if result.has(id): return {"error": "ID duplicado: " + id}
		var data: Dictionary = original[id].duplicate()
		if str(row.classe.value) != str(data.classe): return {"error": "A classe é uma referência fixa: " + id}
		data.nome = str(row.nome.value).strip_edges()
		if data.nome.is_empty(): return {"error": "Nome vazio: " + id}
		for key in ["id", "nome", "classe"] + NUMBERS:
			if row[key].formula or row[key].error: return {"error": "Use valores sem fórmulas na aba Inimigos: %s / %s" % [id, key]}
		for key in NUMBERS:
			var raw := str(row[key].value).strip_edges()
			if raw.is_empty() or not raw.is_valid_float(): return {"error": "Número inválido: %s / %s" % [id, key]}
			var number := float(raw)
			if not is_finite(number) or absf(number) > 1000000000.0: return {"error": "Número fora do limite: %s / %s" % [id, key]}
			if key != "iniciativa" and number < 0: return {"error": "Valor negativo: %s / %s" % [id, key]}
			if key in ["vida_base", "intervalo_visual"] and number <= 0: return {"error": "Valor deve ser positivo: %s / %s" % [id, key]}
			if key == "iniciativa" and number > 100: return {"error": "Iniciativa acima de 100: " + id}
			if key == "esquiva" and number > 0.8: return {"error": "Esquiva acima de 80%: " + id}
			if key == "qtd_ataques" and (number != floorf(number) or number < 1 or number > 20): return {"error": "Quantidade de ataques deve ser inteira de 1 a 20: " + id}
			data[key] = int(number) if key == "qtd_ataques" else number
		result[id] = data
	if result.size() != original.size(): return {"error": "Mantenha todas as %d linhas cadastradas." % original.size()}
	return {"profiles": result}

static func reload_if_changed(path_override := "") -> void:
	var path := source_path() if path_override.is_empty() else path_override
	var bytes := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	var signature := path + ":" + str(hash(bytes))
	if signature == fingerprint: return
	fingerprint = signature
	var parsed := {"error": "Planilha ausente ou maior que 2 MB."} if bytes.is_empty() or bytes.size() > 2 * 1024 * 1024 else validate(Table.read_table(path))
	if parsed.has("error"):
		last_error = str(parsed.error)
		push_warning("Balanceamento: %s Mantidos os últimos valores válidos (ou os originais)." % last_error)
		return
	profiles = parsed.profiles
	last_error = ""

static func apply(foe: Dictionary, owner) -> void:
	if not owner.expedition: return # Old campaign saves retain their original balance.
	var id := ""
	if foe.has("secret_id"): id = "secret_" + str(foe.secret_id)
	elif foe.get("boss", false): id = "boss_%d" % owner.current_boss_rule()
	else: id = "biome_%s_%d" % [Biomes.KEYS[int(foe.biome)], int(foe.variant)]
	foe["balance_id"] = id
	if not profiles.has(id): return
	var original: Dictionary = defaults()[id]
	var data: Dictionary = profiles[id]
	foe.name = data.nome
	foe.hp *= float(data.vida_base) / float(original.vida_base)
	foe.max_hp = foe.hp
	foe.damage *= float(data.ataque_base) / float(original.ataque_base)
	var magic_defense := float(foe.armor) if foe.get("class", "") == "vanguard" else 0.0
	foe.magic_defense = magic_defense + float(data.def_magica_base) - float(original.def_magica_base)
	foe.armor += float(data.def_fisica_base) - float(original.def_fisica_base)
	foe.initiative = data.iniciativa
	foe.attacks = int(data.qtd_ataques)
	foe.evasion = data.esquiva
	foe.interval = data.intervalo_visual
