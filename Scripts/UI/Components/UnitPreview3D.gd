class_name UnitPreview3D
extends SubViewportContainer
## Rotating 3D preview of a soldier (SubViewport with transparent background).

@onready var _pivot: Node3D = %Pivot


func show_soldier(type: int) -> void:
	for c in _pivot.get_children():
		c.queue_free()
	var scene := load(SoldierDB.DATA[type]["model"]) as PackedScene
	if scene != null:
		_pivot.add_child(scene.instantiate())


func _process(delta: float) -> void:
	_pivot.rotation.y += delta * 0.9
