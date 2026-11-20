class_name ProjectilePool
extends Node3D
## All bullets of one team in a single pooled system.
## Data lives in packed arrays and is drawn with ONE MultiMesh, so hundreds
## of bullets cost a single draw call and zero node allocations.

const KIND_ENEMY := 5
const KIND_BOSS := 6
const KIND_COLOR := [
	Color(1.0, 0.95, 0.5), Color(1.0, 0.7, 0.25), Color(0.7, 0.95, 1.0),
	Color(1.0, 0.45, 0.15), Color(0.6, 1.0, 0.6), Color(1.0, 0.3, 0.4), Color(0.85, 0.35, 1.0),
]
const KIND_SIZE := [
	Vector3(0.08, 0.08, 0.7), Vector3(0.09, 0.09, 0.55), Vector3(0.1, 0.1, 1.7),
	Vector3(0.28, 0.28, 0.7), Vector3(0.08, 0.08, 0.4), Vector3(0.14, 0.14, 0.5), Vector3(0.32, 0.32, 0.6),
]

@export var capacity: int = 320
## true = player bullets (hit enemies), false = enemy bullets (hit soldiers).
@export var hits_enemies: bool = true

var _count: int = 0
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _life := PackedFloat32Array()
var _dmg := PackedFloat32Array()
var _pierce := PackedInt32Array()
var _aoe := PackedFloat32Array()
var _rad := PackedFloat32Array()
var _kind := PackedInt32Array()
var _ids: Array = []
var _buf: Array = []
var _mm: MultiMesh


func _ready() -> void:
	_pos.resize(capacity)
	_vel.resize(capacity)
	_life.resize(capacity)
	_dmg.resize(capacity)
	_pierce.resize(capacity)
	_aoe.resize(capacity)
	_rad.resize(capacity)
	_kind.resize(capacity)
	_ids.resize(capacity)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = Mats.box(Vector3.ONE)
	_mm.instance_count = capacity
	_mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = _mm
	inst.material_override = Mats.vcolor(false)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.custom_aabb = AABB(Vector3(-200, -10, -800), Vector3(400, 40, 1000))
	add_child(inst)


func fire(origin: Vector3, dir: Vector3, speed: float, damage: float, travel: float, pierce: int = 0, aoe: float = 0.0, kind: int = 0, radius: float = 0.18) -> void:
	if _count >= capacity:
		return
	var i := _count
	_count += 1
	var d := dir
	d.y = 0.0
	d = d.normalized()
	_pos[i] = origin
	_vel[i] = d * speed
	_life[i] = travel / speed
	_dmg[i] = damage
	_pierce[i] = pierce
	_aoe[i] = aoe
	_rad[i] = radius
	_kind[i] = kind
	if pierce > 0:
		_ids[i] = []
	else:
		_ids[i] = null


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	delta = minf(delta, 0.05)
	var i := 0
	while i < _count:
		var p0 := _pos[i]
		var p1 := p0 + _vel[i] * delta
		_life[i] -= delta
		var consumed := false
		if hits_enemies:
			consumed = _hit_enemies(i, p0, p1)
		else:
			consumed = _hit_soldiers(i, p0, p1)
		if not consumed and _life[i] <= 0.0:
			if _aoe[i] > 0.0:
				_explode(p1, _aoe[i], _dmg[i])
			consumed = true
		if consumed:
			_remove(i)
			continue
		_pos[i] = p1
		i += 1
	_draw()


func _draw() -> void:
	for i in _count:
		var v := _vel[i]
		var k := _kind[i]
		var bs := Basis.looking_at(v, Vector3.UP) * Basis.from_scale(KIND_SIZE[k])
		_mm.set_instance_transform(i, Transform3D(bs, _pos[i]))
		_mm.set_instance_color(i, KIND_COLOR[k])
	_mm.visible_instance_count = _count


func _remove(i: int) -> void:
	var last := _count - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_life[i] = _life[last]
		_dmg[i] = _dmg[last]
		_pierce[i] = _pierce[last]
		_aoe[i] = _aoe[last]
		_rad[i] = _rad[last]
		_kind[i] = _kind[last]
		_ids[i] = _ids[last]
	_ids[last] = null
	_count -= 1


func _hit_enemies(i: int, p0: Vector3, p1: Vector3) -> bool:
	var rb := _rad[i]
	var ids = _ids[i]
	var pierce_n := _pierce[i]
	var best: Enemy = null
	var best_d := INF
	_buf.clear()
	for e in Game.enemies:
		var r := e.radius + rb
		if _seg_dist_sq(p0, p1, e.position) <= r * r:
			if ids != null and ids.has(e.get_instance_id()):
				continue
			var dd := p0.distance_squared_to(e.position)
			if pierce_n > 0:
				_buf.append(e)
			elif dd < best_d:
				best_d = dd
				best = e
	if pierce_n > 0:
		if _buf.is_empty():
			return false
		_buf.sort_custom(func(a: Enemy, b: Enemy) -> bool: return p0.distance_squared_to(a.position) < p0.distance_squared_to(b.position))
		for e in _buf:
			if _pierce[i] < 0:
				break
			ids.append(e.get_instance_id())
			_pierce[i] -= 1
			e.take_damage(_dmg[i], Vector3(e.position.x, p1.y, e.position.z))
		return _pierce[i] < 0
	if best == null:
		return false
	if _aoe[i] > 0.0:
		_explode(p1, _aoe[i], _dmg[i])
	else:
		best.take_damage(_dmg[i], Vector3(best.position.x, p1.y, best.position.z))
	return true


func _hit_soldiers(i: int, p0: Vector3, p1: Vector3) -> bool:
	var rb := _rad[i]
	for s in Game.soldiers:
		var r := s.radius + rb
		if _seg_dist_sq(p0, p1, s.position) <= r * r:
			s.take_damage(_dmg[i])
			Game.fx.hit(Vector3(s.position.x, p1.y, s.position.z), KIND_COLOR[_kind[i]])
			return true
	return false


func _explode(pos: Vector3, radius: float, dmg: float) -> void:
	Game.fx.explosion(pos, radius)
	AudioManager.play("explosion")
	if Game.camera_rig != null:
		Game.camera_rig.shake(0.1)
	for e: Enemy in Game.enemies.duplicate():
		var dx := e.position.x - pos.x
		var dz := e.position.z - pos.z
		var r := radius + e.radius
		var d2 := dx * dx + dz * dz
		if d2 <= r * r:
			var f := 1.0 - 0.4 * sqrt(d2) / r
			e.take_damage(dmg * f, Vector3(e.position.x, 1.0, e.position.z))


static func _seg_dist_sq(a: Vector3, b: Vector3, c: Vector3) -> float:
	var abx := b.x - a.x
	var abz := b.z - a.z
	var acx := c.x - a.x
	var acz := c.z - a.z
	var len2 := abx * abx + abz * abz
	var t := 0.0
	if len2 > 0.00001:
		t = clampf((acx * abx + acz * abz) / len2, 0.0, 1.0)
	var dx := acx - abx * t
	var dz := acz - abz * t
	return dx * dx + dz * dz
