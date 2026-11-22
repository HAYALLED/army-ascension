extends Node
## Headless tests for level selection and the chest slots.
## Run: godot --headless --path . res://Tools/test_level_select.tscn
## Never writes a save file.

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_rules()
	await _test_popup(0, 1)
	await _test_popup(3, 2)
	await _test_popup(LevelDB.TOTAL_LEVELS, 10)
	await _test_slots()
	PlayerData.reset_to_defaults()
	Game.level_index = 1
	get_tree().quit(0 if _failed == 0 else 1)


func _test_rules() -> void:
	PlayerData.reset_to_defaults()
	Game.level_index = 1
	_check("new player: only level 1", Game.select_level(1) and not Game.select_level(2))
	PlayerData.highest_level = 3
	_check("3 beaten: levels 1-4 selectable", Game.select_level(1) and Game.select_level(3) and Game.select_level(4) and Game.level_index == 4)
	_check("3 beaten: level 5 locked and index unchanged", not Game.select_level(5) and Game.level_index == 4)
	_check("level 0 and negatives refused", not Game.select_level(0) and not Game.select_level(-2) and Game.level_index == 4)
	PlayerData.highest_level = LevelDB.TOTAL_LEVELS
	_check("all beaten: last level selectable, past it refused",
		Game.select_level(LevelDB.TOTAL_LEVELS) and not Game.select_level(LevelDB.TOTAL_LEVELS + 1))


## `beaten` levels done: levels 1..unlocked are enabled, the rest disabled; `current` is highlighted.
func _test_popup(beaten: int, current: int) -> void:
	PlayerData.reset_to_defaults()
	PlayerData.highest_level = beaten
	var p := LevelSelectPopup.new()
	p._current = current
	add_child(p)
	await get_tree().process_frame
	var buttons: Array = p._grid.get_children()
	var unlocked := PlayerData.unlocked_level()
	var ok := buttons.size() == LevelDB.TOTAL_LEVELS
	for i in buttons.size():
		var b := buttons[i] as Button
		ok = ok and (b.disabled == (i + 1 > unlocked))
	_check("popup with %d beaten: %d enabled, rest locked" % [beaten, unlocked], ok)
	var cur := buttons[current - 1] as Button
	_check("popup highlights level %d" % current, cur.theme_type_variation == &"ButtonGold")
	p.queue_free()
	await get_tree().process_frame


func _test_slots() -> void:
	var box := HBoxContainer.new()
	add_child(box)
	for i in 4:
		var s := ChestSlot.new()
		s.setup(i)
		box.add_child(s)
	await get_tree().process_frame
	var ok := box.get_child_count() == 4
	for i in 4:
		var s := box.get_child(i) as ChestSlot
		ok = ok and s.index == i and (s.get_node("Box/StateLabel") as Label).text == "EMPTY"
	_check("4 empty chest slots", ok)
	box.queue_free()
