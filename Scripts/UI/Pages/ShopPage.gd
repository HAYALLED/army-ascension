class_name ShopPage
extends Control
## Shop page. All purchases are MOCKED in dev (no real payment provider yet).

signal toast_requested(text: String)


func _ready() -> void:
	for item in find_children("*", "PanelContainer", true, false):
		if item is ShopItem or item is ShopOffer:
			item.buy.connect(func(id: String) -> void:
				toast_requested.emit("MOCK purchase: %s (no real payment yet)" % id))
