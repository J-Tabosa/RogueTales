extends SceneTree
const Rules=preload("res://scripts/ultimate_rules.gd")
func _initialize() -> void:call_deferred("checks")
func checks() -> void:
	for id in ["maria","aladin","peter","rapunzel"]:
		var account:=TaleCampaign.new()
		account.unlocked.assign(TaleCatalog.HEROES.keys())
		var run:=IdleRun.new()
		assert(run.start_expedition(account,id,"vigor"))
		run.spawn_enemy()
		run.actors[0].energy=100
		var hp:float=run.tactics.enemies[0].hp
		assert(run.tactics.reserve_ultimate(0))
		var result:Dictionary=run.tactics.ultimate(0)
		assert(result.damage==0 and run.tactics.enemies[0].hp==hp,"Support ULTs cause no direct damage")
		if id=="peter":assert(run.actors[0].guardian_spirits==1)
		if id=="rapunzel":assert(run.actors[0].shield>0)
		if id=="maria":assert(run.tactics.enemies[0].curse_left==Rules.CURSE_DURATION)
	print("ULT REVISION PASS: no direct damage from sleep, curse, spirits or hair protection")
	quit()
