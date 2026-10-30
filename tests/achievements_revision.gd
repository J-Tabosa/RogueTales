extends SceneTree
func _initialize() -> void:call_deferred("checks")
func checks() -> void:
	var c:=TaleCampaign.new()
	assert(c.ACHIEVEMENTS.size()==25)
	assert(c.ACHIEVEMENTS.filter(func(t):return t.get("hidden",false)).size()==2)
	assert(not c.achievement_ready("first") and not c.claim_achievement("first"))
	for hero in TaleCatalog.HEROES:
		c.record_achievement_state({"leader":hero,"hero_ids":[hero],"stage":7,"rooms_cleared":48},true)
		assert(c.achievement_ready("hero_win_"+hero))
	assert(c.achievement_ready("solo") and c.achievement_ready("stages8"))
	var other:=TaleCampaign.new()
	other.record_achievement_state({"leader":"alice","hero_ids":["alice"],"drafted":["ariel"]},true)
	assert(not other.achievement_ready("solo"))
	c.record_achievement_state({"journey":{"path":preload("res://scripts/world_routes.gd").NODES.keys()},"stage":999,"secret_defeated":preload("res://scripts/secret_encounters.gd").DATA.keys()})
	assert(c.achievement_ready("maps_all") and c.achievement_ready("secrets_all"))
	var equipment:Dictionary={}
	var legendary:Array=[]
	for id in preload("res://scripts/equipment.gd").ITEMS:
		if preload("res://scripts/equipment.gd").data(id).get("rarity",0) in [4,5]:legendary.append(id)
	var ids:Array=TaleCatalog.HEROES.keys().slice(0,5)
	for hero in ids:equipment[hero]={"items":[legendary[0],legendary[1]]}
	c.record_achievement_state({"hero_ids":ids,"equipment_state":equipment,"party_capacity":5})
	assert(c.achievement_ready("royal_gear") and c.achievement_ready("capacity"))
	c.record_achievement_state({"endless":true,"continuation_from":48,"rooms_cleared":78})
	assert(c.achievement_ready("infinite25") and not c.achievement_ready("infinite50"))
	c.record_achievement_state({"endless":true,"continuation_from":48,"rooms_cleared":168})
	assert(c.achievement_ready("infinite100"))
	c.gold=99999
	assert(not c.achievement_ready("memories100k"))
	c.earn_gold(1)
	c.gold=0
	assert(c.achievement_ready("memories100k"))
	c.run_counter=100
	assert(c.achievement_ready("runs100"))
	c.unlocked.assign(TaleCatalog.HEROES.keys())
	assert(c.achievement_ready("tales_all"))
	assert(c.claim_achievement("solo") and not c.claim_achievement("solo"))
	assert(c.save_to("user://achievement_revision_test.json"))
	var restored:=TaleCampaign.new()
	assert(restored.load_from("user://achievement_revision_test.json"))
	assert(restored.claimed.has("solo") and restored.achievement_ready("maps_all"))
	print("ACHIEVEMENTS REVISION PASS: 25 goals, hero wins, hidden feats, maps, secrets, gear, capacity, infinite, balance peak, claims and disk save")
	quit()
