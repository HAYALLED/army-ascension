extends Node
## Shop purchase flow (autoload "PurchaseManager"): validate -> pay -> grant -> save -> confirm to the store.
## The backend is a BillingProvider. On Android with the GodotGooglePlayBilling plugin the real store
## (GooglePlayBillingProvider) is used in every build, START_DELAY seconds after boot. Debug builds off Android
## get MockBillingProvider (no real money). Everything else has no provider, so buying fails with
## "Store not available" and a mock purchase can never reach players.
## While paying, a blocking progress overlay is shown and a second purchase is refused.
##
## Every paid reward is granted by _deliver() and nowhere else: a normal purchase, a purchase recovered after
## a crash / timeout / reinstall, and a restore all end there. _deliver() has no await, so the two ways a
## purchase can arrive (answer of the payment, store query) can never interleave. A purchase is confirmed to
## the store (consumed / acknowledged) only after the reward is on disk; a token hash is stored so it is
## never granted twice. No automatic revoke on refund: a false revoke on a network hiccup costs more.

enum State { IDLE, PROCESSING }

const AdGuard := preload("res://Scripts/Autoload/AdService.gd")
const GOOGLE_SCRIPT := "res://Scripts/Monetization/GooglePlayBillingProvider.gd"
const PLUGIN_SINGLETON := "GodotGooglePlayBilling"
## The store starts this long after boot, so the engine and the first menu frame are already up.
const START_DELAY := 2.0
## Crash-loop guard (release builds only), same logic as ads but its own file: when the store start was never
## confirmed on AdService.GUARD_LIMIT launches in a row, billing stays off for AdService.GUARD_PAUSE_DAYS.
const GUARD_PATH := "user://billing_guard.cfg"
## A restore that gets no answer from the store is given up after this many seconds.
const RESTORE_TIMEOUT := 20.0

signal state_changed(state: int)
## Localized prices changed (a provider answered).
signal prices_updated()
## A paid purchase waits for the player to pick a soldier (see resolve_pending).
signal pending_changed()
## Short player-facing message for something that happened outside a buy() call (restore, recovery).
signal notice(text: String)
signal _answered(result: Array)

var provider: BillingProvider = null:
	set = _set_provider
var state: int = State.IDLE
## Seconds without any provider progress before an unanswered payment is given up and the UI is unlocked.
## The clock restarts on every progress step, so Google's payment sheet is not cut off. A payment that
## completes later is still delivered (see _on_finished). Plain var so tests can shorten it.
var timeout := 120.0
## Plain var so tests can redirect it.
var guard_path := GUARD_PATH

var _overlay: BlockingOverlay = null
var _pending := ""
var _serial := 0
## Raw store tokens of paid purchases that wait for a soldier pick: token hash -> token. Memory only.
var _live := {}
var _restoring := false
var _restored := 0
var _restore_serial := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if provider != null:
		return
	var android := OS.get_name() == "Android"
	match provider_kind(android, OS.is_debug_build(), android and Engine.has_singleton(PLUGIN_SINGLETON)):
		&"mock":
			provider = MockBillingProvider.new(get_tree())
		&"google":
			_start_google()


## Which backend a build gets: &"google", &"mock" (debug builds off Android only) or &"none".
static func provider_kind(is_android: bool, is_debug: bool, has_plugin: bool) -> StringName:
	if is_android:
		return &"google" if has_plugin else &"none"
	return &"mock" if is_debug else &"none"


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and provider != null and state == State.IDLE and not _restoring:
		provider.restore()


