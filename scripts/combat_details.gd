extends RefCounted
## Read-only descriptions from the same live stats used by combat. No RNG draws.
const Content = preload("res://scripts/expedition_content.gd")
static func n(value: float) -> String:
	return "%.1f" % value
static func has(a: Dictionary, key: String) -> bool:
	return Content.has(a,key)
static func active(a: Dictionary) -> String:
	var d: float=a.damage
	match str(a.id):
		"scarlet": return "%s dano + %s fogo/s por 5 s. A cada %d acertos: +%s no alvo e %s nos demais.%s" % [n(d),n(d*.12),2 if has(a,"quick") else 3,n(d),n(d*.45)," Espalha fogo." if has(a,"spread") else ""]
		"snow_white": return "%s dano + %s veneno/s por aplicação (até %s/s), por 5 s. Alvo já envenenado: cura própria de %s PV.%s" % [n(d),n(d*(.2 if has(a,"stack") else .1)),n(d*(.8 if has(a,"stack") else .4)),n(a.max_hp*.06)," Cura também um aliado em 6% dos PV dele." if has(a,"harvest") else ""]
		"rapunzel": return "%s dano; cura o aliado mais ferido em 8%% dos PV máximos dele.%s%s" % [n(d)," Cura um segundo aliado." if has(a,"twin") else ""," Concede escudo de 8% dos PV do alvo." if has(a,"barrier") else ""]
		"mulan": return "%s dano; a cada %d acertos, %s no alvo e %s nos outros inimigos %s." % [n(d),2 if has(a,"quick") else 3,n(d*1.8),n(d*.8),"de qualquer linha" if has(a,"dragon") else "da frente"]
		"ariel": return "%s dano; a cada %d acertos, cura 12%% dos PV máximos de cada aliado.%s%s" % [n(d),2 if has(a,"quick") else 3," Atrasa inimigos em 3 s." if has(a,"tide") else ""," Escudo coletivo de 10% dos PV." if has(a,"overflow") else ""]
		"joao": return "%s dano e marca. Contra alvo marcado: %s dano.%s" % [n(d),n(d*1.4)," Aliados causam +20% contra a marca." if has(a,"hunt") else ""]
		"maria": return "%s dano; alterna veneno de %s/s (5 s, até 4 aplicações) e consumo: +2,5 × veneno/s em dano, cura %s PV.%s%s" % [n(d),n(d*.14),n(a.max_hp*.12)," Preserva metade do veneno." if has(a,"keep") else ""," Cura os demais em 8% dos PV deles." if has(a,"feast") else ""]
		"alice": return "Espadas: %s dano. Copas: %s dano + cura %s. Ouros: %s dano + escudo coletivo de 10%% dos PV. Paus: %s dano + %s nos %s. Ciclo ♠ ♥ ♦ ♣." % [n(d*1.5),n(d),"coletiva de 10% dos PV" if has(a,"heart") else "de 15% dos PV do aliado mais ferido",n(d),n(d),n(d*.75),"demais" if has(a,"double") else "outro alvo"]
		"puss": return "Alterna preparação (%s dano) e corte (%s no alvo + %s nos outros inimigos %s)." % [n(d*.65),n(d*2.4),n(d*1.2),"de qualquer linha" if has(a,"sweep") else "da frente"]
		"matches": return "%s dano; +%s fogo/s por acerto, até %s/s, duração 5 s.%s" % [n(d),n(d*.13),n(d*.5)," Incendeia outro alvo por "+n(d*.10)+"/s." if has(a,"spread") else ""]
		"peter": return "%s dano; cada sombra adiciona %s, até 3 sombras (%s).%s" % [n(d),n(d*.6),n(d*2.8)," Preserva uma sombra após atacar." if has(a,"keep") else ""]
		"aladin": return "Ciclo: %s dano → %s dano + escudo coletivo de %d%% dos PV → %s dano + cura coletiva de %d%% dos PV.%s" % [n(d*1.7),n(d),24 if has(a,"generous") else 12,n(d),20 if has(a,"generous") else 10," O desejo ofensivo atinge outro alvo por "+n(d)+"." if has(a,"storm") else ""]
	return n(d)+" dano."
