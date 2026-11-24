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
## Projectile look in ProjectilePool (index into its KIND_ tables).
var proj_kind: int = 0
## "nearest" | "strongest" (highest max hp first) | "cluster" (biggest crowd first, for mortars).
var prefer: StringName = &"nearest"
## Share of incoming damage that is ignored (Shield Knight).
var armor: float = 0.0
## Enemies within this distance attack this soldier first (Shield Knight). 0 = no taunt.
var taunt_radius: float = 0.0
## Melee soldiers only hit enemies in `attack_range`; `cleave` also hits enemies that close to the target.
var melee: bool = false
var cleave: float = 0.0
## Lobbed shell (Mortar): lands `lob_flight` seconds after the shot.
var lob: bool = false
var lob_flight: float = 0.9
## Auras, refreshed every AURA_INTERVAL. Drummer: allies get +damage / +fire rate.
## Weakener: enemies deal less damage. Blinder: enemies may miss. All stay in `aura_range`.
var buff_dmg: float = 0.0
var buff_rate: float = 0.0
var weaken_frac: float = 0.0
var blind_chance: float = 0.0
var aura_range: float = 0.0

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
## Enemy debuffs (Blinder / Weakener). Seconds left; 0 = not affected.
var _blind_t: float = 0.0
var _weak_t: float = 0.0
## Drummer buff received from an ally. Seconds left; 0 = not affected.
var _drum_t: float = 0.0
var _drum_dmg: float = 0.0
var _drum_rate: float = 0.0
var _aura_t: float = 0.0
var _beat_t: float = 0.0

## While blinded a soldier's shots scatter this much (radians). While weakened it deals this fraction of its damage.
const BLIND_SPREAD := 0.5
const WEAK_DAMAGE_MULT := 0.6
## Aura soldiers (Drummer / Weakener / Blinder) refresh their effect this often; an effect lasts AURA_SECONDS.
const AURA_INTERVAL := 0.5
const AURA_SECONDS := 1.2
## Pulse ring + sound at most this often per aura soldier.
const BEAT_INTERVAL := 1.2
## A blinded mortar's shell lands up to this far from its aim point.
const BLIND_LOB_SCATTER := 4.0


func setup(p_level: int = 1) -> void:
	level = p_level
	uid = _next_uid
	_next_uid += 1
	var d := SoldierDB.stats(type, level)
	_data = d
	display_name = d["name"]
	rank_id = d["rank"]
	# Army-wide upgrades (Upgrades tab) stack on top of this class's own level (Soldiers tab).
	max_hp = float(d["health"]) * PlayerData.health_mult()
	hp = max_hp
	base_damage = float(d["damage"]) * PlayerData.damage_mult()
	attack_speed = float(d["attack_speed"]) * PlayerData.rate_mult()
	follow_rate = d["follow_rate"]
	attack_range = d["range"]
	bullet_speed = d["bullet_speed"]
	pierce = d["pierce"]
	aoe = d["aoe"]
	spread = d["spread"]
	heal_amount = float(d["heal"]) * PlayerData.health_mult()
	heal_interval = d["heal_interval"]
	heal_range = d["heal_range"]
	sfx = d["sfx"]
	row_priority = d["row"]
	proj_kind = int(d.get("proj", int(type)))
	prefer = d.get("prefer", &"nearest")
	armor = float(d.get("armor", 0.0))
	taunt_radius = float(d.get("taunt", 0.0))
	melee = bool(d.get("melee", false))
	cleave = float(d.get("cleave", 0.0))
	lob = bool(d.get("lob", false))
	lob_flight = float(d.get("flight", 0.9))
	radius = float(d.get("radius", 0.35))
	buff_dmg = float(d.get("buff_dmg", 0.0))
	buff_rate = float(d.get("buff_rate", 0.0))
	weaken_frac = float(d.get("weaken", 0.0))
	blind_chance = float(d.get("blind", 0.0))
	aura_range = float(d.get("aura_range", 0.0))


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
		_blind_t = maxf(_blind_t - delta, 0.0)
		_weak_t = maxf(_weak_t - delta, 0.0)
		_drum_t = maxf(_drum_t - delta, 0.0)
		if aura_range > 0.0:
			_aura_t -= delta
			if _aura_t <= 0.0:
				_aura_t = AURA_INTERVAL
				_aura_pulse()
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
		var reach2 := r2
		if melee:
			var reach := attack_range + e.radius
			reach2 = reach * reach
		if d2 > reach2:
			continue
		var score := -d2
		if prefer == &"strongest":
			score = e.max_hp * 1000.0 - d2
		elif prefer == &"cluster":
			score = float(_cluster_size(e)) * 1000.0 - d2
		if score > best_score:
			best_score = score
			best = e
	target = best


## Enemies (itself included) inside one blast radius around `center`.
func _cluster_size(center: Enemy) -> int:
	var r2 := aoe * aoe
	var n := 0
	for o in Game.enemies:
		var dx := o.position.x - center.position.x
		var dz := o.position.z - center.position.z
		if dx * dx + dz * dz <= r2:
			n += 1
	return n


