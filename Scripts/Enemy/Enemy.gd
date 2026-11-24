class_name Enemy
extends Node3D
## Regular enemy (grunt, scout, brute, gunner, warlord, marksman). Boss, Kamikaze and
## MedicEnemy extend this.
## Scene: Scene/Enemy/Enemy.tscn.  Plain Node3D, no physics: chases the
## nearest soldier and attacks.
## Node layout:  Enemy -> Body (yaw / bob / lunge) -> ModelSlot (scale) -> Model (.glb)
## Each kind is an inherited scene in Scene/Enemy/Types/ that instances its .glb
## under ModelSlot and sets `kind`.

@export var kind: EnemyDB.Kind = EnemyDB.Kind.BASIC
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
var proj_kind: int = ProjectilePool.KIND_ENEMY
var hit_color: Color = Color.RED
var model_scale: float = 1.0
## Separation push written each frame by Battle (see Battle._separate_enemies).
var push: Vector3 = Vector3.ZERO
## Bosses ignore the Weakener / Blinder soldiers.
var debuff_immune: bool = false

var target: Soldier = null
var _retarget_t: float = 0.0
var _atk_t: float = 0.0
var _age: float = 0.0
var _phase: float = 0.0
@onready var _body: Node3D = $Body
@onready var _model: Node3D = $Body/ModelSlot   # scale target (model_scale, death squash)

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
var _gun: Node3D = null
## Soldier debuffs. Seconds left; 0 = not affected (see apply_weaken / apply_blind).
var _weak_t: float = 0.0
var _weak_frac: float = 0.0
var _blind_t: float = 0.0
var _blind_chance: float = 0.0
var _miss_pop_t: float = 0.0


const MINION_MIN := 8
const MINION_MAX := 20
## No reinforcements while this many enemies are already alive (keeps phones smooth).
const MAX_ALIVE := 70
## A blinded enemy's shot is turned this far (radians) away from its target.
const MISS_ANGLE := 0.4


## Boss / mini boss reinforcement wave: min_count..max_count enemies, every kind random.
## Spawns in rows in front of `origin`, spread across the arena. Returns how many spawned.
static func spawn_minions(parent: Node3D, origin: Vector3, min_count: int = MINION_MIN, max_count: int = MINION_MAX) -> int:
	if Game.enemies.size() >= MAX_ALIVE:
		return 0
	var count := randi_range(mini(min_count, max_count), maxi(min_count, max_count))
	for n in count:
		var col := n % 6
		var row := floori(n / 6.0)
		var x := clampf(lerpf(-5.5, 5.5, col / 5.0) + randf_range(-0.5, 0.5), -6.5, 6.5)
		var z := origin.z + 1.5 + row * 1.6 + randf() * 0.6
		spawn(parent, RoundDB.random_minion_kind(Game.level_index), Vector3(x, 0.0, z))
	return count


static func spawn(parent: Node3D, p_kind: int, pos: Vector3) -> Enemy:
	var e := EnemyDB.scene(p_kind).instantiate() as Enemy
	e.kind = p_kind as EnemyDB.Kind
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
	proj_kind = int(d.get("proj_kind", ProjectilePool.KIND_ENEMY))
	hit_color = d["color"]
	_bar_h = d["height"]
	model_scale = _bar_h / 1.5
	_phase = randf() * TAU
	_apply_round_model()
	_meshes = Models.collect_meshes(_model)
	_anim = Models.find_anim_player(_model)
	_bar_w = clampf(0.4 * _bar_h, 0.7, 1.8)
	Game.enemies.append(self)
	_post_ready()


func _post_ready() -> void:
	pass


## Round 2 / 3 levels swap the scene's round 1 model for the kind's _r2 / _r3 variant.
func _apply_round_model() -> void:
	var path := EnemyDB.round_model_path(kind, LevelDB.chapter_of(Game.level_index))
	if path == "":
		return
	var old := _model.get_node_or_null("Model") as Node3D
	var packed := load(path) as PackedScene
	if old == null or packed == null:
		return
	var fresh := packed.instantiate() as Node3D
	fresh.name = "Model"
	fresh.transform = old.transform
	_model.remove_child(old)
	old.queue_free()
	_model.add_child(fresh)


