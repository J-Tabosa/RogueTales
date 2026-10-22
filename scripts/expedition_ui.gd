extends "res://scripts/interface.gd"
## The run experience. Legacy chapter checkpoints can still be finished safely.
const Content = preload("res://scripts/expedition_content.gd")
var chosen_blessing := "vigor"
var gallery_building := false
var gallery_size := Vector2.ZERO
var gallery_refresh := false
var gallery_scroll: ScrollContainer

func is_expedition() -> bool:
	return run != null and run.expedition

func label(parent: Node, text: String, rect: Rect2, font_size := 18, color := Color("eeeae2")) -> Label:
	var node := super.label(parent, text, rect, font_size, color)
	if color.get_luminance() < 0.20: node.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	return node

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
	header("Toda run, um novo conto.", "Recorde: %02d / 12 fases  ·  %d vitórias completas" % [campaign.best_depth, campaign.expedition_wins])
	var art := panel(page, Rect2(24, 190, 492, 352))
	UISkin.picture(art, UISkin.FOREST, Rect2(0, 0, 492, 352), true).modulate = Color(0.8, 0.8, 0.9)
	gradient(art, Rect2(0, 0, 492, 352), Color("161c30", 0.15), Color("161c30", 0.95))
	var id: String = campaign.party[0] if campaign.unlocked.has(campaign.party[0]) else "scarlet"
	portrait_fitted(art, id, Vector2(246, 319), 283)
	label(art, "ESCREVA SEU PRÓPRIO FINAL", Rect2(18, 16, 456, 29), 13, GOLD)
	label(page, "Escolha. Arrisque. Recomece.", Rect2(24, 565, 492, 43), 26)
	label(page, "Um protagonista. Companheiros raros.\nHabilidades e relíquias que mudam a cada tentativa.", Rect2(24, 620, 492, 66), 17, MUTED)
	var active := not campaign.checkpoint.is_empty()
	var detail := "A vida, a build e os encontros da sua tentativa estão salvos." if active else "12 fases · chefes em 4, 8 e 12 · escolhas entre combates"
	label(page, detail, Rect2(24, 704, 492, 48), 14, GOLD)
	button(page, "Retomar run  →" if active else "Nova run  →", Rect2(24, 772, 492, 62), resume_checkpoint if active else show_map, true)
	navigation("menu")

func continue_journey() -> void:
	if not campaign.checkpoint.is_empty(): resume_checkpoint()
	else: show_map()

func show_map() -> void:
	state = "expedition_setup"
	clear_page()
	header("Antes da primeira página", "Escolha um protagonista e uma bênção para esta run.")
	if not campaign.checkpoint.is_empty():
		label(page, "Uma tentativa em andamento", Rect2(24, 219, 492, 48), 25, GOLD)
		label(page, "Fase %02d / 12\nRetome sua equipe e sua build, ou encerre a tentativa para começar outra." % (int(campaign.checkpoint.stage) + 1), Rect2(24, 287, 492, 124), 20)
		button(page, "Retomar run", Rect2(24, 487, 492, 64), resume_checkpoint, true)
		button(page, "Encerrar tentativa", Rect2(24, 570, 492, 56), request_abandon)
		navigation("map")
		return
	if not campaign.unlocked.has(selected_hero): selected_hero = campaign.party[0]
	if not campaign.blessings_unlocked.has(chosen_blessing): chosen_blessing = "vigor"
	var hero := button(page, "", Rect2(24, 187, 492, 144), show_heroes)
	face_portrait(hero, selected_hero, Rect2(14, 15, 108, 108))
	label(hero, "PROTAGONISTA", Rect2(139, 17, 334, 23), 11, GOLD)
	label(hero, TaleCatalog.HEROES[selected_hero].name, Rect2(139, 46, 334, 36), 23)
	label(hero, "%s · trocar →" % TaleCatalog.hero_class_name(selected_hero), Rect2(139, 91, 334, 30), 14, MUTED)
	var inner := scroll_area(349, 353, Content.BLESSINGS.size() * 108)
	var i := 0
	for key in Content.BLESSINGS:
		var data: Dictionary = Content.BLESSINGS[key]
		var owned := campaign.blessings_unlocked.has(key)
		var card := button(inner, "", Rect2(0, i * 108, 476, 98), choose_blessing.bind(key), chosen_blessing == key and owned)
		label(card, data.name + ("" if owned else " · %d memórias" % data.cost), Rect2(14, 9, 448, 28), 18, Color("192329") if chosen_blessing == key and owned else GOLD)
		label(card, data.detail, Rect2(14, 44, 448, 45), 14, Color("29363b") if chosen_blessing == key and owned else MUTED)
		i += 1
	label(page, "Ouro, habilidades e convidados pertencem a esta tentativa.\nDesbloqueios e memórias continuam depois dela.", Rect2(24, 724, 492, 55), 14, MUTED)
	button(page, "Iniciar expedição  →", Rect2(24, 798, 492, 60), begin_expedition, true)
	navigation("map")

