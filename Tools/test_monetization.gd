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

## Scripted real-store stand-in: answers purchase() with `token` (or fails), counts calls and records, at the
## moment of every confirm_delivery(), whether `disk_probe` finds the purchase already saved.
class FakeStore extends BillingProvider:
	var token := "tok-1"
	var ok := true
	var error := "Purchase canceled"
	var hang := false
	var bought := 0
	var confirms: Array = []
	var prices := {}
	var disk_probe := Callable()
	var _tokens := {}

	func purchase(id: String) -> void:
		bought += 1
		if hang:
			return
		if ok:
			_tokens[id] = token
		finished.emit.call_deferred(id, ok, "" if ok else error)

	func token_of(id: String) -> String:
		return String(_tokens.get(id, ""))

	func confirm_delivery(id: String, t: String) -> void:
		confirms.append([id, t, bool(disk_probe.call(t)) if disk_probe.is_valid() else false])

	func price_of(id: String) -> String:
		return String(prices.get(id, ""))

	func restore() -> void:
		restore_finished.emit.call_deferred("")

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
	await _test_no_ads_perk()
	await _test_revive_flow()
	await _test_purchases()
	await _test_billing()
	await _test_google_provider()
	_test_guard()
	await _test_shop_ui()


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
			ok = ok and int(shards[t]) >= 3 and int(shards[t]) <= 5
			seen[int(shards[t])] = true
		ok = ok and int(r["gold"]) >= 50 and int(r["gold"]) <= 100
		ok = ok and (int(r["gems"]) == 0 or int(r["gems"]) == 1)
		gems += int(r["gems"])
	_check("1a free chest = wooden chest: 3-5 shards on one soldier, 50-100 gold", ok and seen.size() == 3)
	# Expected 4000 gems (2%); +-5 sigma is 3690..4310.
	_check("1b chest: gem chance about 2%% (%d gems in %d)" % [gems, n], gems >= 3690 and gems <= 4310)


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
	_check("2b owned_types lists every class", PlayerData.owned_types().size() == SoldierDB.listed_types().size() and not PlayerData.owns(999))


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
	PlayerData.apply_save({"purchases": ["bogus", 5, "starter_bundle", "gold_m"], "timers": {"chest_ready_at": 9999999999999}})
	ok = PlayerData.has_purchase("starter_bundle") and not PlayerData.has_purchase("bogus") and not PlayerData.has_purchase("gold_m")
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
	_check("4e remove_ads does not skip rewarded ads (still need a provider)", not AdService.is_available() and await AdService.show_rewarded("t") == false)
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


