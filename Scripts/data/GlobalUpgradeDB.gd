class_name GlobalUpgradeDB
extends RefCounted
## Army-wide upgrades (Upgrades tab). They apply to the whole army and every battle,
## paid with gold only. Per-unit upgrades (one soldier class at a time, gold + that
## class's shards) live in the Soldiers tab: see SoldierDB / PlayerData.try_upgrade.
## Every number is a starting balance value and can be tuned freely.

## Only ever append: the save file uses the string ids below, never these ints.
enum Id { INCOME, DAMAGE, HEALTH, FIRE_RATE, SHARD_LUCK, REINFORCEMENTS }

## "per_level": effect gained per level (0.10 = +10%; for kind "count" a flat number).
## Cost to buy level N+1 = base_cost * growth^N, rounded to 10.
const DATA := {
	Id.INCOME: {
		"id": "income", "name": "Battle Income", "kind": "pct", "per_level": 0.10, "max": 10,
		"icon": "res://Assets/UI/icon_gold.png",
		"desc": "More gold at the end of every level.",
		"base_cost": 400, "growth": 1.5,
	},
	Id.DAMAGE: {
		"id": "damage", "name": "Army Damage", "kind": "pct", "per_level": 0.05, "max": 10,
		"icon": "res://Assets/UI/icon_damage.png",
		"desc": "All soldiers deal more damage.",
		"base_cost": 500, "growth": 1.5,
	},
	Id.HEALTH: {
		"id": "health", "name": "Army Health", "kind": "pct", "per_level": 0.06, "max": 10,
		"icon": "res://Assets/UI/icon_health.png",
		"desc": "All soldiers have more health.",
		"base_cost": 500, "growth": 1.5,
	},
	Id.FIRE_RATE: {
		"id": "fire_rate", "name": "Fire Rate", "kind": "pct", "per_level": 0.04, "max": 10,
		"icon": "res://Assets/UI/icon_firerate.png",
		"desc": "All soldiers shoot faster.",
		"base_cost": 600, "growth": 1.55,
	},
	Id.SHARD_LUCK: {
		"id": "shard_luck", "name": "Shard Luck", "kind": "pct", "per_level": 0.08, "max": 10,
		"icon": "res://Assets/UI/icon_shard.png",
		"desc": "Enemies drop soldier shards more often.",
		"base_cost": 450, "growth": 1.5,
	},
	Id.REINFORCEMENTS: {
		"id": "reinforcements", "name": "Reinforcements", "kind": "count", "per_level": 1.0, "max": 5,
		"icon": "res://Assets/UI/icon_soldiers.png",
		"desc": "Start every battle with extra soldiers.",
		"base_cost": 1200, "growth": 1.9,
	},
}


static func max_level(id: int) -> int:
	return int(DATA[id]["max"])


## Total effect at `level` (0.3 = +30%, or the extra soldier count).
static func value(id: int, level: int) -> float:
	return float(DATA[id]["per_level"]) * float(clampi(level, 0, max_level(id)))


## Gold to go from `level` to `level + 1`.
static func cost(id: int, level: int) -> int:
	var d: Dictionary = DATA[id]
	var raw := float(d["base_cost"]) * pow(float(d["growth"]), float(maxi(level, 0)))
	return int(round(raw / 10.0)) * 10


## "+30%" or "+2" style text of the effect at `level`.
static func effect_text(id: int, level: int) -> String:
	var v := value(id, level)
	if String(DATA[id]["kind"]) == "count":
		return "+%d" % int(round(v))
	return "+%d%%" % int(round(v * 100.0))


## Stable save-file id of an upgrade.
static func id_of(id: int) -> String:
	return String(DATA[id]["id"])


## Upgrade of a save-file id, or -1 for an unknown id.
static func from_id(text: String) -> int:
	for k in DATA:
		if String(DATA[k]["id"]) == text:
			return int(k)
	return -1
