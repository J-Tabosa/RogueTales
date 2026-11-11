extends "res://scripts/main.gd"
## Mobile storybook presentation; progression/story orchestration stays in main.gd.
const TacticalArena = preload("res://scripts/tactical_arena.gd")
const ItemArt = preload("res://scripts/item_art.gd")
var hero_deck_scroll: ScrollContainer
var hero_deck: Control
var equipment_panel: Control
var equipment_was_paused:=false
var battle_gold: Label
var reward_return: Button
const TeamCard = preload("res://scripts/team_card.gd")
const ResourceBar = preload("res://scripts/character_resource_bar.gd")
const HealthDisplay = preload("res://scripts/health_display.gd")
const BattleType = preload("res://scripts/battle_typography.gd")
var battle_view := false
var desktop := false
var logical_width := 540.0
var desktop_shell: Control
var battle_nodes: Array[Control] = []
var ult_buttons: Array[Button] = []
var ult_meters: Array[ProgressBar] = []
var card_health: Array[ProgressBar] = []
var feedback: Control
var battle_history: Array[String] = []
var battle_last_action := ""

var battle_viewport: Control
var auto_button: Button
var power_label: Label
var reset_confirm: Button
var timeline: Control
var action_label: Label
var timeline_key := ""
var roster_filter := "all"
const MobileIcon = preload("res://scripts/mobile_icon.gd")


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is TextureRect:
			child.modulate.a = 0.34
	apply_window_mode()


func center_content(usable_override: Rect2 = Rect2()) -> void:
	if content == null:
		return
	desktop = size.x / maxf(1, size.y) >= 1.28
	if battle_view and desktop:
		logical_width = 1280.0
		logical_height = 800.0
		var factor := minf(size.x / logical_width, size.y / logical_height)
		content.size = Vector2(logical_width, logical_height)
		content.scale = Vector2.ONE * factor
		content.position = (size - content.size * factor) * 0.5
		relayout_page()
	else:
		logical_width = 540.0
		super.center_content(usable_override)
	update_desktop_shell()


func clear_page() -> void:
	battle_view = state in ["travel", "battle"] and run != null and run.tactics != null
	battle_nodes.clear()
	ult_buttons.clear()
	ult_meters.clear()
	card_health.clear()
	super.clear_page()
	page.get_child(0).color = TaleTheme.c("surface")
	center_content()


func panel(parent: Node, rect: Rect2, color := TaleTheme.c("surface")) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	UISkin.decorate(node,false,false,0.055 if rect.size.y>0 and rect.size.y<90 else 0.15)
	register_layout(node)
	return node


func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary := false) -> Button:
	var node := Button.new()
	node.text = text
	node.clip_text = true
	node.position = rect.position
	node.size = Vector2(rect.size.x, maxf(44, rect.size.y))
	node.custom_minimum_size.y = 44
	node.add_theme_font_size_override("font_size", 18)
	BattleType.apply(node,true)
	node.add_theme_color_override("font_color", TaleTheme.c("muted") if primary else TaleTheme.c("text"))
	node.add_theme_color_override("font_disabled_color", TaleTheme.c("border"))
	node.add_theme_stylebox_override("normal", box(TaleTheme.c("surface") if primary else TaleTheme.c("surface"), TaleTheme.c("accent") if primary else TaleTheme.c("border"), 10))
	node.add_theme_stylebox_override("hover", box(TaleTheme.c("surface") if primary else TaleTheme.c("border"), GOLD, 10))
	node.add_theme_stylebox_override("pressed", box(TaleTheme.c("surface"), GOLD, 10))
	node.add_theme_stylebox_override("disabled", box(TaleTheme.c("surface"), TaleTheme.c("border"), 10))
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, GOLD, 8))
	node.set_meta("primary",primary)
	UISkin.decorate(node, true, true,0.10)
	node.pressed.connect(func():
		if is_instance_valid(audio):
			audio.play_effect("click")
		callback.call())
	parent.add_child(node)
	register_layout(node)
	return node


