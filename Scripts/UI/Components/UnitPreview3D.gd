class_name UnitPreview3D
extends SubViewportContainer
## Rotating 3D preview of a soldier (SubViewport with transparent background).

## Camera looks down at the soldier from above and in front, so the player never sees the
## thin / empty sides and undersides of the models while they spin.
const PITCH_DEGREES := 30.0
const DISTANCE := 3.8
const TARGET := Vector3(0.0, 0.6, 0.1)

@onready var _pivot: Node3D = %Pivot
@onready var _camera: Camera3D = $Viewport/Camera3D


func _ready() -> void:
	var pitch := deg_to_rad(PITCH_DEGREES)
	var from := TARGET + Vector3(0.0, sin(pitch), cos(pitch)) * DISTANCE
	_camera.look_at_from_position(from, TARGET, Vector3.UP)


func show_soldier(type: int) -> void:
	for c in _pivot.get_children():
		c.queue_free()
	var scene := load(SoldierDB.DATA[type]["model"]) as PackedScene
	if scene != null:
		_pivot.add_child(scene.instantiate())


func _process(delta: float) -> void:
	_pivot.rotation.y += delta * 0.9
