extends Node
## Global event bus, run state and system registry (autoload "Game").
## Soldiers and enemies live directly under Battle/Units at identity
## transform, so `position` == world position everywhere.

@warning_ignore("unused_signal")
signal army_changed(count: int, hp: float, max_hp: float)
signal gold_changed(total: int)
signal shards_changed(total: int)
signal kills_changed(total: int)
signal buffs_changed(damage_mult: float, rate_mult: float)
@warning_ignore("unused_signal")
signal wave_started(index: int, total: int)
@warning_ignore("unused_signal")
signal boss_spawned(boss_name: String, max_hp: float)
@warning_ignore("unused_signal")
signal boss_hp_changed(hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal boss_defeated()
@warning_ignore("unused_signal")
signal progress_changed(ratio: float)
@warning_ignore("unused_signal")
signal banner_requested(text: String, color: Color)
signal state_changed(new_state: int)
signal battle_won()
signal battle_lost()
## The army is wiped and an ad revive is on offer (state REVIVE, tree paused).
signal revive_offered()

enum State { LOADING, PLAYING, PAUSED, WON, LOST, REVIVE }

const MAX_SOLDIERS := 60

var state: int = State.LOADING
var level_index: int = 1
var gold: int = 0
var shards: int = 0
var run_shards: Dictionary = {}   # SoldierDB.Type -> shards earned this battle
var kills: int = 0
## Chest the won battle dropped ({} = none) and the home slot it went into (-1 = slots were full).
var dropped_chest: Dictionary = {}
var dropped_slot: int = -1
## Most soldiers the army had at one time this run (an ad revive brings back this many).
var peak_soldiers: int = 0
var elapsed: float = 0.0
var damage_buff: float = 1.0
var rate_buff: float = 1.0
var sim_mode: bool = false
## Gold credited to the profile when the battle ended (0 until then).
var credited_gold: int = 0
## True after the end-of-level "double gold" ad was claimed.
var gold_doubled: bool = false
## True after this run used its one ad revive.
var revive_used: bool = false

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
	run_shards.clear()
	kills = 0
	dropped_chest = {}
	dropped_slot = -1
	peak_soldiers = 0
	elapsed = 0.0
	credited_gold = 0
	gold_doubled = false
	revive_used = false
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
	if state == State.WON or state == State.LOST or state == State.REVIVE:
		return
	if not won and can_revive():
		get_tree().paused = true
		_set_state(State.REVIVE)
		revive_offered.emit()
		return
	_finish_battle(won)


## True when a defeat may be answered with an ad revive (once per run, never in --sim).
func can_revive() -> bool:
	return not revive_used and not sim_mode and AdService.is_available()


## Soldiers an ad revive brings back: the biggest army of this run, never fewer than REVIVE_SOLDIERS.
func revive_count() -> int:
	return clampi(maxi(peak_soldiers, RewardDB.REVIVE_SOLDIERS), 1, MAX_SOLDIERS)


## Ad watched: brings soldiers back, clears the enemies around the army and resumes the battle.
func revive() -> void:
	if state != State.REVIVE or army == null:
		return
	revive_used = true
	army.revive(revive_count())
	add_damage_buff(RewardDB.REVIVE_DAMAGE_BUFF)
	get_tree().paused = false
	_set_state(State.PLAYING)


## Player refused the revive: the defeat becomes final.
func decline_revive() -> void:
	if state == State.REVIVE:
		revive_used = true
		_finish_battle(false)


## True while the result popup may offer the "double gold" ad.
func can_double_gold() -> bool:
	return (state == State.WON or state == State.LOST) and credited_gold > 0 \
		and not gold_doubled and not sim_mode and AdService.is_available()


## Ad watched: credits the battle gold a second time. Returns false when not allowed.
func double_gold() -> bool:
	if not can_double_gold():
		return false
	gold_doubled = true
	PlayerData.add_gold(credited_gold)
	SaveManager.save_now()
	return true


func _finish_battle(won: bool) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_credit_rewards(won)
	if won:
		PlayerData.complete_level(level_index)
		_drop_chest()
	MissionManager.record_battle(won, kills, shards)
	SaveManager.save_now()
	_set_state(State.WON if won else State.LOST)
	if won:
		battle_won.emit()
	else:
		battle_lost.emit()


## Every won level drops one chest (60% wood, 30% silver, 10% gold) into a free home slot.
func _drop_chest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	dropped_chest = ChestDB.roll(ChestDB.roll_tier(rng), rng)
	dropped_slot = PlayerData.add_chest(dropped_chest)


## Gold the player really receives for this battle: all of it on victory, half on defeat,
## times the Battle Income upgrade (Upgrades tab).
func final_gold(won: bool) -> int:
	var base := gold if won else int(gold * 0.5)
	return int(round(float(base) * PlayerData.income_mult()))


## Battle rewards go to the player's profile.
func _credit_rewards(won: bool) -> void:
	credited_gold = final_gold(won)
	PlayerData.add_gold(credited_gold)
	for t in run_shards:
		PlayerData.add_shards(t, int(run_shards[t]))


## Sets the level the next battle plays. Only beaten levels and the current unbeaten
## level (PlayerData.unlocked_level) are allowed. Returns false and changes nothing otherwise.
func select_level(level: int) -> bool:
	if level < 1 or level > PlayerData.unlocked_level():
		return false
	level_index = level
	return true


## Moves to the next level after a win (never past the unlocked one).
func next_level() -> void:
	level_index = mini(level_index + 1, PlayerData.unlocked_level())


func goto_menu() -> void:
	reset_run()
	get_tree().change_scene_to_file("res://Scene/Menus/MainMenu.tscn")


func goto_battle() -> void:
	reset_run()
	get_tree().change_scene_to_file("res://Scene/Menus/Loading.tscn")


func restart() -> void:
	reset_run()
	get_tree().reload_current_scene()


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


## Shards drop for a random soldier class. Returns the class that got them.
func add_shards(amount: int) -> int:
	if amount <= 0:
		return -1
	var type := SoldierDB.random_type()
	run_shards[type] = int(run_shards.get(type, 0)) + amount
	shards += amount
	shards_changed.emit(shards)
	return type


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
