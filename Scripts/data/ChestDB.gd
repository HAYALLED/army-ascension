class_name ChestDB
extends RefCounted
## Chest balance and helpers. Every number is tunable.
## A chest is {"tier": Tier, "units": [{"type": SoldierDB.Type, "shards": int}], "gold": int, "gems": int}.
## Its contents are rolled once, when the chest drops, so the preview the player sees before
## opening is exactly what the chest pays. Beaten levels drop a chest into one of the SLOTS
## home-page slots (PlayerData.add_chest); the shop sells a gold chest for gems that opens at once.

enum Tier { WOOD, SILVER, GOLD }

## Chest slots on the home page.
const SLOTS := 4
## Seconds a won chest stays locked, indexed by Tier: wooden 30 min, silver 1 h, gold 2 h.
const UNLOCK_SECONDS := [1800, 3600, 7200]
## One rewarded ad takes this much off a locked chest.
const AD_SKIP_SECONDS := 900
## Opening a locked chest early costs 1 gem per 360 s (a 2 hour gold chest = 20 gems).
const SECONDS_PER_GEM := 360
## Gem price of the gold chest in the shop.
const SHOP_GOLD_GEMS := 20
## Rewarded ads that unlock the shop's ad gold chest (same contents as the gem gold chest).
const SHOP_GOLD_ADS := 5
## Seconds before the ad gold chest can be earned again after it was opened (1 week).
const SHOP_GOLD_COOLDOWN := 604800

const ICON_LOCK := "res://Assets/UI/icon_lock.png"

## drop: weight of the level-win drop (60 / 30 / 10 %). units: different soldier classes inside.
## shards: range per class. gold: range. gem: chance of +1 gem.
const DATA := {
	Tier.WOOD: {
		"id": "wood", "name": "Wooden Chest", "short": "WOODEN", "icon": "res://Assets/UI/chest_wood.png",
		"drop": 60, "units": 1, "shards": Vector2i(3, 5), "gold": Vector2i(50, 100), "gem": 0.02,
	},
	Tier.SILVER: {
		"id": "silver", "name": "Silver Chest", "short": "SILVER", "icon": "res://Assets/UI/chest_silver.png",
		"drop": 30, "units": 2, "shards": Vector2i(7, 10), "gold": Vector2i(200, 400), "gem": 0.02,
	},
	Tier.GOLD: {
		"id": "gold", "name": "Gold Chest", "short": "GOLD", "icon": "res://Assets/UI/chest_gold.png",
		"drop": 10, "units": 3, "shards": Vector2i(20, 50), "gold": Vector2i(600, 1200), "gem": 0.05,
	},
}


static func name_of(tier: int) -> String:
	return String(DATA[tier]["name"])


static func icon_of(tier: int) -> String:
	return String(DATA[tier]["icon"])


## Chest tier a won level drops, by the drop weights.
static func roll_tier(rng: RandomNumberGenerator) -> int:
	var total := 0
	for t in DATA:
		total += int(DATA[t]["drop"])
	var pick := rng.randi_range(1, total)
	for t in DATA:
		pick -= int(DATA[t]["drop"])
		if pick <= 0:
			return t
	return Tier.WOOD


## Chance weight of a soldier class by its rank: higher ranks drop less often.
const RANK_WEIGHT := {&"common": 10.0, &"rare": 5.0, &"super_rare": 2.5, &"legend": 1.0, &"unique": 0.5}


## Random order of `types` without repeats where a heavier class tends to come first
## (weighted sampling, Efraimidis-Spirakis: key = random ^ (1 / weight)).
static func _weighted_order(types: Array, rng: RandomNumberGenerator) -> Array:
	var keyed: Array = []
	for t in types:
		var w: float = float(RANK_WEIGHT.get(SoldierDB.DATA[t]["rank"], 1.0))
		keyed.append([pow(maxf(rng.randf(), 0.000001), 1.0 / maxf(w, 0.01)), t])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var out: Array = []
	for k in keyed:
		out.append(k[1])
	return out


