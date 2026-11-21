class_name MedicEnemy
extends Enemy
## Field medic: walks toward the army, stops at HOLD_DISTANCE and keeps healing wounded
## enemies around it (never bosses). Does not attack. Kill it first.

const HEAL_INTERVAL := 2.5
const HEAL_RANGE := 7.0
const HEAL_FRACTION := 0.15
const HOLD_DISTANCE := 12.0

var _heal_t: float = 1.0


func _think(delta: float) -> void:
	_heal_t -= delta
	_retarget_t -= delta
	if _retarget_t <= 0.0 or not is_instance_valid(target) or target.dead:
		_retarget_t = 0.25 + randf() * 0.15
		_find_target()
	var move_dir := Vector3.ZERO
	var face := Vector3.ZERO
	if is_instance_valid(target):
		var to := target.position - position
		to.y = 0.0
		var dist := to.length()
		if dist > 0.001:
			face = to / dist
		if dist > HOLD_DISTANCE:
			move_dir = face
	position += (move_dir * speed + push) * delta
	position.y = 0.0
	if _heal_t <= 0.0:
		_heal_t = HEAL_INTERVAL
		_heal_pulse()
	_animate(delta, face, move_dir.length_squared() > 0.0)


func _heal_pulse() -> void:
	var healed := false
	for e: Enemy in Game.enemies:
		if e == self or e.dead or e is Boss or e.hp >= e.max_hp:
			continue
		var dx := e.position.x - position.x
		var dz := e.position.z - position.z
		if dx * dx + dz * dz > HEAL_RANGE * HEAL_RANGE:
			continue
		e.hp = minf(e.max_hp, e.hp + e.max_hp * HEAL_FRACTION)
		e._update_bar()
		Game.fx.heal_spark(e.position)
		healed = true
	if healed:
		Game.fx.pulse(position, HEAL_RANGE)
		AudioManager.play("heal")
