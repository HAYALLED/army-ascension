extends Node
## Authoring tool: (re)generates GatePair / SpikeWall / WaveTrigger / Level01 /
## Battle scenes from the assets in Assets/Ingame.
## Run:  godot --headless --path . res://Tools/build_level_scenes.tscn
## (runs as a scene so the autoloads exist)
## After generating, edit the scenes freely in the Godot editor.

const IN := "res://Assets/Ingame/"


func _ready() -> void:
	_gate_pair()
	_spike_wall()
	_wave_trigger()
	_level01()
	_battle()
	get_tree().quit()


# ------------------------------------------------------------------ helpers

func _n3(name: String, parent: Node, owner: Node, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	parent.add_child(n)
	n.owner = owner
	return n


func _inst(path: String, name: String, parent: Node, owner: Node, pos: Vector3 = Vector3.ZERO, yaw_deg: float = 0.0) -> Node:
	var n := (load(path) as PackedScene).instantiate()
	n.name = name
	if n is Node3D:
		(n as Node3D).position = pos
		(n as Node3D).rotation_degrees.y = yaw_deg
	parent.add_child(n)
	n.owner = owner
	return n


func _script_node(base: Node, script_path: String, name: String, parent: Node, owner: Node, pos: Vector3 = Vector3.ZERO) -> Node:
	base.name = name
	base.set_script(load(script_path))
	if base is Node3D:
		(base as Node3D).position = pos
	parent.add_child(base)
	base.owner = owner
	return base


func _mesh(name: String, mesh: Mesh, mat: Material, parent: Node, owner: Node, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.owner = owner
	return mi


func _alpha_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root)
	print("save ", path, " -> ", ResourceSaver.save(ps, path))
	root.free()


func _label(name: String, text: String, size: int, pos: Vector3, parent: Node, owner: Node) -> Label3D:
	var l := Label3D.new()
	l.name = name
	l.text = text
	l.font_size = size
	l.pixel_size = 0.011
	l.shaded = false
	l.outline_size = 22
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.position = pos
	parent.add_child(l)
	l.owner = owner
	return l


# ------------------------------------------------------------------ scenes

func _gate_pair() -> void:
	var root := Node3D.new()
	root.name = "GatePair"
	root.set_script(load("res://Scripts/Ingame/GatePair.gd"))
	var pillars := _n3("Pillars", root, root)
	for i in 3:
		_inst(IN + "gate_pillar.glb", "Pillar%d" % (i + 1), pillars, root, Vector3([-6.95, 0.0, 6.95][i], 0, 0))
	_inst(IN + "gate_beam.glb", "Beam", root, root, Vector3(0, 3.6, 0))
	for side in ["Left", "Right"]:
		var x := -3.5 if side == "Left" else 3.5
		var panel := _n3("Panel" + side, root, root, Vector3(x, 1.6, 0))
		_inst(IN + "gate_panel.glb", "Model", panel, root)
		_label("Value", "+0", 150, Vector3(0, 1.0, 0.16), panel, root)
		_label("Sub", "SOLDIERS", 60, Vector3(0, 0.42, 0.16), panel, root)
		var pad := _mesh("Pad", _box(Vector3(6.2, 0.03, 3.0)), _alpha_mat(Color(0.2, 0.55, 1.0, 0.35)), panel, root, Vector3(0, -1.51, 0))
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_save(root, "res://Scene/Ingame/GatePair.tscn")


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _spike_wall() -> void:
	var root := Node3D.new()
	root.name = "SpikeWall"
	root.set_script(load("res://Scripts/Ingame/SpikeWall.gd"))
	for i in 4:
		_inst(IN + "spike_wall.glb", "Seg%d" % (i + 1), root, root, Vector3((i - 1.5) * 3.5, 0, 0))
	_mesh("ApproachStrip", _box(Vector3(1.0, 0.02, 0.4)), _alpha_mat(Color(1.0, 0.2, 0.15, 0.7)), root, root, Vector3(0, 0.09, 1.4))
	_save(root, "res://Scene/Ingame/SpikeWall.tscn")


func _wave_trigger() -> void:
	var root := Node3D.new()
	root.name = "WaveTrigger"
	root.set_script(load("res://Scripts/Ingame/WaveTrigger.gd"))
	_save(root, "res://Scene/Ingame/WaveTrigger.tscn")


func _level01() -> void:
	var root := Node3D.new()
	root.name = "Level01"
	root.set_script(load("res://Scripts/Ingame/Level.gd"))

	# Ground
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.45, 0.62, 0.34)
	ground_mat.roughness = 1.0
	_mesh("Ground", _box(Vector3(160, 0.5, 470)), ground_mat, root, root, Vector3(0, -0.45, -170))

	# Road: tiles are 10 m long, top surface at y = 0
	var road := _n3("Road", root, root)
	for i in 32:
		_inst(IN + "road_tile.glb", "RoadTile%02d" % i, road, root, Vector3(0, -0.12, 20.0 - 10.0 * i))

	# Barriers along both sides of the road
	var barriers := _n3("Barriers", root, root)
	for sx in [-7.6, 7.6]:
		var b := BarrierLine.new()
		_script_node(b, "res://Scripts/Ingame/BarrierLine.gd", "BarrierLeft" if sx < 0 else "BarrierRight", barriers, root, Vector3(sx, 0, 25))
		b.length = 323.0

	# Boss arena (z -300 .. -360)
	var arena := _n3("Arena", root, root)
	for i in 6:
		var z := -305.0 - 10.0 * i
		_inst(IN + "arena_floor_tile.glb", "Floor%d" % i, arena, root, Vector3(0, -0.16, z))
		_inst(IN + "arena_wall_side.glb", "WallLeft%d" % i, arena, root, Vector3(-7.9, 0, z))
		_inst(IN + "arena_wall_side.glb", "WallRight%d" % i, arena, root, Vector3(7.9, 0, z), 180.0)
	_inst(IN + "arena_wall_back.glb", "BackWall", arena, root, Vector3(0, 0, -361))
	_inst(IN + "arena_entrance.glb", "Entrance", arena, root, Vector3(0, 0, -300))

	# Buff gates: [z, left effect, left value, right effect, right value, right risky]
	var gates := _n3("Gates", root, root)
	var E := GatePair.Effect
	var gate_defs := [
		[-22.0, E.ADD, 4.0, E.DAMAGE, 0.25, false],
		[-120.0, E.RATE, 0.25, E.MULTIPLY, 2.0, false],
		[-205.0, E.ADD, 5.0, E.MULTIPLY, 3.0, true],
		[-265.0, E.ADD, 6.0, E.DAMAGE, 0.25, false],
	]
	for i in gate_defs.size():
		var d: Array = gate_defs[i]
		var g := _inst("res://Scene/Ingame/GatePair.tscn", "Gate%d" % (i + 1), gates, root, Vector3(0, 0, d[0])) as GatePair
		g.left_effect = d[1]
		g.left_value = d[2]
		g.right_effect = d[3]
		g.right_value = d[4]
		g.right_risky = d[5]

	# Spike traps: [z, x, segments]
	var traps := _n3("Traps", root, root)
	var trap_defs := [[-100.0, -3.5, 2], [-108.0, 3.5, 2], [-160.0, -3.5, 2], [-168.0, 3.5, 2], [-190.0, 3.5, 2], [-197.0, 3.5, 2]]
	for i in trap_defs.size():
		var d: Array = trap_defs[i]
		var w := _inst("res://Scene/Ingame/SpikeWall.tscn", "Trap%d" % (i + 1), traps, root, Vector3(d[1], 0, d[0])) as SpikeWall
		w.segments = d[2]

	# Waves: [z, basic, fast, armored, ranged, elite]
	var waves := _n3("Waves", root, root)
	var wave_defs := [[-52.0, 14, 5, 0, 0, 0], [-140.0, 18, 6, 6, 4, 0], [-228.0, 20, 8, 8, 6, 4]]
	for i in wave_defs.size():
		var d: Array = wave_defs[i]
		var wv := _inst("res://Scene/Ingame/WaveTrigger.tscn", "Wave%d" % (i + 1), waves, root, Vector3(0, 0, d[0])) as WaveTrigger
		wv.basic = d[1]
		wv.fast = d[2]
		wv.armored = d[3]
		wv.ranged = d[4]
		wv.elite = d[5]

	# Markers
	var markers := _n3("Markers", root, root)
	for m in [["ArmyStart", 0.0], ["ArenaStop", -318.0], ["BossSpawn", -350.0]]:
		var mk := Marker3D.new()
		mk.name = m[0]
		mk.position = Vector3(0, 0, m[1])
		markers.add_child(mk)
		mk.owner = root
	_save(root, "res://Scene/Ingame/Levels/Level01.tscn")


