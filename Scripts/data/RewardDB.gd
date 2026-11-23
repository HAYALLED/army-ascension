class_name RewardDB
extends RefCounted
## Rewarded-ad and chest balance. Every number is tunable.
## A reward is {"gold": int, "gems": int, "shards": {SoldierDB.Type: int}, "unlock": [SoldierDB.Type]};
## PlayerData.grant applies it ("unlock" = soldier classes the reward gives for the first time).

## Shards for one "free shards" ad (the shop offer text says the same number).
const AD_SHARDS := 5
## Seconds between two free chests.
const CHEST_COOLDOWN := 1800
## Soldiers an ad revive brings back at least (normally it brings back the run's peak army size, see Game.revive_count).
const REVIVE_SOLDIERS := 8
## Damage buff (+20%) an ad revive adds for the rest of the run.
const REVIVE_DAMAGE_BUFF := 0.2

const ICON_GOLD := "res://Assets/UI/icon_gold.png"
const ICON_SHARD := "res://Assets/UI/icon_shard.png"
const ICON_GEM := "res://Assets/UI/icon_gem.png"
const ICON_CHEST := "res://Assets/UI/chest_wood.png"


static func empty() -> Dictionary:
	return {"gold": 0, "gems": 0, "shards": {}, "unlock": []}


## Adds `b` into a copy of `a`.
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := empty()
	for r in [a, b]:
		out["gold"] += int(r.get("gold", 0))
		out["gems"] += int(r.get("gems", 0))
		for t in r.get("unlock", []):
			if not out["unlock"].has(t):
				out["unlock"].append(t)
		var shards: Dictionary = r.get("shards", {})
		for t in shards:
			out["shards"][t] = int(out["shards"].get(t, 0)) + int(shards[t])
	return out


## Wooden chest (free ad chest, starter bundle): same contents rules as the level-drop wood chest, see ChestDB.
static func roll_chest(rng: RandomNumberGenerator) -> Dictionary:
	return ChestDB.to_reward(ChestDB.roll(ChestDB.Tier.WOOD, rng))


## Popup rows for a reward: [{"icon": path, "text": String}].
static func lines(reward: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in reward.get("unlock", []):
		out.append({"icon": String(SoldierDB.DATA[t]["icon"]), "text": "NEW UNIT: %s!" % SoldierDB.DATA[t]["name"]})
	if int(reward.get("gold", 0)) > 0:
		out.append({"icon": ICON_GOLD, "text": "+%d Gold" % int(reward["gold"])})
	var shards: Dictionary = reward.get("shards", {})
	for t in shards:
		out.append({"icon": ICON_SHARD, "text": "+%d %s shards" % [int(shards[t]), SoldierDB.DATA[t]["name"]]})
	if int(reward.get("gems", 0)) > 0:
		out.append({"icon": ICON_GEM, "text": "+%d GEM!" % int(reward["gems"])})
	return out
