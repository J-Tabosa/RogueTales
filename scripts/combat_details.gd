extends RefCounted
const Data=preload("res://scripts/roster_data.gd")
const Rules=preload("res://scripts/combat_rules.gd")
static func n(value:float) -> String:return "%.1f"%value
static func has(a:Dictionary,key:String) -> bool:return a.get("mutations",[]).has(key)
static func active(a:Dictionary) -> String:return Data.TEXT[a.id].basic_text
static func passive(a:Dictionary) -> String:return Data.TEXT[a.id].passive_text
static func ultimate(a:Dictionary) -> String:return Data.TEXT[a.id].ult_text
static func conditions(a:Dictionary) -> String:
	var lines:Array[String]=[]
	for s in a.get("statuses",[]):lines.append("%s · %s turno(s) · %.1f dano por turno"%[str(preload("res://scripts/status_art.gd").NAMES.get(s.kind,s.kind)),"∞" if int(s.turns)<0 else str(s.turns),float(s.potency)*int(s.stacks)])
	return "\n".join(lines)
static func sheet(a:Dictionary) -> String:
	return "%s · %s\nPV %s / %s · Escudo %s\nDano Físico %s · Dano Mágico %s\nDefesa Física %s · Defesa Mágica %s\nIniciativa %.0f · Ataques %d\nCrítico %.0f%% ×%s · Esquiva %.0f%%\n\n%s\n%s\n\n%s\n%s\n\n%s · %s\n%s"%[TaleCatalog.HEROES[a.id].name,TaleCatalog.hero_class_name(a.id),n(a.hp),n(a.max_hp),n(a.shield),n(Rules.power(a,false)),n(Rules.power(a,true)),n(Rules.defense(a,false)),n(Rules.defense(a,true)),Rules.effective_initiative(a),int(a.attacks),float(a.crit)*100,n(a.crit_multiplier),minf(.8,float(a.evasion))*100,Data.TEXT[a.id].basic,active(a),Data.TEXT[a.id].passive,passive(a),Data.TEXT[a.id].ult,Rules.resource(a),ultimate(a)]
