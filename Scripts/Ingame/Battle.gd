class_name Battle
extends Node3D
## Battle scene controller (Scene/Ingame/Battle.tscn). The scene holds the
## world: Level (road, arena, gates, traps, waves), Units, pools, Army,
## Camera and HUD. This script only wires them together and runs the
## timeline: enemy waves, spike traps, enemy separation and progress.

const SEPARATION_CELL := 2.5
const SEPARATION_STRENGTH := 5.0

@onready var level: Level = $Level
@onready var units: Node3D = $Units
@onready var army: Army = $Army
@onready var cam: CameraRig = $Camera

var boss: Boss = null

var _waves: Array = []
var _next_wave: int = 0
var _progress_t: float = 0.0


func _enter_tree() -> void:
	# Before children register their gates / traps in their own _ready.
	Game.reset_run()


func _ready() -> void:
	Game.sim_mode = "--sim" in OS.get_cmdline_user_args()
	Game.fx = $Fx
	Game.player_bullets = $PlayerBullets
	Game.enemy_bullets = $EnemyBullets
	Game.army = army
	Game.camera_rig = cam
	level.configure(LevelDB.is_mini_level(Game.level_index))
	army.position = level.army_start.position
	army.min_z = level.arena_stop.position.z
	cam.snap()

	_spawn_start_army()
	boss = EnemyDB.scene(LevelDB.boss_kind(Game.level_index)).instantiate() as Boss
	boss.position = level.boss_spawn.position
	units.add_child(boss)
	_waves = level.sorted_waves()

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
	for i in PlayerData.start_bonus_soldiers():
		list.append(T.RIFLEMAN)
	for t in list:
		if PlayerData.owns(t):
			army.add_soldier(t, PlayerData.level_of(t))
	army.rebuild_formation()
	for s in Game.soldiers:
		s.position = army.position + s.slot


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	Game.elapsed += delta
	while _next_wave < _waves.size() and army.position.z <= (_waves[_next_wave] as WaveTrigger).position.z:
		_spawn_wave(_next_wave + 1, _waves[_next_wave])
		_next_wave += 1
	_check_walls()
	_separate_enemies()
	_progress_t -= delta
	if _progress_t <= 0.0:
		_progress_t = 0.1
		Game.progress_changed.emit(clampf(-army.position.z / absf(level.boss_z()), 0.0, 1.0))


func _spawn_wave(index: int, wave: WaveTrigger) -> void:
	Game.wave_started.emit(index, _waves.size())
	Game.banner_requested.emit("WAVE %d" % index, Color(1.0, 0.8, 0.2))
	AudioManager.play("wave_horn")
	var list: Array = []
	for entry in RoundDB.wave_composition(Game.level_index, index - 1, wave.composition()):
		for i in int(entry[1]):
			list.append(int(entry[0]))
	list.shuffle()
	var base_z := army.position.z - wave.spawn_distance
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
		if e is Boss:
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
