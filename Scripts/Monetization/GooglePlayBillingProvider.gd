extends BillingProvider
## Real Google Play Billing backend (official GodotGooglePlayBilling plugin 3.x, Android only). Created by
## PurchaseManager once the plugin singleton exists. No class_name on purpose: this script references plugin
## classes (BillingClient), so nothing may load it unless the plugin is installed.
## Rules: a purchase is consumed / acknowledged only in confirm_delivery(), after PurchaseManager saved the
## reward. Every purchase dictionary goes through PurchaseVerifier first. Nothing secret is logged (no token,
## signature, original json or order id): only product ids and response codes. The plugin answers from its own
## thread, so every handler hops to the main thread with call_deferred before it touches anything.

const RETRY_SECONDS := 30.0
const MAX_RETRIES := 3
## A purchase query that got no answer for this long may be asked again.
const QUERY_STALE_MSEC := 20000

var _host: Node
var _on_started: Callable
var _client: BillingClient
var _verifier := PurchaseVerifier.new()
## Localized price text per product id, filled by the product details query (once per connection).
var _prices := {}
var _details_done := false
var _details_pending := false
## Product of the purchase() in progress, "" when none.
var _expecting := ""
var _launch_waiting := false
## Token of the purchase that answered purchase() of a product id (read through token_of).
var _tokens := {}
## Tokens being consumed / acknowledged right now: token -> product id. Memory only.
var _confirming := {}
var _querying := false
var _query_sent := 0
var _retries := 0
var _started := false


## `on_started` (optional) is called once, on the main thread, when the store answered the first connection
## attempt (connected or refused): the plugin did not crash on start. PurchaseManager uses it for its guard.
func _init(host: Node, on_started: Callable = Callable()) -> void:
	_host = host
	_on_started = on_started
	_client = BillingClient.new()
	host.add_child(_client)
	_client.connected.connect(func() -> void: _on_connected.call_deferred())
	_client.disconnected.connect(func() -> void: _on_disconnected.call_deferred())
	_client.connect_error.connect(func(code: int, _message: String) -> void: _on_connect_error.call_deferred(code))
	_client.query_product_details_response.connect(func(r: Dictionary) -> void: _on_details.call_deferred(r))
	_client.query_purchases_response.connect(func(r: Dictionary) -> void: _on_owned.call_deferred(r))
	_client.on_purchase_updated.connect(func(r: Dictionary) -> void: _on_updated.call_deferred(r))
	_client.consume_purchase_response.connect(func(r: Dictionary) -> void: _on_confirmed.call_deferred(r))
	_client.acknowledge_purchase_response.connect(func(r: Dictionary) -> void: _on_confirmed.call_deferred(r))
	_client.start_connection()


func purchase(product_id: String) -> void:
	progress.emit("Connecting to store...", 0.1)
	_expecting = product_id
	if not _client.is_ready():
		_retries = 0
		_connect_now()
		_fail(product_id, "Google Play is not connected, try again")
		return
	if _details_done:
		_launch()
		return
	# Play refuses purchase() for a product whose details were not loaded first.
	_launch_waiting = true
	if not _details_pending:
		_query_details()


func token_of(product_id: String) -> String:
	return String(_tokens.get(product_id, ""))


func price_of(product_id: String) -> String:
	return String(_prices.get(product_id, ""))


func confirm_delivery(product_id: String, token: String) -> void:
	if token.is_empty() or _confirming.has(token) or not _client.is_ready():
		return  # not connected: the purchase stays at Google and the next restore() delivers / confirms it again
	_confirming[token] = product_id
	if ProductDB.is_once(product_id):
		_client.acknowledge_purchase(token)
	else:
		_client.consume_purchase(token)


func restore() -> void:
	if _querying and Time.get_ticks_msec() - _query_sent < QUERY_STALE_MSEC:
		return  # the answer of the running query ends with restore_finished
	if not _client.is_ready():
		_retries = 0
		_connect_now()
		restore_finished.emit.call_deferred("Google Play is not connected, try again")
		return
	_query_owned()


## Short player-facing text of a Play Billing response code. Never contains store data.
static func error_text(code: int) -> String:
	match code:
		BillingClient.BillingResponseCode.USER_CANCELED:
			return "Purchase canceled"
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			return "Already owned, restoring"
		BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, BillingClient.BillingResponseCode.NETWORK_ERROR, \
		BillingClient.BillingResponseCode.SERVICE_DISCONNECTED, BillingClient.BillingResponseCode.SERVICE_TIMEOUT:
			return "No connection to Google Play"
		BillingClient.BillingResponseCode.BILLING_UNAVAILABLE:
			return "Google Play billing is unavailable"
		BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return "Product not found in the store"
		BillingClient.BillingResponseCode.DEVELOPER_ERROR:
			return "Store setup error"
		BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED:
			return "Not supported on this device"
	return "Purchase failed (code %d)" % code


## Package name of this app, "" when it cannot be read (the verifier then skips the package check).
func _own_package() -> String:
	if not Engine.has_singleton("AndroidRuntime"):
		return ""
	var runtime: Variant = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = runtime.getActivity()
	return str(activity.getPackageName()) if activity != null else ""


func _connect_now() -> void:
	if _client.is_ready() or _client.get_connection_state() == BillingClient.ConnectionState.CONNECTING:
		return
	_client.start_connection()


## Bounded: MAX_RETRIES tries, then again only when the app resumes or the player buys / restores.
func _schedule_retry() -> void:
	if _retries >= MAX_RETRIES:
		return
	_retries += 1
	_host.get_tree().create_timer(RETRY_SECONDS).timeout.connect(_connect_now, CONNECT_ONE_SHOT)


