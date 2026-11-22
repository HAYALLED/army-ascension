class_name UpgradeRow
extends PanelContainer
## One army-wide upgrade of the Upgrades page (scene: Scene/UI/Components/UpgradeRow.tscn).
## Gold only; the effect applies to the whole army (see GlobalUpgradeDB). Upgrading a
## single soldier class is done in the Soldiers tab instead.

var upgrade_id: int = GlobalUpgradeDB.Id.INCOME

@onready var _icon: TextureRect = %ClassIcon
@onready var _name: Label = %NameLabel
@onready var _stat: Label = %StatLabel
@onready var _gold: Label = %GoldCost
@onready var _button: Button = %UpgradeButton


func setup(p_id: int) -> void:
	upgrade_id = p_id


func _ready() -> void:
	_button.pressed.connect(func() -> void:
		if PlayerData.try_buy_upgrade(upgrade_id):
			AudioManager.play("gate_good"))
	PlayerData.wallet_changed.connect(_refresh)
	PlayerData.global_upgrade_changed.connect(func(_id: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var d: Dictionary = GlobalUpgradeDB.DATA[upgrade_id]
	var lv := PlayerData.upgrade_level(upgrade_id)
	var top := GlobalUpgradeDB.max_level(upgrade_id)
	_icon.texture = load(d["icon"])
	_name.text = "%s  Lv %d/%d" % [str(d["name"]).to_upper(), lv, top]
	if lv >= top:
		_stat.text = "%s\n%s  MAX" % [d["desc"], GlobalUpgradeDB.effect_text(upgrade_id, lv)]
		_gold.text = "-"
		_gold.modulate = Color.WHITE
		_button.text = "MAX"
		_button.disabled = true
		return
	_stat.text = "%s\n%s > %s" % [d["desc"], GlobalUpgradeDB.effect_text(upgrade_id, lv), GlobalUpgradeDB.effect_text(upgrade_id, lv + 1)]
	var need := GlobalUpgradeDB.cost(upgrade_id, lv)
	_gold.text = str(need)
	_gold.modulate = Color.WHITE if PlayerData.gold >= need else Color(1.0, 0.45, 0.4)
	_button.text = "UPGRADE"
	_button.disabled = not PlayerData.can_buy_upgrade(upgrade_id)
