class_name RewardDB
extends RefCounted
## Rewarded-ad and chest balance. Every number is tunable.
## A reward is {"gold": int, "gems": int, "shards": {SoldierDB.Type: int}}; PlayerData.grant applies it.

## Shards for one "free shards" ad (the shop offer text says the same number).
const AD_SHARDS := 5
## Seconds between two free chests.
const CHEST_COOLDOWN := 1800
const CHEST_SHARDS_MIN := 2
const CHEST_SHARDS_MAX := 7
const CHEST_GOLD_MIN := 25
const CHEST_GOLD_MAX := 75
## Chance that a wooden chest also holds one gem.
const CHEST_GEM_CHANCE := 0.001
## Soldiers an ad revive brings back.
const REVIVE_SOLDIERS := 8

const ICON_GOLD := "res://Assets/UI/icon_gold.png"
const ICON_SHARD := "res://Assets/UI/icon_shard.png"
const ICON_GEM := "res://Assets/UI/icon_gem.png"
const ICON_CHEST := "res://Assets/UI/chest_wood.png"


static func empty() -> Dictionary:
	return {"gold": 0, "gems": 0, "shards": {}}


## Adds `b` into a copy of `a`.
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := empty()
	for r in [a, b]:
		out["gold"] += int(r.get("gold", 0))
		out["gems"] += int(r.get("gems", 0))
		var shards: Dictionary = r.get("shards", {})
		for t in shards:
			out["shards"][t] = int(out["shards"].get(t, 0)) + int(shards[t])
	return out


## Wooden chest: 2-7 shards for one owned soldier class, a few coins, rarely a gem.
static func roll_chest(rng: RandomNumberGenerator) -> Dictionary:
	var r := empty()
	var owned := PlayerData.owned_types()
	if not owned.is_empty():
		r["shards"][owned[rng.randi() % owned.size()]] = rng.randi_range(CHEST_SHARDS_MIN, CHEST_SHARDS_MAX)
	r["gold"] = rng.randi_range(CHEST_GOLD_MIN, CHEST_GOLD_MAX)
	if rng.randf() < CHEST_GEM_CHANCE:
		r["gems"] = 1
	return r


## Popup rows for a reward: [{"icon": path, "text": String}].
static func lines(reward: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if int(reward.get("gold", 0)) > 0:
		out.append({"icon": ICON_GOLD, "text": "+%d Gold" % int(reward["gold"])})
	var shards: Dictionary = reward.get("shards", {})
	for t in shards:
		out.append({"icon": ICON_SHARD, "text": "+%d %s shards" % [int(shards[t]), SoldierDB.DATA[t]["name"]]})
	if int(reward.get("gems", 0)) > 0:
		out.append({"icon": ICON_GEM, "text": "+%d GEM!" % int(reward["gems"])})
	return out
