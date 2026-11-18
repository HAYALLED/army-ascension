class_name Boss
extends Enemy
## Iron Colossus. Sleeps until the army gets close, then cycles three
## attack patterns: FAN (projectile spread), SLAM (telegraphed ground
## smash, dodge by strafing) and SUMMON (calls reinforcements).
## Below 50% health it enrages: faster patterns, bigger fans, more summons.

enum Pattern { FAN, SLAM, SUMMON }
enum Phase { SLEEP, WALK, WINDUP, RECOVER }

const SEQUENCE := [Pattern.FAN, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM, Pattern.FAN, Pattern.SLAM]
const WAKE_DISTANCE := 55.0
const HOLD_DISTANCE := 13.0
const SLAM_RADIUS := 3.3
const SLAM_DAMAGE := 45.0
const SLAM_TIME := 1.4

var _state: int = Phase.SLEEP
var _pattern: int = Pattern.FAN
var _timer: float = 0.0
var _seq_i: int = 0
var _volleys: int = 0
var _slam_pos: Vector3 = Vector3.ZERO
var _slam_total: float = SLAM_TIME
var _tele: MeshInstance3D = null
var _tele_fill: MeshInstance3D = null
var _enraged: bool = false


func _init() -> void:
	kind = EnemyDB.Kind.BOSS


func _exit_tree() -> void:
	super._exit_tree()
	if is_instance_valid(_tele):
		_tele.queue_free()
	if is_instance_valid(_tele_fill):
		_tele_fill.queue_free()


func _think(delta: float) -> void:
	var army := Game.army
	if army == null:
		return
	var to := army.position - position
	to.y = 0.0
	var dist := to.length()
	var face := to / dist if dist > 0.01 else Vector3(0, 0, 1)
	match _state:
		Phase.SLEEP:
			if dist < WAKE_DISTANCE:
				_wake()
			return
		Phase.WALK:
			if dist > HOLD_DISTANCE:
				position += face * speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_start_pattern(army)
		Phase.WINDUP:
			_timer -= delta
			_update_windup(delta, face)
		Phase.RECOVER:
			if dist > HOLD_DISTANCE:
				position += face * speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = Phase.WALK
				_timer = 0.2
	_animate(delta, face, _state == Phase.WALK and dist > HOLD_DISTANCE)


func _wake() -> void:
	_state = Phase.WALK
	_timer = 1.5
	Game.boss_spawned.emit(enemy_name, max_hp)
	Game.banner_requested.emit("BOSS!", Color(1.0, 0.25, 0.2))
	AudioManager.play("boss_roar")
	Game.camera_rig.shake(0.35)


func _start_pattern(army: Army) -> void:
	_pattern = SEQUENCE[_seq_i % SEQUENCE.size()]
	_seq_i += 1
	_state = Phase.WINDUP
	_set_overlay(Mats.warn())
	if _anim != null:
		Models.play(_anim, ["shoot", "slam", "roar"][_pattern])
	match _pattern:
		Pattern.FAN:
			_timer = 0.7
			_volleys = 2
		Pattern.SLAM:
			_slam_total = SLAM_TIME * (0.75 if _enraged else 1.0)
			_timer = _slam_total
			_slam_pos = Vector3(army.position.x, 0.0, army.position.z)
			_show_telegraph()
		Pattern.SUMMON:
			_timer = 0.9
			AudioManager.play("boss_roar", 1.3)


func _update_windup(_delta: float, face: Vector3) -> void:
	match _pattern:
		Pattern.FAN:
			if _timer <= 0.0:
				_fire_fan(face)
				_volleys -= 1
				if _volleys > 0:
					_timer = 0.35
				else:
					_finish_pattern()
		Pattern.SLAM:
			var k := clampf(1.0 - _timer / _slam_total, 0.0, 1.0)
			if is_instance_valid(_tele_fill):
				var s := maxf(SLAM_RADIUS * k, 0.01)
				_tele_fill.scale = Vector3(s, 1.0, s)
			if _timer <= 0.0:
				_do_slam()
				_finish_pattern()
		Pattern.SUMMON:
			if _timer <= 0.0:
				_do_summon()
				_finish_pattern()


