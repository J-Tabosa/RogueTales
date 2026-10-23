extends Node2D
var arena
func _draw() -> void:
	arena.draw_combat_effects(self)
