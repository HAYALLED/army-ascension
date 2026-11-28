class_name UnitFilterBar
extends MarginContainer
## Class + rank filter chips for unit lists (Soldiers tab, Prepare your army). Built in code, no scene.
## One chip per row is active at most; tapping the active chip clears it. Both rows combine (AND).
## Chips come from UnitClassDB / RankDB, so a new class or rank .tres shows up by itself.
## Use: add it above the list, connect `changed`, then show a unit only when matches(type) is true.

signal changed()

var _class_id: StringName = &""
var _rank_id: StringName = &""


func _ready() -> void:
	for side in ["left", "right"]:
		add_theme_constant_override("margin_" + side, 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var classes := HFlowContainer.new()
	for c: UnitClassData in UnitClassDB.get_sorted():
		_chip(classes, c.display_name, c.id, true)
	box.add_child(classes)
	var ranks := HFlowContainer.new()
	for r: RankData in RankDB.get_sorted():
		_chip(ranks, r.display_name, r.id, false)
	box.add_child(ranks)


## True when the unit passes both filters (an empty filter passes everything).
func matches(type: int) -> bool:
	var d: Dictionary = SoldierDB.DATA[type]
	return (_class_id == &"" or d["class"] == _class_id) and (_rank_id == &"" or d["rank"] == _rank_id)


func _chip(row: HFlowContainer, text: String, id: StringName, is_class: bool) -> void:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = &"ButtonSecondary"
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.toggled.connect(_on_chip.bind(b, row, id, is_class))
	row.add_child(b)


func _on_chip(on: bool, chip: Button, row: HFlowContainer, id: StringName, is_class: bool) -> void:
	AudioManager.play("ui_click")
	if on:
		for other in row.get_children():
			if other != chip:
				(other as Button).set_pressed_no_signal(false)
	if is_class:
		_class_id = id if on else &""
	else:
		_rank_id = id if on else &""
	changed.emit()
