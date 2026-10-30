extends SceneTree
func _initialize() -> void:
	var account:=TaleCampaign.new()
	account.gold=0
	for run_id in range(1,4):
		account.run_counter=run_id
		var data:={"expedition":true,"run_id":run_id,"rooms_cleared":48}
		var result:=account.finish_expedition(data,true)
		assert(result.reward==1700)
		assert(account.finish_expedition(data,true).is_empty())
	assert(account.gold==5100)
	assert(account.buy_hero("alice"))
	assert(account.gold==100)
	for sample in [[0,0],[1,25],[4,100],[5,100],[6,175],[48,1400]]:
		account.run_counter+=1
		var result:=account.finish_expedition({"expedition":true,"run_id":account.run_counter,"rooms_cleared":sample[0]},false)
		assert(result.reward==sample[1])
	account.run_counter+=1
	var endless:={"expedition":true,"endless":true,"run_id":account.run_counter,"rooms_cleared":48,"continuation_from":48}
	assert(account.finish_expedition(endless,false).reward==0)
	account.run_counter+=1
	endless.run_id=account.run_counter
	endless.rooms_cleared=60
	# 10 new combats, two bosses and one new endless milestone.
	assert(account.finish_expedition(endless,false).reward==450)
	print("MEMORY REWARDS PASS: three wins buy a hero, partial runs, no shop payment, no duplicate claims, endless continuation")
	quit()
