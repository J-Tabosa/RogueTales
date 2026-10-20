class_name IdleRun
extends RefCounted
## Run state only. Nothing here depends on the interface or animation.

const STAGES = [
	{
		"name": "Bosque dos Sussurros",
		"enemy": "Gosma silvestre",
		"boss": "Rei das Gosmas",
		"hp": 46.0,
		"damage": 5.0,
		"color": Color("72c9a0")
	},
	{
		"name": "Ruínas da Lua",
		"enemy": "Sentinela de pedra",
		"boss": "Guardião Lunar",
		"hp": 72.0,
		"damage": 8.0,
		"color": Color("a49bda")
	},
	{
		"name": "Caldeira Carmesim",
		"enemy": "Brasa errante",
		"boss": "Coração da Caldeira",
		"hp": 100.0,
		"damage": 11.0,
		"color": Color("f28a69")
	},
]
const RELICS = [
	{"id": "power", "title": "Pavio longo", "detail": "+30% de dano das bombas"},
	{"id": "heart", "title": "Coração do bosque", "detail": "+40 de vida máxima e cura 40"},
	{"id": "haste", "title": "Mãos ligeiras", "detail": "Ataques 20% mais rápidos"},
	{"id": "critical", "title": "Pólvora instável", "detail": "+20% de chance crítica (dano ×2)"},
	{"id": "leech", "title": "Cesta encantada", "detail": "Recupera 4 de vida a cada acerto"},
	{"id": "armor", "title": "Capa reforçada", "detail": "Reduz dano recebido em 2"},
]
var stage := 0
var wave := 0
var max_hp := 180.0
var hp := 180.0
var damage := 20.0
var interval := 1.5
var crit := 0.1
var leech := 0.0
var armor := 0.0
var enemy_hp := 0.0
var enemy_max := 0.0
var kills := 0
var relics: Array[String] = []


func spawn_enemy() -> void:
	enemy_max = float(STAGES[stage].hp) * (2.0 if wave == 2 else 1.0)
	enemy_hp = enemy_max


func hit_enemy() -> Dictionary:
	var critical := randf() < crit
	var amount := damage * (2.0 if critical else 1.0)
	enemy_hp = maxf(0.0, enemy_hp - amount)
	hp = minf(max_hp, hp + leech)
	return {"damage": amount, "critical": critical}


func hit_hero() -> float:
	var amount := maxf(1.0, float(STAGES[stage].damage) * (1.5 if wave == 2 else 1.0) - armor)
	hp = maxf(0.0, hp - amount)
	return amount


func apply_relic(id: String) -> void:
	relics.append(id)
	match id:
		"power":
			damage *= 1.3
		"heart":
			max_hp += 40.0
			hp = minf(max_hp, hp + 40.0)
		"haste":
			interval = maxf(1.05, interval * 0.8)
		"critical":
			crit = minf(1.0, crit + 0.2)
		"leech":
			leech += 4.0
		"armor":
			armor += 2.0
