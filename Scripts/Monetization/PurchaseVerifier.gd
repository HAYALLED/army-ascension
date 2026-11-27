class_name PurchaseVerifier
extends RefCounted
## Client-side sanity check of a store purchase before it can pay out. NOT a security boundary: a patched
## APK or a fake purchase app can skip it. Before real money is at risk a server check (Google Play
## Developer API, purchases.products.get) must replace or extend verify(). The flow does not change:
## a provider does `var err: String = await verifier.verify(...)`, so verify() may be asynchronous.
## No plugin classes here: this script loads on every platform.

## Play Billing PurchaseState.PURCHASED (0 = unspecified, 2 = pending).
const PURCHASED := 1

## Package name of this app. "" when unknown: the package check is then skipped.
var package_name := ""


func _init(own_package: String = "") -> void:
	package_name = own_package


## "" when the purchase looks valid, otherwise a short player-facing error. Nothing from `purchase` is logged.
func verify(product_id: String, purchase: Dictionary) -> String:
	if int(purchase.get("purchase_state", 0)) != PURCHASED:
		return "Payment not completed"
	var ids: Variant = purchase.get("product_ids")
	if not (ids is Array or ids is PackedStringArray) or not ids.has(product_id):
		return "Purchase does not match the product"
	if package_name != "" and String(purchase.get("package_name", "")) != package_name:
		return "Purchase belongs to another app"
	for key in ["purchase_token", "signature", "original_json"]:
		if not (purchase.get(key) is String) or (purchase[key] as String).is_empty():
			return "Purchase data incomplete"
	return ""
