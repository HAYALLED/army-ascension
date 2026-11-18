class_name EnemyDB
extends RefCounted
## Enemy definitions. `armor` is the fraction of incoming damage ignored.

enum Kind { BASIC, FAST, ARMORED, RANGED, ELITE, BOSS }

const DATA := {
	Kind.BASIC: {
		"model": "res://Assets/Enemy/grunt", "model_scale": 1.0, "height": 1.5,
		"name": "Grunt", "health": 75.0, "damage": 8.0, "speed": 3.6, "gold": 2,
		"shards": 1, "shard_chance": 0.06, "radius": 0.45, "attack_range": 1.1, "attack_cd": 0.9,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.85, 0.22, 0.2),
	},
	Kind.FAST: {
		"model": "res://Assets/Enemy/scout", "model_scale": 1.0, "height": 1.2,
		"name": "Scout", "health": 42.0, "damage": 6.0, "speed": 6.2, "gold": 3,
		"shards": 1, "shard_chance": 0.08, "radius": 0.36, "attack_range": 1.0, "attack_cd": 0.7,
		"armor": 0.0, "scale": 0.85, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.62, 0.12),
	},
	Kind.ARMORED: {
		"model": "res://Assets/Enemy/brute", "model_scale": 1.0, "height": 2.2,
		"name": "Brute", "health": 320.0, "damage": 14.0, "speed": 2.4, "gold": 6,
		"shards": 1, "shard_chance": 0.25, "radius": 0.7, "attack_range": 1.3, "attack_cd": 1.1,
		"armor": 0.4, "scale": 1.2, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.5, 0.53, 0.6),
	},
	Kind.RANGED: {
		"model": "res://Assets/Enemy/gunner", "model_scale": 1.0, "height": 1.6,
		"name": "Gunner", "health": 85.0, "damage": 9.0, "speed": 2.8, "gold": 4,
		"shards": 1, "shard_chance": 0.12, "radius": 0.42, "attack_range": 11.0, "attack_cd": 1.5,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 16.0,
		"color": Color(0.6, 0.28, 0.8),
	},
	Kind.ELITE: {
		"model": "res://Assets/Enemy/warlord", "model_scale": 1.0, "height": 3.6,
		"name": "Warlord", "health": 1200.0, "damage": 28.0, "speed": 2.8, "gold": 25,
		"shards": 3, "shard_chance": 1.0, "radius": 0.85, "attack_range": 1.6, "attack_cd": 1.0,
		"armor": 0.25, "scale": 1.7, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.7, 0.08, 0.12),
	},
	Kind.BOSS: {
		"model": "res://Assets/Enemy/boss_colossus", "model_scale": 1.0, "height": 6.8,
		"name": "IRON COLOSSUS", "health": 27000.0, "damage": 30.0, "speed": 3.2, "gold": 250,
		"shards": 20, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 2.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.37, 0.45),
	},
}
