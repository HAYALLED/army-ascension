class_name MockAdProvider
extends AdProvider
## Dev-only fake ad: 3 second countdown, then CLAIM REWARD. CLOSE ends it with no reward.
## AdService creates it in debug builds only.

const DURATION := 3.0

var _host: Node


func _init(host: Node) -> void:
	_host = host


func is_ready() -> bool:
	return true


func show(placement: String) -> void:
	var overlay := BlockingOverlay.open(_host, "AD  (dev mock: %s)" % placement)
	var close := overlay.add_button("close", "CLOSE")
	var claim := overlay.add_button("claim", "CLAIM REWARD")
	claim.disabled = true
	overlay.button_pressed.connect(func(id: String) -> void:
		overlay.close()
		finished.emit(id == "claim"))
	var tw := overlay.create_tween()
	tw.tween_method(func(r: float) -> void:
		overlay.set_status("Reward in %d s" % ceili(DURATION * (1.0 - r)), r), 0.0, 1.0, DURATION)
	tw.tween_callback(func() -> void:
		overlay.set_status("Reward ready", 1.0)
		claim.disabled = false)
	close.grab_focus()
