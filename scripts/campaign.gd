class_name TaleCampaign
extends RefCounted
## Persistent progression. Combat checkpoints always begin at an encounter boundary.
const SAVE_PATH := "user://campaign_v1.json"
const HERO_PRICE := 5000
const MEMORIES_PER_COMBAT := 25
const MEMORIES_PER_BOSS := 50
const MEMORIES_COMPLETION := 300
const MEMORIES_ENDLESS_MILESTONE := 100
var gold := HERO_PRICE
var unlocked: Array[String] = []
var party: Array[String] = []
var cleared: Array[int] = []
var levels: Dictionary = {}
var choices: Dictionary = {}
var journal: Array = []
var checkpoint: Dictionary = {}
var pending_story := -1
var reduced_motion := false
var speed := 2.0
var goals:Dictionary={}
var daily:Dictionary={}
var goals_run:=0
var goals_receipts:Array[String]=[]
var save_error := ""
var hero_levels: Dictionary = {}
var hero_xp: Dictionary = {}
var player_name := "Viajante"
var avatar := "scarlet"
var player_level := 1
var player_xp := 0
var total_kills := 0
var total_wins := 0
var total_defeats := 0
var total_gold := HERO_PRICE
var total_spent := 0
var play_seconds := 0.0
var idle_anchor := 0
var idle_seconds := 0
var claimed: Array[String] = []
var music_volume := 0.45
var effects_volume := 0.65
var voice_volume := 0.5
var high_quality := true
var fps_limit := 60
var text_speed := 36
var auto_repeat := false
var unlock_progress: Dictionary = initial_unlock_progress()
var formation_rows: Dictionary = {}
var auto_ult := true
var window_mode := "fullscreen"
var window_mode_selected := false
var run_counter := 0
var last_resolved_run := 0
var best_depth := 0
var best_score := 0
var expedition_wins := 0
var hero_milestones: Dictionary = {}
var blessing_credit: Dictionary = {}
var blessings_unlocked: Array[String] = ["vigor", "fury", "echo"]
var best_endless := 0
var endless_runs := 0
var discovered_synergies: Array[String] = []
var discovered_events: Array[String] = []
const IDLE_CAP := 8 * 3600
const ACHIEVEMENTS = preload("res://scripts/achievement_catalog.gd").DATA
const DAILIES := [
	{"id":"battles","title":"Mais cinco páginas","detail":"Vença 5 combates hoje.","goal":5,"reward":50,"icon":"sword"},
	{"id":"enemies","title":"Limpando a trilha","detail":"Derrote 15 inimigos hoje.","goal":15,"reward":50,"icon":"target"},
	{"id":"bosses","title":"Desafio do dia","detail":"Vença 1 chefe de mapa hoje.","goal":1,"reward":75,"icon":"crown"}
]
static func speed_label(value:float) -> int:return clampi(int(value)-1,1,3)
static func next_speed(value:float) -> float:return float(2+(clampi(int(value),2,4)-1)%3)
func refresh_daily(today:=Time.get_date_string_from_system()) -> void:
	# A backward clock change cannot reopen a previously claimed day.
	if today>str(daily.get("day","")):
		daily={"day":today,"battles":0,"enemies":0,"bosses":0,"claimed":[]}
func record_goal_combat(number:int,receipt:String,enemies:int,boss:bool,team_size:int,today:=Time.get_date_string_from_system()) -> void:
	if number<goals_run:return
	if number>goals_run:
		goals_run=number
		goals_receipts.clear()
	if goals_receipts.has(receipt):return
	goals_receipts.append(receipt)
	refresh_daily(today)
	for metric in ["battles","enemies","bosses"]:
		var amount:=1 if metric=="battles" else maxi(0,enemies) if metric=="enemies" else int(boss)
		goals[metric]=int(goals.get(metric,0))+amount
		if daily.get("day")==today:daily[metric]=int(daily.get(metric,0))+amount
	goals.team=maxi(int(goals.get("team",0)),team_size)
