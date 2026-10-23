extends RefCounted
## Serialized idle cooldowns for runs; legacy checkpoints keep their AP rounds.
var owner_ref: WeakRef
var order: Array[Dictionary] = []
var round_number := 0
var cursor := 0
var waiting := 0.3
var active: Dictionary = {}
var ult_queue: Array[int] = []

func bind(owner) -> void:
	owner_ref = weakref(owner)
	start_round()
	if owner.expedition:
		for entry in order:
			ready_at[entry_key(entry)] = (0.7 if entry.side == "ally" else 1.05) + entry.index * 0.22

func unit(entry: Dictionary) -> Dictionary:
	var owner = owner_ref.get_ref()
	return owner.actors[entry.index] if entry.side == "ally" else owner.tactics.enemies[entry.index]

func start_round() -> void:
	var owner = owner_ref.get_ref()
	round_number += 1
	if owner.expedition:
		owner.tactics.synergy_used.clear()
		owner.tactics.BossRules.round_start(owner.tactics)
	order.clear()
	cursor = 0
	for side in ["ally", "enemy"]:
		var units: Array = owner.actors if side == "ally" else owner.tactics.enemies
		for index in units.size():
			var actor: Dictionary = units[index]
			actor.ap = 2 if side == "ally" or actor.get("boss", false) else 1
			actor.pp = 2 if actor.get("boss", false) else 1
			if actor.hp > 0:
				var interval: float = actor.interval if side == "ally" else owner.tactics.interval_for(index)
				if side == "ally" and int(actor.get("hindered_rounds", 0)) > 0: interval *= 1.3
				order.append({"side": side, "index": index, "initiative": 100.0 / maxf(0.1, interval)})
	order.sort_custom(func(a, b):
		if is_equal_approx(a.initiative, b.initiative):
			return a.index < b.index if a.side == b.side else a.side == "ally"
		return a.initiative > b.initiative)

func preview(limit := 6) -> Array[Dictionary]:
	if owner_ref.get_ref().expedition:
		var upcoming: Array[Dictionary] = []
		for entry in order:
			if unit(entry).hp > 0: upcoming.append(entry)
		upcoming.sort_custom(func(a, b): return ready_at.get(entry_key(a), 0) < ready_at.get(entry_key(b), 0))
		return upcoming.slice(0, limit)
	var result: Array[Dictionary] = []
	if order.is_empty():
		return result
	for offset in order.size():
		var entry: Dictionary = order[(cursor + offset) % order.size()]
		if unit(entry).hp > 0 and unit(entry).ap > 0:
			result.append(entry)
			if result.size() >= limit:
				break
	return result

func next_action() -> Dictionary:
	if not active.is_empty():
		return {}
	var owner = owner_ref.get_ref()
	while not ult_queue.is_empty():
		var index: int = ult_queue.pop_front()
		if index < owner.actors.size():
			var actor: Dictionary = owner.actors[index]
			actor.ult_queued = false
			if actor.hp > 0 and actor.energy >= 100:
				return {"side": "ally", "index": index, "ultimate": true, "manual": true}
	if owner.expedition: return cooldown_action()
	if order.is_empty():
		return {}
	for attempt in order.size():
		var entry: Dictionary = order[cursor]
		cursor = (cursor + 1) % order.size()
		if unit(entry).hp > 0 and unit(entry).ap > 0:
			return entry.duplicate()
	start_round()
	waiting = 0.55
	return {}

func begin(entry: Dictionary) -> void:
	active = entry.duplicate()
	if owner_ref.get_ref().expedition:
		var owner = owner_ref.get_ref()
		var interval: float = unit(entry).interval if entry.side == "ally" else owner.tactics.interval_for(entry.index)
		if entry.side == "ally" and int(unit(entry).get("hindered_rounds", 0)) > 0: interval *= 1.3
		ready_at[entry_key(entry)] = clock + maxf(1.5, interval * 1.25)
		return
	if not entry.get("manual", false):
		unit(entry).ap = maxi(0, int(unit(entry).ap) - 1)

func complete() -> void:
	active.clear()
	waiting = 0.46

func queue_ultimate(index: int) -> bool:
	if ult_queue.has(index) or (active.get("side") == "ally" and active.get("index") == index):
		return false
	ult_queue.append(index)
	owner_ref.get_ref().actors[index].ult_queued = true
	return true


# Runs use cooldowns, rather than AP rounds. Every living unit gets its own turn.
var clock := 0.0
var ready_at: Dictionary = {}
var reaction_at := 6.0
var reaction_due: Dictionary = {}

func entry_key(entry: Dictionary) -> String:
	return "%s:%d" % [entry.side, entry.index]

func advance(delta: float) -> void:
	if not owner_ref.get_ref().expedition: return
	clock += delta
	if clock >= reaction_at:
		reaction_at = clock + 6.0
		var owner = owner_ref.get_ref()
		owner.tactics.synergy_used.clear()
		owner.tactics.BossRules.round_start(owner.tactics)
	for entry in order:
		var actor := unit(entry)
		var key := entry_key(entry)
		if actor.pp > 0:
			reaction_due.erase(key)
		elif not reaction_due.has(key):
			reaction_due[key] = clock + 6.0
		elif clock >= float(reaction_due[key]):
			actor.pp = 1
			reaction_due.erase(key)

func cooldown_action() -> Dictionary:
	var selected := {}
	var earliest := INF
	for entry in order:
		if unit(entry).hp <= 0: continue
		var at: float = ready_at.get(entry_key(entry), 0.0)
		if at <= clock and at < earliest:
			earliest = at
			selected = entry
	return selected.duplicate()
