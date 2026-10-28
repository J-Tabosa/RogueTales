extends SceneTree
## Output JSON for the workbook authoring script; does not change game balance.
func _initialize() -> void:
	var rows: Array = preload("res://scripts/enemy_balance.gd").defaults().values()
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass the JSON output path after --")
		quit(1)
		return
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	print("Exported %d enemy profiles" % rows.size())
	quit()
