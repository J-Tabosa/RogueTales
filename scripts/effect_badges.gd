extends RefCounted
## Concise effect labels share the game's vector icon system, without emoji fonts.
static func symbol(key: String) -> String:
	if ExpeditionContent.SHOP_SUPPLIES.has(key):
		return "heart" if key == ExpeditionContent.REVIVE_SUPPLY else "potion"
	return {"capacity":"heroes","power":"sword","heart":"heart","haste":"clock","critical":"target","leech":"heart","armor":"shield"}.get(key,"magic")

static func for_supply(key: String, capacity: int) -> Array:
	if key.begins_with("bonus:"):
		var b=preload("res://scripts/run_bonuses.gd").describe(key)
		return [{"glyph":"heroes" if b.mode=="group" else "profile","text":"Equipe + futuros" if b.mode=="group" else "Escolher personagem"}]
	if key.begins_with("item:"):
		var id:=key.trim_prefix("item:")
		var gear=preload("res://scripts/equipment.gd")
		return [{"glyph":"magic","text":gear.rarity_name(id),"color":gear.tint(id).to_html(false)}]
	if ExpeditionContent.SHOP_SUPPLIES.has(key):
		var percent := roundi(ExpeditionContent.SHOP_SUPPLIES[key].fraction * 100)
		if key == ExpeditionContent.REVIVE_SUPPLY:
			return [{"glyph":"heart","text":"1 aliado com %d%% PV" % percent}]
		return [{"glyph":"heart","text":"Cura %d%%" % percent},{"glyph":"heroes","text":"Aliados vivos"}]
	match key:
		"capacity":return [{"glyph":"heroes","text":"%d → %d vagas"%[capacity,mini(5,capacity+1)]}]
		"power":return [{"glyph":"sword","text":"Dano +20%"}]
		"heart":return [{"glyph":"heart","text":"+25 PV"},{"glyph":"potion","text":"Cura 40 PV"}]
		"haste":return [{"glyph":"clock","text":"Iniciativa +10"}]
		"critical":return [{"glyph":"target","text":"Crítico +12%"}]
		"leech":return [{"glyph":"heart","text":"+3 PV/acerto"}]
		"armor":return [{"glyph":"shield","text":"+3 Def. Física"}]
	return [{"glyph":"magic","text":"Ver efeito"}]
