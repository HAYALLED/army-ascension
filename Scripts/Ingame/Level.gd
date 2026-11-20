class_name Level
extends Node3D
## Root of a level scene (Scene/Ingame/Levels/Level01.tscn). Everything you
## see in the level is a node you can move in the editor:
##   Road / Arena / Barriers  - tiled assets
##   Gates                    - GatePair scenes (buffs; z = node z)
##   Traps                    - SpikeWall scenes
##   Waves                    - WaveTrigger scenes (enemy waves; z = node z)
##   Markers/BossSpawn        - where the boss stands
##   Markers/ArenaStop        - the army cannot advance past this z
##   Markers/ArmyStart        - where the army starts

@onready var boss_spawn: Marker3D = $Markers/BossSpawn
@onready var arena_stop: Marker3D = $Markers/ArenaStop
@onready var army_start: Marker3D = $Markers/ArmyStart
@onready var waves: Node3D = $Waves


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