static func passive(a: Dictionary) -> String:
	var d: float=a.damage
	match str(a.id):
		"scarlet": return "Acerto crítico: +20 mana."
		"snow_white": return "Morte de alvo envenenado: transfere seu veneno (mínimo %s/s) por 5 s a %s." % [n(d*.10),"todos os sobreviventes" if has(a,"seed") else "um sobrevivente"]
		"rapunzel": return "Aliado atingido abaixo de %d%% dos PV: cura %d%% e escudo de 8%% dos PV máximos dele." % [65 if has(a,"rescue") else 45,20 if has(a,"rescue") else 10]
		"mulan": return "Esquiva: contracorte de %s dano e escudo próprio de %s PV.%s" % [n(d*.45),n(a.max_hp*.1)," Escudo coletivo de 8% dos PV." if has(a,"guard") else ""]
		"ariel": return "Aliado atingido abaixo de 50% dos PV: cura 8% dos PV dele e atrasa inimigos em 3 s."
		"joao": return "Outro aliado acerta sua presa marcada: estocada adicional de %s dano%s." % [n(d*.6)," + valor da armadura inimiga" if has(a,"pierce") else ""]
		"maria": return "Ao receber dano: +%s veneno/s no agressor (5 s; até 4 aplicações).%s" % [n(d*.16)," Nos outros: "+n(d*.10)+"/s." if has(a,"toxic") else ""]
		"alice": return "Ao receber dano: avança um naipe e ganha 25 mana.%s" % [" Ao completar o ciclo: +25 mana e recarrega a passiva." if has(a,"wild") else ""]
		"puss": return "Intercepta golpe dirigido a outro aliado abaixo de 45%% dos PV; recebe 75%% do dano.%s" % [" Uma vez por combate: revive com 30% dos PV." if has(a,"nine") else ""]
		"matches": return "Morte de alvo incendiado: espalha fogo por 5 s (mínimo %s/s) e causa %s dano imediato.%s" % [n(d*.12),n(d*(.6 if has(a,"fuel") else .3))," +25 mana." if has(a,"ash") else ""]
		"peter": return "Esquiva: contra-ataca por %s dano e cria %d sombra(s), até 3." % [n(d*.6),2 if has(a,"double") else 1]
		"aladin": return "Escudo de aliado se rompe: +12 mana para todos.%s" % [" Concede escudo coletivo de 8% dos PV." if has(a,"reserve") else ""]
	return ""
static func ultimate(a: Dictionary) -> String:
	var d: float=a.damage
	var factor: float={"scarlet":2.0,"snow_white":4.0,"mulan":3.2,"ariel":1.6,"joao":4.2,"maria":2.8,"alice":2.0,"puss":3.6,"matches":2.0,"peter":0.0,"aladin":2.0,"rapunzel":0.0}.get(a.id,1.0)
	var ranks: Array=a.get("ranks",[0,0,0])
	var extras: Dictionary={
		"scarlet":"Todos os inimigos; fogo %s/s por 4 s."%n(6+int(ranks[1])*2),
		"snow_white":"Um alvo; veneno %s/s por 6 s."%n(8+int(ranks[0])*2),
		"mulan":"Inimigos da frente; escudo próprio de %s PV."%n(a.max_hp*.35),
		"ariel":"Todos; cura coletiva 20% dos PV, remove condições e atrasa inimigos 5 s.",
		"joao":"Um alvo: 5 estocadas de %s cada."%n(d*.84),
		"maria":"Todos; veneno %s/s por 6 s e −20%% armadura por 6 s."%n(8+int(ranks[2])*2),
		"alice":"Todos os inimigos; explosão do naipe atual.",
		"puss":"Inimigos da frente; escudo próprio de %s PV."%n(a.max_hp*.25),
		"matches":"Todos; fogo %s/s por 5 s."%n(8+int(ranks[0])*2),
		"peter":"Sem dano inicial; escudo de %s PV e 3 chamas que retaliam por %s dano cada."%[n(a.max_hp*.3),n(d)],
		"aladin":"Todos; cura e escudo coletivos de 15% dos PV máximos.",
		"rapunzel":"Cura coletiva de 35% e escudo coletivo de 20% dos PV máximos de cada aliado."}
	return "%s dano bruto. %s" % [n(d*factor),extras[a.id]]
static func conditions(a: Dictionary) -> String:
	var lines: Array[String]=[]
	for kind in ["burn","poison"]:
		var amount: float=float(a.get("hostile_"+kind,0))
		var duration: float=float(a.get("hostile_dot_left",0))
		if amount>0 and duration>0: lines.append("%s: %.1f dano/s · %.1f s · até %.1f dano pendente"%["Fogo" if kind=="burn" else "Veneno",amount,duration,amount*duration])
	return "\n".join(lines)
static func sheet(a: Dictionary) -> String:
	var interval: float=maxf(1.5,a.interval*1.25)*(1.3 if int(a.get("hindered_rounds",0))>0 else 1.0)
	return TaleCatalog.hero_class_name(a.id)+" · "+str(TaleCatalog.CLASSES[a["class"]].rule)+"\n\n"+conditions(a)+("\n\n" if not conditions(a).is_empty() else "")+"PV %s / %s  ·  Escudo %s\nMana %d / 100  ·  +1,4/s e +%s por acerto\nAtaque %s  ·  Intervalo mínimo %.2f s em 1×\nArmadura %s  ·  Crítico %.0f%% (2× dano)\nEsquiva %.0f%%  ·  Cura por acerto %s PV\n\n%s — AUTOMÁTICA\n%s\n\n%s — PASSIVA (recarga 6 s)\n%s\n\n%s — ULT (100 mana)\n%s\n\nValores atuais com os buffs desta run. Dano bruto antes de armadura, guarda e esquiva. A fila de animações pode adiar o próximo ataque." % [n(a.hp),n(a.max_hp),n(a.shield),int(a.energy),n(18+a.energy_bonus),n(a.damage),interval,n(a.armor),a.crit*100,float(a.get("evasion",0))*100,n(a.leech),Content.KITS[a.id][0],active(a),Content.KITS[a.id][2],passive(a),TaleCatalog.HERO_TACTICS[a.id].ult,ultimate(a)]
