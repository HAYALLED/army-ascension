extends Node
## Headless tests for missions, achievements, daily login and the sound / music settings. Run:
##   godot --headless --path . res://Tools/test_missions.tscn
## Uses user://test_save.* only; the player's real save is never touched.

const TEST_PATH := "user://test_save.json"
const SETTINGS := preload("res://Scene/Menus/Popups/SettingsPopup.tscn")
const DAY := 1000

var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.enabled = true
	SaveManager.save_path = TEST_PATH
	await _run()
	_clean()
	MissionManager.day_override = -1
	get_tree().quit(0 if _failed == 0 else 1)


func _run() -> void:
	_clean()
	_test_progress_and_claim()
	_test_spend_and_gauges()
	_test_reward_rules()
	_test_period_reset()
	_test_login()
	_test_battle_end()
	_test_save()
	await _test_audio_settings()


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


func _reset(day: int = DAY) -> void:
	MissionManager.day_override = day
	PlayerData.reset_to_defaults()
	Game.reset_run()
	SaveManager._dirty = false


func _row(scope: String, id: String) -> Dictionary:
	for r in MissionManager.list(scope):
		if r["id"] == id:
			return r
	return {}


# 1
func _test_progress_and_claim() -> void:
	_reset()
	_check("1a lists: 4 daily, 6 weekly, 15 achievements",
		MissionManager.list("daily").size() == 4 and MissionManager.list("weekly").size() == 6
		and MissionManager.list("achievements").size() == 15)
	var untouched := MissionManager.list("daily").all(func(r: Dictionary) -> bool: return r["progress"] == 0 and not r["complete"])
	_check("1b nothing moves until a game is played", untouched)
	_check("1c unfinished mission cannot be claimed", MissionManager.claim("daily", "d_win").is_empty())
	MissionManager.record_battle(true, 200, 3)
	_check("1d one played battle: 1/3 battles, win and kills done",
		_row("daily", "d_battles")["progress"] == 1 and not _row("daily", "d_battles")["complete"]
		and _row("daily", "d_win")["complete"] and _row("daily", "d_kills")["complete"])
	var gold := PlayerData.gold
	var r := MissionManager.claim("daily", "d_win")
	_check("1e claim pays the gold once", int(r.get("gold", 0)) == 250 and PlayerData.gold == gold + 250)
	_check("1f second claim refused", MissionManager.claim("daily", "d_win").is_empty() and PlayerData.gold == gold + 250)
	var rows := MissionManager.list("daily")
	_check("1g list order: claimable, in progress, claimed last",
		rows[0]["complete"] and not rows[0]["claimed"] and rows[rows.size() - 1]["claimed"])
	_check("1h unknown scope / id claim -> {}", MissionManager.claim("nope", "d_win").is_empty() and MissionManager.claim("daily", "zzz").is_empty())
	MissionManager.record_battle(false, 0, 0)
	_check("1i a lost battle still counts as played", _row("daily", "d_battles")["progress"] == 2 and _row("daily", "d_win")["claimed"])


# 2
func _test_spend_and_gauges() -> void:
	_reset()
	PlayerData.gold = 100000
	PlayerData.shards[SoldierDB.Type.RIFLEMAN] = 1000
	var cost := SoldierDB.upgrade_gold(1)
	_check("2a soldier upgrade works", PlayerData.try_upgrade(SoldierDB.Type.RIFLEMAN))
	var id := GlobalUpgradeDB.Id.DAMAGE
	var cost2 := GlobalUpgradeDB.cost(id, 0)
	_check("2b army upgrade works", PlayerData.try_buy_upgrade(id))
	_check("2c gold spent and upgrades counted (daily, weekly, lifetime)",
		MissionManager.value("daily", "gold_spent") == cost + cost2
		and MissionManager.value("weekly", "upgrades") == 2
		and MissionManager.value("achievements", "gold_spent") == cost + cost2)
	_check("2d first upgrade achievement completes", _row("achievements", "a_upg_1")["complete"])
	PlayerData.complete_level(3)
	_check("2e beat-level achievement follows highest_level", _row("achievements", "a_lvl_3")["complete"] and not _row("achievements", "a_lvl_5")["complete"])
	_check("2f soldier-level achievement follows the best soldier", _row("achievements", "a_unit_3")["progress"] == 2 and not _row("achievements", "a_unit_3")["complete"])
	PlayerData.levels[SoldierDB.Type.SNIPER] = 5
	_check("2g reaching level 5 completes the level 3 and 5 achievements",
		_row("achievements", "a_unit_3")["complete"] and _row("achievements", "a_unit_5")["complete"] and not _row("achievements", "a_unit_10")["complete"])
	PlayerData.gold = 10
	var before := MissionManager.value("daily", "gold_spent")
	PlayerData.try_buy_upgrade(id)
	_check("2h failed purchase counts nothing", MissionManager.value("daily", "gold_spent") == before)


