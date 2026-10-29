extends RefCounted
const Rules=preload("res://scripts/combat_rules.gd")
const Details=preload("res://scripts/combat_details.gd")
const COLORS=["ff6969","64c7ff","ead9ff"]
static func coefficient_text(value:float) -> String:
	var rendered:="%.4f"%value
	while rendered.ends_with("0"):rendered=rendered.trim_suffix("0")
	return rendered.trim_suffix(".")
static func preview(a:Dictionary,kind:int) -> Dictionary:
	var description:String=[Details.active(a),Details.passive(a),Details.ultimate(a)][kind]
	var values:Array[float]=[0.0,0.0,0.0]
	var label:=""
	var formula:Array[String]=[]
	if kind==0:values=Rules.basic_components(a)
	elif kind==2:values=Rules.ultimate_components(a)
	if kind==1:
		match str(a.id):
			"scarlet":label="+10% por carga · até 10 cargas"
			"snow_white":values[0]=Rules.power(a,false);label="Adicional exclusivo contra escudos"
			"joao":values[0]=Rules.power(a,false)*1.2;label="Básico contra presa marcada"
			"alice":label="%d / 4 cartas"%int(a.get("card_charge",0))
			"rapunzel":label="−10% de dano sob escudo de seda"
			"ariel":
				var healing_multiplier:float=1+Rules.Bonuses.total(a,"healing")+float(Rules.Gear.effects(a).get("healing",0))
				var healing:float=Rules.power(a,true)*.15*healing_multiplier
				label="%s de cura por acerto"%Details.n(healing)
				formula.append("15%% de AP × bônus de cura: %s × 0,15 × %s ≈ %s"%[Details.n(Rules.power(a,true)),coefficient_text(healing_multiplier),Details.n(healing)])
			"aladin":label="+%.0f%% AP · desejos disponíveis"%(Rules.wishes_left(a)*(20 if Rules.boon(a,0) else 10))
			"puss":label="+%.0f%% AD · vida perdida"%(clampf(1-float(a.hp)/maxf(1,a.max_hp),0,1)*100)
			"mulan":values[0]=Rules.power(a,false)*.6;label="Contra-ataque"
			"maria":values[2]=Rules.power(a,true)*.1;label="Por dose / turno";formula.append("10%% de AP: %s × 0,10 ≈ %s"%[Details.n(Rules.power(a,true)),Details.n(values[2])])
			"matches":values[2]=Rules.power(a,true);label="Fogo inicial / turno";formula.append("100%% de AP: %s × 1 ≈ %s"%[Details.n(Rules.power(a,true)),Details.n(values[2])])
			_:label="Efeito passivo"
	if a.id=="rapunzel" and kind!=1 and not (kind==0 and a.get("sealed",false)):
		values=[0.0,0.0,0.0]
		var coefficient:float=1.0 if kind==0 else 3.0 if Rules.boon(a,3) else 2.0
		label="%s de escudo"%Details.n(Rules.power(a,true)*coefficient)
		formula.append("%.0f%% de AP: %s × %s ≈ %s de escudo"%[coefficient*100,Details.n(Rules.power(a,true)),coefficient_text(coefficient),Details.n(Rules.power(a,true)*coefficient)])
	if a.id=="joao" and kind==2:
		values[0]=Rules.power(a,false)*.5
		label="Por estocada · 6 golpes"
		formula.append("Presa marcada: 70% de AD por estocada; sem marca: 50%.")
	if a.id=="aladin" and kind==2:label="3 desejos · manual"
	if a.id=="peter" and kind==2:label="3 sombras · fortalecimento"
	if a.id=="maria" and kind==2:label="75% de chance · Maldição"
	if kind!=1 and not (a.id=="rapunzel" and not a.get("sealed",false)):
		var effects:Dictionary=Rules.Gear.effects(a)
		var multiplier:float=1.0+float(effects.get("ult_mult" if kind==2 else "attack_mult",0))
		if kind==2 and a.get("gear_first_ult",false):multiplier*=1+float(effects.get("first_ult",0))
		if kind==0:multiplier*=float(a.get("gear_basic_scale",1))
		for i in 3:values[i]*=multiplier
	var lines:Array[String]=[]
	for i in 3:
		if values[i]<=0:continue
		lines.append("[color=#%s]%s %s[/color]"%[COLORS[i],Details.n(values[i]),["físico","mágico","real"][i]])
		if i<2:
			var base:=Rules.power(a,i==1)
			var coefficient:float=values[i]/maxf(.001,base)
			formula.append("%.0f%% de %s: %s × %s ≈ %s"%[coefficient*100,"AP" if i==1 else "AD",Details.n(base),coefficient_text(coefficient),Details.n(values[i])])
	if not label.is_empty():lines.append(label)
	if lines.is_empty():lines.append("Efeito utilitário")
	formula.append("Prévia sem alvo, antes das defesas e dos críticos. Multiplicadores que dependem do alvo, impactos extras e efeitos condicionais de equipamentos não estão incluídos. Valores arredondados para exibição.")
	return {"summary":" · ".join(lines),"detail":description+"\n\n"+"\n".join(formula),"components":values}
