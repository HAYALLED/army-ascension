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
## Gem price of the gold chest in the shop.
const SHOP_GOLD_GEMS := 20

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


## Rolls the contents of one chest. Classes are picked from ALL soldier classes (owned or not),
## each at most once per chest; a class the player does not own is a new unit.
static func roll(tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var d: Dictionary = DATA[tier]
	var types: Array = SoldierDB.DATA.keys()
	for i in range(types.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = types[i]
		types[i] = types[j]
		types[j] = tmp
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


## Chest -> RewardDB reward. "unlock" lists the classes the player does not own yet (they are
## unlocked by PlayerData.grant before their shards are added).
static func to_reward(chest: Dictionary) -> Dictionary:
	var r := RewardDB.empty()
	r["gold"] = int(chest.get("gold", 0))
	r["gems"] = int(chest.get("gems", 0))
	var unlock: Array = []
	for u: Dictionary in chest.get("units", []):
		var t := int(u["type"])
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
	return {"tier": String(DATA[int(chest["tier"])]["id"]), "units": units, "gold": int(chest["gold"]), "gems": int(chest["gems"])}


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
	return {
		"tier": tier,
		"units": units,
		"gold": _int(v.get("gold"), gold_range.x, gold_range.y, gold_range.x),
		"gems": _int(v.get("gems"), 0, 1, 0),
	}


## Number clamped to lo..hi; `fallback` when the value is not a finite number.
static func _int(v: Variant, lo: int, hi: int, fallback: int) -> int:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT or not is_finite(float(v)):
		return fallback
	return int(clampf(float(v), float(lo), float(hi)))
