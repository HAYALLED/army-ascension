class_name LevelBuilder
extends RefCounted
## Builds the battlefield from primitives: ground, lane, barriers,
## decorations (MultiMesh, one draw call each) and the boss arena.


static func _multi(parent: Node3D, mesh: Mesh, mat: Material, xforms: Array, colors: Array, shadows: bool = false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)


static func _xf(pos: Vector3, scl: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(scl), pos)


## Asset names looked up in Assets/Ingame (any of .glb/.gltf/.tscn).
## Missing ones fall back to primitive placeholders.
const TREES := ["tree_a", "tree_b"]
const ROCKS := ["rock_a", "rock_b"]
const BUILDINGS := ["building_a", "building_b", "building_c"]
const BARRIERS := ["barrier_a", "barrier_b"]
const ASSET_DIR := "res://Assets/Ingame/"


static func _variants(names: Array) -> Array:
	var bases: Array = []
	for n in names:
		bases.append(ASSET_DIR + String(n))
	return Models.prop_variants(bases)


## Scatter real prop meshes: one MultiMesh per variant. placements = [{pos, scale, yaw}]
static func _scatter(root: Node3D, variants: Array, placements: Array, rng: RandomNumberGenerator, shadows: bool) -> void:
	var buckets: Array = []
	for v in variants:
		buckets.append([])
	for pl in placements:
		var vi := rng.randi() % variants.size()
		var xf: Transform3D = _xf(pl["pos"], Vector3.ONE * float(pl["scale"]), float(pl["yaw"]))
		buckets[vi].append(xf * (variants[vi]["xform"] as Transform3D))
	for vi in variants.size():
		if not buckets[vi].is_empty():
			_multi(root, variants[vi]["mesh"], null, buckets[vi], [], shadows)