func claim_daily(id:String,today:=Time.get_date_string_from_system()) -> bool:
	refresh_daily(today)
	if daily.get("day")!=today or daily.claimed.has(id):return false
	for task in DAILIES:
		if task.id==id and int(daily.get(id,0))>=task.goal:
			daily.claimed.append(id)
			earn_gold(task.reward)
			return true
	return false
func record_achievement_state(data:Dictionary,won:=false) -> void:
	var g:=goals
	var maps:Dictionary=g.get("maps",{})
	var journey:Dictionary=data.get("journey",{})
	var path:Array=journey.get("path",[])
	for index in mini(path.size(),int(data.get("stage",0))+1):maps[str(path[index])]=true
	g.maps=maps
	var secrets:Dictionary=g.get("secrets",{})
	for id in data.get("secret_defeated",[]):secrets[str(id)]=true
	g.secrets=secrets
	g.capacity=maxi(int(g.get("capacity",0)),int(data.get("party_capacity",0)))
	if bool(data.get("endless",false)):
		var depth:=maxi(0,int(data.get("rooms_cleared",0))-int(data.get("continuation_from",0)))
		g.infinite_combat=maxi(int(g.get("infinite_combat",0)),memory_combats(depth))
	var ids:Array=data.get("hero_ids",[])
	var royal:=ids.size()==ExpeditionContent.MAX_PARTY
	var equipment:Dictionary=data.get("equipment_state",{})
	for id in ids:
		var items:Array=equipment.get(id,{}).get("items",[])
		if items.size()!=2:royal=false
		for item in items:
			if int(preload("res://scripts/equipment.gd").data(item).get("rarity",-1)) not in [4,5]:royal=false
	if royal:g.royal_gear=1
	if won and not data.get("endless",false):
		g["hero_win_"+str(data.get("leader",""))]=1
		g.stages8=8
		if ids.size()==1 and data.get("drafted",[]).is_empty() and data.get("inactive_companions",[]).is_empty():g.solo=1
func achievement_progress(id:String) -> Vector2i:
	if id.begins_with("hero_win_"):
		var hero:=id.trim_prefix("hero_win_")
		return Vector2i(maxi(int(goals.get(id,0)),int(hero_milestones.get(hero,{}).get("win",false))),1)
	match id:
		"blessings4":
			var best:=0
			for hero in TaleCatalog.HEROES:
				var count:=0
				for i in 4:
					if preload("res://scripts/hero_blessings.gd").unlocked(self,preload("res://scripts/hero_blessings.gd").id_for(hero,i)):count+=1
				best=maxi(best,count)
			return Vector2i(best,4)
		"stages8":return Vector2i(maxi(int(goals.get("stages8",0)),8 if expedition_wins>0 else mini(best_depth,8)),8)
		"maps_all":return Vector2i(goals.get("maps",{}).size(),preload("res://scripts/world_routes.gd").NODES.size())
		"secrets_all":return Vector2i(goals.get("secrets",{}).size(),preload("res://scripts/secret_encounters.gd").DATA.size())
		"runs100":return Vector2i(run_counter,100)
		"infinite25":return Vector2i(int(goals.get("infinite_combat",0)),25)
		"infinite50":return Vector2i(int(goals.get("infinite_combat",0)),50)
		"infinite100":return Vector2i(int(goals.get("infinite_combat",0)),100)
		"tales_all":return Vector2i(unlocked.size(),TaleCatalog.HEROES.size())
		"capacity":return Vector2i(int(goals.get("capacity",0)),ExpeditionContent.MAX_PARTY)
		"memories100k":return Vector2i(maxi(gold,int(goals.get("memory_peak",0))),100000)
		"solo","royal_gear":return Vector2i(int(goals.get(id,0)),1)
	return Vector2i(0,1)


func _init() -> void:
	for id in TaleCatalog.HEROES:
		levels[id] = [0, 0, 0]
		hero_levels[id] = 1
		hero_xp[id] = 0
		formation_rows[id] = TaleCatalog.HERO_TACTICS[id].row
	ensure_front()


func can_play(index: int) -> bool:
	return index >= 0 and index < TaleCatalog.CHAPTER_COUNT and (index == 0 or cleared.has(index - 1))


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
	total_spent += cost
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
		if party.size() >= ExpeditionContent.MAX_PARTY:
			return false
		party.append(id)
	ensure_front()
	return true