# 3
func _test_reward_rules() -> void:
	var ok := true
	for m in MissionDB.ACHIEVEMENTS:
		ok = ok and (int(m.get("gold", 0)) > 0) != (int(m.get("gems", 0)) > 0)
	_check("3a every achievement pays gold or gems, never both", ok)
	var basic := ["a_win_1", "a_upg_1", "a_battle_10", "a_lvl_3", "a_unit_3", "a_spend_1k", "a_kills_500"]
	var gold_only := true
	for id in basic:
		var m := MissionDB.find("achievements", id)
		gold_only = gold_only and int(m.get("gold", 0)) > 0 and int(m.get("gems", 0)) == 0
	_check("3b basic achievements give gold only", gold_only)
	var ids := {}
	var unique := true
	for scope in MissionDB.SCOPES:
		for m in MissionDB.list(scope):
			unique = unique and not ids.has(m["id"])
			ids[m["id"]] = true
	_check("3c mission ids are unique", unique)


# 4
func _test_period_reset() -> void:
	_reset(DAY)
	MissionManager.record_battle(true, 10, 1)
	MissionManager.claim("daily", "d_win")
	MissionManager.day_override = DAY + 1
	_check("4a next day: daily progress and claims reset",
		MissionManager.value("daily", "battles") == 0 and not _row("daily", "d_win")["claimed"])
	_check("4b weekly and lifetime stay inside the week",
		MissionManager.value("weekly", "battles") == 1 and MissionManager.value("achievements", "battles") == 1)
	MissionManager.record_battle(true, 10, 1)
	MissionManager.claim("weekly", "w_battles")
	MissionManager.day_override = DAY + 5
	_check("4c new week: weekly resets, lifetime stays",
		MissionManager.value("weekly", "battles") == 0 and MissionManager.value("achievements", "battles") == 2)


# 5
func _test_login() -> void:
	_reset(2000)
	var rng := RandomNumberGenerator.new()
	_check("5a first login is day 1", MissionManager.login_next_day() == 1 and MissionManager.login_claimed_days() == 0)
	var gold := PlayerData.gold
	var r := MissionManager.claim_login(rng)
	_check("5b day 1 pays 100 gold", int(r.get("gold", 0)) == 100 and PlayerData.gold == gold + 100)
	_check("5c once per day", MissionManager.claim_login(rng).is_empty() and MissionManager.login_next_day() == 0 and MissionManager.login_claimed_days() == 1)
	MissionManager.day_override = 1999
	_check("5d clock moved back cannot claim again", MissionManager.login_next_day() == 0)
	MissionManager.day_override = 2001
	_check("5e next day continues the streak (day 2)", MissionManager.login_next_day() == 2 and MissionManager.login_claimed_days() == 1)
	MissionManager.claim_login(rng)
	MissionManager.day_override = 2002
	var total_shards := PlayerData.total_shards()
	r = MissionManager.claim_login(rng)
	_check("5f day 3 pays 5 shards to one owned soldier", PlayerData.total_shards() == total_shards + 5 and r["shards"].size() == 1)
	MissionManager.day_override = 2004
	_check("5g a missed day starts again at day 1", MissionManager.login_next_day() == 1 and MissionManager.login_claimed_days() == 0)
	for i in 7:
		MissionManager.day_override = 2010 + i
		var n := MissionManager.login_next_day()
		if i == 6:
			var gems := PlayerData.gems
			gold = PlayerData.gold
			total_shards = PlayerData.total_shards()
			r = MissionManager.claim_login(rng)
			_check("5h day 7 box: 400 gold, 3 gems, 15 shards",
				n == 7 and PlayerData.gold == gold + MissionDB.BOX_GOLD and PlayerData.gems == gems + MissionDB.BOX_GEMS
				and PlayerData.total_shards() == total_shards + MissionDB.BOX_SHARDS)
		else:
			MissionManager.claim_login(rng)
	MissionManager.day_override = 2017
	_check("5i after day 7 the strip starts over", MissionManager.login_next_day() == 1 and MissionManager.login_claimed_days() == 0)