func choose_blessing(id: String) -> void:
	if not campaign.blessings_unlocked.has(id):
		if not campaign.unlock_blessing(id):
			modal("Uma nova possibilidade", "%s\n\nChegue à fase %d e reúna %d memórias para liberar esta bênção inicial." % [Content.BLESSINGS[id].name, 4 if id == "thorns" else 8, Content.BLESSINGS[id].cost])
			button(overlay, "Voltar", Rect2(32, 614, 476, 56), show_map, true)
			return
	chosen_blessing = id
	persist()
	show_map()

func begin_expedition() -> void:
	if not campaign.checkpoint.is_empty(): return
	run = IdleRun.new()
	if not run.start_expedition(campaign, selected_hero, chosen_blessing): return
	campaign.pending_story = -1
	campaign.auto_repeat = false
	persist_run()
	show_loading(enter_encounter, 0)

func persist_run() -> void:
	campaign.checkpoint = run.to_checkpoint()
	persist()

func enter_encounter() -> void:
	build_battle()
	begin_travel()

func begin_travel() -> void:
	super.begin_travel()
	if is_expedition():
		log_label.text = "Fase %02d · %s" % [run.stage + 1, "o chefe aguarda" if Content.is_boss(run.stage) else ("rota de elite" if run.room_kind == "elite" else "a jornada continua")]

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
		_: enter_encounter()

func resolve_enemy() -> void:
	if not is_expedition():
		super.resolve_enemy()
		return
	if state != "battle": return
	if not run.alive():
		finish_defeat()
		return
	state = "resolving"
	arena.reset_effects()
	campaign.total_kills += run.tactics.enemies.size()
	if run.clear_encounter():
		var result := campaign.finish_expedition(run.to_checkpoint(), true)
		persist()
		show_run_result(result)
	else:
		persist_run()
		show_relics()

func show_relics() -> void:
	if not is_expedition():
		super.show_relics()
		return
	state = "choice"
	paused = false
	clear_page()
	header("Reescreva sua build", "%02d / 12 fases vencidas · escolha uma melhoria." % run.rooms_cleared)
	label(page, "ESCOLHAS DESTA RUN", Rect2(24, 190, 492, 28), 12, GOLD)
	for index in run.offers.size():
		var id: String = run.offers[index]
		var offer := TaleCatalog.offer_data(id)
		var card := button(page, "", Rect2(24, 238 + index * 174, 492, 158), select_relic.bind(id))
		var title: String = offer.title
		var detail: String = offer.detail
		var note := "RELÍQUIA · %d / 3" % (run.relics.count(id) + 1)
		if offer.has("owner"):
			note = "HABILIDADE · " + str(TaleCatalog.HEROES[offer.owner].name)
		elif offer.has("hero"):
			var owned := campaign.unlocked.has(offer.hero)
			title = str(TaleCatalog.HEROES[offer.hero].name) if owned else "Um viajante desconhecido"
			detail = "%s · junta-se à equipe apenas nesta run." % TaleCatalog.hero_class_name(offer.hero)
			note = "ENCONTRO RARO · 10% POR ESCOLHA DE RECOMPENSA"
		label(card, note, Rect2(16, 12, 460, 25), 10, GOLD)
		label(card, title, Rect2(16, 45, 460, 35), 22)
		label(card, detail, Rect2(16, 88, 460, 58), 15, MUTED)
	label(page, "Escolhas salvas: voltar ao início mantém estas opções.", Rect2(24, 782, 492, 40), 13, MUTED)
	button(page, "Salvar e sair", Rect2(24, 837, 492, 52), leave_battle)

