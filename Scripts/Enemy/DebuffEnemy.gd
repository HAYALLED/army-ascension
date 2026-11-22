class_name DebuffEnemy
extends Enemy
## Support caster (Blinder / Weakener). Walks toward the army, stops at HOLD_DISTANCE and every
## attack_cd seconds curses the soldiers around its target: Blinder = shots scatter (blind),
## Weakener = less damage. Does no damage itself. Kill it first.

const HOLD_DISTANCE := 13.0
const CAST_RADIUS := 4.5
const BLIND_SECONDS := 3.0
const WEAKEN_SECONDS := 5.0

var _cast_t: float = 2.0


func _think(delta: float) -> void:
	_cast_t -= delta
	_retarget_t -= delta
	if _retarget_t <= 0.0 or not is_instance_valid(target) or target.dead:
		_retarget_t = 0.25 + randf() * 0.15
		_find_target()
	var move_dir := Vector3.ZERO
	var face := Vector3.ZERO
	var dist := INF
	if is_instance_valid(target):
		var to := target.position - position
		to.y = 0.0
		dist = to.length()
		if dist > 0.001:
			face = to / dist
		if dist > HOLD_DISTANCE:
			move_dir = face
	position += (move_dir * speed + push) * delta
	position.y = 0.0
	if _cast_t <= 0.0 and dist <= attack_range:
		_cast_t = attack_cd * randf_range(0.9, 1.1)
		_cast()
	_animate(delta, face, move_dir.length_squared() > 0.0)


func _cast() -> void:
	var blind := kind == EnemyDB.Kind.BLINDER
	var hit := 0
	for s: Soldier in Game.soldiers:
		var dx := s.position.x - target.position.x
		var dz := s.position.z - target.position.z
		if dx * dx + dz * dz > CAST_RADIUS * CAST_RADIUS:
			continue
		if blind:
			s.apply_blind(BLIND_SECONDS)
		else:
			s.apply_weaken(WEAKEN_SECONDS)
		hit += 1
	if hit == 0:
		return
	var text := "BLINDED!" if blind else "WEAKENED!"
	var color := Color(1.0, 0.9, 0.3) if blind else Color(0.75, 0.45, 1.0)
	Game.fx.pulse(target.position, CAST_RADIUS)
	Game.fx.popup(target.position + Vector3(0, 2.2, 0), text, color, 1.1)
	AudioManager.play("shoot_enemy", 0.7)