func _shoot() -> void:
	_cooldown = 1.0 / (attack_speed * Game.rate_buff * _drum_rate_mult())
	var dmg := base_damage * Game.damage_buff * _drum_dmg_mult() * (WEAK_DAMAGE_MULT if _weak_t > 0.0 else 1.0)
	var from := _muzzle.global_position
	var to := target.position
	if melee:
		_melee_hit(dmg)
		return
	if lob:
		_lob_shell(from, to, dmg)
		return
	var dir := to - from
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3(0, 0, -1)
	var scatter := spread + (BLIND_SPREAD if _blind_t > 0.0 else 0.0)
	dir = dir.normalized().rotated(Vector3.UP, randf_range(-scatter, scatter))
	var travel := attack_range + 4.0
	if aoe > 0.0:
		travel = maxf(from.distance_to(to) - 0.5, 1.0)
	Game.player_bullets.fire(from, dir, bullet_speed, dmg, travel, pierce, aoe, proj_kind)
	_muzzle_flash.visible = true
	_muzzle_t = 0.05
	_recoil = 1.0
	if _anim != null:
		Models.play(_anim, "shoot")
	AudioManager.play(sfx)


## Shield Knight: a direct hit on the target, plus a weaker hit on enemies close to it (cleave).
func _melee_hit(dmg: float) -> void:
	var victim := target
	var at := Vector3(victim.position.x, 0.9, victim.position.z)
	victim.take_damage(dmg, at)
	if cleave > 0.0:
		var r2 := cleave * cleave
		for e: Enemy in Game.enemies.duplicate():
			if e == victim or e.dead:
				continue
			var dx := e.position.x - at.x
			var dz := e.position.z - at.z
			if dx * dx + dz * dz <= r2:
				e.take_damage(dmg * 0.6, Vector3(e.position.x, 0.9, e.position.z))
	_recoil = 1.0
	if _anim != null:
		Models.play(_anim, "attack")
	AudioManager.play(sfx, 0.8)


## Mortar: aims a little ahead of the target (enemies walk toward the army), then lobs a shell.
func _lob_shell(from: Vector3, to: Vector3, dmg: float) -> void:
	var spot := to
	var back := position - to
	back.y = 0.0
	if back.length_squared() > 0.01:
		spot += back.normalized() * minf(target.speed * lob_flight, back.length())
	if _blind_t > 0.0:
		spot += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * BLIND_LOB_SCATTER
	LobShell.fire(get_parent() as Node3D, from, spot, lob_flight, aoe, dmg)
	_muzzle_flash.visible = true
	_muzzle_t = 0.08
	_recoil = 1.0
	AudioManager.play(sfx, 0.7)


func _drum_dmg_mult() -> float:
	return 1.0 + _drum_dmg if _drum_t > 0.0 else 1.0


func _drum_rate_mult() -> float:
	return 1.0 + _drum_rate if _drum_t > 0.0 else 1.0


## Drummer / Weakener / Blinder: refreshes the effect on everyone in `aura_range`.
func _aura_pulse() -> void:
	var r2 := aura_range * aura_range
	var touched := 0
	if buff_dmg > 0.0 or buff_rate > 0.0:
		for s in Game.soldiers:
			if s == self:
				continue
			var dx := s.position.x - position.x
			var dz := s.position.z - position.z
			if dx * dx + dz * dz <= r2:
				s.apply_drum(buff_dmg, buff_rate, AURA_SECONDS)
				touched += 1
	if weaken_frac > 0.0 or blind_chance > 0.0:
		for e in Game.enemies:
			var ex := e.position.x - position.x
			var ez := e.position.z - position.z
			if ex * ex + ez * ez <= r2:
				if weaken_frac > 0.0:
					e.apply_weaken(weaken_frac, AURA_SECONDS)
				if blind_chance > 0.0:
					e.apply_blind(blind_chance, AURA_SECONDS)
				touched += 1
	_beat_t -= AURA_INTERVAL
	if touched > 0 and _beat_t <= 0.0:
		_beat_t = BEAT_INTERVAL
		if buff_dmg > 0.0 or buff_rate > 0.0:
			Game.fx.pulse(position, aura_range, Color(1.0, 0.85, 0.3, 0.45))
			AudioManager.play("hit", 0.5)
		elif weaken_frac > 0.0:
			Game.fx.pulse(position, aura_range, Color(0.7, 0.4, 1.0, 0.4))
			AudioManager.play("heal", 0.6)
		else:
			Game.fx.pulse(position, aura_range, Color(1.0, 0.95, 0.6, 0.45))
			AudioManager.play("shoot_sniper", 1.6)


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


## Blinder hit: shots scatter for `seconds`. A longer running effect is never shortened.
func apply_blind(seconds: float) -> void:
	if not dead:
		_blind_t = maxf(_blind_t, seconds)


## Weakener hit: damage is reduced for `seconds`. A longer running effect is never shortened.
func apply_weaken(seconds: float) -> void:
	if not dead:
		_weak_t = maxf(_weak_t, seconds)


## Drummer aura: +damage / +fire rate for `seconds`. Several drummers do not stack; the best value wins.
func apply_drum(dmg: float, rate: float, seconds: float) -> void:
	if dead:
		return
	if _drum_t <= 0.0:
		_drum_dmg = dmg
		_drum_rate = rate
	else:
		_drum_dmg = maxf(_drum_dmg, dmg)
		_drum_rate = maxf(_drum_rate, rate)
	_drum_t = maxf(_drum_t, seconds)


func is_blinded() -> bool:
	return _blind_t > 0.0


func is_weakened() -> bool:
	return _weak_t > 0.0


func heal(amount: float) -> void:
	if dead:
		return
	hp = minf(hp + amount, max_hp)


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount * (1.0 - armor)
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