func promote(id: String) -> bool:
	if not party.has(id) or not checkpoint.is_empty():
		return false
	party.erase(id)
	party.push_front(id)
	return true


func complete_stage(index: int, recipients: Array = []) -> Dictionary:
	if not can_play(index):
		return {}
	var first := not cleared.has(index)
	var reward := 100 + index * 35 if first else 35 + index * 12
	earn_gold(reward)
	total_wins += 1
	grant_xp(30 + index * 10, recipients)
	checkpoint.clear()
	if first:
		cleared.append(index)
		cleared.sort()
		pending_story = index
		journal.append({"stage": index, "title": TaleCatalog.STAGES[index].name})
	return {"first": first, "reward": reward}


func choose_memory(index: int, choice: String) -> bool:
	if not cleared.has(index) or choices.has(str(index)) or choice not in ["hope", "power"]:
		return false
	choices[str(index)] = choice
	pending_story = -1
	return true


## Local collection code. It grants heroes only, never currencies or blessings.
func redeem_code(value:String) -> Dictionary:
	if value.strip_edges()!="500.001":return {"ok":false,"added":0,"message":"Código inválido. Confira e tente novamente."}
	var added:=0
	for id in TaleCatalog.HEROES:
		if not unlocked.has(id):
			unlocked.append(id)
			added+=1
	if party.is_empty() and not unlocked.is_empty():party.append(unlocked[0])
	return {"ok":true,"added":added,"message":"Todos os personagens já estão desbloqueados." if added==0 else "Código resgatado! Todos os personagens foram desbloqueados."}


func to_dict() -> Dictionary:
	return {
		"version": 12,"speed_base":2,
		"goals":goals.duplicate(true),"daily":daily.duplicate(true),"goals_run":goals_run,"goals_receipts":goals_receipts.duplicate(),
		"hero_milestones":hero_milestones.duplicate(true),"blessing_credit":blessing_credit.duplicate(),
		"best_endless": best_endless, "endless_runs": endless_runs,
		"discovered_synergies": discovered_synergies.duplicate(), "discovered_events": discovered_events.duplicate(),
		"best_score": best_score, "best_depth": best_depth, "expedition_wins": expedition_wins,
		"blessings_unlocked": blessings_unlocked.duplicate(),
		"formation_rows": formation_rows,
		"auto_ult": auto_ult,
		"window_mode": window_mode,
		"window_mode_selected":window_mode_selected,
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
		"speed": speed,
		"hero_levels": hero_levels,
		"hero_xp": hero_xp,
		"player_name": player_name,
		"avatar": avatar,
		"player_level": player_level,
		"player_xp": player_xp,
		"total_kills": total_kills,
		"total_wins": total_wins,
		"total_defeats": total_defeats,
		"total_gold": total_gold,
		"total_spent": total_spent,
		"play_seconds": play_seconds,
		"idle_anchor": idle_anchor,
		"idle_seconds": idle_seconds,
		"claimed": claimed,
		"music_volume": music_volume,
		"effects_volume": effects_volume,
		"voice_volume": voice_volume,
		"high_quality": high_quality,
		"fps_limit": fps_limit,
		"text_speed": text_speed,
		"auto_repeat": auto_repeat,
		"unlock_progress": unlock_progress,
		"run_counter": run_counter,
		"last_resolved_run": last_resolved_run
	}


