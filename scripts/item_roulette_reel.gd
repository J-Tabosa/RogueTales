extends Control
## Presentation only: the selected item is already recorded in the run.
const ItemArt := preload("res://scripts/item_art.gd")
const Gear := preload("res://scripts/equipment.gd")

const TILE_SIZE := 112.0
const PITCH := 124.0
const VISIBLE_TILES := 6
const FAST_STEPS := 32.0
const STOP_STEP := 62.0
const FAST_TIME := 1.25
const SLOW_TIME := 3.5
const HOLD_TIME := 0.3

var cursor := 0.0
var winner := ""
var pool: Array[String] = []
var tiles: Array[Panel] = []
var art: Array[TextureRect] = []
var plates: Array[StyleBoxFlat] = []
var animation: Tween

func setup(item_id: String, excluded: Array) -> void:
	winner = item_id
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name = "ItemRouletteReel"
	var candidates := Gear.ITEMS.keys().filter(func(id): return id != winner and not excluded.has(id))
	var visual_random := RandomNumberGenerator.new()
	visual_random.seed = hash(winner)
	# Reuse a short strip instead of loading the whole catalog of full-size textures.
	for index in mini(12, candidates.size()):
		pool.append(candidates.pop_at(visual_random.randi_range(0, candidates.size() - 1)))
	for rank in Gear.RARITIES.size():
		plates.append(ItemArt.roulette_plate(rank))
	# Warm the icon cache before the fast stretch to avoid loading during a frame.
	for id in pool:
		ItemArt.texture(id)
	ItemArt.texture(winner)
	for index in VISIBLE_TILES:
		var tile := Panel.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tile)
		tiles.append(tile)
		art.append(ItemArt.picture(tile, "", Rect2(8, 8, 96, 96)))
	move_strip(0.0)

func play(finished: Callable) -> void:
	animation = create_tween()
	animation.tween_method(move_strip, 0.0, FAST_STEPS, FAST_TIME).set_trans(Tween.TRANS_LINEAR)
	# Cubic-out starts at almost the same speed as the linear stretch, then settles.
	animation.tween_method(move_strip, FAST_STEPS, STOP_STEP, SLOW_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_interval(HOLD_TIME)
	animation.tween_callback(finished)

func stop() -> void:
	if animation != null and animation.is_valid(): animation.kill()

func move_strip(value: float) -> void:
	cursor = value
	var whole := floori(value)
	var center := (size.x - TILE_SIZE) * 0.5
	for index in tiles.size():
		var slot := whole + index - 2
		var tile := tiles[index]
		tile.position = Vector2(center + (slot - value) * PITCH, (size.y - TILE_SIZE) * 0.5)
		var id := winner if slot == int(STOP_STEP) or pool.is_empty() else pool[posmod(slot, pool.size())]
		if tile.get_meta("roulette_item", "") != id:
			tile.set_meta("roulette_item", id)
			tile.add_theme_stylebox_override("panel", plates[int(Gear.ITEMS[id].rarity)])
			art[index].texture = ItemArt.texture(id)
