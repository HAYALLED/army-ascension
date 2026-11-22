extends Node
## Headless tests for rewarded ads, chests, revive, double gold and the purchase flow. Run:
##   godot --headless --path . res://Tools/test_monetization.tscn
## Uses user://test_save.* only; the player's real save is never touched.

const TEST_PATH := "user://test_save.json"

## Scripted ad backend: answers `earned` one frame after show().
class FakeAds extends AdProvider:
	var earned := true
	var shown := 0
	var hang := false

	func is_ready() -> bool:
		return true

	func show(_placement: String) -> void:
		shown += 1
		if not hang:
			finished.emit.call_deferred(earned)

## Store that never answers (timeout test).
class SilentBilling extends BillingProvider:
	func purchase(_product_id: String) -> void:
		pass

var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.enabled = true
	SaveManager.save_path = TEST_PATH
	await _run()
	_clean()
	get_tree().paused = false
	get_tree().quit(0 if _failed == 0 else 1)


func _run() -> void:
	_clean()
	PlayerData.reset_to_defaults()
	_test_chest_roll()
	_test_grant()
	_test_save_fields()
	await _test_ads()
	await _test_double_gold()
	await _test_revive_flow()
	await _test_purchases()


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


func _reset() -> void:
	PlayerData.reset_to_defaults()
	Game.reset_run()
	Game.sim_mode = false
	SaveManager._dirty = false


# 1
func _test_chest_roll() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var ok := true
	var gems := 0
	var seen := {}
	var n := 200000
	for i in n:
		var r := RewardDB.roll_chest(rng)
		var shards: Dictionary = r["shards"]
		ok = ok and shards.size() == 1
		for t in shards:
			ok = ok and int(shards[t]) >= RewardDB.CHEST_SHARDS_MIN and int(shards[t]) <= RewardDB.CHEST_SHARDS_MAX
			seen[int(shards[t])] = true
		ok = ok and int(r["gold"]) >= RewardDB.CHEST_GOLD_MIN and int(r["gold"]) <= RewardDB.CHEST_GOLD_MAX
		ok = ok and (int(r["gems"]) == 0 or int(r["gems"]) == 1)
		gems += int(r["gems"])
	_check("1a chest: 2-7 shards on one soldier, few coins", ok and seen.size() == 6)
	# Expected 200 gems (0.1%); +-5 sigma is 130..270.
	_check("1b chest: gem chance about 0.1%% (%d gems in %d)" % [gems, n], gems >= 130 and gems <= 270)


# 2
func _test_grant() -> void:
	_reset()
	var T := SoldierDB.Type
	var r := RewardDB.empty()
	r["gold"] = 40
	r["gems"] = 1
	r["shards"] = {T.SNIPER: 5, 999: 9}
	PlayerData.grant(r)
	var ok := PlayerData.gold == PlayerData.START_GOLD + 40
	ok = ok and PlayerData.gems == 1
	ok = ok and PlayerData.shards_of(T.SNIPER) == 5
	ok = ok and not PlayerData.shards.has(999)
	_check("2 grant adds gold, gems, owned shards; unowned class dropped", ok)
	_check("2b owned_types lists every class", PlayerData.owned_types().size() == SoldierDB.DATA.size() and not PlayerData.owns(999))


# 3
func _test_save_fields() -> void:
	_reset()
	PlayerData.mark_purchased("remove_ads")
	PlayerData.mark_purchased("gold_s")  # not a one-time product: ignored
	PlayerData.start_chest_cooldown()
	var at := PlayerData.chest_ready_at
	SaveManager._dirty = true
	SaveManager.save_now()
	PlayerData.reset_to_defaults()
	SaveManager.load_game()
	var ok := PlayerData.has_purchase("remove_ads") and not PlayerData.has_purchase("gold_s")
	ok = ok and PlayerData.chest_ready_at == at and PlayerData.chest_seconds_left() > 0
	_check("3a purchases and chest timer survive save/load", ok)
	PlayerData.apply_save({"purchases": ["bogus", 5, "season_pass", "gold_m"], "timers": {"chest_ready_at": 9999999999999}})
	ok = PlayerData.has_purchase("season_pass") and not PlayerData.has_purchase("bogus") and not PlayerData.has_purchase("gold_m")
	ok = ok and PlayerData.chest_seconds_left() <= RewardDB.CHEST_COOLDOWN
	PlayerData.apply_save({"purchases": "x", "timers": [1]})
	ok = ok and PlayerData.purchases.is_empty() and PlayerData.chest_ready_at == 0
	_check("3b hostile purchase / timer data is cleaned", ok)


