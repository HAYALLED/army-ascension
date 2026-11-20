class_name UpgradeRow
extends PanelContainer
## One row of the Upgrades page (scene: Scene/UI/Components/UpgradeRow.tscn).

var type: int = SoldierDB.Type.RIFLEMAN

@onready var _icon: TextureRect = %ClassIcon
@onready var _name: Label = %NameLabel
@onready var _stat: Label = %StatLabel
@onready var _gold: Label = %GoldCost
@onready var _shards: Label = %ShardCost
@onready var _button: Button = %UpgradeButton


func setup(p_type: int) -> void:
	type = p_type


func _ready() -> void:
	_button.pressed.connect(func() -> void:
		if PlayerData.try_upgrade(type):
			AudioManager.play("gate_good"))
	PlayerData.wallet_changed.connect(_refresh)
	PlayerData.soldier_changed.connect(func(_t: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var d: Dictionary = SoldierDB.DATA[type]
	var lv := PlayerData.level_of(type)
	_icon.texture = load(d["icon"])
	_name.text = "%s  Lv %d" % [str(d["name"]).to_upper(), lv]
	var now := SoldierDB.stats(type, lv)
	if lv >= SoldierDB.MAX_LEVEL:
		_stat.text = "DMG %d  HP %d  MAX" % [now["damage"], now["health"]]
		_gold.text = "-"
		_shards.text = "-"
		_button.text = "MAX"
		_button.disabled = true
		return
	var nxt := SoldierDB.stats(type, lv + 1)
	_stat.text = "DMG %d>%d  HP %d>%d" % [now["damage"], nxt["damage"], now["health"], nxt["health"]]
	var gold_need := SoldierDB.upgrade_gold(lv)
	var shard_need := SoldierDB.upgrade_shards(lv)
	_gold.text = str(gold_need)
	_gold.modulate = Color.WHITE if PlayerData.gold >= gold_need else Color(1.0, 0.45, 0.4)
	_shards.text = "%d/%d" % [PlayerData.shards_of(type), shard_need]
	_shards.modulate = Color.WHITE if PlayerData.shards_of(type) >= shard_need else Color(1.0, 0.45, 0.4)
	_button.text = "UPGRADE"
	_button.disabled = not PlayerData.can_upgrade(type)
