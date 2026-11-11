extends RefCounted

const Worlds = preload("res://scripts/world_routes.gd")

static func place(owner: IdleRun, map_id: String) -> bool:
	for season in Worlds.PATHS:
		for path in Worlds.PATHS[season]:
			var index: int = path.find(map_id)
			if index < 0: continue
			owner.journey = {"format": 1, "season": season, "path": path.slice(0, index + 1)}
			owner.stage = index
			return true
	return false

static func place_at_meeting(owner: IdleRun, hero: String) -> bool:
	for map_id in Worlds.NODES:
		if Worlds.meeting_heroes(Worlds.NODES[map_id]).has(hero):
			return place(owner, map_id)
	return false
