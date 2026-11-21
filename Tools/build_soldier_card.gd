extends "res://Tools/build_ui_scenes.gd"
## Regenerates ONLY Scene/UI/Components/SoldierCard.tscn (other scenes untouched).
## Run:  godot --headless --path . res://Tools/build_soldier_card.tscn


func _ready() -> void:
	_theme = load("res://Resources/UI/ui_theme.tres")
	_soldier_card()
	get_tree().quit()
