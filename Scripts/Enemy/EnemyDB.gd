class_name EnemyDB
extends RefCounted
## Enemy definitions. `armor` is the fraction of incoming damage ignored.

## New kinds are only ever appended: scenes store the kind as its int value.
enum Kind { BASIC, FAST, ARMORED, RANGED, ELITE, BOSS, KAMIKAZE, SNIPER, MEDIC,
	MINI_CRUSHER, MINI_GATLING, MINI_BOMBER, MINI_COMMANDER,
	MORTAR, BLINDER, WEAKENER, BREACHER, SHOTGUNNER,
	BOSS_YETI, BOSS_DRAKE,
	MINI_ICEBREAKER, MINI_BLIZZARD, MINI_SLED, MINI_FROST_COMMANDER,
	MINI_FORGE_SMASHER, MINI_FLAMECASTER, MINI_LAVA_MORTAR, MINI_FOUNDRY_OVERSEER }

## Full boss fights: one per round (levels 5, 10, 15).
const FULL_BOSS_KINDS := [Kind.BOSS, Kind.BOSS_YETI, Kind.BOSS_DRAKE]
## Every kind that uses Boss.gd (full bosses and mini bosses).
const BOSS_KINDS := [
	Kind.BOSS, Kind.BOSS_YETI, Kind.BOSS_DRAKE,
	Kind.MINI_CRUSHER, Kind.MINI_GATLING, Kind.MINI_BOMBER, Kind.MINI_COMMANDER,
	Kind.MINI_ICEBREAKER, Kind.MINI_BLIZZARD, Kind.MINI_SLED, Kind.MINI_FROST_COMMANDER,
	Kind.MINI_FORGE_SMASHER, Kind.MINI_FLAMECASTER, Kind.MINI_LAVA_MORTAR, Kind.MINI_FOUNDRY_OVERSEER,
]

## Kinds a boss / mini boss reinforcement wave picks from (uniform random).
const MINION_POOL := [
	Kind.BASIC, Kind.FAST, Kind.ARMORED, Kind.RANGED,
	Kind.ELITE, Kind.KAMIKAZE, Kind.SNIPER, Kind.MEDIC,
]

static var _scenes: Dictionary = {}


## True for every boss and mini boss kind (they all use Boss.gd).
static func is_boss_kind(kind: int) -> bool:
	return BOSS_KINDS.has(kind)


## Model of `kind` for round 2 / 3 (res://Assets/Enemy/<model>_r2.glb), or "" when the kind
## has no variant for that round (the scene's own round 1 model is then kept).
static func round_model_path(kind: int, round_number: int) -> String:
	if round_number <= 1 or not DATA.has(kind) or not DATA[kind].has("model"):
		return ""
	var path := "res://Assets/Enemy/%s_r%d.glb" % [DATA[kind]["model"], round_number]
	return path if ResourceLoader.exists(path) else ""


## Enemy scene of a kind (loaded lazily; scenes live in Scene/Enemy/Types).
static func random_minion_kind() -> int:
	return MINION_POOL[randi() % MINION_POOL.size()]


static func scene(kind: int) -> PackedScene:
	if not _scenes.has(kind):
		_scenes[kind] = load(DATA[kind]["scene"])
	return _scenes[kind]