# 5x: NO RANDOM ADS perk (free trial + purchase): auto 2X gold, random ad after every 2 battles otherwise
func _test_no_ads_perk() -> void:
	_reset()
	var saved := AdService.provider
	var ads := FakeAds.new()
	AdService.provider = ads
	Game.battles_since_ad = 0
	Game.interstitial_due = false
	_check("5x1 new profile starts with a %d battle trial" % PlayerData.NO_ADS_TRIAL_BATTLES, PlayerData.no_ads_trial_left == 3 and PlayerData.has_no_ads())
	Game.gold = 100
	Game.state = Game.State.PLAYING
	Game.end_battle(true)
	_check("5x2 trial battle pays 2X gold on its own and uses one trial battle",
		Game.auto_doubled and Game.credited_gold == 200 and PlayerData.no_ads_trial_left == 2 and not Game.can_double_gold())
	for i in 2:
		Game.reset_run()
		Game.gold = 100
		Game.state = Game.State.PLAYING
		Game.end_battle(true)
	_check("5x3 trial over after 3 battles, no random ad during it", PlayerData.no_ads_trial_left == 0 and not PlayerData.has_no_ads() and not Game.interstitial_due and ads.shown == 0)
	Game.reset_run()
	Game.gold = 100
	Game.state = Game.State.PLAYING
	Game.end_battle(true)
	_check("5x4 after the trial: normal gold, no 2X, first battle plays no ad yet", not Game.auto_doubled and Game.credited_gold == 100 and not Game.interstitial_due)
	await Game.play_due_interstitial()
	_check("5x5 nothing due -> no ad", ads.shown == 0)
	Game.reset_run()
	Game.state = Game.State.PLAYING
	Game.end_battle(false)
	Game.revive_used = true
	_check("5x6 revive offer is not an ad due", true)
	Game.decline_revive()
	_check("5x7 second battle makes a random ad due", Game.interstitial_due)
	await Game.play_due_interstitial()
	_check("5x8 random ad plays once and the counter restarts", ads.shown == 1 and not Game.interstitial_due and Game.battles_since_ad == 0)
	PlayerData.mark_purchased("remove_ads")
	for i in 3:
		Game.reset_run()
		Game.gold = 50
		Game.state = Game.State.PLAYING
		Game.end_battle(true)
	await Game.play_due_interstitial()
	_check("5x9 owner: always 2X, never a random ad", Game.auto_doubled and Game.credited_gold == 100 and not Game.interstitial_due and ads.shown == 1)
	_check("5x10 owner still watches rewarded ads", await AdService.show_rewarded("t") == true and ads.shown == 2)
	AdService.provider = null
	_check("5x11 owner without ad provider gets no rewarded ad", not AdService.is_available() and await AdService.show_rewarded("t") == false)
	Game.sim_mode = true
	_reset()
	Game.sim_mode = true
	Game.gold = 100
	Game.end_battle(true)
	_check("5x12 --sim: no auto 2X and no trial use", not Game.auto_doubled and PlayerData.no_ads_trial_left == 3 and Game.credited_gold == 100)
	Game.sim_mode = false
	PlayerData.apply_save({"no_ads_trial_left": 99})
	_check("5x13 save: trial counter is clamped, missing key means full trial", PlayerData.no_ads_trial_left == 3)
	PlayerData.no_ads_trial_left = 1
	var saved_data := JSON.parse_string(JSON.stringify(PlayerData.to_save())) as Dictionary
	PlayerData.apply_save(saved_data)
	_check("5x14 save: trial counter survives", PlayerData.no_ads_trial_left == 1)
	AdService.provider = saved
	_reset()


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

	var gems := PlayerData.gems
	r = await pm.buy("gems_s")
	_check("7b small gem pack pays +40 gems", r["ok"] and PlayerData.gems == gems + 40)
	_check("7b2 the shop sells no shard packs", not ProductDB.has("shards_s") and not ProductDB.has("shards_m") and not ProductDB.has("shards_l"))

	gold = PlayerData.gold
	var shards := PlayerData.shards_of(T.ROCKET)
	r = await pm.buy("starter_bundle", -1)
	_check("7c starter bundle without a soldier is refused, nothing charged",
		not r["ok"] and PlayerData.shards_of(T.ROCKET) == shards and PlayerData.gold == gold and not PlayerData.has_purchase("starter_bundle"))

	r = await pm.buy("remove_ads")
	var again: Dictionary = await pm.buy("remove_ads")
	_check("7d remove ads is bought once", r["ok"] and PlayerData.has_purchase("remove_ads") and not again["ok"] and again["message"] == "Already owned")

	_check("7e season pass is gone", not ProductDB.has("season_pass"))

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
		r["ok"] and PlayerData.gold >= gold + 1000 + 50 and shard_gain >= 30 and not again2["ok"])

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


# ---- 8: real-store pipeline (FakeStore) ---------------------------------------------------------

func _on_disk(token: String) -> bool:
	var r: Variant = SaveManager._read(TEST_PATH)
	if r == null:
		return false
	var billing: Variant = (r["data"] as Dictionary).get("billing", {})
	return billing is Dictionary and (billing.get("delivered", []) as Array).has(token.sha256_text())


func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame


func _fresh_store(token: String) -> FakeStore:
	_reset()
	SaveManager.read_only = false
	PurchaseManager._live.clear()
	var store := FakeStore.new()
	store.token = token
	store.disk_probe = _on_disk
	PurchaseManager.provider = store
	PurchaseManager.timeout = 120.0
	return store


