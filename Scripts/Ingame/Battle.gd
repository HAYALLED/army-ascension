class_name Battle
extends Node3D
## Main battle scene: builds the world, spawns the army, runs the level
## timeline (gates, spike walls, waves, boss) and reports progress.

const HUD_SCENE := preload("res://Scene/UI/HUD.tscn")
const GATE_SCENE := preload("res://Scene/Ingame/GatePair.tscn")
const WALL_SCENE := preload("res://Scene/Ingame/SpikeWall.tscn")
const BOSS_SCENE := preload("res://Scene/Enemy/Boss.tscn")

const LEVEL_LENGTH := 360.0
const ARENA_START_Z := -300.0
const BOSS_Z := -350.0
const ARENA_STOP_Z := -318.0
const SEPARATION_CELL := 2.5
const SEPARATION_STRENGTH := 5.0

var units: Node3D = null
var army: Army = null
var boss: Boss = null

var _events: Array = []
var _next_event: int = 0
var _progress_t: float = 0.0


func _ready() -> void:
	Game.reset_run()
	Game.sim_mode = "--sim" in OS.get_cmdline_user_args()
	_build_environment()
	LevelBuilder.build_world(self, LEVEL_LENGTH, ARENA_START_Z)

	units = Node3D.new()
	units.name = "Units"
	add_child(units)

	var fx := Fx.new()
	fx.name = "Fx"
	add_child(fx)
	Game.fx = fx

	var pb := ProjectilePool.new()
	pb.name = "PlayerBullets"
	pb.hits_enemies = true
	add_child(pb)
	Game.player_bullets = pb
	var eb := ProjectilePool.new()
	eb.name = "EnemyBullets"
	eb.hits_enemies = false
	eb.capacity = 200
	add_child(eb)
	Game.enemy_bullets = eb

	army = Army.new()
	army.name = "Army"
	army.units = units
	army.min_z = ARENA_STOP_Z
	add_child(army)
	Game.army = army

	var cam := CameraRig.new()
	cam.name = "Camera"
	cam.target = army
	add_child(cam)
	cam.snap()
	Game.camera_rig = cam

	_spawn_start_army()
	_build_level()

	var hud := HUD_SCENE.instantiate()
	add_child(hud)

	if Game.sim_mode:
		var pilot: Node = load("res://Scripts/Dev/SimPilot.gd").new()
		add_child(pilot)

	AudioManager.play_music()
	Game.start_battle()
	army.emit_status()
	Game.banner_requested.emit("DRAG TO MOVE", Color(1, 1, 1))


func _spawn_start_army() -> void:
	var T := SoldierDB.Type
	var list := [T.RIFLEMAN, T.RIFLEMAN, T.RIFLEMAN, T.RIFLEMAN, T.MACHINE_GUNNER, T.MACHINE_GUNNER, T.MACHINE_GUNNER,
		T.SNIPER, T.SNIPER, T.ROCKET, T.ROCKET, T.MEDIC]
	for t in list:
		army.add_soldier(t)
	army.rebuild_formation()
	for s in Game.soldiers:
		s.position = army.position + s.slot


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.3, 0.52, 0.85)
	sm.sky_horizon_color = Color(0.72, 0.82, 0.92)
	sm.ground_horizon_color = Color(0.72, 0.82, 0.92)
	sm.ground_bottom_color = Color(0.35, 0.42, 0.35)
	sky.sky_material = sm
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
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _build_level() -> void:
	var G := GatePair
	# --- gates (z, left, right)
	_add_gate(-22.0, G.make_def(G.Effect.ADD, 4), G.make_def(G.Effect.DAMAGE, 0.25))
	_add_gate(-120.0, G.make_def(G.Effect.RATE, 0.25), G.make_def(G.Effect.MULTIPLY, 2))
	_add_gate(-205.0, G.make_def(G.Effect.ADD, 5), G.make_def(G.Effect.MULTIPLY, 3, true))
	_add_gate(-265.0, G.make_def(G.Effect.ADD, 6), G.make_def(G.Effect.DAMAGE, 0.25))
	# --- spike walls (z, x_center, width)
	_add_wall(-100.0, -3.5, 7.0)
	_add_wall(-108.0, 3.5, 7.0)
	_add_wall(-160.0, -3.5, 7.0)
	_add_wall(-168.0, 3.5, 7.0)
	# risky path to the x3 gate: two walls on the right lane
	_add_wall(-190.0, 3.5, 7.0)
	_add_wall(-197.0, 3.5, 7.0)
	# --- boss
	boss = BOSS_SCENE.instantiate() as Boss
	boss.position = Vector3(0, 0, BOSS_Z)
	units.add_child(boss)
	# --- waves (trigger z, comp)
	var K := EnemyDB.Kind
	_events = [
		{"z": -52.0, "wave": 1, "comp": [[K.BASIC, 14], [K.FAST, 5]]},
		{"z": -140.0, "wave": 2, "comp": [[K.BASIC, 18], [K.FAST, 6], [K.ARMORED, 6], [K.RANGED, 4]]},
		{"z": -228.0, "wave": 3, "comp": [[K.BASIC, 20], [K.FAST, 8], [K.ARMORED, 8], [K.RANGED, 6], [K.ELITE, 4]]},
	]


