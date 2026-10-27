extends RefCounted
## Explicit pre-0.9.10 account fixture; production accounts buy the first hero.
static func legacy() -> TaleCampaign:
	var c:=TaleCampaign.new()
	c.unlocked.assign(["scarlet"])
	c.party.assign(["scarlet"])
	c.gold=80
	c.total_gold=80
	return c
