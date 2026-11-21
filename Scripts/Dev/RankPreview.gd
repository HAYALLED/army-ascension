extends Control
## Dev scene (Scene/Dev/RankPreview.tscn, run with F6): shows a real SoldierCard of
## every soldier in every rank so you can check the frames and fire effects.

const CARD := preload("res://Scene/UI/Components/SoldierCard.tscn")

@onready var _grid: GridContainer = %Grid
@onready var _low_graphics: CheckButton = %LowGraphics


func _ready() -> void:
	_low_graphics.button_pressed = not RankDB.fire_animation_enabled
	_low_graphics.toggled.connect(func(on: bool) -> void: RankDB.fire_animation_enabled = not on)
	for rank in RankDB.get_sorted(true):
		for type in SoldierDB.DATA:
			var card := CARD.instantiate() as SoldierCard
			card.setup(type, rank.id)
			_grid.add_child(card)
