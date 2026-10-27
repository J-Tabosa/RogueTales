extends RefCounted
## A round gives each living unit one own turn, with all its basics in sequence.
const Rules=preload("res://scripts/combat_rules.gd")
var owner_ref:WeakRef
var order:Array[Dictionary]=[]
var round_number:=0
var cursor:=0
var waiting:=.3
var active:Dictionary={}
var ult_queue:Array[int]=[]
var turn_entry:Dictionary={}
var remaining:=0
var clock:=0.0
var ready_at:Dictionary={}
var auto_ult:=false

func bind(owner) -> void:
	owner_ref=weakref(owner)
	start_round()

func unit(entry:Dictionary) -> Dictionary:
	var owner=owner_ref.get_ref()
	return owner.actors[entry.index] if entry.side=="ally" else owner.tactics.enemies[entry.index]

func less(a:Dictionary,b:Dictionary) -> bool:
	var ad:bool=int(unit(a).get("gear_delayed_round",-1))==round_number
	var bd:bool=int(unit(b).get("gear_delayed_round",-1))==round_number
	if ad!=bd:return not ad
	var ai:=Rules.effective_initiative(unit(a))
	var bi:=Rules.effective_initiative(unit(b))
	if not is_equal_approx(ai,bi):return ai>bi
	return a.index<b.index if a.side==b.side else a.side=="ally"

func start_round() -> void:
	var owner=owner_ref.get_ref()
	round_number+=1
	owner.tactics.round_number=round_number
	if owner.expedition:owner.tactics.BossRules.round_start(owner.tactics)
	order.clear()
	cursor=0
	turn_entry={}
	for side in ["ally","enemy"]:
		var units:Array=owner.actors if side=="ally" else owner.tactics.enemies
		for at in units.size():
			units[at]["ap"]=Rules.Bonuses.attacks(units[at])
			units[at]["pp"]=0
			if units[at].hp>0:order.append({"side":side,"index":at,"initiative":Rules.effective_initiative(units[at])})
	order.sort_custom(less)

func preview(limit:=6) -> Array[Dictionary]:
	var future:Array[Dictionary]=[]
	for at in range(cursor,order.size()):
		if unit(order[at]).hp>0:future.append(order[at].duplicate())
	if turn_entry.is_empty():future.sort_custom(less)
	return future.slice(0,limit)

func finish_turn() -> void:
	if not turn_entry.is_empty():Rules.end_turn(unit(turn_entry))
	turn_entry={}
	remaining=0
	cursor+=1

func next_action() -> Dictionary:
	if not active.is_empty():return {}
	var owner=owner_ref.get_ref()
	while not ult_queue.is_empty():
		var i:int=ult_queue.pop_front()
		if i>=0 and i<owner.actors.size():
			owner.actors[i].ult_queued=false
			if owner.actors[i].hp>0 and Rules.ready(owner.actors[i]):return {"side":"ally","index":i,"manual":true,"ultimate":true}
	if not turn_entry.is_empty():
		var a:=unit(turn_entry)
		if a.hp<=0:finish_turn()
		elif turn_entry.side=="ally" and (auto_ult or a.id=="alice") and Rules.ready(a):
			var ult:=turn_entry.duplicate()
			ult["ultimate"]=true
			return ult
		elif remaining>0:return turn_entry.duplicate()
		else:finish_turn()
	while cursor<order.size():
		# Re-evaluate only not-yet-acted units after Initiative penalties.
		var tail:Array=order.slice(cursor)
		tail.sort_custom(less)
		for n in tail.size():order[cursor+n]=tail[n]
		var entry:Dictionary=order[cursor]
		if unit(entry).hp<=0:cursor+=1;continue
		turn_entry=entry.duplicate()
		var state:=Rules.start_turn(owner.tactics,unit(entry))
		remaining=int(state.attacks)
		unit(entry).ap=remaining
		if remaining<=0 or unit(entry).hp<=0:
			finish_turn()
			continue
		return next_action()
	start_round()
	waiting=.55
	return {}

func begin(entry:Dictionary) -> void:
	active=entry.duplicate()
	if not entry.get("ultimate",false) and not entry.get("manual",false):
		remaining=maxi(0,remaining-1)
		unit(entry).ap=remaining

func complete() -> void:
	var finished:=active.duplicate()
	active={}
	if not finished.is_empty():
		var a:=unit(finished)
		if int(a.get("bonus_attacks",0))>0 and not turn_entry.is_empty() and turn_entry.side==finished.side and turn_entry.index==finished.index:
			remaining+=int(a.bonus_attacks)
			a.bonus_attacks=0
	waiting=.46

func queue_ultimate(index:int) -> bool:
	if ult_queue.has(index):return false
	ult_queue.append(index)
	owner_ref.get_ref().actors[index].ult_queued=true
	return true

func can_delay(hero:int,enemy:int) -> bool:
	var owner=owner_ref.get_ref()
	if hero<0 or hero>=owner.actors.size() or enemy<0 or enemy>=owner.tactics.enemies.size():return false
	var a:Dictionary=owner.actors[hero]
	if a.hp<=0 or a.get("gear_time_used",false) or not Rules.Gear.effects(a).get("time_sands",false):return false
	if owner.tactics.enemies[enemy].hp<=0 or int(owner.tactics.enemies[enemy].get("gear_delayed_round",-1))==round_number:return false
	if not turn_entry.is_empty() and turn_entry.side=="enemy" and turn_entry.index==enemy:return false
	return order.slice(cursor).any(func(entry):return entry.side=="enemy" and entry.index==enemy)

func delay_enemy(hero:int,enemy:int) -> bool:
	if not can_delay(hero,enemy):return false
	var owner=owner_ref.get_ref()
	owner.actors[hero]["gear_time_used"]=true
	owner.tactics.enemies[enemy]["gear_delayed_round"]=round_number
	owner.tactics.notify(owner.actors[hero].id,"Areias do Tempo",str(owner.tactics.enemies[enemy].get("name","Inimigo"))+" agirá no final da rodada")
	return true

func entry_key(entry:Dictionary) -> String:return "%s:%d"%[entry.side,entry.index]
func advance(delta:float) -> void:clock+=delta
func cooldown_action() -> Dictionary:return next_action()