func _notify_started() -> void:
	if _started:
		return
	_started = true
	if _on_started.is_valid():
		_on_started.call()


func _on_connected() -> void:
	_retries = 0
	_verifier.package_name = _own_package()
	_notify_started()
	_details_done = false
	_query_details()
	_query_owned()


func _on_disconnected() -> void:
	_details_done = false
	_details_pending = false
	_schedule_retry()


func _on_connect_error(code: int) -> void:
	push_warning("GooglePlayBilling: connection failed (code %d)" % code)
	_notify_started()
	_schedule_retry()


func _query_details() -> void:
	_details_pending = true
	_client.query_product_details(PackedStringArray(ProductDB.PRODUCTS.keys()), BillingClient.ProductType.INAPP)


func _query_owned() -> void:
	_querying = true
	_query_sent = Time.get_ticks_msec()
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_details(r: Dictionary) -> void:
	_details_pending = false
	var code := int(r.get("response_code", BillingClient.BillingResponseCode.OK))
	_details_done = code == BillingClient.BillingResponseCode.OK
	if not _details_done:
		push_warning("GooglePlayBilling: product query failed (code %d)" % code)
	var changed := false
	for entry in r.get("product_details", []):
		if not (entry is Dictionary):
			continue
		var id := String(entry.get("product_id", ""))
		var price := _price_in(entry)
		if ProductDB.has(id) and price != "" and String(_prices.get(id, "")) != price:
			_prices[id] = price
			changed = true
	for entry in r.get("unfetched_products", []):
		if entry is Dictionary:
			push_warning("GooglePlayBilling: product %s not found in the store (status %d)" % [
				String(entry.get("product_id", "?")), int(entry.get("status_code", 0))])
	if changed:
		prices_updated.emit()
	if _launch_waiting:
		_launch_waiting = false
		_launch()


## Formatted price of a one-time product's first offer ("" when the plugin sent none).
func _price_in(entry: Dictionary) -> String:
	var offers: Variant = entry.get("one_time_purchase_offer_details_list", entry.get("one_time_purchase_offer_details"))
	if offers is Array and not (offers as Array).is_empty():
		offers = (offers as Array)[0]
	return String(offers.get("formatted_price", "")) if offers is Dictionary else ""


func _launch() -> void:
	var id := _expecting
	if id == "":
		return
	if not _prices.has(id):
		_fail(id, error_text(BillingClient.BillingResponseCode.ITEM_UNAVAILABLE))
		return
	progress.emit("Waiting for Google Play...", 0.4)
	var r: Dictionary = _client.purchase(id)
	var code := int(r.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		_fail(id, error_text(code))


## Answers the purchase() in progress with an error. `finished` fires once per purchase(), later.
func _fail(id: String, text: String) -> void:
	if id == "" or _expecting != id:
		return
	_expecting = ""
	_launch_waiting = false
	finished.emit.call_deferred(id, false, text)


func _on_updated(r: Dictionary) -> void:
	var code := int(r.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			_query_owned()  # paid before and not delivered yet: the query hands it to PurchaseManager
		_fail(_expecting, error_text(code))
		return
	progress.emit("Confirming purchase...", 0.8)
	for p in r.get("purchases", []):
		if p is Dictionary:
			await _handle(p, false)


func _on_owned(r: Dictionary) -> void:
	var code := int(r.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		_querying = false
		restore_finished.emit(error_text(code))
		return
	for p in r.get("purchases", []):
		if p is Dictionary:
			await _handle(p, true)
	_querying = false
	restore_finished.emit("")


## One purchase from the store. `from_query`: found by a purchase query, not as the answer of purchase().
## PENDING purchases never pay: they arrive here again as PURCHASED once the money is there.
func _handle(p: Dictionary, from_query: bool) -> void:
	var id := _product_of(p)
	if id == "":
		return
	if int(p.get("purchase_state", 0)) == BillingClient.PurchaseState.PENDING:
		if not from_query:
			_fail(id, "Payment pending, the reward arrives when it completes")
		return
	var err: String = await _verifier.verify(id, p)
	if err != "":
		push_warning("GooglePlayBilling: purchase of %s rejected" % id)
		if not from_query:
			_fail(id, err)
		return
	if from_query and bool(p.get("is_acknowledged", false)):
		if ProductDB.is_once(id):
			ownership_restored.emit(id)
		return
	var token := String(p["purchase_token"])
	if not from_query and _expecting == id:
		_tokens[id] = token
		_expecting = ""
		finished.emit(id, true, "")
	else:
		purchase_recovered.emit(id, token)


## The known product a purchase is for (the one being bought first), "" when none of its ids is ours.
func _product_of(p: Dictionary) -> String:
	var ids: Variant = p.get("product_ids")
	if not (ids is Array or ids is PackedStringArray):
		return ""
	if _expecting != "" and ids.has(_expecting):
		return _expecting
	for id in ids:
		if ProductDB.has(String(id)):
			return String(id)
	return ""


## Answer of consume / acknowledge. A failed confirm is harmless: the purchase stays at Google and the next
## restore() reports it again; PurchaseManager then only confirms, it never grants twice.
func _on_confirmed(r: Dictionary) -> void:
	var token := String(r.get("token", ""))
	var product := String(_confirming.get(token, ""))
	if token.is_empty():
		_confirming.clear()
	else:
		_confirming.erase(token)
	var code := int(r.get("response_code", BillingClient.BillingResponseCode.OK))
	if code != BillingClient.BillingResponseCode.OK and code != BillingClient.BillingResponseCode.ITEM_NOT_OWNED:
		push_warning("GooglePlayBilling: confirming %s failed (code %d)" % [product, code])
