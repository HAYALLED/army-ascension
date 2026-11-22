extends Node
## Player profile (autoload "PlayerData"): wallet, soldier levels, class shards,
## army-wide upgrades, settings and level progress. Persistence lives in SaveManager; this script only
## serialises (to_save) and validates (apply_save). Every transaction is validated:
## balances never go negative.

signal wallet_changed()
signal soldier_changed(type: int)
signal global_upgrade_changed(id: int)
signal level_progress_changed()
signal settings_changed()
## Purchases or timers changed (shop, chest cooldown).
signal shop_changed()
## Gold was spent on an upgrade (soldier or army). Missions count it.
signal spent(gold: int)

## Dev starting wallet so the upgrade menu can be tried right away.
const START_GOLD := 600
const START_SHARDS := 12
const START_GEMS := 0
const MAX_CURRENCY := 999_999_999

var gold: int = START_GOLD
var gems: int = START_GEMS
var levels: Dictionary = {}   # SoldierDB.Type -> level
var shards: Dictionary = {}   # SoldierDB.Type -> shard count
## Army-wide upgrades (Upgrades tab): GlobalUpgradeDB.Id -> level. Per-unit levels above
## belong to the Soldiers tab; the two systems never touch each other.
var upgrades: Dictionary = {}
## Highest level number the player has completed (0 = none).
var highest_level: int = 0
## Player settings. sfx / music mirror AudioManager, which owns the live flags.
var settings: Dictionary = {}
## One-time shop products the player owns: ProductDB id -> true.
var purchases: Dictionary = {}
## Unix time when the next free chest is ready (0 = ready now).
var chest_ready_at: int = 0


func _ready() -> void:
	reset_to_defaults()


## Fresh profile. Does not emit signals (see notify_all).
func reset_to_defaults() -> void:
	gold = START_GOLD
	gems = START_GEMS
	levels.clear()
	shards.clear()
	upgrades.clear()
	for t in SoldierDB.DATA:
		levels[t] = 1
		shards[t] = 0
	for u in GlobalUpgradeDB.DATA:
		upgrades[u] = 0
	shards[SoldierDB.Type.RIFLEMAN] = START_SHARDS
	highest_level = 0
	purchases.clear()
	chest_ready_at = 0
	MissionManager.reset()
	settings = {"vibration": true, "graphics_high": true, "sfx": true, "music": true}
	_push_audio_settings()


## Tells every listener to refresh after a bulk change (load, reset).
func notify_all() -> void:
	wallet_changed.emit()
	for t in SoldierDB.DATA:
		soldier_changed.emit(t)
	for u in GlobalUpgradeDB.DATA:
		global_upgrade_changed.emit(u)
	level_progress_changed.emit()
	settings_changed.emit()
	shop_changed.emit()


func set_setting(key: String, value: bool) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	settings_changed.emit()


func level_of(type: int) -> int:
	return int(levels.get(type, 1))


func shards_of(type: int) -> int:
	return int(shards.get(type, 0))


func total_shards() -> int:
	var n := 0
	for t in shards:
		n += int(shards[t])
	return n


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	wallet_changed.emit()


func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	gems = mini(gems + amount, MAX_CURRENCY)
	wallet_changed.emit()


func add_shards(type: int, amount: int) -> void:
	if amount <= 0 or not shards.has(type):
		return
	shards[type] += amount
	wallet_changed.emit()
	soldier_changed.emit(type)


func can_upgrade(type: int) -> bool:
	var lv := level_of(type)
	return lv < SoldierDB.MAX_LEVEL \
		and gold >= SoldierDB.upgrade_gold(lv) \
		and shards_of(type) >= SoldierDB.upgrade_shards(lv)


## Spends gold + class shards and raises the level. Returns false (and
## changes nothing) when the player cannot afford it.
func try_upgrade(type: int) -> bool:
	if not can_upgrade(type):
		return false
	var lv := level_of(type)
	var cost := SoldierDB.upgrade_gold(lv)
	gold -= cost
	shards[type] -= SoldierDB.upgrade_shards(lv)
	levels[type] = lv + 1
	wallet_changed.emit()
	soldier_changed.emit(type)
	spent.emit(cost)
	return true


