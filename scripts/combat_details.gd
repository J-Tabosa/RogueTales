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
		"alice": return "Ao receber dano: escudo de 8% dos PV máximos. Cada ataque avança um naipe e carrega uma das quatro cartas da ULT."
		"puss": return "Intercepta golpe dirigido a outro aliado abaixo de 45%% dos PV; recebe 75%% do dano.%s" % [" Uma vez por combate: revive com 30% dos PV." if has(a,"nine") else ""]
		"matches": return "Morte de alvo incendiado: espalha fogo por 5 s (mínimo %s/s) e causa %s dano imediato.%s" % [n(d*.12),n(d*(.6 if has(a,"fuel") else .3))," +25 mana." if has(a,"ash") else ""]
		"peter": return "Esquiva: contra-ataca por %s dano e cria %d sombra(s), até 3." % [n(d*.6),2 if has(a,"double") else 1]
		"aladin": return "Escudo de aliado se rompe: +12 mana para todos.%s" % [" Concede escudo coletivo de 8% dos PV." if has(a,"reserve") else ""]
	return ""
static func ultimate(a: Dictionary) -> String:
	var d:float=a.damage
	match str(a.id):
		"scarlet":return "%s dano em todos os inimigos; bombas em arco + fogo de %s/s por 4 s."%[n(d*2.2),n(d*.12)]
		"ariel":return "Cavalga uma onda gigante até todos os inimigos: %s dano em cada alvo."%n(d*2)
		"aladin":return "Sem dano. Nuvem roxa: 50% de chance por inimigo de fazê-lo dormir e perder seu próximo turno."
		"joao":return "Dash e seis estocadas de %s dano bruto em um alvo (%s total)."%[n(d*.7),n(d*4.2)]
		"maria":return "Sem dano. Amaldiçoa todos os inimigos por 8 s: −20% armadura e −20% dano de ataques."
		"peter":return "Invoca um espírito, até três acumulados. Cada ataque recebido consome um espírito, anula o golpe inteiro e devolve o dano ao agressor."
		"mulan":return "Gira e lança cortes horizontais contra a frente inimiga: %s dano por alvo."%n(d*3.2)
		"snow_white":return "Carrega a picareta e esmaga um único alvo: %s dano bruto (800%% do ataque)."%n(d*8)
		"rapunzel":return "Raízes de cabelo protegem a própria Rapunzel e até dois aliados mais feridos. Escudo de 30% dos PV máximos de cada um; sem cura."
		"alice":return "Sem mana. Após quatro ataques e quatro trocas de naipe, lança automaticamente o cortejo: %s dano nos inimigos da mesma linha horizontal do alvo."%n(d*2.2)
		"matches":return "Fogo em órbita vira um dragão até o centro inimigo: %s dano em todos + %s fogo/s por 6 s."%[n(d*2),n(d*.25)]
	return "%s dano nos inimigos da frente; escudo próprio de %s PV."%[n(d*3.6),n(a.max_hp*.25)]
static func conditions(a: Dictionary) -> String:
	var lines:Array[String]=[]
	var statuses:=preload("res://scripts/status_art.gd").active(a,false)
	for kind in statuses:
		lines.append(preload("res://scripts/status_art.gd").description(kind,statuses[kind][0],statuses[kind][1]))
	return "\n".join(lines)

static func sheet(a: Dictionary) -> String:
	var interval: float=maxf(1.5,a.interval*1.25)*(1.3 if int(a.get("hindered_rounds",0))>0 else 1.0)
	var text:String = TaleCatalog.hero_class_name(a.id)+" · "+str(TaleCatalog.CLASSES[a["class"]].rule)+"\n\n"+conditions(a)+("\n\n" if not conditions(a).is_empty() else "")+"PV %s / %s  ·  Escudo %s\nMana %d / 100  ·  +1,4/s e +%s por acerto\nAtaque %s  ·  Intervalo mínimo %.2f s em 1×\nArmadura %s  ·  Crítico %.0f%% (2× dano)\nEsquiva %.0f%%  ·  Cura por acerto %s PV\n\n%s — AUTOMÁTICA\n%s\n\n%s — PASSIVA (recarga 6 s)\n%s\n\n%s — ULT (100 mana)\n%s\n\nValores atuais com os buffs desta run. Dano bruto antes de armadura, guarda e esquiva. A fila de animações pode adiar o próximo ataque." % [n(a.hp),n(a.max_hp),n(a.shield),int(a.energy),n(18+a.energy_bonus),n(a.damage),interval,n(a.armor),a.crit*100,float(a.get("evasion",0))*100,n(a.leech),Content.KITS[a.id][0],active(a),Content.KITS[a.id][2],passive(a),TaleCatalog.HERO_TACTICS[a.id].ult,ultimate(a)]

	if a.id=="alice":
		var begin:=text.find("Mana ")
		var end:=text.find("\nAtaque ",begin)
		text=text.substr(0,begin)+"Cartas %d / 4 · +1 por ataque · sem mana"%int(a.get("card_charge",0))+text.substr(end)
		text=text.replace("ULT (100 mana)","ULT (4 ataques · automática)")
	return text
