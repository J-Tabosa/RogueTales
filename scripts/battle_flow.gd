extends RefCounted
## One action at a time. Initiative sorts each round; AP buys actions and PP reactions.
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
	if not entry.get("manual", false):
		unit(entry).ap = maxi(0, int(unit(entry).ap) - 1)

func complete() -> void:
	active.clear()
	waiting = 0.18

func queue_ultimate(index: int) -> bool:
	if ult_queue.has(index) or (active.get("side") == "ally" and active.get("index") == index):
		return false
	ult_queue.append(index)
	owner_ref.get_ref().actors[index].ult_queued = true
	return true