## Waits START_DELAY, then starts the store. The plugin script is loaded by path and never referenced by name:
## without the plugin it does not compile.
func _start_google() -> void:
	await get_tree().create_timer(START_DELAY).timeout
	if provider != null:
		return
	if not OS.is_debug_build() and _guard_blocked():
		push_warning("PurchaseManager: billing paused, the store did not start on recent launches")
		return
	var script := load(GOOGLE_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("PurchaseManager: billing plugin missing, store unavailable")
		return
	provider = script.new(self, _on_store_started) as BillingProvider


## Called by the provider once the store answered (connected or refused): the start did not crash.
func _on_store_started() -> void:
	_guard_save({"pending": false, "crashes": 0, "until": 0})


## One launch of the crash-loop guard. True when billing must stay off this launch.
func _guard_blocked() -> bool:
	var step := AdGuard.guard_step(_guard_load(), int(Time.get_unix_time_from_system()))
	_guard_save(step)
	return bool(step["blocked"])


func _guard_load() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(guard_path) != OK:
		return {}
	var saved := {}
	for key in ["pending", "crashes", "until"]:
		saved[key] = cfg.get_value("guard", key, null)
	return saved


func _guard_save(saved: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for key in ["pending", "crashes", "until"]:
		cfg.set_value("guard", key, saved[key])
	cfg.save(guard_path)


func _set_provider(p: BillingProvider) -> void:
	if provider != null:
		_link(provider, false)
	provider = p
	if p != null:
		_link(p, true)
		prices_updated.emit()


func _link(p: BillingProvider, on: bool) -> void:
	var wiring: Array[Array] = [
		[p.progress, _on_progress],
		[p.finished, _on_finished],
		[p.purchase_recovered, _on_recovered],
		[p.ownership_restored, _on_ownership],
		[p.restore_finished, _on_restore_finished],
		[p.prices_updated, prices_updated.emit],
	]
	for pair in wiring:
		var sig: Signal = pair[0]
		var target: Callable = pair[1]
		if on and not sig.is_connected(target):
			sig.connect(target)
		elif not on and sig.is_connected(target):
			sig.disconnect(target)


## Localized store price of a product, "" when unknown (the shop then keeps its default text).
func price_of(id: String) -> String:
	return provider.price_of(id) if provider != null else ""


## Buys a product. `unit` is the soldier class that gets the shards (products with pick_unit).
## Returns {"ok": bool, "message": String, "reward": Dictionary}. The reward is already saved.
func buy(id: String, unit: int = -1) -> Dictionary:
	var err := _check(id, unit)
	if err != "":
		return _result(false, err)
	_pending = id
	_set_state(State.PROCESSING)
	_overlay = BlockingOverlay.open(self, "PAYMENT")
	_overlay.set_status("Starting...", 0.0)
	provider.purchase.call_deferred(id)
	_arm_timeout()
	var res: Array = await _answered
	_overlay.close()
	_overlay = null
	_pending = ""
	_set_state(State.IDLE)
	if not bool(res[0]):
		return _result(false, String(res[1]))
	return _deliver(id, provider.token_of(id), unit)


## Asks the store for the purchases the player owns (Shop: RESTORE PURCHASES). Reports through `notice`.
func restore() -> void:
	if provider == null:
		notice.emit("Store not available")
		return
	if _restoring:
		return
	_restoring = true
	_restored = 0
	_restore_serial += 1
	get_tree().create_timer(RESTORE_TIMEOUT).timeout.connect(_end_restore.bind(_restore_serial, "No answer from Google Play"))
	provider.restore()


## Finishes the oldest paid purchase that waits for a soldier pick (starter bundle found after a restart or
## reinstall): asks the player and delivers it. Returns the delivery result, or {} when nothing is waiting,
## the player cancelled, or the store has not handed the token back yet. The shop calls it when it opens.
func resolve_pending(host: Node) -> Dictionary:
	for entry in PlayerData.pending_deliveries:
		var token := String(_live.get(entry["hash"], ""))
		if token.is_empty():
			continue
		var unit := await UnitPickerPopup.pick(host, "Shards for which soldier?")
		if unit < 0:
			return {}
		return _deliver(String(entry["id"]), token, unit)
	return {}


func _check(id: String, unit: int) -> String:
	if provider == null:
		return "Store not available"
	if state != State.IDLE:
		return "Another purchase is in progress"
	if not ProductDB.has(id):
		return "Unknown product"
	if not ProductDB.is_available(id):
		return "Coming soon"
	if ProductDB.is_once(id) and PlayerData.has_purchase(id):
		return "Already owned"
	if bool(ProductDB.get_product(id).get("pick_unit", false)) and not PlayerData.owns(unit):
		return "Choose a soldier first"
	# Nobody pays for value that would be clamped away.
	var spec: Dictionary = ProductDB.get_product(id).get("reward", {})
	if PlayerData.gold + int(spec.get("gold", 0)) > PlayerData.MAX_CURRENCY \
			or PlayerData.gems + int(spec.get("gems", 0)) > PlayerData.MAX_CURRENCY:
		return "Wallet full"
	return ""


## The only code that grants a paid reward. Synchronous: no await, so it cannot interleave with itself.
## Order: dedupe by token hash -> grant -> remember the hash -> save for real -> confirm to the store.
## When the save fails the grant is rolled back and nothing is confirmed: the purchase stays at the store
## and the next restore (app resume, next launch) delivers it.
func _deliver(id: String, token: String, unit: int) -> Dictionary:
	if token.is_empty() or not ProductDB.has(id):
		return _result(false, "Unknown purchase")
	var token_hash := token.sha256_text()
	if PlayerData.is_delivered(token_hash):
		_confirm(id, token)  # granted earlier, maybe never confirmed (crash): confirm only
		return _result(false, "Already delivered")
	# A one-time product the player already owns (reinstall, second device) gets no second reward.
	var owned := ProductDB.is_once(id) and PlayerData.has_purchase(id)
	if not owned and bool(ProductDB.get_product(id).get("pick_unit", false)) and not PlayerData.owns(unit):
		return _hold(id, token_hash, token)
	var snapshot := PlayerData.to_save().duplicate(true)
	var reward := RewardDB.empty() if owned else ProductDB.reward_of(id, unit, RandomNumberGenerator.new())
	PlayerData.grant(reward)
	PlayerData.mark_purchased(id)
	PlayerData.record_delivery(token_hash)
	if not SaveManager.persist_now():
		PlayerData.apply_save(snapshot)
		return _result(false, "Could not save, will retry")
	_live.erase(token_hash)
	_confirm(id, token)
	var out := _result(true, "Purchase complete")
	out["reward"] = reward
	return out


## Paid purchase without a soldier to give the shards to (found by a restore): not delivered, not confirmed,
## remembered until the player picks one.
func _hold(id: String, token_hash: String, token: String) -> Dictionary:
	PlayerData.add_pending(id, token_hash)
	if not PlayerData.has_pending(token_hash):
		return _result(false, "Too many unfinished purchases")
	var fresh := not _live.has(token_hash)
	_live[token_hash] = token
	if fresh:
		pending_changed.emit()
	var out := _result(false, "Choose a soldier to finish your purchase")
	out["hold"] = true
	return out


func _confirm(id: String, token: String) -> void:
	if provider != null:
		provider.confirm_delivery(id, token)


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message, "reward": RewardDB.empty()}


func _set_state(s: int) -> void:
	state = s
	state_changed.emit(s)


func _arm_timeout() -> void:
	_serial += 1
	get_tree().create_timer(timeout).timeout.connect(_on_timeout.bind(_serial))


func _on_progress(text: String, ratio: float) -> void:
	if _overlay != null:
		_overlay.set_status(text, ratio)
	if state == State.PROCESSING:
		_arm_timeout()


## The answer of the payment in progress. An ok answer that arrives when nobody waits for it any more (after
## the timeout) is delivered like a recovered purchase, so a late payment is never lost.
func _on_finished(product_id: String, ok: bool, error: String) -> void:
	if state == State.PROCESSING and product_id == _pending:
		_answered.emit([ok, error])
	elif ok and provider != null:
		_on_recovered(product_id, provider.token_of(product_id))


func _on_timeout(serial: int) -> void:
	if state == State.PROCESSING and serial == _serial:
		_answered.emit([false, "Payment timed out. If you were charged, the reward arrives by itself"])


## A paid purchase found outside buy(): app killed mid-payment, late or pending payment, new device, restore.
func _on_recovered(product_id: String, token: String) -> void:
	if state == State.PROCESSING and product_id == _pending:
		return  # the open payment owns it; if it fails, the next restore finds the purchase again
	var res := _deliver(product_id, token, -1)
	if bool(res["ok"]):
		_restored += 1
		notice.emit("Purchase delivered")
	elif String(res["message"]) != "Already delivered":
		notice.emit(String(res["message"]))


## The store says the player owns a one-time product that was delivered before: restore the flag, no reward.
func _on_ownership(product_id: String) -> void:
	if not ProductDB.is_once(product_id) or PlayerData.has_purchase(product_id):
		return
	PlayerData.mark_purchased(product_id)
	SaveManager.persist_now()
	_restored += 1
	notice.emit("Purchase restored")


func _on_restore_finished(error: String) -> void:
	_end_restore(_restore_serial, error)


func _end_restore(serial: int, error: String) -> void:
	if not _restoring or serial != _restore_serial:
		return
	_restoring = false
	if error != "":
		notice.emit(error)
	elif _restored == 0:
		notice.emit("Nothing to restore")
	else:
		notice.emit("Purchases restored")