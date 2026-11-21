extends Node
## Player profile (autoload "PlayerData"): wallet, soldier levels, class shards,
## settings and level progress. Persistence lives in SaveManager; this script only
## serialises (to_save) and validates (apply_save). Every transaction is validated:
## balances never go negative.

signal wallet_changed()
signal soldier_changed(type: int)
signal level_progress_changed()
signal settings_changed()

## Dev starting wallet so the upgrade menu can be tried right away.
const START_GOLD := 600
const START_SHARDS := 12
const START_GEMS := 0
const MAX_CURRENCY := 999_999_999

var gold: int = START_GOLD
var gems: int = START_GEMS
var levels: Dictionary = {}   # SoldierDB.Type -> level
var shards: Dictionary = {}   # SoldierDB.Type -> shard count
## Highest level number the player has completed (0 = none).
var highest_level: int = 0
## Player settings. sfx / music mirror AudioManager, which owns the live flags.
var settings: Dictionary = {}


func _ready() -> void:
	reset_to_defaults()


## Fresh profile. Does not emit signals (see notify_all).
func reset_to_defaults() -> void:
	gold = START_GOLD
	gems = START_GEMS
	levels.clear()
	shards.clear()
	for t in SoldierDB.DATA:
		levels[t] = 1
		shards[t] = 0
	shards[SoldierDB.Type.RIFLEMAN] = START_SHARDS
	highest_level = 0
	settings = {"vibration": true, "graphics_high": true, "sfx": true, "music": true}
	_push_audio_settings()


## Tells every listener to refresh after a bulk change (load, reset).
func notify_all() -> void:
	wallet_changed.emit()
	for t in SoldierDB.DATA:
		soldier_changed.emit(t)
	level_progress_changed.emit()
	settings_changed.emit()


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
	gold -= SoldierDB.upgrade_gold(lv)
	shards[type] -= SoldierDB.upgrade_shards(lv)
	levels[type] = lv + 1
	wallet_changed.emit()
	soldier_changed.emit(type)
	return true


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
	return {
		"gold": gold,
		"gems": gems,
		"soldiers": soldiers,
		"progress": {"highest_level": highest_level},
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

	var progress: Variant = d.get("progress")
	if progress is Dictionary:
		highest_level = _read_int(progress.get("highest_level"), 0, LevelDB.TOTAL_LEVELS, highest_level)

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