func _test_billing() -> void:
	var T := SoldierDB.Type
	var pm := PurchaseManager
	var saved := pm.provider
	var notices: Array[String] = []
	var on_notice := func(text: String) -> void: notices.append(text)
	pm.notice.connect(on_notice)

	# 8a success: reward granted, saved, confirm only AFTER the save is on disk
	var store := _fresh_store("tok-a")
	var gold := PlayerData.gold
	var r: Dictionary = await pm.buy("gold_s")
	_check("8a paid purchase: +500 gold, token hash on disk, confirm called once, after the save",
		r["ok"] and PlayerData.gold == gold + 500 and store.confirms.size() == 1
		and store.confirms[0][0] == "gold_s" and store.confirms[0][1] == "tok-a" and store.confirms[0][2] == true)
	_check("8a2 delivered list holds the hash, not the token", PlayerData.delivered_tokens == [("tok-a").sha256_text()])

	# 8b canceled / failed: nothing granted, UI unlocked, nothing confirmed
	store = _fresh_store("tok-b")
	store.ok = false
	gold = PlayerData.gold
	r = await pm.buy("gold_s")
	_check("8b canceled payment: no reward, no confirm, UI unlocked",
		not r["ok"] and r["message"] == "Purchase canceled" and PlayerData.gold == gold
		and store.confirms.is_empty() and pm.state == PurchaseManager.State.IDLE and PlayerData.delivered_tokens.is_empty())

	# 8d same token twice -> granted once; 8m both arrival paths at once
	store = _fresh_store("tok-dup")
	store.hang = true
	gold = PlayerData.gold
	var first := {}
	var run_first := func() -> void: first["v"] = await pm.buy("gold_s")
	run_first.call()
	await _frames()
	store.purchase_recovered.emit("gold_s", "tok-dup")  # the query path reports it while the payment is open
	_check("8m query path is ignored while the payment of that product is open", PlayerData.gold == gold and store.confirms.is_empty())
	store._tokens["gold_s"] = "tok-dup"
	store.finished.emit("gold_s", true, "")
	while not first.has("v"):
		await _frames(1)
	store.purchase_recovered.emit("gold_s", "tok-dup")
	store.purchase_recovered.emit("gold_s", "tok-dup")
	_check("8d same token reported again and again: granted once (+500), only re-confirmed",
		first["v"]["ok"] and PlayerData.gold == gold + 500 and store.confirms.size() == 3)

	# 8e recovered purchase: delivered once, then confirmed after the save
	store = _fresh_store("x")
	gold = PlayerData.gold
	store.purchase_recovered.emit("gold_m", "tok-r1")
	_check("8e recovered gold_m: +1500 once, confirmed after the save",
		PlayerData.gold == gold + 1500 and store.confirms.size() == 1 and store.confirms[0][2] == true)
	store.purchase_recovered.emit("gold_m", "tok-r1")
	_check("8e2 the same recovered purchase never pays twice", PlayerData.gold == gold + 1500)

	# 8f recovered starter_bundle: kept pending, not confirmed, until a soldier is picked
	store = _fresh_store("x")
	gold = PlayerData.gold
	var shards := PlayerData.shards_of(T.MEDIC)
	store.purchase_recovered.emit("starter_bundle", "tok-s1")
	_check("8f recovered starter bundle waits for a soldier: nothing granted, nothing confirmed, queued",
		PlayerData.gold == gold and store.confirms.is_empty() and PlayerData.pending_deliveries.size() == 1
		and not PlayerData.has_purchase("starter_bundle"))
	var pick := {}
	var run_pick := func() -> void: pick["v"] = await pm.resolve_pending(self)
	run_pick.call()
	await _frames()
	for child in get_children():
		if child is UnitPickerPopup:
			(child as UnitPickerPopup)._finish(T.MEDIC)
	while not pick.has("v"):
		await _frames(1)
	var done: Dictionary = pick["v"]
	_check("8f2 after the pick: bundle delivered (gold, shards, owned), queue empty, confirmed",
		done["ok"] and PlayerData.gold >= gold + 1000 and PlayerData.shards_of(T.MEDIC) >= shards + 30
		and PlayerData.has_purchase("starter_bundle") and PlayerData.pending_deliveries.is_empty()
		and store.confirms.size() == 1 and store.confirms[0][1] == "tok-s1")
	_check("8f3 pending queue survives save / load as hashes",
		(func() -> bool:
			store.purchase_recovered.emit("starter_bundle", "tok-s2")  # owned now: acknowledged, no reward
			return PlayerData.pending_deliveries.is_empty()).call())

	# 8g late answer after the timeout is delivered through recovery
	store = _fresh_store("tok-late")
	store.hang = true
	pm.timeout = 0.2
	gold = PlayerData.gold
	r = await pm.buy("gold_s")
	_check("8g payment sheet too slow: timed out, UI unlocked, nothing granted yet",
		not r["ok"] and pm.state == PurchaseManager.State.IDLE and PlayerData.gold == gold)
	store._tokens["gold_s"] = "tok-late"
	store.finished.emit("gold_s", true, "")
	_check("8g2 the late payment is delivered by recovery and confirmed", PlayerData.gold == gold + 500 and store.confirms.size() == 1)
	pm.timeout = 120.0

	# 8h one-time product restore: OWNED, no reward
	store = _fresh_store("x")
	gold = PlayerData.gold
	store.ownership_restored.emit("remove_ads")
	_check("8h restore marks remove_ads owned without a reward", PlayerData.has_purchase("remove_ads") and PlayerData.gold == gold)
	store = _fresh_store("x")
	store.purchase_recovered.emit("remove_ads", "tok-ra")
	_check("8h2 unconfirmed remove_ads: owned, empty reward, acknowledged", PlayerData.has_purchase("remove_ads") and store.confirms.size() == 1 and PlayerData.gold == PlayerData.START_GOLD)
	store.ownership_restored.emit("gold_s")
	_check("8h3 a consumable is never 'restored'", not PlayerData.has_purchase("gold_s"))

	# 8i no provider (release build): store not available, never a mock
	pm.provider = null
	r = await pm.buy("gold_s")
	_check("8i no provider -> Store not available", not r["ok"] and r["message"] == "Store not available")
	_check("8i2 provider_kind: release off Android has no store, mock only in debug off Android",
		pm.provider_kind(false, false, false) == &"none" and pm.provider_kind(false, true, false) == &"mock"
		and pm.provider_kind(false, false, true) == &"none" and pm.provider_kind(true, true, false) == &"none"
		and pm.provider_kind(true, false, false) == &"none" and pm.provider_kind(true, false, true) == &"google"
		and pm.provider_kind(true, true, true) == &"google")

	# 8j old save without the new fields loads unchanged; hostile billing data is cleaned
	_reset()
	PlayerData.apply_save({"gold": 123, "purchases": ["remove_ads"]})
	_check("8j old save (no billing key) loads, billing lists empty", PlayerData.gold == 123 and PlayerData.has_purchase("remove_ads")
		and PlayerData.delivered_tokens.is_empty() and PlayerData.pending_deliveries.is_empty())
	var good := ("tok-ok").sha256_text()
	var many: Array = []
	for i in 80:
		many.append(("t%d" % i).sha256_text())
	PlayerData.apply_save({"billing": {"delivered": ["nothex", 5] + many + [good, good, "A".repeat(64)],
		"pending": [{"id": "gold_s", "hash": good}, {"id": "starter_bundle", "hash": "x"}, {"id": "bogus", "hash": good}, 7]}})
	_check("8j2 hostile billing data: only valid hashes, no duplicates, capped at %d, bad pending dropped" % PlayerData.MAX_DELIVERED,
		PlayerData.delivered_tokens.size() == PlayerData.MAX_DELIVERED and PlayerData.pending_deliveries.is_empty()
		and not PlayerData.delivered_tokens.has("nothex"))
	PlayerData.apply_save({"billing": "x"})
	_check("8j3 billing of the wrong type is ignored", PlayerData.delivered_tokens.is_empty())

	# 8k save fails / read-only: nothing confirmed, nothing granted, purchase stays undelivered, retried later
	store = _fresh_store("tok-k")
	gold = PlayerData.gold
	SaveManager.read_only = true
	r = await pm.buy("gold_s")
	_check("8k read-only save: no confirm, grant rolled back, hash not stored, toast text",
		not r["ok"] and r["message"] == "Could not save, will retry" and store.confirms.is_empty()
		and PlayerData.gold == gold and not PlayerData.is_delivered(("tok-k").sha256_text()))
	SaveManager.read_only = false
	store.purchase_recovered.emit("gold_s", "tok-k")
	_check("8k2 the same purchase is delivered once the save works again", PlayerData.gold == gold + 500 and store.confirms.size() == 1)
	_check("8k3 persist_now: false when read-only, true when written",
		(func() -> bool:
			SaveManager.read_only = true
			var a := SaveManager.persist_now()
			SaveManager.read_only = false
			return not a and SaveManager.persist_now()).call())

	# 8l granted but not confirmed (crash after the save): next launch only confirms
	store = _fresh_store("x")
	store.purchase_recovered.emit("gold_l", "tok-crash")
	var after := PlayerData.gold
	store.confirms.clear()
	PlayerData.reset_to_defaults()  # the app restarted: memory is gone, the save file stays
	SaveManager.load_game()
	store.purchase_recovered.emit("gold_l", "tok-crash")
	_check("8l after a restart the saved purchase is only confirmed, never granted again",
		PlayerData.gold == after and store.confirms.size() == 1 and store.confirms[0][1] == "tok-crash")

	# 8n wallet near the cap: refused before payment; a paid recovery still pays
	store = _fresh_store("tok-n")
	PlayerData.gold = PlayerData.MAX_CURRENCY - 100
	r = await pm.buy("gold_s")
	_check("8n wallet would overflow: refused before the store is asked", not r["ok"] and r["message"] == "Wallet full" and store.bought == 0)
	store.purchase_recovered.emit("gold_s", "tok-n2")
	_check("8n2 already paid (recovery): granted anyway", PlayerData.gold == PlayerData.MAX_CURRENCY)

	# 8o double tap on BUY
	store = _fresh_store("tok-o")
	store.hang = true
	var run_o := func() -> void: await pm.buy("gold_m")
	run_o.call()
	await _frames()
	var second: Dictionary = await pm.buy("gold_m")
	_check("8o second BUY while paying is refused, the store is asked once", not second["ok"] and second["message"] == "Another purchase is in progress" and store.bought == 1)
	store._tokens["gold_m"] = "tok-o"
	store.finished.emit("gold_m", true, "")
	await _frames()

	# 8p stored tokens: hashes only, newest 50
	store = _fresh_store("x")
	for i in 55:
		store.purchase_recovered.emit("gold_s", "tok-secret-%d" % i)
	var text := FileAccess.get_file_as_string(TEST_PATH)
	var hashes_only := true
	for h in PlayerData.delivered_tokens:
		hashes_only = hashes_only and h.length() == 64
	_check("8p delivered list: 64-char hashes only, capped at 50, no raw token in the save file",
		PlayerData.delivered_tokens.size() == 50 and hashes_only and not text.contains("tok-secret") and PlayerData.is_delivered(("tok-secret-54").sha256_text())
		and not PlayerData.is_delivered(("tok-secret-0").sha256_text()))

	# 8q restore button flow and prices
	store = _fresh_store("x")
	notices.clear()
	store.prices["gold_s"] = "TRY 29.99"
	pm.restore()
	await _frames()
	_check("8q restore with nothing owned says so; price_of reads the store", notices == ["Nothing to restore"] and pm.price_of("gold_s") == "TRY 29.99" and pm.price_of("gold_m") == "")

	pm.notice.disconnect(on_notice)
	pm.provider = saved
	pm.timeout = 120.0
	_reset()


