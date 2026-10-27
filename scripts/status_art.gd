extends RefCounted
## Presentation only: recognizes existing and future status fields without applying damage.
const PATHS={"coin":"res://assets/fx/status_coin.png","bleed":"res://assets/fx/status_bleed.png","curse":"res://assets/fx/status_curse.png"}
const NAMES={"powder":"Pólvora","poison":"Veneno","burn":"Queimadura","bleed":"Sangramento","curse":"Maldição","sleep":"Sono","immortal":"Imortalidade","bubble":"Bolha","hangover":"Ressaca","antiheal":"Corta-Cura","shield_break":"Quebra-Escudos"}
static var textures:Dictionary={}
static func texture(kind:String) -> Texture2D:
	if textures.has(kind):return textures[kind]
	var path:String=PATHS.get(kind,"")
	if path.is_empty() or not ResourceLoader.exists(path):return null
	var source:Texture2D=load(path)
	var crop:=AtlasTexture.new()
	crop.atlas=source
	crop.region=Rect2(source.get_image().get_used_rect())
	crop.filter_clip=true
	textures[kind]=crop
	return crop
static func active(data:Dictionary,hostile:=false) -> Dictionary:
	var result:Dictionary={}
	if float(data.get("hp",1))<=0:return result
	for kind in ["poison","burn","bleed"]:
		var amount:float=float(data.get(kind if hostile else "hostile_"+kind,0))
		var duration:float=float(data.get(kind+"_left",0)) if hostile else float(data.get("hostile_"+kind+"_left",data.get("hostile_dot_left",0)))
		if kind=="bleed":
			amount=maxf(amount,float(data.get("bleeding",data.get("bleed",0))))
			duration=maxf(duration,float(data.get("bleeding_left",data.get("bleed_left",0))))
		if amount>0 and duration>0:result[kind]=[amount,duration]
	if float(data.get("curse_left",0))>0:result.curse=[0.0,float(data.curse_left)]
	if int(data.get("sleep_turns",0))>0:result.sleep=[0.0,float(data.sleep_turns)]
	if int(data.get("powder",0))>0:result.powder=[float(clampi(int(data.powder),0,10)),0.0]
	if protected(data):result.immortal=[0.0,float(data.get("immortal_turns",data.get("invulnerable_turns",0)))]
	for kind in ["bubble","hangover","antiheal","shield_break"]:
		for status in data.get("statuses",[]):
			if status.kind==kind:result[kind]=[0.0,float(status.turns)]
	for kind in ["poison","burn","bleed"]:
		if float(data.get(kind,0))>0 and float(data.get(kind+"_left",0))>0:result[kind]=[float(data[kind]),float(data[kind+"_left"])]
	return result
static func protected(data:Dictionary) -> bool:
	return int(data.get("immortal_turns",0))>0 or int(data.get("invulnerable_turns",0))>0 or float(data.get("invulnerable_left",0))>0
static func description(kind:String,amount:float,duration:float) -> String:
	match kind:
		"powder":return "Pólvora · %d carga(s)\nChapeuzinho causa +%d%% de dano contra este alvo. A ult consome as cargas."%[int(amount),int(amount)*10]
		"curse":return "Maldição · ataque e defesa −20%%\n%.0f turno(s) restantes"%duration
		"bubble":return "Bolha · remove um ataque da próxima vez, podendo chegar a zero"
		"hangover":return "Ressaca · −20 de Iniciativa na próxima vez"
		"antiheal":return "Corta-Cura · cura recebida reduzida em 50%"
		"shield_break":return "Quebra-Escudos · novos escudos reduzidos em 50%"
		"sleep":return "Sono · 50% de chance de perder a vez"
		"immortal":return "Imortalidade ativa · não pode cair enquanto durar a proteção"
	return "%s · %.1f dano por turno\n%.0f turno(s) restantes · até %.1f dano pendente"%[NAMES.get(kind,kind),amount,duration,amount*duration]
