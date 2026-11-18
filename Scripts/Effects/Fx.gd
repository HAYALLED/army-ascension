class_name Fx
extends Node3D
## Pooled visual effects: hit sparks, death bursts, explosions, rings and
## floating damage numbers. Nothing is allocated during gameplay.

const SMALL_POOL := 24
const BIG_POOL := 10
const LABEL_POOL := 24
const RING_POOL := 12

var _small: Array = []
var _big: Array = []
var _small_i: int = 0
var _big_i: int = 0
var _labels: Array = []
var _label_age := PackedFloat32Array()
var _label_i: int = 0
var _rings: Array = []
var _ring_age := PackedFloat32Array()
var _ring_dur := PackedFloat32Array()
var _ring_size := PackedFloat32Array()
var _ring_i: int = 0


func _ready() -> void:
	for i in SMALL_POOL:
		_small.append(_make_burst(7, 0.35, 2.0, 5.0, 0.8))
	for i in BIG_POOL:
		_big.append(_make_burst(22, 0.7, 3.0, 9.0, 1.6))
	for i in LABEL_POOL:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.shaded = false
		l.font_size = 64
		l.pixel_size = 0.008
		l.outline_size = 16
		l.outline_modulate = Color(0, 0, 0, 0.9)
		l.render_priority = 10
		l.outline_render_priority = 9
		l.visible = false
		add_child(l)
		_labels.append(l)
		_label_age.append(-1.0)
	for i in RING_POOL:
		var mi := MeshInstance3D.new()
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_rings.append(mi)
		_ring_age.append(-1.0)
		_ring_dur.append(0.3)
		_ring_size.append(1.0)


func _make_burst(amount: int, life: float, vmin: float, vmax: float, scl: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 85.0
	p.gravity = Vector3(0, -14, 0)
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = scl * 0.6
	p.scale_amount_max = scl
	p.mesh = Mats.sphere(0.07, 6)
	p.material_override = Mats.vcolor(false)
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


func _fire(p: CPUParticles3D, pos: Vector3, color: Color) -> void:
	p.position = pos
	p.color = color
	p.restart()
	p.emitting = true


## Small spark burst at a bullet impact.
func hit(pos: Vector3, color: Color) -> void:
	var p: CPUParticles3D = _small[_small_i]
	_small_i = (_small_i + 1) % SMALL_POOL
	_fire(p, pos, color)


## Large burst used for deaths. `size` scales the debris cloud position only.
func death_burst(pos: Vector3, color: Color, _size: float = 1.0) -> void:
	var p: CPUParticles3D = _big[_big_i]
	_big_i = (_big_i + 1) % BIG_POOL
	_fire(p, pos, color)


func explosion(pos: Vector3, radius: float) -> void:
	var p: CPUParticles3D = _big[_big_i]
	_big_i = (_big_i + 1) % BIG_POOL
	_fire(p, pos + Vector3(0, 0.4, 0), Color(1.0, 0.6, 0.2))
	_ring(pos + Vector3(0, 0.6, 0), radius, 0.35, true)


## Expanding green ground ring (medic pulse).
func pulse(pos: Vector3, radius: float) -> void:
	_ring(pos + Vector3(0, 0.1, 0), radius, 0.5, false)


func heal_spark(pos: Vector3) -> void:
	hit(pos + Vector3(0, 1.2, 0), Color(0.4, 1.0, 0.5))


func popup(pos: Vector3, text: String, color: Color, size: float = 1.0) -> void:
	var l: Label3D = _labels[_label_i]
	var idx := _label_i
	_label_i = (_label_i + 1) % LABEL_POOL
	l.text = text
	l.modulate = color
	l.position = pos
	l.pixel_size = 0.008 * size
	l.visible = true
	_label_age[idx] = 0.0


func _ring(pos: Vector3, radius: float, dur: float, sphere: bool) -> void:
	var idx := _ring_i
	_ring_i = (_ring_i + 1) % RING_POOL
	var mi: MeshInstance3D = _rings[idx]
	if sphere:
		mi.mesh = Mats.sphere(1.0, 12)
		mi.material_override = Mats.unshaded(Color(1.0, 0.65, 0.25, 0.55))
	else:
		mi.mesh = Mats.cylinder(1.0, 1.0, 0.05, 24)
		mi.material_override = Mats.unshaded(Color(0.4, 1.0, 0.5, 0.45))
	mi.position = pos
	mi.scale = Vector3.ONE * 0.2
	mi.transparency = 0.0
	mi.visible = true
	_ring_age[idx] = 0.0
	_ring_dur[idx] = dur
	_ring_size[idx] = radius


func _process(delta: float) -> void:
	for i in LABEL_POOL:
		if _label_age[i] < 0.0:
			continue
		_label_age[i] += delta
		var l: Label3D = _labels[i]
		l.position.y += 1.8 * delta
		var a := 1.0 - _label_age[i] / 0.7
		if a <= 0.0:
			l.visible = false
			_label_age[i] = -1.0
		else:
			l.modulate.a = a
	for i in RING_POOL:
		if _ring_age[i] < 0.0:
			continue
		_ring_age[i] += delta
		var k := _ring_age[i] / _ring_dur[i]
		var mi: MeshInstance3D = _rings[i]
		if k >= 1.0:
			mi.visible = false
			_ring_age[i] = -1.0
			continue
		var ease_k := 1.0 - pow(1.0 - k, 3.0)
		var s := lerpf(0.2, _ring_size[i], ease_k)
		mi.scale = Vector3(s, s if mi.mesh is SphereMesh else 1.0, s)
		mi.transparency = k