const DATA := {
	Kind.BASIC: {
		"model": "grunt", "scene": "res://Scene/Enemy/Types/Grunt.tscn", "height": 1.5,
		"name": "Grunt", "health": 75.0, "damage": 8.0, "speed": 3.6, "gold": 2,
		"shards": 1, "shard_chance": 0.06, "radius": 0.45, "attack_range": 1.1, "attack_cd": 0.9,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.85, 0.22, 0.2),
	},
	Kind.FAST: {
		"model": "scout", "scene": "res://Scene/Enemy/Types/Scout.tscn", "height": 1.2,
		"name": "Scout", "health": 42.0, "damage": 6.0, "speed": 6.2, "gold": 3,
		"shards": 1, "shard_chance": 0.08, "radius": 0.36, "attack_range": 1.0, "attack_cd": 0.7,
		"armor": 0.0, "scale": 0.85, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.62, 0.12),
	},
	Kind.ARMORED: {
		"model": "brute", "scene": "res://Scene/Enemy/Types/Brute.tscn", "height": 2.2,
		"name": "Brute", "health": 320.0, "damage": 14.0, "speed": 2.4, "gold": 6,
		"shards": 1, "shard_chance": 0.25, "radius": 0.7, "attack_range": 1.3, "attack_cd": 1.1,
		"armor": 0.4, "scale": 1.2, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.5, 0.53, 0.6),
	},
	Kind.RANGED: {
		"model": "gunner", "scene": "res://Scene/Enemy/Types/Gunner.tscn", "height": 1.6,
		"name": "Gunner", "health": 85.0, "damage": 9.0, "speed": 2.8, "gold": 4,
		"shards": 1, "shard_chance": 0.12, "radius": 0.42, "attack_range": 11.0, "attack_cd": 1.5,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 16.0,
		"color": Color(0.6, 0.28, 0.8),
	},
	Kind.ELITE: {
		"model": "warlord", "scene": "res://Scene/Enemy/Types/Warlord.tscn", "height": 3.6,
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
		"model": "kamikaze", "scene": "res://Scene/Enemy/Types/Kamikaze.tscn", "height": 1.3,
		"name": "Kamikaze", "health": 45.0, "damage": 32.0, "speed": 7.2, "gold": 4,
		"shards": 1, "shard_chance": 0.1, "radius": 0.4, "attack_range": 1.6, "attack_cd": 1.0,
		"armor": 0.0, "scale": 0.85, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.45, 0.1),
	},
	## Stays far away and fires slow, hard-hitting shots.
	Kind.SNIPER: {
		"model": "sniper_enemy", "scene": "res://Scene/Enemy/Types/SniperEnemy.tscn", "height": 1.7,
		"name": "Marksman", "health": 70.0, "damage": 22.0, "speed": 2.2, "gold": 6,
		"shards": 1, "shard_chance": 0.15, "radius": 0.4, "attack_range": 26.0, "attack_cd": 2.8,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 46.0,
		"proj_kind": ProjectilePool.KIND_SNIPER,
		"color": Color(0.3, 0.75, 0.35),
	},
	## Hangs back and heals wounded enemies around it. Kill it first.
	Kind.MEDIC: {
		"model": "medic_enemy", "scene": "res://Scene/Enemy/Types/MedicEnemy.tscn", "height": 1.5,
		"name": "Field Medic", "health": 90.0, "damage": 0.0, "speed": 3.0, "gold": 7,
		"shards": 1, "shard_chance": 0.2, "radius": 0.42, "attack_range": 1.0, "attack_cd": 1.0,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.9, 0.5),
	},
	## ---- Mini bosses (end of every level that is not a boss level) ----------
	## Behaviour per kind lives in Boss.CONFIGS. Numbers here are starting balance.
	Kind.MINI_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniCrusher.tscn", "height": 4.2,
		"name": "CRUSHER", "health": 5000.0, "damage": 24.0, "speed": 3.0, "gold": 80,
		"shards": 6, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.85, 0.45, 0.17),
	},
	Kind.MINI_GATLING: {
		"scene": "res://Scene/Enemy/Types/MiniGatling.tscn", "height": 3.8,
		"name": "GATLING", "health": 4200.0, "damage": 20.0, "speed": 3.0, "gold": 80,
		"shards": 6, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.12, 0.64, 0.6),
	},
	Kind.MINI_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniBomber.tscn", "height": 3.6,
		"name": "BOMBER CHIEF", "health": 4600.0, "damage": 22.0, "speed": 3.2, "gold": 85,
		"shards": 6, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.05, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.5, 0.2, 0.75),
	},
	Kind.MINI_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniCommander.tscn", "height": 4.6,
		"name": "COMMANDER", "health": 6200.0, "damage": 26.0, "speed": 2.8, "gold": 90,
		"shards": 7, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.3, 0.48, 0.2),
	},
	## ---- Round 1 additions (mortar level 2+, blinder 3+, weakener 4+) and the extra round 2 / 3 roster ----
	## Rounds: levels 1-5, 6-10, 11-15. See RoundDB for who appears where.
	## Lobs shells that land on a marked circle after a short delay. Kill it from range.
	Kind.MORTAR: {
		"model": "mortar", "scene": "res://Scene/Enemy/Types/Mortar.tscn", "height": 1.7,
		"name": "Mortar", "health": 100.0, "damage": 28.0, "speed": 2.0, "gold": 7,
		"shards": 1, "shard_chance": 0.2, "radius": 0.5, "attack_range": 24.0, "attack_cd": 3.8,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 0.0,
		"color": Color(0.85, 0.55, 0.2),
	},
	## Flashes a group of soldiers: blinded soldiers miss a lot for a few seconds.
	Kind.BLINDER: {
		"model": "blinder", "scene": "res://Scene/Enemy/Types/Blinder.tscn", "height": 1.6,
		"name": "Blinder", "health": 90.0, "damage": 0.0, "speed": 2.8, "gold": 7,
		"shards": 1, "shard_chance": 0.2, "radius": 0.45, "attack_range": 15.0, "attack_cd": 7.0,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.9, 0.3),
	},
	## Curses a group of soldiers: weakened soldiers deal much less damage for a few seconds.
	Kind.WEAKENER: {
		"model": "weakener", "scene": "res://Scene/Enemy/Types/Weakener.tscn", "height": 1.6,
		"name": "Weakener", "health": 90.0, "damage": 0.0, "speed": 2.8, "gold": 7,
		"shards": 1, "shard_chance": 0.2, "radius": 0.5, "attack_range": 15.0, "attack_cd": 8.0,
		"armor": 0.0, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.6, 0.35, 0.8),
	},
	## Tough, slow tank with a breach cannon: one heavy slug at medium range.
	Kind.BREACHER: {
		"model": "breacher", "scene": "res://Scene/Enemy/Types/Breacher.tscn", "height": 2.0,
		"name": "Breacher", "health": 380.0, "damage": 24.0, "speed": 2.6, "gold": 8,
		"shards": 1, "shard_chance": 0.25, "radius": 0.85, "attack_range": 9.0, "attack_cd": 2.4,
		"armor": 0.3, "scale": 1.0, "ranged": true, "proj_speed": 20.0,
		"proj_kind": ProjectilePool.KIND_BOSS,
		"color": Color(0.55, 0.5, 0.45),
	},
	## Short range scatter gun: a fan of 5 pellets.
	Kind.SHOTGUNNER: {
		"model": "shotgunner", "scene": "res://Scene/Enemy/Types/Shotgunner.tscn", "height": 1.5,
		"name": "Shotgunner", "health": 110.0, "damage": 6.0, "speed": 3.4, "gold": 5,
		"shards": 1, "shard_chance": 0.1, "radius": 0.42, "attack_range": 8.0, "attack_cd": 1.8,
		"armor": 0.0, "scale": 1.0, "ranged": true, "proj_speed": 24.0,
		"color": Color(0.9, 0.35, 0.3),
	},
	## ---- Round 2 (ice) and round 3 (lava) bosses and mini bosses. Behaviour per kind lives in Boss.CONFIGS. ----
	Kind.BOSS_YETI: {
		"scene": "res://Scene/Enemy/Types/BossYeti.tscn", "height": 8.0,
		"name": "YETI KING", "health": 30000.0, "damage": 32.0, "speed": 3.2, "gold": 400,
		"shards": 30, "shard_chance": 1.0, "radius": 2.1, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.75, 0.88, 1.0),
	},
	Kind.BOSS_DRAKE: {
		"scene": "res://Scene/Enemy/Types/BossDrake.tscn", "height": 8.0,
		"name": "MAGMA DRAKE", "health": 36000.0, "damage": 36.0, "speed": 3.4, "gold": 600,
		"shards": 40, "shard_chance": 1.0, "radius": 2.3, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.2, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.42, 0.1),
	},
	Kind.MINI_ICEBREAKER: {
		"scene": "res://Scene/Enemy/Types/MiniIcebreaker.tscn", "height": 4.5,
		"name": "ICEBREAKER", "health": 5800.0, "damage": 26.0, "speed": 3.0, "gold": 100,
		"shards": 8, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.5, 0.78, 0.97),
	},
	Kind.MINI_BLIZZARD: {
		"scene": "res://Scene/Enemy/Types/MiniBlizzard.tscn", "height": 4.5,
		"name": "BLIZZARD GUNNER", "health": 4900.0, "damage": 22.0, "speed": 3.0, "gold": 100,
		"shards": 8, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.62, 0.95, 1.0),
	},
	Kind.MINI_SLED: {
		"scene": "res://Scene/Enemy/Types/MiniSled.tscn", "height": 4.5,
		"name": "SLED RIDER", "health": 5300.0, "damage": 24.0, "speed": 3.6, "gold": 105,
		"shards": 8, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.05, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.6, 0.24),
	},
	Kind.MINI_FROST_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniFrostCommander.tscn", "height": 4.5,
		"name": "FROST COMMANDER", "health": 7000.0, "damage": 28.0, "speed": 2.8, "gold": 110,
		"shards": 9, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.86, 0.9, 0.96),
	},
	Kind.MINI_FORGE_SMASHER: {
		"scene": "res://Scene/Enemy/Types/MiniForgeSmasher.tscn", "height": 4.5,
		"name": "FORGE SMASHER", "health": 6600.0, "damage": 30.0, "speed": 3.0, "gold": 130,
		"shards": 10, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.42, 0.1),
	},
	Kind.MINI_FLAMECASTER: {
		"scene": "res://Scene/Enemy/Types/MiniFlamecaster.tscn", "height": 4.5,
		"name": "FLAMECASTER", "health": 5600.0, "damage": 26.0, "speed": 3.0, "gold": 130,
		"shards": 10, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.0, 0.76, 0.1),
	},
	Kind.MINI_LAVA_MORTAR: {
		"scene": "res://Scene/Enemy/Types/MiniLavaMortar.tscn", "height": 4.5,
		"name": "LAVA MORTAR", "health": 6000.0, "damage": 28.0, "speed": 2.8, "gold": 130,
		"shards": 10, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.1, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.48, 0.12, 0.12),
	},
	Kind.MINI_FOUNDRY_OVERSEER: {
		"scene": "res://Scene/Enemy/Types/MiniFoundryOverseer.tscn", "height": 4.5,
		"name": "FOUNDRY OVERSEER", "health": 8000.0, "damage": 30.0, "speed": 2.8, "gold": 135,
		"shards": 10, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.2, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.69, 0.49, 1.0),
	},
}
