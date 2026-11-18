class_name Army
extends Node3D
## The army anchor: handles drag / keyboard steering, auto-advance, the
## formation layout and soldier add / remove. Soldiers are NOT children of
## this node; each one chases `position + slot` so the crowd sways naturally.

const FIELD_HALF := 7.0
const SPACING_X := 0.78
const SPACING_Z := 0.85
const SLOW_FAR := 22.0
const SLOW_NEAR := 8.0
const MIN_SPEED := 0.25
const SOLDIER_SCENE := preload("res://Scene/Units/Soldier.tscn")
## Strafe "crowd" effect: sideways speed (units/s) that gives the full squeeze.
const SQUEEZE_SPEED := 6.0

var units: Node3D = null
var forward_speed: float = 6.0
var drag_sensitivity: float = 0.026
var keyboard_speed: float = 10.0
var follow_rate: float = 12.0
## Army cannot advance past this z (boss arena wall).
var min_z: float = -100000.0
var target_x: float = 0.0
var half_width: float = 2.0
var engage_factor: float = 1.0
## 0..1, how hard the army is strafing right now (smoothed).
var squeeze: float = 0.0
## Minimum formation width factor at full squeeze (formation gets narrower).
var squeeze_min_x: float = 0.5
## Formation gets a bit longer while squeezed.
var z_scale: float = 1.0
## -1..1 signed sideways lean (soldiers tilt into the movement).
var lean: float = 0.0

var _lateral: float = 0.0

var _engage_t: float = 0.0
var _emit_t: float = 0.0


func max_offset() -> float:
	return maxf(FIELD_HALF - half_width, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if Game.state != Game.State.PLAYING:
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		target_x += event.relative.x * drag_sensitivity


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		_update_squeeze(0.0, delta)
		return
	var key := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		key -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		key += 1.0
	target_x += key * keyboard_speed * delta
	target_x = clampf(target_x, -max_offset(), max_offset())

	_engage_t -= delta
	if _engage_t <= 0.0:
		_engage_t = 0.1
		_update_engage()

	position.z = maxf(position.z - forward_speed * engage_factor * delta, min_z)
	var old_x := position.x
	position.x = lerpf(position.x, target_x, 1.0 - exp(-follow_rate * delta))
	_update_squeeze((position.x - old_x) / maxf(delta, 0.0001), delta)

	_emit_t -= delta
	if _emit_t <= 0.0:
		_emit_t = 0.12
		emit_status()


## Fast sideways movement squeezes the formation narrower and tilts the
## soldiers, so a strafing army reads as a moving crowd, not a rigid block.
func _update_squeeze(vx: float, delta: float) -> void:
	_lateral = lerpf(_lateral, vx, 1.0 - exp(-14.0 * delta))
	var want := clampf(absf(_lateral) / SQUEEZE_SPEED, 0.0, 1.0)
	squeeze = move_toward(squeeze, want, (9.0 if want > squeeze else 2.5) * delta)
	lean = clampf(_lateral / 10.0, -1.0, 1.0)
	z_scale = lerpf(1.0, 1.3, squeeze)


## Slow the advance while enemies are close ahead so fights last a bit.
func _update_engage() -> void:
	var nearest := 999.0
	for e in Game.enemies:
		var dz := position.z - e.position.z
		if dz > -3.0 and dz < nearest:
			nearest = dz
	var k := clampf((nearest - SLOW_NEAR) / (SLOW_FAR - SLOW_NEAR), 0.0, 1.0)
	engage_factor = lerpf(MIN_SPEED, 1.0, k)


func emit_status() -> void:
	var hp := 0.0
	var mx := 0.0
	for s in Game.soldiers:
		hp += s.hp
		mx += s.max_hp
	Game.army_changed.emit(Game.soldiers.size(), hp, mx)


func add_soldier(type: int, level: int = 1, pop: bool = false) -> Soldier:
	if Game.soldiers.size() >= Game.MAX_SOLDIERS:
		return null
	var s := SOLDIER_SCENE.instantiate() as Soldier
	s.setup(type, level)
	s.position = position + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(0.0, 2.0))
	units.add_child(s)
	Game.soldiers.append(s)
	if pop:
		AudioManager.play("soldier_spawn")
	return s


func add_random_soldiers(count: int) -> void:
	for i in count:
		add_soldier(SoldierDB.random_type(), 1, i == 0)
	rebuild_formation()
	emit_status()


func multiply_soldiers(factor: float) -> void:
	var current: Array = Game.soldiers.duplicate()
	var extra := mini(int(round(current.size() * (factor - 1.0))), Game.MAX_SOLDIERS - current.size())
	for i in extra:
		var src: Soldier = current[i % current.size()]
		add_soldier(src.type, src.level, i == 0)
	rebuild_formation()
	emit_status()


## Remove soldiers from the back of the formation (negative gate).
func remove_soldiers(count: int) -> void:
	var list: Array = Game.soldiers.duplicate()
	list.sort_custom(func(a: Soldier, b: Soldier) -> bool: return a.slot.z > b.slot.z)
	for i in mini(count, list.size()):
		var s: Soldier = list[i]
		s.take_damage(99999.0)


func on_soldier_died() -> void:
	rebuild_formation()
	emit_status()
	if Game.soldiers.is_empty():
		Game.end_battle(false)


## Row based formation: tough / close-range soldiers in front, snipers,
## medics and launchers behind. Rows are centered and re-packed on every
## change so the army always stays compact.
func rebuild_formation() -> void:
	var list: Array = Game.soldiers.duplicate()
	var n := list.size()
	if n == 0:
		return
	list.sort_custom(func(a: Soldier, b: Soldier) -> bool:
		if a.row_priority != b.row_priority:
			return a.row_priority < b.row_priority
		return a.uid < b.uid)
	var cols := clampi(int(ceil(sqrt(n * 1.5))), 3, 7)
	var rows := int(ceil(float(n) / cols))
	for i in n:
		var s: Soldier = list[i]
		var row := i / cols
		var col := i % cols
		var in_row := mini(cols, n - row * cols)
		s.slot = Vector3(
			(col - (in_row - 1) * 0.5) * SPACING_X,
			0.0,
			(row - (rows - 1) * 0.5) * SPACING_Z)
	half_width = (cols - 1) * SPACING_X * 0.5 + 0.55