func select_relic(id: String, replace_index: int = -1) -> void:
	if not is_expedition():
		super.select_relic(id, replace_index)
		return
	if state != "choice" or not run.offers.has(id): return
	var offer := TaleCatalog.offer_data(id)
	if offer.is_empty(): return
	if offer.has("hero") and run.actors.size() == 3 and replace_index < 0:
		show_recruit_replacement(id)
		return
	var applied: bool = run.recruit(campaign, offer.hero, replace_index) if offer.has("hero") else run.apply_relic(id)
	if not applied: return
	persist_run()
	show_routes()

func show_routes() -> void:
	state = "route"
	paused = false
	clear_page()
	header("A próxima página", "Fase %02d / 12 · %d ouro nesta run" % [run.stage + 1, run.run_gold])
	if Content.is_boss(run.stage):
		label(page, "O FIO LEVA A UM CHEFE", Rect2(24, 201, 492, 30), 13, GOLD)
		label(page, TaleCatalog.STAGES[run.stage].boss, Rect2(24, 261, 492, 83), 32)
		label(page, "Os inimigos desta fase são mais resistentes.\nSua vida, energia e melhorias continuam com você.", Rect2(24, 378, 492, 104), 19, MUTED)
		button(page, "Enfrentar o chefe  →", Rect2(24, 570, 492, 65), select_route.bind("battle"), true)
	else:
		label(page, "ESCOLHA SEU CAMINHO", Rect2(24, 201, 492, 30), 13, GOLD)
		for index in run.route_offers.size():
			var key: String = run.route_offers[index]
			var data: Dictionary = Content.ROUTES[key]
			var card := button(page, "", Rect2(24, 260 + index * 201, 492, 181), select_route.bind(key))
			label(card, "ROTA %02d" % (index + 1), Rect2(18, 13, 456, 23), 11, GOLD)
			label(card, data.title, Rect2(18, 49, 456, 38), 24)
			label(card, data.detail, Rect2(18, 100, 456, 63), 16, MUTED)
	button(page, "Ver build da equipe", Rect2(24, 738, 492, 52), show_run_build)
	button(page, "Salvar e sair", Rect2(24, 810, 492, 52), leave_battle)

func select_route(id: String) -> void:
	if state != "route" or not run.choose_route(id): return
	persist_run()
	if run.interlude == "shop": show_run_shop()
	else: enter_encounter()

func show_run_shop() -> void:
	state = "shop"
	clear_page()
	header("Mercador de histórias", "%d ouro nesta run · compras não voltam a aparecer." % run.run_gold)
	for index in run.shop_stock.size():
		var key: String = run.shop_stock[index]
		var data := {"title": "Frasco de recomeço", "detail": "Cure 35% dos PV e levante um aliado com 20%."} if key == "potion" else TaleCatalog.offer_data(key)
		var cost := 22 if key == "potion" else 32
		var bought := run.shop_bought.has(key)
		var card := button(page, "", Rect2(24, 228 + index * 162, 492, 146), buy_run_supply.bind(key))
		card.disabled = bought or run.run_gold < cost
		label(card, data.title, Rect2(16, 12, 460, 32), 22, GOLD)
		label(card, data.detail, Rect2(16, 51, 460, 48), 15, MUTED)
		label(card, "COMPRADO" if bought else "%d OURO" % cost, Rect2(16, 111, 460, 23), 12, GOLD)
	button(page, "Seguir viagem  →", Rect2(24, 773, 492, 60), leave_run_shop, true)
	button(page, "Salvar e sair", Rect2(24, 848, 492, 48), leave_battle)

func buy_run_supply(id: String) -> void:
	if state == "shop" and run.buy_supply(id):
		persist_run()
		show_run_shop()

func leave_run_shop() -> void:
	if state != "shop": return
	run.leave_shop()
	persist_run()
	enter_encounter()

