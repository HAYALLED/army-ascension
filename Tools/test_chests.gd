extends Node
## Headless chest tests. Run: godot --headless --path . res://Tools/test_chests.tscn

const T := SoldierDB.Type

var _failed := 0


## Ad backend that always pays out one frame after show().
class FakeAds extends AdProvider:
	var shown := 0

	func is_ready() -> bool:
		return true

	func show(_placement: String) -> void:
		shown += 1
		finished.emit.call_deferred(true)


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_drop_weights()
	_test_contents()
	_test_preview_and_open()
	_test_slots()
	_test_save()
	await _test_win_drop()
	await _test_shop_chest()
	print("CHESTS %s" % ("OK" if _failed == 0 else "FAILED (%d)" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _fresh() -> void:
	PlayerData.reset_to_defaults()


func _test_drop_weights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var n := 100000
	var counts := [0, 0, 0]
	for i in n:
		counts[ChestDB.roll_tier(rng)] += 1
	# 60 / 30 / 10 %, +-5 sigma is about 1.5 points
	_check("drop weights wood 60 / silver 30 / gold 10 (%d / %d / %d per 100000)" % counts,
		absi(counts[0] - 60000) < 1600 and absi(counts[1] - 30000) < 1500 and absi(counts[2] - 10000) < 1000)


func _test_contents() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var expect := {
		ChestDB.Tier.WOOD: [1, 3, 5, 50, 100, 0.02],
		ChestDB.Tier.SILVER: [2, 7, 10, 200, 400, 0.02],
		ChestDB.Tier.GOLD: [3, 20, 50, 600, 1200, 0.05],
	}
	for tier in expect:
		var e: Array = expect[tier]
		var ok := true
		var gems := 0
		var n := 40000
		for i in n:
			var c := ChestDB.roll(tier, rng)
			var seen := {}
			ok = ok and c["units"].size() == e[0]
			for u: Dictionary in c["units"]:
				ok = ok and int(u["shards"]) >= e[1] and int(u["shards"]) <= e[2] and not seen.has(u["type"])
				seen[u["type"]] = true
			ok = ok and int(c["gold"]) >= e[3] and int(c["gold"]) <= e[4]
			gems += int(c["gems"])
		var want: float = float(n) * float(e[5])
		var tol: float = 5.0 * sqrt(want)
		_check("%s: %d distinct unit(s), shards %d-%d, gold %d-%d" % [ChestDB.name_of(tier), e[0], e[1], e[2], e[3], e[4]], ok)
		_check("%s: gem chance %.0f%% (%d gems in %d)" % [ChestDB.name_of(tier), float(e[5]) * 100.0, gems, n], absf(float(gems) - want) < tol)


## Owned unit = name + shards, unowned unit = "???"; opening unlocks it and pays everything.
func _test_preview_and_open() -> void:
	_fresh()
	PlayerData.unlocked.erase(T.SNIPER)
	var chest := {"tier": ChestDB.Tier.SILVER, "units": [{"type": T.RIFLEMAN, "shards": 8}, {"type": T.SNIPER, "shards": 9}], "gold": 250, "gems": 1}
	var lines := ChestDB.preview_lines(chest)
	var texts: Array = lines.map(func(l: Dictionary) -> String: return l["text"])
	_check("preview: owned unit shows name + shards", texts[0] == "Rifleman  +8 shards")
	_check("preview: unowned unit shows only ???", texts[1] == "???" and ChestDB.has_unknown_unit(chest))
	_check("preview: gold and gem visible", texts.has("+250 Gold") and texts.has("+1 GEM"))

	PlayerData.chest_slots[0] = chest
	var gold := PlayerData.gold
	var rifle := PlayerData.shards_of(T.RIFLEMAN)
	var reward := PlayerData.open_chest(0)
	_check("open: reward lists the new unit", reward["unlock"] == [T.SNIPER])
	_check("open: unit unlocked, shards of both units paid",
		PlayerData.owns(T.SNIPER) and PlayerData.shards_of(T.SNIPER) == 9 and PlayerData.shards_of(T.RIFLEMAN) == rifle + 8)
	_check("open: gold and gem paid, slot emptied", PlayerData.gold == gold + 250 and PlayerData.gems == 1 and PlayerData.chest_slots[0].is_empty())
	_check("open: empty slot gives nothing", PlayerData.open_chest(0).is_empty() and PlayerData.open_chest(-1).is_empty() and PlayerData.open_chest(99).is_empty())
	_check("preview after unlock shows the unit", not ChestDB.has_unknown_unit(chest))
	var texts_lines := RewardDB.lines(reward).map(func(l: Dictionary) -> String: return l["text"])
	_check("reward popup lines show NEW UNIT", texts_lines.has("NEW UNIT: Sniper!"))

	# unowned units never spawn in battle
	_fresh()
	PlayerData.unlocked.erase(T.MEDIC)
	var no_medic := true
	for i in 3000:
		no_medic = no_medic and SoldierDB.random_type() != T.MEDIC
	_check("locked units are not spawned by gates", no_medic)
	_fresh()


func _test_slots() -> void:
	_fresh()
	var ok := PlayerData.chest_slots.size() == ChestDB.SLOTS
	var rng := RandomNumberGenerator.new()
	for i in ChestDB.SLOTS:
		ok = ok and PlayerData.add_chest(ChestDB.roll(ChestDB.Tier.WOOD, rng)) == i
	_check("chests fill slots 0..%d in order" % (ChestDB.SLOTS - 1), ok)
	_check("full slots: new chest is refused (-1)", PlayerData.add_chest(ChestDB.roll(ChestDB.Tier.GOLD, rng)) == -1)
	PlayerData.open_chest(1)
	_check("a freed slot is reused", PlayerData.add_chest(ChestDB.roll(ChestDB.Tier.GOLD, rng)) == 1)
	_fresh()


func _test_save() -> void:
	_fresh()
	var chest := {"tier": ChestDB.Tier.GOLD, "units": [{"type": T.SNIPER, "shards": 33}, {"type": T.MEDIC, "shards": 21}, {"type": T.ROCKET, "shards": 50}], "gold": 777, "gems": 1}
	PlayerData.chest_slots[2] = chest
	var data := PlayerData.to_save()
	var json := JSON.parse_string(JSON.stringify(data)) as Dictionary
	PlayerData.reset_to_defaults()
	PlayerData.apply_save(json)
	_check("chest survives save / load (JSON round trip)", PlayerData.chest_slots[2] == chest and PlayerData.chest_slots[0].is_empty())
	_check("owned units are written to the save", json["unlocked"].size() == PlayerData.owned_types().size() and json["unlocked"].has("sniper"))
	PlayerData.apply_save({"chests": "x", "unlocked": 5})
	_check("hostile chest data is ignored", PlayerData.chest_slots.size() == ChestDB.SLOTS and PlayerData.chest_slots[2].is_empty())
	PlayerData.apply_save({"chests": [
		{"tier": "gold", "units": [{"id": "sniper", "shards": 99999}, {"id": "sniper", "shards": 5}, {"id": "nope", "shards": 5}], "gold": -5, "gems": 99},
		{"tier": "diamond", "units": []},
		{"tier": "wood", "units": []},
		7, null,
		{"tier": "wood", "units": [{"id": "sniper", "shards": 4}], "gold": 60, "gems": 0},
	], "unlocked": ["rocket", "ghost", 5]})
	var c0: Dictionary = PlayerData.chest_slots[0]
	_check("save validation: shards / gold / gems clamped, duplicates and bad ids dropped",
		c0["units"].size() == 1 and c0["units"][0]["shards"] == 50 and c0["gold"] == 600 and c0["gems"] == 1)
	_check("save validation: bad tier / empty / non-dict entries become empty slots",
		PlayerData.chest_slots[1].is_empty() and PlayerData.chest_slots[2].is_empty() and PlayerData.chest_slots[3].is_empty())
	_check("save validation: extra entries beyond the slots ignored, unknown unit ids ignored, starters always owned", PlayerData.chest_slots.size() == ChestDB.SLOTS and PlayerData.owns(T.ROCKET) and PlayerData.owns(T.RIFLEMAN))
	_fresh()


## A won battle drops a chest into the first free slot; full slots lose it; a lost battle drops nothing.
func _test_win_drop() -> void:
	_fresh()
	Game.sim_mode = true
	Game.reset_run()
	Game._finish_battle(true)
	_check("win drops a chest into slot 0", not Game.dropped_chest.is_empty() and Game.dropped_slot == 0 and PlayerData.chest_slots[0] == Game.dropped_chest)
	for i in 3:
		Game.reset_run()
		Game._finish_battle(true)
	_check("4 wins fill the 4 slots", Game.dropped_slot == 3 and PlayerData.chest_slots.all(func(c: Dictionary) -> bool: return not c.is_empty()))
	Game.reset_run()
	Game._finish_battle(true)
	_check("full slots: the chest is lost (slot -1), nothing overwritten", Game.dropped_slot == -1 and not Game.dropped_chest.is_empty())
	_fresh()
	Game.reset_run()
	Game._finish_battle(false)
	_check("a lost battle drops no chest", Game.dropped_chest.is_empty() and PlayerData.chest_slots[0].is_empty())
	Game.sim_mode = false
	Game.reset_run()
	_fresh()
	await get_tree().process_frame


## Shop gold chest: 20 gems, opens at once, nothing is stored in a slot.
func _test_shop_chest() -> void:
	_fresh()
	var shop := (load("res://Scene/Menus/Pages/ShopPage.tscn") as PackedScene).instantiate() as ShopPage
	add_child(shop)
	await get_tree().process_frame
	var card: ShopOffer = null
	var gem_cards := 0
	var shard_cards := 0
	for c in shop.find_children("*", "PanelContainer", true, false):
		if c is ShopOffer and c.item_id == "gold_chest":
			card = c
		if c is ShopItem and String(c.item_id).begins_with("gems_"):
			gem_cards += 1
		if c is ShopItem and String(c.item_id).begins_with("shards_"):
			shard_cards += 1
	_check("shop: gold chest card exists, costs %d gems, shows no description" % ChestDB.SHOP_GOLD_GEMS,
		card != null and card.price_text == "20 GEMS" and card.description == "")
	_check("shop: 3 gem packs, no shard packs", gem_cards == 3 and shard_cards == 0)
	var toasts: Array = []
	shop.toast_requested.connect(func(t: String) -> void: toasts.append(t))
	await shop._buy_gold_chest()
	_check("shop: too few gems -> refused, nothing granted", toasts == ["Not enough gems"] and PlayerData.gems == 0 and PlayerData.gold == PlayerData.START_GOLD)
	PlayerData.gems = 25
	var gold := PlayerData.gold
	var total := PlayerData.total_shards()
	# the reward popup waits for OK: close it from outside once it appears
	var closer := func() -> void:
		while true:
			await get_tree().process_frame
			for p in get_tree().root.find_children("*", "RewardPopup", true, false):
				p.closed.emit()
				p.queue_free()
				return
	closer.call()
	await shop._buy_gold_chest()
	_check("shop: 20 gems spent, gold chest paid out at once (3 units, 600+ gold)",
		PlayerData.gems >= 5 and PlayerData.gems <= 6 and PlayerData.gold >= gold + 600 and PlayerData.total_shards() >= total + 60)
	_check("shop: bought chest is not stored in a slot", PlayerData.chest_slots.all(func(c: Dictionary) -> bool: return c.is_empty()))
	# wooden chest by video: above the gold chest, shares the home cooldown
	var cards: Array = shop.find_children("*", "PanelContainer", true, false).filter(func(c: Node) -> bool: return c is ShopOffer)
	var ids: Array = cards.map(func(c: ShopOffer) -> String: return c.item_id)
	_check("shop: wood chest card sits right above the gold chest", ids.find("wood_chest") >= 0 and ids.find("wood_chest") + 1 == ids.find("gold_chest"))
	_check("shop: no season pass, NO RANDOM ADS card present", not ids.has("season_pass") and ids.has("remove_ads"))
	var saved_provider := AdService.provider
	var ads := FakeAds.new()
	AdService.provider = ads
	PlayerData.chest_ready_at = 0
	gold = PlayerData.gold
	total = PlayerData.total_shards()
	closer.call()
	await shop._watch_for_wood_chest()
	_check("shop: watching the video pays a wooden chest at once and starts the cooldown",
		ads.shown == 1 and PlayerData.gold > gold and PlayerData.total_shards() >= total + 3 and PlayerData.chest_seconds_left() > 0)
	await shop._watch_for_wood_chest()
	_check("shop: wood chest on cooldown shows no second ad", ads.shown == 1)
	AdService.provider = saved_provider
	shop.queue_free()
	_fresh()