func _battle() -> void:
	var root := Node3D.new()
	root.name = "Battle"
	root.set_script(load("res://Scripts/Ingame/Battle.gd"))

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.52, 0.85)
	sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92)
	sky_mat.ground_horizon_color = Color(0.72, 0.82, 0.92)
	sky_mat.ground_bottom_color = Color(0.35, 0.42, 0.35)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.72, 0.82, 0.92)
	env.fog_depth_begin = 60.0
	env.fog_depth_end = 125.0
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)
	we.owner = root

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0
	root.add_child(sun)
	sun.owner = root

	_inst("res://Scene/Ingame/Levels/Level01.tscn", "Level", root, root)
	var units := _n3("Units", root, root)
	_script_node(Node3D.new(), "res://Scripts/Effects/Fx.gd", "Fx", root, root)
	var pb := _script_node(Node3D.new(), "res://Scripts/Effects/ProjectilePool.gd", "PlayerBullets", root, root)
	pb.hits_enemies = true
	pb.capacity = 320
	var eb := _script_node(Node3D.new(), "res://Scripts/Effects/ProjectilePool.gd", "EnemyBullets", root, root)
	eb.hits_enemies = false
	eb.capacity = 200
	var army := _script_node(Node3D.new(), "res://Scripts/Ingame/Army.gd", "Army", root, root)
	army.units = units
	var cam := _script_node(Camera3D.new(), "res://Scripts/Ingame/CameraRig.gd", "Camera", root, root)
	cam.target = army
	cam.fov = 52.0
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.near = 0.3
	cam.far = 160.0
	cam.current = true
	_inst("res://Scene/UI/HUD.tscn", "HUD", root, root)
	_save(root, "res://Scene/Ingame/Battle.tscn")
