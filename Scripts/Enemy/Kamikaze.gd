class_name Kamikaze
extends Enemy
## Runs at the nearest soldier, lights a short fuse when it arrives and explodes for
## area damage. Killed before the fuse ends = no blast (and the normal reward).

const FUSE_TIME := 0.45
const BLAST_RADIUS := 3.0

var _fuse: float = -1.0


func _think(delta: float) -> void:
	_retarget_t -= delta
	if _retarget_t <= 0.0 or not is_instance_valid(target) or target.dead:
		_retarget_t = 0.2 + randf() * 0.1
		_find_target()
	if _fuse >= 0.0:
		_fuse -= delta
		_set_overlay(Mats.warn() if int(_fuse * 14.0) % 2 == 0 else null)
		if _fuse < 0.0:
			_explode()
		return
	var move_dir := Vector3.ZERO
	var face := Vector3.ZERO
	if is_instance_valid(target):
		var to := target.position - position
		to.y = 0.0
		var dist := to.length()
		if dist > 0.001:
			face = to / dist
		if dist > attack_range + target.radius:
			move_dir = face
		else:
			_fuse = FUSE_TIME
	position += (move_dir * speed + push) * delta
	position.y = 0.0
	_animate(delta, face, move_dir.length_squared() > 0.0)


func _explode() -> void:
	dead = true
	Game.enemies.erase(self)
	for s: Soldier in Game.soldiers.duplicate():
		var dx := s.position.x - position.x
		var dz := s.position.z - position.z
		var r := BLAST_RADIUS + s.radius
		if dx * dx + dz * dz <= r * r:
			s.take_damage(damage * dmg_mult())
	Game.fx.explosion(position, BLAST_RADIUS)
	AudioManager.play("explosion")
	Game.camera_rig.shake(0.15)
	queue_free()
