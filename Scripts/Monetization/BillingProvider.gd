class_name BillingProvider
extends RefCounted
## Contract of a store backend. PurchaseManager owns one. A real adapter (Google Play Billing plugin)
## extends this class and is assigned to PurchaseManager.provider.
## purchase() must emit `progress` while it works and `finished` exactly once, later (never inside the
## same call). A real adapter must verify the purchase with the store before it reports ok = true.
## Paid purchases that PurchaseManager did not wait for (app killed mid-payment, payment finished after the
## timeout, pending payment completed later, new device) are reported through `purchase_recovered`.
## Rule: a purchase is consumed / acknowledged only in confirm_delivery(), after the reward is saved.

@warning_ignore("unused_signal")
signal progress(text: String, ratio: float)
signal finished(product_id: String, ok: bool, error: String)
## A verified, paid, not yet delivered purchase found outside a normal purchase() call.
@warning_ignore("unused_signal")
signal purchase_recovered(product_id: String, token: String)
## A one-time product the store says the player owns and that was already delivered (reinstall, new device).
@warning_ignore("unused_signal")
signal ownership_restored(product_id: String)
## Localized prices changed (shop cards refresh through this, never by polling).
@warning_ignore("unused_signal")
signal prices_updated()
## restore() is done; error is "" on success.
signal restore_finished(error: String)


func purchase(product_id: String) -> void:
	finished.emit.call_deferred(product_id, false, "Store not available")


## Token of the purchase that made finished(product_id, true) fire. "" when there is none.
func token_of(_product_id: String) -> String:
	return ""


## Called by PurchaseManager ONLY after the reward is granted AND saved. Consumes a consumable product or
## acknowledges a one-time product. Safe to call again for the same token.
func confirm_delivery(_product_id: String, _token: String) -> void:
	pass


## Localized price text of a product, "" when unknown.
func price_of(_product_id: String) -> String:
	return ""


## Asks the store for the purchases the player owns; they come back through purchase_recovered /
## ownership_restored, then restore_finished.
func restore() -> void:
	restore_finished.emit.call_deferred("")
