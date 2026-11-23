class_name BillingProvider
extends RefCounted
## Contract of a store backend. PurchaseManager owns one. A real adapter (Google Play Billing plugin)
## extends this class, overrides purchase() and is assigned to PurchaseManager.provider.
## purchase() must emit `progress` while it works and `finished` exactly once, later (never inside the
## same call). A real adapter must verify the purchase with the store before it reports ok = true,
## and must re-deliver purchases that were paid but not yet reported (app killed mid-payment).

@warning_ignore("unused_signal")
signal progress(text: String, ratio: float)
signal finished(product_id: String, ok: bool, error: String)


func purchase(product_id: String) -> void:
	finished.emit.call_deferred(product_id, false, "Store not available")