static func build_world(parent: Node3D, length: float, arena_start_z: float) -> void:
	var root := Node3D.new()
	root.name = "World"
	parent.add_child(root)
	var z_start := 25.0
	var z_end := -(length + 45.0)
	var span := z_start - z_end
	var center := (z_start + z_end) * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260

	# Ground + lane
	Mats.part(root, Mats.box(Vector3(160, 0.5, span)), Mats.solid(Color(0.3, 0.38, 0.22), 0.0, 1.0), Vector3(0, -0.25, center))
	Mats.part(root, Mats.box(Vector3(14.4, 0.12, span)), Mats.solid(Color(0.62, 0.55, 0.42), 0.0, 1.0), Vector3(0, 0.0, center))

	# Lane stripes (strong sense of forward motion) + edge dashes
	var stripes: Array = []
	var stripe_cols: Array = []
	var dashes: Array = []
	var z := z_start
	var i := 0
	while z > z_end:
		stripes.append(_xf(Vector3(0, 0.075, z), Vector3(14.2, 0.02, 0.45)))
		var shade := 0.5 + 0.06 * float(i % 3)
		stripe_cols.append(Color(shade, shade * 0.88, shade * 0.7))
		dashes.append(_xf(Vector3(-6.6, 0.075, z), Vector3(0.22, 0.02, 1.6)))
		dashes.append(_xf(Vector3(6.6, 0.075, z), Vector3(0.22, 0.02, 1.6)))
		z -= 5.0
		i += 1
	_multi(root, Mats.box(Vector3.ONE), Mats.vcolor(true), stripes, stripe_cols)
	_multi(root, Mats.box(Vector3.ONE), Mats.unshaded(Color(0.95, 0.95, 0.9)), dashes, [])
	Mats.part(root, Mats.box(Vector3(14.2, 0.02, 0.6)), Mats.unshaded(Color.WHITE), Vector3(0, 0.08, 3.5))

	# Side barriers
	var barrier_v := _variants(BARRIERS)
	if not barrier_v.is_empty():
		var pl: Array = []
		z = z_start
		while z > z_end:
			for sx in [-7.6, 7.6]:
				pl.append({"pos": Vector3(sx, 0, z), "scale": 1.0, "yaw": 0.0})
			z -= 2.1
		_scatter(root, barrier_v, pl, rng, true)
	else:
		var blocks: Array = []
		var block_cols: Array = []
		z = z_start
		i = 0
		while z > z_end:
			for sx in [-7.6, 7.6]:
				blocks.append(_xf(Vector3(sx, 0.43, z), Vector3(0.7, 0.86, 2.0)))
				block_cols.append(Color(0.85, 0.85, 0.85) if i % 2 == 0 else Color(0.8, 0.25, 0.2))
			z -= 2.1
			i += 1
		_multi(root, Mats.box(Vector3.ONE), Mats.vcolor(true), blocks, block_cols, true)

	# Trees
	var tree_pl: Array = []
	for t in 150:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		tree_pl.append({
			"pos": Vector3(side * rng.randf_range(10.5, 42.0), 0, rng.randf_range(z_end, z_start)),
			"scale": rng.randf_range(0.8, 1.4), "yaw": rng.randf() * TAU})
	var tree_v := _variants(TREES)
	if not tree_v.is_empty():
		_scatter(root, tree_v, tree_pl, rng, false)
	else:
		var trunks: Array = []
		var canopies: Array = []
		var canopy_cols: Array = []
		for pl in tree_pl:
			var p: Vector3 = pl["pos"]
			var s: float = pl["scale"]
			var h := 2.4 * s
			trunks.append(_xf(Vector3(p.x, h * 0.5, p.z), Vector3(s, h, s)))
			var ch := 2.8 * s
			canopies.append(_xf(Vector3(p.x, h * 0.7 + ch * 0.5, p.z), Vector3(1.7 * s, ch, 1.7 * s)))
			var g := rng.randf()
			canopy_cols.append(Color(0.16 + g * 0.1, 0.38 + g * 0.17, 0.15))
		_multi(root, Mats.cylinder(0.12, 0.2, 1.0, 6), Mats.solid(Color(0.35, 0.24, 0.14)), trunks, [])
		_multi(root, Mats.cone(1.0, 1.0, 7), Mats.vcolor(true), canopies, canopy_cols)

	# Rocks
	var rock_pl: Array = []
	for r in 70:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		rock_pl.append({
			"pos": Vector3(side * rng.randf_range(9.0, 30.0), 0, rng.randf_range(z_end, z_start)),
			"scale": rng.randf_range(0.6, 1.5), "yaw": rng.randf() * TAU})
	var rock_v := _variants(ROCKS)
	if not rock_v.is_empty():
		_scatter(root, rock_v, rock_pl, rng, false)
	else:
		var rocks: Array = []
		var rock_cols: Array = []
		for pl in rock_pl:
			var p: Vector3 = pl["pos"]
			var s: float = pl["scale"] * 0.7
			rocks.append(_xf(Vector3(p.x, s * 0.2, p.z), Vector3(s, s * 0.6, s), pl["yaw"]))
			var gr := rng.randf_range(0.35, 0.55)
			rock_cols.append(Color(gr, gr, gr * 1.05))
		_multi(root, Mats.sphere(1.0, 7), Mats.vcolor(true), rocks, rock_cols)

	# Buildings in the distance
	var b_pl: Array = []
	for b in 40:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		b_pl.append({
			"pos": Vector3(side * rng.randf_range(16.0, 44.0), 0, rng.randf_range(z_end, z_start)),
			"scale": rng.randf_range(0.8, 1.3), "yaw": rng.randi_range(0, 3) * PI * 0.5})
	var b_v := _variants(BUILDINGS)
	if not b_v.is_empty():
		_scatter(root, b_v, b_pl, rng, true)
	else:
		var buildings: Array = []
		var b_cols: Array = []
		for pl in b_pl:
			var p: Vector3 = pl["pos"]
			var w := rng.randf_range(4.0, 8.0)
			var h := rng.randf_range(4.0, 12.0)
			var d := rng.randf_range(4.0, 8.0)
			buildings.append(_xf(Vector3(p.x, h * 0.5, p.z), Vector3(w, h, d)))
			var c := rng.randf_range(0.3, 0.5)
			b_cols.append(Color(c, c * 0.95, c * 0.88))
		_multi(root, Mats.box(Vector3.ONE), Mats.vcolor(true), buildings, b_cols, true)

	_build_arena(root, arena_start_z, length)


static func _build_arena(root: Node3D, arena_start_z: float, length: float) -> void:
	var back_z := -(length + 8.0)
	var arena_len := arena_start_z - back_z
	var cz := (arena_start_z + back_z) * 0.5
	Mats.part(root, Mats.box(Vector3(14.4, 0.16, arena_len)), Mats.solid(Color(0.24, 0.25, 0.3), 0.0, 0.6), Vector3(0, 0.0, cz))
	var hazards: Array = []
	var z := arena_start_z
	while z > back_z:
		hazards.append(_xf(Vector3(0, 0.09, z), Vector3(14.2, 0.02, 0.7)))
		z -= 6.0
	_multi(root, Mats.box(Vector3.ONE), Mats.solid(Color(0.95, 0.75, 0.1), 0.6), hazards, [])
	var wall_mat := Mats.solid(Color(0.13, 0.13, 0.17), 0.0, 0.5)
	Mats.part(root, Mats.box(Vector3(1.4, 5.0, arena_len)), wall_mat, Vector3(-8.4, 2.5, cz))
	Mats.part(root, Mats.box(Vector3(1.4, 5.0, arena_len)), wall_mat, Vector3(8.4, 2.5, cz))
	Mats.part(root, Mats.box(Vector3(40, 10, 2)), wall_mat, Vector3(0, 5, back_z - 1.0))
	var glow := Mats.solid(Color(1.0, 0.15, 0.1), 2.0)
	for y in [2.5, 5.0, 7.5]:
		Mats.part(root, Mats.box(Vector3(30, 0.35, 0.1)), glow, Vector3(0, y, back_z + 0.05))
