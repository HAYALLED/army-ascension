class_name UpgradeRow
extends PanelContainer
## One army-wide upgrade of the Upgrades page (scene: Scene/UI/Components/UpgradeRow.tscn).
## Gold only; the effect applies to the whole army (see GlobalUpgradeDB). There is no level
## limit: a TierBar shows the progress inside the current tier of 10 levels and changes color
## every tier. Upgrading a single soldier class is done in the Soldiers tab instead.

var upgrade_id: int = GlobalUpgradeDB.Id.INCOME

var _bar: TierBar = null
var _shown_once: bool = false

@onready var _icon: TextureRect = %ClassIcon
@onready var _name: Label = %NameLabel
@onready var _stat: Label = %StatLabel
@onready var _gold: Label = %GoldCost
@onready var _button: Button = %UpgradeButton


func setup(p_id: int) -> void:
	upgrade_id = p_id


func _ready() -> void:
	_bar = TierBar.new()
	_bar.name = "TierBar"
	_bar.custom_minimum_size = Vector2(0, 30)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat.get_parent().add_child(_bar)
	_button.pressed.connect(_on_button)
	PlayerData.wallet_changed.connect(_refresh)
	PlayerData.global_upgrade_changed.connect(func(_id: int) -> void: _refresh())
	_refresh()


func _on_button() -> void:
	var before := PlayerData.upgrade_level(upgrade_id)
	if not PlayerData.try_buy_upgrade(upgrade_id):
		return
	AudioManager.play("gate_good")
	var tier_up := GlobalUpgradeDB.tier_of(float(before + 1)) > GlobalUpgradeDB.tier_of(float(before))
	_flash(1.9 if tier_up else 1.45)


func _flash(strength: float) -> void:
	_bar.modulate = Color(strength, strength, strength)
	create_tween().tween_property(_bar, "modulate", Color.WHITE, 0.4)


func _refresh() -> void:
	var d: Dictionary = GlobalUpgradeDB.DATA[upgrade_id]
	var lv := PlayerData.upgrade_level(upgrade_id)
	var tier_color := GlobalUpgradeDB.tier_color(GlobalUpgradeDB.tier_of(float(lv)))
	_icon.texture = load(d["icon"])
	_name.text = "%s  Lv %d" % [str(d["name"]).to_upper(), lv]
	_name.add_theme_color_override("font_color", tier_color.lightened(0.25))
	_bar.set_level(lv, _shown_once)
	_shown_once = true
	if GlobalUpgradeDB.is_capped(upgrade_id, lv):
		_stat.text = "%s\n%s  (army is full)" % [d["desc"], GlobalUpgradeDB.effect_text(upgrade_id, lv)]
		_gold.text = "-"
		_gold.modulate = Color.WHITE
		_button.text = "FULL"
		_button.disabled = true
		return
	_stat.text = "%s\n%s > %s" % [d["desc"], GlobalUpgradeDB.effect_text(upgrade_id, lv), GlobalUpgradeDB.effect_text(upgrade_id, lv + 1)]
	var need := GlobalUpgradeDB.cost(upgrade_id, lv)
	_gold.text = str(need)
	_gold.modulate = Color.WHITE if PlayerData.gold >= need else Color(1.0, 0.45, 0.4)
	_button.text = "UPGRADE"
	_button.disabled = not PlayerData.can_buy_upgrade(upgrade_id)
