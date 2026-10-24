extends RefCounted
## Width is shared by battle, gallery and editable scenes. Height stays independent.
const WIDTH := {"puss": 1.25}
static func width(id: String) -> float:
	return float(WIDTH.get(id,1.0))
static func height(id: String) -> float:
	return 0.62 if id=="puss" else 0.75 if id=="matches" else 1.0

const FACE := {"scarlet":Vector2(.65,.18),"rapunzel":Vector2(.77,.19),"snow_white":Vector2(.60,.18),"mulan":Vector2(.62,.18),"ariel":Vector2(.64,.19),"joao":Vector2(.62,.18),"maria":Vector2(.58,.18),"alice":Vector2(.60,.19),"puss":Vector2(.62,.25),"matches":Vector2(.58,.23),"peter":Vector2(.54,.24),"aladin":Vector2(.62,.18)}