## ---- Army-wide upgrades (Upgrades tab) ---------------------------------------

func upgrade_level(id: int) -> int:
	return int(upgrades.get(id, 0))


func can_buy_upgrade(id: int) -> bool:
	if not GlobalUpgradeDB.DATA.has(id):
		return false
	var lv := upgrade_level(id)
	return lv < GlobalUpgradeDB.max_level(id) and gold >= GlobalUpgradeDB.cost(id, lv)


## Spends gold and raises the upgrade one level. Returns false (and changes nothing)
## when it is maxed out or the player cannot afford it.
func try_buy_upgrade(id: int) -> bool:
	if not can_buy_upgrade(id):
		return false
	var lv := upgrade_level(id)
	var cost := GlobalUpgradeDB.cost(id, lv)
	gold -= cost
	upgrades[id] = lv + 1
	wallet_changed.emit()
	global_upgrade_changed.emit(id)
	spent.emit(cost)
	return true


## Multipliers / bonuses read by the battle (1.0 = no upgrade bought).
func income_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.INCOME, upgrade_level(GlobalUpgradeDB.Id.INCOME))


func damage_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.DAMAGE, upgrade_level(GlobalUpgradeDB.Id.DAMAGE))


func health_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.HEALTH, upgrade_level(GlobalUpgradeDB.Id.HEALTH))


func rate_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.FIRE_RATE, upgrade_level(GlobalUpgradeDB.Id.FIRE_RATE))


func shard_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.SHARD_LUCK, upgrade_level(GlobalUpgradeDB.Id.SHARD_LUCK))


## Extra soldiers every battle starts with.
func start_bonus_soldiers() -> int:
	return int(round(GlobalUpgradeDB.value(GlobalUpgradeDB.Id.REINFORCEMENTS, upgrade_level(GlobalUpgradeDB.Id.REINFORCEMENTS))))


## ---- Ownership, rewards, shop ------------------------------------------------

## True when the player has this soldier class. Every class is owned from the start for now;
## when classes become unlockable, only this function changes.
func owns(type: int) -> bool:
	return levels.has(type)


func owned_types() -> Array[int]:
	var out: Array[int] = []
	for t in SoldierDB.DATA:
		if owns(t):
			out.append(t)
	return out


## Applies a RewardDB reward ({"gold", "gems", "shards": {type: n}}). Shards for a class the
## player does not own are dropped.
func grant(reward: Dictionary) -> void:
	add_gold(int(reward.get("gold", 0)))
	add_gems(int(reward.get("gems", 0)))
	var s: Dictionary = reward.get("shards", {})
	for t in s:
		if owns(t):
			add_shards(t, int(s[t]))


func has_purchase(id: String) -> bool:
	return purchases.has(id)


func mark_purchased(id: String) -> void:
	if ProductDB.is_once(id) and not purchases.has(id):
		purchases[id] = true
		shop_changed.emit()


func chest_seconds_left() -> int:
	return maxi(chest_ready_at - int(Time.get_unix_time_from_system()), 0)


func start_chest_cooldown() -> void:
	chest_ready_at = int(Time.get_unix_time_from_system()) + RewardDB.CHEST_COOLDOWN
	shop_changed.emit()


## ---- Level progress --------------------------------------------------------

## Level the player plays next (highest completed + 1, capped at the last level).
func unlocked_level() -> int:
	return mini(highest_level + 1, LevelDB.TOTAL_LEVELS)


## Records a completed level. Never lowers progress; out-of-range indices are ignored.
func complete_level(index: int) -> void:
	if index < 1 or index > LevelDB.TOTAL_LEVELS:
		return
	if index > highest_level:
		highest_level = index
		level_progress_changed.emit()


## ---- Serialisation ----------------------------------------------------------

