class_name Soldier
extends Node3D
## One soldier (scene: Scene/Units/Soldier.tscn). A plain Node3D, no physics:
## targeting and bullets use cheap distance checks so big armies stay light.
##
## Node layout:  Soldier -> Body (yaw / bob / recoil) -> ModelSlot (scale) -> Model (.glb)
## Each class is an inherited scene in Scene/Units/Soldiers/ that instances its
## .glb under ModelSlot. The glb's "Muzzle" node is the bullet spawn point.

static var _next_uid: int = 1

var uid: int = 0
## Set per class in the inherited scene (Scene/Units/Soldiers/*.tscn).
@export var type: SoldierDB.Type = SoldierDB.Type.RIFLEMAN
var display_name: String = ""
var rank_id: StringName = &"common"
var level: int = 1
var max_hp: float = 100.0
var hp: float = 100.0
var base_damage: float = 10.0
var attack_speed: float = 3.0
var follow_rate: float = 10.0
var attack_range: float = 15.0
var bullet_speed: float = 45.0
var pierce: int = 0
var aoe: float = 0.0
var spread: float = 0.02
var heal_amount: float = 0.0
var heal_interval: float = 1.2
var heal_range: float = 6.0
var sfx: String = "shoot_rifle"
var row_priority: int = 1
var dead: bool = false
var slot: Vector3 = Vector3.ZERO
var radius: float = 0.35
var target: Enemy = null

@onready var _body: Node3D = $Body
@onready var _slot: Node3D = $Body/ModelSlot

var _data: Dictionary = {}
var _muzzle: Node3D = null
var _muzzle_flash: MeshInstance3D = null
var _meshes: Array = []
var _anim: AnimationPlayer = null
var _has_run_anim: bool = false
var _cooldown: float = 0.0
var _retarget_t: float = 0.0
var _heal_t: float = 0.0
var _flash_t: float = 0.0
var _muzzle_t: float = 0.0
var _recoil: float = 0.0
var _age: float = 0.0
var _phase: float = 0.0
var _scale_mul: Vector3 = Vector3.ONE
var _jitter: Vector2 = Vector2.ZERO
var _squeeze_var: float = 1.0


func setup(p_level: int = 1) -> void:
	level = p_level
	uid = _next_uid
	_next_uid += 1
	var d := SoldierDB.stats(type, level)
	_data = d
	display_name = d["name"]
	rank_id = d["rank"]
	max_hp = d["health"]
	hp = max_hp
	base_damage = d["damage"]
	attack_speed = d["attack_speed"]
	follow_rate = d["follow_rate"]
	attack_range = d["range"]
	bullet_speed = d["bullet_speed"]
	pierce = d["pierce"]
	aoe = d["aoe"]
	spread = d["spread"]
	heal_amount = d["heal"]
	heal_interval = d["heal_interval"]
	heal_range = d["heal_range"]
	sfx = d["sfx"]
	row_priority = d["row"]


