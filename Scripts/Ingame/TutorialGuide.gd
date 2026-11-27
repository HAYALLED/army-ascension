class_name TutorialGuide
extends Node3D
## Sergeant Tatter, the flag-carrying tutorial guide (scene: Scene/Units/TutorialGuide.tscn).
## Runs ahead of the army, never takes damage and has no collision. Uses Assets/Units/tutorial_guide.glb
## when it exists, otherwise a primitive placeholder. Node layout: Body -> ModelSlot (rotated 180 deg so the
## glb, which faces +Z, faces -Z = the advance direction) -> model.
## Poses: follow (default), warn (stops and turns to the camera), cheer (hops), plant_flag (finish).

## Top speed (m/s) he catches up with his lead spot; faster than the army so he is never run over for long.
const CATCH_UP_SPEED := 14.0
const LEAD_CHANGE_SPEED := 4.0
const X_FOLLOW := 6.0

## Meters ahead of the army (negative = behind it). The director switches it for the boss fight.
var lead: float = TutorialDB.GUIDE_LEAD
## True after plant_flag: he stays where he is.
var frozen: bool = false

var _lead_now: float = TutorialDB.GUIDE_LEAD
var _warn_t: float = 0.0
var _t: float = 0.0
var _prev_z: float = 0.0
var _anim: AnimationPlayer = null
var _hop: Tween = null

@onready var _body: Node3D = $Body
@onready var _slot: Node3D = $Body/ModelSlot


func _ready() -> void:
	var packed := Models.find(TutorialDB.GUIDE_MODEL)
	if packed != null:
		_slot.add_child(packed.instantiate())
		_anim = Models.find_anim_player(_slot)
	else:
		_build_placeholder()
	snap()


## Puts him at his lead spot at once (battle start).
func snap() -> void:
	var army := Game.army
	if army == null:
		return
	_lead_now = lead
	position = Vector3(army.position.x, 0.0, army.position.z - _lead_now)
	_prev_z = position.z


func _process(delta: float) -> void:
	_t += delta
	var army := Game.army
	var moving := false
	if army != null and not frozen:
		if _warn_t > 0.0:
			_warn_t -= delta
			if _warn_t <= 0.0:
				_body.rotation.y = 0.0
		else:
			_lead_now = move_toward(_lead_now, lead, LEAD_CHANGE_SPEED * delta)
			position.x = lerpf(position.x, army.position.x, 1.0 - exp(-X_FOLLOW * delta))
			position.z = move_toward(position.z, army.position.z - _lead_now, CATCH_UP_SPEED * delta)
		moving = absf(position.z - _prev_z) > 0.002
	_prev_z = position.z
	# walking bob and flag sway; the hop of cheer() is on Body, so the two never fight
	var bob := absf(sin(_t * 9.0)) * 0.12 if moving else 0.0
	_slot.position.y = lerpf(_slot.position.y, bob, 1.0 - exp(-20.0 * delta))
	_slot.rotation.z = sin(_t * 2.2) * 0.04
	if _anim != null:
		if not Models.play(_anim, "run" if moving else "idle"):
			Models.play(_anim, "walk" if moving else "idle")


## Stops and faces the camera for `seconds` (before the red gate, the spikes, the boss).
func warn(seconds: float = 1.2) -> void:
	if frozen:
		return
	_warn_t = seconds
	_body.rotation.y = PI


## Two quick hops.
func cheer() -> void:
	if _hop != null:
		_hop.kill()
	_hop = create_tween()
	for i in 2:
		_hop.tween_property(_body, "position:y", 0.6, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hop.tween_property(_body, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Finish: he stops, plants a flag at `pos` (in `parent`), steps beside it and cheers.
func plant_flag(parent: Node3D, pos: Vector3) -> void:
	if frozen:
		return
	frozen = true
	_warn_t = 0.0
	_body.rotation.y = PI
	var flag := Node3D.new()
	flag.name = "PlantedFlag"
	flag.position = pos
	parent.add_child(flag)
	var packed := Models.find(TutorialDB.FLAG_MODEL)
	if packed != null:
		flag.add_child(packed.instantiate())
	else:
		_build_flag(flag)
	flag.scale = Vector3.ZERO
	var tw := create_tween()
	tw.tween_property(flag, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "position", pos + Vector3(-1.8, 0.0, 0.8), 0.5)
	tw.tween_callback(cheer)


func _build_placeholder() -> void:
	var skin := Mats.solid(Color(0.95, 0.78, 0.6))
	var uniform := Mats.solid(Color(0.30, 0.42, 0.28))
	var helmet := Mats.solid(Color(0.36, 0.46, 0.30))
	Mats.part(_slot, Mats.capsule(0.32, 1.1), uniform, Vector3(0.0, 0.75, 0.0))
	Mats.part(_slot, Mats.sphere(0.26), skin, Vector3(0.0, 1.55, 0.0))
	Mats.part(_slot, Mats.cylinder(0.28, 0.3, 0.18), helmet, Vector3(0.0, 1.78, 0.0))
	_build_flag(_slot, Vector3(0.5, 0.0, 0.0), 1.0)


## Pole + cloth + base (the cloth flies toward -X of its parent).
func _build_flag(parent: Node3D, at: Vector3 = Vector3.ZERO, scale_mul: float = 1.4) -> void:
	var wood := Mats.solid(Color(0.50, 0.35, 0.20))
	var cloth := Mats.solid(Color(0.20, 0.50, 0.95))
	var root := Node3D.new()
	root.position = at
	root.scale = Vector3.ONE * scale_mul
	parent.add_child(root)
	Mats.part(root, Mats.cylinder(0.04, 0.04, 2.8), wood, Vector3(0.0, 1.4, 0.0))
	Mats.part(root, Mats.box(Vector3(0.9, 0.55, 0.04)), cloth, Vector3(-0.45, 2.45, 0.0))
	Mats.part(root, Mats.cylinder(0.25, 0.3, 0.12), wood, Vector3(0.0, 0.06, 0.0))