func _add_gate(z: float, left: Dictionary, right: Dictionary) -> void:
	var g := GATE_SCENE.instantiate() as GatePair
	g.setup(z, left, right)
	add_child(g)


func _add_wall(z: float, x: float, width: float) -> void:
	var n := WALL_SCENE.instantiate() as SpikeWall
	n.width = width
	n.position = Vector3(x, 0, z)
	add_child(n)
	Game.walls.append({"z": z, "x": x, "hw": width * 0.5, "damage": 35.0, "hit": {}, "done": false})


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	Game.elapsed += delta
	while _next_event < _events.size() and army.position.z <= float(_events[_next_event]["z"]):
		var ev: Dictionary = _events[_next_event]
		_spawn_wave(int(ev["wave"]), ev["comp"])
		_next_event += 1
	_check_walls()
	_separate_enemies()
	_progress_t -= delta
	if _progress_t <= 0.0:
		_progress_t = 0.1
		Game.progress_changed.emit(clampf(-army.position.z / absf(BOSS_Z), 0.0, 1.0))


func _spawn_wave(index: int, comp: Array) -> void:
	Game.wave_started.emit(index, _events.size())
	Game.banner_requested.emit("WAVE %d" % index, Color(1.0, 0.8, 0.2))
	AudioManager.play("wave_horn")
	var list: Array = []
	for entry in comp:
		for i in int(entry[1]):
			list.append(int(entry[0]))
	list.shuffle()
	var base_z := army.position.z - 40.0
	for n in list.size():
		var row := floori(n / 6.0)
		var col := n % 6
		var x := lerpf(-5.5, 5.5, col / 5.0) + randf_range(-0.6, 0.6)
		var z := base_z - row * 1.6 - randf() * 0.8
		Enemy.spawn(units, list[n], Vector3(x, 0, z))


func _check_walls() -> void:
	var az := army.position.z
	for w in Game.walls:
		if w["done"]:
			continue
		var wz: float = w["z"]
		if az > wz + 9.0:
			continue
		if az < wz - 10.0:
			w["done"] = true
			continue
		var hits: Dictionary = w["hit"]
		for s: Soldier in Game.soldiers.duplicate():
			if hits.has(s.uid):
				continue
			if absf(s.position.z - wz) < 0.9 and absf(s.position.x - float(w["x"])) <= float(w["hw"]) + 0.25:
				hits[s.uid] = true
				s.take_damage(float(w["damage"]))
				Game.fx.hit(Vector3(s.position.x, 0.6, s.position.z), Color(1.0, 0.3, 0.2))
				Game.camera_rig.shake(0.08)


## Keeps enemies from stacking into one blob: grid-hashed push-apart.
func _separate_enemies() -> void:
	var list := Game.enemies
	if list.size() < 2:
		return
	var grid := {}
	for e in list:
		e.push = Vector3.ZERO
		var key := Vector2i(floori(e.position.x / SEPARATION_CELL), floori(e.position.z / SEPARATION_CELL))
		if grid.has(key):
			grid[key].append(e)
		else:
			grid[key] = [e]
	for e in list:
		if e.kind == EnemyDB.Kind.BOSS:
			continue
		var cx := floori(e.position.x / SEPARATION_CELL)
		var cz := floori(e.position.z / SEPARATION_CELL)
		for ox in range(-1, 2):
			for oz in range(-1, 2):
				var arr = grid.get(Vector2i(cx + ox, cz + oz))
				if arr == null:
					continue
				for o in arr:
					if o == e:
						continue
					var dx: float = e.position.x - o.position.x
					var dz: float = e.position.z - o.position.z
					var min_d: float = e.radius + o.radius
					var d2 := dx * dx + dz * dz
					if d2 < min_d * min_d:
						if d2 < 0.0001:
							e.push += Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
						else:
							var d := sqrt(d2)
							var k := (min_d - d) / d * SEPARATION_STRENGTH
							e.push.x += dx * k
							e.push.z += dz * k
