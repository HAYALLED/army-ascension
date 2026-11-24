class_name ChestSlot
extends PanelContainer
## One of the ChestDB.SLOTS chest slots under the DAILY / FREE CHEST buttons on the home page.
## Shows the chest the slot holds (wooden / silver / gold) or stays empty; tapping it emits
## pressed(index) and HomePage opens the preview. Built in code with the shared UI theme.

signal pressed(index: int)

const EMPTY_ICON := "res://Assets/UI/chest_wood.png"

## 0-based position of the slot (0..SLOTS-1).
var index: int = 0

var _icon: TextureRect
var _label: Label
var _tick := 0.0


## "H:MM:SS" from 1 hour up, "M:SS" below.
static func clock(seconds: int) -> String:
	if seconds >= 3600:
		return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori((seconds % 3600) / 60.0), seconds % 60]
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func setup(p_index: int) -> void:
	index = p_index
	name = "ChestSlot%d" % (p_index + 1)


func _ready() -> void:
	theme_type_variation = &"PanelDark"
	custom_minimum_size = Vector2(0, 170)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.custom_minimum_size = Vector2(0, 96)
	_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_icon)
	_label = Label.new()
	_label.name = "StateLabel"
	_label.theme_type_variation = &"LabelSmall"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_label)
	PlayerData.chests_changed.connect(refresh)
	refresh()


## Redraws the slot from PlayerData.chest_slots[index].
func refresh() -> void:
	var chest: Dictionary = PlayerData.chest_slots[index] if index < PlayerData.chest_slots.size() else {}
	var path := EMPTY_ICON
	if chest.is_empty():
		_icon.modulate = Color(1.0, 1.0, 1.0, 0.2)
		_label.text = "EMPTY"
	else:
		path = ChestDB.icon_of(int(chest["tier"]))
		_icon.modulate = Color.WHITE
		var left := PlayerData.chest_left(index)
		_label.text = String(ChestDB.DATA[int(chest["tier"])]["short"]) if left <= 0 else clock(left)
	if ResourceLoader.exists(path):
		_icon.texture = load(path)


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		if is_visible_in_tree():
			refresh()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(index)