func load_data(data: Dictionary) -> void:
	hero_milestones={}
	blessing_credit=data.get("blessing_credit",{}).duplicate() if data.get("blessing_credit",{}) is Dictionary else {}
	var milestones:Dictionary=data.get("hero_milestones",{}) if data.get("hero_milestones",{}) is Dictionary else {}
	for hero in TaleCatalog.HEROES:
		var p:Dictionary=milestones.get(hero,{}) if milestones.get(hero,{}) is Dictionary else {}
		hero_milestones[hero]={"rooms":clampi(int(p.get("rooms",0)),0,12),"secret":bool(p.get("secret",false)),"win":bool(p.get("win",false)),"feat":bool(p.get("feat",false))}
	best_endless = clampi(int(data.get("best_endless", 0)), 0, 2147483647)
	endless_runs = maxi(0, int(data.get("endless_runs", 0)))
	discovered_synergies.clear()
	discovered_events.clear()
	for key in data.get("discovered_synergies", []):
		if preload("res://scripts/team_synergies.gd").PAIRS.has(key) and not discovered_synergies.has(key): discovered_synergies.append(key)
	for key in data.get("discovered_events", []):
		if preload("res://scripts/team_events.gd").has_event(key) and not discovered_events.has(key): discovered_events.append(key)
	best_score = maxi(0, int(data.get("best_score", 0)))
	best_depth = clampi(int(data.get("best_depth", 0)), 0, 12)
	if int(data.get("version", 1)) < 8: best_depth = floori(best_depth / 6.0)
	expedition_wins = maxi(0, int(data.get("expedition_wins", 0)))
	blessings_unlocked.assign(["vigor", "fury", "echo"])
	for key in data.get("blessings_unlocked", []):
		if ExpeditionContent.BLESSINGS.has(key) and not blessings_unlocked.has(key): blessings_unlocked.append(key)
	gold = clampi(int(data.get("gold", HERO_PRICE)), 0, 9999999)
	# Version 1 contained a removed heroine. Refund her purchased skill ranks exactly once.
	if int(data.get("version", 1)) == 1:
		var old_levels: Variant = data.get("levels", {})
		if old_levels is Dictionary and old_levels.get("cinderella") is Array:
			for rank in old_levels.cinderella:
				var count := clampi(int(rank), 0, 5)
				gold += count * 35 + 15 * count * (count - 1)
	unlocked.clear()
	if int(data.get("version",1))<10:unlocked.append("scarlet")
	if data.get("unlocked") is Array:
		for id in data.unlocked:
			if TaleCatalog.HEROES.has(id) and not unlocked.has(id):
				unlocked.append(id)
	party.clear()
	if data.get("party") is Array:
		for id in data.party:
			if unlocked.has(id) and not party.has(id) and party.size() < ExpeditionContent.MAX_PARTY:
				party.append(id)
	if party.is_empty() and not unlocked.is_empty():
		party.append(unlocked[0])
	cleared.clear()
	if data.get("cleared") is Array:
		var completed: Array[int] = []
		for value in data.cleared:
			if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
				completed.append(int(value))
		for index in TaleCatalog.CHAPTER_COUNT:
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
	speed = float(clampi(int(data.get("speed",2)) if int(data.get("speed_base",0))==2 else int(data.get("speed",1))+1,2,4))
	goals=data.get("goals",{}).duplicate(true) if data.get("goals",{}) is Dictionary else {}
	daily=data.get("daily",{}).duplicate(true) if data.get("daily",{}) is Dictionary else {}
	if not daily.get("claimed",[]) is Array:daily["claimed"]=[]
	if not daily.has("claimed"):daily["claimed"]=[]
	goals_run=maxi(0,int(data.get("goals_run",0)))
	goals_receipts.clear()
	if data.get("goals_receipts",[]) is Array:
		for receipt in data.get("goals_receipts",[]):goals_receipts.append(str(receipt))
	refresh_daily()
	goals.memory_peak=maxi(gold,int(goals.get("memory_peak",0)))
	checkpoint = {}
	var candidate: Variant = data.get("checkpoint", {})
	if candidate is Dictionary and candidate.has("stage") and (int(candidate.stage) in range(12) if candidate.get("expedition", false) else can_play(int(candidate.stage))):
		if (
			int(candidate.get("wave", -1)) in [0, 1, 2]
			and candidate.get("health") is Array
			and valid_checkpoint_party(candidate)
		):
			checkpoint = candidate.duplicate(true)
	for id in TaleCatalog.HEROES:
		var saved_hero_levels: Variant = data.get("hero_levels", {})
		var saved_hero_xp: Variant = data.get("hero_xp", {})
		hero_levels[id] = (
			clampi(int(saved_hero_levels.get(id, 1)), 1, 30)
			if saved_hero_levels is Dictionary
			else 1
		)
		hero_xp[id] = (
			clampi(int(saved_hero_xp.get(id, 0)), 0, 9999999) if saved_hero_xp is Dictionary else 0
		)
	player_name = str(data.get("player_name", "Viajante")).strip_edges().substr(0, 20)
	if player_name.is_empty():
		player_name = "Viajante"
	avatar = str(data.get("avatar", "scarlet"))
	if not unlocked.has(avatar):
		avatar = "scarlet"
	player_level = clampi(int(data.get("player_level", 1)), 1, 100)
	player_xp = clampi(int(data.get("player_xp", 0)), 0, 9999999)
	total_kills = maxi(0, int(data.get("total_kills", 0)))
	total_wins = maxi(0, int(data.get("total_wins", cleared.size())))
	total_defeats = maxi(0, int(data.get("total_defeats", 0)))
	total_gold = maxi(gold, int(data.get("total_gold", gold)))
	total_spent = maxi(0, int(data.get("total_spent", 0)))
	play_seconds = maxf(0, float(data.get("play_seconds", 0)))
	idle_anchor = maxi(0, int(data.get("idle_anchor", 0)))
	idle_seconds = clampi(int(data.get("idle_seconds", 0)), 0, IDLE_CAP)
	claimed.clear()
	if data.get("claimed") is Array:
		for item in ACHIEVEMENTS:
			if data.claimed.has(item.id):
				claimed.append(item.id)
	music_volume = clampf(float(data.get("music_volume", 0.45)), 0, 1)
	effects_volume = clampf(float(data.get("effects_volume", 0.65)), 0, 1)
	voice_volume = clampf(float(data.get("voice_volume", 0.5)), 0, 1)
	high_quality = bool(data.get("high_quality", true))
	fps_limit = 30 if int(data.get("fps_limit", 60)) == 30 else 60
	text_speed = int(data.get("text_speed", 36))
	if text_speed not in [0, 24, 48, 36]:
		text_speed = 36
	auto_repeat = bool(data.get("auto_repeat", false))
	unlock_progress = initial_unlock_progress()
	var progress: Variant = data.get("unlock_progress", {})
	if progress is Dictionary:
		for id in TaleCatalog.UNLOCKS:
			if id == "ariel":
				continue
			unlock_progress[id] = clampf(
				float(progress.get(id, 0)), 0, TaleCatalog.UNLOCKS[id].goal
			)
		if progress.get("ariel") is Array:
			for chapter in progress.ariel:
				if (
					typeof(chapter) in [TYPE_INT, TYPE_FLOAT]
					and int(chapter) in range(TaleCatalog.CHAPTER_COUNT)
					and not unlock_progress.ariel.has(int(chapter))
				):
					unlock_progress.ariel.append(int(chapter))
	run_counter = maxi(0, int(data.get("run_counter", 0)))
	formation_rows.clear()
	var saved_rows: Variant = data.get("formation_rows", {})
	for id in TaleCatalog.HEROES:
		formation_rows[id] = str(saved_rows.get(id, TaleCatalog.HERO_TACTICS[id].row)) if saved_rows is Dictionary else str(TaleCatalog.HERO_TACTICS[id].row)
		if formation_rows[id] not in ["front", "back"]:
			formation_rows[id] = TaleCatalog.HERO_TACTICS[id].row
	ensure_front()
	auto_ult = bool(data.get("auto_ult", true))
	window_mode_selected=bool(data.get("window_mode_selected",false))
	window_mode="windowed" if window_mode_selected and data.get("window_mode")=="windowed" else "fullscreen"
	if int(data.get("version", 1)) < 4:
		claimed.erase("ending")
	last_resolved_run = clampi(int(data.get("last_resolved_run", 0)), 0, run_counter)
	if not checkpoint.is_empty():
		var checkpoint_id := int(checkpoint.get("run_id", 0))
		if (
			checkpoint_id > 0
			and (checkpoint_id <= last_resolved_run or checkpoint_id > run_counter)
		):
			checkpoint.clear()
	# Returning to camp avoids associating an old party member's health with a different heroine.
	if data.get("party") is Array and data.party.has("cinderella"):
		checkpoint.clear()


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
			if int(parser.data.get("version", 0)) in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]:
				load_data(parser.data)
				return true
	return false