## Save-file data (schema version 1, see Docs/SAVE_SYSTEM_PLAN.md).
func to_save() -> Dictionary:
	var soldiers := {}
	for t in SoldierDB.DATA:
		soldiers[SoldierDB.id_of(t)] = {"level": level_of(t), "shards": shards_of(t)}
	var global_upgrades := {}
	for u in GlobalUpgradeDB.DATA:
		global_upgrades[GlobalUpgradeDB.id_of(u)] = upgrade_level(u)
	return {
		"gold": gold,
		"gems": gems,
		"soldiers": soldiers,
		"upgrades": global_upgrades,
		"progress": {"highest_level": highest_level},
		"purchases": purchases.keys(),
		"timers": {"chest_ready_at": chest_ready_at},
		"missions": MissionManager.to_save(),
		"settings": {
			"vibration": bool(settings.get("vibration", true)),
			"graphics_high": bool(settings.get("graphics_high", true)),
			"sfx": AudioManager.sfx_enabled,
			"music": AudioManager.music_enabled,
		},
	}


## Loads save data. Every field is validated; invalid or missing fields keep their
## defaults and unknown keys are dropped. Never throws.
func apply_save(d: Dictionary) -> void:
	reset_to_defaults()
	gold = _read_int(d.get("gold"), 0, MAX_CURRENCY, gold)
	gems = _read_int(d.get("gems"), 0, MAX_CURRENCY, gems)

	var soldiers: Variant = d.get("soldiers")
	if soldiers is Dictionary:
		for id in soldiers:
			if not (id is String):
				continue
			var type := SoldierDB.type_of(id)
			if type < 0 or not (soldiers[id] is Dictionary):
				continue
			var entry: Dictionary = soldiers[id]
			levels[type] = _read_int(entry.get("level"), 1, SoldierDB.MAX_LEVEL, level_of(type))
			shards[type] = _read_int(entry.get("shards"), 0, MAX_CURRENCY, shards_of(type))

	var saved_upgrades: Variant = d.get("upgrades")
	if saved_upgrades is Dictionary:
		for uid in saved_upgrades:
			if not (uid is String):
				continue
			var u := GlobalUpgradeDB.from_id(uid)
			if u < 0:
				continue
			upgrades[u] = _read_int(saved_upgrades[uid], 0, GlobalUpgradeDB.max_level(u), 0)

	var progress: Variant = d.get("progress")
	if progress is Dictionary:
		highest_level = _read_int(progress.get("highest_level"), 0, LevelDB.TOTAL_LEVELS, highest_level)

	var saved_purchases: Variant = d.get("purchases")
	if saved_purchases is Array:
		for pid in saved_purchases:
			if pid is String and ProductDB.is_once(pid):
				purchases[pid] = true

	var timers: Variant = d.get("timers")
	if timers is Dictionary:
		# Capped at one cooldown from now, so a bad value or a changed clock never locks the chest for long.
		var now := int(Time.get_unix_time_from_system())
		chest_ready_at = _read_int(timers.get("chest_ready_at"), 0, now + RewardDB.CHEST_COOLDOWN, 0)

	MissionManager.apply_save(d.get("missions"))

	var saved_settings: Variant = d.get("settings")
	if saved_settings is Dictionary:
		for key in settings:
			if saved_settings.get(key) is bool:
				settings[key] = saved_settings[key]
	_push_audio_settings()
	notify_all()


## Number validated and clamped to lo..hi; `fallback` when the value is not a finite number.
static func _read_int(v: Variant, lo: int, hi: int, fallback: int) -> int:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return fallback
	var f := float(v)
	if not is_finite(f):
		return fallback
	return int(clampf(f, float(lo), float(hi)))


func _push_audio_settings() -> void:
	AudioManager.sfx_enabled = bool(settings.get("sfx", true))
	AudioManager.music_enabled = bool(settings.get("music", true))
	if not AudioManager.music_enabled:
		AudioManager.stop_music()
