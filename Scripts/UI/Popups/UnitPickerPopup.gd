class_name UnitPickerPopup
extends Control
## Modal list of the soldier classes the player owns. Emits chosen(type), or -1 on cancel.
## Built in code with the shared UI theme. Use: var type := await UnitPickerPopup.pick(host, "Title").

signal chosen(type: int)

const THEME := preload("res://Resources/UI/ui_theme.tres")

var _title_text := ""


## Opens the picker under `host` and waits for the answer (-1 = cancelled).
static func pick(host: Node, title: String) -> int:
	var p := UnitPickerPopup.new()
	p._title_text = title
	host.add_child(p)
	return await p.chosen


func _ready() -> void:
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelPopup"
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"LabelBig"
	title.text = _title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for t in PlayerData.owned_types():
		var d: Dictionary = SoldierDB.DATA[t]
		var b := _button("%s   Lv %d   %d shards" % [d["name"], PlayerData.level_of(t), PlayerData.shards_of(t)], &"ButtonPrimary")
		if ResourceLoader.exists(String(d["icon"])):
			b.icon = load(String(d["icon"]))
			b.expand_icon = true
		b.pressed.connect(_finish.bind(t))
		box.add_child(b)
	var cancel := _button("CANCEL", &"ButtonSecondary")
	cancel.pressed.connect(_finish.bind(-1))
	box.add_child(cancel)


func _button(text: String, variation: StringName) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 88)
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = variation
	b.add_theme_font_size_override("font_size", 28)
	return b


func _finish(type: int) -> void:
	AudioManager.play("ui_click")
	chosen.emit(type)
	queue_free()