# 6
func _test_battle_end() -> void:
	_reset()
	Game.state = Game.State.PLAYING
	Game.kills = 30
	Game.shards = 2
	Game.end_battle(true)
	_check("6a a finished battle feeds the missions (battle, win, kills, shards)",
		MissionManager.value("daily", "battles") == 1 and MissionManager.value("daily", "wins") == 1
		and MissionManager.value("daily", "kills") == 30 and MissionManager.value("weekly", "shards") == 2)
	Game.end_battle(true)
	_check("6b a battle is counted once", MissionManager.value("daily", "battles") == 1)
	_reset()


# 7
func _test_save() -> void:
	_reset(3000)
	MissionManager.record_battle(true, 160, 4)
	MissionManager.claim("daily", "d_win")
	MissionManager.claim_login(RandomNumberGenerator.new())
	SaveManager._dirty = true
	SaveManager.save_now()
	var rows_before := MissionManager.list("daily")
	var next_before := MissionManager.login_next_day()
	PlayerData.reset_to_defaults()
	SaveManager.load_game()
	_check("7a missions, claims and login survive save / load",
		MissionManager.value("daily", "kills") == 160 and _row("daily", "d_win")["claimed"]
		and MissionManager.login_next_day() == next_before and next_before == 0 and rows_before.size() == MissionManager.list("daily").size())
	PlayerData.apply_save({"missions": "junk"})
	_check("7b junk missions block -> clean state", MissionManager.value("daily", "kills") == 0 and MissionManager.login_next_day() == 1)
	PlayerData.apply_save({"missions": {
		"day": -5, "week": 9999999, "daily": {"kills": -3, "bogus": 9, "battles": "x"}, "life": {"wins": 1e30},
		"claimed": {"daily": ["d_win", "zzz", 7, "d_win"], "achievements": "no"}, "login": {"day": 99, "last": 99999999}}})
	var ok := MissionManager.value("daily", "kills") == 0 and MissionManager.value("daily", "battles") == 0
	ok = ok and MissionManager.value("achievements", "wins") <= PlayerData.MAX_CURRENCY
	ok = ok and MissionManager.to_save()["login"]["day"] == MissionDB.LOGIN.size() and MissionManager.to_save()["login"]["last"] <= 3000
	_check("7c hostile values are clamped / dropped", ok)
	MissionManager.day_override = 3000
	PlayerData.apply_save({"missions": {"day": 3000, "week": 428, "claimed": {"daily": ["d_win", "zzz", 7, "d_win"]}}})
	_check("7d claim list keeps only known ids, once", MissionManager.to_save()["claimed"]["daily"] == ["d_win"])
	_reset()


# 8
func _test_audio_settings() -> void:
	_reset()
	AudioManager.stop_music()
	var popup := SETTINGS.instantiate()
	add_child(popup)
	await get_tree().process_frame
	var sound: Button = popup.get_node("%SoundToggle")
	var music: Button = popup.get_node("%MusicToggle")
	AudioManager.play_music()
	_check("8a music is playing", AudioManager._music.playing)
	music.button_pressed = false
	_check("8b music off stops it", not AudioManager.music_enabled and not AudioManager._music.playing)
	music.button_pressed = true
	_check("8c music on again starts it again", AudioManager.music_enabled and AudioManager._music.playing)
	sound.button_pressed = false
	_check("8d sound off", not AudioManager.sfx_enabled)
	sound.button_pressed = true
	_check("8e sound on again", AudioManager.sfx_enabled)
	music.button_pressed = false
	sound.button_pressed = false
	SaveManager.save_now()
	popup.free()
	AudioManager.sfx_enabled = true
	AudioManager.music_enabled = true
	PlayerData.reset_to_defaults()
	SaveManager.load_game()
	_check("8f both stay off after a restart (save / load)", not AudioManager.sfx_enabled and not AudioManager.music_enabled and not AudioManager._music.playing)
	var reopened := SETTINGS.instantiate()
	add_child(reopened)
	await get_tree().process_frame
	var music2: Button = reopened.get_node("%MusicToggle")
	_check("8g settings popup shows them OFF", not music2.button_pressed and music2.text == "OFF")
	music2.button_pressed = true
	_check("8h turning music on after a restart plays it", AudioManager.music_enabled and AudioManager._music.playing)
	reopened.free()
	AudioManager.stop_music()
