class_name SoldiersPage
extends Control
## Soldier collection: a grid of SoldierCards. Tapping a card opens the detail popup.

signal soldier_selected(type: int)

const CARD := preload("res://Scene/UI/Components/SoldierCard.tscn")

@onready var _grid: GridContainer = %Grid


func _ready() -> void:
	var types: Array = SoldierDB.DATA.keys()
	types.sort_custom(_before)
	for type in types:
		var card := CARD.instantiate() as SoldierCard
		card.setup(type)
		card.selected.connect(func(t: int) -> void: soldier_selected.emit(t))
		_grid.add_child(card)


## Card order: owned units first, then by rank (weakest first), then by class id.
func _before(a: int, b: int) -> bool:
	var owned_a := PlayerData.owns(a)
	var owned_b := PlayerData.owns(b)
	if owned_a != owned_b:
		return owned_a
	var rank_a := RankDB.get_order(SoldierDB.DATA[a]["rank"])
	var rank_b := RankDB.get_order(SoldierDB.DATA[b]["rank"])
	if rank_a != rank_b:
		return rank_a < rank_b
	return a < b
