# path: scripts/data/UnitClassData.gd
class_name UnitClassData
extends Resource
## One unit class/category (Deadeye, Assault, ...). Not related to rank.
## Add a new class = add a .tres in res://resources/classes/.

enum Row { ANY, BACK, MID, FRONT }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_texture: Texture2D
@export var tint: Color = Color.WHITE
@export var preferred_row: Row = Row.ANY
## Order of filter tabs / sorting.
@export var sort_order: int = 0


func is_valid() -> bool:
	return id != &""
