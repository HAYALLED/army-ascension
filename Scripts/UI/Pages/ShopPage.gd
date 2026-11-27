class_name ShopPage
extends Control
## Shop page: the free-shards ad, the wooden chest (video), the gold chest (gems) and the store products. Purchases run through PurchaseManager
## (real Google Play on Android; a mock store in debug builds off Android only, never in a release build).

signal toast_requested(text: String)

var _cards: Array[Control] = []
var _wood_card: ShopOffer = null
var _ads_card: ShopOffer = null
var _tick := 0.0
var _resolving := false


func _ready() -> void:
	for node in find_children("*", "PanelContainer", true, false):
		if node is ShopItem or node is ShopOffer:
			node.buy.connect(_on_buy)
			_cards.append(node)
			if node.item_id == "gold_chest":
				node.set_button("%d GEMS" % ChestDB.SHOP_GOLD_GEMS, false)
			elif node.item_id == "wood_chest":
				_wood_card = node
			elif node.item_id == "remove_ads":
				_ads_card = node
	PlayerData.shop_changed.connect(_refresh)
	PurchaseManager.prices_updated.connect(_refresh)
	PurchaseManager.pending_changed.connect(_check_pending)
	PurchaseManager.notice.connect(toast_requested.emit)
	visibility_changed.connect(_check_pending)
	_add_restore_button()
	_refresh()


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		if is_visible_in_tree():
			_refresh_wood_chest()


## WATCH when the wooden chest is ready, otherwise the time left (its own 30 minute timer).
func _refresh_wood_chest() -> void:
	if _wood_card == null:
		return
	var left := PlayerData.chest_seconds_left()
	if left > 0:
		_wood_card.set_button("%d:%02d" % [floori(left / 60.0), left % 60], true)
	else:
		_wood_card.set_button("WATCH", false)


## OWNED for one-time products the player has, SOON for products that are not ready, otherwise the
## localized store price (the card keeps its default text until the store has answered).
func _refresh() -> void:
	for card in _cards:
		var id: String = card.item_id
		if ProductDB.is_once(id) and PlayerData.has_purchase(id):
			card.set_button("OWNED", true)
		elif ProductDB.has(id) and not ProductDB.is_available(id):
			card.set_button("SOON", true)
		elif ProductDB.has(id):
			var price := PurchaseManager.price_of(id)
			if price != "":
				card.set_button(price, false)
	_refresh_wood_chest()
	if _ads_card != null:
		_ads_card.set_description(_ads_text())


## RESTORE PURCHASES under the last card (reinstall, new phone): asks the store for what the player owns.
func _add_restore_button() -> void:
	var b := Button.new()
	b.theme = preload("res://Resources/UI/ui_theme.tres")
	b.theme_type_variation = &"ButtonSecondary"
	b.text = "RESTORE PURCHASES"
	b.custom_minimum_size = Vector2(0, 84)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		PurchaseManager.restore())
	get_node("Content/Scroll/Margin/List").add_child(b)


## A paid starter bundle found after a restart or reinstall has no soldier to give the shards to: ask now.
func _check_pending() -> void:
	if _resolving or not is_visible_in_tree():
		return
	_resolving = true
	while not PlayerData.pending_deliveries.is_empty():
		var result := await PurchaseManager.resolve_pending(_host())
		if result.is_empty():
			break
		if not bool(result["ok"]):
			toast_requested.emit(String(result["message"]))
			break
		await RewardPopup.show_reward(_host(), "PURCHASE COMPLETE", result["reward"])
	_resolving = false


## NO RANDOM ADS pitch; shows the free trial while it lasts.
func _ads_text() -> String:
	if PlayerData.has_purchase("remove_ads"):
		return "Battles pay 2X gold, no random ads. Thank you!"
	var text := "Every battle pays 2X gold and no more ad after every 2 games!"
	if PlayerData.no_ads_trial_left > 0:
		text += "\nFREE TRIAL: %d battles left" % PlayerData.no_ads_trial_left
	return text


func _on_buy(id: String) -> void:
	if id == "ad_shards":
		await _watch_for_shards()
		return
	if id == "gold_chest":
		await _buy_gold_chest()
		return
	if id == "wood_chest":
		await _watch_for_wood_chest()
		return
	var product := ProductDB.get_product(id)
	if product.is_empty():
		toast_requested.emit("Unknown product")
		return
	var unit := -1
	if bool(product.get("pick_unit", false)):
		unit = await UnitPickerPopup.pick(_host(), "Shards for which soldier?")
		if unit < 0:
			return
	var result := await PurchaseManager.buy(id, unit)
	if not bool(result["ok"]):
		toast_requested.emit(String(result["message"]))
		return
	await RewardPopup.show_reward(_host(), "PURCHASE COMPLETE", result["reward"], String(product.get("note", "")))


## Free shards: pick an owned soldier, watch one ad, the shards go to that soldier.
func _watch_for_shards() -> void:
	if not AdService.is_available():
		toast_requested.emit("No ad available right now")
		return
	var unit := await UnitPickerPopup.pick(_host(), "Shards for which soldier?")
	if unit < 0:
		return
	if not await AdService.show_rewarded("shards"):
		toast_requested.emit("Ad not completed, no reward")
		return
	var reward := RewardDB.empty()
	reward["shards"][unit] = RewardDB.AD_SHARDS
	PlayerData.grant(reward)
	SaveManager.save_now()
	await RewardPopup.show_reward(_host(), "FREE SHARDS", reward)


## Watch one ad, get a wooden chest that opens at once. Has its own 30 minute timer (`PlayerData.chest_ready_at`); the Home screen has no free chest.
func _watch_for_wood_chest() -> void:
	if PlayerData.chest_seconds_left() > 0:
		return
	if not AdService.is_available():
		toast_requested.emit("No ad available right now")
		return
	if not await AdService.show_rewarded("chest"):
		toast_requested.emit("Ad not completed, no chest")
		return
	var reward := RewardDB.roll_chest(RandomNumberGenerator.new())
	PlayerData.grant(reward)
	PlayerData.start_chest_cooldown()
	SaveManager.save_now()
	await RewardPopup.show_reward(_host(), "WOODEN CHEST", reward, "", RewardDB.ICON_CHEST)


## Gold chest for gems. The shop shows no contents: the chest opens at once and pays out.
func _buy_gold_chest() -> void:
	if not PlayerData.spend_gems(ChestDB.SHOP_GOLD_GEMS):
		toast_requested.emit("Not enough gems")
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var reward := ChestDB.to_reward(ChestDB.roll(ChestDB.Tier.GOLD, rng))
	PlayerData.grant(reward)
	SaveManager.save_now()
	await RewardPopup.show_reward(_host(), "GOLD CHEST", reward, "", ChestDB.icon_of(ChestDB.Tier.GOLD))


## Popups sit on the menu root so they cover the tab bar too.
func _host() -> Node:
	return get_tree().current_scene
