extends RefCounted
## Concise effect labels share the game's vector icon system, without emoji fonts.
static func symbol(key: String) -> String:
	return {"capacity":"heroes","potion":"potion","power":"sword","heart":"heart","haste":"clock","critical":"target","leech":"heart","armor":"shield"}.get(key,"magic")

static func for_supply(key: String, capacity: int) -> Array:
	if key.begins_with("bonus:"):
		var b=preload("res://scripts/run_bonuses.gd").describe(key)
		return [{"glyph":"heroes" if b.mode=="group" else "profile","text":"Equipe + futuros" if b.mode=="group" else "Escolher personagem"}]
	match key:
		"capacity":return [{"glyph":"heroes","text":"%d → %d vagas"%[capacity,mini(9,capacity+1)]}]
		"potion":return [{"glyph":"heart","text":"Cura 35%"},{"glyph":"potion","text":"Revive 1 aliado"}]
		"item:ember_pearl":return [{"glyph":"flame","text":"18%/vez · 2 turnos","color":"e8a06a"}]
		"item:winter_match":return [{"glyph":"skull","text":"Fogo → veneno"},{"glyph":"clock","text":"Iniciativa −20"}]
		"item:venom_vial":return [{"glyph":"skull","text":"12%/vez · 2 turnos","color":"a7c77d"},{"glyph":"poison","text":"Até 4 doses"}]
		"item:hunters_lens":return [{"glyph":"target","text":"Crítico +12%"},{"glyph":"sword","text":"Dano +15%"}]
		"item:tower_braid":return [{"glyph":"heart","text":"+40 PV"},{"glyph":"shield","text":"+4 Def. Física"}]
		"item:clockwork":return [{"glyph":"clock","text":"Iniciativa +15"},{"glyph":"magic","text":"+4 mana"}]
		"item:mirror_shard":return [{"glyph":"shield","text":"Escudo 20%"},{"glyph":"mirror","text":"Reflete 20%"}]
		"item:echo_bell":return [{"glyph":"blast_pair","text":"2 alvos · eco 30%"}]
		"item:red_goblet":return [{"glyph":"heart","text":"+4 PV/acerto"},{"glyph":"skull","text":"Abate: cura 6%"}]
		"item:jade_seal":return [{"glyph":"bomb","text":"ULT +25%"},{"glyph":"shield","text":"Escudo 15%"}]
		"power":return [{"glyph":"sword","text":"Dano +20%"}]
		"heart":return [{"glyph":"heart","text":"+25 PV"},{"glyph":"potion","text":"Cura 40 PV"}]
		"haste":return [{"glyph":"clock","text":"Iniciativa +10"}]
		"critical":return [{"glyph":"target","text":"Crítico +12%"}]
		"leech":return [{"glyph":"heart","text":"+3 PV/acerto"}]
		"armor":return [{"glyph":"shield","text":"+3 Def. Física"}]
	return [{"glyph":"magic","text":"Ver efeito"}]
