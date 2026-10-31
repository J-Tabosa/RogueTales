extends SceneTree
const Balance = preload("res://scripts/enemy_balance.gd")
const Table = preload("res://scripts/xlsx_table.gd")
const Flow = preload("res://scripts/battle_flow.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("test")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func fixture(path: String, replacements: Dictionary, file_replacements: Dictionary = {}) -> void:
	var source := ZIPReader.new()
	assert(source.open(Balance.PATH) == OK)
	var output := ZIPPacker.new()
	assert(output.open(path) == OK)
	var target := Table.worksheet(source, "Inimigos")
	for file in source.get_files():
		var bytes := source.read_file(file)
		if file_replacements.has(file): bytes = str(file_replacements[file]).to_utf8_buffer()
		if file == target:
			var text := bytes.get_string_from_utf8()
			for reference in replacements:
				var expression := RegEx.new()
				expression.compile('<(?:[A-Za-z0-9_]+:)?c\\b[^>]*\\br="%s"[^>]*>[\\s\\S]*?</(?:[A-Za-z0-9_]+:)?c>' % reference)
				assert(expression.search(text) != null)
				var cell: Variant = replacements[reference]
				var content: String = str(cell.xml) if cell is Dictionary else str(cell)
				var cell_type: String = str(cell.type) if cell is Dictionary else ("inlineStr" if content.begins_with("<is>") else "n")
				text = expression.sub(text, '<c r="%s" t="%s">%s</c>' % [reference, cell_type, content])
			bytes = text.to_utf8_buffer()
		output.start_file(file)
		output.write_file(bytes)
		output.close_file()
	output.close()
	source.close()

func new_run() -> IdleRun:
	var account := preload("res://tests/test_accounts.gd").legacy()
	var run := IdleRun.new()
	assert(run.start_expedition(account, "scarlet", "blessing:scarlet:0"))
	run.journey.clear()
	return run

func matches_defaults() -> bool:
	if Balance.profiles.size() != Balance.defaults().size(): return false
	for id in Balance.defaults():
		for key in Balance.defaults()[id]:
			if key in Balance.NUMBERS:
				if not is_equal_approx(float(Balance.profiles[id][key]), float(Balance.defaults()[id][key])): return false
			elif Balance.profiles[id][key] != Balance.defaults()[id][key]: return false
	return true

func test() -> void:
	Balance.reload_if_changed()
	check(Balance.last_error.is_empty(), "Real delivered workbook must parse")
	check(Balance.profiles.size() == 79, "Original 63 profiles plus 16 starting-forest profiles load")
	check(matches_defaults(), "Workbook preserves every original base value")
	var pack_path := "user://enemy_balance.pck"
	var pack := PCKPacker.new()
	check(pack.pck_start(pack_path) == OK and pack.add_file("res://balance_pack/inimigos.xlsx", Balance.PATH) == OK and pack.flush() == OK, "Workbook must pack successfully")
	check(ProjectSettings.load_resource_pack(pack_path), "Workbook test pack must mount")
	check(not Balance.validate(Table.read_table("res://balance_pack/inimigos.xlsx")).has("error"), "XLSX must also load from an exported resource pack")
	var owner := new_run()
	# Compare actual generated encounters with the exact original formulas.
	for stage in 12:
		owner.stage = stage
		for phase in [0, 2, 5]:
			owner.phase = phase
			for kind in ["battle", "elite"]:
				owner.room_kind = kind
				owner.spawn_enemy()
				for foe in owner.tactics.enemies:
					var depth: int = stage * 6 + phase
					var growth := (1.0 + depth * .05) * pow(1.045, mini(depth, 120)) * (1.0 + maxi(0, depth - 120) * .08)
					var weight: float = (.7 if foe.boss else .15) if phase == 5 else .72
					var health: float = 86 * growth * (1.5 if phase == 5 else 1.0) * (1.35 if kind == "elite" else 1.0) * weight * (1.0 if foe.boss else Balance.Biomes.HP[foe.variant])
					check(is_equal_approx(foe.max_hp, health), "Default health progression changed")
					var damage: float = (13 + depth * .85) * (1.2 if foe.boss else 1.0) * (1.15 if kind == "elite" else 1.0) * (1.0 if foe.boss else Balance.Biomes.POWER[foe.variant])
					if foe.get("banner", false): damage = 0
					if foe.has("binds"): damage *= .6
					check(is_equal_approx(foe.damage, damage), "Default attack progression changed")
					check(foe.attacks == 1 and foe.initiative == 50 and foe.evasion == 0, "Original initiative/attacks/evasion changed")
	for hero in Balance.Secrets.DATA:
		owner.active_secret = hero
		owner.spawn_enemy()
		check(owner.tactics.enemies[0].balance_id == "secret_" + hero, "Secret mapping failed")
	owner.active_secret = ""
	owner.stage = 0
	owner.phase = 0
	owner.room_kind = "battle"
	for seed_value in 100:
		owner.rng.seed = seed_value
		owner.spawn_enemy()
		if owner.tactics.enemies[0].balance_id == "biome_forest_0": break
	check(owner.tactics.enemies[0].balance_id == "biome_forest_0", "Fixture enemy must match edited workbook row")
	var before: Dictionary = owner.tactics.enemies[0].duplicate(true)
	# Use a real altered XLSX, then exercise the production load path and battle flow.
	var changed := "user://enemy_balance_changed.xlsx"
	fixture(changed, {"F2":"<v>146.1312</v>", "G2":"<v>26</v>", "H2":"<v>21</v>", "I2":"<v>31</v>", "J2":"<v>99</v>", "K2":"<v>3</v>", "L2":"<v>0.1</v>", "D2":"<is><t>Gosma de teste &amp; tinta</t></is>"})
	# D2 is an inline string, as emitted by some spreadsheet editors.
	var reader := ZIPReader.new()
	reader.open(changed)
	var sheet_path := Table.worksheet(reader, "Inimigos")
	var altered := reader.read_file(sheet_path).get_string_from_utf8()
	reader.close()
	check(altered.contains("Gosma de teste"), "Altered XLSX fixture must contain edited cells")
	Balance.reload_if_changed(changed)
	check(Balance.last_error.is_empty(), "Changed workbook rejected: " + Balance.last_error)
	var foe := before.duplicate(true)
	# apply() runs before combat initialization, so reset the generated baseline.
	foe.erase("magic_defense")
	Balance.apply(foe, owner)
	check(is_equal_approx(foe.max_hp, before.max_hp * 2) and is_equal_approx(foe.damage, before.damage * 2), "Saved health and attack must double")
	check(foe.armor == before.armor + 20 and foe.magic_defense == before.magic_defense + 30, "Independent defenses must update")
	check(foe.attacks == 3 and foe.initiative == 99 and is_equal_approx(foe.evasion, .1), "Attacks, initiative and evasion must update")
	check(foe.name == "Gosma de teste & tinta", "Inline strings and XML entities must load")
	owner.tactics.enemies.assign([foe])
	owner.tactics.Rules.start_combat(owner.tactics)
	var flow := Flow.new()
	flow.bind(owner)
	var action := flow.next_action()
	check(action.get("side") == "enemy" and flow.remaining == 3, "Battle flow must use edited initiative and attack count")
	var before_hit: float = owner.actors[0].hp
	for strike in 3:
		action = flow.next_action()
		check(action.get("side") == "enemy", "Every edited attack must execute on the enemy's turn")
		flow.begin(action)
		owner.hit_party(0)
		flow.complete()
	check(flow.next_action().get("side") == "ally", "Enemy turn must finish after three attacks")
	check(owner.actors[0].hp < before_hit, "Edited enemy must execute real damaging attacks")
	var stable := Balance.profiles.duplicate(true)
	var invalid := "user://enemy_balance_invalid.xlsx"
	fixture(invalid, {"D2":{"type":"s", "xml":"<v>0</v>"}}, {"xl/sharedStrings.xml":'<sst><si><r><t>Gosma </t></r><r><t>compartilhada</t></r></si></sst>'})
	var shared := Balance.validate(Table.read_table(invalid))
	check(not shared.has("error") and shared.profiles.biome_forest_0.nome == "Gosma compartilhada", "Excel shared and rich strings must load")
	fixture(invalid, {"K2":"<v>1.5</v>"})
	Balance.reload_if_changed(invalid)
	check(not Balance.last_error.is_empty() and Balance.profiles == stable, "Fractional attacks must preserve last valid balance")
	fixture(invalid, {"G2":"<v>-1</v>"})
	Balance.reload_if_changed(invalid)
	check(not Balance.last_error.is_empty() and Balance.profiles == stable, "Negative attack must be rejected")
	fixture(invalid, {"G2":"<f>1+1</f><v>2</v>"})
	Balance.reload_if_changed(invalid)
	check(not Balance.last_error.is_empty(), "Formula cached values must not silently drive balance")
	fixture(invalid, {"A3":"<is><t>biome_forest_0</t></is>"})
	Balance.reload_if_changed(invalid)
	check(not Balance.last_error.is_empty(), "Duplicate IDs must be rejected")
	var file := FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string("not an xlsx")
	file.close()
	Balance.reload_if_changed(invalid)
	check(not Balance.last_error.is_empty() and Balance.profiles == stable, "Corruption must preserve valid balance")
	Balance.reload_if_changed()
	check(Balance.last_error.is_empty() and matches_defaults(), "Corrected workbook restores defaults")
	DirAccess.remove_absolute(changed)
	DirAccess.remove_absolute(invalid)
	DirAccess.remove_absolute(pack_path)
	print("ENEMY BALANCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
