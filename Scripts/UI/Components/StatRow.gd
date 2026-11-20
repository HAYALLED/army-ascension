class_name StatRow
extends HBoxContainer
## One stat line of the soldier detail popup: icon, name, value, next-level bonus.

@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %NameLabel
@onready var _value: Label = %ValueLabel
@onready var _next: Label = %NextLabel


func setup(icon_path: String, stat_name: String, value: String, next_text: String) -> void:
	if not is_node_ready():
		await ready
	_icon.texture = load(icon_path)
	_name.text = stat_name
	_value.text = value
	_next.text = next_text
	_next.visible = next_text != ""
