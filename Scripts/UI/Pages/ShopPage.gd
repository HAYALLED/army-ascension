class_name ShopPage
extends Control
## Shop page: the free-shards ad and the store products. Purchases run through PurchaseManager
## (mock payment in debug builds only, never in a release build).

signal toast_requested(text: String)

var _cards: Array[Control] = []


func _ready() -> void:
	for node in find_children("*", "PanelContainer", true, false):
		if node is ShopItem or node is ShopOffer:
			node.buy.connect(_on_buy)
			_cards.append(node)
	PlayerData.shop_changed.connect(_refresh)
	_refresh()


## OWNED for one-time products the player has, SOON for products that are not ready.
func _refresh() -> void:
	for card in _cards:
		var id: String = card.item_id
		if ProductDB.is_once(id) and PlayerData.has_purchase(id):
			card.set_button("OWNED", true)
		elif ProductDB.has(id) and not ProductDB.is_available(id):
			card.set_button("SOON", true)


func _on_buy(id: String) -> void:
	if id == "ad_shards":
		await _watch_for_shards()
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


## Popups sit on the menu root so they cover the tab bar too.
func _host() -> Node:
	return get_tree().current_scene