func _ready() -> void:
	_meshes = Models.collect_meshes(_slot)
	_anim = Models.find_anim_player(_slot)
	_has_run_anim = _anim != null and Models.find_anim(_anim, "run") != &""
	_muzzle = _slot.find_child("Muzzle", true, false) as Node3D
	if _muzzle == null:
		_muzzle = Node3D.new()
		_muzzle.position = Vector3(0.2, 0.7, -0.7)
		_body.add_child(_muzzle)
	_muzzle_flash = Mats.part(_muzzle, Mats.sphere(0.12, 8), Mats.unshaded(Color(1.0, 0.9, 0.5)))
	_muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_muzzle_flash.visible = false
	_cooldown = randf() * 0.5
	_heal_t = randf() * heal_interval
	_phase = randf() * TAU
	_jitter = Vector2(randf_range(-0.12, 0.12), randf_range(-0.1, 0.1))
	_squeeze_var = randf_range(0.8, 1.2)
	_scale_mul = Vector3.ONE * 0.1
	var tw := create_tween()
	tw.tween_property(self, "_scale_mul", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var army := Game.army
	var slim := 1.0
	if army != null:
		slim = 1.0 - 0.22 * clampf(army.squeeze * _squeeze_var, 0.0, 1.0)
	_slot.scale = _scale_mul * Vector3(slim, 1.0, 1.0)
	if dead:
		return
	_age += delta
	if army != null:
		# Formation slot, squeezed + stretched while the army strafes (crowd feel).
		var xs := lerpf(1.0, army.squeeze_min_x, clampf(army.squeeze * _squeeze_var, 0.0, 1.0))
		var goal := army.position + Vector3(slot.x * xs + _jitter.x, 0.0, slot.z * army.z_scale + _jitter.y)
		position = position.lerp(goal, 1.0 - exp(-follow_rate * delta))
		rotation.z = lerpf(rotation.z, -army.lean * 0.28, 1.0 - exp(-10.0 * delta))
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_set_overlay(null)
	if _muzzle_t > 0.0:
		_muzzle_t -= delta
		if _muzzle_t <= 0.0:
			_muzzle_flash.visible = false

	var playing := Game.state == Game.State.PLAYING
	var face := Vector3(0, 0, -1)
	if playing:
		_retarget_t -= delta
		if _retarget_t <= 0.0 or not is_instance_valid(target) or target.dead:
			_retarget_t = 0.15 + randf() * 0.1
			_acquire_target()
		if is_instance_valid(target):
			face = target.position - position
			face.y = 0.0
		_cooldown -= delta
		if _cooldown <= 0.0 and is_instance_valid(target) and base_damage > 0.0:
			_shoot()
		if heal_amount > 0.0:
			_heal_t -= delta
			if _heal_t <= 0.0:
				_heal_t = heal_interval
				_heal_pulse()
	if face.length_squared() > 0.0001:
		var want := atan2(-face.x, -face.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, want, 1.0 - exp(-14.0 * delta))
	# Run bob only when the model has no run clip of its own.
	var bob := 0.0
	if playing and not _has_run_anim:
		bob = absf(sin(_age * 9.0 + _phase)) * 0.06
	_recoil = move_toward(_recoil, 0.0, delta * 6.0)
	_body.position = Vector3(0, bob, _recoil * 0.12)
	if _anim != null:
		Models.play(_anim, "run" if playing else "idle")


func _acquire_target() -> void:
	var best: Enemy = null
	var best_score := -INF
	var r2 := attack_range * attack_range
	for e in Game.enemies:
		var dx := e.position.x - position.x
		var dz := e.position.z - position.z
		var d2 := dx * dx + dz * dz
		if d2 > r2:
			continue
		var score := -d2
		if type == SoldierDB.Type.SNIPER:
			score = e.max_hp * 1000.0 - d2
		if score > best_score:
			best_score = score
			best = e
	target = best


func _shoot() -> void:
	_cooldown = 1.0 / (attack_speed * Game.rate_buff)
	var from := _muzzle.global_position
	var to := target.position
	var dir := to - from
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3(0, 0, -1)
	dir = dir.normalized().rotated(Vector3.UP, randf_range(-spread, spread))
	var travel := attack_range + 4.0
	if aoe > 0.0:
		travel = maxf(from.distance_to(to) - 0.5, 1.0)
	Game.player_bullets.fire(from, dir, bullet_speed, base_damage * Game.damage_buff, travel, pierce, aoe, type)
	_muzzle_flash.visible = true
	_muzzle_t = 0.05
	_recoil = 1.0
	if _anim != null:
		Models.play(_anim, "shoot")
	AudioManager.play(sfx)


func _heal_pulse() -> void:
	var r2 := heal_range * heal_range
	var healed := 0
	for s in Game.soldiers:
		if s.hp >= s.max_hp:
			continue
		var dx := s.position.x - position.x
		var dz := s.position.z - position.z
		if dx * dx + dz * dz <= r2:
			s.heal(heal_amount)
			if healed < 5:
				Game.fx.heal_spark(s.position)
			healed += 1
	if healed > 0:
		Game.fx.pulse(position, heal_range)
		AudioManager.play("heal")


func heal(amount: float) -> void:
	if dead:
		return
	hp = minf(hp + amount, max_hp)


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	_flash_t = 0.07
	_set_overlay(Mats.flash())
	if hp <= 0.0:
		_die()


func _set_overlay(mat: Material) -> void:
	for m in _meshes:
		m.material_overlay = mat


func _die() -> void:
	dead = true
	Game.soldiers.erase(self)
	var body: Color = _data["body"]
	Game.fx.death_burst(position + Vector3(0, 0.7, 0), body)
	AudioManager.play("soldier_die")
	_set_overlay(null)
	if _anim != null:
		Models.play(_anim, "die")
	var tw := create_tween()
	tw.tween_property(self, "_scale_mul", Vector3(1.2, 0.05, 1.2), 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
	if Game.army != null:
		Game.army.on_soldier_died()