# 4
func _test_ads() -> void:
	_reset()
	var saved := AdService.provider
	var fake := FakeAds.new()
	AdService.provider = fake
	var ok := await AdService.show_rewarded("t") == true and fake.shown == 1
	fake.earned = false
	ok = ok and await AdService.show_rewarded("t") == false
	_check("4a ad result: earned true / closed early false", ok)
	fake.earned = true
	fake.hang = true
	var first := {}
	var run_first := func() -> void: first["v"] = await AdService.show_rewarded("t")  # stays busy
	run_first.call()
	await get_tree().process_frame
	var second := await AdService.show_rewarded("t")
	_check("4b second ad while one is running is refused", second == false and fake.shown == 3)
	fake.finished.emit(true)
	await get_tree().process_frame
	_check("4c first ad still completes", first.get("v") == true)
	fake.hang = false
	AdService.provider = null
	_check("4d no provider -> unavailable, no reward", not AdService.is_available() and await AdService.show_rewarded("t") == false)
	PlayerData.mark_purchased("remove_ads")
	_check("4e remove_ads -> instant reward without a provider", AdService.is_available() and await AdService.show_rewarded("t") == true)
	AdService.provider = saved


# 5
func _test_double_gold() -> void:
	_reset()
	AdService.provider = FakeAds.new()
	Game.state = Game.State.WON
	Game.credited_gold = 100
	var before := PlayerData.gold
	var ok := Game.can_double_gold() and Game.double_gold()
	ok = ok and PlayerData.gold == before + 100
	_check("5a double gold credits the battle gold once more", ok)
	_check("5b second claim refused", not Game.can_double_gold() and not Game.double_gold() and PlayerData.gold == before + 100)
	Game.reset_run()
	Game.state = Game.State.LOST
	Game.credited_gold = 0
	_check("5c nothing to double when no gold was credited", not Game.can_double_gold())
	Game.credited_gold = 50
	Game.sim_mode = true
	_check("5d never in --sim", not Game.can_double_gold())
	Game.sim_mode = false
	Game.state = Game.State.PLAYING
	_check("5e not while playing", not Game.can_double_gold())
	AdService.provider = null


# 6
func _test_revive_flow() -> void:
	_reset()
	AdService.provider = FakeAds.new()
	Game.state = Game.State.PLAYING
	Game.end_battle(false)
	var ok := Game.state == Game.State.REVIVE and get_tree().paused and PlayerData.highest_level == 0
	var gold_before := PlayerData.gold
	_check("6a defeat with ads available offers a revive and pays nothing yet", ok and Game.credited_gold == 0)
	Game.end_battle(true)
	_check("6b end_battle is ignored while the revive is on offer", Game.state == Game.State.REVIVE)
	Game.decline_revive()
	_check("6c declining finishes the defeat (half gold paid, tree unpaused)",
		Game.state == Game.State.LOST and not get_tree().paused and PlayerData.gold >= gold_before)
	_reset()
	Game.state = Game.State.PLAYING
	Game.revive_used = true
	Game.end_battle(false)
	_check("6d only one revive per run", Game.state == Game.State.LOST)
	_reset()
	Game.sim_mode = true
	Game.state = Game.State.PLAYING
	Game.end_battle(false)
	_check("6e no revive in --sim", Game.state == Game.State.LOST)
	_reset()
	AdService.provider = null
	Game.state = Game.State.PLAYING
	Game.end_battle(false)
	_check("6f no ad available -> plain defeat", Game.state == Game.State.LOST)
	_reset()
	Game.state = Game.State.REVIVE
	Game.revive()
	_check("6g revive without an army does nothing", Game.state == Game.State.REVIVE and not Game.revive_used)
	_reset()


