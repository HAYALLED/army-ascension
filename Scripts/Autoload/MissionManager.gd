extends Node
## Daily / weekly missions, achievements and the 7-day login (autoload "MissionManager").
## Progress comes from played battles (record_battle) and from gold spent on upgrades. Daily and weekly
## counters reset on a new local day / week. State is saved through PlayerData (to_save / apply_save).
## Autoload order: after PlayerData, before SaveManager.
##
## shortcut: days come from the device clock, so changing the phone date resets dailies;
## upgrade to a server time check when an online backend exists.

signal changed()

## Plain var so tests can fake "today" (day number since 1970-01-01). -1 = real clock.
var day_override := -1

var _day := 0
var _week := 0
var _daily: Dictionary = {}
var _weekly: Dictionary = {}
var _life: Dictionary = {}
var _claimed: Dictionary = {"daily": [], "weekly": [], "achievements": []}
var _login_day := 0
var _login_last := -1
var _tick := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PlayerData.spent.connect(_on_spent)


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		_roll()


## Local day number since 1970-01-01.
func current_day() -> int:
	if day_override >= 0:
		return day_override
	var d := Time.get_datetime_dict_from_system(false)
	var midnight := Time.get_unix_time_from_datetime_dict(
		{"year": d["year"], "month": d["month"], "day": d["day"], "hour": 0, "minute": 0, "second": 0})
	return floori(midnight / 86400.0)


## Everything back to a fresh profile. No signal (see apply_save).
func reset() -> void:
	_day = current_day()
	_week = floori((_day + 3) / 7.0)
	_daily = {}
	_weekly = {}
	_life = {}
	_claimed = {"daily": [], "weekly": [], "achievements": []}
	_login_day = 0
	_login_last = -1


## ---- Progress -------------------------------------------------------------

## Called once when a battle ends (win or loss). Missions only move by playing.
func record_battle(won: bool, kills: int, shards: int) -> void:
	_roll()
	_bump("battles", 1)
	if won:
		_bump("wins", 1)
	_bump("kills", kills)
	_bump("shards", shards)
	changed.emit()


func value(scope: String, stat: String) -> int:
	_roll()
	match scope:
		"daily":
			return int(_daily.get(stat, 0))
		"weekly":
			return int(_weekly.get(stat, 0))
	match stat:
		MissionDB.STAT_LEVEL:
			return PlayerData.highest_level
		MissionDB.STAT_UNIT_LEVEL:
			var best := 1
			for t in PlayerData.levels:
				best = maxi(best, PlayerData.level_of(t))
			return best
	return int(_life.get(stat, 0))


## Rows for the Missions page: claimable first, then in progress, then claimed.
## Each row: {id, title, goal, progress, complete, claimed, reward}.
func list(scope: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var order := 0
	for m in MissionDB.list(scope):
		var goal := int(m["goal"])
		var have := value(scope, String(m["stat"]))
		var claimed := is_claimed(scope, String(m["id"]))
		var complete := have >= goal
		rows.append({
			"id": m["id"], "title": m["title"], "goal": goal, "progress": mini(have, goal),
			"complete": complete, "claimed": claimed, "reward": MissionDB.reward_of(m),
			"_rank": (2 if claimed else (0 if complete else 1)) * 1000 + order,
		})
		order += 1
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["_rank"] < b["_rank"])
	return rows


func is_claimed(scope: String, id: String) -> bool:
	_roll()
	return _claimed.has(scope) and id in _claimed[scope]


## Pays a finished mission. Returns the reward, or {} when it is unknown, unfinished or already claimed.
func claim(scope: String, id: String) -> Dictionary:
	var m := MissionDB.find(scope, id)
	if m.is_empty() or is_claimed(scope, id) or value(scope, String(m["stat"])) < int(m["goal"]):
		return {}
	_claimed[scope].append(id)
	var reward := MissionDB.reward_of(m)
	PlayerData.grant(reward)
	changed.emit()
	SaveManager.save_now()
	return reward


