class_name Level
extends Node3D
## Root of a level scene (Scene/Ingame/Levels/Level01.tscn). Everything you
## see in the level is a node you can move in the editor:
##   Road / Barriers          - tiled assets
##   Gates                    - GatePair scenes (buffs; z = node z)
##   Traps                    - SpikeWall scenes
##   Waves                    - WaveTrigger scenes (enemy waves; z = node z)
##   Arena + Markers/BossSpawn, Markers/ArenaStop        - boss arena (levels 5, 10, ...)
##   MiniArena + Markers/MiniBossSpawn, Markers/MiniArenaStop - mini boss arena (all other levels)
##   Markers/ArmyStart        - where the army starts
## Battle calls configure() once: the arena that is not needed is removed, and
## `boss_spawn` / `arena_stop` point at the markers of the arena that stays.

@onready var army_start: Marker3D = $Markers/ArmyStart
@onready var waves: Node3D = $Waves
@onready var boss_arena: Node3D = $Arena
@onready var mini_arena: Node3D = $MiniArena

## Where the boss / mini boss stands (set by configure, boss arena by default).
var boss_spawn: Marker3D = null
## The army cannot advance past this z.
var arena_stop: Marker3D = null
var is_mini: bool = false


func _ready() -> void:
	mini_arena.visible = false
	boss_spawn = $Markers/BossSpawn
	arena_stop = $Markers/ArenaStop


## Picks the arena for this level. `use_mini` = mini boss level. Call once, before the battle starts.
func configure(use_mini: bool) -> void:
	is_mini = use_mini
	if use_mini:
		boss_arena.queue_free()
		mini_arena.visible = true
		boss_spawn = $Markers/MiniBossSpawn
		arena_stop = $Markers/MiniArenaStop
	else:
		mini_arena.queue_free()


## Wave triggers sorted by z, nearest to the start first.
func sorted_waves() -> Array:
	var list: Array = []
	for w in waves.get_children():
		if w is WaveTrigger:
			list.append(w)
	list.sort_custom(func(a: WaveTrigger, b: WaveTrigger) -> bool: return a.position.z > b.position.z)
	return list


func boss_z() -> float:
	return boss_spawn.position.z