# ---- 9: the real provider fed with crafted purchase dictionaries (no Android needed) --------------

func _purchase(id: String, state: int = 1, token: String = "tok-p", ack: bool = false, pkg: String = "com.test.app") -> Dictionary:
	return {"order_id": "o-1", "purchase_token": token, "package_name": pkg, "purchase_state": state, "purchase_time": 0,
		"original_json": "{}", "is_acknowledged": ack, "quantity": 1, "signature": "sig", "product_ids": [id]}


func _test_google_provider() -> void:
	var script := load("res://Scripts/Monetization/GooglePlayBillingProvider.gd") as GDScript
	_check("9a provider script compiles with the plugin installed", script != null and script.can_instantiate())
	var gp := script.new(self, Callable()) as BillingProvider
	(gp.get("_verifier") as PurchaseVerifier).package_name = "com.test.app"
	var fin: Array = []
	var rec: Array = []
	var own: Array = []
	var prices_signals := [0]
	gp.finished.connect(func(id: String, ok: bool, err: String) -> void: fin.append([id, ok, err]))
	gp.purchase_recovered.connect(func(id: String, t: String) -> void: rec.append([id, t]))
	gp.ownership_restored.connect(func(id: String) -> void: own.append(id))
	gp.prices_updated.connect(func() -> void: prices_signals[0] += 1)

	gp.set("_expecting", "gold_s")
	gp.call("_on_updated", {"response_code": 0, "purchases": [_purchase("gold_s", 2)]})
	await _frames()
	_check("9b PENDING payment: no reward path, one error answer, nothing recovered",
		fin.size() == 1 and fin[0][1] == false and String(fin[0][2]).begins_with("Payment pending") and rec.is_empty())

	fin.clear()
	gp.set("_expecting", "gold_s")
	gp.call("_on_updated", {"response_code": 0, "purchases": [_purchase("gold_s")]})
	await _frames()
	_check("9c PURCHASED answer: finished ok exactly once, token handed over, not recovered",
		fin.size() == 1 and fin[0][1] == true and gp.token_of("gold_s") == "tok-p" and rec.is_empty())

	fin.clear()
	gp.set("_expecting", "gold_s")
	gp.call("_on_updated", {"response_code": 1, "purchases": []})
	await _frames()
	_check("9d user canceled: one error answer 'Purchase canceled'", fin.size() == 1 and fin[0][1] == false and fin[0][2] == "Purchase canceled")

	fin.clear()
	gp.call("_on_updated", {"response_code": 0, "purchases": [_purchase("gold_m", 1, "tok-late")]})
	await _frames()
	_check("9e answer nobody waits for (after the timeout) is reported as recovered", fin.is_empty() and rec == [["gold_m", "tok-late"]])

	rec.clear()
	gp.call("_on_owned", {"response_code": 0, "purchases": [_purchase("gold_l", 1, "tok-q"), _purchase("remove_ads", 1, "tok-ra", true),
		_purchase("remove_ads", 2, "tok-pend"), _purchase("nope", 1, "tok-x")]})
	await _frames()
	_check("9f query: unacknowledged paid -> recovered; acknowledged one-time -> ownership; pending / unknown ignored",
		rec == [["gold_l", "tok-q"]] and own == ["remove_ads"])

	rec.clear()
	fin.clear()
	var bad_pkg := _purchase("gold_s", 1, "tok-bp", false, "com.evil.app")
	var no_sig := _purchase("gold_s", 1, "tok-ns")
	no_sig.erase("signature")
	var wrong_id := _purchase("gold_s", 1, "tok-wi")
	wrong_id["product_ids"] = ["gold_l"]
	gp.call("_on_owned", {"response_code": 0, "purchases": [bad_pkg, no_sig]})
	gp.set("_expecting", "gold_s")
	gp.call("_on_updated", {"response_code": 0, "purchases": [wrong_id]})
	await _frames()
	_check("9g wrong package / missing signature are rejected; a purchase of another product is not paid as this one",
		not rec.has(["gold_s", "tok-bp"]) and not rec.has(["gold_s", "tok-ns"]) and not fin.any(func(f: Array) -> bool: return f[1] == true))

	gp.call("_on_details", {"response_code": 0, "product_details": [{"product_id": "gold_s", "one_time_purchase_offer_details_list": [{"formatted_price": "TRY 29,99"}]}], "unfetched_products": []})
	var first_count: int = prices_signals[0]
	gp.call("_on_details", {"response_code": 0, "product_details": [{"product_id": "gold_s", "one_time_purchase_offer_details_list": [{"formatted_price": "TRY 29,99"}]}], "unfetched_products": []})
	_check("9h localized price cached and signalled once; unchanged answer does not signal again",
		gp.price_of("gold_s") == "TRY 29,99" and first_count == 1 and prices_signals[0] == 1 and gp.price_of("gold_m") == "")

	var codes_ok: bool = script.error_text(1) == "Purchase canceled" and script.error_text(2) == "No connection to Google Play" \
		and script.error_text(3) == "Google Play billing is unavailable" and script.error_text(4) == "Product not found in the store" \
		and script.error_text(5) == "Store setup error" and script.error_text(7) == "Already owned, restoring"
	_check("9i response codes map to short player texts", codes_ok)

	fin.clear()
	gp.call("purchase", "gold_s")  # off Android the plugin is absent: the client is never ready
	await _frames()
	_check("9j store not connected: one clear error, no crash", fin.size() == 1 and fin[0][1] == false and String(fin[0][2]).contains("not connected"))
	(gp.get("_client") as Node).free()  # drops the signal lambdas that point back at the provider


