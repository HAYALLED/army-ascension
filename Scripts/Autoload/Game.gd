extends Node
## Global event bus, run state and system registry (autoload "Game").
## Soldiers and enemies live directly under Battle/Units at identity
## transform, so `position` == world position everywhere.

signal army_changed(count: int, hp: float, max_hp: float)
signal gold_changed(total: int)
signal shards_changed(total: int)
signal kills_changed(total: int)
signal buffs_changed(damage_mult: float, rate_mult: float)
signal wave_started(index: int, total: int)
signal boss_spawned(boss_name: String, max_hp: float)
signal boss_hp_changed(hp: float, max_hp: float)
signal boss_defeated()
signal progress_changed(ratio: float)
signal banner_requested(text: String, color: Color)
signal state_changed(new_state: int)
signal battle_won()
signal battle_lost()

enum State { LOADING, PLAYING, PAUSED, WON, LOST }

const MAX_SOLDIERS := 60

var state: int = State.LOADING
var level_index: int = 1
var gold: int = 0
var shards: int = 0
var kills: int = 0
var elapsed: float = 0.0
var damage_buff: float = 1.0
var rate_buff: float = 1.0
var sim_mode: bool = false

# Registries (filled by Battle and entities).
var enemies: Array[Enemy] = []
var soldiers: Array[Soldier] = []
var walls: Array[Dictionary] = []
var gates: Array[GatePair] = []
var army: Army = null
var player_bullets: ProjectilePool = null
var enemy_bullets: ProjectilePool = null
var fx: Fx = null
var camera_rig: CameraRig = null


func reset_run() -> void:
	gold = 0
	shards = 0
	kills = 0
	elapsed = 0.0
	damage_buff = 1.0
	rate_buff = 1.0
	enemies.clear()
	soldiers.clear()
	walls.clear()
	gates.clear()
	army = null
	player_bullets = null
	enemy_bullets = null
	fx = null
	camera_rig = null
	Engine.time_scale = 1.0
	get_tree().paused = false
	state = State.LOADING


func difficulty_scale() -> float:
	return 1.0 + 0.2 * float(level_index - 1)


func start_battle() -> void:
	_set_state(State.PLAYING)


func set_paused(paused: bool) -> void:
	if paused and state == State.PLAYING:
		get_tree().paused = true
		_set_state(State.PAUSED)
	elif not paused and state == State.PAUSED:
		get_tree().paused = false
		_set_state(State.PLAYING)


func end_battle(won: bool) -> void:
	if state == State.WON or state == State.LOST:
		return
	get_tree().paused = false
	Engine.time_scale = 1.0
	_set_state(State.WON if won else State.LOST)
	if won:
		battle_won.emit()
	else:
		battle_lost.emit()


func restart() -> void:
	reset_run()
	get_tree().reload_current_scene()


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount
	shards_changed.emit(shards)


func add_kill() -> void:
	kills += 1
	kills_changed.emit(kills)


func add_damage_buff(amount: float) -> void:
	damage_buff += amount
	buffs_changed.emit(damage_buff, rate_buff)


func add_rate_buff(amount: float) -> void:
	rate_buff += amount
	buffs_changed.emit(damage_buff, rate_buff)


func _set_state(new_state: int) -> void:
	state = new_state
	state_changed.emit(new_state)