func header(title: String, subtitle: String) -> void:
	face_portrait(page, campaign.avatar, Rect2(24, 12, 48, 48))
	label(page, campaign.player_name, Rect2(84, 12, 220, 25), 16)
	label(page, "VIAJANTE · NÍVEL %d" % campaign.player_level, Rect2(84, 36, 236, 22), 10, MUTED)
	panel(page, Rect2(332, 14, 112, 42))
	label(page, "%s G" % format_gold(campaign.gold), Rect2(340, 18, 96, 32), 14, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := button(page, "", Rect2(458, 12, 58, 48), show_settings)
	icon(settings, "settings", Rect2(17, 12, 24, 24))
	label(page, title, Rect2(24, 80, 492, 48), 30)
	label(page, subtitle, Rect2(24, 133, 492, 31), 14, MUTED)

func show_menu() -> void:
	state = "menu"
	paused = false
	farm_timer = -1.0
	clear_page()
	header("Entre contos e destinos.", "Sua próxima página começa aqui.")
	var chapter := mini(campaign.cleared.size(), TaleCatalog.FINAL_CHAPTER)
	var hero_card := panel(page, Rect2(20, 184, 500, 405))
	hero_card.clip_contents = true
	UISkin.picture(hero_card, preload("res://assets/ui/storybook_battle.png"), Rect2(2, 2, 496, 401), true).modulate = Color(0.70, 0.76, 0.91)
	gradient(hero_card, Rect2(2, 2, 496, 401), TaleTheme.c("background", .08), TaleTheme.c("surface"))
	label(hero_card, "CAPÍTULO %02d / 12" % (chapter + 1), Rect2(22, 16, 300, 28), 12, GOLD)
	button(hero_card, "Editar", Rect2(376, 14, 102, 44), show_party)
	for index in campaign.party.size():
		var id: String = campaign.party[index]
		var x := 250.0 + (index - (campaign.party.size() - 1) * 0.5) * 142
		portrait_fitted(hero_card, id, Vector2(x, 282), 190)
	label(hero_card, "A JORNADA CONTINUA", Rect2(24, 291, 452, 23), 11, GOLD)
	label(hero_card, TaleCatalog.STAGES[chapter].name, Rect2(24, 319, 452, 60), 27)
	var title := "Continuar história" if campaign.pending_story >= 0 else ("Retomar expedição" if not campaign.checkpoint.is_empty() else "Entrar em batalha")
	var play := button(page, title + "   →", Rect2(24, 612, 492, 66), continue_journey, true)
	play.add_theme_font_size_override("font_size", 22)
	panel(page, Rect2(24, 704, 492, 116))
	icon(page, "chest", Rect2(42, 724, 34, 34))
	label(page, "PROVISÕES DO ACAMPAMENTO", Rect2(91, 716, 248, 24), 11, GOLD)
	idle_label = label(page, "", Rect2(91, 746, 240, 51), 15)
	idle_button = button(page, "Coletar", Rect2(354, 743, 144, 52), show_idle_rewards)
	update_idle_display()
	label(page, "%d / 12 contos concluídos   ·   %d / 12 personagens" % [campaign.cleared.size(), campaign.unlocked.size()], Rect2(24, 840, 492, 25), 12, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation("menu")

func show_map() -> void:
	state = "map"
	clear_page()
	header("Campanha", "%d / 12 capítulos concluídos" % campaign.cleared.size())
	var inner := scroll_area(190, 676, 1056)
	for index in TaleCatalog.CHAPTER_COUNT:
		var data: Dictionary = TaleCatalog.STAGES[index]
		var x := (index % 2) * 244.0
		var y := floori(index / 2.0) * 174.0
		var open := campaign.can_play(index)
		var done := campaign.cleared.has(index)
		var card := button(inner, "", Rect2(x, y, 232, 158), show_chapter.bind(index), open and not done)
		card.disabled = not open
		label(card, "%02d  %s" % [index + 1, "✓" if done else ("" if open else "· bloqueado")], Rect2(14, 10, 204, 23), 14, TaleTheme.c("surface") if open and not done else GOLD)
		label(card, data.name, Rect2(14, 43, 204, 62), 20, TaleTheme.c("surface") if open and not done else TaleTheme.c("text"))
		label(card, "Revisitar" if done else ("Entrar →" if open else "Conclua o anterior"), Rect2(14, 119, 204, 25), 13, TaleTheme.c("surface") if open and not done else MUTED)
	inner.get_parent().set_deferred("scroll_vertical", int(maxf(0, floori(mini(11, campaign.cleared.size()) / 2.0) * 174 - 120)))
	navigation("map")


func show_party() -> void:
	state = "party"
	clear_page()
	header("Formação", "Até 3 aliados · mantenha pelo menos uma na vanguarda.")
	label(page, "VANGUARDA", Rect2(270, 183, 246, 28), 13, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(page, "RETAGUARDA", Rect2(24, 183, 246, 28), 13, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for side in ["back", "front"]:
		var ids: Array[String] = []
		for id in campaign.party:
			if campaign.row_for(id) == side:
				ids.append(id)
		for slot in ids.size():
			var x := (132.0 if side == "back" else 396.0) + (slot - (ids.size() - 1) * 0.5) * 73
			portrait(page, ids[slot], Vector2(x, 365), 0.44)
	var inner := scroll_area(402, 463, TaleCatalog.HEROES.size() * 145)
	var index := 0
	for id in TaleCatalog.HEROES:
		var y := index * 145.0
		var owned := campaign.unlocked.has(id)
		var equipped := campaign.party.has(id)
		var profile: Dictionary = TaleCatalog.HERO_TACTICS[id]
		panel(inner, Rect2(0, y, 476, 133))
		label(inner, TaleCatalog.HEROES[id].name, Rect2(14, y + 8, 250, 29), 20)
		label(inner, TaleCatalog.hero_class_name(id), Rect2(14, y + 39, 275, 24), 14, MUTED)
		var join := button(inner, "Retirar" if equipped else ("Adicionar" if owned else "Ver requisito"), Rect2(305, y + 14, 156, 44), toggle_member.bind(id) if owned else show_unlock_details.bind(id), equipped)
		join.disabled = owned and (not campaign.checkpoint.is_empty() or (not equipped and campaign.party.size() >= 3) or (equipped and campaign.party.size() == 1))
		var row := campaign.row_for(id)
		var formation := button(inner, ("Frente → Fundo" if row == "front" else "Fundo → Frente") if equipped else "Fora da formação", Rect2(14, y + 76, 447, 44), switch_row.bind(id))
		formation.add_theme_font_size_override("font_size", 15)
		formation.disabled = not equipped or not campaign.checkpoint.is_empty()
		index += 1
	navigation("heroes")


func switch_row(id: String) -> void:
	if campaign.set_row(id, "back" if campaign.row_for(id) == "front" else "front"):
		persist()
		show_party()
	else:
		modal("Mantenha a linha de frente", "Coloque outra aliada na vanguarda antes de mover esta para a retaguarda.")
		button(overlay, "Voltar à formação", Rect2(32, 461, 476, 56), show_party, true)


func show_hero_details(id: String) -> void:
	super.show_hero_details(id)
	if state != "hero":
		return
	for child in page.get_children():
		if child is Label and child.has_meta("base_rect") and is_equal_approx(child.get_meta("base_rect").position.y, 422):
			child.queue_free()
	button(page, "Classe e ULT  ·  " + str(TaleCatalog.HERO_TACTICS[id].ult), Rect2(24, 430, 492, 44), show_tactical_details.bind(id)).add_theme_font_size_override("font_size", 16)


func show_tactical_details(id: String) -> void:
	var profile: Dictionary = TaleCatalog.HERO_TACTICS[id]
	var job: Dictionary = TaleCatalog.CLASSES[profile["class"]]
	modal(str(TaleCatalog.HEROES[id].name) + " · " + TaleCatalog.hero_class_name(id), str(job.rule))
	label(overlay, str(profile.ult), Rect2(32, 410, 476, 40), 26, GOLD)
	label(overlay, str(profile.detail) + "\n\nA ULT carrega ao lutar, acertar e sofrer dano. Toque no retrato ou use 1–3 no PC. Pode ativar o uso automático.", Rect2(32, 470, 476, 207), 20)
	button(overlay, "Voltar ao personagem", Rect2(32, 746, 476, 56), show_hero_details.bind(id), true)


func build_battle() -> void:
	combat_flow = null
	battle_history.clear()
	run.enable_tactics(campaign)
	state = "travel"
	paused = false
	game_speed = campaign.speed
	clear_page()
	cooldowns.clear()
	ally_bars.clear()
	ally_labels.clear()
	ally_clocks.clear()
	var header_frame := panel(page, Rect2(8, 6, 524, 50))
	header_frame.name="BattleHeader"
	battle_place(header_frame, Rect2(8, 6, 524, 50), Rect2(12, 5, 1256, 50))
	stage_label = label(page, "%02d / 12   %s" % [run.stage + 1, TaleCatalog.STAGES[run.stage].name], Rect2(20, 10, 412, 53), 20)
	battle_place(stage_label, Rect2(25, 16, 416, 28), Rect2(40, 16, 930, 28))
	BattleType.apply(stage_label,true)
	stage_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	stage_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	stage_label.clip_text=true
	var pause := button(page, "Ⅱ", Rect2(), toggle_pause)
	battle_place(pause, Rect2(454, 9, 66, 44), Rect2(1186, 8, 68, 44))
	enemy_label = label(page, "", Rect2(), 12, MUTED)
	enemy_label.visible = false
	power_label = label(page, "", Rect2(), 14, GOLD)
	power_label.visible = false
	battle_viewport = Control.new()
	battle_viewport.clip_contents = true
	page.add_child(battle_viewport)
	battle_place(battle_viewport, Rect2(0, 66, 540, 590), Rect2(12, 62, 984, 726))
	arena = Node2D.new()
	arena.set_script(TacticalArena)
	arena.simulation = run
	arena.stage = run.stage
	arena.speed = game_speed
	arena.reduced_motion = campaign.reduced_motion
	arena.high_quality = campaign.high_quality
	for id in run.actor_ids():
		arena.party_scenes.append(HERO_SCENES[id])
	battle_viewport.add_child(arena)
	var atmosphere:=preload("res://scripts/combat_atmosphere.gd").new()
	atmosphere.arena=arena
	atmosphere.reduced_motion=campaign.reduced_motion
	battle_viewport.add_child(atmosphere)
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.atmosphere=atmosphere
	UISkin.decorate(battle_viewport, false, true).z_index = 1600
	arena.attack_hit.connect(on_attack_hit)
	arena.attack_started.connect(on_attack_started)
	arena.enemy_attack_hit.connect(on_enemy_attack_hit)
	arena.status_requested.connect(show_condition_information)
	timeline = Control.new()
	page.add_child(timeline)
	timeline.visible = false
	timeline_key = ""
	# Preserve the action history, but no attacker banner covers the arena.
	action_label = label(page, "", Rect2(), 14, GOLD)
	action_label.visible = false
	action_label.z_index = 1701
	hero_deck_scroll=ScrollContainer.new()
	hero_deck_scroll.name="HeroDeck"
	hero_deck_scroll.scroll_deadzone=10
	hero_deck_scroll.set_script(preload("res://scripts/touch_scroll.gd"))
	page.add_child(hero_deck_scroll)
	battle_place(hero_deck_scroll,Rect2(16,0,508,156),Rect2(1008,62,258,622),"deck")
	hero_deck=Control.new()
	hero_deck_scroll.add_child(hero_deck)
	for index in run.actors.size():
		cooldowns.append(0.15 + index * 0.28)
		var actor: Dictionary = run.actors[index]
		var card := TeamCard.new()
		card.set_meta("theme_decoration",true)
		card.pressed.connect(try_ultimate.bind(index))
		hero_deck.add_child(card)
		var slot := int(index)
		card.set_meta("deck_index",slot)
		card.set_meta("hero_id",str(actor.id))
		var face := face_portrait(card, actor.id, Rect2(10,10,40,40))
		face.set_meta("card_face",true)
		face.set_meta("theme_decoration",true)
		face.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		card.add_theme_color_override("font_disabled_color", TaleTheme.c("text"))
		var information := Button.new()
		information.name="CharacterInformation"
		information.text="i"
		information.custom_minimum_size=Vector2(30,30)
		information.add_theme_font_size_override("font_size",20)
		information.add_theme_color_override("font_color",GOLD)
		information.set_meta("theme_decoration",true)
		for skin in ["normal","hover","pressed","disabled","focus"]:
			information.add_theme_stylebox_override(skin,StyleBoxEmpty.new())
		information.tooltip_text="Atributos, habilidades e passivas atuais"
		information.set_meta("card_info",true)
		information.pressed.connect(show_character_information.bind(index))
		card.add_child(information)
		for equipment_slot in 2:
			var equipped_id: String = ItemArt.equipped(actor,equipment_slot)
			var item_slot := ItemArt.slot(card, equipped_id, Rect2(18 + equipment_slot * 39, 110, 34, 34), show_equipment.bind(index, equipment_slot))
			item_slot.set_meta("card_items", equipment_slot)
			item_slot.set_meta("theme_square",true)
		var name_tag := label(card, str(TaleCatalog.HEROES[actor.id].get("short_name", TaleCatalog.HEROES[actor.id].name)), Rect2(58, 6, 94, 43), 14)
		name_tag.set_meta("card_name", true)
		name_tag.set_meta("theme_font", TeamCard.SERIF)
		name_tag.set_meta("full_name",name_tag.text)
		name_tag.set_meta("short_name",{"snow_white":"Branca","puss":"Gato","matches":"Fósforos"}.get(actor.id,name_tag.text))
		name_tag.autowrap_mode=TextServer.AUTOWRAP_OFF
		name_tag.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		name_tag.clip_text=true
		var ult_tag := label(card, str(TaleCatalog.HERO_TACTICS[actor.id].ult), Rect2(10, 101, 140, 21), 12, GOLD)
		ult_tag.set_meta("card_ult", true)
		ult_tag.set_meta("theme_font",TeamCard.SERIF)
		ult_tag.add_theme_font_size_override("font_size",16)
		var status := label(card, "", Rect2(10, 123, 140, 19), 11, MUTED)
		status.set_meta("card_status", true)
		status.tooltip_text = ult_tag.text
		status.accessibility_description = ult_tag.text
		var italic := FontVariation.new()
		italic.base_font = TeamCard.SERIF
		italic.variation_transform = Transform2D(Vector2(1,0),Vector2(-.18,1),Vector2.ZERO)
		status.set_meta("theme_font",italic)
		status.add_theme_font_size_override("font_size",16)
		var hp_text := label(card, "", Rect2(10, 48, 140, 19), 10, TaleTheme.c("accent"))
		hp_text.set_meta("card_hp", true)
		hp_text.set_meta("theme_text_role","combat_text")
		hp_text.set_meta("bar_number",true)
		hp_text.set_meta("theme_font",TeamCard.SERIF)
		hp_text.add_theme_font_override("font",TeamCard.SERIF)
		hp_text.set_meta("bar_outline_size",2)
		hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_text.z_index = 2
		hp_text.autowrap_mode=TextServer.AUTOWRAP_OFF
		var hp := ResourceBar.new()
		hp.health = true
		card.add_child(hp)
		hp.set_meta("card_hp_bar", true)
		hp.set_meta("health_bar",true)
		hp.set_meta("theme_radius",12)
		card.move_child(hp,0)
		var shield_text := label(card,"",Rect2(),16)
		shield_text.set_meta("card_shield",true)
		shield_text.set_meta("theme_text_role","combat_text")
		shield_text.set_meta("bar_number",true)
		shield_text.set_meta("theme_font",TeamCard.SERIF)
		shield_text.add_theme_font_override("font",TeamCard.SERIF)
		shield_text.set_meta("bar_outline_size",2)
		shield_text.z_index = 2
		shield_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield_text.autowrap_mode = TextServer.AUTOWRAP_OFF
		var shield_icon := UISkin.picture(card,preload("res://assets/ui/team_shield.svg"),Rect2())
		shield_icon.set_meta("card_shield_icon",true)
		shield_icon.set_meta("theme_decoration",true)
		shield_icon.z_index = 2
		card_health.append(hp)
		var mana_text := label(card, "", Rect2(10, 76, 140, 17), 11, TaleTheme.c("accent"))
		mana_text.set_meta("card_mana", true)
		mana_text.set_meta("theme_text_role","combat_text")
		mana_text.set_meta("bar_number",true)
		mana_text.set_meta("theme_font",TeamCard.SERIF)
		mana_text.add_theme_font_override("font",TeamCard.SERIF)
		mana_text.set_meta("bar_outline_size",2)
		mana_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mana_text.autowrap_mode = TextServer.AUTOWRAP_OFF
		mana_text.z_index = 2
		var meter := ResourceBar.new()
		card.add_child(meter)
		meter.set_meta("card_mana_bar", true)
		meter.set_meta("theme_bar_role","mana")
		meter.set_meta("theme_radius",12)
		card.move_child(meter,0)
		ult_meters.append(meter)
		ult_buttons.append(card)
		card.update_theme()
	log_label = label(page, "", Rect2(), 12, MUTED)
	log_label.visible = false # Complete history remains available through Histórico.
	auto_button = button(page, "", Rect2(), toggle_auto_ult)
	battle_place(auto_button, Rect2(16, 0, 246, 46), Rect2(1008, 694, 258, 44), "bottom")
	speed_button = button(page, "%d×" % TaleCampaign.speed_label(game_speed), Rect2(), toggle_speed)
	battle_place(speed_button, Rect2(278, 0, 246, 46), Rect2(1008, 744, 258, 44), "bottom")
	var gold_box := panel(page, Rect2())
	gold_box.name="BattleGoldBox"
	for child in gold_box.get_children():child.queue_free()
	gold_box.add_theme_stylebox_override("panel",box(TaleTheme.c("surface"),TaleTheme.c("accent"),8))
	gold_box.z_index=1800
	battle_place(gold_box,Rect2(16,78,166,36),Rect2(26,76,170,38),"gold")
	battle_gold=label(page,"",Rect2(),15,GOLD)
	battle_gold.name="BattleGold"
	battle_gold.z_index=1801
	BattleType.apply(battle_gold,true)
	battle_gold.autowrap_mode=TextServer.AUTOWRAP_OFF
	battle_gold.clip_text=true
	battle_place(battle_gold,Rect2(50,82,124,28),Rect2(62,81,124,28),"gold_text")
	var coin:=UISkin.picture(page,preload("res://scripts/status_art.gd").texture("coin"),Rect2())
	coin.name="BattleCoin"
	coin.z_index=1801
	battle_place(coin,Rect2(20,82,28,28),Rect2(30,81,28,28),"gold_coin")
	reward_return = button(page,"Escolher melhoria  →",Rect2(),show_relics)
	reward_return.name = "ReturnToReward"
	reward_return.visible = false
	reward_return.z_index = 1800
	battle_place(reward_return,Rect2(278,76,246,44),Rect2(700,74,280,44),"reward_return")
	relayout_battle()
	update_hud()

func battle_place(node: Control, mobile: Rect2, pc: Rect2, kind := "fixed") -> void:
	node.set_meta("mobile_rect", mobile)
	node.set_meta("pc_rect", pc)
	node.set_meta("battle_kind", kind)
	battle_nodes.append(node)


func relayout_battle() -> void:
	if not battle_view:
		return
	for node in battle_nodes:
		if not is_instance_valid(node):
			continue
		var rect: Rect2 = node.get_meta("pc_rect" if desktop else "mobile_rect")
		if not desktop:
			match str(node.get_meta("battle_kind")):
				"deck":
					rect.position.y = logical_height - 274
					rect.size.y = 200

				"bottom": rect.position.y = logical_height - 67
			if node == battle_viewport:
				rect.size.y = logical_height - 346
		if node.has_meta("desktop_fullscreen"):node.visible=desktop
		node.position = rect.position
		node.size = rect.size
	if is_instance_valid(hero_deck_scroll):
		hero_deck_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED if desktop else ScrollContainer.SCROLL_MODE_AUTO
		hero_deck_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if desktop else ScrollContainer.SCROLL_MODE_DISABLED
		hero_deck.custom_minimum_size=Vector2(242,maxf(622,ult_buttons.size()*154)) if desktop else Vector2(maxf(508,ult_buttons.size()*390-14),192)
	for card in ult_buttons:
		var at:int=card.get_meta("deck_index",0)
		card.position=Vector2(0,at*154) if desktop else Vector2(at*390,0)
		card.size=Vector2(242,146) if desktop else Vector2(376,192)
		card.layout_fields()
	if is_instance_valid(stage_label):BattleType.fit_line(stage_label,20 if desktop else 14,9,stage_label.get_meta("pc_rect" if desktop else "mobile_rect").size)
	if is_instance_valid(battle_gold):BattleType.fit_line(battle_gold,15)
	if is_instance_valid(arena) and arena.get_script() == TacticalArena:
		arena.fit_field(battle_viewport.size)
	if is_instance_valid(feedback):
		feedback.size = battle_viewport.size
		feedback.layout()
	if is_instance_valid(equipment_panel):equipment_panel.size=Vector2(logical_width,logical_height)
	if is_instance_valid(overlay):
		if overlay.has_meta("character_inspector") or overlay.has_meta("reward_modal"):
			overlay.position=Vector2.ZERO
			overlay.size=Vector2(logical_width,logical_height)
			if overlay.has_meta("reward_modal"): overlay.layout()
		else:overlay.position.x = (logical_width - 540) * 0.5


func update_hud() -> void:
	if not battle_view or run == null or run.tactics == null:
		return
	if not is_instance_valid(enemy_label):
		return
	var living := 0
	for foe in run.tactics.enemies:
		if foe.hp > 0:
			living += 1
	enemy_label.text = "ENCONTRO %d / 3   ·   %s" % [run.wave + 1, "CHEFE" if run.wave == 2 else "ESCARAMUÇA"]
	power_label.text = "%d aliados   ×   %d inimigos" % [run.actors.filter(func(unit): return unit.hp > 0).size(), living]
	for index in mini(ult_buttons.size(), run.actors.size()):
		var actor: Dictionary = run.actors[index]
		ult_meters[index].max_value=4 if run.expedition and actor.id=="alice" else maxf(1,run.tactics.Rules.cost(actor))
		ult_meters[index].value = actor.get("card_charge",0) if run.expedition and actor.id=="alice" else actor.energy
		if actor.id=="aladin":
			ult_meters[index].max_value = 4 if run.tactics.Rules.boon(actor,2) else 3
			ult_meters[index].value = run.tactics.Rules.wishes_left(actor)
		card_health[index].call("set_unit",actor)
		ult_buttons[index].set_meta("shield_present",actor.shield>0)
		ult_buttons[index].layout_fields()
		for child in ult_buttons[index].get_children():
			if child.has_meta("card_status"):
				child.text = "Caído" if actor.hp <= 0 else ("ULT na fila" if actor.get("ult_queued", false) else ("ULT em ação" if actor.ult_pending else ("ULT pronta" if run.tactics.ultimate_ready(index) else ("Selada" if actor.get("sealed", false) else "Aguardando"))))
			elif child.has_meta("card_hp"):
				child.text = "%d / %d" % [ceili(actor.hp), ceili(actor.max_hp)]
				child.size.x = card_health[index].size.x
				BattleType.fit_line(child,maxi(18,ceili(13.0/content.scale.x)),maxi(13,ceili(13.0/content.scale.x)),child.size)
			elif child.has_meta("card_shield"):
				child.text = str(ceili(actor.shield))
				child.visible = actor.shield>0
				child.tooltip_text = "%d de escudo" % ceili(actor.shield)
				BattleType.fit_line(child,maxi(15,ceili(13.0/content.scale.x)),maxi(13,ceili(13.0/content.scale.x)),child.size)
			elif child.has_meta("card_shield_icon"):
				child.visible = actor.shield>0
				child.modulate = TaleTheme.c("combat_text")
			elif child.has_meta("card_items"):
				var equipment_slot: int = child.get_meta("card_items")
				ItemArt.refresh(child, ItemArt.equipped(actor,equipment_slot))
			elif child.has_meta("card_mana"):
				child.text = "%d / %d" % [int(ult_meters[index].value),int(ult_meters[index].max_value)]
				if actor.id not in ["alice","aladin"]:
					child.text = "%s / %s" % [str(snappedf(actor.energy,.1)).trim_suffix(".0"),str(run.tactics.Rules.cost(actor)).trim_suffix(".0")]
				BattleType.fit_line(child,maxi(18,ceili(13.0/content.scale.x)),maxi(13,ceili(13.0/content.scale.x)),child.size)
		ult_buttons[index].disabled = paused or state != "battle" or actor.hp <= 0 or not run.tactics.ultimate_ready(index) or actor.ult_pending or actor.get("ult_queued", false) or arena.tracks[index].time >= 0
		if actor.id=="aladin":
			ult_buttons[index].disabled=paused or state!="battle" or run.tactics.Rules.wishes_left(actor)<=0
			for child in ult_buttons[index].get_children():
				if child.has_meta("card_status"):
					child.text="Usar desejos" if run.tactics.Rules.wishes_left(actor)>0 else "Esgotados"
					child.add_theme_color_override("font_color",GOLD)
		for child in ult_buttons[index].get_children():
			if child.has_meta("card_status"): child.accessibility_name = child.text
		ult_buttons[index].tooltip_text = "%s · %s\n%s" % [TaleCatalog.HERO_TACTICS[actor.id].ult, ("%d/4 cartas"%int(actor.get("card_charge",0))) if run.expedition and actor.id=="alice" else run.tactics.Rules.resource(actor), TaleCatalog.HERO_TACTICS[actor.id].detail]
	if is_instance_valid(auto_button):
		auto_button.text = "AUTO ULT  " + ("ON" if campaign.auto_ult else "OFF")
	if is_instance_valid(action_label) and is_instance_valid(log_label):
		action_label.text = battle_last_action
	refresh_timeline()
	arena.sync_health(run.actors)


func register_layout(node: Control, kind := "auto") -> void:
	if battle_view and node.get_parent() == page:
		return
	super.register_layout(node, kind)


func relayout_page() -> void:
	if battle_view:
		if is_instance_valid(page):
			page.size = Vector2(logical_width, logical_height)
			if page.get_child_count() > 0:
				page.get_child(0).size = page.size
		relayout_battle()
		if is_instance_valid(overlay):
			for child in overlay.get_children():
				if child is Control:
					place_control(child)
	else:
		super.relayout_page()


func modal(title: String, subtitle: String) -> void:
	super.modal(title, subtitle)
	overlay.position.x = (logical_width - 540.0) * 0.5
	var shade: ColorRect = overlay.get_child(0)
	shade.remove_meta("base_rect")
	shade.position.x = -overlay.position.x
	shade.size = Vector2(logical_width, logical_height)
	shade.color = TaleTheme.c("background", .96)


func toggle_auto_ult() -> void:
	campaign.auto_ult = not campaign.auto_ult
	persist()
	update_hud()


func show_settings() -> void:
	super.show_settings()
	var scroll: ScrollContainer
	for child in page.get_children():
		if child is ScrollContainer:
			scroll = child
	if scroll == null:
		return
	var inner: Control = scroll.get_child(0)
	inner.custom_minimum_size.y = 1770
	button(inner, "AUTO ULT  " + ("ON" if campaign.auto_ult else "OFF"), Rect2(0, 1430, 476, 52), settings_auto_ult)
	button(inner, "Tela cheia / Janela  ·  F11", Rect2(0, 1500, 476, 52), toggle_fullscreen).disabled = OS.has_feature("mobile")
	var reset := button(inner, "Resetar conta deste dispositivo", Rect2(0, 1600, 476, 56), request_reset)
	reset.add_theme_color_override("font_color", TaleTheme.c("accent"))
	if debug_tools_allowed():button(inner,"Ferramentas DEBUG",Rect2(0,1680,476,52),open_debug_tools)


func open_debug_tools() -> void:
	if not debug_tools_allowed():return
	debug_enabled=true
	show_debug_panel()

func settings_auto_ult() -> void:
	campaign.auto_ult = not campaign.auto_ult
	persist()
	show_settings()


func request_reset() -> void:
	modal("Recomeçar do zero?", "Isso apaga neste dispositivo: ouro, EXP, personagens, capítulos, conquistas, formação, preferências e saves de recuperação. Você recomeça com a Chapeuzinho. Esta ação não pode ser desfeita.")
	reset_confirm = button(overlay, "Apagar progresso e recomeçar", Rect2(32, 500, 476, 60), confirm_reset)
	reset_confirm.add_theme_color_override("font_color", TaleTheme.c("accent"))
	button(overlay, "Cancelar", Rect2(32, 590, 476, 56), show_settings, true)


func confirm_reset() -> void:
	if not TaleCampaign.reset_account(save_path):
		modal("Não foi possível resetar", "Não foi possível substituir o save e a cópia de recuperação. Tente novamente.")
		button(overlay, "Voltar", Rect2(32, 500, 476, 56), show_settings)
		return
	run = null
	campaign = TaleCampaign.new()
	campaign.load_from(save_path)
	ui_theme.switch_to(campaign.ui_theme)
	paused = false
	selected_hero = "scarlet"
	debug_enabled = false
	apply_preferences()
	apply_window_mode()
	show_menu()


var windowed_size:=Vector2i(1280,720)
var windowed_position:=Vector2i.ZERO
var fullscreen_host: Window
var last_window_key:=0
func hook_window_keys(window: Window) -> void:
	if not window.window_input.is_connected(window_hotkeys):window.window_input.connect(window_hotkeys)
func window_hotkeys(event: InputEvent) -> void:
	if handle_window_key(event):get_viewport().set_input_as_handled()
func handle_window_key(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:return false
	if KEY_F11 not in [event.keycode,event.physical_keycode,event.key_label]:return false
	if last_window_key!=event.get_instance_id():
		last_window_key=event.get_instance_id()
		toggle_fullscreen()
	return true
func apply_window_mode() -> void:
	if OS.has_feature("mobile") or DisplayServer.get_name()=="headless":return
	hook_window_keys(get_tree().root)
	# The engine consumes --wid before get_cmdline_args(), so inspecting it never
	# detected the embedded Game view. Editor binaries always use our native host.
	if OS.has_feature("editor") or is_instance_valid(fullscreen_host):
		apply_embedded_fullscreen.call_deferred()
		return
	set_game_window_mode(get_window())
	if not get_tree().process_frame.is_connected(finalize_window_mode):get_tree().process_frame.connect(finalize_window_mode,CONNECT_ONE_SHOT)
func set_game_window_mode(window: Window) -> void:
	if campaign.window_mode=="fullscreen":
		if window.mode==Window.MODE_WINDOWED:
			windowed_size=window.size
			windowed_position=window.position
		window.mode=Window.MODE_FULLSCREEN
	else:
		var was_fullscreen:=window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
		window.mode=Window.MODE_WINDOWED
		if was_fullscreen:
			window.size=windowed_size
			window.position=windowed_position
func finalize_window_mode() -> void:
	if campaign.window_mode=="fullscreen" and DisplayServer.get_name()!="headless":get_window().mode=Window.MODE_FULLSCREEN
func apply_embedded_fullscreen() -> void:
	if not is_instance_valid(fullscreen_host):
		fullscreen_host=Window.new()
		fullscreen_host.hide()
		fullscreen_host.title="RogueTales"
		fullscreen_host.force_native=true
		fullscreen_host.transient=false
		fullscreen_host.current_screen=get_tree().root.current_screen
		fullscreen_host.size=windowed_size
		fullscreen_host.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		fullscreen_host.content_scale_size=Vector2i(1280,720)
		get_tree().root.add_child(fullscreen_host)
		reparent(fullscreen_host)
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fullscreen_host.close_requested.connect(func():persist();get_tree().quit())
		hook_window_keys(fullscreen_host)
		fullscreen_host.show()
		fullscreen_host.move_to_center()
	set_game_window_mode(fullscreen_host)
	fullscreen_host.grab_focus()
	if not get_tree().process_frame.is_connected(finalize_window_mode):get_tree().process_frame.connect(finalize_window_mode,CONNECT_ONE_SHOT)
func toggle_fullscreen() -> void:
	if OS.has_feature("mobile"):return
	var actual_fullscreen:=get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
	if DisplayServer.get_name()=="headless":actual_fullscreen=campaign.window_mode=="fullscreen"
	campaign.window_mode="windowed" if actual_fullscreen else "fullscreen"
	campaign.window_mode_selected=true
	apply_window_mode()
	persist()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if handle_window_key(event):
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(equipment_panel):
			if key == KEY_ESCAPE:
				if is_instance_valid(equipment_panel.transfer_prompt):equipment_panel.cancel_transfer()
				else:close_equipment()
			get_viewport().set_input_as_handled()
			return
		if state in ["battle", "travel", "route_travel", "encounter_intro", "battle_outro"] and not event.ctrl_pressed:
			if key == KEY_SPACE:
				toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if key>=KEY_1 and key<=KEY_9:
				try_ultimate(int(key - KEY_1))
				get_viewport().set_input_as_handled()
				return
			if key == KEY_A:
				toggle_auto_ult()
				get_viewport().set_input_as_handled()
				return
	super._input(event)


func update_desktop_shell() -> void:
	if is_instance_valid(desktop_shell):
		desktop_shell.queue_free()
		desktop_shell = null
	if not desktop or battle_view or campaign == null or not is_instance_valid(page):
		return
	var factor := content.scale.x
	var extra: float = (size.x - content.size.x * factor) / factor * 0.5
	if extra < 210:
		return
	desktop_shell = Control.new()
	desktop_shell.position = Vector2(content.position.x - 215 * factor, content.position.y)
	desktop_shell.scale = Vector2.ONE * factor
	add_child(desktop_shell)
	label(desktop_shell, "ROGUETALES", Rect2(0, 52, 190, 40), 22, GOLD)
	label(desktop_shell, "O ÚLTIMO FIO", Rect2(0, 98, 190, 26), 12, MUTED)
	var links := [["Início", show_menu], ["Campanha", show_map], ["Heróis", show_heroes], ["Perfil", show_profile], ["Configurações", show_settings]]
	for index in links.size():
		button(desktop_shell, links[index][0], Rect2(0, 192 + index * 67, 187, 48), links[index][1])
	var right := 770.0
	label(desktop_shell, "SUA JORNADA", Rect2(right, 190, 190, 35), 16, GOLD)
	label(desktop_shell, "%02d / 12 capítulos\n\n%d personagens\n\nNível de conta %d" % [campaign.cleared.size(), campaign.unlocked.size(), campaign.player_level], Rect2(right, 247, 190, 210), 18, MUTED)
	label(desktop_shell, "NO COMBATE\n\n1–3  ULT\nEspaço  Pausa\nA  ULT automática\nF11  Tela cheia", Rect2(right, 528, 190, 240), 15, MUTED)


func icon(parent: Node, glyph: String, rect: Rect2, tint := TaleTheme.c("accent")) -> Control:
	var node := Control.new()
	node.set_script(MobileIcon)
	node.glyph = glyph
	node.tint = tint
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	register_layout(node)
	return node


func gradient(parent: Node, rect: Rect2, top: Color, bottom: Color) -> void:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([top, bottom])
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_from = Vector2(0,0)
	texture.fill_to = Vector2(0,1)
	UISkin.picture(parent, texture, rect).stretch_mode = TextureRect.STRETCH_SCALE


func portrait_slot(parent: Node, rect: Rect2) -> Control:
	var slot:=Panel.new()
	slot.position=rect.position
	slot.size=rect.size
	slot.clip_contents=true
	slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel",box(TaleTheme.c("surface"),TaleTheme.c("border", .65),9))
	parent.add_child(slot)
	register_layout(slot)
	return slot

func face_portrait(parent: Node,id: String,rect: Rect2) -> Control:
	var slot := portrait_slot(parent, rect)
	preload("res://scripts/hero_art.gd").place_head(slot,id)
	return slot


func portrait_fitted(parent: Node, id: String, at: Vector2, height: float) -> void:
	cache_portrait(id)
	var data: Dictionary = static_portraits[id]
	var actual: float = data.bounds.size.y * data.scale.y
	portrait(parent,id,at,height/maxf(1,actual))


func navigation(active: String) -> void:
	panel(page, Rect2(16, 882, 508, 68))
	var entries: Array = [["menu", "Início", "home", show_menu], ["map", "Contos", "map", show_map], ["heroes", "Heróis", "heroes", show_heroes], ["journal", "Diário", "book", show_journal], ["profile", "Perfil", "profile", show_profile]]
	for index in entries.size():
		var entry: Array = entries[index]
		var selected: bool = active == entry[0]
		var item := button(page, "", Rect2(22 + index * 100, 887, 96, 58), entry[3])
		item.add_theme_stylebox_override("normal", box(TaleTheme.c("surface") if selected else Color.TRANSPARENT, Color.TRANSPARENT, 12))
		icon(item, entry[2], Rect2(37, 6, 22, 22), GOLD if selected else TaleTheme.c("muted"))
		label(item, entry[1], Rect2(0, 32, 96, 22), 11, GOLD if selected else MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_heroes() -> void:
	state = "heroes"
	clear_page()
	header("Personagens", "%d / 12 recrutados · escolha quem escreverá seu conto." % campaign.unlocked.size())
	button(page, "Todos", Rect2(24, 182, 154, 48), filter_roster.bind("all"), roster_filter == "all")
	button(page, "Recrutados", Rect2(188, 182, 158, 48), filter_roster.bind("owned"), roster_filter == "owned")
	var ids: Array = TaleCatalog.HEROES.keys().filter(func(id): return roster_filter == "all" or campaign.unlocked.has(id))
	var inner := scroll_area(247, 620, ceili(ids.size()/2.0)*284)
	for index in ids.size():
		var id: String = ids[index]
		var data: Dictionary = TaleCatalog.HEROES[id]
		var owned := campaign.unlocked.has(id)
		var x := (index % 2) * 244.0
		var y := floori(index/2.0) * 284
		var card := button(inner, "", Rect2(x,y,232,272), show_hero_details.bind(id) if owned else show_unlock_details.bind(id))
		card.add_theme_stylebox_override("normal", box(TaleTheme.c("surface") if owned else TaleTheme.c("surface"), TaleTheme.c("border", .55 if owned else .22), 18))
		gradient(card, Rect2(2,2,228,180), TaleTheme.c("accent", .17), TaleTheme.c("accent", 0))
		label(card, "NÍVEL %02d" % campaign.hero_levels[id] if owned else "VÍNCULO A DESCOBRIR", Rect2(14,10,204,24), 10, data.color)
		portrait_fitted(card, id, Vector2(116,183), 156)
		label(card, data.get("short_name", data.name), Rect2(14,187,204,34), 19, TaleTheme.c("text") if owned else MUTED)
		label(card, TaleCatalog.hero_class_name(id), Rect2(14,225,204,22), 12, data.color)
		var progress := bar(card, Rect2(14,254,204,5), data.color)
		progress.max_value = 30 if owned else TaleCatalog.UNLOCKS[id].goal
		progress.value = campaign.hero_levels[id] if owned else campaign.unlock_amount(id)
	navigation("heroes")


func filter_roster(value: String) -> void:
	roster_filter = value
	show_heroes()


func refresh_timeline() -> void:
	if run != null and run.expedition:return
	if combat_flow == null or not is_instance_valid(timeline):
		return
	var upcoming: Array = combat_flow.preview()
	var key := str(combat_flow.round_number) + str(upcoming) + str(combat_flow.active)
	if key == timeline_key:
		return
	timeline_key = key
	for child in timeline.get_children():
		child.queue_free()
	var tag := label(timeline, "RODADA %02d" % combat_flow.round_number, Rect2(0,0,94,44), 11, GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for at in mini(5, upcoming.size()):
		var entry: Dictionary = upcoming[at]
		var unit: Dictionary = combat_flow.unit(entry)
		var x := 104 + at * 79.0
		var tint := TaleTheme.c("accent") if entry.side == "ally" else TaleTheme.c("accent")
		if entry.side == "ally":
			face_portrait(timeline, unit.id, Rect2(x,3,34,36))
		else:
			icon(timeline, "sword", Rect2(x,8,26,26), tint)
		label(timeline, "%d×" % int(unit.get("ap",unit.get("attacks",1))), Rect2(x+38,8,36,24), 10, tint)


func current_action(message: String) -> void:
	battle_last_action = message
	if is_instance_valid(action_label): action_label.text = message

func push_battle_log(message: String) -> void:
	var seconds := int(run.tactics.elapsed) if run != null and run.tactics != null else 0
	battle_history.append("%02d:%02d  %s" % [seconds / 60, seconds % 60, message])
	if battle_history.size() > 150: battle_history.pop_front()
	if is_instance_valid(log_label): log_label.text = "\n".join(battle_history.slice(maxi(0, battle_history.size() - 4)))

func consume_feedback() -> void:
	if run == null or run.tactics == null: return
	for event in run.tactics.feedback_events:
		if is_instance_valid(arena): arena.passive_effect(event)
		if is_instance_valid(feedback): feedback.enqueue(event)
		var hero_id:=str(event.get("hero","")).trim_prefix("item_")
		var source_name:String=str(TaleCatalog.HEROES[hero_id].name) if TaleCatalog.HEROES.has(hero_id) else str(event.get("source_name","Efeito de combate"))
		push_battle_log("%s · %s · %s" % [source_name,event.get("title","Efeito"),event.get("detail","")])
	run.tactics.feedback_events.clear()

func show_battle_history() -> void:
	if state not in ["battle", "travel"]: return
	paused = true
	arena.frozen = true
	if is_instance_valid(feedback): feedback.frozen = true
	modal("Histórico da batalha", "Ataques, dano, cura, escudos, ULTs e passivas deste encontro.")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(32, 385)
	scroll.size = Vector2(476, 350)
	overlay.add_child(scroll)
	register_layout(scroll, "center")
	var text := Label.new()
	text.custom_minimum_size = Vector2(450, 0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	text.text = "\n\n".join(battle_history) if not battle_history.is_empty() else "A equipe está a caminho."
	scroll.add_child(text)
	button(overlay, "Continuar", Rect2(32, 776, 476, 58), resume_battle, true)


func record_result(hit: Dictionary, hostile: bool, index: int, before: Array) -> void:
	var name: String = str(run.tactics.enemies[index].name) if hostile else str(TaleCatalog.HEROES[run.actors[index].id].name)
	var skill: String = str(hit.get("message", "Ataque"))
	if hostile and skill.is_empty(): skill = "Ataque"
	var parts: Array[String] = []
	for target in hit.get("targets", [hit.get("target", -1)]):
		if target < 0: continue
		var target_name: String = str(TaleCatalog.HEROES[run.actors[target].id].get("short_name", TaleCatalog.HEROES[run.actors[target].id].name)) if hostile else str(run.tactics.enemies[target].name)
		var damage: float = hit.get("target_damage", {}).get(target, hit.get("damage", 0))
		var evaded: bool = hit.get("target_evaded", {}).get(target, hit.get("evaded", false))
		parts.append("%s: %s" % [target_name, "esquiva" if evaded else "−%d PV" % ceili(damage)])
	push_battle_log("%s · %s%s" % [name, skill, " → " + "; ".join(parts) if not parts.is_empty() else ""])
	for at in mini(before.size(), run.actors.size()):
		var actor: Dictionary = run.actors[at]
		var received := 0.0
		if hostile:
			received = float(hit.get("target_damage", {}).get(at, hit.get("damage", 0) if hit.get("target", -1) == at else 0))
		var healed: float = maxf(0, actor.hp - float(before[at].hp) + received)
		var shield: float = maxf(0, actor.shield - float(before[at].shield))
		if healed > 0:
			push_battle_log("%s recuperou %d PV" % [TaleCatalog.HEROES[actor.id].name, ceili(healed)])
			arena.damage_number("+%d PV" % ceili(healed), arena.tracks[at].home + Vector2(0, 30), TaleTheme.c("accent"))
		if shield > 0:
			push_battle_log("%s ganhou %d de escudo" % [TaleCatalog.HEROES[actor.id].name, ceili(shield)])
			arena.damage_number("+%d ESCUDO" % ceili(shield), arena.tracks[at].home + Vector2(0, 58), TaleTheme.c("accent"))
	if hit.get("absorbed", 0) > 0: push_battle_log("O escudo absorveu %d de dano" % ceili(hit.absorbed))

var information_was_paused := false
func show_character_information(index: int) -> void:
	if run==null or index<0 or index>=run.actors.size(): return
	information_was_paused=paused
	paused=true
	arena.frozen=true
	if is_instance_valid(overlay):overlay.queue_free()
	var inspector:=preload("res://scripts/character_inspector.gd").new()
	overlay=inspector
	content.add_child(inspector)
	inspector.size=Vector2(logical_width,logical_height)
	inspector.setup(self,run.actors[index])

func close_character_information() -> void:
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=null
	paused=information_was_paused
	if is_instance_valid(arena): arena.frozen=paused

func show_condition_information(index: int, hostile: bool) -> void:
	if not hostile:
		show_character_information(index)
		return
	if run==null or index<0 or index>=run.tactics.enemies.size(): return
	var data: Dictionary=run.tactics.enemies[index]
	information_was_paused=paused
	paused=true
	arena.frozen=true
	modal(str(data.name),"Condições atuais")
	var description := ""
	var conditions:=preload("res://scripts/status_art.gd").active(data,true)
	for kind in conditions:
		description+=preload("res://scripts/status_art.gd").description(kind,conditions[kind][0],conditions[kind][1])+"\n\n"
	label(overlay,description if not description.is_empty() else "Sem condições ativas.",Rect2(32,336,476,350),22)
	button(overlay,"Voltar ao combate",Rect2(32,768,476,58),close_character_information,true)

func show_equipment(index: int=0, slot_index: int=0) -> void:
	if run==null or not run.expedition or is_instance_valid(equipment_panel):return
	equipment_was_paused=paused
	paused=true
	if is_instance_valid(arena):arena.frozen=true
	if is_instance_valid(feedback):feedback.frozen=true
	equipment_panel=Control.new()
	equipment_panel.set_script(preload("res://scripts/equipment_panel.gd"))
	equipment_panel.size=Vector2(logical_width,logical_height)
	content.add_child(equipment_panel)
	equipment_panel.setup(self,index,slot_index)
func close_equipment() -> void:
	if is_instance_valid(equipment_panel):equipment_panel.queue_free()
	equipment_panel=null
	paused=equipment_was_paused
	if is_instance_valid(arena):arena.frozen=paused
	if is_instance_valid(feedback):feedback.frozen=paused
	update_hud()
func equip_from_panel(index: int,id: String,slot: int) -> void:
	if run.equip_item(index,id,slot):
		if has_method("persist_run"):call("persist_run")
		equipment_panel.selected_slot = slot
		equipment_panel.rebuild()
		update_hud()
