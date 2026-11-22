class_name MissionDB
extends RefCounted
## Missions, achievements and the 7-day login rewards. Every number is tunable.
## Mission: {id, title, stat, goal, gold | gems}. Daily and weekly progress counts the stat inside the
## current day / week, achievements count it for the whole profile. STAT_LEVEL and STAT_UNIT_LEVEL are
## read live from PlayerData. Basic (first-tier) achievements pay gold only; harder ones pay gems.

## Counted stats. MissionManager.add() ignores anything else.
const STATS := ["battles", "wins", "kills", "gold_spent", "upgrades", "shards"]
## Highest level beaten (live from PlayerData).
const STAT_LEVEL := "level"
## Highest soldier level (live from PlayerData).
const STAT_UNIT_LEVEL := "unit_level"

const SCOPES := ["daily", "weekly", "achievements"]

const DAILY := [
	{"id": "d_battles", "title": "Complete 3 battles", "stat": "battles", "goal": 3, "gold": 150},
	{"id": "d_win", "title": "Win a battle", "stat": "wins", "goal": 1, "gold": 250},
	{"id": "d_kills", "title": "Defeat 150 enemies", "stat": "kills", "goal": 150, "gold": 200},
	{"id": "d_spend", "title": "Spend 400 gold", "stat": "gold_spent", "goal": 400, "gold": 150},
]

const WEEKLY := [
	{"id": "w_battles", "title": "Complete 15 battles", "stat": "battles", "goal": 15, "gold": 1000},
	{"id": "w_wins", "title": "Win 8 battles", "stat": "wins", "goal": 8, "gems": 15},
	{"id": "w_kills", "title": "Defeat 1000 enemies", "stat": "kills", "goal": 1000, "gold": 1200},
	{"id": "w_spend", "title": "Spend 3000 gold", "stat": "gold_spent", "goal": 3000, "gems": 15},
	{"id": "w_upgrades", "title": "Buy 5 upgrades", "stat": "upgrades", "goal": 5, "gold": 800},
	{"id": "w_shards", "title": "Collect 40 soldier shards", "stat": "shards", "goal": 40, "gems": 10},
]

const ACHIEVEMENTS := [
	{"id": "a_win_1", "title": "Win your first battle", "stat": "wins", "goal": 1, "gold": 200},
	{"id": "a_upg_1", "title": "Buy your first upgrade", "stat": "upgrades", "goal": 1, "gold": 150},
	{"id": "a_battle_10", "title": "Play 10 battles", "stat": "battles", "goal": 10, "gold": 300},
	{"id": "a_lvl_3", "title": "Beat level 3", "stat": STAT_LEVEL, "goal": 3, "gold": 300},
	{"id": "a_lvl_5", "title": "Beat level 5", "stat": STAT_LEVEL, "goal": 5, "gems": 20},
	{"id": "a_lvl_10", "title": "Beat level 10", "stat": STAT_LEVEL, "goal": 10, "gems": 50},
	{"id": "a_unit_3", "title": "Raise a soldier to level 3", "stat": STAT_UNIT_LEVEL, "goal": 3, "gold": 300},
	{"id": "a_unit_5", "title": "Raise a soldier to level 5", "stat": STAT_UNIT_LEVEL, "goal": 5, "gems": 20},
	{"id": "a_unit_10", "title": "Raise a soldier to level 10", "stat": STAT_UNIT_LEVEL, "goal": 10, "gems": 50},
	{"id": "a_spend_1k", "title": "Spend 1,000 gold", "stat": "gold_spent", "goal": 1000, "gold": 300},
	{"id": "a_spend_5k", "title": "Spend 5,000 gold", "stat": "gold_spent", "goal": 5000, "gems": 20},
	{"id": "a_spend_20k", "title": "Spend 20,000 gold", "stat": "gold_spent", "goal": 20000, "gems": 50},
	{"id": "a_kills_500", "title": "Defeat 500 enemies", "stat": "kills", "goal": 500, "gold": 400},
	{"id": "a_kills_5k", "title": "Defeat 5,000 enemies", "stat": "kills", "goal": 5000, "gems": 30},
	{"id": "a_wins_25", "title": "Win 25 battles", "stat": "wins", "goal": 25, "gems": 30},
]

## Daily login, day 1..7 (the Missions page strip shows the same amounts).
## shards: go to one random owned soldier class. box: day-7 bonus.
const LOGIN := [
	{"gold": 100},
	{"gold": 200},
	{"shards": 5},
	{"gold": 300},
	{"shards": 10},
	{"gold": 500},
	{"box": true},
]
const BOX_GOLD := 400
const BOX_SHARDS := 15
const BOX_GEMS := 3


static func list(scope: String) -> Array:
	match scope:
		"daily":
			return DAILY
		"weekly":
			return WEEKLY
		"achievements":
			return ACHIEVEMENTS
	return []


static func find(scope: String, id: String) -> Dictionary:
	for m in list(scope):
		if m["id"] == id:
			return m
	return {}


## Reward of a mission in the RewardDB format.
static func reward_of(m: Dictionary) -> Dictionary:
	var r := RewardDB.empty()
	r["gold"] = int(m.get("gold", 0))
	r["gems"] = int(m.get("gems", 0))
	return r


## Reward of login day 1..7 in the RewardDB format.
static func login_reward(day: int, rng: RandomNumberGenerator) -> Dictionary:
	var r := RewardDB.empty()
	var spec: Dictionary = LOGIN[clampi(day, 1, LOGIN.size()) - 1]
	var shards := int(spec.get("shards", 0))
	if bool(spec.get("box", false)):
		r["gold"] = BOX_GOLD
		r["gems"] = BOX_GEMS
		shards = BOX_SHARDS
	else:
		r["gold"] = int(spec.get("gold", 0))
	var owned := PlayerData.owned_types()
	if shards > 0 and not owned.is_empty():
		r["shards"][owned[rng.randi() % owned.size()]] = shards
	return r
