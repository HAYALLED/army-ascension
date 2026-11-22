class_name RewardPopup
extends Control
## Modal that lists what the player just received (ad rewards, chests, purchases).
## Built in code with the shared UI theme. Use: await RewardPopup.show_reward(host, "TITLE", reward).

signal closed()

const THEME := preload("res://Resources/UI/ui_theme.tres")

var _title_text := ""
var _reward: Dictionary = {}
var _note := ""
var _icon_path := ""


## Opens the popup under `host` and waits until the player presses OK.
static func show_reward(host: Node, title: String, reward: Dictionary, note: String = "", icon_path: String = "") -> void:
	var p := RewardPopup.new()
	p._title_text = title
	p._reward = reward
	p._note = note
	p._icon_path = icon_path
	host.add_child(p)
	await p.closed


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
	var title := Label.new()
	title.theme_type_variation = &"LabelBig"
	title.text = _title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if _icon_path != "" and ResourceLoader.exists(_icon_path):
		var hero := TextureRect.new()
		hero.texture = load(_icon_path)
		hero.custom_minimum_size = Vector2(0, 200)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(hero)
	for line in RewardDB.lines(_reward):
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
	if _note != "":
		var note := Label.new()
		note.theme_type_variation = &"LabelSmall"
		note.text = _note
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(0, 88)
	ok.focus_mode = Control.FOCUS_NONE
	ok.theme_type_variation = &"ButtonPrimary"
	ok.add_theme_font_size_override("font_size", 32)
	ok.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		closed.emit()
		queue_free())
	box.add_child(ok)
