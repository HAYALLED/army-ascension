class_name UpgradePage
extends Control
## Quick upgrade list: one row per soldier class.

const ROW := preload("res://Scene/UI/Components/UpgradeRow.tscn")

@onready var _list: VBoxContainer = %List


func _ready() -> void:
	for type in SoldierDB.DATA:
		var row := ROW.instantiate() as UpgradeRow
		row.setup(type)
		_list.add_child(row)