# 7
func _test_purchases() -> void:
	_reset()
	var T := SoldierDB.Type
	var pm := PurchaseManager
	var saved := pm.provider
	var mock := MockBillingProvider.new(get_tree())
	pm.provider = mock
	pm.timeout = 45.0

	var gold := PlayerData.gold
	var writes := SaveManager.write_count
	var r: Dictionary = await pm.buy("gold_s")
	_check("7a gold pack pays +500 gold and saves at once",
		r["ok"] and PlayerData.gold == gold + 500 and SaveManager.write_count > writes and pm.state == PurchaseManager.State.IDLE)

	var shards := PlayerData.shards_of(T.SNIPER)
	r = await pm.buy("shards_m", T.SNIPER)
	_check("7b shard pack goes to the chosen soldier", r["ok"] and PlayerData.shards_of(T.SNIPER) == shards + 60)

	gold = PlayerData.gold
	shards = PlayerData.shards_of(T.ROCKET)
	r = await pm.buy("shards_s", -1)
	_check("7c shard pack without a soldier is refused, nothing charged",
		not r["ok"] and PlayerData.shards_of(T.ROCKET) == shards and PlayerData.gold == gold)

	r = await pm.buy("remove_ads")
	var again: Dictionary = await pm.buy("remove_ads")
	_check("7d remove ads is bought once", r["ok"] and PlayerData.has_purchase("remove_ads") and not again["ok"] and again["message"] == "Already owned")

	r = await pm.buy("season_pass")
	_check("7e season pass is not for sale yet", not r["ok"] and not PlayerData.has_purchase("season_pass"))

	r = await pm.buy("nope")
	_check("7f unknown product refused", not r["ok"])

	gold = PlayerData.gold
	mock.fail_next = true
	r = await pm.buy("gold_m")
	_check("7g declined payment grants nothing and unlocks the UI",
		not r["ok"] and PlayerData.gold == gold and pm.state == PurchaseManager.State.IDLE)

	var first := {}
	var run_first := func() -> void: first["v"] = await pm.buy("gold_l")
	run_first.call()
	await get_tree().process_frame
	var second: Dictionary = await pm.buy("gold_m")
	while not first.has("v"):
		await get_tree().process_frame
	var first_result: Dictionary = first["v"]
	_check("7h second purchase during payment refused; first still completes",
		not second["ok"] and first_result["ok"] and PlayerData.gold == gold + 5000)

	gold = PlayerData.gold
	shards = PlayerData.shards_of(T.MEDIC)
	r = await pm.buy("starter_bundle", T.MEDIC)
	var again2: Dictionary = await pm.buy("starter_bundle", T.MEDIC)
	var shard_gain := PlayerData.shards_of(T.MEDIC) - shards
	_check("7i starter bundle: 1000 gold + 30 shards + a chest, once",
		r["ok"] and PlayerData.gold >= gold + 1000 + RewardDB.CHEST_GOLD_MIN and shard_gain >= 30 and not again2["ok"])

	pm.provider = SilentBilling.new()
	pm.timeout = 0.3
	gold = PlayerData.gold
	r = await pm.buy("gold_s")
	_check("7j silent store times out, grants nothing, unlocks the UI",
		not r["ok"] and PlayerData.gold == gold and pm.state == PurchaseManager.State.IDLE)

	pm.provider = null
	r = await pm.buy("gold_s")
	_check("7k no store provider (release build) -> Store not available", not r["ok"] and r["message"] == "Store not available")

	pm.provider = saved
	pm.timeout = 45.0
