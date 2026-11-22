class_name UpgradePage
extends Control
## Army-wide upgrades: income, damage, health, fire rate, shard luck, reinforcements.
## They affect every soldier. Per-soldier upgrades are in the Soldiers tab.

const ROW := preload("res://Scene/UI/Components/UpgradeRow.tscn")

@onready var _list: VBoxContainer = %List


func _ready() -> void:
	for id in GlobalUpgradeDB.DATA:
		var row := ROW.instantiate() as UpgradeRow
		row.setup(id)
		_list.add_child(row)
