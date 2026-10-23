extends RefCounted
## Width is shared by battle, gallery and editable scenes. Height stays independent.
const WIDTH := {"mulan": 1.18, "aladin": 1.18, "ariel": 1.12, "alice": 1.15, "joao": 1.25, "maria": 1.18, "puss": 1.06}
static func width(id: String) -> float:
	return float(WIDTH.get(id,1.0))
static func height(id: String) -> float:
	return 0.62 if id=="puss" else 0.75 if id=="matches" else 1.0
