class_name Enemy
extends Node3D
## Regular enemy (grunt, scout, brute, gunner, warlord). Boss.gd extends this.
## Scene: Scene/Enemy/Enemy.tscn.  Plain Node3D, no physics: chases the
## nearest soldier and attacks.
## Node layout:  Enemy -> Body (yaw / bob / lunge) -> ModelSlot (scale) -> [3D model]

var kind: int = EnemyDB.Kind.BASIC
var enemy_name: String = ""
var dead: bool = false
var hp: float = 1.0
var max_hp: float = 1.0
var damage: float = 5.0
var speed: float = 3.0
var radius: float = 0.45
var attack_range: float = 1.2
var attack_cd: float = 1.0
var armor: float = 0.0
var ranged: bool = false
var gold: int = 1
var shard_amount: int = 0
var shard_chance: float = 0.0
var proj_speed: float = 16.0
var hit_color: Color = Color.RED
var model_scale: float = 1.0
## Separation push written each frame by Battle (see Battle._separate_enemies).
var push: Vector3 = Vector3.ZERO

var target: Soldier = null
var _retarget_t: float = 0.0
var _atk_t: float = 0.0
var _age: float = 0.0
var _phase: float = 0.0
@onready var _body: Node3D = $Body
@onready var _model: Node3D = $Body/ModelSlot   # scale target (model_scale, death squash)

static var _scene: PackedScene = null

var _meshes: Array = []
var _anim: AnimationPlayer = null
var _flash_t: float = 0.0
var _bar: Node3D = null
var _bar_fill: MeshInstance3D = null
var _bar_w: float = 1.0
var _bar_h: float = 2.0
var _dmg_accum: float = 0.0
var _popup_t: float = 0.0
var _lunge: float = 0.0


static func spawn(parent: Node3D, p_kind: int, pos: Vector3) -> Enemy:
	if _scene == null:
		_scene = load("res://Scene/Enemy/Enemy.tscn")
	var e := _scene.instantiate() as Enemy
	e.kind = p_kind
	e.position = pos
	parent.add_child(e)
	return e


func _ready() -> void:
	var d: Dictionary = EnemyDB.DATA[kind]
	var ds := Game.difficulty_scale()
	enemy_name = d["name"]
	max_hp = float(d["health"]) * ds
	hp = max_hp
	damage = float(d["damage"]) * ds
	speed = d["speed"]
	radius = d["radius"]
	attack_range = d["attack_range"]
	attack_cd = d["attack_cd"]
	armor = d["armor"]
	ranged = d["ranged"]
	gold = d["gold"]
	shard_amount = d["shards"]
	shard_chance = d["shard_chance"]
	proj_speed = d["proj_speed"]
	hit_color = d["color"]
	model_scale = d["scale"]
	_phase = randf() * TAU
	var built := Models.unit(d["model"], func() -> Dictionary: return PlaceholderModels.enemy(kind))
	var model: Node3D = built["root"]
	_model.add_child(model)
	_meshes = built["meshes"]
	_anim = built["anim"]
	_bar_h = d["height"]
	_bar_w = clampf(0.4 * _bar_h, 0.7, 1.8)
	if built["external"]:
		model.scale = Vector3.ONE * float(d["model_scale"])
	else:
		# Placeholders are built at unit size and scaled here; real assets
		# are authored at final size (DB "height").
		_model.scale = Vector3.ONE * model_scale
	Game.enemies.append(self)
	_post_ready()


func _post_ready() -> void:
	pass


func _exit_tree() -> void:
	Game.enemies.erase(self)


func _process(delta: float) -> void:
	if dead:
		return
	_age += delta
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_set_overlay(null)
	_popup_t -= delta
	if _dmg_accum > 0.0 and _popup_t <= 0.0:
		Game.fx.popup(position + Vector3(0, _bar_h + 0.2, 0), str(int(round(_dmg_accum))), Color(1.0, 0.95, 0.6), 0.9 + 0.15 * model_scale)
		_dmg_accum = 0.0
		_popup_t = 0.3
	if Game.state != Game.State.PLAYING:
		return
	_think(delta)


func _think(delta: float) -> void:
	_atk_t -= delta
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
		if ranged:
			if dist > attack_range * 0.8:
				move_dir = face
			if dist <= attack_range and _atk_t <= 0.0:
				_attack(face)
		else:
			var reach := attack_range + target.radius
			if dist > reach:
				move_dir = face
			elif _atk_t <= 0.0:
				_attack(face)
	position += (move_dir * speed + push) * delta
	position.y = 0.0
	_animate(delta, face, move_dir.length_squared() > 0.0)


