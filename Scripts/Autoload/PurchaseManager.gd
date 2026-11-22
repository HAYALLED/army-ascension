extends Node
## Shop purchase flow (autoload "PurchaseManager"): validate -> pay -> grant -> save.
## While paying, a blocking progress overlay is shown and a second purchase is refused.
## The backend is a BillingProvider. Debug builds get MockBillingProvider (no real money);
## a release build has no provider until a real adapter is assigned, so buying fails with
## "Store not available" and a mock purchase can never reach players.

enum State { IDLE, PROCESSING }

signal state_changed(state: int)
signal _answered(result: Array)

var provider: BillingProvider = null
var state: int = State.IDLE
## Seconds before an unanswered payment is given up and the UI is unlocked. Plain var so tests can shorten it.
var timeout := 45.0

var _overlay: BlockingOverlay = null
var _pending := ""
var _serial := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if provider == null and OS.is_debug_build():
		provider = MockBillingProvider.new(get_tree())


## Buys a product. `unit` is the soldier class that gets the shards (products with pick_unit).
## Returns {"ok": bool, "message": String, "reward": Dictionary}. The reward is already saved.
func buy(id: String, unit: int = -1) -> Dictionary:
	var err := _check(id, unit)
	if err != "":
		return _result(false, err)
	_serial += 1
	var my := _serial
	_pending = id
	_set_state(State.PROCESSING)
	_overlay = BlockingOverlay.open(self, "PAYMENT")
	_overlay.set_status("Starting...", 0.0)
	provider.progress.connect(_on_progress)
	provider.finished.connect(_on_finished)
	provider.purchase.call_deferred(id)
	get_tree().create_timer(timeout).timeout.connect(_on_timeout.bind(my))
	var res: Array = await _answered
	provider.progress.disconnect(_on_progress)
	provider.finished.disconnect(_on_finished)
	_overlay.close()
	_overlay = null
	_pending = ""
	_set_state(State.IDLE)
	if not bool(res[0]):
		return _result(false, String(res[1]))
	var reward := ProductDB.reward_of(id, unit, RandomNumberGenerator.new())
	PlayerData.grant(reward)
	if ProductDB.is_once(id):
		PlayerData.mark_purchased(id)
	SaveManager.save_now()
	var out := _result(true, "Purchase complete")
	out["reward"] = reward
	return out


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
	return ""


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message, "reward": RewardDB.empty()}


func _set_state(s: int) -> void:
	state = s
	state_changed.emit(s)


func _on_progress(text: String, ratio: float) -> void:
	if _overlay != null:
		_overlay.set_status(text, ratio)


# shortcut: a provider answer that arrives after the timeout is dropped. A real adapter must
# re-deliver paid-but-unreported purchases on startup (see BillingProvider).
func _on_finished(product_id: String, ok: bool, error: String) -> void:
	if state == State.PROCESSING and product_id == _pending:
		_answered.emit([ok, error])


func _on_timeout(serial: int) -> void:
	if state == State.PROCESSING and serial == _serial:
		_answered.emit([false, "Payment timed out"])
