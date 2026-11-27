class_name Scenery
extends RefCounted
## Semi-random scenery beside the road, rebuilt on every battle (see EnvTheme for the data).
## The road lane and the barriers are never touched: every prop keeps LANE_CLEAR + its radius
## away from the lane centre. What changes per play: ground tint, landmark kinds and spots, prop
## mix (weights are re-rolled), cluster / lone prop / decal positions, fence-like runs, density.
## Props are batched in MultiMeshes per (prop, 80 m chunk) so far chunks are frustum culled.

const GROUND_Y := -0.2 ## top of the Ground box in the level scenes
const Z_START := 30.0
const X_MAX := 38.0
const LANE_CLEAR := 8.2
const VERGE_LEN := 10.0
const CHUNK := 80.0
const CELL := 8.0 ## footprint grid cell, larger than the biggest radius sum (landmark 4.6 + prop 1.9)
const GROUP_SPACING := 22.0 ## about one prop cluster per this many metres per side
const SOLO_SPACING := 7.0 ## about one lone prop per this many metres per side
const DECAL_SPACING := 20.0
const RUN_CHANCE := 0.6
const LANDMARKS_PER_SIDE := Vector2i(2, 4)
const LOW_GFX_DENSITY := 0.55

var _theme: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _root: Node3D
var _z_end := 0.0
var _high := true
var _props: Dictionary = {} ## stem -> {"mesh", "xform"} or {} when the file is missing
var _grid: Dictionary = {} ## Vector2i cell -> Array of Vector3(x, z, radius)
var _batches: Dictionary = {} ## "stem|chunk" -> {"mesh", "xforms", "shadow"}
var _weights: Dictionary = {} ## prop name -> weight rolled for this build
var _fill: Array = []
var _decals: Array = []
var _runs: Array = []
var _landmarks: Array = []


## Adds the "Scenery" node to `level` for a themed chapter; does nothing for the others.
## `z_end` = the furthest z (negative) that needs scenery.
static func build(level: Node3D, level_index: int, z_end: float) -> void:
	var theme := EnvTheme.of(level_index)
	if theme.is_empty():
		return
	Scenery.new()._run(level, theme, z_end)


func _run(level: Node3D, theme: Dictionary, z_end: float) -> void:
	_theme = theme
	_z_end = z_end
	_rng.randomize()
	_high = bool(PlayerData.settings.get("graphics_high", true))
	_root = Node3D.new()
	_root.name = "Scenery"
	level.add_child(_root)
	_fill = _existing(theme["fill"])
	_decals = _existing(theme["decals"])
	_runs = _existing(theme["runs"])
	_landmarks = _existing(theme["landmarks"])
	for e: Dictionary in _fill + _decals:
		_weights[e["n"]] = float(e["w"]) * _rng.randf_range(0.4, 1.6)
	_tint_ground(level)
	_verge()
	var length := Z_START - _z_end
	var density_scale := 1.0 if _high else LOW_GFX_DENSITY
	for side in [-1.0, 1.0]:
		_place_landmarks(side, length)
		_place_runs(side)
	for side in [-1.0, 1.0]:
		var density := _rng.randf_range(0.7, 1.3) * density_scale
		_place_groups(side, length, density)
		_place_solos(side, length, density)
		_place_decals(side, length, density)
	for b: Dictionary in _batches.values():
		_multi(b["mesh"], b["xforms"], bool(b["shadow"]) and _high)


## Entries of `list` whose glb exists, so a missing file never leaves a hole in the weights.
func _existing(list: Array) -> Array:
	return list.filter(func(e: Dictionary) -> bool: return not _prop(e["n"]).is_empty())


func _prop(stem: String) -> Dictionary:
	if not _props.has(stem):
		_props[stem] = Models.prop(EnvTheme.prop_base(_theme, stem))
	return _props[stem]


## Ground box: theme colour, slid toward the alternate colour by a random amount, plus a brightness shift.
func _tint_ground(level: Node3D) -> void:
	var ground := level.get_node_or_null("Ground") as MeshInstance3D
	if ground == null:
		return
	var c: Color = (_theme["ground"] as Color).lerp(_theme["ground_alt"], _rng.randf_range(0.0, 0.6))
	var k := _rng.randf_range(0.94, 1.06)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0))
	ground.material_override = m


## Raised verge strip along both sides of the lane (right side tile, rotated 180 deg for the left).
func _verge() -> void:
	var p := _prop("verge")
	if p.is_empty():
		return
	var xfs: Array = []
	var z := Z_START
	while z > _z_end:
		for yaw in [0.0, PI]:
			xfs.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(0.0, GROUND_Y, z - VERGE_LEN * 0.5)) * (p["xform"] as Transform3D))
		z -= VERGE_LEN
	_multi(p["mesh"], xfs, false)


## 2-4 big props per side, one per equal slice of the level, never the same kind twice in a row.
func _place_landmarks(side: float, length: float) -> void:
	if _landmarks.is_empty():
		return
	var count := _rng.randi_range(LANDMARKS_PER_SIDE.x, LANDMARKS_PER_SIDE.y)
	var last := ""
	for i in count:
		var pool: Array = _landmarks.filter(func(lm: Dictionary) -> bool: return lm["n"] != last or _landmarks.size() == 1)
		var e: Dictionary = pool[_rng.randi() % pool.size()]
		var z := Z_START - length / count * (float(i) + _rng.randf_range(0.2, 0.8))
		for attempt in 5:
			var x := side * (float(e["x"]) + _rng.randf_range(0.0, 8.0))
			if _put(e, x, z, true, _rng.randf_range(0.9, 1.15)):
				last = e["n"]
				break