## World position bullets leave from: the model's "Muzzle" node when it has one, else `fallback`.
func _gun_origin(fallback: Vector3) -> Vector3:
	if _gun == null:
		_gun = _model.find_child("Muzzle", true, false) as Node3D
	return _gun.global_position if is_instance_valid(_gun) else fallback


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
	_weak_t = maxf(_weak_t - delta, 0.0)
	_blind_t = maxf(_blind_t - delta, 0.0)
	_miss_pop_t = maxf(_miss_pop_t - delta, 0.0)
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


## Nearest soldier, except that a taunting soldier (Shield Knight) within its taunt radius wins.
func _find_target() -> void:
	var best: Soldier = null
	var best_d := INF
	var taunter: Soldier = null
	var taunt_d := INF
	for s in Game.soldiers:
		var dx := s.position.x - position.x
		var dz := s.position.z - position.z
		var d2 := dx * dx + dz * dz
		if d2 < best_d:
			best_d = d2
			best = s
		if s.taunt_radius > 0.0 and d2 < taunt_d and d2 <= s.taunt_radius * s.taunt_radius:
			taunt_d = d2
			taunter = s
	target = taunter if taunter != null else best


## Weakener aura: this enemy deals `frac` less damage for `seconds`. The strongest running effect wins.
func apply_weaken(frac: float, seconds: float) -> void:
	if dead or debuff_immune:
		return
	if _weak_t <= 0.0:
		_weak_frac = frac
	else:
		_weak_frac = maxf(_weak_frac, frac)
	_weak_t = maxf(_weak_t, seconds)


## Blinder aura: this enemy misses with probability `chance` for `seconds`. The strongest running effect wins.
func apply_blind(chance: float, seconds: float) -> void:
	if dead or debuff_immune:
		return
	if _blind_t <= 0.0:
		_blind_chance = chance
	else:
		_blind_chance = maxf(_blind_chance, chance)
	_blind_t = maxf(_blind_t, seconds)


## 1.0 normally, less while a Weakener soldier is near. Multiply every damage number an enemy deals with it.
func dmg_mult() -> float:
	return (1.0 - _weak_frac) if _weak_t > 0.0 else 1.0


## True when this attack misses because of a Blinder soldier. Shows MISS (at most every 0.6 s).
func miss_roll() -> bool:
	if _blind_t <= 0.0 or randf() >= _blind_chance:
		return false
	if _miss_pop_t <= 0.0:
		_miss_pop_t = 0.6
		Game.fx.popup(position + Vector3(0, _bar_h + 0.4, 0), "MISS", Color(1.0, 0.95, 0.4), 0.8)
	return true


## `dir` turned away from the target when the attack missed (always the same sign per shot).
func miss_dir(dir: Vector3, missed: bool) -> Vector3:
	if not missed:
		return dir
	return dir.rotated(Vector3.UP, MISS_ANGLE * randf_range(1.0, 1.6) * (1.0 if randf() < 0.5 else -1.0))


func _attack(face: Vector3) -> void:
	_atk_t = attack_cd * randf_range(0.9, 1.1)
	var missed := miss_roll()
	var dmg := damage * dmg_mult()
	if ranged:
		var from := position + Vector3(0, 1.0, 0) + face * 0.6
		Game.enemy_bullets.fire(from, miss_dir(face, missed), proj_speed, dmg, attack_range + 4.0, 0, 0.0, proj_kind)
		AudioManager.play("shoot_enemy")
	else:
		_lunge = 1.0
		if _anim != null:
			Models.play(_anim, "attack")
		if not missed:
			target.take_damage(dmg)


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
	if EnemyDB.is_boss_kind(kind):
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
	if shard_amount > 0 and randf() < shard_chance * PlayerData.shard_mult():
		var type := Game.add_shards(shard_amount)
		var who: String = SoldierDB.DATA[type]["name"]
		Game.fx.popup(position + Vector3(0, _bar_h + 0.9, 0), "+%d %s SHARD" % [shard_amount, who.to_upper()], Color(0.5, 0.9, 1.0), 0.9)
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
