class_name FormationTile
extends PanelContainer
## One unit tile of the "Prepare your army" popup (scene: Scene/UI/Components/FormationTile.tscn).
## Slot mode: an equipped class, or an empty slot when type = -1.
## List mode: an owned class, outlined green while it is equipped.
## Border color = rank color (RankDB). Emits pressed(type) on a tap (not on a scroll drag).

signal pressed(type: int)

const TAP_SLOP := 14.0
const EMPTY_COLOR := Color(0.4, 0.45, 0.55)
const EQUIPPED_COLOR := Color(0.35, 0.9, 0.4)

var type: int = -1

@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %NameLabel
@onready var _rank: Label = %RankLabel
@onready var _info: Label = %InfoLabel

var _list_mode := false
var _press_pos := Vector2.ZERO


func setup(p_type: int, list_mode: bool) -> void:
	type = p_type
	_list_mode = list_mode


func _ready() -> void:
	PlayerData.equipped_changed.connect(_refresh)
	PlayerData.soldier_changed.connect(func(_t: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var border := EMPTY_COLOR
	_info.remove_theme_color_override("font_color")
	_rank.visible = type >= 0
	if type < 0:
		_portrait.texture = null
		_name.text = ""
		_info.text = "EMPTY"
	else:
		var d: Dictionary = SoldierDB.DATA[type]
		var rank := RankDB.get_rank(d["rank"])
		_portrait.texture = load(d["icon"])
		_name.text = str(d["name"]).to_upper()
		_rank.text = rank.display_name
		_rank.add_theme_color_override("font_color", rank.glow_color)
		border = rank.glow_color
		_info.text = "Lv %d" % PlayerData.level_of(type)
		if _list_mode and PlayerData.is_equipped(type):
			_info.text = "EQUIPPED"
			_info.add_theme_color_override("font_color", EQUIPPED_COLOR)
			border = EQUIPPED_COLOR
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.13, 0.22, 0.95)
	box.border_color = border
	box.set_border_width_all(4 if border == EQUIPPED_COLOR else 3)
	box.set_corner_radius_all(12)
	add_theme_stylebox_override("panel", box)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif event.position.distance_to(_press_pos) < TAP_SLOP:
			pressed.emit(type)
