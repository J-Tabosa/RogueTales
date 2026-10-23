extends RefCounted
## Eight illustrated ecosystems, six authored enemies per biome, across twelve acts.
const KEYS := ["forest", "castle", "ice", "shore", "fire", "arcane", "swamp", "desert"]
const STAGE_BIOMES := [0, 1, 0, 2, 1, 3, 4, 5, 6, 2, 7, 5]
const NAMES := ["Bosque Encantado", "Castelo da Meia-noite", "Montanhas de Jade", "Costa das Marés", "Forja das Cinzas", "Ruínas do Último Fio", "Pântano dos Reflexos", "Dunas do Tempo"]
const COLORS := [Color("93c56c"), Color("d9accb"), Color("a3e3ff"), Color("72ded7"), Color("ff9756"), Color("c5a2f2"), Color("a0b66c"), Color("e5bd78")]
const CLASSES := ["vanguard", "vanguard", "ranger", "mage", "assassin", "vanguard"]
const ENEMIES := [
	["Cavaleiro das Sarças", "Lobo dos Espinhos", "Caçadora do Corvo", "Bruxa dos Cogumelos", "Lâmina do Corvo", "Dríade dos Chifres"],
	["Guarda da Coroa", "Marionete de Porcelana", "Besteiro da Corte", "Mago da Ampulheta", "Arlequim da Meia-noite", "Gárgula do Campanário"],
	["Lanceiro de Jade", "Lobo da Neve", "Arqueira do Gelo", "Bruxa da Geada", "Lâmina da Nevasca", "Golem de Cristal"],
	["Sentinela das Conchas", "Caranguejo de Espinhos", "Arremessador de Coral", "Sereia das Profundezas", "Corsário Afogado", "Saqueador das Algas"],
	["Cavaleiro da Brasa", "Cão de Carvão", "Besteiro das Cinzas", "Feiticeira da Fornalha", "Lâmina de Fumaça", "Demônio das Brasas"],
	["Guardião de Papel", "Marionete das Tesouras", "Arqueiro das Penas", "Bibliotecário Cego", "Assassino de Tinta", "Autômato do Tear"],
	["Vigia do Musgo", "Cão do Brejo", "Caçadora do Lodo", "Bruxa dos Reflexos", "Garça das Sombras", "Dríade dos Lírios"],
	["Sentinela de Arenito", "Chacal do Deserto", "Arqueiro de Vidro", "Cronomante da Areia", "Lâmina das Dunas", "Escorpião do Relógio"]
]
const HP := [1.18, 0.98, 0.86, 0.90, 0.75, 1.30]
const POWER := [1.00, 1.12, 1.00, 0.86, 1.22, 0.94]
const INTERVALS := [3.3, 2.8, 3.0, 3.5, 2.5, 3.7]
static var textures: Dictionary = {}
static var frames_cache: Dictionary = {}
static var bounds_cache: Dictionary = {}

static func biome(stage: int) -> int:
	return STAGE_BIOMES[clampi(stage, 0, 11)]

static func sheet(biome_id: int) -> Texture2D:
	var key: String = KEYS[biome_id]
	if not textures.has(key): textures[key] = load("res://assets/biomes/enemies_%s.webp" % key)
	return textures[key]

static func scenery(stage: int) -> Texture2D:
	if not textures.has("scenery"): textures["scenery"] = load("res://assets/biomes/scenery.webp")
	var source: Texture2D = textures.scenery
	var cell := source.get_size() / Vector2(2, 4)
	var id := biome(stage)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(Vector2(id % 2, id / 2) * cell, cell)
	return atlas

static func pick(stage: int, phase: int, slot: int, rng: RandomNumberGenerator, chosen: Array[int]) -> int:
	var deck: Array[int] = [0, 1, 2, 3, 4, 5]
	var shuffle := RandomNumberGenerator.new()
	shuffle.seed = rng.seed ^ ((stage + 1) * 7919)
	for at in range(5, 0, -1):
		var other := shuffle.randi_range(0, at)
		var swap := deck[at]
		deck[at] = deck[other]
		deck[other] = swap
	for offset in 6:
		var candidate := deck[(phase * 2 + slot + offset) % 6]
		if not chosen.has(candidate): return candidate
	return deck[0]

static func flip_for(biome_id: int, variant: int, pose: int) -> bool:
	return (biome_id in [0, 4] and variant == 2 and pose in [1, 2]) or (biome_id == 5 and variant == 0 and pose == 2)

static func profile(stage: int, variant: int) -> Dictionary:
	var id := biome(stage)
	return {"variant": variant, "biome": id, "name": ENEMIES[id][variant], "class": CLASSES[variant], "hp_factor": HP[variant], "power_factor": POWER[variant], "interval": INTERVALS[variant]}

static func frames(biome_id: int, variant: int) -> SpriteFrames:
	var key := "%d:%d" % [biome_id, variant]
	if frames_cache.has(key): return frames_cache[key]
	var source := sheet(biome_id)
	var cell := source.get_size() / Vector2(4, 6)
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for animation in ["idle", "attack", "boss_idle", "boss_attack"]:
		result.add_animation(animation)
		result.set_animation_speed(animation, 4 if animation.ends_with("attack") else 2)
		result.set_animation_loop(animation, not animation.ends_with("attack"))
		for frame in 4:
			var image := AtlasTexture.new()
			image.atlas = source
			image.filter_clip = true
			image.region = Rect2(Vector2(frame if animation.ends_with("attack") else 0, variant) * cell, cell)
			result.add_frame(animation, image)
	frames_cache[key] = result
	return result


static func bounds(biome_id: int, variant: int) -> Rect2:
	var key := "%d:%d" % [biome_id, variant]
	if not bounds_cache.has(key): bounds_cache[key] = Rect2(frames(biome_id, variant).get_frame_texture("idle", 0).get_image().get_used_rect())
	return bounds_cache[key]


static func height_factor(biome_id: int, variant: int) -> float:
	return 0.65 if variant == 1 and biome_id not in [1, 5] else 1.0
