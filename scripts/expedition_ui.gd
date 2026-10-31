extends "res://scripts/interface.gd"
## The run experience. Legacy chapter checkpoints can still be finished safely.
const Bonuses=preload("res://scripts/run_bonuses.gd")
const Content = preload("res://scripts/expedition_content.gd")
const Synergies = preload("res://scripts/team_synergies.gd")
const TeamEvents = preload("res://scripts/team_events.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const Blessings = preload("res://scripts/hero_blessings.gd")
const Equipment = preload("res://scripts/equipment.gd")
const EffectBadges = preload("res://scripts/effect_badges.gd")
const SealedBlessing = preload("res://scripts/sealed_blessing.gd")
var chosen_blessing := "blessing:scarlet:0"
var chosen_endless := false
var gallery_building := false
var gallery_size := Vector2.ZERO
var gallery_refresh := false
var gallery_scroll: ScrollContainer
var resolution_left := 0.0
var defeated_pending := false
var encounter_left := 0.0
var route_walk_left := 0.0


func is_expedition() -> bool:
	return run != null and run.expedition

func label(parent: Node, text: String, rect: Rect2, font_size := 18, color := Color("eeeae2")) -> Label:
	var node := super.label(parent, text, rect, font_size, color)
	BattleType.apply(node,font_size>=20)
	node.size=rect.size
	if color.get_luminance() < 0.55:
		node.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
		node.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
		node.add_theme_constant_override("outline_size",0)
	return node

func modal(title: String, subtitle: String) -> void:
	if is_instance_valid(gallery_scroll):gallery_scroll.set_process_input(false)
	super.modal(title, subtitle)
	overlay.z_index = 3000

func header(title: String, subtitle: String) -> void:
	label(page, "ROGUETALES", Rect2(24, 14, 220, 27), 15, GOLD)
	label(page, "%s memórias" % format_gold(campaign.gold), Rect2(244, 14, 202, 27), 13, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button(page, "", Rect2(464, 8, 52, 44), show_settings)
	icon(page, "settings", Rect2(480, 21, 20, 20))
	label(page, title, Rect2(24, 66, 492, 55), 30)
	label(page, subtitle, Rect2(24, 126, 492, 46), 15, MUTED)

func show_menu() -> void:
	state = "menu"
	paused = false
	farm_timer = -1
	clear_page()
	header("Toda run, um novo conto.", "Recorde: %d pontos · Conto %02d / 12 · Infinito %d" % [campaign.best_score, campaign.best_depth, campaign.best_endless])
	var art := panel(page, Rect2(24, 190, 492, 352))
	var id: String = campaign.party[0] if not campaign.party.is_empty() else "scarlet"
	var achievement_art=preload("res://scripts/achievement_art.gd")
	if achievement_art.HERO_IMAGES.has(id):
		UISkin.picture(art,achievement_art.HERO_IMAGES[id],Rect2(0,0,492,352))
	else:
		UISkin.picture(art, UISkin.FOREST, Rect2(0, 0, 492, 352), true).modulate = Color(0.8, 0.8, 0.9)
		gradient(art, Rect2(0, 0, 492, 352), Color("161c30", 0.15), Color("161c30", 0.95))
		portrait_fitted(art, id, Vector2(246, 319), 283)
	achievement_art.gold_frame(art,achievement_art.fitted_rect(achievement_art.HERO_IMAGES[id],Rect2(0,0,492,352)) if achievement_art.HERO_IMAGES.has(id) else Rect2(0,0,492,352))
	label(page, "Escolha. Arrisque. Recomece.", Rect2(24, 565, 492, 43), 26)
	label(page, "Um protagonista. Companheiros raros.\nHabilidades e bônus que mudam a cada tentativa.", Rect2(24, 620, 492, 66), 17, MUTED)
	var active := not campaign.checkpoint.is_empty()
	var detail := "A vida, a build e os encontros da sua tentativa estão salvos." if active else "4 estações · 8 mapas por run · 48 fases · vença a run para continuar no infinito"
	label(page, detail, Rect2(24, 704, 492, 48), 14, GOLD)
	button(page, "Retomar run  →" if active else "Nova run  →", Rect2(24, 772, 492, 62), resume_checkpoint if active else show_map, true)
	navigation("menu")

func continue_journey() -> void:
	if not campaign.checkpoint.is_empty(): resume_checkpoint()
	else: show_map()

func show_map() -> void:
	if campaign.unlocked.is_empty():
		show_heroes()
		return
	state = "expedition_setup"
	clear_page()
	header("Antes da primeira página", "Escolha o protagonista e a bênção desta run.")
	if not campaign.checkpoint.is_empty():
		label(page, "Uma tentativa em andamento", Rect2(24, 219, 492, 48), 25, GOLD)
		var phase := "Infinito · fase %d" % (int(campaign.checkpoint.get("rooms_cleared", 0)) + 1) if campaign.checkpoint.get("endless", false) else Content.location_label(campaign.checkpoint)
		label(page, phase + "\nRetome sua equipe e sua build, ou encerre a tentativa para começar outra.", Rect2(24, 287, 492, 124), 20)
		button(page, "Retomar run", Rect2(24, 487, 492, 64), resume_checkpoint, true)
		button(page, "Encerrar tentativa", Rect2(24, 570, 492, 56), request_abandon)
		navigation("map")
		return
	if not campaign.unlocked.has(selected_hero): selected_hero = campaign.unlocked[0]
	if Blessings.data(chosen_blessing).get("hero","")!=selected_hero or not Blessings.unlocked(campaign,chosen_blessing):chosen_blessing=Blessings.id_for(selected_hero,0)
	chosen_endless = false
	label(page, "CONTO · 4 ESTAÇÕES · 8 MAPAS → INFINITO", Rect2(24, 183, 492, 46), 14, GOLD)
	var hero := button(page, "", Rect2(24, 246, 492, 118), show_heroes)
	if preload("res://scripts/achievement_art.gd").HERO_IMAGES.has(selected_hero):
		UISkin.picture(hero,preload("res://scripts/achievement_art.gd").HERO_IMAGES[selected_hero],Rect2(14,14,90,90))
	else:face_portrait(hero, selected_hero, Rect2(14, 14, 90, 90))
	preload("res://scripts/achievement_art.gd").gold_frame(hero,preload("res://scripts/achievement_art.gd").fitted_rect(preload("res://scripts/achievement_art.gd").HERO_IMAGES[selected_hero],Rect2(14,14,90,90)) if preload("res://scripts/achievement_art.gd").HERO_IMAGES.has(selected_hero) else Rect2(14,14,90,90))
	label(hero, "Selecionar Personagem", Rect2(123, 11, 350, 21), 10, GOLD)
	label(hero, TaleCatalog.HEROES[selected_hero].name, Rect2(123, 38, 350, 35), 22)
	label(hero, "%s · trocar →" % TaleCatalog.hero_class_name(selected_hero), Rect2(123, 81, 350, 26), 14, MUTED)
	var inner := scroll_area(381,321,4*140)
	inner.get_parent().name="BlessingList"
	for i in 4:
		var key:=Blessings.id_for(selected_hero,i)
		var data:=Blessings.data(key)
		var owned:=Blessings.unlocked(campaign,key)
		var card:=button(inner,"",Rect2(0,i*140,476,130),choose_blessing.bind(key),chosen_blessing==key and owned)
		card.set_meta("blessing_id",key)
		card.set_meta("locked",not owned)
		if owned:
			label(card,data.title,Rect2(20,12,416,30),20,GOLD)
			label(card,data.detail,Rect2(20,48,416,40),14,Color("cad5c1"))
			label(card,"SELECIONADA" if chosen_blessing==key else "TOQUE PARA ESCOLHER",Rect2(20,97,416,20),10,Color("8fba9d"))
		else:
			for child in card.get_children():child.queue_free()
			card.disabled=true
			var seal:=Control.new()
			seal.set_script(SealedBlessing)
			seal.size=card.size
			seal.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(seal)
			icon(card,"lock",Rect2(218,25,40,40),Color("c5b27e"))
			var condition:=label(card,blessing_condition(key),Rect2(48,74,380,38),14,Color("c7c2b2"))
			condition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

	var note:=label(page, "Memórias e desbloqueios permanecem entre expedições.", Rect2(24, 722, 492, 44), 13, MUTED)
	register_layout(note,"bottom")
	button(page, "Iniciar run DEBUG  →" if debug_session else "Iniciar expedição  →", Rect2(24, 798, 492, 60), begin_expedition, true)
	navigation("map")

func choose_blessing(id: String) -> void:
	if not Blessings.unlocked(campaign,id):
		modal("Bênção pessoal bloqueada",blessing_condition(id))
		button(overlay,"Voltar",Rect2(32,680,476,56),show_map,true)
		return
	chosen_blessing=id
	show_map()

func blessing_condition(id: String) -> String:
	return "Desbloqueia: "+Blessings.mission(campaign,id)

func set_run_mode(infinite: bool) -> void:
	if not campaign.checkpoint.is_empty(): return
	chosen_endless = false # Endless is offered only after this run is won.
	show_map()

func begin_expedition() -> void:
	if not campaign.checkpoint.is_empty(): return
	run = IdleRun.new()
	if not run.start_expedition(campaign, selected_hero, chosen_blessing, chosen_endless): return
	campaign.pending_story = -1
	campaign.auto_repeat = false
	if debug_session:
		run.party_capacity=Content.MAX_PARTY
		for hero in debug_party:
			if run.actor_ids().has(hero) or run.actors.size()>=Content.MAX_PARTY:continue
			var a:=run.run_actor(hero)
			run.actors.append(a)
			run.tactics.configure_actor(a,a.row)
		run.tactics.ensure_front()
		run.run_gold=5000
		for item in Equipment.ITEMS:run.grant_item(item)
		for hero in Equipment.TROPHIES:run.grant_item("trophy_"+str(hero))
		run.interlude="route"
		run.route_offers.assign(["battle"])
		show_routes()
	else:
		persist_run()
		show_loading(enter_encounter,0)

func persist_run() -> void:
	campaign.checkpoint = run.to_checkpoint()
	campaign.record_achievement_state(campaign.checkpoint)
	if run.expedition:Blessings.record(campaign,campaign.checkpoint)
	persist()

func enter_encounter() -> void:
	if is_expedition():campaign.record_achievement_state(run.to_checkpoint())
	if is_expedition() and run.needs_map():
		run.roll_routes()
		run.interlude="route"
		show_routes()
		return
	if is_expedition() and run.active_secret.is_empty() and Content.is_market(run.phase):
		if run.route_offers.is_empty():run.roll_routes()
		run.interlude="route"
		show_routes()
		return
	build_battle()
	begin_travel()

func build_battle() -> void:
	super.build_battle()
	if not is_expedition(): return
	feedback = Control.new()
	feedback.set_script(preload("res://scripts/combat_feedback.gd"))
	feedback.reduced_motion = campaign.reduced_motion
	battle_viewport.add_child(feedback)
	arena.feedback = feedback
	auto_button.add_theme_font_size_override("font_size", 15)
	auto_button.set_meta("mobile_rect", Rect2(16, 0, 246, 46))
	auto_button.set_meta("pc_rect", Rect2(1018, 694, 248, 44))
	speed_button.set_meta("mobile_rect", Rect2(278, 0, 246, 46))
	relayout_battle()

func begin_travel() -> void:
	super.begin_travel()
	if is_expedition():
		current_action("%s · a equipe segue pela trilha" % run.phase_label())

func spawn_enemy() -> void:
	super.spawn_enemy()
	if not is_expedition(): return
	state = "encounter_intro"
	encounter_left = 1.15
	current_action("CHEFE SECRETO · "+str(preload("res://scripts/secret_encounters.gd").DATA[run.active_secret].name) if not run.active_secret.is_empty() else ("CHEFE À VISTA" if Content.is_boss(run.stage, run.phase) else "ENCONTRO · prepare-se!"))
	arena.damage_number("DESAFIO SECRETO" if not run.active_secret.is_empty() else ("CHEFE À VISTA" if Content.is_boss(run.stage, run.phase) else "INIMIGOS À VISTA"), Vector2(arena.field_width * 0.45, arena.field_height * 0.44), GOLD)

func _process(delta: float) -> void:
	if state == "route_travel" and not paused:
		route_walk_left -= delta * game_speed
		if route_walk_left <= 0: show_routes()
	if state == "encounter_intro" and not paused:
		encounter_left -= delta
		if encounter_left <= 0:
			state = "battle"
			current_action("Combate iniciado")
		update_hud()
	elif state == "battle_outro" and not paused:
		resolution_left -= delta
		if resolution_left <= 0:
			if defeated_pending: finish_defeat_now()
			else: finish_encounter_now()
	super._process(delta)


func restore_checkpoint_now() -> void:
	if campaign.checkpoint.is_empty() or not campaign.checkpoint.get("expedition", false):
		super.restore_checkpoint_now()
		return
	run = IdleRun.new()
	run.restore(campaign, campaign.checkpoint)
	if not run.alive():
		finish_defeat()
		return
	match run.interlude:
		"reward": show_relics()
		"route": show_routes()
		"shop": show_run_shop()
		"event": show_team_event()
		"secret_reward": show_secret_reward()
		_: enter_encounter()

func resolve_enemy() -> void:
	if not is_expedition():
		super.resolve_enemy()
		return
	if state != "battle" or arena.is_action_busy(): return
	if not run.alive():
		finish_defeat()
		return
	state = "battle_outro"
	resolution_left = 1.2
	defeated_pending = false
	current_action("VITÓRIA · encontro concluído")
	push_battle_log("Todos os inimigos foram derrotados")
	arena.set_animation("idle")
	update_hud()

func finish_encounter_now() -> void:
	if state != "battle_outro": return
	state = "resolving"
	campaign.total_kills += run.tactics.enemies.size()
	var secret_id:String=run.active_secret
	var was_boss:bool=secret_id.is_empty() and Content.is_boss(run.stage,run.phase)
	var finished: bool = run.clear_encounter()
	campaign.record_goal_combat(run.run_id,"secret:"+secret_id if not secret_id.is_empty() else "room:"+str(run.rooms_cleared),run.tactics.enemies.size(),was_boss,run.actors.size())
	campaign.best_score = maxi(campaign.best_score, run.score)
	if finished:
		var result := campaign.finish_expedition(run.to_checkpoint(), true)
		persist()
		show_run_result(result)
	else:
		persist_run()
		if run.interlude=="secret_reward": show_secret_reward()
		else: show_relics()

func show_relics() -> void:
	if not is_expedition():
		super.show_relics()
		return
	if not is_instance_valid(arena) or not battle_view:
		build_battle()
		arena.enemy_visible = false
	state = "choice"
	paused = true
	arena.frozen = true
	if is_instance_valid(feedback): feedback.frozen = true
	journey_modal("Encontro vencido", "+%d pontos · total %d · escolha uma melhoria." % [run.last_room_score, run.score])
	for index in run.offers.size():
		var id: String = run.offers[index]
		var offer := TaleCatalog.offer_data(id)
		var card := button(overlay, "", Rect2(32, 390 + index * 126, 476, 116), select_relic.bind(id))
		var title: String = offer.title
		var detail: String = run.upgrade_detail(id)
		var note := "BÔNUS LEGADO · ACÚMULO %d" % (run.upgrade_count(id) + 1)
		if offer.has("bonus"):
			note=offer.note
			bonus_skin(card,id)
		elif offer.has("item"):note="RELÍQUIA MÍTICA · +1 VAGA · LIMITE 5" if offer.get("consumable",false) else "EQUIPAMENTO · ESCOLHA O PORTADOR NO INVENTÁRIO"
		elif offer.has("owner"): note = "HABILIDADE · " + str(TaleCatalog.HEROES[offer.owner].name)
		elif offer.has("hero"):
			var owned := campaign.unlocked.has(offer.hero)
			title = str(TaleCatalog.HEROES[offer.hero].name) if owned else "Um viajante desconhecido"
			detail = "%s · junta-se à equipe nesta run." % TaleCatalog.hero_class_name(offer.hero)
			note = "COMPANHEIRO · 25% POR RECOMPENSA"
		label(card, note, Rect2(14, 7, 448, 19), 10, GOLD)
		label(card, title, Rect2(14, 29, 448, 30), 20)
		label(card, detail, Rect2(14, 65, 448, 44), 14, MUTED)
	button(overlay, "Salvar e sair", Rect2(32, 798, 476, 48), leave_battle)

func select_relic(id: String, replace_index: int = -1) -> void:
	if not is_expedition():
		super.select_relic(id, replace_index)
		return
	if state != "choice" or not run.offers.has(id): return
	var offer := TaleCatalog.offer_data(id)
	if offer.is_empty(): return
	if offer.has("bonus"):
		show_bonus_selection(id)
		return
	if offer.has("hero") and not run.can_recruit(offer.hero) and replace_index < 0:
		show_recruit_replacement(id)
		return
	var applied: bool = run.recruit(campaign, offer.hero, replace_index) if offer.has("hero") else run.apply_relic(id)
	if not applied: return
	persist_run()
	walk_to_routes()

func show_routes() -> void:
	if not is_instance_valid(arena) or not battle_view:
		build_battle()
		arena.enemy_visible = false
	state = "route"
	paused = true
	arena.walking = false
	arena.set_animation("idle")
	arena.frozen = true
	if is_instance_valid(feedback): feedback.frozen = true
	journey_modal("Fase %d-5 · Mercador ou Negociante"%[run.stage+1] if Content.is_market(run.phase) else "A próxima página", "%s · %d ouro · escolha o próximo caminho." % [run.phase_label(), run.run_gold])
	if run.needs_map():
		show_map_choices()
	elif Content.is_boss(run.stage, run.phase):
		label(overlay, run.boss_name(), Rect2(32, 390, 476, 75), 28, GOLD)
		label(overlay, BossRules.DESCRIPTIONS[run.current_boss_rule()], Rect2(32, 482, 476, 132), 18, MUTED)
		button(overlay, "Enfrentar o chefe  →", Rect2(32, 624, 476, 50), select_route.bind("battle"), true)
	else:
		for index in run.route_offers.size():
			var key: String = run.route_offers[index]
			var data: Dictionary = Content.ROUTES[key]
			var card := button(overlay, "", Rect2(32, 390 + index * 116, 476, 106), select_route.bind(key))
			label(card, data.title, Rect2(14, 9, 448, 33), 21, GOLD)
			label(card, data.detail, Rect2(14, 48, 448, 50), 14, MUTED)
	button(overlay,"Itens · %d"%run.inventory.size(),Rect2(32,682,230,48),show_equipment.bind(0))
	button(overlay,"Equipe · %d/%d"%[run.actors.size(),run.party_capacity],Rect2(278,682,230,48),show_run_build)
	button(overlay, "Ver build", Rect2(32, 758, 230, 48), show_run_build)
	button(overlay, "Salvar e sair", Rect2(278, 758, 230, 48), leave_battle)
	wishes_button()


func show_recruit_replacement(id: String) -> void:
	if not is_expedition():
		super.show_recruit_replacement(id)
		return
	state = "replacement"
	var offer := TaleCatalog.offer_data(id)
	journey_modal("Quem abre espaço?", "%s · capacidade %d/%d. Cada posição comporta até 3 viajantes." % [TaleCatalog.HEROES[offer.hero].name, run.actors.size(), run.party_capacity])
	var scroll := ScrollContainer.new()
	scroll.name = "RecruitReplacementScroll"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.position = Vector2(32, 390)
	scroll.size = Vector2(476, 354)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	register_layout(scroll, "center")
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(460, run.actors.size() * 96)
	scroll.add_child(inner)
	for index in run.actors.size():
		var actor: Dictionary = run.actors[index]
		var card := button(inner, "Substituir %s\n%d / %d PV" % [TaleCatalog.HEROES[actor.id].name, actor.hp, actor.max_hp], Rect2(0, index * 96, 460, 86), confirm_replacement.bind(id, index))
		card.disabled = not run.can_recruit(offer.hero, index)
	button(overlay, "Voltar às opções", Rect2(32, 778, 476, 52), show_relics)

func walk_to_routes() -> void:
	build_battle()
	begin_travel()
	state = "route_travel"
	route_walk_left = 2.3
	current_action("A equipe avança até a próxima encruzilhada…")

func select_route(id: String) -> void:
	if state != "route" or not run.choose_route(id): return
	paused = false
	persist_run()
	if id.begins_with("map:"):
		build_battle()
		arena.enemy_visible=false
		show_routes()
	elif run.interlude == "shop": show_run_shop()
	elif run.interlude == "event": show_team_event()
	else: enter_encounter()

func show_run_shop() -> void:
	state="shop"
	clear_page()
	header("Negociante de contos" if run.merchant_kind=="trader" else "Mercador de histórias","%s ouro   ·   Equipe %d/%d"%[format_gold(run.run_gold),run.actors.size(),run.party_capacity])
	var keys:Array[String]=[]
	keys.append_array(run.shop_stock)
	var inner:=scroll_area(225,513,keys.size()*150)
	inner.get_parent().name="ShopList"
	for index in keys.size():
		var key:String=keys[index]
		var data:=supply_data(key)
		var cost:int=run.supply_cost(key)
		var bought:bool=run.shop_bought.has(key)
		var card:=button(inner,"",Rect2(0,index*150,476,140),buy_run_supply.bind(key))
		card.set_meta("shop_item",key)
		var capped:bool=key=="item:travelers_page" and run.party_capacity>=Content.MAX_PARTY
		card.disabled=bought or cost<0 or run.run_gold<cost or capped
		for child in card.get_children():child.queue_free()
		for skin in ["normal","disabled"]:card.add_theme_stylebox_override(skin,box(Color("142f27"),Color("486047"),12))
		if key.begins_with("item:"):
			ItemArt.picture(card,key.trim_prefix("item:"),Rect2(12,20,82,82))
		else:
			icon(card,EffectBadges.symbol(key),Rect2(28,35,48,48),GOLD)
		if key.begins_with("bonus:"):
			bonus_skin(card,key,false)
			label(card,data.note,Rect2(108,59,340,18),11,Bonuses.tint(key))
		var title:=label(card,data.title,Rect2(108,12,306,42),19,GOLD)
		title.set_meta("shop_title",true)
		effect_badges(card,EffectBadges.for_supply(key,run.party_capacity),Vector2(108,80 if key.begins_with("bonus:") else 61),340)
		label(card,"EQUIPE COMPLETA" if cost<0 or capped else "COMPRADO" if bought else "%d OURO"%cost,Rect2(108,110,296,21),12,Color("92b99d") if bought else GOLD)
		var info:=button(card,"i",Rect2(422,90,42,40),show_supply_details.bind(key))
		info.tooltip_text="Ver todos os efeitos"
	var inventory:=button(page,"Equipar itens · %d na bolsa"%run.inventory.size(),Rect2(24,752,492,48),show_equipment.bind(0))
	register_layout(inventory,"bottom")
	button(page,"Seguir viagem →",Rect2(24,818,316,56),leave_run_shop,true)
	button(page,"Salvar e sair",Rect2(356,818,160,56),leave_battle)
	wishes_button()


func supply_data(key: String) -> Dictionary:
	if key=="capacity":return {"title":"Expandir equipe","detail":"Capacidade %d → %d. Até 5 no total, com no máximo 3 personagens por posição."%[run.party_capacity,mini(Content.MAX_PARTY,run.party_capacity+1)]}
	if key=="potion":return {"title":"Frasco de recomeço","detail":"Cura 35% dos PV de todos os aliados e levanta um aliado com 20% dos PV."}
	return TaleCatalog.offer_data(key)

func effect_badges(parent: Node, entries: Array, at: Vector2, available: float) -> void:
	var x:=at.x
	for entry in entries:
		var width:=BattleType.font().get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+34
		if x+width>at.x+available:break
		var badge:=Panel.new()
		badge.position=Vector2(x,at.y)
		badge.size=Vector2(width,30)
		badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		badge.set_meta("effect_badge",entry.glyph)
		badge.add_theme_stylebox_override("panel",box(Color("0b231e"),Color("3e5947"),6))
		parent.add_child(badge)
		icon(badge,entry.glyph,Rect2(6,6,18,18),Color(entry.get("color","e2c487")))
		label(badge,entry.text,Rect2(29,2,width-33,26),12,Color("cbd6bf"))
		x+=width+7

func show_supply_details(key: String) -> void:
	var data:=supply_data(key)
	if key.begins_with("bonus:"):
		show_bonus_selection(key,"shop")
		return
	modal(data.title,"SUPRIMENTO" if key in ["capacity","potion"] else "EQUIPAMENTO" if key.begins_with("item:") else "BÔNUS LEGADO")
	if key.begins_with("item:"):ItemArt.picture(overlay,key.trim_prefix("item:"),Rect2(180,388,180,160))
	else:icon(overlay,EffectBadges.symbol(key),Rect2(230,410,80,80))
	label(overlay,data.detail,Rect2(40,564,460,120),18)
	button(overlay,"Voltar ao mercador",Rect2(32,740,476,56),show_run_shop,true)

func buy_run_supply(id: String) -> void:
	if state=="shop" and id.begins_with("bonus:"):
		show_bonus_selection(id,"shop")
		return
	if state == "shop" and run.buy_supply(id):
		persist_run()
		show_run_shop()

func leave_run_shop() -> void:
	if state != "shop": return
	run.leave_shop()
	persist_run()
	enter_encounter()

func show_team_event() -> void:
	if not TeamEvents.has_event(run.pending_event): return
	state = "team_event"
	clear_page()
	var event: Dictionary = TeamEvents.event(run.pending_event)
	header(event.title, "%s · sua companhia muda esta página." % run.phase_label())
	for node in page.get_children():
		if node is Label and node.text == event.title: node.add_theme_font_size_override("font_size", 25)
	var lines := TeamEvents.dialogue(run, run.pending_event)
	for index in lines.size():
		var data: Dictionary = lines[index]
		var speaker: String = data.speaker
		var tint := GOLD if speaker == "narrator" else Color(TaleCatalog.HEROES[speaker].color)
		var y := 184 + index * 88.0
		panel(page, Rect2(24, y, 492, 81))
		label(page, "Narradora" if speaker == "narrator" else str(TaleCatalog.HEROES[speaker].name), Rect2(38, y + 4, 464, 21), 12, tint)
		label(page, data.text, Rect2(38, y + 29, 464, 48), 15)
	var can_pair := TeamEvents.can_pair(run, run.pending_event)
	var options := [["supplies", "Recolher os suprimentos", "+30 ouro nesta run."], ["rest", "Ajudar e recuperar o fôlego", "Cure 25% dos PV e levante um aliado com 20%."], ["pair", event.choice if can_pair else "Uma companhia diferente pode ajudar", event.reward if can_pair else "Esta opção exige dois viajantes específicos vivos na equipe."]]
	var secret := run.pending_event.begins_with("secret_")
	if secret:
		options=[["challenge","Aceitar o duelo secreto",event.reward+" Só nesta run. Inimigo único com poder de 2 mundos à frente."],["leave","Seguir pela trilha","Deixe o desafio para outra ocasião. Nenhuma penalidade."]]
	for index in options.size():
		var option: Array = options[index]
		var card := button(page, "", Rect2(24, 468 + index * 117, 492, 106), select_team_event.bind(str(option[0])))
		card.disabled = index == 2 and not can_pair
		label(card, option[1], Rect2(14, 5, 464, 31), 18, GOLD if index == 2 and can_pair else Color("e6e5df"))
		label(card, option[2], Rect2(14, 42, 464, 57), 14, MUTED)
	button(page, "Salvar e sair", Rect2(24, 842, 492, 52), leave_battle)

func select_team_event(choice: String) -> void:
	if state != "team_event" or not TeamEvents.resolve(run, choice): return
	persist_run()
	enter_encounter()

func show_enemy_intents(_selected: int = -1) -> void:
	show_battle_history()

func show_run_build() -> void:
	state = "build"
	clear_page()
	header("O conto até aqui", "%s · %d ouro · %d melhorias" % [run.phase_label(), run.run_gold, run.upgrade_total()])
	var pairs := Synergies.available(run)
	var entries: Array[Dictionary]=[]
	var total_height := 360.0+run.relics.size()*83+run.bonus_history.size()*120+pairs.size()*139
	for actor in run.actors:
		var description:=preload("res://scripts/combat_details.gd").sheet(actor)
		var text_height:=get_theme_font("font").get_multiline_string_size(description,HORIZONTAL_ALIGNMENT_LEFT,476,14).y+24
		entries.append({"actor":actor,"description":description,"height":text_height})
		total_height+=text_height+115
	var inner := scroll_area(225,558,total_height)
	label(inner, "BÊNÇÃO · " + str(Blessings.data(run.blessing).get("title",Content.BLESSINGS.get(run.blessing,{}).get("name","Bênção"))), Rect2(0, 0, 476, 42), 18, GOLD)
	var y := 63.0
	if not run.inactive_companions.is_empty():
		label(inner,"Equipe antiga ajustada ao limite de 5. Equipamentos dos viajantes inativos estão disponíveis na bolsa.",Rect2(0,y,476,70),14,GOLD)
		y+=85
	for key in pairs:
		var pair: Dictionary = Synergies.PAIRS[key]
		label(inner, "SINERGIA · " + str(pair.name), Rect2(0, y, 476, 32), 20, GOLD)
		label(inner, pair.detail, Rect2(0, y + 41, 476, 79), 15, MUTED)
		y += 139
	for entry in entries:
		var actor: Dictionary=entry.actor
		face_portrait(inner, actor.id, Rect2(0, y, 70, 74))
		label(inner, TaleCatalog.HEROES[actor.id].name, Rect2(88, y, 388, 32), 21)
		label(inner, entry.description, Rect2(0, y + 86, 476, entry.height), 14, MUTED)
		y += entry.height+115
	for entry in run.bonus_history:
		var data:=Bonuses.describe(entry.id)
		var card:=panel(inner,Rect2(0,y,476,110))
		bonus_skin(card,entry.id,false)
		var recipient:String="Equipe e futuros recrutados" if entry.mode=="group" else str(TaleCatalog.HEROES.get(entry.target,{}).get("name",entry.target))
		label(card,data.note,Rect2(12,6,452,20),11,Bonuses.tint(entry.id))
		label(card,data.title,Rect2(12,31,452,31),19)
		label(card,recipient+(" · Agir depois" if entry.attribute=="initiative" and int(entry.sign)<0 else " · Agir antes" if entry.attribute=="initiative" else ""),Rect2(12,70,452,30),13,Color("e1e4dc"))
		y+=120
	if not run.relics.is_empty():
		label(inner,"BÔNUS LEGADOS · efeitos originais preservados",Rect2(0,y,476,40),13,GOLD)
		y+=45
	for key in run.relics:
		var data := TaleCatalog.offer_data(key)
		label(inner, str(data.title) + (" ×%d" % run.upgrade_count(key) if run.endless else ""), Rect2(0, y, 476, 29), 19, GOLD)
		label(inner, data.detail, Rect2(0, y + 31, 476, 47), 13, MUTED)
		y += 83
	button(page, "Voltar ao caminho", Rect2(24, 814, 492, 56), show_routes, true)
	wishes_button()


func finish_defeat() -> void:
	if not is_expedition():
		super.finish_defeat()
		return
	if state in ["battle_outro", "result", "defeat"]: return
	if is_instance_valid(arena) and arena.is_action_busy(): return
	if not is_instance_valid(arena) or not battle_view:
		finish_defeat_now()
		return
	state = "battle_outro"
	resolution_left = 1.2
	defeated_pending = true
	current_action("A equipe caiu…")
	push_battle_log("Fim do encontro · equipe derrotada")

func finish_defeat_now() -> void:
	if not is_expedition():
		super.finish_defeat()
		return
	if state in ["result", "defeat"]: return
	var result := campaign.finish_expedition(run.to_checkpoint(), false)
	persist()
	show_run_result(result)

func show_run_result(result: Dictionary) -> void:
	state = "result"
	paused = false
	farm_timer = -1
	clear_page()
	var won := bool(result.get("won", false))
	audio.play_effect("win" if won else "loss")
	header("O final é seu." if won else "Uma página se fecha.", "RUN CONCLUÍDA" if won else "FIM DA TENTATIVA · NOVO COMEÇO")
	portrait_fitted(page, run.leader, Vector2(270, 479), 273)
	label(page, "%d páginas · infinito" % result.get("depth", 0) if result.get("endless", false) else "%02d / 72 fases vencidas" % result.get("depth", 0), Rect2(24, 513, 492, 54), 30, GOLD)
	var record := "recorde infinito: %d" % campaign.best_endless if result.get("endless", false) else "recorde %02d / 12" % campaign.best_depth
	label(page, "%d PONTOS · RECORDE %d\n+%d memórias · %s" % [run.score, campaign.best_score, result.get("reward", 0), record], Rect2(24, 585, 492, 89), 17, MUTED)
	var unlocked_now: Array = result.get("unlocks", [])
	label(page, "Novo protagonista: " + hero_names(unlocked_now) if not unlocked_now.is_empty() else "Seus feitos e desbloqueios foram salvos.", Rect2(24, 700, 492, 63), 19, GOLD)
	if won and not run.endless:
		button(page, "Continuar no infinito  →", Rect2(24, 775, 492, 54), continue_into_endless, true)
		button(page, "Encerrar e voltar", Rect2(24, 838, 492, 44), show_menu)
	else:
		button(page, "Começar outra run  →", Rect2(24, 790, 492, 62), show_map, true)
	navigation("menu")

func request_abandon() -> void:
	if campaign.checkpoint.get("expedition", false):
		modal("Encerrar esta tentativa?", "A equipe temporária, a build e o ouro desta run serão perdidos. Seus feitos, memórias e personagens desbloqueados permanecem.")
		button(overlay, "Encerrar e voltar", Rect2(32, 524, 476, 60), abandon_expedition, true)
		button(overlay, "Cancelar", Rect2(32, 607, 476, 56), cancel_run_abandon)
	else: super.request_abandon()

func cancel_run_abandon() -> void:
	if state in ["battle", "travel"]:
		resume_battle()
		if is_instance_valid(overlay): overlay.queue_free()
	else: show_map()

func abandon_expedition() -> void:
	if campaign.checkpoint.get("expedition", false):
		var data: Dictionary = run.to_checkpoint() if is_expedition() else campaign.checkpoint
		campaign.finish_expedition(data, false)
		persist()
		run = null
		paused = false
		show_menu()
	else: super.abandon_expedition()

func update_hud() -> void:
	super.update_hud()
	if is_expedition() and battle_view and is_instance_valid(enemy_label):
		enemy_label.text = "%s · %s · %d OURO" % [run.phase_label(), "PRESSÃO +%d%%" % int((run.tactics.pressure() - 1) * 100) if run.tactics.pressure() > 1 else ("CHEFE" if Content.is_boss(run.stage, run.phase) else ("ELITE" if run.room_kind == "elite" else "COMBATE")), run.run_gold]
		if not run.active_secret.is_empty(): enemy_label.text=run.phase_label()+" · SECRETO · "+str(preload("res://scripts/secret_encounters.gd").DATA[run.active_secret].name)
		power_label.text = ""
		if is_instance_valid(battle_gold):battle_gold.text="%s OURO"%format_gold(run.run_gold)
		stage_label.text = ("INFINITO · FASE %d · %s"%[run.rooms_cleared+1,run.map_name()]) if run.endless else "ESTÁGIO %02d · FASE %d/6 · %s" % [run.stage+1,run.phase+1,run.map_name()]
		if debug_session:stage_label.text="DEBUG · "+stage_label.text
		BattleType.fit_line(stage_label,20 if desktop else 14)
		BattleType.fit_line(battle_gold,15)
		for i in mini(ult_buttons.size(), run.actors.size()):
			var actor: Dictionary = run.actors[i]
			ult_buttons[i].tooltip_text = ("HABILIDADE SELADA · destrua seu fio para libertá-la.\n\n" if actor.get("sealed", false) else "") + "%s (automática)\n%s\n\n%s (passiva · 6 s)\n%s\n\nULT: %s" % [Content.KITS[actor.id][0], Content.KITS[actor.id][1], Content.KITS[actor.id][2], Content.KITS[actor.id][3], TaleCatalog.HERO_TACTICS[actor.id].ult]

func navigation(active: String) -> void:
	panel(page, Rect2(16, 882, 508, 68))
	var entries := [["menu", "Início", "home", show_menu], ["map", "Run", "map", show_map], ["heroes", "Heróis", "heroes", show_heroes], ["journal", "Diário", "book", show_journal], ["profile", "Perfil", "profile", show_profile]]
	for i in entries.size():
		var entry: Array = entries[i]
		var item := button(page, "", Rect2(22 + i * 100, 887, 96, 58), entry[3],active == entry[0])
		icon(item, entry[2], Rect2(37, 6, 22, 22), GOLD if active == entry[0] else MUTED)
		label(item, entry[1], Rect2(0, 32, 96, 22), 11, GOLD if active == entry[0] else MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func center_content(usable_override: Rect2 = Rect2()) -> void:
	if content == null: return
	if state == "heroes" and size.x / maxf(1, size.y) >= 1.28:
		desktop = true
		logical_width = 1280
		logical_height = 800
		var factor := minf(size.x / logical_width, size.y / logical_height)
		content.size = Vector2(logical_width, logical_height)
		content.scale = Vector2.ONE * factor
		content.position = (size - content.size * factor) * 0.5
		if is_instance_valid(page):
			page.size = content.size
			page.get_child(0).size = page.size
		if is_instance_valid(desktop_shell): desktop_shell.queue_free()
	else: super.center_content(usable_override)
	if state == "heroes" and not gallery_building and gallery_size != Vector2(logical_width, logical_height) and not gallery_refresh:
		gallery_refresh = true
		call_deferred("refresh_gallery")

func refresh_gallery() -> void:
	gallery_refresh = false
	if state == "heroes": show_heroes()

func show_heroes() -> void:
	gallery_building = true
	state = "heroes"
	clear_page()
	page.size = Vector2(logical_width, logical_height)
	page.get_child(0).size = page.size
	gradient(page, Rect2(0, 0, logical_width, logical_height), Color("18392e"), Color("0c1c1a"))
	var w := logical_width
	label(page, "O LIVRO DOS VIAJANTES", Rect2(24, 20, w - 120, 28), 12, GOLD)
	label(page, "Heróis dos contos", Rect2(24, 57, w - 48, 54), 32)
	button(page, "Voltar", Rect2(w - 112, 23, 88, 44), show_menu)
	label(page, "DEBUG · 12 visíveis · progresso da coleção preservado." if debug_enabled and debug_roster_all else "%02d / 12 comprados · %s memórias" % [campaign.unlocked.size(),format_gold(campaign.gold)], Rect2(24, 115, w - 48, 35), 14, MUTED)
	button(page, "Todos", Rect2(24, 160, 154, 44), filter_roster.bind("all"), roster_filter == "all")
	button(page, "Revelados", Rect2(190, 160, 154, 44), filter_roster.bind("owned"), roster_filter == "owned")
	var ids: Array = TaleCatalog.HEROES.keys().filter(func(id): return roster_filter == "all" or hero_revealed(id))
	if not ids.has(selected_hero) and not ids.is_empty(): selected_hero = ids[0]
	gallery_scroll = ScrollContainer.new()
	gallery_scroll.set_script(preload("res://scripts/hero_carousel.gd"))
	var gallery_height:=456.0 if desktop else minf(620,logical_height-432)
	var card_width:=320.0 if desktop else 410.0
	var card_height:=gallery_height-16
	var pitch:=card_width+16
	gallery_scroll.position = Vector2(24, 220)
	gallery_scroll.size = Vector2(w - 48, gallery_height)
	gallery_scroll.set_meta("gallery_height",gallery_height)
	gallery_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	gallery_scroll.scroll_deadzone = 12
	page.add_child(gallery_scroll)
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(ids.size() * pitch-16, card_height)
	gallery_scroll.add_child(strip)
	for i in ids.size():
		var id: String = ids[i]
		var owned := hero_revealed(id)
		var selected := selected_hero == id
		var card := button(strip, "", Rect2(i * pitch, 0, card_width, card_height), select_gallery_hero.bind(id),selected)
		card.set_meta("hero_id", id)
		card.set_meta("silhouette", not owned)
		card.clip_contents = true
		card.add_theme_stylebox_override("normal", box(Color("092b22") if selected else Color("1c3d31"), GOLD if selected else Color("5b6e51"), 10))
		gradient(card, Rect2(8, 8, card_width-16, card_height-88), Color("42664c"), Color("122f27"))
		banner_portrait(card, id, Rect2(12, 24, card_width-24, card_height-114), not owned, true)
		label(card, "%02d" % (i + 1), Rect2(20, 14, card_width-40, 21), 11, GOLD)
		label(card, str(TaleCatalog.HEROES[id].get("short_name", TaleCatalog.HEROES[id].name)) if owned else str(TaleCatalog.HEROES[id].name), Rect2(16, card_height-76, card_width-32, 36), 24).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label(card, TaleCatalog.hero_class_name(id) if owned else "BLOQUEADO · 5.000 MEMÓRIAS", Rect2(16, card_height-36, card_width-32, 22), 12,Color("a7bea2")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var owned := hero_revealed(selected_hero)
	var note: String = "%s · %s\nAtiva: %s" % [TaleCatalog.HEROES[selected_hero].name, TaleCatalog.hero_class_name(selected_hero), Content.KITS[selected_hero][0]] if owned else "Compre este personagem por 5.000 memórias. A primeira conta recebe 5.000 para escolher seu primeiro viajante."
	var note_y:=220+gallery_height+12
	label(page, note, Rect2(24, note_y, w - 48, 54), 15, MUTED)
	var bottom := 734.0 if desktop else note_y+76
	var select_character := button(page,"Selecionar Personagem" if owned else "Comprar · 5.000 memórias",Rect2(24,bottom,w-48,62),show_hero_details.bind(selected_hero) if owned else show_unlock_details.bind(selected_hero),true)
	select_character.set_meta("select_character",true)
	select_character.add_theme_font_size_override("font_size",20)
	select_character.disabled=not campaign.checkpoint.is_empty()
	# Gallery coordinates already use the full current logical height.
	for child in page.get_children():
		if child is Control and child.has_meta("layout_kind"):
			child.set_meta("layout_kind","fixed")
			place_control(child)

	gallery_scroll.set_deferred("scroll_horizontal", int(maxf(0, ids.find(selected_hero) * pitch - (w - 48 - card_width) * 0.5)))
	gallery_size = Vector2(logical_width, logical_height)
	gallery_building = false

func banner_portrait(parent: Node, id: String, rect: Rect2, hidden: bool,standardized:=false) -> void:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var bounds: Rect2 = data.bounds
	var actor := Sprite2D.new()
	actor.name = "Silhouette" if hidden else "HeroArt"
	actor.texture = data.texture
	actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	actor.centered = false
	var body_scale := Vector2(preload("res://scripts/character_visuals.gd").width(id),1)
	var reference_height:float=rect.size.y*.98 if standardized else rect.size.y*.92
	var height:float=reference_height*preload("res://scripts/character_visuals.gd").height(id)
	height=minf(height,rect.size.x*bounds.size.y/maxf(1,bounds.size.x*body_scale.x))
	var factor:=height/maxf(1,bounds.size.y)
	actor.scale = body_scale * factor
	actor.position=rect.position+Vector2((rect.size.x-bounds.size.x*actor.scale.x)*.5,(rect.size.y-height) if standardized else (rect.size.y-height)*.5)-bounds.position*actor.scale
	if not hidden:preload("res://scripts/hero_art.gd").ink(actor,id,factor)
	actor.self_modulate = Color.BLACK if hidden else Color.WHITE
	actor.set_meta("portrait_rect",rect)
	actor.set_meta("visual_height",height)
	parent.add_child(actor)
	if parent == overlay:
		actor.set_meta("portrait_base", actor.position)
		actor.position.y += (logical_height - 960.0) * 0.5

func select_gallery_hero(id: String) -> void:
	selected_hero = id
	show_hero_details(id) if hero_revealed(id) else show_unlock_details(id)

func use_protagonist(id: String) -> void:
	if not campaign.unlocked.has(id) or not campaign.checkpoint.is_empty(): return
	selected_hero = id
	campaign.party.assign([id])
	campaign.ensure_front()
	persist()
	show_map()

func show_party() -> void:
	show_map()

func show_upgrades() -> void:
	show_hero_details(selected_hero if hero_revealed(selected_hero) else "scarlet")

func show_unlock_details(id: String) -> void:
	if hero_revealed(id):
		show_hero_details(id)
		return
	modal("Comprar "+str(TaleCatalog.HEROES[id].name),"%s · 5.000 memórias\nSaldo: %s memórias. Desbloqueio permanente para usar como protagonista."%[TaleCatalog.hero_class_name(id),format_gold(campaign.gold)])
	banner_portrait(overlay,id,Rect2(177,394,186,236),true)
	var buy:=button(overlay,"Comprar · 5.000 memórias",Rect2(32,650,476,56),buy_character.bind(id),true)
	buy.name="PurchaseHero"
	buy.disabled=campaign.gold<TaleCampaign.HERO_PRICE or not campaign.checkpoint.is_empty()
	button(overlay,"Voltar à coleção",Rect2(32,721,476,56),show_heroes)

func buy_character(id:String) -> void:
	if not campaign.buy_hero(id):return
	selected_hero=id
	persist()
	show_hero_details(id)

func show_hero_details(id: String) -> void:
	if not hero_revealed(id):
		show_unlock_details(id)
		return
	selected_hero = id
	state = "hero_details"
	clear_page()
	header(TaleCatalog.HEROES[id].name, "%s · uma ativa, uma reação e uma ULT própria." % TaleCatalog.hero_class_name(id))
	var inner := scroll_area(184, 605, 1570)
	var art := panel(inner, Rect2(0, 0, 476, 228))
	gradient(art, Rect2(0, 0, 476, 228), Color(TaleCatalog.HEROES[id].color, 0.18), Color("212338"))
	banner_portrait(art, id, Rect2(76, 4, 324, 217), false)
	var stats:=TaleCatalog.hero_stats(id,[0,0,0],{})
	if is_expedition():
		for current in run.actors:
			if current.id==id: stats=current
	var detail=preload("res://scripts/combat_details.gd")
	var descriptions := [["ATIVA · AUTOMÁTICA", Content.KITS[id][0], detail.active(stats)], ["PASSIVA", Content.KITS[id][2], detail.passive(stats)], ["ESPECIAL · "+detail.Rules.resource(stats), TaleCatalog.HERO_TACTICS[id].ult, detail.ultimate(stats)]]
	var y:=248.0
	for data in descriptions:
		var h:=maxf(240,get_theme_font("font").get_multiline_string_size(str(data[2]),HORIZONTAL_ALIGNMENT_LEFT,444,15).y+110)
		panel(inner,Rect2(0,y,476,h))
		label(inner,data[0],Rect2(16,y+10,444,21),10,GOLD)
		label(inner,data[1],Rect2(16,y+37,444,32),22)
		label(inner,data[2],Rect2(16,y+78,444,h-88),15,MUTED)
		y+=h+12
	inner.custom_minimum_size.y=y+24
	button(page, "Selecionar Personagem", Rect2(24, 813, 316, 54), use_protagonist.bind(id), true).disabled = not campaign.checkpoint.is_empty()
	button(page, "Coleção", Rect2(356, 813, 160, 54), show_heroes)
	navigation("heroes")

func show_tactical_details(id: String) -> void:
	show_hero_details(id)

func show_journal() -> void:
	show_goals("daily")

func show_profile() -> void:
	state = "profile"
	clear_page()
	header(campaign.player_name, "Sua coleção e suas memórias atravessam as runs.")
	face_portrait(page, campaign.avatar, Rect2(200, 198, 140, 142))
	label(page, "RECORDE · %d pontos\n%d runs iniciadas\n%d vitórias completas\n%d tentativas encerradas\nMaior estágio alcançado: %02d\nInfinito: %d páginas\n%d personagens revelados" % [campaign.best_score, campaign.run_counter, campaign.expedition_wins, campaign.total_defeats, campaign.best_depth, campaign.best_endless, campaign.unlocked.size()], Rect2(54, 382, 432, 245), 23, GOLD)
	button(page, "Conquistas",Rect2(24,636,492,52),show_goals.bind("achievements"),true)
	button(page, "Nome e avatar", Rect2(24, 698, 492, 56), edit_profile)
	button(page, "Configurações", Rect2(24, 776, 492, 56), show_settings)
	navigation("profile")

func show_settings() -> void:
	if state in ["battle", "travel"]:
		toggle_pause()
		return
	state = "settings"
	clear_page()
	header("Configurações", "Som, apresentação e controles da sua jornada.")
	var inner := scroll_area(190, 679, 1320)
	setting_slider(inner, "Música", 0, campaign.music_volume, set_music_volume)
	setting_slider(inner, "Efeitos", 132, campaign.effects_volume, set_effects_volume)
	setting_slider(inner, "Vozes de ataque", 264, campaign.voice_volume, set_voice_volume)
	button(inner, "Movimento reduzido: " + ("ON" if campaign.reduced_motion else "OFF"), Rect2(0, 413, 476, 52), toggle_motion)
	button(inner, "Qualidade: " + ("Alta" if campaign.high_quality else "Leve"), Rect2(0, 481, 476, 52), set_quality.bind(not campaign.high_quality))
	button(inner, "%d FPS" % campaign.fps_limit, Rect2(0, 549, 476, 52), set_fps.bind(30 if campaign.fps_limit == 60 else 60))
	button(inner, "Velocidade padrão: %d×" % TaleCampaign.speed_label(campaign.speed), Rect2(0, 617, 476, 52), change_default_speed)
	button(inner, "ULT automática: " + ("ON" if campaign.auto_ult else "OFF"), Rect2(0, 685, 476, 52), settings_auto_ult)
	button(inner, "Tela cheia / Janela · F11", Rect2(0, 753, 476, 52), toggle_fullscreen).disabled = OS.has_feature("mobile")
	button(inner, "Como jogar", Rect2(0, 835, 476, 52), show_help)
	button(inner, "Créditos", Rect2(0, 903, 476, 52), show_credits)
	code_settings_section(inner,1000)
	button(inner, "Resetar conta deste dispositivo", Rect2(0, 1230, 476, 56), request_reset).add_theme_color_override("font_color", Color("ecaaa3"))
	navigation("profile")

func show_help() -> void:
	state = "help"
	clear_page()
	header("Uma estação, oito mapas", "Prepare o protagonista; descubra o restante durante a tentativa.")
	var inner := scroll_area(190, 674, 1290)
	label(inner, "1. MODOS\nConto: uma das quatro florestas é sorteada. Seus percursos levam por oito mapas, cada um com seis fases: 40 combates e oito visitas ao mercado. Cada mundo termina em um chefe e cura 12% dos PV dos sobreviventes. Após vencer o Castelo do Autor, escolha continuar no infinito com a mesma build e dificuldade crescente. Cada combate vencido rende 25 Memórias; chefes rendem mais 50 e concluir a run concede mais 300. Uma run completa rende 1.700 Memórias: três permitem comprar um personagem. Memórias são recebidas ao encerrar a tentativa. No infinito, novos marcos de 12 páginas rendem mais 100 Memórias.\n\n2. COMBATE\nCada rodada segue a Iniciativa, da maior à menor, com teto 100 e valores negativos permitidos. Cada personagem executa seus básicos em sequência na própria vez. ULTs usam os custos de cada ficha e podem intercalar os básicos sem consumi-los. Mana não regenera por tempo. Passivas seguem os gatilhos e limites da ficha. Histórico pausa e mostra dano, cura e efeitos. Vanguardas ficam na frente, assassinos no meio e magos/atiradores atrás. A classe define a formação.\n\n3. SINERGIAS\nJoão e Maria, Peter e Mulan, Scarlet e Vendedora combinam efeitos. As fichas atuais usam os gatilhos próprios de cada personagem; as antigas sinergias por tempo foram substituídas. Veja os gatilhos em Ver build da equipe.\n\n4. CHEFES\nQuebre o estandarte do General para interrompê-lo. A Guardiã copia a última ULT deste combate: pense antes de usar cura e escudo. Destrua os fios da Costureira para libertar as ativas seladas. Ataques básicos e ULTs continuam disponíveis.\n\n5. BUILD E EVENTOS\nEscolha uma de três melhorias após vencer. Convites temporários têm 25% de chance por tela; personagens permanentes custam 5.000 memórias. Eventos opcionais antecedem combates sem substituir sua fase. A Página dos Viajantes é uma relíquia mítica consumida ao receber: +1 vaga nesta run, até 5. Cada posição comporta 3. Estágios 1–2 têm até 3 inimigos; estágios 3–6 até 6; estágio 7 em diante até 9. Fases 1–4 são combates e recompensas, fase 5 é Mercador ou Negociante, fase 6 é o chefe. Eventos podem aparecer antes dos combates. Inimigos atuais não têm esquiva. Chefes vêm com 2 ajudantes. Cada personagem equipa 2 itens entre combates. Chefes oferecem um equipamento; duelos secretos dão um troféu exclusivo. Cada protagonista tem 4 bênçãos, liberadas por feitos próprios. A equipe muda as falas e libera opções especiais. Bônus duram até o fim da run: 70% Único (escolha o personagem), 30% Grupo (compatíveis e futuros recrutados). Raridades: comum 40%, incomum 28%, raro 18%, épico 9%, lendário 4%, mítico 1%. Valores exatos e percentuais aditivos. Iniciativa permite agir antes (+) ou depois (−), com prévia. Saves antigos mantêm os efeitos legados sem conversão.\n\n6. FIM E RETOMADA\nOuro, bônus e convidados são da run. Feitos, coleção, descobertas, recordes e memórias permanecem. Pontos vêm das vitórias, chefes, elites, rapidez e aliados sobreviventes; vencer sem perder PV concede um bônus. Salvar e sair retoma no início do combate atual ou na escolha salva, sem sortear outras opções.\n\nCONTROLES\nToque nos retratos ou use 1–5 para a ULT. Espaço/ESC pausa; A alterna ULT automática; F11 alterna tela cheia.", Rect2(0, 0, 476, 1270), 17)
	navigation("profile")

func show_preview() -> void:
	state = "preview"
	clear_page()
	header("Livro animado", "DEBUG · todos os viajantes · progresso preservado." if debug_enabled and debug_roster_all else "Somente viajantes já revelados na coleção.")
	if not hero_revealed(selected_hero): selected_hero = "scarlet"
	make_arena(286, [selected_hero], 0)
	arena.set_animation("idle")
	frame_label = label(page, "", Rect2(24, 651, 492, 42), 18, GOLD)
	var ids:Array=TaleCatalog.HEROES.keys() if debug_enabled and debug_roster_all else campaign.unlocked
	var inner := scroll_area(184, 94, 68)
	for index in ids.size():
		var id: String = ids[index]
		button(inner, str(TaleCatalog.HEROES[id].get("short_name", TaleCatalog.HEROES[id].name)), Rect2(index * 155, 0, 146, 52), choose_preview.bind(id), selected_hero == id)
	inner.custom_minimum_size.x = maxf(476, ids.size() * 155)
	inner.get_parent().horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	for index in 4:
		button(page, ["Parado", "Piscando", "Andar", "Ataque"][index], Rect2(24 + (index % 2) * 252, 714 + floori(index / 2.0) * 63, 240, 52), preview_anim.bind(["idle", "idle_blink", "walk", "attack"][index]))
	navigation("heroes")

func choose_preview(id: String) -> void:
	if hero_revealed(id):
		selected_hero = id
		show_preview()

func preview_anim(anim: String) -> void:
	if state != "preview" or anim not in ["idle", "idle_blink", "walk", "attack"]: return
	arena.reset_effects()
	if anim == "attack":
		arena.preview = true
		arena.attack()
	else: arena.set_animation(anim)

func update_desktop_shell() -> void:
	if state == "heroes":
		if is_instance_valid(desktop_shell): desktop_shell.queue_free()
		return
	super.update_desktop_shell()
	if is_instance_valid(desktop_shell):
		for child in desktop_shell.get_children():
			if child is Label and child.text.begins_with("%02d / 12 capítulos" % campaign.cleared.size()):
				child.text = "Recorde %02d / 12\n\n%d personagens\n\n%d vitórias completas" % [campaign.best_depth, campaign.unlocked.size(), campaign.expedition_wins]
			elif child is Button and child.text == "Campanha": child.text = "Nova run"


func continue_into_endless() -> void:
	if state != "result" or not run.continue_endless(campaign): return
	persist_run()
	show_relics()


func journey_modal(title: String, subtitle: String) -> void:
	modal(title, subtitle)
	overlay.get_child(0).color = Color(0.02, 0.03, 0.06, 0.60)
	var card := Panel.new()
	card.position = Vector2(16, 148)
	card.size = Vector2(508, 718)
	card.add_theme_stylebox_override("panel", box(Color("111a2b", 0.96), Color("947e50"), 19))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card)
	register_layout(card, "center")
	overlay.move_child(card, 1)

func show_secret_reward() -> void:
	var secrets=preload("res://scripts/secret_encounters.gd")
	if not secrets.DATA.has(run.pending_secret_reward):
		run.interlude=""
		enter_encounter()
		return
	state="secret_reward"
	paused=true
	if not is_instance_valid(arena) or not battle_view: build_battle()
	arena.frozen=true
	arena.enemy_visible=false
	var reward: Dictionary=secrets.DATA[run.pending_secret_reward]
	journey_modal("Lenda vencida · "+str(reward.name),"+600 pontos · +%d ouro"%(75+run.stage*5))
	face_portrait(overlay,run.pending_secret_reward,Rect2(208,336,124,124))
	label(overlay,reward.reward+"\nEspecial: "+Equipment.data("trophy_"+run.pending_secret_reward).title+" adicionado ao inventário.\n\nBônus aplicado nesta run. A próxima fase normal continua de onde parou.",Rect2(40,492,460,170),20,GOLD)
	button(overlay,"Equipar troféu",Rect2(32,702,476,50),show_equipment.bind(maxi(0,run.actor_ids().find(run.pending_secret_reward))))
	button(overlay,"Continuar a jornada",Rect2(32,768,476,58),continue_after_secret,true)
func continue_after_secret() -> void:
	if run.interlude!="secret_reward": return
	run.pending_secret_reward=""
	run.interlude=""
	paused=false
	persist_run()
	enter_encounter()

var wishes_was_paused:=false
func show_wishes() -> void:
	if run==null:return
	var rules=preload("res://scripts/combat_rules.gd")
	var a:Dictionary=rules.actor(run,"aladin")
	if a.is_empty():return
	wishes_was_paused=paused
	paused=true
	if is_instance_valid(arena):arena.frozen=true
	modal("3 Desejos","Um uso de cada desejo por run. Disponível mesmo com Aladin caído. Restam %d desejos."%rules.wishes_left(a))
	var labels:Array=[["wealth","Riqueza · +%d ouro"%(200*(run.stage+1))],["life","Ressurreição · reviver todos os aliados"],["death","Abate · eliminar inimigos / 1000% DM em chefes"]]
	for i in labels.size():
		var id:String=labels[i][0]
		var used:bool=a.get("wishes",[]).has(id)
		var can_repeat:bool=rules.boon(a,2) and not a.get("wish_extra",false)
		var b:=button(overlay,labels[i][1],Rect2(32,410+i*66,476,58),perform_wish.bind(id))
		b.disabled=(used and not can_repeat) or (id=="death" and (state!="battle" or run.enemy_hp<=0))
	button(overlay,"Voltar",Rect2(32,634,476,56),close_wishes,true)

func close_wishes() -> void:
	if is_instance_valid(overlay):overlay.queue_free()
	paused=wishes_was_paused
	if is_instance_valid(arena):arena.frozen=paused
	update_hud()
	if state=="route":show_routes()

func perform_wish(id:String) -> void:
	var hit:Dictionary=preload("res://scripts/combat_rules.gd").wish(run,id)
	if hit.is_empty():return
	close_wishes()
	if state=="battle":
		if is_instance_valid(arena):
			for id_revived in hit.get("revived",[]):
				var at:int=run.actor_ids().find(str(id_revived))
				if at<0:continue
				arena.tracks[at].alive=true
				arena.tracks[at].time=-1.0
				arena.heroes[at].modulate=Color.WHITE
				arena.heroes[at].show_animation("idle")
				arena.damage_number("RESSURREIÇÃO",arena.tracks[at].home,Color("9ce5b3"))
			arena.sync_health(run.actors)
		push_battle_log("Aladin · "+{"life":"Ressurreição","death":"Abate","wealth":"Riqueza"}.get(id,id))
		update_hud()
	else:
		persist_run()
		if state=="shop":show_run_shop()
		elif state=="route":show_routes()
		else:show_run_build()

func wishes_button() -> void:
	if run==null:return
	var rules=preload("res://scripts/combat_rules.gd")
	var a:Dictionary=rules.actor(run,"aladin")
	if not a.is_empty():
		if state=="route" and is_instance_valid(overlay):button(overlay,"✦ 3 Desejos · %d disponíveis"%rules.wishes_left(a),Rect2(32,324,476,44),show_wishes)
		else:button(page,"✦ 3 Desejos · %d disponíveis"%rules.wishes_left(a),Rect2(24,177,492,38),show_wishes)


func bonus_skin(card:Control,id:String,remove_decoration:=true) -> void:
	if remove_decoration:
		for child in card.get_children():
			card.remove_child(child)
			child.queue_free()
	var tint:=Bonuses.tint(id)
	card.set_meta("bonus_rarity",Bonuses.parse(id).rarity)
	card.set_meta("rarity_color",tint)
	var background:=tint.darkened(.72)
	if card is Button:
		for skin in ["normal","disabled","hover","pressed"]:
			card.add_theme_stylebox_override(skin,box(background.lightened(.10) if skin=="hover" else background,tint,10))
	else:card.add_theme_stylebox_override("panel",box(background,tint,10))

func show_bonus_selection(id:String,source:="reward",target:="",direction:=0) -> void:
	var data:=Bonuses.describe(id)
	if data.is_empty():return
	state="bonus_choice"
	paused=true
	journey_modal(data.title,data.note+"\n"+data.detail)
	overlay.set_meta("bonus_offer",id)
	var strip:=panel(overlay,Rect2(32,382,476,52))
	bonus_skin(strip,id,false)
	label(strip,"PRÉVIA · escolha e confirme abaixo",Rect2(14,8,448,36),17,Color("f4efdf"))
	var initiative:bool=data.attribute=="initiative"
	if initiative:
		for sign_value in [1,-1]:
			var text:="Agir antes (+%d)"%int(data.magnitude) if sign_value>0 else "Agir depois (−%d)"%int(data.magnitude)
			var choice:=button(overlay,text,Rect2(32 if sign_value>0 else 278,444,230,52),show_bonus_selection.bind(id,source,target,sign_value),direction==sign_value)
			choice.name="BonusEarlier" if sign_value>0 else "BonusLater"
	var top:=510.0 if initiative else 448.0
	var scroll:=ScrollContainer.new()
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.name="BonusRecipients"
	scroll.position=Vector2(32,top)
	scroll.size=Vector2(476,708-top)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	register_layout(scroll,"center")
	var inner:=Control.new()
	inner.custom_minimum_size=Vector2(458,run.actors.size()*87)
	scroll.add_child(inner)
	var valid:=false
	for i in run.actors.size():
		var a:Dictionary=run.actors[i]
		var preview:=Bonuses.preview(a,data,direction if direction!=0 else 1)
		var eligible:bool=Bonuses.useful(a,data.attribute,direction)
		var recipient:=button(inner,"",Rect2(0,i*87,458,79),show_bonus_selection.bind(id,source,str(a.id),direction),a.id==target)
		recipient.set_meta("bonus_recipient",a.id)
		recipient.disabled=data.mode=="group" or not eligible
		face_portrait(recipient,a.id,Rect2(9,9,58,58))
		label(recipient,str(TaleCatalog.HEROES[a.id].name)+(" · CAÍDO" if a.hp<=0 else ""),Rect2(78,7,365,26),16,GOLD if a.id==target else Color("edf0e3"))
		label(recipient,"Escolha o sentido acima" if initiative and direction==0 and eligible else preview.text,Rect2(78,37,365,34),14,Color("c9d9c5"))
		if preview.eligible and (data.mode=="group" or a.id==target):valid=true
	var help_text:="Caídos recebem o bônus sem reviver. Nada é consumido ao voltar."
	if data.mode=="group":help_text="Uma aplicação por integrante compatível, incluindo futuros recrutados."
	label(overlay,help_text,Rect2(32,714,476,43),13,MUTED)
	var confirm:=button(overlay,"Confirmar%s"%(" · %d ouro"%run.supply_cost(id) if source=="shop" else ""),Rect2(32,764,476,50),confirm_bonus_selection.bind(id,source,target,direction),true)
	confirm.name="ConfirmBonus"
	confirm.disabled=not valid or initiative and direction==0 or source=="shop" and (run.shop_bought.has(id) or run.run_gold<run.supply_cost(id))
	button(overlay,"Voltar sem escolher",Rect2(32,822,476,44),cancel_bonus_selection.bind(source))

func cancel_bonus_selection(source:String) -> void:
	if source=="shop":show_run_shop()
	else:show_relics()

func confirm_bonus_selection(id:String,source:String,target:String,direction:int) -> void:
	if state!="bonus_choice" or not run.confirm_bonus(id,target,direction,source):return
	persist_run()
	if source=="shop":show_run_shop()
	else:walk_to_routes()


func show_debug_run_setup() -> void:
	if not prepare_debug_campaign():return
	state="debug_setup"
	if debug_party.is_empty():debug_party.assign([selected_hero])
	modal("Montar run DEBUG","Até 5 viajantes; o primeiro é o protagonista. Todas as bênçãos ficam liberadas. Equipamentos completos na bolsa do teste.")
	var scroll:=ScrollContainer.new()
	scroll.name="DebugHeroList"
	scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	scroll.position=Vector2(32,390);scroll.size=Vector2(476,320)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll);register_layout(scroll,"center")
	var inner:=Control.new();inner.custom_minimum_size=Vector2(458,6*76);scroll.add_child(inner)
	var ids:Array=TaleCatalog.HEROES.keys()
	for i in ids.size():
		var id:String=ids[i]
		var selected:bool=debug_party.has(id)
		var item:=button(inner,str(TaleCatalog.HEROES[id].name),Rect2((i%2)*232,floori(i/2.0)*76,226,66),toggle_debug_hero.bind(id),selected)
		item.set_meta("debug_hero",id)
		item.add_theme_font_size_override("font_size",15)
		item.disabled=not selected and not can_add_debug_hero(id)
	label(overlay,"%d / 5 · Protagonista: %s"%[debug_party.size(),TaleCatalog.HEROES[debug_party[0]].name],Rect2(32,716,476,38),15,GOLD)
	button(overlay,"Escolher bênção e iniciar →",Rect2(32,766,476,54),configure_debug_protagonist,true)
	button(overlay,"Voltar à coleção",Rect2(32,828,476,44),show_heroes)

func can_add_debug_hero(id:String) -> bool:
	if debug_party.size()>=Content.MAX_PARTY:return false
	var rank=preload("res://scripts/tactics.gd").rank_for_class(TaleCatalog.HERO_TACTICS[id]["class"])
	return debug_party.filter(func(hero):return preload("res://scripts/tactics.gd").rank_for_class(TaleCatalog.HERO_TACTICS[hero]["class"])==rank).size()<3

func toggle_debug_hero(id:String) -> void:
	if not debug_session:return
	if debug_party.has(id):
		if debug_party.size()>1:debug_party.erase(id)
	elif can_add_debug_hero(id):debug_party.append(id)
	show_debug_run_setup()

func configure_debug_protagonist() -> void:
	if not debug_session or debug_party.is_empty():return
	selected_hero=debug_party[0]
	campaign.party.assign([selected_hero])
	chosen_blessing=Blessings.id_for(selected_hero,0)
	show_map()

func show_map_choices() -> void:
	for index in run.route_offers.size():
		var key:String=run.route_offers[index]
		var id:=key.trim_prefix("map:")
		var data:Dictionary=run.Worlds.NODES[id]
		var card:=button(overlay,"",Rect2(32,390+index*124,476,114),select_route.bind(key),true)
		card.set_meta("map_choice",id)
		var picture:=TextureRect.new()
		picture.texture=run.Worlds.texture(id)
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.position=Vector2(8,8);picture.size=Vector2(128,98)
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(picture)
		label(card,data.name,Rect2(148,10,314,46),20,GOLD)
		var note:String="Mapa %d de 8 · %s"%[run.stage+1,run.Worlds.LABELS[run.journey.season]]
		if not str(data.meeting).is_empty():note+="\nEncontro: "+str(TaleCatalog.HEROES[data.meeting].name)
		label(card,note,Rect2(148,60,314,48),13,MUTED)

func show_goals(tab:="daily") -> void:
	state="goals"
	clear_page()
	campaign.refresh_daily()
	header("Objetivos do viajante","Conquistas permanentes e três missões por dia.")
	button(page,"Missões diárias",Rect2(24,181,242,48),show_goals.bind("daily"),tab=="daily")
	button(page,"Conquistas",Rect2(274,181,242,48),show_goals.bind("achievements"),tab!="daily")
	var daily_tab:=tab=="daily"
	var tasks:Array=TaleCampaign.DAILIES if daily_tab else TaleCampaign.ACHIEVEMENTS
	label(page,"Dia %s · renova à meia-noite do dispositivo"%campaign.daily.day if daily_tab else "Recompensas únicas · progresso salvo entre runs",Rect2(24,240,492,40),12,MUTED)
	var inner:=scroll_area(290,564,tasks.size()*162)
	for index in tasks.size():
		var task:Dictionary=tasks[index]
		var card:=panel(inner,Rect2(0,index*162,476,152))
		var done:bool=campaign.daily.claimed.has(task.id) if daily_tab else campaign.claimed.has(task.id)
		var progress:Vector2i=Vector2i(int(campaign.daily.get(task.id,0)),task.goal) if daily_tab else campaign.achievement_progress(task.id)
		var ready:=progress.x>=progress.y
		var concealed:bool=not daily_tab and bool(task.get("hidden",false)) and not ready and not done
		if daily_tab:icon(card,task.icon,Rect2(12,14,36,36),GOLD if ready else MUTED)
		else:
			var picture:=TextureRect.new()
			picture.name="AchievementImage"
			picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			picture.texture=preload("res://scripts/achievement_art.gd").texture(task,concealed)
			picture.position=Vector2(8,12)
			picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			picture.size=Vector2(44,44)
			picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card.add_child(picture)
			preload("res://scripts/achievement_art.gd").gold_frame(card,preload("res://scripts/achievement_art.gd").fitted_rect(picture.texture,Rect2(8,12,44,44)))
		label(card,"Conquista oculta" if concealed else task.title,Rect2(60,10,398,28),16,GOLD)
		label(card,"Continue explorando para descobrir este feito." if concealed else task.detail,Rect2(60,40,398,34),12)
		var meter:=bar(card,Rect2(16,86,266,8),GOLD)
		meter.max_value=progress.y
		meter.value=0 if concealed else mini(progress.x,progress.y)
		label(card,"???" if concealed else "%d / %d · +%d Memórias"%[mini(progress.x,progress.y),progress.y,task.reward],Rect2(16,107,278,26),12,MUTED)
		var collect:=button(card,"Resgatado" if done else "Resgatar",Rect2(302,94,158,44),claim_goal.bind(task.id,daily_tab),ready and not done)
		collect.disabled=done or not ready
		collect.name="Claim_"+task.id
	navigation("profile")

func claim_goal(id:String,daily_task:bool) -> void:
	var before:=campaign.to_dict().duplicate(true)
	var collected:bool=campaign.claim_daily(id) if daily_task else campaign.claim_achievement(id)
	if collected:
		if not campaign.save_to(save_path):
			campaign.load_data(before)
		else:audio.play_effect("achievement")
	show_goals("daily" if daily_task else "achievements")
