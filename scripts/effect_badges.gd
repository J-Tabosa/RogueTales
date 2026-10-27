extends RefCounted
## Concise effect labels share the game's vector icon system, without emoji fonts.
static func symbol(key: String) -> String:
	return {"capacity":"heroes","potion":"potion","power":"sword","heart":"heart","haste":"clock","critical":"target","leech":"heart","armor":"shield"}.get(key,"magic")

static func for_supply(key: String, capacity: int) -> Array:
	if key.begins_with("bonus:"):
		var b=preload("res://scripts/run_bonuses.gd").describe(key)
		return [{"glyph":"heroes" if b.mode=="group" else "profile","text":"Equipe + futuros" if b.mode=="group" else "Escolher personagem"}]
	if key.begins_with("item:"):
		var id:=key.trim_prefix("item:")
		var gear=preload("res://scripts/equipment.gd")
		return [{"glyph":"magic","text":gear.rarity_name(id),"color":gear.tint(id).to_html(false)}]
	match key:
		"capacity":return [{"glyph":"heroes","text":"%d → %d vagas"%[capacity,mini(9,capacity+1)]}]
		"potion":return [{"glyph":"heart","text":"Cura 35%"},{"glyph":"potion","text":"Revive 1 aliado"}]
		"power":return [{"glyph":"sword","text":"Dano +20%"}]
		"heart":return [{"glyph":"heart","text":"+25 PV"},{"glyph":"potion","text":"Cura 40 PV"}]
		"haste":return [{"glyph":"clock","text":"Iniciativa +10"}]
		"critical":return [{"glyph":"target","text":"Crítico +12%"}]
		"leech":return [{"glyph":"heart","text":"+3 PV/acerto"}]
		"armor":return [{"glyph":"shield","text":"+3 Def. Física"}]
	return [{"glyph":"magic","text":"Ver efeito"}]
