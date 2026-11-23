extends Node
## Headless test of the Upgrades page rows (tier bar, no level limit) and the unit preview camera.
## Run: godot --headless --path . res://Tools/test_upgrade_ui.tscn
## Never writes a save file.

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	PlayerData.reset_to_defaults()
	await _test_page()
	await _test_tier_up()
	await _test_preview()
	PlayerData.reset_to_defaults()
	get_tree().quit(0 if _failed == 0 else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _test_page() -> void:
	var page: Node = load("res://Scene/Menus/Pages/UpgradePage.tscn").instantiate()
	add_child(page)
	await _frames(3)
	var rows: Array = page.find_children("*", "UpgradeRow", true, false)
	_check("page lists every army upgrade", rows.size() == GlobalUpgradeDB.DATA.size())
	var ok := true
	for r in rows:
		var row := r as UpgradeRow
		ok = ok and row._bar != null and row._bar.get_parent() == row._stat.get_parent()
	_check("each row has a tier bar under its text", ok)
	page.queue_free()
	await _frames(2)


func _test_tier_up() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.gold = PlayerData.MAX_CURRENCY
	var row := load("res://Scene/UI/Components/UpgradeRow.tscn").instantiate() as UpgradeRow
	row.setup(GlobalUpgradeDB.Id.DAMAGE)
	add_child(row)
	await _frames(2)
	var first := row._bar.current_color()
	_check("bar starts empty, button enabled", PlayerData.upgrade_level(GlobalUpgradeDB.Id.DAMAGE) == 0 and not row._button.disabled)
	for i in 9:
		row._button.pressed.emit()
	await _frames(2)
	_check("level 9: bar still in the first color", PlayerData.upgrade_level(GlobalUpgradeDB.Id.DAMAGE) == 9 and row._bar.current_color() == first)
	row._button.pressed.emit()
	await _frames(2)
	_check("level 10: bar changes color", PlayerData.upgrade_level(GlobalUpgradeDB.Id.DAMAGE) == 10 and row._bar.current_color() != first)
	for i in 15:
		row._button.pressed.emit()
	await _frames(2)
	_check("no limit: level 25 reached, button still enabled", PlayerData.upgrade_level(GlobalUpgradeDB.Id.DAMAGE) == 25 and not row._button.disabled)
	_check("name shows the level", row._name.text.ends_with("Lv 25"))
	row.queue_free()
	await _frames(1)
	PlayerData.reset_to_defaults()
	PlayerData.gold = PlayerData.MAX_CURRENCY
	var rein := load("res://Scene/UI/Components/UpgradeRow.tscn").instantiate() as UpgradeRow
	rein.setup(GlobalUpgradeDB.Id.REINFORCEMENTS)
	add_child(rein)
	await _frames(2)
	for i in 40:
		PlayerData.gold = PlayerData.MAX_CURRENCY
		rein._button.pressed.emit()
	await _frames(2)
	_check("Reinforcements row shows FULL at its cap", rein._button.disabled and rein._button.text == "FULL")
	rein.queue_free()
	await _frames(1)


func _test_preview() -> void:
	var preview := load("res://Scene/UI/Components/UnitPreview3D.tscn").instantiate() as UnitPreview3D
	add_child(preview)
	preview.show_soldier(SoldierDB.Type.SNIPER)
	await _frames(2)
	var cam := preview.get_node("Viewport/Camera3D") as Camera3D
	var pitch := rad_to_deg(asin(-cam.global_transform.basis.z.y))
	_check("preview camera looks down about 30 degrees", absf(pitch + UnitPreview3D.PITCH_DEGREES) < 1.0 or absf(absf(pitch) - UnitPreview3D.PITCH_DEGREES) < 1.0)
	_check("preview camera is above the soldier and in front", cam.position.y > 1.8 and cam.position.z > 2.5)
	preview.queue_free()