# ---- 10: crash-loop guard of the store (its own file, ads unaffected) ---------------------------------

func _test_guard() -> void:
	var pm := PurchaseManager
	var path := "user://test_billing_guard.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var saved_path := pm.guard_path
	pm.guard_path = path
	var ads_file_before := FileAccess.file_exists(AdService.GUARD_PATH)
	var l1 := pm._guard_blocked()
	var l2 := pm._guard_blocked()
	var l3 := pm._guard_blocked()
	_check("10a store start never confirmed on 2 launches in a row: billing paused on the 3rd", not l1 and not l2 and l3)
	_check("10b still paused afterwards", pm._guard_blocked())
	_check("10c ads are not affected: fresh ad guard state is not blocked, ads guard file untouched",
		not AdService.guard_step({}, int(Time.get_unix_time_from_system()))["blocked"] and FileAccess.file_exists(AdService.GUARD_PATH) == ads_file_before)
	pm._on_store_started()
	_check("10d a confirmed start clears the guard", not pm._guard_blocked())
	pm._guard_blocked()
	pm._on_store_started()
	var g1 := pm._guard_blocked()
	var g2 := pm._guard_blocked()
	pm._on_store_started()
	var g3 := pm._guard_blocked()
	pm._on_store_started()
	var g4 := pm._guard_blocked()
	_check("10e a confirmed start in between resets the count: never paused", not g1 and not g2 and not g3 and not g4)
	DirAccess.remove_absolute(path)
	pm.guard_path = saved_path


