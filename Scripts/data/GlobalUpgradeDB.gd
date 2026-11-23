class_name GlobalUpgradeDB
extends RefCounted
## Army-wide upgrades (Upgrades tab). They apply to the whole army and every battle,
## paid with gold only. Per-unit upgrades (one soldier class at a time, gold + that
## class's shards) live in the Soldiers tab: see SoldierDB / PlayerData.try_upgrade.
## There is no level limit (only Reinforcements has a cap, because the army can only hold so many
## soldiers). The bar of an upgrade shows its progress inside the current tier of TIER_SIZE levels;
## every full tier the bar color changes (tier_color) and starts filling again.
## Every number is a starting balance value and can be tuned freely.

## Levels per tier (one full bar), cost growth after level 10, and the biggest level a save file may hold.
const TIER_SIZE := 10
const LATE_GROWTH := 1.18
const MAX_SAVED_LEVEL := 9999

## Bar color of each tier, in order; repeats after the last one.
const TIER_COLORS := [
	Color(0.3, 0.85, 0.4), Color(0.25, 0.6, 1.0), Color(0.7, 0.4, 1.0), Color(1.0, 0.78, 0.2),
	Color(1.0, 0.32, 0.3), Color(0.2, 0.9, 0.95), Color(1.0, 0.45, 0.75), Color(0.95, 0.95, 1.0),
]

## Only ever append: the save file uses the string ids below, never these ints.
enum Id { INCOME, DAMAGE, HEALTH, FIRE_RATE, SHARD_LUCK, REINFORCEMENTS }

## "per_level": effect gained per level (0.10 = +10%; for kind "count" a flat number).
## "cap": highest level that still does something (0 = no cap).
## Cost to buy level N+1 = base_cost * growth^min(N, 10) * LATE_GROWTH^max(N - 10, 0), rounded to 10.
const DATA := {
	Id.INCOME: {
		"id": "income", "name": "Battle Income", "kind": "pct", "per_level": 0.10, "cap": 0,
		"icon": "res://Assets/UI/icon_gold.png",
		"desc": "More gold at the end of every level.",
		"base_cost": 400, "growth": 1.5,
	},
	Id.DAMAGE: {
		"id": "damage", "name": "Army Damage", "kind": "pct", "per_level": 0.05, "cap": 0,
		"icon": "res://Assets/UI/icon_damage.png",
		"desc": "All soldiers deal more damage.",
		"base_cost": 500, "growth": 1.5,
	},
	Id.HEALTH: {
		"id": "health", "name": "Army Health", "kind": "pct", "per_level": 0.06, "cap": 0,
		"icon": "res://Assets/UI/icon_health.png",
		"desc": "All soldiers have more health.",
		"base_cost": 500, "growth": 1.5,
	},
	Id.FIRE_RATE: {
		"id": "fire_rate", "name": "Fire Rate", "kind": "pct", "per_level": 0.04, "cap": 0,
		"icon": "res://Assets/UI/icon_firerate.png",
		"desc": "All soldiers shoot faster.",
		"base_cost": 600, "growth": 1.55,
	},
	Id.SHARD_LUCK: {
		"id": "shard_luck", "name": "Shard Luck", "kind": "pct", "per_level": 0.08, "cap": 0,
		"icon": "res://Assets/UI/icon_shard.png",
		"desc": "Enemies drop soldier shards more often.",
		"base_cost": 450, "growth": 1.5,
	},
	Id.REINFORCEMENTS: {
		"id": "reinforcements", "name": "Reinforcements", "kind": "count", "per_level": 1.0, "cap": 20,
		"icon": "res://Assets/UI/icon_soldiers.png",
		"desc": "Start every battle with extra soldiers.",
		"base_cost": 1200, "growth": 1.9,
	},
}


## Highest level that still adds something (0 = unlimited).
static func cap_of(id: int) -> int:
	return int(DATA[id]["cap"])


## True when `level` is at the cap of `id` (never for unlimited upgrades).
static func is_capped(id: int, level: int) -> bool:
	var cap := cap_of(id)
	return cap > 0 and level >= cap


## Total effect at `level` (0.3 = +30%, or the extra soldier count).
static func value(id: int, level: int) -> float:
	var lv := maxi(level, 0)
	var cap := cap_of(id)
	if cap > 0:
		lv = mini(lv, cap)
	return float(DATA[id]["per_level"]) * float(lv)


## Gold to go from `level` to `level + 1`.
static func cost(id: int, level: int) -> int:
	var d: Dictionary = DATA[id]
	var lv := maxi(level, 0)
	var raw := float(d["base_cost"]) * pow(float(d["growth"]), float(mini(lv, 10)))
	raw *= pow(LATE_GROWTH, float(maxi(lv - 10, 0)))
	return mini(int(round(minf(raw, float(PlayerData.MAX_CURRENCY)) / 10.0)) * 10, PlayerData.MAX_CURRENCY)


## 0-based tier of a level (levels 0-9 = tier 0, 10-19 = tier 1, ...). Accepts a fractional level.
static func tier_of(level: float) -> int:
	return maxi(floori(level / float(TIER_SIZE)), 0)


## 0..1 fill of the bar inside the current tier. Accepts a fractional level.
static func tier_progress(level: float) -> float:
	return fposmod(maxf(level, 0.0), float(TIER_SIZE)) / float(TIER_SIZE)


static func tier_color(tier: int) -> Color:
	return TIER_COLORS[maxi(tier, 0) % TIER_COLORS.size()]


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
