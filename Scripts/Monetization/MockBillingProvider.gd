class_name MockBillingProvider
extends BillingProvider
## Dev-only fake store: three timed stages, then success. PurchaseManager creates it in debug builds only.

const STAGES := [["Connecting to store...", 0.7], ["Processing payment...", 1.3], ["Confirming purchase...", 0.6]]

## Set true to make the next purchase fail (tests and manual checks of the failure path).
var fail_next := false

var _tree: SceneTree
var _count := 0
var _tokens := {}


func _init(tree: SceneTree) -> void:
	_tree = tree


func purchase(product_id: String) -> void:
	var total := 0.0
	for s in STAGES:
		total += float(s[1])
	var done := 0.0
	for s in STAGES:
		progress.emit(String(s[0]), done / total)
		await _tree.create_timer(float(s[1])).timeout
		done += float(s[1])
	if fail_next:
		fail_next = false
		finished.emit(product_id, false, "Payment declined")
		return
	progress.emit("Done", 1.0)
	_count += 1
	_tokens[product_id] = "mock-%d-%d" % [Time.get_ticks_usec(), _count]
	finished.emit(product_id, true, "")


func token_of(product_id: String) -> String:
	return String(_tokens.get(product_id, ""))