func show_run_build() -> void:
	state = "build"
	clear_page()
	header("O conto até aqui", "Fase %02d / 12 · %d ouro · %d melhorias" % [run.stage + 1, run.run_gold, run.relics.size()])
	var inner := scroll_area(190, 593, 230 + run.actors.size() * 122 + run.relics.size() * 83)
	label(inner, "BÊNÇÃO · " + str(Content.BLESSINGS[run.blessing].name), Rect2(0, 0, 476, 42), 18, GOLD)
	var y := 63.0
	for actor in run.actors:
		face_portrait(inner, actor.id, Rect2(0, y, 70, 74))
		label(inner, TaleCatalog.HEROES[actor.id].name, Rect2(88, y, 388, 32), 21)
		label(inner, "%d / %d PV · %s\n%s" % [actor.hp, actor.max_hp, TaleCatalog.hero_class_name(actor.id), Content.KITS[actor.id][0]], Rect2(88, y + 39, 388, 55), 14, MUTED)
		y += 122
	for key in run.relics:
		var data := TaleCatalog.offer_data(key)
		label(inner, data.title, Rect2(0, y, 476, 29), 19, GOLD)
		label(inner, data.detail, Rect2(0, y + 31, 476, 47), 13, MUTED)
		y += 83
	button(page, "Voltar ao caminho", Rect2(24, 814, 492, 56), show_routes, true)

func finish_defeat() -> void:
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
	label(page, "%02d / 12 fases vencidas" % result.get("depth", 0), Rect2(24, 513, 492, 54), 30, GOLD)
	label(page, "+%d memórias · recorde %02d / 12\nAs relíquias, o ouro e os convidados desta run se encerram aqui." % [result.get("reward", 0), campaign.best_depth], Rect2(24, 585, 492, 89), 17, MUTED)
	var unlocked_now: Array = result.get("unlocks", [])
	label(page, "Novo protagonista: " + hero_names(unlocked_now) if not unlocked_now.is_empty() else "Seus feitos e desbloqueios foram salvos.", Rect2(24, 700, 492, 63), 19, GOLD)
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
		enemy_label.text = "RUN %02d · FASE %02d / 12 · %s · %d OURO" % [run.run_id, run.stage + 1, "CHEFE" if Content.is_boss(run.stage) else ("ELITE" if run.room_kind == "elite" else "COMBATE"), run.run_gold]
		for i in mini(ult_buttons.size(), run.actors.size()):
			var actor: Dictionary = run.actors[i]
			ult_buttons[i].tooltip_text = "%s (1 AP)\n%s\n\n%s (1 PP)\n%s\n\nULT: %s" % [Content.KITS[actor.id][0], Content.KITS[actor.id][1], Content.KITS[actor.id][2], Content.KITS[actor.id][3], TaleCatalog.HERO_TACTICS[actor.id].ult]

