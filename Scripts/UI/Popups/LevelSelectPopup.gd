class_name LevelSelectPopup
extends Control
## Modal level list opened from the level banner on the home page. Beaten levels and the
## current unbeaten level can be picked; every later level is locked.
## Built in code with the shared UI theme.
## Use: var level := await LevelSelectPopup.pick(host, Game.level_index)   (-1 = closed).

signal chosen(level: int)

const THEME := preload("res://Resources/UI/ui_theme.tres")
const LOCK_ICON := "res://Assets/UI/icon_lock.png"

var _current: int = 1
var _grid: GridContainer = null


## Opens the list under `host` and waits for the answer. `current_level` is highlighted.
static func pick(host: Node, current_level: int) -> int:
	var p := LevelSelectPopup.new()
	p._current = current_level
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
	panel.custom_minimum_size = Vector2(660, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"LabelBig"
	title.text = "SELECT LEVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	for level in range(1, LevelDB.TOTAL_LEVELS + 1):
		_grid.add_child(_level_button(level))
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(0, 88)
	close.focus_mode = Control.FOCUS_NONE
	close.theme_type_variation = &"ButtonSecondary"
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(_finish.bind(-1))
	box.add_child(close)


func _level_button(level: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 120)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 26)
	var kind := "BOSS" if LevelDB.is_boss_level(level) else "MINI BOSS"
	if level > PlayerData.unlocked_level():
		b.text = "LEVEL %d\nLOCKED" % level
		b.theme_type_variation = &"ButtonDisabled"
		b.disabled = true
		if ResourceLoader.exists(LOCK_ICON):
			b.icon = load(LOCK_ICON)
			b.expand_icon = true
		return b
	var beaten := level <= PlayerData.highest_level
	b.text = "LEVEL %d\n%s%s" % [level, kind, "  -  DONE" if beaten else ""]
	b.theme_type_variation = &"ButtonGold" if level == _current else &"ButtonSecondary"
	b.pressed.connect(_finish.bind(level))
	return b


func _finish(level: int) -> void:
	AudioManager.play("ui_click")
	chosen.emit(level)
	queue_free()
