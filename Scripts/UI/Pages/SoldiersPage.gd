class_name SoldiersPage
extends Control
## Soldier collection: a grid of SoldierCards. Tapping a card opens the detail popup.

signal soldier_selected(type: int)

const CARD := preload("res://Scene/UI/Components/SoldierCard.tscn")

@onready var _grid: GridContainer = %Grid


func _ready() -> void:
	for type in SoldierDB.DATA:
		var card := CARD.instantiate() as SoldierCard
		card.setup(type)
		card.selected.connect(func(t: int) -> void: soldier_selected.emit(t))
		_grid.add_child(card)
