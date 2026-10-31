extends RefCounted
## The four starting forests have their own roster; later biomes stay unchanged.
const Roster = preload("res://scripts/roster_data.gd")
const MAPS = {"FlorestaPrimavera":"spring","FlorestaVerao":"summer","FlorestaOutono":"autumn","FlorestaInverno":"winter"}
const LABELS = {"spring":"Primavera","summer":"Verão","autumn":"Outono","winter":"Inverno"}
## name, class, category, HP%, damage%, defense%, initiative%, range, boss
const DATA = {
	"winter_wolf":["Lobo Branco","assassin","beast",55,75,30,125,"short",false],
	"winter_owl":["Coruja Branca","assassin","beast",45,70,25,125,"short",false],
	"winter_hunter":["Caçador de Inverno","ranger","humanoid",55,100,30,80,"medium",false],
	"winter_moose":["Alce","vanguard","beast",440,105,105,90,"short",true],
	"autumn_hare":["Lebre de Dentes Afiados","assassin","beast",35,55,15,140,"short",false],
	"autumn_fox":["Raposa","assassin","beast",45,65,25,125,"short",false],
	"autumn_wolf":["Lobo Preto","assassin","beast",60,85,35,120,"short",false],
	"autumn_lumberjack":["Lenhador","vanguard","humanoid",400,115,90,85,"short",true],
	"spring_wolf":["Lobo Cinza","assassin","beast",55,75,30,120,"short",false],
	"spring_boar":["Javali","vanguard","beast",100,70,70,95,"short",false],
	"spring_hunter":["Caçador de Primavera","ranger","humanoid",45,90,25,85,"long",false],
	"spring_bear":["Urso Pardo","vanguard","beast",480,115,115,80,"short",true],
	"summer_falcon":["Falcão","assassin","beast",40,70,20,135,"short",false],
	"summer_raccoon":["Guaxinim","vanguard","beast",65,60,40,100,"short",false],
	"summer_wolf":["Lobo Marrom","assassin","beast",55,80,30,120,"short",false],
	"summer_snake":["Serpente","assassin","beast",360,125,65,90,"short",true]
}
static var animation_data:Dictionary={}
static var frame_cache:Dictionary={}

static func season_for(owner) -> String:
	if not owner.expedition or not owner.active_secret.is_empty():return ""
	if owner.journey.is_empty() or owner.stage>=owner.journey.get("path",[]).size():return ""
	return MAPS.get(str(owner.journey.path[owner.stage]),"")

static func averages() -> Dictionary:
	var out:={"hp":0.0,"damage":0.0,"armor":0.0,"magic_defense":0.0,"initiative":0.0}
	for hero in Roster.BASE.values():
		out.hp+=hero.hp
		out.damage+=hero.physical_damage+hero.magic_damage
		out.armor+=hero.physical_defense
		out.magic_defense+=hero.magic_defense
		out.initiative+=hero.initiative
	for key in out:out[key]/=Roster.BASE.size()
	return out

static func profiles() -> Dictionary:
	var base:=averages()
	var out:={}
	for id in DATA:
		var d:Array=DATA[id]
		out["phase1_"+id]={"id":"phase1_"+id,"tipo":"Chefe" if d[8] else "Comum","bioma":"Floresta "+LABELS[str(id).get_slice("_",0)],"nome":d[0],"classe":d[1],
			"vida_base":base.hp*float(d[3])*.01,"ataque_base":base.damage*float(d[4])*.01,
			"def_fisica_base":base.armor*float(d[5])*.01,"def_magica_base":base.magic_defense*float(d[5])*.01,
			"iniciativa":base.initiative*float(d[6])*.01,"qtd_ataques":1,"esquiva":0.0,"intervalo_visual":3.0}
	return out

static func boss_for(season:String) -> String:
	for id in DATA:
		if id.begins_with(season+"_") and DATA[id][8]:return id
	return ""

static func spawn(owner, edited:Dictionary) -> Array[Dictionary]:
	var season:=season_for(owner)
	var result:Array[Dictionary]=[]
	if season.is_empty() or ExpeditionContent.is_market(owner.phase):return result
	var is_boss:=ExpeditionContent.is_boss(owner.stage,owner.phase)
	var count:int=1 if is_boss else (owner.phase+1 if not owner.endless and owner.phase<3 else owner.rng.randi_range(1,ExpeditionContent.enemy_limit(owner.stage,owner.endless)))
	var pool:Array[String]=[]
	for id in DATA:
		if id.begins_with(season+"_") and not DATA[id][8]:pool.append(id)
	var originals:=profiles()
	var rows:={"front":0,"middle":0,"back":0}
	for n in count:
		var id:=boss_for(season) if is_boss else pool[owner.rng.randi_range(0,pool.size()-1)]
		var spec:Array=DATA[id]
		var stats:Dictionary=edited.get("phase1_"+id,originals["phase1_"+id])
		var row:String="front" if spec[1]=="vanguard" else "middle" if spec[1]=="assassin" else "back"
		if rows[row]>=3:
			for alternative in rows:
				if rows[alternative]<3:row=alternative;break
		rows[row]+=1
		# First-map table values already include the boss bonus. Never apply
		# the old 1.5× boss pool, group dilution, or intra-map growth again.
		var depth:int=owner.rooms_cleared if owner.endless else owner.stage*6
		var growth:float=(1+depth*.05)*pow(1.045,mini(depth,120))*(1+maxi(0,depth-120)*.08)
		var hp:float=float(stats.vida_base)*growth*(1.35 if owner.room_kind=="elite" else 1.0)
		result.append({"id":"enemy_%d"%n,"species_id":id,"balance_id":"phase1_"+id,"name":stats.nome,"class":spec[1],"category":spec[2],"range":spec[7],"flying":id in ["winter_owl","summer_falcon"],
			"row":row,"hp":hp,"max_hp":hp,"damage":float(stats.ataque_base)*(1+depth*.85/13)*(1.15 if owner.room_kind=="elite" else 1.0),
			"armor":float(stats.def_fisica_base),"magic_defense":float(stats.def_magica_base),"initiative":float(stats.iniciativa),"attacks":int(stats.qtd_ataques),"evasion":float(stats.esquiva),
			"boss":is_boss,"interval":float(stats.intervalo_visual),"timer":1.8+n*.5,"biome":owner.current_biome(),"variant":0,
			"burn":0.0,"burn_left":0.0,"poison":0.0,"poison_left":0.0})
	return result

static func metadata(id:String) -> Dictionary:
	if animation_data.is_empty():animation_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/phase1/manifest.json"))
	return animation_data.get(id,{})

static func frames(id:String) -> SpriteFrames:
	if frame_cache.has(id):return frame_cache[id]
	# Bound resident textures when cycling between forests on mobile.
	if frame_cache.size()>=4:frame_cache.erase(frame_cache.keys()[0])
	var data:=metadata(id)
	var result:=SpriteFrames.new()
	result.remove_animation("default")
	for name in ["idle","attack","boss_idle","boss_attack"]:
		var attack:bool=name.ends_with("attack")
		result.add_animation(name)
		result.set_animation_speed(name,float(data.fps) if attack else 6.0)
		result.set_animation_loop(name,not attack)
		for path in data.attack if attack else data.idle:result.add_frame(name,load(path))
	frame_cache[id]=result
	return result

static func impact_times(id:String) -> Array[float]:
	var d:=metadata(id)
	var times:Array[float]=[]
	for frame in d.impacts:times.append((float(frame)-1)/float(d.fps))
	return times
