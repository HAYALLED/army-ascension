extends Node
## Headless test of the defeat flow in a real battle: the army is wiped, the HUD must offer
## the ad revive (or the defeat screen when no ad is available). Run:
## godot --headless --path . res://Tools/test_revive_ui.tscn
## Never writes a save file.

## Ad backend that pays out at once, so the test does not wait for the 3 second dev mock.
class InstantAd extends AdProvider:
	func is_ready() -> bool:
		return true

	func show(_placement: String) -> void:
		finished.emit.call_deferred(true)


var _failed := 0
var _battle: Node = null
var _hud: HUD = null
var _real_provider: AdProvider = null


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_real_provider = AdService.provider
	AdService.provider = InstantAd.new()
	await _fresh_battle()
	_check("ads available in this test (mock provider)", AdService.is_available())
	# grow the army first: the revive must bring back the biggest army of the run, not the army at death
	Game.army.add_random_soldiers(10)
	var peak := Game.peak_soldiers
	_check("0a peak army size is tracked (> start army)", peak == Game.soldiers.size() and peak > RewardDB.REVIVE_SOLDIERS)
	await _wipe_army()
	_check("1a army wiped -> state REVIVE", Game.state == Game.State.REVIVE)
	_check("1b HUD shows a popup (no stuck screen)", _hud._overlay.visible)
	_check("1c popup is the revive offer", _hud._mode == HUD.Mode.REVIVE)
	_check("1d revive popup has both buttons", _hud._primary.visible and _hud._secondary.visible)

	# watch the ad -> army comes back, battle continues
	_hud._on_primary()
	await _wait(3.0)
	_check("2a ad watched -> battle resumes", Game.state == Game.State.PLAYING and not get_tree().paused)
	_check("2b the peak army is back (%d)" % peak, Game.soldiers.size() == peak)
	_check("2b2 revive adds +20%% damage", is_equal_approx(Game.damage_buff, 1.0 + RewardDB.REVIVE_DAMAGE_BUFF))
	_check("2c popup closed", not _hud._overlay.visible)

	# second wipe in the same run -> no second revive, defeat screen
	await _wipe_army()
	_check("3a second wipe -> DEFEAT screen, no second revive", Game.state == Game.State.LOST and _hud._mode == HUD.Mode.LOSE and _hud._overlay.visible)
	_check("3b defeat screen has TRY AGAIN and HOME", _hud._primary.visible and _hud._secondary.visible)

	# decline the revive -> defeat screen
	await _fresh_battle()
	await _wipe_army()
	_check("4a revive offered again in a new run", Game.state == Game.State.REVIVE and _hud._mode == HUD.Mode.REVIVE)
	_hud._on_secondary()
	await get_tree().process_frame
	_check("4b NO THANKS -> DEFEAT screen", Game.state == Game.State.LOST and _hud._mode == HUD.Mode.LOSE and _hud._overlay.visible)
	_check("4c game is not left paused", not get_tree().paused)

	# no ads available (release build without provider) -> straight to defeat
	await _fresh_battle()
	AdService.provider = null
	await _wipe_army()
	_check("5a no ads -> DEFEAT screen at once", Game.state == Game.State.LOST and _hud._mode == HUD.Mode.LOSE and _hud._overlay.visible)
	AdService.provider = _real_provider

	# the real dev mock ad (3 s countdown + CLAIM REWARD) must work while the tree is paused
	await _fresh_battle()
	AdService.provider = MockAdProvider.new(AdService)
	await _wipe_army()
	_check("6a mock ad: revive offered", Game.state == Game.State.REVIVE and _hud._mode == HUD.Mode.REVIVE)
	var peak2 := Game.peak_soldiers
	_hud._on_primary()
	await _wait(0.3)
	var claim := await _find_button(AdService, "CLAIM REWARD")
	_check("6b mock ad overlay opens while paused", claim != null and Game.state == Game.State.REVIVE)
	if claim != null:
		var start := Time.get_ticks_msec()
		while claim.disabled and Time.get_ticks_msec() - start < 8000:
			await get_tree().process_frame
		_check("6c claim button unlocks after the countdown", not claim.disabled)
		claim.pressed.emit()
		await _wait(0.5)
	_check("6d claimed -> battle resumes with soldiers", Game.state == Game.State.PLAYING and Game.soldiers.size() == peak2 and not _hud._overlay.visible)
	AdService.provider = _real_provider

	PlayerData.reset_to_defaults()
	Game.level_index = 1
	Game.reset_run()
	get_tree().paused = false
	get_tree().quit(0 if _failed == 0 else 1)


func _fresh_battle() -> void:
	get_tree().paused = false
	if _battle != null:
		_battle.queue_free()
		await get_tree().process_frame
	PlayerData.reset_to_defaults()
	Game.level_index = 1
	Game.reset_run()
	_battle = load("res://Scene/Ingame/Battle.tscn").instantiate()
	add_child(_battle)
	await _wait(0.5)
	_hud = _battle.get_node("HUD") as HUD
	if Game.state != Game.State.PLAYING:
		Game.start_battle()
	await get_tree().process_frame


func _wipe_army() -> void:
	for s: Soldier in Game.soldiers.duplicate():
		s.take_damage(999999.0)
	await _wait(0.6)


## Waits real frames (the tree may be paused, so this does not use timers).
func _wait(seconds: float) -> void:
	var frames := int(seconds * 60.0)
	for i in frames:
		await get_tree().process_frame


func _find_button(root: Node, label: String) -> Button:
	for i in 30:
		for b in root.find_children("*", "Button", true, false):
			if (b as Button).text == label:
				return b as Button
		await get_tree().process_frame
	return null