## Rolls the contents of one chest. Classes are picked from ALL soldier classes (owned or not),
## each at most once per chest; a class the player does not own is a new unit.
static func roll(tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var d: Dictionary = DATA[tier]
	var types: Array = _weighted_order(SoldierDB.listed_types(), rng)
	var units: Array = []
	var shard_range: Vector2i = d["shards"]
	for i in mini(int(d["units"]), types.size()):
		units.append({"type": int(types[i]), "shards": rng.randi_range(shard_range.x, shard_range.y)})
	var gold_range: Vector2i = d["gold"]
	return {
		"tier": tier,
		"units": units,
		"gold": rng.randi_range(gold_range.x, gold_range.y),
		"gems": 1 if rng.randf() < float(d["gem"]) else 0,
	}


## Gems needed to open a chest that still has `seconds_left` to wait (0 when it is ready).
static func skip_gems(seconds_left: int) -> int:
	return maxi(ceili(float(seconds_left) / float(SECONDS_PER_GEM)), 0)


## Chest -> RewardDB reward. "unlock" lists the classes the player does not own yet (they are
## unlocked by PlayerData.grant before their shards are added).
static func to_reward(chest: Dictionary) -> Dictionary:
	var r := RewardDB.empty()
	r["gold"] = int(chest.get("gold", 0))
	r["gems"] = int(chest.get("gems", 0))
	var unlock: Array = []
	for u: Dictionary in chest.get("units", []):
		var t := int(u["type"])
		if not SoldierDB.is_listed(t):
			continue
		r["shards"][t] = int(r["shards"].get(t, 0)) + int(u["shards"])
		if not PlayerData.owns(t):
			unlock.append(t)
	r["unlock"] = unlock
	return r


## What the player may see before opening: [{"icon": path, "text": String}].
## An owned class shows its name and shards, an unowned one only "???" (opening it unlocks the unit).
static func preview_lines(chest: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Dictionary in chest.get("units", []):
		var t := int(u["type"])
		if not SoldierDB.is_listed(t):
			continue
		if PlayerData.owns(t):
			out.append({"icon": String(SoldierDB.DATA[t]["icon"]), "text": "%s  +%d shards" % [SoldierDB.DATA[t]["name"], int(u["shards"])]})
		else:
			out.append({"icon": ICON_LOCK, "text": "???"})
	if int(chest.get("gold", 0)) > 0:
		out.append({"icon": RewardDB.ICON_GOLD, "text": "+%d Gold" % int(chest["gold"])})
	if int(chest.get("gems", 0)) > 0:
		out.append({"icon": RewardDB.ICON_GEM, "text": "+%d GEM" % int(chest["gems"])})
	return out


## True when the preview hides at least one unit ("???").
static func has_unknown_unit(chest: Dictionary) -> bool:
	for u: Dictionary in chest.get("units", []):
		if not PlayerData.owns(int(u["type"])):
			return true
	return false


## ---- Save file ---------------------------------------------------------------

## Save-file form of a chest (string ids only, never enum ints).
static func to_save(chest: Dictionary) -> Dictionary:
	if chest.is_empty():
		return {}
	var units: Array = []
	for u: Dictionary in chest["units"]:
		units.append({"id": SoldierDB.id_of(int(u["type"])), "shards": int(u["shards"])})
	var out := {"tier": String(DATA[int(chest["tier"])]["id"]), "units": units, "gold": int(chest["gold"]), "gems": int(chest["gems"])}
	if int(chest.get("ready_at", 0)) > 0:
		out["ready_at"] = int(chest["ready_at"])
	return out


## Chest from save data; {} when the data is not a valid chest. Every number is clamped.
static func from_save(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var tier := -1
	for t in DATA:
		if DATA[t]["id"] == v.get("tier"):
			tier = int(t)
	if tier < 0 or not (v.get("units") is Array):
		return {}
	var d: Dictionary = DATA[tier]
	var units: Array = []
	var seen := {}
	for u in v["units"]:
		if not (u is Dictionary) or not (u.get("id") is String):
			continue
		var type := SoldierDB.type_of(u["id"])
		if type < 0 or seen.has(type):
			continue
		seen[type] = true
		var shard_range: Vector2i = d["shards"]
		units.append({"type": type, "shards": _int(u.get("shards"), shard_range.x, shard_range.y, shard_range.x)})
	if units.is_empty() or units.size() > int(d["units"]):
		return {}
	var gold_range: Vector2i = d["gold"]
	var chest := {
		"tier": tier,
		"units": units,
		"gold": _int(v.get("gold"), gold_range.x, gold_range.y, gold_range.x),
		"gems": _int(v.get("gems"), 0, 1, 0),
	}
	# Capped at one full unlock time from now, so a bad value or a changed clock never locks a chest for long.
	var latest := int(Time.get_unix_time_from_system()) + int(UNLOCK_SECONDS[tier])
	var ready_at := _int(v.get("ready_at"), 0, latest, 0)
	if ready_at > 0:
		chest["ready_at"] = ready_at
	return chest


## Number clamped to lo..hi; `fallback` when the value is not a finite number.
static func _int(v: Variant, lo: int, hi: int, fallback: int) -> int:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT or not is_finite(float(v)):
		return fallback
	return int(clampf(float(v), float(lo), float(hi)))