func navigation(active: String) -> void:
	panel(page, Rect2(16, 882, 508, 68))
	var entries := [["menu", "Início", "home", show_menu], ["map", "Run", "map", show_map], ["heroes", "Heróis", "heroes", show_heroes], ["journal", "Diário", "book", show_journal], ["profile", "Perfil", "profile", show_profile]]
	for i in entries.size():
		var entry: Array = entries[i]
		var item := button(page, "", Rect2(22 + i * 100, 887, 96, 58), entry[3])
		item.add_theme_stylebox_override("normal", box(Color("383346") if active == entry[0] else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12))
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
	gradient(page, Rect2(0, 0, logical_width, logical_height), Color("3f3030"), Color("171d2c"))
	var w := logical_width
	label(page, "O LIVRO DOS VIAJANTES", Rect2(24, 20, w - 120, 28), 12, GOLD)
	label(page, "Heróis dos contos", Rect2(24, 62, w - 120, 54), 32)
	button(page, "Voltar", Rect2(w - 112, 23, 88, 44), show_menu)
	label(page, "%02d / 12 revelados · os encontros escrevem sua coleção." % campaign.unlocked.size(), Rect2(24, 125, w - 48, 45), 15, MUTED)
	button(page, "Todos", Rect2(24, 182, 154, 44), filter_roster.bind("all"), roster_filter == "all")
	button(page, "Revelados", Rect2(190, 182, 154, 44), filter_roster.bind("owned"), roster_filter == "owned")
	var ids: Array = TaleCatalog.HEROES.keys().filter(func(id): return roster_filter == "all" or campaign.unlocked.has(id))
	if not ids.has(selected_hero) and not ids.is_empty(): selected_hero = ids[0]
	gallery_scroll = ScrollContainer.new()
	gallery_scroll.position = Vector2(24, 246)
	gallery_scroll.size = Vector2(w - 48, 416)
	gallery_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	gallery_scroll.scroll_deadzone = 12
	page.add_child(gallery_scroll)
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(ids.size() * 236, 400)
	gallery_scroll.add_child(strip)
	for i in ids.size():
		var id: String = ids[i]
		var owned := campaign.unlocked.has(id)
		var selected := selected_hero == id
		var card := button(strip, "", Rect2(i * 236, 0, 222, 400), select_gallery_hero.bind(id))
		card.set_meta("hero_id", id)
		card.set_meta("silhouette", not owned)
		card.clip_contents = true
		card.add_theme_stylebox_override("normal", box(Color("e3cf9e") if selected else Color("c9b58d"), GOLD if selected else Color("806747"), 4))
		card.add_theme_stylebox_override("hover", box(Color("eddbb3"), GOLD, 4))
		gradient(card, Rect2(4, 4, 214, 330), Color("f4e4be"), Color("b79b78"))
		banner_portrait(card, id, Rect2(6, 19, 210, 300), not owned)
		label(card, "%02d" % (i + 1), Rect2(14, 12, 190, 21), 11, Color("746045"))
		label(card, str(TaleCatalog.HEROES[id].get("short_name", TaleCatalog.HEROES[id].name)) if owned else "???", Rect2(14, 321, 194, 38), 21, Color("332c30")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label(card, TaleCatalog.hero_class_name(id) if owned else "CONTO NÃO REVELADO", Rect2(8, 369, 206, 23), 11, Color("5f5144")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var owned := campaign.unlocked.has(selected_hero)
	var note: String = "%s · %s\nAtiva: %s" % [TaleCatalog.HEROES[selected_hero].name, TaleCatalog.hero_class_name(selected_hero), Content.KITS[selected_hero][0]] if owned else "Uma silhueta aguarda sua história. Encontre-a numa run e cumpra seu feito para revelá-la."
	label(page, note, Rect2(24, 682, w - 48, 52), 16, MUTED)
	var bottom := 744.0 if desktop else 778.0
	button(page, "Habilidades" if owned else "Vínculo desconhecido", Rect2(24, bottom, (w - 62) * 0.5, 54), show_hero_details.bind(selected_hero) if owned else show_unlock_details.bind(selected_hero))
	button(page, "Escolher protagonista", Rect2(38 + (w - 62) * 0.5, bottom, (w - 62) * 0.5, 54), use_protagonist.bind(selected_hero), true).disabled = not owned or not campaign.checkpoint.is_empty()
	gallery_scroll.set_deferred("scroll_horizontal", int(maxf(0, ids.find(selected_hero) * 236 - (w - 48 - 222) * 0.5)))
	gallery_size = Vector2(logical_width, logical_height)
	gallery_building = false

func banner_portrait(parent: Node, id: String, rect: Rect2, hidden: bool) -> void:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var bounds: Rect2 = data.bounds
	var actor := Sprite2D.new()
	actor.name = "Silhouette" if hidden else "HeroArt"
	actor.texture = data.texture
	actor.centered = false
	var factor := minf(rect.size.x / maxf(1, bounds.size.x), rect.size.y / maxf(1, bounds.size.y))
	actor.scale = Vector2.ONE * factor
	actor.position = rect.position + (rect.size - bounds.size * factor) * 0.5 - bounds.position * factor
	actor.self_modulate = Color.BLACK if hidden else Color.WHITE
	parent.add_child(actor)
	if parent == overlay:
		actor.set_meta("portrait_base", actor.position)
		actor.position.y += (logical_height - 960.0) * 0.5

func select_gallery_hero(id: String) -> void:
	selected_hero = id
	show_heroes()

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
	show_hero_details(selected_hero if campaign.unlocked.has(selected_hero) else "scarlet")

func show_unlock_details(id: String) -> void:
	if campaign.unlocked.has(id):
		show_hero_details(id)
		return
	modal("Um conto ainda desconhecido", "Encontre este viajante nas recompensas de uma run. Convites têm 10% de chance por tela de melhoria. Depois de convocá-lo, seus feitos contam para o desbloqueio permanente.")
	banner_portrait(overlay, id, Rect2(177, 394, 186, 236), true)
	button(overlay, "Voltar à coleção", Rect2(32, 721, 476, 56), show_heroes, true)

func show_hero_details(id: String) -> void:
	if not campaign.unlocked.has(id):
		show_unlock_details(id)
		return
	selected_hero = id
	state = "hero_details"
	clear_page()
	header(TaleCatalog.HEROES[id].name, "%s · uma ativa, uma reação e uma ULT própria." % TaleCatalog.hero_class_name(id))
	var inner := scroll_area(184, 605, 1160)
	var art := panel(inner, Rect2(0, 0, 476, 228))
	gradient(art, Rect2(0, 0, 476, 228), Color(TaleCatalog.HEROES[id].color, 0.18), Color("212338"))
	banner_portrait(art, id, Rect2(76, 4, 324, 217), false)
	var descriptions := [["ATIVA · 1 AP", Content.KITS[id][0], Content.KITS[id][1]], ["REAÇÃO · 1 PP", Content.KITS[id][2], Content.KITS[id][3]], ["ULT · 100 ENERGIA", TaleCatalog.HERO_TACTICS[id].ult, TaleCatalog.HERO_TACTICS[id].detail]]
	for index in descriptions.size():
		var data: Array = descriptions[index]
		var y := 248 + index * 156
		panel(inner, Rect2(0, y, 476, 145))
		label(inner, data[0], Rect2(16, y + 10, 444, 21), 10, GOLD)
		label(inner, data[1], Rect2(16, y + 37, 444, 32), 22)
		label(inner, data[2], Rect2(16, y + 78, 444, 58), 15, MUTED)
	label(inner, "TRANSFORMAÇÕES DURANTE A RUN", Rect2(0, 737, 476, 26), 12, GOLD)
	for index in Content.MUTATIONS[id].size():
		var entry: Array = Content.MUTATIONS[id][index]
		label(inner, entry[1], Rect2(0, 783 + index * 110, 476, 30), 20)
		label(inner, entry[2], Rect2(0, 821 + index * 110, 476, 57), 14, MUTED)
	button(page, "Escolher protagonista", Rect2(24, 813, 316, 54), use_protagonist.bind(id), true).disabled = not campaign.checkpoint.is_empty()
	button(page, "Coleção", Rect2(356, 813, 160, 54), show_heroes)
	navigation("heroes")

func show_tactical_details(id: String) -> void:
	show_hero_details(id)

func show_journal() -> void:
	state = "journal"
	clear_page()
	header("Memórias das expedições", "Descobertas permanecem; cada tentativa começa uma nova build.")
	var inner := scroll_area(190, 670, 220 + campaign.journal.size() * 107)
	label(inner, "MELHOR RUN · %02d / 12\nVITÓRIAS COMPLETAS · %d\nVIAJANTES REVELADOS · %d / 12" % [campaign.best_depth, campaign.expedition_wins, campaign.unlocked.size()], Rect2(0, 0, 476, 151), 21, GOLD)
	for index in campaign.journal.size():
		var entry: Dictionary = campaign.journal[index]
		var y := 198 + index * 107
		var card := button(inner, "", Rect2(0, y, 476, 94), show_story.bind(int(entry.stage), "outro", 0, true))
		label(card, "PÁGINA %02d" % (int(entry.stage) + 1), Rect2(14, 9, 448, 21), 11, GOLD)
		label(card, entry.title, Rect2(14, 40, 448, 43), 21)
	navigation("journal")

func show_profile() -> void:
	state = "profile"
	clear_page()
	header(campaign.player_name, "Sua coleção e suas memórias atravessam as runs.")
	face_portrait(page, campaign.avatar, Rect2(200, 198, 140, 142))
	label(page, "%d runs iniciadas\n%d vitórias completas\n%d tentativas encerradas\nRecorde: %02d / 12 fases\n%d personagens revelados" % [campaign.run_counter, campaign.expedition_wins, campaign.total_defeats, campaign.best_depth, campaign.unlocked.size()], Rect2(54, 382, 432, 245), 24, GOLD)
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
	var inner := scroll_area(190, 679, 1270)
	setting_slider(inner, "Música", 0, campaign.music_volume, set_music_volume)
	setting_slider(inner, "Efeitos", 132, campaign.effects_volume, set_effects_volume)
	setting_slider(inner, "Vozes de ataque", 264, campaign.voice_volume, set_voice_volume)
	button(inner, "Movimento reduzido: " + ("ON" if campaign.reduced_motion else "OFF"), Rect2(0, 413, 476, 52), toggle_motion)
	button(inner, "Qualidade: " + ("Alta" if campaign.high_quality else "Leve"), Rect2(0, 481, 476, 52), set_quality.bind(not campaign.high_quality))
	button(inner, "%d FPS" % campaign.fps_limit, Rect2(0, 549, 476, 52), set_fps.bind(30 if campaign.fps_limit == 60 else 60))
	button(inner, "Velocidade padrão: %d×" % int(campaign.speed), Rect2(0, 617, 476, 52), change_default_speed)
	button(inner, "ULT automática: " + ("ON" if campaign.auto_ult else "OFF"), Rect2(0, 685, 476, 52), settings_auto_ult)
	button(inner, "Tela cheia / Janela · F11", Rect2(0, 753, 476, 52), toggle_fullscreen).disabled = OS.has_feature("mobile")
	button(inner, "Como jogar", Rect2(0, 835, 476, 52), show_help)
	button(inner, "Animações dos revelados", Rect2(0, 903, 476, 52), show_preview)
	button(inner, "Créditos", Rect2(0, 971, 476, 52), show_credits)
	button(inner, "Resetar conta deste dispositivo", Rect2(0, 1100, 476, 56), request_reset).add_theme_color_override("font_color", Color("ecaaa3"))
	navigation("profile")

func show_help() -> void:
	state = "help"
	clear_page()
	header("Uma run, doze páginas", "Prepare o protagonista; descubra o restante durante a tentativa.")
	var inner := scroll_area(190, 674, 1010)
	label(inner, "1. COMEÇO\nEscolha um personagem revelado e uma bênção. Níveis e treinamentos antigos não alteram os atributos das novas runs.\n\n2. COMBATE\nA iniciativa organiza ações sequenciais. Ativas gastam AP; reações gastam PP. Os pontos se renovam a cada rodada. Vanguarda enfrenta a frente, atiradores priorizam o fundo e magia alcança ambas as linhas.\n\n3. BUILD\nApós vencer, escolha uma de três melhorias. As skills têm transformações próprias. Existe 10% de chance por tela de uma das cartas ser um convite temporário.\n\n4. JORNADA\nA vida e a energia continuam entre fases. Escolha rotas comuns, elites, descanso, mercador e eventos. O ouro só vale nesta run. Chefes nas fases 4, 8 e 12.\n\n5. FIM\nDerrota ou abandono encerram a tentativa. Ouro, relíquias e convidados se perdem. Feitos, personagens desbloqueados e memórias permanecem. Use memórias para abrir novas bênçãos iniciais.\n\n6. CONTROLES\nToque nos retratos ou use 1–3 para a ULT. Espaço/ESC pausa; A alterna ULT automática; F11 alterna tela cheia. Salvar e sair retoma no início do encontro atual, com as mesmas escolhas.", Rect2(0, 0, 476, 1000), 18)
	navigation("profile")

func show_preview() -> void:
	state = "preview"
	clear_page()
	header("Livro animado", "Somente viajantes já revelados na coleção.")
	if not campaign.unlocked.has(selected_hero): selected_hero = "scarlet"
	make_arena(286, [selected_hero], 0)
	arena.set_animation("idle")
	frame_label = label(page, "", Rect2(24, 651, 492, 42), 18, GOLD)
	var inner := scroll_area(184, 94, 68)
	for index in campaign.unlocked.size():
		var id: String = campaign.unlocked[index]
		button(inner, str(TaleCatalog.HEROES[id].get("short_name", TaleCatalog.HEROES[id].name)), Rect2(index * 155, 0, 146, 52), choose_preview.bind(id), selected_hero == id)
	inner.custom_minimum_size.x = maxf(476, campaign.unlocked.size() * 155)
	inner.get_parent().horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	for index in 4:
		button(page, ["Parado", "Piscando", "Andar", "Ataque"][index], Rect2(24 + (index % 2) * 252, 714 + floori(index / 2.0) * 63, 240, 52), preview_anim.bind(["idle", "idle_blink", "walk", "attack"][index]))
	navigation("heroes")

func choose_preview(id: String) -> void:
	if campaign.unlocked.has(id):
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
