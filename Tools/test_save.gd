extends Node
## Headless save-system tests. Run:
##   godot --headless --path . res://Tools/test_save.tscn
## Uses user://test_save.* only; the player's real save is never touched.

const TEST_PATH := "user://test_save.json"

var _failed := 0


func _ready() -> void:
	SaveManager.enabled = true
	SaveManager.save_path = TEST_PATH
	await _run()
	_clean()
	SaveManager.read_only = false
	get_tree().quit(0 if _failed == 0 else 1)


func _run() -> void:
	_clean()
	_test_defaults()
	_test_round_trip()
	_test_bak_recovery()
	_test_bad_checksum()
	_test_both_corrupt()
	_test_hostile_data()
	_test_newer_version()
	_test_bad_version()
	_test_two_saves()
	_test_level_progress()
	_test_chapters()
	await _test_coalesce()


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _clean() -> void:
	for ext in ["json", "bak", "tmp", "corrupt"]:
		var p: String = "user://test_save." + ext
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	SaveManager._dirty = false
	SaveManager.read_only = false


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text()
	f.close()
	return t


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _envelope(data: Dictionary, version: Variant = 1) -> String:
	var body := JSON.stringify(data)
	return JSON.stringify({"version": version, "saved_at": 0, "sum": body.sha256_text(), "body": body})


func _store(data: Dictionary) -> void:
	PlayerData.apply_save(data)
	SaveManager._dirty = true
	SaveManager.save_now()


# 1
func _test_defaults() -> void:
	_clean()
	PlayerData.gold = 5
	SaveManager.load_game()
	var ok := PlayerData.gold == PlayerData.START_GOLD
	ok = ok and PlayerData.shards_of(SoldierDB.Type.RIFLEMAN) == PlayerData.START_SHARDS
	ok = ok and PlayerData.highest_level == 0
	for t in SoldierDB.DATA:
		ok = ok and PlayerData.level_of(t) == 1
	_check("1 defaults when no files exist", ok)


# 2
func _test_round_trip() -> void:
	_clean()
	PlayerData.reset_to_defaults()
	PlayerData.gold = 1234
	PlayerData.levels[SoldierDB.Type.RIFLEMAN] = 4
	PlayerData.shards[SoldierDB.Type.RIFLEMAN] = 7
	PlayerData.highest_level = 3
	PlayerData.set_setting("vibration", false)
	AudioManager.sfx_enabled = false
	SaveManager._dirty = true
	SaveManager.save_now()
	PlayerData.reset_to_defaults()
	SaveManager.load_game()
	var ok := PlayerData.gold == 1234
	ok = ok and PlayerData.level_of(SoldierDB.Type.RIFLEMAN) == 4
	ok = ok and PlayerData.shards_of(SoldierDB.Type.RIFLEMAN) == 7
	ok = ok and PlayerData.highest_level == 3
	ok = ok and PlayerData.settings["vibration"] == false
	ok = ok and AudioManager.sfx_enabled == false
	_check("2 round trip", ok)
	PlayerData.reset_to_defaults()


# 3
func _test_bak_recovery() -> void:
	_clean()
	PlayerData.reset_to_defaults()
	PlayerData.gold = 111
	SaveManager._dirty = true
	SaveManager.save_now()
	PlayerData.gold = 222
	SaveManager._dirty = true
	SaveManager.save_now()   # bak now holds gold 111
	_write_text(TEST_PATH, "{ garbage")
	SaveManager.load_game()
	var ok := PlayerData.gold == 111
	SaveManager.save_now()   # load from bak requested a repair save
	ok = ok and SaveManager._read(TEST_PATH) != null
	_check("3 garbled main -> loads .bak and repairs main", ok)
	PlayerData.reset_to_defaults()


# 4
func _test_bad_checksum() -> void:
	_clean()
	var body := JSON.stringify({"gold": 5})
	_write_text(TEST_PATH, JSON.stringify({"version": 1, "saved_at": 0, "sum": body.sha256_text(), "body": JSON.stringify({"gold": 999})}))
	_check("4 body edited without fixing sum is rejected", SaveManager._read(TEST_PATH) == null)


# 5
func _test_both_corrupt() -> void:
	_clean()
	_write_text(TEST_PATH, "nope")
	_write_text("user://test_save.bak", "also nope")
	PlayerData.gold = 5
	SaveManager.load_game()
	var ok := PlayerData.gold == PlayerData.START_GOLD
	ok = ok and FileAccess.file_exists("user://test_save.corrupt")
	_check("5 both corrupt -> defaults, .corrupt created", ok)