func _animate(delta: float, face: Vector3, moving: bool) -> void:
	if face.length_squared() > 0.0001:
		var want := atan2(-face.x, -face.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, want, 1.0 - exp(-10.0 * delta))
	var bob := 0.0
	if moving and (_anim == null or Models.find_anim(_anim, "walk") == &"" and Models.find_anim(_anim, "run") == &""):
		bob = absf(sin(_age * speed * 2.6 + _phase)) * 0.12 * model_scale
	_lunge = move_toward(_lunge, 0.0, delta * 5.0)
	_body.position = Vector3(0, bob, -_lunge * 0.45)
	if _anim != null:
		if not Models.play(_anim, "walk" if moving else "idle"):
			Models.play(_anim, "run" if moving else "idle")


func _find_target() -> void:
	var best: Soldier = null
	var best_d := INF
	for s in Game.soldiers:
		var dx := s.position.x - position.x
		var dz := s.position.z - position.z
		var d2 := dx * dx + dz * dz
		if d2 < best_d:
			best_d = d2
			best = s
	target = best


func _attack(face: Vector3) -> void:
	_atk_t = attack_cd * randf_range(0.9, 1.1)
	if ranged:
		var from := position + Vector3(0, 1.0, 0) + face * 0.6
		Game.enemy_bullets.fire(from, face, proj_speed, damage, attack_range + 4.0, 0, 0.0, ProjectilePool.KIND_ENEMY)
		AudioManager.play("shoot_enemy")
	else:
		_lunge = 1.0
		if _anim != null:
			Models.play(_anim, "attack")
		target.take_damage(damage)


func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO) -> void:
	if dead:
		return
	var dmg := amount * (1.0 - armor)
	hp -= dmg
	_dmg_accum += dmg
	_flash_t = 0.07
	_set_overlay(Mats.flash())
	var at := hit_pos if hit_pos != Vector3.ZERO else position + Vector3(0, 1.0, 0)
	Game.fx.hit(at, hit_color)
	AudioManager.play("hit")
	_update_bar()
	_on_damaged()
	if hp <= 0.0:
		_die()


func _on_damaged() -> void:
	pass


func _ensure_bar() -> void:
	if _bar != null:
		return
	_bar = Node3D.new()
	_bar.position = Vector3(0, _bar_h + 0.35, 0)
	add_child(_bar)
	var bg := MeshInstance3D.new()
	bg.mesh = Mats.quad(Vector2(1.0, 0.16))
	bg.material_override = Mats.bar(Color(0.05, 0.05, 0.08, 0.85), 0)
	bg.scale = Vector3(_bar_w, 1.0, 1.0)
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.add_child(bg)
	_bar_fill = MeshInstance3D.new()
	_bar_fill.mesh = Mats.quad(Vector2(1.0, 0.1))
	_bar_fill.material_override = Mats.bar(Color(0.9, 0.2, 0.2), 1)
	_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.add_child(_bar_fill)


func _update_bar() -> void:
	if kind == EnemyDB.Kind.BOSS:
		return
	_ensure_bar()
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var w := _bar_w * 0.96
	_bar_fill.scale = Vector3(maxf(w * ratio, 0.001), 1.0, 1.0)
	_bar_fill.position = Vector3(-(w - w * ratio) * 0.5, 0, 0)


func _set_overlay(mat: Material) -> void:
	for m in _meshes:
		m.material_overlay = mat


func _grant_rewards() -> void:
	Game.add_gold(gold)
	Game.add_kill()
	if shard_amount > 0 and randf() < shard_chance:
		Game.add_shards(shard_amount)
		Game.fx.popup(position + Vector3(0, _bar_h + 0.9, 0), "+%d SHARD" % shard_amount, Color(0.5, 0.9, 1.0), 0.9)
	Game.fx.popup(position + Vector3(0, _bar_h * 0.6, 0), "+%d" % gold, Color(1.0, 0.82, 0.2), 0.8)


func _die() -> void:
	if dead:
		return
	dead = true
	Game.enemies.erase(self)
	_grant_rewards()
	Game.fx.death_burst(position + Vector3(0, 0.8 * model_scale, 0), hit_color, model_scale)
	AudioManager.play("enemy_die")
	_set_overlay(null)
	if _bar != null:
		_bar.visible = false
	if _anim != null:
		Models.play(_anim, "die")
	var tw := create_tween()
	tw.tween_property(_model, "scale", _model.scale * Vector3(1.3, 0.05, 1.3), 0.22).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