func earn_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold = mini(9999999, gold + amount)
	total_gold += amount
	goals.memory_peak=maxi(int(goals.get("memory_peak",0)),gold)


func player_next_xp() -> int:
	return 75 + player_level * 50


func hero_next_xp(id: String) -> int:
	return 40 + int(hero_levels[id]) * 25


func hero_level_cost(id: String) -> int:
	return 25 + int(hero_levels[id]) * 12


func can_level_hero(id: String) -> bool:
	return (
		unlocked.has(id)
		and checkpoint.is_empty()
		and hero_levels[id] < 30
		and hero_xp[id] >= hero_next_xp(id)
		and gold >= hero_level_cost(id)
	)


func level_hero(id: String) -> bool:
	if not TaleCatalog.HEROES.has(id) or not can_level_hero(id):
		return false
	var cost := hero_level_cost(id)
	hero_xp[id] -= hero_next_xp(id)
	gold -= cost
	total_spent += cost
	hero_levels[id] += 1
	return true


func grant_xp(amount: int, recipients: Array = []) -> void:
	if amount <= 0:
		return
	for id in party if recipients.is_empty() else recipients:
		if not TaleCatalog.HEROES.has(id):
			continue
		hero_xp[id] = mini(9999999, int(hero_xp[id]) + amount)
	player_xp += amount
	while player_level < 100 and player_xp >= player_next_xp():
		player_xp -= player_next_xp()
		player_level += 1
	if player_level == 100:
		player_xp = 0