# 6
func _test_hostile_data() -> void:
	_clean()
	PlayerData.apply_save({
		"gold": -5, "gems": "abc",
		"soldiers": {
			"rifleman": {"level": 999, "shards": -4},
			"sniper": {"level": 0, "shards": 3.0},
			"ghost": {"level": 5, "shards": 5},
			"medic": "bad",
		},
		"progress": {"highest_level": 9999},
		"settings": {"vibration": "yes", "sfx": false, "extra": true},
		"extra_root": 1,
	})
	var ok := PlayerData.gold == 0
	ok = ok and PlayerData.gems == PlayerData.START_GEMS
	ok = ok and PlayerData.level_of(SoldierDB.Type.RIFLEMAN) == SoldierDB.MAX_LEVEL
	ok = ok and PlayerData.shards_of(SoldierDB.Type.RIFLEMAN) == 0
	ok = ok and PlayerData.level_of(SoldierDB.Type.SNIPER) == 1
	ok = ok and PlayerData.shards_of(SoldierDB.Type.SNIPER) == 3
	ok = ok and PlayerData.level_of(SoldierDB.Type.MEDIC) == 1
	ok = ok and PlayerData.highest_level == LevelDB.TOTAL_LEVELS
	ok = ok and PlayerData.settings["vibration"] == true
	ok = ok and AudioManager.sfx_enabled == false
	ok = ok and not PlayerData.settings.has("extra")
	PlayerData.apply_save({})
	ok = ok and PlayerData.gold == PlayerData.START_GOLD
	PlayerData.apply_save({"soldiers": 5, "progress": [], "settings": "x", "gold": null})
	ok = ok and PlayerData.gold == PlayerData.START_GOLD
	_check("6 hostile data clamped or defaulted", ok)
	PlayerData.reset_to_defaults()


# 7
func _test_newer_version() -> void:
	_clean()
	_write_text(TEST_PATH, _envelope({"gold": 777}, 99))
	var before := _read_text(TEST_PATH)
	PlayerData.gold = 5
	SaveManager.load_game()
	var ok := SaveManager.read_only
	ok = ok and PlayerData.gold == PlayerData.START_GOLD
	SaveManager.request_save()
	SaveManager.save_now()
	ok = ok and _read_text(TEST_PATH) == before
	_check("7 newer version is read-only and never overwritten", ok)
	SaveManager.read_only = false


# 8
func _test_bad_version() -> void:
	_clean()
	var ok := true
	_write_text(TEST_PATH, JSON.stringify({"sum": "x", "body": "{}"}))
	ok = ok and SaveManager._read(TEST_PATH) == null
	_write_text(TEST_PATH, _envelope({"gold": 1}, 1.5))
	ok = ok and SaveManager._read(TEST_PATH) == null
	_write_text(TEST_PATH, _envelope({"gold": 1}, "1"))
	ok = ok and SaveManager._read(TEST_PATH) == null
	_write_text(TEST_PATH, _envelope({"gold": 1}, 0))
	ok = ok and SaveManager._read(TEST_PATH) == null
	_write_text(TEST_PATH, _envelope({"gold": 1}, 1))
	ok = ok and SaveManager._read(TEST_PATH) != null
	_check("8 missing / non-integer version is invalid", ok)


# 9
func _test_two_saves() -> void:
	_clean()
	PlayerData.reset_to_defaults()
	SaveManager._dirty = true
	SaveManager.save_now()
	PlayerData.gold = 42
	SaveManager._dirty = true
	SaveManager.save_now()
	var ok := not FileAccess.file_exists("user://test_save.tmp")
	ok = ok and SaveManager._read("user://test_save.bak") != null
	ok = ok and SaveManager._read(TEST_PATH) != null
	_check("9 no .tmp left, .bak valid after two saves", ok)
	PlayerData.reset_to_defaults()


# 10
func _test_level_progress() -> void:
	PlayerData.reset_to_defaults()
	var ok := true
	PlayerData.complete_level(1)
	ok = ok and PlayerData.highest_level == 1
	PlayerData.complete_level(1)
	ok = ok and PlayerData.highest_level == 1
	PlayerData.complete_level(0)
	PlayerData.complete_level(-3)
	PlayerData.complete_level(LevelDB.TOTAL_LEVELS + 1)
	ok = ok and PlayerData.highest_level == 1
	PlayerData.complete_level(3)
	PlayerData.complete_level(2)
	ok = ok and PlayerData.highest_level == 3
	PlayerData.complete_level(LevelDB.TOTAL_LEVELS)
	ok = ok and PlayerData.unlocked_level() == LevelDB.TOTAL_LEVELS
	_check("10 level progress rules", ok)
	PlayerData.reset_to_defaults()


# 11
func _test_chapters() -> void:
	var ok := LevelDB.chapter_of(1) == 1
	ok = ok and LevelDB.chapter_of(LevelDB.LEVELS_PER_CHAPTER) == 1
	ok = ok and LevelDB.chapter_of(LevelDB.LEVELS_PER_CHAPTER + 1) == 2
	_check("11 chapter_of", ok)


# 12
func _test_coalesce() -> void:
	_clean()
	PlayerData.reset_to_defaults()
	var before := SaveManager.write_count
	for i in 20:
		PlayerData.add_gold(1)
		SaveManager.request_save()
	await get_tree().process_frame
	await get_tree().process_frame
	_check("12 20 requests in one frame -> one write", SaveManager.write_count == before + 1)
	PlayerData.reset_to_defaults()
