class_name EnemyDB
extends RefCounted
## Enemy definitions. `armor` is the fraction of incoming damage ignored.

enum Kind { BASIC, FAST, ARMORED, RANGED, ELITE, BOSS, KAMIKAZE, SNIPER, MEDIC }

## Kinds a boss / mini boss reinforcement wave picks from (uniform random).
const MINION_POOL := [
	Kind.BASIC, Kind.FAST, Kind.ARMORED, Kind.RANGED,
	Kind.ELITE, Kind.KAMIKAZE, Kind.SNIPER, Kind.MEDIC,
]

static var _scenes: Dictionary = {}


## Enemy scene of a kind (loaded lazily; scenes live in Scene/Enemy/Types).
static func random_minion_kind() -> int:
	return MINION_POOL[randi() % MINION_POOL.size()]


static func scene(kind: int) -> PackedScene:
	if not _scenes.has(kind):
		_scenes[kind] = load(DATA[kind]["scene"])
	return _scenes[kind]


const DATA := {
	Kind.BASIC: {
		"scene": "res://Scene/Enemy/Types/Grunt.tscn", "height": 1.5,
		"name": "Grunt", "health": 75.0, "damage": 8.0, "speed": 3.6, "gold": 2,
		"shards": 1, "shard_chance": 0.06, "radius": 0.45, "attack_range": 1.1, "attack_cd": 0.9,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.85, 0.22, 0.2),
	},
	Kind.FAST: {
		"scene": "res://Scene/Enemy/Types/Scout.tscn", "height": 1.2,
		"name": "Scout", "health": 42.0, "damage": 6.0, "speed": 6.2, "gold": 3,
		"shards": 1, "shard_chance": 0.08, "radius": 0.36, "attack_range": 1.0, "attack_cd": 0.7,
		"armor": 0.0, "scale": 0.85, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.62, 0.12),
	},
	Kind.ARMORED: {
		"scene": "res://Scene/Enemy/Types/Brute.tscn", "height": 2.2,
		"name": "Brute", "health": 320.0, "damage": 14.0, "speed": 2.4, "gold": 6,
		"shards": 1, "shard_chance": 0.25, "radius": 0.7, "attack_range": 1.3, "attack_cd": 1.1,
		"armor": 0.4, "scale": 1.2, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.5, 0.53, 0.6),
	},
	Kind.RANGED: {
		"scene": "res://Scene/Enemy/Types/Gunner.tscn", "height": 1.6,
		"name": "Gunner", "health": 85.0, "damage": 9.0, "speed": 2.8, "gold": 4,
		"shards": 1, "shard_chance": 0.12, "radius": 0.42, "attack_range": 11.0, "attack_cd": 1.5,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 16.0,
		"color": Color(0.6, 0.28, 0.8),
	},
	Kind.ELITE: {
		"scene": "res://Scene/Enemy/Types/Warlord.tscn", "height": 3.6,
		"name": "Warlord", "health": 1200.0, "damage": 28.0, "speed": 2.8, "gold": 25,
		"shards": 3, "shard_chance": 1.0, "radius": 0.85, "attack_range": 1.6, "attack_cd": 1.0,
		"armor": 0.25, "scale": 1.7, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.7, 0.08, 0.12),
	},
	Kind.BOSS: {
		"scene": "res://Scene/Enemy/Types/Boss.tscn", "height": 6.8,
		"name": "IRON COLOSSUS", "health": 25000.0, "damage": 30.0, "speed": 3.2, "gold": 250,
		"shards": 20, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 2.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.37, 0.45),
	},
	## Runs at the nearest soldier and explodes (area damage). Killed first = no blast.
	Kind.KAMIKAZE: {
		"scene": "res://Scene/Enemy/Types/Kamikaze.tscn", "height": 1.3,
		"name": "Kamikaze", "health": 45.0, "damage": 32.0, "speed": 7.2, "gold": 4,
		"shards": 1, "shard_chance": 0.1, "radius": 0.4, "attack_range": 1.6, "attack_cd": 1.0,
		"armor": 0.0, "scale": 0.85, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.45, 0.1),
	},
	## Stays far away and fires slow, hard-hitting shots.
	Kind.SNIPER: {
		"scene": "res://Scene/Enemy/Types/SniperEnemy.tscn", "height": 1.7,
		"name": "Marksman", "health": 70.0, "damage": 22.0, "speed": 2.2, "gold": 6,
		"shards": 1, "shard_chance": 0.15, "radius": 0.4, "attack_range": 26.0, "attack_cd": 2.8,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 46.0,
		"proj_kind": ProjectilePool.KIND_SNIPER,
		"color": Color(0.3, 0.75, 0.35),
	},
	## Hangs back and heals wounded enemies around it. Kill it first.
	Kind.MEDIC: {
		"scene": "res://Scene/Enemy/Types/MedicEnemy.tscn", "height": 1.5,
		"name": "Field Medic", "health": 90.0, "damage": 0.0, "speed": 3.0, "gold": 7,
		"shards": 1, "shard_chance": 0.2, "radius": 0.42, "attack_range": 1.0, "attack_cd": 1.0,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.9, 0.5),
	},
}