# ---- 11: shop page (prices, no restore button, owned state) -------------------------------------------

func _test_shop_ui() -> void:
	var pm := PurchaseManager
	var saved := pm.provider
	var store := _fresh_store("x")
	var page := (load("res://Scene/Menus/Pages/ShopPage.tscn") as PackedScene).instantiate()
	add_child(page)
	await _frames()
	var list := page.get_node("Content/Scroll/Margin/List")
	var gold_card := page.get_node("Content/Scroll/Margin/List/GoldRow/Gold1")
	var gold_button := gold_card.get_node("%BuyButton") as Button
	var default_text := gold_button.text
	_check("11a the shop has no restore button", list.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).text == "RESTORE PURCHASES").is_empty())
	store.prices["gold_s"] = "TRY 29,99"
	store.prices_updated.emit()
	_check("11b a store price replaces the card text; products without a price keep theirs", gold_button.text == "TRY 29,99" and default_text != "TRY 29,99")
	PlayerData.mark_purchased("remove_ads")
	var ads_button := page.get_node("Content/Scroll/Margin/List/NoAds").get_node("%BuyButton") as Button
	_check("11c an owned product shows OWNED, not a price", ads_button.text == "OWNED" and ads_button.disabled)
	page.queue_free()
	pm.provider = saved
	_reset()