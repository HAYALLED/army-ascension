class_name CameraRig
extends Camera3D
## Elevated third-person follow camera with smoothing and screen shake.

@export var offset: Vector3 = Vector3(0.0, 15.0, 11.0)
@export var look_offset: Vector3 = Vector3(0.0, 0.0, -30.0)
@export var follow_x: float = 0.5
@export var smoothing: float = 7.0

@export var target: Node3D = null
var _shake: float = 0.0
var _pos: Vector3 = Vector3.ZERO
var _focus: Vector3 = Vector3.ZERO


func snap() -> void:
	if target == null:
		return
	_pos = _desired_pos()
	_focus = _desired_focus()
	look_at_from_position(_pos, _focus, Vector3.UP)


func shake(amount: float) -> void:
	_shake = maxf(_shake, minf(amount, 0.6))


func _desired_pos() -> Vector3:
	var t := target.position
	return Vector3(t.x * follow_x, 0.0, t.z) + offset


func _desired_focus() -> Vector3:
	var t := target.position
	return Vector3(t.x * follow_x, 0.0, t.z) + look_offset


func _process(delta: float) -> void:
	if target == null:
		return
	var k := 1.0 - exp(-smoothing * delta)
	_pos = _pos.lerp(_desired_pos(), k)
	_focus = _focus.lerp(_desired_focus(), k)
	_shake = move_toward(_shake, 0.0, delta * 1.8)
	var jitter := Vector3.ZERO
	if _shake > 0.0:
		jitter = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	look_at_from_position(_pos + jitter, _focus + jitter * 0.5, Vector3.UP)
