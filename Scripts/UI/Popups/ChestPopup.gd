class_name ChestPopup
extends Control
## Modal that shows what a chest holds before the player opens it. Units the player does not
## own yet show as "???" (opening the chest unlocks them). Emits answered(true) for OPEN and
## answered(false) for CLOSE. Built in code with the shared UI theme.
## Use: if await ChestPopup.ask(host, chest): ...open it.

signal answered(open: bool)

const THEME := preload("res://Resources/UI/ui_theme.tres")

var _chest: Dictionary = {}


## Opens the preview under `host` and waits for the answer (true = open the chest).
static func ask(host: Node, chest: Dictionary) -> bool:
	var p := ChestPopup.new()
	p._chest = chest
	host.add_child(p)
	return await p.answered


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
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var tier := int(_chest["tier"])
	var title := Label.new()
	title.theme_type_variation = &"LabelBig"
	title.text = ChestDB.name_of(tier).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if ResourceLoader.exists(ChestDB.icon_of(tier)):
		var hero := TextureRect.new()
		hero.texture = load(ChestDB.icon_of(tier))
		hero.custom_minimum_size = Vector2(0, 200)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(hero)
	for line in ChestDB.preview_lines(_chest):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		var icon := TextureRect.new()
		icon.texture = load(String(line["icon"]))
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = String(line["text"])
		label.add_theme_font_size_override("font_size", 36)
		row.add_child(label)
		box.add_child(row)
	if ChestDB.has_unknown_unit(_chest):
		var note := Label.new()
		note.theme_type_variation = &"LabelSmall"
		note.text = "??? = a new unit for your army"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	box.add_child(_button("OPEN", &"ButtonGold", true))
	box.add_child(_button("CLOSE", &"ButtonSecondary", false))


func _button(text: String, variation: StringName, open: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 88)
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = variation
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		answered.emit(open)
		queue_free())
	return b