## ---- Daily login ----------------------------------------------------------

## Login day (1..7) the player can claim now, 0 when today is already claimed.
## Claiming on consecutive days walks 1..7; a missed day starts again at 1.
func login_next_day() -> int:
	var today := current_day()
	if _login_last >= today:
		return 0
	if _login_last == today - 1:
		return _login_day % MissionDB.LOGIN.size() + 1
	return 1


## Days of the 7-day strip already claimed in the running cycle.
func login_claimed_days() -> int:
	var next := login_next_day()
	return _login_day if next == 0 else next - 1


## Pays today's login reward. Returns {} when it was already claimed today.
func claim_login(rng: RandomNumberGenerator) -> Dictionary:
	var n := login_next_day()
	if n == 0:
		return {}
	var reward := MissionDB.login_reward(n, rng)
	_login_day = n
	_login_last = current_day()
	PlayerData.grant(reward)
	changed.emit()
	SaveManager.save_now()
	return reward


## ---- Serialisation --------------------------------------------------------

func to_save() -> Dictionary:
	return {
		"day": _day, "week": _week,
		"daily": _daily.duplicate(), "weekly": _weekly.duplicate(), "life": _life.duplicate(),
		"claimed": {
			"daily": _claimed["daily"].duplicate(),
			"weekly": _claimed["weekly"].duplicate(),
			"achievements": _claimed["achievements"].duplicate(),
		},
		"login": {"day": _login_day, "last": _login_last},
	}


## Validates and loads saved data. Bad or missing fields keep their defaults; never throws.
func apply_save(v: Variant) -> void:
	reset()
	if v is Dictionary:
		var today := current_day()
		_day = PlayerData._read_int(v.get("day"), 0, today, 0)
		_week = PlayerData._read_int(v.get("week"), 0, floori((today + 3) / 7.0), 0)
		_daily = _read_stats(v.get("daily"))
		_weekly = _read_stats(v.get("weekly"))
		_life = _read_stats(v.get("life"))
		var claimed: Variant = v.get("claimed")
		if claimed is Dictionary:
			for scope in MissionDB.SCOPES:
				var ids: Variant = claimed.get(scope)
				if ids is Array:
					for id in ids:
						if id is String and not MissionDB.find(scope, id).is_empty() and not id in _claimed[scope]:
							_claimed[scope].append(id)
		var login: Variant = v.get("login")
		if login is Dictionary:
			_login_day = PlayerData._read_int(login.get("day"), 0, MissionDB.LOGIN.size(), 0)
			_login_last = PlayerData._read_int(login.get("last"), -1, today, -1)
	_roll()
	changed.emit()


## ---- Internals ------------------------------------------------------------

static func _read_stats(v: Variant) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for stat in MissionDB.STATS:
			if v.has(stat):
				out[stat] = PlayerData._read_int(v[stat], 0, PlayerData.MAX_CURRENCY, 0)
	return out


## Adds to a stat in the day, week and lifetime counters. Does not emit.
func _bump(stat: String, n: int) -> void:
	if n <= 0 or not stat in MissionDB.STATS:
		return
	for bucket in [_daily, _weekly, _life]:
		bucket[stat] = mini(int(bucket.get(stat, 0)) + n, PlayerData.MAX_CURRENCY)


## Starts a new day / week: clears that period's counters and claims.
func _roll() -> void:
	var today := current_day()
	var week := floori((today + 3) / 7.0)
	var rolled := false
	if today != _day:
		_day = today
		_daily = {}
		_claimed["daily"] = []
		rolled = true
	if week != _week:
		_week = week
		_weekly = {}
		_claimed["weekly"] = []
		rolled = true
	if rolled:
		changed.emit()


func _on_spent(gold: int) -> void:
	_roll()
	_bump("gold_spent", gold)
	_bump("upgrades", 1)
	changed.emit()
