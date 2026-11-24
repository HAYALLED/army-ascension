class_name MortarEnemy
extends Enemy
## Artillery: stays far away and lobs a shell at a soldier. A glowing circle marks the landing
## spot and fills up; when it is full the shell explodes for area damage. Strafe out of the circle.

const BLAST_RADIUS := 2.3
const SHELL_DELAY := 1.2


func _attack(_face: Vector3) -> void:
	_atk_t = attack_cd * randf_range(0.9, 1.1)
	if not is_instance_valid(target):
		return
	AudioManager.play("shoot_enemy")
	var spot := target.position
	if miss_roll():
		# Blinded: the shell lands well outside the blast radius.
		spot += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized() * randf_range(BLAST_RADIUS * 2.0, BLAST_RADIUS * 3.0)
	lob_shell(get_parent(), spot, BLAST_RADIUS, damage * dmg_mult(), SHELL_DELAY)


## Marks `pos`, then after `delay` seconds damages every soldier within `blast_radius`.
## Independent of the caster: the shell still lands if the mortar dies meanwhile.
static func lob_shell(parent: Node3D, pos: Vector3, blast_radius: float, dmg: float, delay: float) -> void:
	var spot := Vector3(pos.x, 0.0, pos.z)
	var ring := MeshInstance3D.new()
	ring.mesh = Mats.cylinder(1.0, 1.0, 0.04, 28)
	ring.material_override = Mats.unshaded(Color(1.0, 0.45, 0.1, 0.4))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.position = spot + Vector3(0.0, 0.1, 0.0)
	ring.scale = Vector3(0.1, 1.0, 0.1)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3(blast_radius, 1.0, blast_radius), delay)
	tw.tween_callback(MortarEnemy.detonate.bind(spot, blast_radius, dmg))
	tw.tween_callback(ring.queue_free)


static func detonate(spot: Vector3, blast_radius: float, dmg: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	for s: Soldier in Game.soldiers.duplicate():
		var dx := s.position.x - spot.x
		var dz := s.position.z - spot.z
		var r := blast_radius + s.radius
		if dx * dx + dz * dz <= r * r:
			s.take_damage(dmg)
	if is_instance_valid(Game.fx):
		Game.fx.explosion(spot, blast_radius)
	AudioManager.play("explosion", 0.9)
	if is_instance_valid(Game.camera_rig):
		Game.camera_rig.shake(0.1)