func _finish_pattern() -> void:
	_set_overlay(null)
	_hide_telegraph()
	_state = Phase.RECOVER
	_timer = 1.4 if _enraged else 2.2


func _fire_fan(face: Vector3) -> void:
	var army := Game.army
	var from := position + Vector3(0, 2.5, 0) + face * 2.0
	var dir := army.position - from
	dir.y = 0.0
	dir = dir.normalized()
	var shots := 13 if _enraged else 9
	for i in shots:
		var ang := lerpf(-0.66, 0.66, float(i) / float(shots - 1))
		Game.enemy_bullets.fire(from, dir.rotated(Vector3.UP, ang), 15.0, 8.0 * Game.difficulty_scale(), 45.0, 0, 0.0, ProjectilePool.KIND_BOSS, 0.3)
	AudioManager.play("boss_shoot")
	Game.camera_rig.shake(0.12)


func _do_slam() -> void:
	for s: Soldier in Game.soldiers.duplicate():
		var dx := s.position.x - _slam_pos.x
		var dz := s.position.z - _slam_pos.z
		var r := SLAM_RADIUS + s.radius
		if dx * dx + dz * dz <= r * r:
			s.take_damage(SLAM_DAMAGE * Game.difficulty_scale())
	Game.fx.explosion(_slam_pos, SLAM_RADIUS)
	AudioManager.play("slam")
	Game.camera_rig.shake(0.5)


func _do_summon() -> void:
	var count := 6 if _enraged else 4
	for i in count:
		var ang := TAU * float(i) / float(count) + randf() * 0.4
		var pos := position + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(3.0, 5.0)
		pos.x = clampf(pos.x, -6.0, 6.0)
		Enemy.spawn(get_parent(), EnemyDB.Kind.FAST if i % 3 == 2 else EnemyDB.Kind.BASIC, pos)
	Game.camera_rig.shake(0.2)


func _show_telegraph() -> void:
	if _tele == null:
		_tele = MeshInstance3D.new()
		_tele.mesh = Mats.cylinder(1.0, 1.0, 0.04, 32)
		_tele.material_override = Mats.unshaded(Color(1.0, 0.1, 0.1, 0.28))
		_tele.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(_tele)
		_tele_fill = MeshInstance3D.new()
		_tele_fill.mesh = Mats.cylinder(1.0, 1.0, 0.05, 32)
		_tele_fill.material_override = Mats.unshaded(Color(1.0, 0.15, 0.1, 0.5))
		_tele_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(_tele_fill)
	_tele.position = _slam_pos + Vector3(0, 0.1, 0)
	_tele.scale = Vector3(SLAM_RADIUS, 1.0, SLAM_RADIUS)
	_tele.visible = true
	_tele_fill.position = _slam_pos + Vector3(0, 0.11, 0)
	_tele_fill.scale = Vector3(0.01, 1.0, 0.01)
	_tele_fill.visible = true


func _hide_telegraph() -> void:
	if is_instance_valid(_tele):
		_tele.visible = false
	if is_instance_valid(_tele_fill):
		_tele_fill.visible = false


func _on_damaged() -> void:
	Game.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
	if not _enraged and hp < max_hp * 0.5 and hp > 0.0:
		_enraged = true
		speed *= 1.3
		Game.banner_requested.emit("ENRAGED!", Color(1.0, 0.4, 0.1))
		AudioManager.play("boss_roar", 1.15)
		Game.camera_rig.shake(0.3)


func _die() -> void:
	if dead:
		return
	dead = true
	Game.enemies.erase(self)
	_hide_telegraph()
	_set_overlay(null)
	_grant_rewards()
	Game.boss_defeated.emit()
	Game.camera_rig.shake(0.6)
	AudioManager.play("explosion")
	var tw := create_tween()
	for i in 9:
		tw.tween_callback(_death_blast)
		tw.tween_interval(0.2)
	tw.tween_property(_model, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish_death)


func _death_blast() -> void:
	var p := position + Vector3(randf_range(-1.8, 1.8), randf_range(0.5, 4.0), randf_range(-1.5, 1.5))
	Game.fx.explosion(p, 2.2)
	Game.camera_rig.shake(0.25)


func _finish_death() -> void:
	Game.end_battle(true)
	queue_free()
