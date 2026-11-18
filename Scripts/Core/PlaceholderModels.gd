class_name PlaceholderModels
extends RefCounted
## Primitive-shape fallback models. Used only when no real 3D asset exists
## for a unit yet (see Models.gd). Delete a builder once its asset is in.
## Each returns { "root": Node3D, "meshes": Array } (+ "height" for enemies).


static func enemy(kind: int) -> Dictionary:
	var root := Node3D.new()
	var meshes: Array = []
	var height := 1.5
	match kind:
		EnemyDB.Kind.BASIC:
			height = 1.5
			_basic(root, meshes)
		EnemyDB.Kind.FAST:
			height = 1.4
			_fast(root, meshes)
		EnemyDB.Kind.ARMORED:
			height = 1.8
			_armored(root, meshes)
		EnemyDB.Kind.RANGED:
			height = 1.6
			_ranged(root, meshes)
		EnemyDB.Kind.ELITE:
			height = 2.1
			_elite(root, meshes)
		EnemyDB.Kind.BOSS:
			height = 3.4
			_boss(root, meshes)
	return {"root": root, "meshes": meshes, "height": height}


static func soldier(type: int) -> Dictionary:
	var d: Dictionary = SoldierDB.DATA[type]
	var body_col: Color = d["body"]
	var accent: Color = d["accent"]
	var root := Node3D.new()
	var m: Array = []
	var skin := Color(0.93, 0.76, 0.6)
	var gun_mat := Mats.solid(Color(0.14, 0.14, 0.17), 0.0, 0.5)
	_p(root, m, Mats.capsule(0.24, 0.85), Mats.solid(body_col), Vector3(0, 0.52, 0))
	_p(root, m, Mats.sphere(0.17), Mats.solid(skin), Vector3(0, 1.1, 0))
	_p(root, m, Mats.sphere(0.2), Mats.solid(accent), Vector3(0, 1.17, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	_p(root, m, Mats.box(Vector3(0.12, 0.3, 0.14)), Mats.solid(accent), Vector3(-0.1, 0.15, 0))
	_p(root, m, Mats.box(Vector3(0.12, 0.3, 0.14)), Mats.solid(accent), Vector3(0.1, 0.15, 0))
	match type:
		SoldierDB.Type.RIFLEMAN:
			_p(root, m, Mats.box(Vector3(0.07, 0.09, 0.6)), gun_mat, Vector3(0.18, 0.66, -0.3))
		SoldierDB.Type.MACHINE_GUNNER:
			_p(root, m, Mats.box(Vector3(0.1, 0.12, 0.72)), gun_mat, Vector3(0.18, 0.64, -0.36))
			_p(root, m, Mats.box(Vector3(0.15, 0.15, 0.15)), Mats.solid(Color(0.95, 0.75, 0.2)), Vector3(0.18, 0.5, -0.2))
			_p(root, m, Mats.box(Vector3(0.55, 0.07, 0.3)), Mats.solid(Color(0.95, 0.75, 0.2)), Vector3(0, 0.75, -0.02), Vector3(0, 0, 25))
		SoldierDB.Type.SNIPER:
			_p(root, m, Mats.box(Vector3(0.05, 0.07, 1.0)), gun_mat, Vector3(0.17, 0.68, -0.5))
			_p(root, m, Mats.cylinder(0.04, 0.04, 0.25), gun_mat, Vector3(0.17, 0.78, -0.45), Vector3(90, 0, 0))
			_p(root, m, Mats.sphere(0.23), Mats.solid(Color(0.12, 0.24, 0.12)), Vector3(0, 1.15, 0.02), Vector3.ZERO, Vector3(1, 0.8, 1))
		SoldierDB.Type.ROCKET:
			_p(root, m, Mats.cylinder(0.1, 0.1, 0.95), Mats.solid(Color(0.3, 0.33, 0.2)), Vector3(0.2, 0.92, -0.2), Vector3(90, 0, 0))
			_p(root, m, Mats.cone(0.1, 0.18), Mats.solid(Color(0.9, 0.25, 0.1)), Vector3(0.2, 0.92, -0.74), Vector3(-90, 0, 0))
		SoldierDB.Type.MEDIC:
			_p(root, m, Mats.box(Vector3(0.32, 0.36, 0.16)), Mats.solid(Color(0.95, 0.95, 0.95)), Vector3(0, 0.66, 0.22))
			var red := Mats.solid(Color(0.9, 0.12, 0.12))
			_p(root, m, Mats.box(Vector3(0.22, 0.07, 0.02)), red, Vector3(0, 0.66, 0.31))
			_p(root, m, Mats.box(Vector3(0.07, 0.22, 0.02)), red, Vector3(0, 0.66, 0.31))
			_p(root, m, Mats.box(Vector3(0.22, 0.07, 0.02)), red, Vector3(0, 0.62, -0.25))
			_p(root, m, Mats.box(Vector3(0.07, 0.22, 0.02)), red, Vector3(0, 0.62, -0.25))
			_p(root, m, Mats.box(Vector3(0.06, 0.08, 0.28)), gun_mat, Vector3(0.18, 0.62, -0.2))
	return {"root": root, "meshes": m}


static func _p(root: Node3D, meshes: Array, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> void:
	meshes.append(Mats.part(root, mesh, mat, pos, rot, scl))


static func _basic(root: Node3D, m: Array) -> void:
	var body := Mats.solid(Color(0.82, 0.22, 0.2))
	var dark := Mats.solid(Color(0.45, 0.08, 0.1))
	_p(root, m, Mats.capsule(0.27, 0.95), body, Vector3(0, 0.55, 0))
	_p(root, m, Mats.sphere(0.2), Mats.solid(Color(0.85, 0.65, 0.5)), Vector3(0, 1.2, 0))
	_p(root, m, Mats.sphere(0.22), dark, Vector3(0, 1.27, 0), Vector3.ZERO, Vector3(1, 0.65, 1))
	_p(root, m, Mats.box(Vector3(0.1, 0.1, 0.5)), body, Vector3(-0.32, 0.85, -0.25))
	_p(root, m, Mats.box(Vector3(0.1, 0.1, 0.5)), body, Vector3(0.32, 0.85, -0.25))
	_p(root, m, Mats.box(Vector3(0.13, 0.3, 0.15)), dark, Vector3(-0.11, 0.15, 0))
	_p(root, m, Mats.box(Vector3(0.13, 0.3, 0.15)), dark, Vector3(0.11, 0.15, 0))
	var eye := Mats.solid(Color(1.0, 0.9, 0.2), 2.0)
	_p(root, m, Mats.sphere(0.04, 6), eye, Vector3(-0.08, 1.22, -0.18))
	_p(root, m, Mats.sphere(0.04, 6), eye, Vector3(0.08, 1.22, -0.18))


static func _fast(root: Node3D, m: Array) -> void:
	var body := Mats.solid(Color(1.0, 0.62, 0.12))
	var dark := Mats.solid(Color(0.55, 0.28, 0.05))
	_p(root, m, Mats.capsule(0.2, 0.85), body, Vector3(0, 0.5, 0), Vector3(-18, 0, 0))
	_p(root, m, Mats.sphere(0.18), Mats.solid(Color(0.9, 0.7, 0.5)), Vector3(0, 1.12, -0.12))
	_p(root, m, Mats.cone(0.12, 0.45), dark, Vector3(0, 0.95, 0.25), Vector3(60, 0, 0))
	_p(root, m, Mats.box(Vector3(0.09, 0.09, 0.45)), body, Vector3(-0.25, 0.7, -0.3))
	_p(root, m, Mats.box(Vector3(0.09, 0.09, 0.45)), body, Vector3(0.25, 0.7, -0.3))
	_p(root, m, Mats.box(Vector3(0.1, 0.3, 0.12)), dark, Vector3(-0.09, 0.15, 0))
	_p(root, m, Mats.box(Vector3(0.1, 0.3, 0.12)), dark, Vector3(0.09, 0.15, 0))
	var eye := Mats.solid(Color(1.0, 0.1, 0.1), 2.0)
	_p(root, m, Mats.sphere(0.035, 6), eye, Vector3(-0.07, 1.15, -0.28))
	_p(root, m, Mats.sphere(0.035, 6), eye, Vector3(0.07, 1.15, -0.28))


static func _armored(root: Node3D, m: Array) -> void:
	var steel := Mats.solid(Color(0.5, 0.53, 0.6), 0.0, 0.4)
	var dark := Mats.solid(Color(0.22, 0.24, 0.28), 0.0, 0.5)
	_p(root, m, Mats.box(Vector3(0.75, 0.85, 0.5)), steel, Vector3(0, 0.8, 0))
	_p(root, m, Mats.box(Vector3(0.36, 0.3, 0.36)), dark, Vector3(0, 1.4, 0))
	_p(root, m, Mats.box(Vector3(0.95, 1.0, 0.12)), Mats.solid(Color(0.3, 0.38, 0.55), 0.0, 0.35), Vector3(0, 0.85, -0.42))
	_p(root, m, Mats.box(Vector3(0.6, 0.1, 0.14)), Mats.solid(Color(1.0, 0.8, 0.2), 1.0), Vector3(0, 1.05, -0.5))
	_p(root, m, Mats.sphere(0.22), steel, Vector3(-0.47, 1.18, 0))
	_p(root, m, Mats.sphere(0.22), steel, Vector3(0.47, 1.18, 0))
	_p(root, m, Mats.box(Vector3(0.25, 0.4, 0.3)), dark, Vector3(-0.2, 0.2, 0))
	_p(root, m, Mats.box(Vector3(0.25, 0.4, 0.3)), dark, Vector3(0.2, 0.2, 0))
	_p(root, m, Mats.box(Vector3(0.22, 0.05, 0.05)), Mats.solid(Color(1.0, 0.2, 0.2), 2.0), Vector3(0, 1.42, -0.19))


static func _ranged(root: Node3D, m: Array) -> void:
	var body := Mats.solid(Color(0.55, 0.25, 0.75))
	var dark := Mats.solid(Color(0.25, 0.1, 0.35))
	_p(root, m, Mats.capsule(0.24, 0.9), body, Vector3(0, 0.55, 0))
	_p(root, m, Mats.sphere(0.18), Mats.solid(Color(0.85, 0.7, 0.6)), Vector3(0, 1.17, 0))
	_p(root, m, Mats.sphere(0.23), dark, Vector3(0, 1.2, 0.03), Vector3.ZERO, Vector3(1, 0.85, 1))
	_p(root, m, Mats.box(Vector3(0.1, 0.12, 0.95)), Mats.solid(Color(0.15, 0.15, 0.18), 0.0, 0.5), Vector3(0.25, 0.8, -0.5))
	_p(root, m, Mats.sphere(0.07, 6), Mats.solid(Color(0.3, 0.9, 1.0), 2.5), Vector3(0.25, 0.8, -1.0))
	_p(root, m, Mats.box(Vector3(0.13, 0.3, 0.15)), dark, Vector3(-0.1, 0.15, 0))
	_p(root, m, Mats.box(Vector3(0.13, 0.3, 0.15)), dark, Vector3(0.1, 0.15, 0))


static func _elite(root: Node3D, m: Array) -> void:
	var body := Mats.solid(Color(0.55, 0.08, 0.1))
	var black := Mats.solid(Color(0.1, 0.08, 0.1))
	var gold := Mats.solid(Color(0.9, 0.7, 0.2), 0.0, 0.35)
	_p(root, m, Mats.capsule(0.32, 1.15), body, Vector3(0, 0.75, 0))
	_p(root, m, Mats.sphere(0.24), Mats.solid(Color(0.85, 0.6, 0.5)), Vector3(0, 1.5, 0))
	_p(root, m, Mats.sphere(0.27), black, Vector3(0, 1.56, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	_p(root, m, Mats.cone(0.07, 0.4), gold, Vector3(-0.22, 1.8, 0), Vector3(0, 0, 25))
	_p(root, m, Mats.cone(0.07, 0.4), gold, Vector3(0.22, 1.8, 0), Vector3(0, 0, -25))
	_p(root, m, Mats.sphere(0.28), gold, Vector3(-0.5, 1.15, 0))
	_p(root, m, Mats.sphere(0.28), gold, Vector3(0.5, 1.15, 0))
	_p(root, m, Mats.cone(0.09, 0.35), black, Vector3(-0.5, 1.45, 0))
	_p(root, m, Mats.cone(0.09, 0.35), black, Vector3(0.5, 1.45, 0))
	_p(root, m, Mats.box(Vector3(0.1, 0.9, 0.35)), Mats.solid(Color(0.7, 0.72, 0.78), 0.0, 0.3), Vector3(0.58, 0.95, -0.4))
	_p(root, m, Mats.box(Vector3(0.16, 0.16, 0.16)), body, Vector3(0.58, 0.55, -0.4))
	var eye := Mats.solid(Color(1.0, 0.85, 0.1), 3.0)
	_p(root, m, Mats.sphere(0.045, 6), eye, Vector3(-0.09, 1.52, -0.21))
	_p(root, m, Mats.sphere(0.045, 6), eye, Vector3(0.09, 1.52, -0.21))
	_p(root, m, Mats.box(Vector3(0.18, 0.4, 0.2)), black, Vector3(-0.15, 0.2, 0))
	_p(root, m, Mats.box(Vector3(0.18, 0.4, 0.2)), black, Vector3(0.15, 0.2, 0))


static func _boss(root: Node3D, m: Array) -> void:
	var steel := Mats.solid(Color(0.26, 0.28, 0.34), 0.0, 0.35)
	var dark := Mats.solid(Color(0.14, 0.15, 0.19), 0.0, 0.45)
	var glow := Mats.solid(Color(1.0, 0.25, 0.1), 3.0)
	var core := Mats.solid(Color(1.0, 0.55, 0.1), 3.0)
	_p(root, m, Mats.box(Vector3(0.55, 1.0, 0.55)), dark, Vector3(-0.45, 0.5, 0))
	_p(root, m, Mats.box(Vector3(0.55, 1.0, 0.55)), dark, Vector3(0.45, 0.5, 0))
	_p(root, m, Mats.box(Vector3(1.7, 1.3, 1.0)), steel, Vector3(0, 1.65, 0))
	_p(root, m, Mats.sphere(0.28, 10), core, Vector3(0, 1.75, -0.52))
	_p(root, m, Mats.box(Vector3(0.65, 0.5, 0.85)), dark, Vector3(-1.1, 2.25, 0))
	_p(root, m, Mats.box(Vector3(0.65, 0.5, 0.85)), dark, Vector3(1.1, 2.25, 0))
	_p(root, m, Mats.cone(0.16, 0.5), steel, Vector3(-1.1, 2.7, 0))
	_p(root, m, Mats.cone(0.16, 0.5), steel, Vector3(1.1, 2.7, 0))
	_p(root, m, Mats.cylinder(0.28, 0.28, 1.3), steel, Vector3(-1.2, 1.35, -0.15), Vector3(0, 0, 8))
	_p(root, m, Mats.cylinder(0.28, 0.28, 1.3), steel, Vector3(1.2, 1.35, -0.15), Vector3(0, 0, -8))
	_p(root, m, Mats.sphere(0.4, 10), dark, Vector3(-1.25, 0.65, -0.2))
	_p(root, m, Mats.sphere(0.4, 10), dark, Vector3(1.25, 0.65, -0.2))
	_p(root, m, Mats.box(Vector3(0.75, 0.6, 0.7)), dark, Vector3(0, 2.6, 0))
	_p(root, m, Mats.box(Vector3(0.2, 0.1, 0.05)), glow, Vector3(-0.2, 2.62, -0.36))
	_p(root, m, Mats.box(Vector3(0.2, 0.1, 0.05)), glow, Vector3(0.2, 2.62, -0.36))
	_p(root, m, Mats.cone(0.12, 0.7), steel, Vector3(-0.35, 3.1, 0), Vector3(0, 0, 20))
	_p(root, m, Mats.cone(0.12, 0.7), steel, Vector3(0.35, 3.1, 0), Vector3(0, 0, -20))
	_p(root, m, Mats.cylinder(0.15, 0.15, 1.0), dark, Vector3(-0.7, 2.55, -0.55), Vector3(90, 0, 0))
	_p(root, m, Mats.cylinder(0.15, 0.15, 1.0), dark, Vector3(0.7, 2.55, -0.55), Vector3(90, 0, 0))