## Rows of one piece laid along the road (fences, sandbags, pipes, lamp posts). Blocked pieces leave a gap.
func _place_runs(side: float) -> void:
	for e: Dictionary in _runs:
		if _rng.randf() > RUN_CHANCE:
			continue
		var pieces := _rng.randi_range(3, 7)
		var step := float(e["len"])
		var z := _rng.randf_range(_z_end + step * pieces, Z_START - 5.0)
		var x := side * (float(e["x"]) + _rng.randf_range(0.0, 1.5))
		for i in pieces:
			var pz := z - step * i
			var r := minf(step * 0.5, 1.6)
			if absf(x) >= LANE_CLEAR and _free(x, pz, r):
				_claim(x, pz, r)
				_add(e["n"], Vector3(x, GROUND_Y, pz), 1.0, PI * 0.5, false)


## Clusters of 3-7 props of two kinds, spread by a gaussian around a centre that leans toward the road.
func _place_groups(side: float, length: float, density: float) -> void:
	if _fill.is_empty():
		return
	for i in roundi(length / GROUP_SPACING * density):
		var cx := side * (9.5 + pow(_rng.randf(), 1.5) * (X_MAX - 12.0))
		var cz := _rng.randf_range(_z_end, Z_START)
		var main := _pick(_fill)
		var other := _pick(_fill)
		for k in _rng.randi_range(3, 7):
			var e := main if _rng.randf() < 0.6 else other
			for attempt in 4:
				if _put(e, cx + _rng.randfn(0.0, 2.5), cz + _rng.randfn(0.0, 3.5)):
					break


func _place_solos(side: float, length: float, density: float) -> void:
	if _fill.is_empty():
		return
	for i in roundi(length / SOLO_SPACING * density):
		var x := side * (8.8 + pow(_rng.randf(), 1.6) * (X_MAX - 9.0))
		_put(_pick(_fill), x, _rng.randf_range(_z_end, Z_START))


## Flat ground pieces (flowers, ponds, lava cracks). They sit under everything, so they do not claim space.
func _place_decals(side: float, length: float, density: float) -> void:
	if _decals.is_empty():
		return
	for i in roundi(length / DECAL_SPACING * density):
		var e := _pick(_decals)
		var x := side * _rng.randf_range(float(e["x"]), 30.0)
		var z := _rng.randf_range(_z_end, Z_START)
		if _free(x, z, 1.0):
			var s: Array = e["s"]
			_add(e["n"], Vector3(x, GROUND_Y + 0.02, z), _rng.randf_range(s[0], s[1]), _rng.randf() * TAU, false)


## Weighted pick from `list` using this build's rolled weights.
func _pick(list: Array) -> Dictionary:
	var total := 0.0
	for e: Dictionary in list:
		total += float(_weights[e["n"]])
	var t := _rng.randf() * total
	for e: Dictionary in list:
		t -= float(_weights[e["n"]])
		if t <= 0.0:
			return e
	return list[list.size() - 1]


## Places one prop at (x, z) when it fits: outside the lane, inside the level, clear of other props.
## `scale` < 0 = roll it from the entry's "s" range (landmarks pass their own).
func _put(e: Dictionary, x: float, z: float, shadow: bool = false, scale: float = -1.0) -> bool:
	if scale < 0.0:
		var s: Array = e["s"]
		scale = _rng.randf_range(s[0], s[1])
	var r := float(e.get("r", 1.0)) * scale
	if absf(x) < maxf(float(e["x"]), LANE_CLEAR + r) or absf(x) > X_MAX or z > Z_START or z < _z_end:
		return false
	if not _free(x, z, r):
		return false
	_claim(x, z, r)
	_add(e["n"], Vector3(x, GROUND_Y, z), scale, _rng.randf() * TAU, shadow)
	return true


func _cell(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / CELL), floori(z / CELL))


func _free(x: float, z: float, r: float) -> bool:
	var c := _cell(x, z)
	for ox in range(-1, 2):
		for oz in range(-1, 2):
			var list: Array = _grid.get(Vector2i(c.x + ox, c.y + oz), [])
			for o: Vector3 in list:
				if Vector2(x - o.x, z - o.y).length() < r + o.z:
					return false
	return true


func _claim(x: float, z: float, r: float) -> void:
	var c := _cell(x, z)
	if not _grid.has(c):
		_grid[c] = []
	_grid[c].append(Vector3(x, z, r))


## Queues one prop instance into its (prop, chunk) batch.
func _add(stem: String, pos: Vector3, scale: float, yaw: float, shadow: bool) -> void:
	var p := _prop(stem)
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * scale), pos) * (p["xform"] as Transform3D)
	var key := "%s|%d" % [stem, floori((Z_START - pos.z) / CHUNK)]
	if not _batches.has(key):
		_batches[key] = {"mesh": p["mesh"], "xforms": [], "shadow": shadow}
	_batches[key]["xforms"].append(xf)


func _multi(mesh: Mesh, xforms: Array, shadow: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(inst)
