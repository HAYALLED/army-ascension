class_name SoldierCard
extends PanelContainer
## Collection card of one soldier class (scene: Scene/UI/Components/SoldierCard.tscn).

signal selected(type: int)

const FRAMES := [
	"res://Assets/UI/frame_common.png", "res://Assets/UI/frame_rare.png",
	"res://Assets/UI/frame_epic.png", "res://Assets/UI/frame_legendary.png",
]

var type: int = SoldierDB.Type.RIFLEMAN

@onready var _frame: TextureRect = %Frame
@onready var _icon: TextureRect = %ClassIcon
@onready var _name: Label = %NameLabel
@onready var _level: Label = %LevelLabel
@onready var _rarity: Label = %RarityLabel
@onready var _bar: TextureProgressBar = %ShardBar
@onready var _shard_label: Label = %ShardLabel
@onready var _upgrade: Button = %UpgradeButton

var _press_pos: Vector2 = Vector2.ZERO


func setup(p_type: int) -> void:
	type = p_type


func _ready() -> void:
	_upgrade.pressed.connect(_on_upgrade)
	PlayerData.wallet_changed.connect(_refresh)
	PlayerData.soldier_changed.connect(func(_t: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var d: Dictionary = SoldierDB.DATA[type]
	var lv := PlayerData.level_of(type)
	var rarity: int = d["rarity"]
	_icon.texture = load(d["icon"])
	_frame.texture = load(FRAMES[rarity])
	_name.text = str(d["name"]).to_upper()
	_level.text = "Lv %d" % lv
	_rarity.text = SoldierDB.RARITY_NAMES[rarity]
	_rarity.add_theme_color_override("font_color", SoldierDB.RARITY_COLORS[rarity])
	var need := SoldierDB.upgrade_shards(lv)
	var have := PlayerData.shards_of(type)
	_bar.max_value = need
	_bar.value = mini(have, need)
	if lv >= SoldierDB.MAX_LEVEL:
		_shard_label.text = "MAX"
		_upgrade.text = "MAX"
		_upgrade.disabled = true
	else:
		_shard_label.text = "%d/%d" % [have, need]
		_upgrade.text = "UPGRADE"
		_upgrade.disabled = not PlayerData.can_upgrade(type)


func _on_upgrade() -> void:
	if PlayerData.try_upgrade(type):
		AudioManager.play("gate_good")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif event.position.distance_to(_press_pos) < 14.0:
			AudioManager.play("ui_click")
			selected.emit(type)
