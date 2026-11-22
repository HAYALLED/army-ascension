class_name BlockingOverlay
extends CanvasLayer
## Full-screen modal with a title, a status line, a progress bar and optional buttons.
## Blocks all input underneath. Used for the ad countdown and the purchase progress.
## Built in code (no scene) with the shared UI theme. Runs while the tree is paused.

signal button_pressed(id: String)

const THEME := preload("res://Resources/UI/ui_theme.tres")

var _title: Label
var _status: Label
var _bar: ProgressBar
var _buttons: VBoxContainer


## Adds an overlay to `host` and returns it. Call close() when done.
static func open(host: Node, title: String) -> BlockingOverlay:
	var o := BlockingOverlay.new()
	o._build(title)
	host.add_child(o)
	return o


func set_status(text: String, ratio: float) -> void:
	_status.text = text
	_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


## Adds a button under the bar. Pressing it emits button_pressed(id).
func add_button(id: String, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 30)
	b.theme_type_variation = &"ButtonPrimary" if id == "claim" else &"ButtonSecondary"
	b.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		button_pressed.emit(id))
	_buttons.add_child(b)
	return b


func close() -> void:
	queue_free()


func _build(title: String) -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.theme = THEME
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelPopup"
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	_title = Label.new()
	_title.theme_type_variation = &"LabelBig"
	_title.text = title
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 28)
	box.add_child(_bar)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	box.add_child(_buttons)
