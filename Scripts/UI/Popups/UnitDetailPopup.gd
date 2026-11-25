class_name UnitDetailPopup
extends Control
## Soldier detail: rotating 3D model, stats with next-level bonus, upgrade.

signal closed()

const STAT_ROW := preload("res://Scene/UI/Components/StatRow.tscn")

var type: int = SoldierDB.Type.RIFLEMAN

@onready var _preview: UnitPreview3D = %Preview
@onready var _name: Label = %NameLabel
@onready var _rarity: Label = %RarityLabel
@onready var _level: Label = %LevelLabel
@onready var _stats: VBoxContainer = %Stats
@onready var _gold: Label = %GoldCost
@onready var _shards: Label = %ShardCost
@onready var _upgrade: Button = %UpgradeButton
@onready var _close: Button = %CloseButton
@onready var _desc: Label = %DescLabel
@onready var _passive_box: PanelContainer = %PassivePanel
@onready var _passive: Label = %PassiveLabel


func setup(p_type: int) -> void:
	type = p_type


func _ready() -> void:
	_close.pressed.connect(close)
	_upgrade.pressed.connect(func() -> void:
		if PlayerData.try_upgrade(type):
			AudioManager.play("gate_good"))
	PlayerData.wallet_changed.connect(_refresh)
	_preview.show_soldier(type)
	_refresh()


func close() -> void:
	AudioManager.play("ui_click")
	closed.emit()
	queue_free()


func _refresh() -> void:
	var d: Dictionary = SoldierDB.DATA[type]
	var lv := PlayerData.level_of(type)
	var rank := RankDB.get_rank(d["rank"])
	var unit_class := UnitClassDB.get_unit_class(d["class"])
	_name.text = str(d["name"]).to_upper()
	_rarity.text = "%s - %s" % [rank.display_name, unit_class.display_name]
	_rarity.add_theme_color_override("font_color", rank.glow_color)
	_level.text = "Lv %d" % lv if PlayerData.owns(type) else "LOCKED"
	var ability := SoldierDB.ability_text(type)
	_desc.text = str(d.get("desc", ""))
	_passive_box.visible = ability != ""
	_passive.text = "Passive: " + ability
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.07, 0.12, 0.92)
	box.border_color = rank.glow_color
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	_passive_box.add_theme_stylebox_override("panel", box)
	for c in _stats.get_children():
		c.queue_free()
	var now := SoldierDB.stats(type, lv)
	var nxt := SoldierDB.stats(type, lv + 1) if lv < SoldierDB.MAX_LEVEL else now
	var is_max := lv >= SoldierDB.MAX_LEVEL
	_add_stat("res://Assets/UI/icon_damage.png", "Damage", now["damage"], nxt["damage"], is_max)
	_add_stat("res://Assets/UI/icon_health.png", "Health", now["health"], nxt["health"], is_max)
	_add_stat("res://Assets/UI/icon_firerate.png", "Fire rate", now["attack_speed"], now["attack_speed"], true, "/s")
	_add_stat("res://Assets/UI/icon_range.png", "Range", now["range"], now["range"], true)
	if is_max:
		_gold.text = "-"
		_shards.text = "-"
		_upgrade.text = "MAX LEVEL"
		_upgrade.disabled = true
		return
	var gold_need := SoldierDB.upgrade_gold(lv, type)
	var shard_need := SoldierDB.upgrade_shards(lv, type)
	_gold.text = str(gold_need)
	_gold.modulate = Color.WHITE if PlayerData.gold >= gold_need else Color(1.0, 0.45, 0.4)
	_shards.text = "%d/%d" % [PlayerData.shards_of(type), shard_need]
	_shards.modulate = Color.WHITE if PlayerData.shards_of(type) >= shard_need else Color(1.0, 0.45, 0.4)
	_upgrade.text = "UPGRADE" if PlayerData.owns(type) else "LOCKED"
	_upgrade.disabled = not PlayerData.can_upgrade(type)


func _add_stat(icon_path: String, stat_name: String, value: float, next: float, same: bool, unit: String = "") -> void:
	var row := STAT_ROW.instantiate() as StatRow
	_stats.add_child(row)
	var v := "%s%s" % [_fmt(value), unit]
	var bonus := "" if same or is_equal_approx(value, next) else "+%s" % _fmt(next - value)
	row.setup(icon_path, stat_name, v, bonus)


func _fmt(v: float) -> String:
	return str(int(round(v))) if absf(v - round(v)) < 0.05 else "%.1f" % v