func record_enemy(stage: int, recipients: Array = []) -> void:
	total_kills += 1
	earn_gold(3 + stage * 2)
	grant_xp(25 + stage * 10, recipients)


func idle_rate() -> int:
	return 6 + cleared.size() * 4 if not cleared.is_empty() else 0


func settle_idle(now: int) -> void:
	if idle_anchor <= 0:
		idle_anchor = now
		return
	# A backwards clock never grants resources and never replaces a future anchor.
	if now < idle_anchor:
		return
	if not cleared.is_empty():
		idle_seconds = mini(IDLE_CAP, idle_seconds + now - idle_anchor)
	idle_anchor = now


func idle_reward() -> Dictionary:
	var minutes := int(idle_seconds / 60.0)
	return {
		"gold": minutes * idle_rate(),
		"xp": minutes * (2 + cleared.size() * 2) if idle_rate() > 0 else 0,
		"seconds": idle_seconds
	}


func claim_idle(now: int) -> Dictionary:
	settle_idle(now)
	var reward := idle_reward()
	if reward.gold <= 0:
		return {}
	earn_gold(int(reward.gold))
	grant_xp(int(reward.xp))
	idle_seconds = idle_seconds % 60
	return reward


func achievement_ready(id: String) -> bool:
	var progress:=achievement_progress(id)
	return progress.x>=progress.y


func claim_achievement(id: String) -> bool:
	if claimed.has(id) or not achievement_ready(id):
		return false
	for item in ACHIEVEMENTS:
		if item.id == id:
			claimed.append(id)
			earn_gold(int(item.reward))
			return true
	return false


func valid_checkpoint_party(data: Dictionary) -> bool:
	if not data.has("hero_ids"):
		return data.health.size() == party.size()
	var ids: Variant = data.hero_ids
	var drafted: Variant = data.get("drafted", [])
	if not ids is Array or not drafted is Array or ids.is_empty() or ids.size() > (clampi(int(data.get("party_capacity",3)),3,9 if int(data.get("route_format",0))<3 else ExpeditionContent.MAX_PARTY) if data.get("expedition",false) else 3):
		return false
	if data.health.size() != ids.size():
		return false
	var seen: Array = []
	for id in ids:
		if not TaleCatalog.HEROES.has(id) or seen.has(id):
			return false
		if not unlocked.has(id) and not drafted.has(id):
			return false
		seen.append(id)
	if data.get("expedition",false):
		var rows:Dictionary={}
		for id in ids:
			var row:=preload("res://scripts/tactics.gd").rank_for_class(TaleCatalog.HERO_TACTICS[id]["class"])
			rows[row]=int(rows.get(row,0))+1
			if rows[row]>3:return false
	return true


