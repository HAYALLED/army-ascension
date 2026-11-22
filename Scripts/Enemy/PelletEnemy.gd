class_name PelletEnemy
extends Enemy
## Ranged enemy that fires a burst of pellets from its Muzzle: Shotgunner = 5 pellets in a fan,
## Breacher = one heavy slug. Walks until it is in range (Enemy._think), then shoots.

## kind -> [pellet count, fan half angle in radians].
const PATTERNS := {
	EnemyDB.Kind.SHOTGUNNER: [5, 0.36],
	EnemyDB.Kind.BREACHER: [1, 0.0],
}


func _attack(face: Vector3) -> void:
	_atk_t = attack_cd * randf_range(0.9, 1.1)
	var pattern: Array = PATTERNS.get(kind, [1, 0.0])
	var count := int(pattern[0])
	var arc := float(pattern[1])
	var from := _gun_origin(position + Vector3(0, 1.0, 0) + face * 0.6)
	var dir := face
	if is_instance_valid(target):
		dir = target.position - from
		dir.y = 0.0
		dir = dir.normalized()
	for i in count:
		var t := 0.5 if count < 2 else float(i) / float(count - 1)
		var ang := lerpf(-arc, arc, t)
		Game.enemy_bullets.fire(from, dir.rotated(Vector3.UP, ang), proj_speed, damage, attack_range + 3.0, 0, 0.0, proj_kind)
	AudioManager.play("shoot_enemy", 0.8)
