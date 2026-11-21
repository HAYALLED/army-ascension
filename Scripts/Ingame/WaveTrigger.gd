class_name WaveTrigger
extends Node3D
## An enemy wave. When the army reaches this node's z, the enemies spawn
## `spawn_distance` ahead of the army. Counts are editable in the inspector.

@export var basic: int = 0
@export var fast: int = 0
@export var armored: int = 0
@export var ranged: int = 0
@export var elite: int = 0
@export var kamikaze: int = 0
@export var sniper: int = 0
@export var medic: int = 0
@export var spawn_distance: float = 40.0


## [[kind, count], ...] for the spawner.
func composition() -> Array:
	return [
		[EnemyDB.Kind.BASIC, basic], [EnemyDB.Kind.FAST, fast], [EnemyDB.Kind.ARMORED, armored],
		[EnemyDB.Kind.RANGED, ranged], [EnemyDB.Kind.ELITE, elite],
		[EnemyDB.Kind.KAMIKAZE, kamikaze], [EnemyDB.Kind.SNIPER, sniper], [EnemyDB.Kind.MEDIC, medic],
	]