func new_run_id() -> int:
	run_counter += 1
	return run_counter


static func initial_unlock_progress() -> Dictionary:
	var result := {}
	for id in TaleCatalog.UNLOCKS:
		result[id] = [] if id == "ariel" else 0.0
	return result


func unlock_amount(id: String) -> float:
	if id == "ariel":
		return unlock_progress.ariel.size()
	return float(unlock_progress.get(id, 0))


func unlock_text(id: String) -> String:
	return "Desbloqueio permanente" if unlocked.has(id) else "Comprar por 5.000 memórias"

func buy_hero(id:String) -> bool:
	if not TaleCatalog.HEROES.has(id) or unlocked.has(id) or gold<HERO_PRICE or not checkpoint.is_empty():return false
	gold-=HERO_PRICE
	total_spent+=HERO_PRICE
	unlocked.append(id)
	if party.is_empty():party.append(id)
	ensure_front()
	return true


func resolve_run(data: Dictionary, won: bool) -> Array[String]:
	# One terminal resolution per persisted run ID. Reloads cannot credit it twice.
	var number := int(data.get("run_id", 0))
	var newly_unlocked: Array[String] = []
	if number <= last_resolved_run or number <= 0 or number > run_counter:
		return newly_unlocked
	last_resolved_run = number
	var drafted: Array = data.get("drafted", [])
	var metrics: Dictionary = data.get("unlock_stats", {})
	var is_expedition := bool(data.get("expedition", false))
	var bosses: Dictionary = metrics.get("boss_guests", {}) if metrics.get("boss_guests", {}) is Dictionary else {}
	if is_expedition and drafted.has("snow_white"):
		unlock_progress.snow_white = mini(3, int(unlock_progress.snow_white) + bosses.get("snow_white", []).size())
	elif drafted.has("snow_white") and won:
		unlock_progress.snow_white = mini(3, int(unlock_progress.snow_white) + 1)
	if drafted.has("rapunzel"):
		unlock_progress.rapunzel = minf(
			60, float(unlock_progress.rapunzel) + maxf(0, float(metrics.get("healing", 0)))
		)
	if drafted.has("mulan"):
		unlock_progress.mulan = mini(
			8, int(unlock_progress.mulan) + maxi(0, int(metrics.get("combos", 0)))
		)
	if is_expedition and drafted.has("ariel"):
		for chapter in bosses.get("ariel", []):
			if chapter in ExpeditionContent.BOSSES and not unlock_progress.ariel.has(chapter): unlock_progress.ariel.append(chapter)
	elif drafted.has("ariel") and won:
		var ids: Array = data.get("hero_ids", [])
		var health: Array = data.get("health", [])
		var slot := ids.find("ariel")
		var chapter := int(data.get("stage", -1))
		if (
			slot >= 0
			and slot < health.size()
			and float(health[slot]) > 0
			and chapter in range(TaleCatalog.CHAPTER_COUNT)
			and not unlock_progress.ariel.has(chapter)
		):
			unlock_progress.ariel.append(chapter)
	var new_hits: Variant = metrics.get("new_hits", {})
	if new_hits is Dictionary:
		for id in TaleCatalog.NEW_HERO_IDS:
			if drafted.has(id):
				unlock_progress[id] = minf(TaleCatalog.UNLOCKS[id].goal, float(unlock_progress.get(id, 0)) + maxf(0, float(new_hits.get(id, 0))))
	# Feats still progress, but only an explicit memory purchase unlocks a hero.
	return newly_unlocked


static func memory_combats(depth:int) -> int:
	return depth-floori((depth+1)/6.0)

