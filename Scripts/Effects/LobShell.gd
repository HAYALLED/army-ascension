class_name LobShell
extends RefCounted
## Player mortar shell: flies in an arc from the muzzle to a marked spot, then blasts every enemy
## in the radius (ProjectilePool.blast). Visual only until it lands; no per-frame script.

const ARC_HEIGHT := 5.5
const SHELL_COLOR := Color(0.16, 0.17, 0.2)
const RING_COLOR := Color(0.4, 0.9, 1.0, 0.35)


static func fire(parent: Node3D, from: Vector3, spot: Vector3, flight: float, radius: float, dmg: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var ground := Vector3(spot.x, 0.0, spot.z)
	flight = maxf(flight, 0.1)
	# Landing marker: a cyan ring that grows to the blast radius while the shell is in the air.
	var ring := Mats.part(parent, Mats.cylinder(1.0, 1.0, 0.04, 28), Mats.unshaded(RING_COLOR), ground + Vector3(0.0, 0.1, 0.0))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3(0.1, 1.0, 0.1)
	var shell := Mats.part(parent, Mats.sphere(0.2, 8), Mats.solid(SHELL_COLOR), from)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := shell.create_tween()
	tw.set_parallel(true)
	tw.tween_method(LobShell._step.bind(shell, from, ground), 0.0, 1.0, flight)
	tw.tween_property(ring, "scale", Vector3(radius, 1.0, radius), flight)
	tw.chain().tween_callback(LobShell._land.bind(ground, radius, dmg))
	tw.tween_callback(shell.queue_free)
	tw.tween_callback(ring.queue_free)


static func _step(t: float, shell: Node3D, from: Vector3, ground: Vector3) -> void:
	if not is_instance_valid(shell):
		return
	var p := from.lerp(ground, t)
	p.y = lerpf(from.y, 0.2, t) + sin(t * PI) * ARC_HEIGHT
	shell.position = p


static func _land(ground: Vector3, radius: float, dmg: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	if is_instance_valid(Game.player_bullets):
		Game.player_bullets.blast(ground, radius, dmg)
