class_name TaleCampaign
extends RefCounted
## Persistent progression. Combat checkpoints always begin at an encounter boundary.
const SAVE_PATH := "user://campaign_v1.json"
var gold := 80
var unlocked: Array[String] = ["scarlet"]
var party: Array[String] = ["scarlet"]
var cleared: Array[int] = []
var levels: Dictionary = {}
var choices: Dictionary = {}
var journal: Array = []
var checkpoint: Dictionary = {}
var pending_story := -1
var reduced_motion := false
var speed := 1.0
var save_error := ""


func _init() -> void:
	for id in TaleCatalog.HEROES:
		levels[id] = [0, 0, 0]


func can_play(index: int) -> bool:
	return index >= 0 and index < 8 and (index == 0 or cleared.has(index - 1))


func upgrade_cost(id: String, branch: int) -> int:
	return 35 + int(levels[id][branch]) * 30


func buy_upgrade(id: String, branch: int) -> bool:
	if not unlocked.has(id) or branch < 0 or branch > 2 or not checkpoint.is_empty():
		return false
	if int(levels[id][branch]) >= 5:
		return false
	var cost := upgrade_cost(id, branch)
	if gold < cost:
		return false
	gold -= cost
	levels[id][branch] += 1
	return true


func toggle_party(id: String) -> bool:
	if not unlocked.has(id) or not checkpoint.is_empty():
		return false
	if party.has(id):
		if party.size() == 1:
			return false
		party.erase(id)
	else:
		if party.size() >= 3:
			return false
		party.append(id)
	return true


func promote(id: String) -> bool:
	if not party.has(id) or not checkpoint.is_empty():
		return false
	party.erase(id)
	party.push_front(id)
	return true


func complete_stage(index: int) -> Dictionary:
	if not can_play(index):
		return {}
	var first := not cleared.has(index)
	var reward := 100 + index * 35 if first else 35 + index * 12
	gold += reward
	checkpoint.clear()
	var recruit: String = TaleCatalog.STAGES[index].recruit
	if first:
		cleared.append(index)
		cleared.sort()
		pending_story = index
		journal.append({"stage": index, "title": TaleCatalog.STAGES[index].name})
		if not recruit.is_empty() and not unlocked.has(recruit):
			unlocked.append(recruit)
			if party.size() < 3:
				party.append(recruit)
	return {"first": first, "reward": reward, "recruit": recruit if first else ""}


func choose_memory(index: int, choice: String) -> bool:
	if not cleared.has(index) or choices.has(str(index)) or choice not in ["hope", "power"]:
		return false
	choices[str(index)] = choice
	pending_story = -1
	return true


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"gold": gold,
		"unlocked": unlocked,
		"party": party,
		"cleared": cleared,
		"levels": levels,
		"choices": choices,
		"journal": journal,
		"checkpoint": checkpoint,
		"pending_story": pending_story,
		"reduced_motion": reduced_motion,
		"speed": speed
	}


func load_data(data: Dictionary) -> void:
	gold = clampi(int(data.get("gold", 80)), 0, 9999999)
	unlocked.assign(["scarlet"])
	if data.get("unlocked") is Array:
		for id in data.unlocked:
			if TaleCatalog.HEROES.has(id) and not unlocked.has(id):
				unlocked.append(id)
	party.clear()
	if data.get("party") is Array:
		for id in data.party:
			if unlocked.has(id) and not party.has(id) and party.size() < 3:
				party.append(id)
	if party.is_empty():
		party.append("scarlet")
	cleared.clear()
	if data.get("cleared") is Array:
		var completed: Array[int] = []
		for value in data.cleared:
			if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				completed.append(int(value))
		for index in 8:
			if completed.has(index) and (index == 0 or cleared.has(index - 1)):
				cleared.append(index)
	var saved_levels: Dictionary = (
		data.get("levels", {}) if data.get("levels", {}) is Dictionary else {}
	)
	for id in levels:
		var ranks: Variant = saved_levels.get(id, [0, 0, 0])
		if ranks is Array and ranks.size() == 3:
			for branch in 3:
				levels[id][branch] = clampi(int(ranks[branch]), 0, 5)
	choices.clear()
	var saved_choices: Variant = data.get("choices", {})
	if saved_choices is Dictionary:
		for key in saved_choices:
			if cleared.has(int(key)) and saved_choices[key] in ["hope", "power"]:
				choices[str(key)] = saved_choices[key]
	journal = []
	for index in cleared:
		journal.append({"stage": index, "title": TaleCatalog.STAGES[index].name})
	pending_story = int(data.get("pending_story", -1))
	if not cleared.has(pending_story) or choices.has(str(pending_story)):
		pending_story = -1
	reduced_motion = bool(data.get("reduced_motion", false))
	speed = 2.0 if float(data.get("speed", 1.0)) == 2.0 else 1.0
	checkpoint = {}
	var candidate: Variant = data.get("checkpoint", {})
	if candidate is Dictionary and candidate.has("stage") and can_play(int(candidate.stage)):
		if (
			int(candidate.get("wave", -1)) in [0, 1, 2]
			and candidate.get("health") is Array
			and candidate.health.size() == party.size()
		):
			checkpoint = candidate.duplicate(true)


func save_to(path: String = SAVE_PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		save_error = "Não foi possível gravar o progresso."
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak")
		)
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)
	)
	save_error = "" if error == OK else "Falha ao concluir o salvamento."
	return error == OK


func load_from(path: String = SAVE_PATH) -> bool:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parser := JSON.new()
		if (
			parser.parse(FileAccess.get_file_as_string(candidate)) == OK
			and parser.data is Dictionary
		):
			if int(parser.data.get("version", 0)) == 1:
				load_data(parser.data)
				return true
	return false
