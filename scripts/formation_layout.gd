extends RefCounted
## Mirrored fixed slots. Dead units retain their slot throughout an encounter.
const ROWS := ["back", "middle", "front"]
const MAX_PER_ROW := 3
const FLOOR_HORIZON := 0.36
const COLUMNS := {"back":0.12,"middle":0.255,"front":0.39}
const SINGLE_DEPTH := {"back":0.52,"middle":0.69,"front":0.86}
const DEPTHS := {2:[0.50,0.86],3:[0.44,0.66,0.88]}
static func zone(hostile: bool) -> Rect2:
	return Rect2(0.56 if hostile else 0.06,0.40,0.38,0.50)
static func max_stack(units: Array) -> int:
	var result := 0
	for row in ROWS:
		var count := 0
		for unit in units:
			if unit.row == row: count += 1
		result = maxi(result,count)
	return result
static func home(units: Array,index: int,hostile: bool) -> Vector2:
	var row: String = units[index].row
	var peers: Array[int] = []
	for at in units.size():
		if units[at].row == row: peers.append(at)
	assert(peers.size() <= MAX_PER_ROW,"Each row supports at most three units")
	var y: float = SINGLE_DEPTH[row] if peers.size()==1 else DEPTHS[peers.size()][peers.find(index)]
	var x: float = COLUMNS[row]
	return Vector2(1.0-x if hostile else x,y)