func finish_expedition(data: Dictionary, won: bool) -> Dictionary:
	var number := int(data.get("run_id", 0))
	if not data.get("expedition", false) or number <= last_resolved_run or number > run_counter:
		return {}
	preload("res://scripts/hero_blessings.gd").record(self,data,won and not data.get("endless",false))
	record_achievement_state(data,won)
	var newly_unlocked := resolve_run(data, won)
	best_score = maxi(best_score, int(data.get("score", 0)))
	var infinite := bool(data.get("endless", false))
	var depth := clampi(int(data.get("rooms_cleared", 0)), 0, 2147483647 if infinite else 72)
	var milestones := maxi(0, floori(depth / 12.0) - floori(maxi(best_endless, int(data.get("continuation_from", 0))) / 12.0)) if infinite else 0
	if infinite:
		best_endless = maxi(best_endless, depth)
		endless_runs += 1
	best_depth = maxi(best_depth, mini(floori(depth / 6.0), 12))
	if infinite:goals.endless=maxi(int(goals.get("endless",0)),depth-int(data.get("continuation_from",0)))
	var new_depth := maxi(0, depth - (int(data.get("continuation_from", 0)) if infinite else 0))
	# Markets (phase X-5) do not pay combat memories. Subtract already paid
	# progress when a completed story continues into endless mode.
	var paid_depth:=clampi(int(data.get("continuation_from",0)),0,depth) if infinite else 0
	var combats:=memory_combats(depth)-memory_combats(paid_depth)
	var bosses:=floori(depth/6.0)-floori(paid_depth/6.0)
	var fragments:=mini(9999999,combats*MEMORIES_PER_COMBAT+bosses*MEMORIES_PER_BOSS+(MEMORIES_COMPLETION if won and not infinite else 0)+milestones*MEMORIES_ENDLESS_MILESTONE)
	for key in data.get("synergies_seen", []):
		if preload("res://scripts/team_synergies.gd").PAIRS.has(key) and not discovered_synergies.has(key): discovered_synergies.append(key)
	for key in data.get("events_discovered", []):
		if preload("res://scripts/team_events.gd").has_event(key) and not discovered_events.has(key): discovered_events.append(key)
	earn_gold(fragments)
	grant_xp(new_depth * 8, []) # Profile experience; starting combat stats always use level 1.
	if won and not infinite:
		expedition_wins += 1
		total_wins += 1
	else: total_defeats += 1
	for chapter in mini(floori(depth / 6.0), 12):
		if not cleared.has(chapter):
			cleared.append(chapter)
			journal.append({"stage": chapter, "title": TaleCatalog.STAGES[chapter].name})
	pending_story = -1
	checkpoint.clear()
	return {"unlocks": newly_unlocked, "depth": depth, "reward": fragments, "won": won, "endless": infinite, "milestones": milestones, "score": int(data.get("score", 0)), "best_score": best_score}


func unlock_blessing(id: String) -> bool:
	if not checkpoint.is_empty() or not ExpeditionContent.BLESSINGS.has(id) or blessings_unlocked.has(id): return false
	var required := 4 if id == "thorns" else 8
	var cost: int = ExpeditionContent.BLESSINGS[id].cost
	if best_depth < required or gold < cost: return false
	gold -= cost
	total_spent += cost
	blessings_unlocked.append(id)
	return true


func row_for(id: String) -> String:
	return str(formation_rows.get(id, TaleCatalog.HERO_TACTICS[id].row))


func ensure_front() -> void:
	for id in party:
		if row_for(id) == "front":
			return
	if not party.is_empty():
		formation_rows[party[0]] = "front"


func set_row(id: String, row: String) -> bool:
	if not party.has(id) or row not in ["front", "back"] or not checkpoint.is_empty():
		return false
	if row == "back":
		var others_front := 0
		for other in party:
			if other != id and row_for(other) == "front":
				others_front += 1
		if others_front == 0:
			return false
	formation_rows[id] = row
	return true


static func reset_account(path: String = SAVE_PATH) -> bool:
	# Replace the primary save, then replace the backup too: a stale backup must not resurrect progress.
	var fresh := TaleCampaign.new()
	fresh.idle_anchor = int(Time.get_unix_time_from_system())
	if not fresh.save_to(path):
		return false
	var error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	if error != OK:
		return false
	if FileAccess.file_exists(path + ".tmp"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
	return true
