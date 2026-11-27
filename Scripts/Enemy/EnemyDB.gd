class_name EnemyDB
extends RefCounted
## Enemy definitions. `armor` is the fraction of incoming damage ignored.

## New kinds are only ever appended: scenes store the kind as its int value.
enum Kind { BASIC, FAST, ARMORED, RANGED, ELITE, BOSS, KAMIKAZE, SNIPER, MEDIC,
	MINI_CRUSHER, MINI_GATLING, MINI_BOMBER, MINI_COMMANDER,
	MORTAR, BLINDER, WEAKENER, BREACHER, SHOTGUNNER,
	BOSS_YETI, BOSS_DRAKE,
	MINI_ICEBREAKER, MINI_BLIZZARD, MINI_SLED, MINI_FROST_COMMANDER,
	MINI_FORGE_SMASHER, MINI_FLAMECASTER, MINI_LAVA_MORTAR, MINI_FOUNDRY_OVERSEER,
	## Round 4 (graveyard)
	MINI_GRAVEDIGGER, MINI_COFFIN_CANNON, MINI_PUMPKIN_BOMBER, MINI_LICH_COMMANDER, BOSS_BONE_REAPER,
	## Round 5 (desert)
	MINI_SARCOPHAGUS_SMASHER, MINI_ANUBIS_GUNNER, MINI_SCARAB_BOMBER, MINI_PHARAOH_COMMANDER, BOSS_GOLDEN_SPHINX,
	## Round 6 (swamp)
	MINI_BOG_BRUTE, MINI_CAULDRON_WITCH, MINI_TOADSTOOL_BOMBER, MINI_HAG_COMMANDER, BOSS_BOG_HYDRA,
	## Round 7 (junkyard)
	MINI_WRECKER, MINI_TURBINE_GUNNER, MINI_DUMPSTER_BOMBER, MINI_FOREMAN_COMMANDER, BOSS_SCRAP_TITAN,
	## Round 8 (neon city)
	MINI_NEON_ENFORCER, MINI_LASER_DJ, MINI_DRONE_CARRIER, MINI_NEON_OVERLORD, BOSS_NEON_SHOGUN,
	## Round 9 (space station)
	MINI_AIRLOCK_CRUSHER, MINI_SATELLITE_GUNNER, MINI_MINE_BOMBER, MINI_STATION_COMMANDER, BOSS_ORBITAL_GUARDIAN,
	## Round 10 (insect hive)
	MINI_MANDIBLE_CRUSHER, MINI_WASP_GUNNER, MINI_LADYBUG_BOMBER, MINI_MANTIS_COMMANDER, BOSS_HIVE_QUEEN,
	## Round 11 (toxic waste)
	MINI_SLUDGE_SMASHER, MINI_HAZMAT_GUNNER, MINI_BARREL_BOMBER, MINI_MUTANT_COMMANDER, BOSS_MUTANT_BEHEMOTH,
	## Round 12 (crystal cave)
	MINI_GEODE_CRUSHER, MINI_PRISM_GUNNER, MINI_BAT_BOMBER, MINI_GEM_COMMANDER, BOSS_PRISM_GUARDIAN,
	## Round 13 (pirate)
	MINI_ANCHOR_SMASHER, MINI_BROADSIDE_GUNNER, MINI_POWDER_KEG_BOMBER, MINI_FIRST_MATE, BOSS_IRON_GALLEON,
	## Round 14 (ghost ship)
	MINI_BARNACLE_CRUSHER, MINI_GHOST_GUNNER, MINI_BUOY_BOMBER, MINI_PHANTOM_ADMIRAL, BOSS_SPECTRAL_ADMIRAL,
	## Round 15 (deep sea)
	MINI_CRAB_CRUSHER, MINI_ANGLER_GUNNER, MINI_PUFFER_BOMBER, MINI_TRITON_COMMANDER, BOSS_KRAKEN,
	## Round 16 (void)
	MINI_OBSIDIAN_CRUSHER, MINI_ECLIPSE_GUNNER, MINI_METEOR_BOMBER, MINI_VOID_HERALD, BOSS_VOID_EMPEROR }

## Full boss fights: one per round (levels 5, 10, 15 ... 80).
const FULL_BOSS_KINDS := [
	Kind.BOSS, Kind.BOSS_YETI, Kind.BOSS_DRAKE,
	Kind.BOSS_BONE_REAPER,
	Kind.BOSS_GOLDEN_SPHINX,
	Kind.BOSS_BOG_HYDRA,
	Kind.BOSS_SCRAP_TITAN,
	Kind.BOSS_NEON_SHOGUN,
	Kind.BOSS_ORBITAL_GUARDIAN,
	Kind.BOSS_HIVE_QUEEN,
	Kind.BOSS_MUTANT_BEHEMOTH,
	Kind.BOSS_PRISM_GUARDIAN,
	Kind.BOSS_IRON_GALLEON,
	Kind.BOSS_SPECTRAL_ADMIRAL,
	Kind.BOSS_KRAKEN,
	Kind.BOSS_VOID_EMPEROR,
]
## Every kind that uses Boss.gd (full bosses and mini bosses).
const BOSS_KINDS := [
	Kind.BOSS, Kind.BOSS_YETI, Kind.BOSS_DRAKE,
	Kind.MINI_CRUSHER, Kind.MINI_GATLING, Kind.MINI_BOMBER, Kind.MINI_COMMANDER,
	Kind.MINI_ICEBREAKER, Kind.MINI_BLIZZARD, Kind.MINI_SLED, Kind.MINI_FROST_COMMANDER,
	Kind.MINI_FORGE_SMASHER, Kind.MINI_FLAMECASTER, Kind.MINI_LAVA_MORTAR, Kind.MINI_FOUNDRY_OVERSEER,
	Kind.MINI_GRAVEDIGGER, Kind.MINI_COFFIN_CANNON, Kind.MINI_PUMPKIN_BOMBER, Kind.MINI_LICH_COMMANDER, Kind.BOSS_BONE_REAPER,
	Kind.MINI_SARCOPHAGUS_SMASHER, Kind.MINI_ANUBIS_GUNNER, Kind.MINI_SCARAB_BOMBER, Kind.MINI_PHARAOH_COMMANDER, Kind.BOSS_GOLDEN_SPHINX,
	Kind.MINI_BOG_BRUTE, Kind.MINI_CAULDRON_WITCH, Kind.MINI_TOADSTOOL_BOMBER, Kind.MINI_HAG_COMMANDER, Kind.BOSS_BOG_HYDRA,
	Kind.MINI_WRECKER, Kind.MINI_TURBINE_GUNNER, Kind.MINI_DUMPSTER_BOMBER, Kind.MINI_FOREMAN_COMMANDER, Kind.BOSS_SCRAP_TITAN,
	Kind.MINI_NEON_ENFORCER, Kind.MINI_LASER_DJ, Kind.MINI_DRONE_CARRIER, Kind.MINI_NEON_OVERLORD, Kind.BOSS_NEON_SHOGUN,
	Kind.MINI_AIRLOCK_CRUSHER, Kind.MINI_SATELLITE_GUNNER, Kind.MINI_MINE_BOMBER, Kind.MINI_STATION_COMMANDER, Kind.BOSS_ORBITAL_GUARDIAN,
	Kind.MINI_MANDIBLE_CRUSHER, Kind.MINI_WASP_GUNNER, Kind.MINI_LADYBUG_BOMBER, Kind.MINI_MANTIS_COMMANDER, Kind.BOSS_HIVE_QUEEN,
	Kind.MINI_SLUDGE_SMASHER, Kind.MINI_HAZMAT_GUNNER, Kind.MINI_BARREL_BOMBER, Kind.MINI_MUTANT_COMMANDER, Kind.BOSS_MUTANT_BEHEMOTH,
	Kind.MINI_GEODE_CRUSHER, Kind.MINI_PRISM_GUNNER, Kind.MINI_BAT_BOMBER, Kind.MINI_GEM_COMMANDER, Kind.BOSS_PRISM_GUARDIAN,
	Kind.MINI_ANCHOR_SMASHER, Kind.MINI_BROADSIDE_GUNNER, Kind.MINI_POWDER_KEG_BOMBER, Kind.MINI_FIRST_MATE, Kind.BOSS_IRON_GALLEON,
	Kind.MINI_BARNACLE_CRUSHER, Kind.MINI_GHOST_GUNNER, Kind.MINI_BUOY_BOMBER, Kind.MINI_PHANTOM_ADMIRAL, Kind.BOSS_SPECTRAL_ADMIRAL,
	Kind.MINI_CRAB_CRUSHER, Kind.MINI_ANGLER_GUNNER, Kind.MINI_PUFFER_BOMBER, Kind.MINI_TRITON_COMMANDER, Kind.BOSS_KRAKEN,
	Kind.MINI_OBSIDIAN_CRUSHER, Kind.MINI_ECLIPSE_GUNNER, Kind.MINI_METEOR_BOMBER, Kind.MINI_VOID_HERALD, Kind.BOSS_VOID_EMPEROR,
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
	## ---- Round 4 (graveyard): 4 mini bosses (levels 16-19) and the boss (level 20) ----
	Kind.MINI_GRAVEDIGGER: {
		"scene": "res://Scene/Enemy/Types/MiniGravedigger.tscn", "height": 4.2,
		"name": "GRAVEDIGGER", "health": 6800.0, "damage": 31.0, "speed": 3.0, "gold": 134,
		"shards": 10, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.70, 0.45, 0.90),
	},
	Kind.MINI_COFFIN_CANNON: {
		"scene": "res://Scene/Enemy/Types/MiniCoffinCannon.tscn", "height": 3.8,
		"name": "COFFIN CANNON", "health": 5770.0, "damage": 27.0, "speed": 3.0, "gold": 134,
		"shards": 10, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.70, 0.45, 0.90),
	},
	Kind.MINI_PUMPKIN_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniPumpkinBomber.tscn", "height": 3.6,
		"name": "PUMPKIN BOMBER", "health": 6180.0, "damage": 29.0, "speed": 2.8, "gold": 134,
		"shards": 10, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.70, 0.45, 0.90),
	},
	Kind.MINI_LICH_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniLichCommander.tscn", "height": 4.6,
		"name": "LICH COMMANDER", "health": 8240.0, "damage": 31.0, "speed": 2.8, "gold": 139,
		"shards": 10, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.70, 0.45, 0.90),
	},
	Kind.BOSS_BONE_REAPER: {
		"scene": "res://Scene/Enemy/Types/BossBoneReaper.tscn", "height": 8.0,
		"name": "BONE REAPER", "health": 37100.0, "damage": 37.0, "speed": 3.4, "gold": 618,
		"shards": 42, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.21, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.70, 0.45, 0.90),
	},
	## ---- Round 5 (desert): 4 mini bosses (levels 21-24) and the boss (level 25) ----
	Kind.MINI_SARCOPHAGUS_SMASHER: {
		"scene": "res://Scene/Enemy/Types/MiniSarcophagusSmasher.tscn", "height": 4.2,
		"name": "SARCOPHAGUS SMASHER", "health": 7000.0, "damage": 32.0, "speed": 3.0, "gold": 138,
		"shards": 11, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.95, 0.76, 0.25),
	},
	Kind.MINI_ANUBIS_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniAnubisGunner.tscn", "height": 3.8,
		"name": "ANUBIS GUNNER", "health": 5940.0, "damage": 28.0, "speed": 3.0, "gold": 138,
		"shards": 11, "shard_chance": 1.0, "radius": 1.3, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.95, 0.76, 0.25),
	},
	Kind.MINI_SCARAB_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniScarabBomber.tscn", "height": 3.6,
		"name": "SCARAB BOMBER", "health": 6360.0, "damage": 30.0, "speed": 2.8, "gold": 138,
		"shards": 11, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.95, 0.76, 0.25),
	},
	Kind.MINI_PHARAOH_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniPharaohCommander.tscn", "height": 4.6,
		"name": "PHARAOH COMMANDER", "health": 8480.0, "damage": 32.0, "speed": 2.8, "gold": 143,
		"shards": 11, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.95, 0.76, 0.25),
	},
	Kind.BOSS_GOLDEN_SPHINX: {
		"scene": "res://Scene/Enemy/Types/BossGoldenSphinx.tscn", "height": 8.0,
		"name": "GOLDEN SPHINX", "health": 38200.0, "damage": 38.0, "speed": 3.4, "gold": 636,
		"shards": 44, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.22, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.95, 0.76, 0.25),
	},
	## ---- Round 6 (swamp): 4 mini bosses (levels 26-29) and the boss (level 30) ----
	Kind.MINI_BOG_BRUTE: {
		"scene": "res://Scene/Enemy/Types/MiniBogBrute.tscn", "height": 4.2,
		"name": "BOG BRUTE", "health": 7190.0, "damage": 33.0, "speed": 3.0, "gold": 142,
		"shards": 11, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.45, 0.80, 0.30),
	},
	Kind.MINI_CAULDRON_WITCH: {
		"scene": "res://Scene/Enemy/Types/MiniCauldronWitch.tscn", "height": 3.8,
		"name": "CAULDRON WITCH", "health": 6100.0, "damage": 28.0, "speed": 3.0, "gold": 142,
		"shards": 11, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.45, 0.80, 0.30),
	},
	Kind.MINI_TOADSTOOL_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniToadstoolBomber.tscn", "height": 3.6,
		"name": "TOADSTOOL BOMBER", "health": 6540.0, "damage": 31.0, "speed": 2.8, "gold": 142,
		"shards": 11, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.45, 0.80, 0.30),
	},
	Kind.MINI_HAG_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniHagCommander.tscn", "height": 4.6,
		"name": "HAG COMMANDER", "health": 8720.0, "damage": 33.0, "speed": 2.8, "gold": 147,
		"shards": 11, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.45, 0.80, 0.30),
	},
	Kind.BOSS_BOG_HYDRA: {
		"scene": "res://Scene/Enemy/Types/BossBogHydra.tscn", "height": 8.0,
		"name": "BOG HYDRA", "health": 39200.0, "damage": 39.0, "speed": 3.4, "gold": 654,
		"shards": 46, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.23, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.45, 0.80, 0.30),
	},
	## ---- Round 7 (junkyard): 4 mini bosses (levels 31-34) and the boss (level 35) ----
	Kind.MINI_WRECKER: {
		"scene": "res://Scene/Enemy/Types/MiniWrecker.tscn", "height": 4.2,
		"name": "WRECKER", "health": 7390.0, "damage": 34.0, "speed": 3.0, "gold": 146,
		"shards": 12, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.78, 0.50, 0.25),
	},
	Kind.MINI_TURBINE_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniTurbineGunner.tscn", "height": 3.8,
		"name": "TURBINE GUNNER", "health": 6270.0, "damage": 29.0, "speed": 3.0, "gold": 146,
		"shards": 12, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.78, 0.50, 0.25),
	},
	Kind.MINI_DUMPSTER_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniDumpsterBomber.tscn", "height": 3.6,
		"name": "DUMPSTER BOMBER", "health": 6720.0, "damage": 31.0, "speed": 2.8, "gold": 146,
		"shards": 12, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.78, 0.50, 0.25),
	},
	Kind.MINI_FOREMAN_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniForemanCommander.tscn", "height": 4.6,
		"name": "FOREMAN COMMANDER", "health": 8960.0, "damage": 34.0, "speed": 2.8, "gold": 151,
		"shards": 12, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.78, 0.50, 0.25),
	},
	Kind.BOSS_SCRAP_TITAN: {
		"scene": "res://Scene/Enemy/Types/BossScrapTitan.tscn", "height": 8.0,
		"name": "SCRAP TITAN", "health": 40300.0, "damage": 40.0, "speed": 3.4, "gold": 672,
		"shards": 48, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.24, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.78, 0.50, 0.25),
	},
	## ---- Round 8 (neon city): 4 mini bosses (levels 36-39) and the boss (level 40) ----
	Kind.MINI_NEON_ENFORCER: {
		"scene": "res://Scene/Enemy/Types/MiniNeonEnforcer.tscn", "height": 4.2,
		"name": "NEON ENFORCER", "health": 7590.0, "damage": 34.0, "speed": 3.0, "gold": 150,
		"shards": 12, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.00, 0.25, 0.75),
	},
	Kind.MINI_LASER_DJ: {
		"scene": "res://Scene/Enemy/Types/MiniLaserDj.tscn", "height": 3.8,
		"name": "LASER DJ", "health": 6440.0, "damage": 30.0, "speed": 3.0, "gold": 150,
		"shards": 12, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.00, 0.25, 0.75),
	},
	Kind.MINI_DRONE_CARRIER: {
		"scene": "res://Scene/Enemy/Types/MiniDroneCarrier.tscn", "height": 3.6,
		"name": "DRONE CARRIER", "health": 6900.0, "damage": 32.0, "speed": 2.8, "gold": 150,
		"shards": 12, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.00, 0.25, 0.75),
	},
	Kind.MINI_NEON_OVERLORD: {
		"scene": "res://Scene/Enemy/Types/MiniNeonOverlord.tscn", "height": 4.6,
		"name": "NEON OVERLORD", "health": 9200.0, "damage": 34.0, "speed": 2.8, "gold": 155,
		"shards": 12, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.00, 0.25, 0.75),
	},
	Kind.BOSS_NEON_SHOGUN: {
		"scene": "res://Scene/Enemy/Types/BossNeonShogun.tscn", "height": 8.0,
		"name": "NEON SHOGUN", "health": 41400.0, "damage": 41.0, "speed": 3.4, "gold": 690,
		"shards": 50, "shard_chance": 1.0, "radius": 2.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.25, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(1.00, 0.25, 0.75),
	},
	## ---- Round 9 (space station): 4 mini bosses (levels 41-44) and the boss (level 45) ----
	Kind.MINI_AIRLOCK_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniAirlockCrusher.tscn", "height": 4.2,
		"name": "AIRLOCK CRUSHER", "health": 7790.0, "damage": 35.0, "speed": 3.0, "gold": 153,
		"shards": 13, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.60, 1.00),
	},
	Kind.MINI_SATELLITE_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniSatelliteGunner.tscn", "height": 3.8,
		"name": "SATELLITE GUNNER", "health": 6610.0, "damage": 31.0, "speed": 3.0, "gold": 153,
		"shards": 13, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.60, 1.00),
	},
	Kind.MINI_MINE_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniMineBomber.tscn", "height": 3.6,
		"name": "MINE BOMBER", "health": 7080.0, "damage": 33.0, "speed": 2.8, "gold": 153,
		"shards": 13, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.60, 1.00),
	},
	Kind.MINI_STATION_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniStationCommander.tscn", "height": 4.6,
		"name": "STATION COMMANDER", "health": 9440.0, "damage": 35.0, "speed": 2.8, "gold": 159,
		"shards": 13, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.60, 1.00),
	},
	Kind.BOSS_ORBITAL_GUARDIAN: {
		"scene": "res://Scene/Enemy/Types/BossOrbitalGuardian.tscn", "height": 8.0,
		"name": "ORBITAL GUARDIAN", "health": 42500.0, "damage": 42.0, "speed": 3.4, "gold": 708,
		"shards": 52, "shard_chance": 1.0, "radius": 2.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.26, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.35, 0.60, 1.00),
	},
	## ---- Round 10 (insect hive): 4 mini bosses (levels 46-49) and the boss (level 50) ----
	Kind.MINI_MANDIBLE_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniMandibleCrusher.tscn", "height": 4.2,
		"name": "MANDIBLE CRUSHER", "health": 7990.0, "damage": 36.0, "speed": 3.0, "gold": 157,
		"shards": 13, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.90, 0.80, 0.15),
	},
	Kind.MINI_WASP_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniWaspGunner.tscn", "height": 3.8,
		"name": "WASP GUNNER", "health": 6780.0, "damage": 31.0, "speed": 3.0, "gold": 157,
		"shards": 13, "shard_chance": 1.0, "radius": 1.3, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.90, 0.80, 0.15),
	},
	Kind.MINI_LADYBUG_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniLadybugBomber.tscn", "height": 3.6,
		"name": "LADYBUG BOMBER", "health": 7260.0, "damage": 34.0, "speed": 2.8, "gold": 157,
		"shards": 13, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.90, 0.80, 0.15),
	},
	Kind.MINI_MANTIS_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniMantisCommander.tscn", "height": 4.6,
		"name": "MANTIS COMMANDER", "health": 9680.0, "damage": 36.0, "speed": 2.8, "gold": 163,
		"shards": 13, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.90, 0.80, 0.15),
	},
	Kind.BOSS_HIVE_QUEEN: {
		"scene": "res://Scene/Enemy/Types/BossHiveQueen.tscn", "height": 8.0,
		"name": "HIVE QUEEN", "health": 43600.0, "damage": 44.0, "speed": 3.4, "gold": 726,
		"shards": 54, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.27, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.90, 0.80, 0.15),
	},
	## ---- Round 11 (toxic waste): 4 mini bosses (levels 51-54) and the boss (level 55) ----
	Kind.MINI_SLUDGE_SMASHER: {
		"scene": "res://Scene/Enemy/Types/MiniSludgeSmasher.tscn", "height": 4.2,
		"name": "SLUDGE SMASHER", "health": 8180.0, "damage": 37.0, "speed": 3.0, "gold": 161,
		"shards": 14, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 1.00, 0.20),
	},
	Kind.MINI_HAZMAT_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniHazmatGunner.tscn", "height": 3.8,
		"name": "HAZMAT GUNNER", "health": 6940.0, "damage": 32.0, "speed": 3.0, "gold": 161,
		"shards": 14, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 1.00, 0.20),
	},
	Kind.MINI_BARREL_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniBarrelBomber.tscn", "height": 3.6,
		"name": "BARREL BOMBER", "health": 7440.0, "damage": 35.0, "speed": 2.8, "gold": 161,
		"shards": 14, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 1.00, 0.20),
	},
	Kind.MINI_MUTANT_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniMutantCommander.tscn", "height": 4.6,
		"name": "MUTANT COMMANDER", "health": 9920.0, "damage": 37.0, "speed": 2.8, "gold": 167,
		"shards": 14, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 1.00, 0.20),
	},
	Kind.BOSS_MUTANT_BEHEMOTH: {
		"scene": "res://Scene/Enemy/Types/BossMutantBehemoth.tscn", "height": 8.0,
		"name": "MUTANT BEHEMOTH", "health": 44600.0, "damage": 45.0, "speed": 3.4, "gold": 744,
		"shards": 56, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.28, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 1.00, 0.20),
	},
	## ---- Round 12 (crystal cave): 4 mini bosses (levels 56-59) and the boss (level 60) ----
	Kind.MINI_GEODE_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniGeodeCrusher.tscn", "height": 4.2,
		"name": "GEODE CRUSHER", "health": 8380.0, "damage": 38.0, "speed": 3.0, "gold": 165,
		"shards": 14, "shard_chance": 1.0, "radius": 1.3, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.50, 0.95, 0.90),
	},
	Kind.MINI_PRISM_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniPrismGunner.tscn", "height": 3.8,
		"name": "PRISM GUNNER", "health": 7110.0, "damage": 33.0, "speed": 3.0, "gold": 165,
		"shards": 14, "shard_chance": 1.0, "radius": 1.4, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.50, 0.95, 0.90),
	},
	Kind.MINI_BAT_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniBatBomber.tscn", "height": 3.6,
		"name": "BAT BOMBER", "health": 7620.0, "damage": 36.0, "speed": 2.8, "gold": 165,
		"shards": 14, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.50, 0.95, 0.90),
	},
	Kind.MINI_GEM_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniGemCommander.tscn", "height": 4.6,
		"name": "GEM COMMANDER", "health": 10160.0, "damage": 38.0, "speed": 2.8, "gold": 171,
		"shards": 14, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.50, 0.95, 0.90),
	},
	Kind.BOSS_PRISM_GUARDIAN: {
		"scene": "res://Scene/Enemy/Types/BossPrismGuardian.tscn", "height": 8.0,
		"name": "PRISM GUARDIAN", "health": 45700.0, "damage": 46.0, "speed": 3.4, "gold": 762,
		"shards": 58, "shard_chance": 1.0, "radius": 2.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.29, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.50, 0.95, 0.90),
	},
	## ---- Round 13 (pirate): 4 mini bosses (levels 61-64) and the boss (level 65) ----
	Kind.MINI_ANCHOR_SMASHER: {
		"scene": "res://Scene/Enemy/Types/MiniAnchorSmasher.tscn", "height": 4.2,
		"name": "ANCHOR SMASHER", "health": 8580.0, "damage": 39.0, "speed": 3.0, "gold": 169,
		"shards": 15, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 0.40, 0.25),
	},
	Kind.MINI_BROADSIDE_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniBroadsideGunner.tscn", "height": 3.8,
		"name": "BROADSIDE GUNNER", "health": 7280.0, "damage": 34.0, "speed": 3.0, "gold": 169,
		"shards": 15, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 0.40, 0.25),
	},
	Kind.MINI_POWDER_KEG_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniPowderKegBomber.tscn", "height": 3.6,
		"name": "POWDER KEG BOMBER", "health": 7800.0, "damage": 36.0, "speed": 2.8, "gold": 169,
		"shards": 15, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 0.40, 0.25),
	},
	Kind.MINI_FIRST_MATE: {
		"scene": "res://Scene/Enemy/Types/MiniFirstMate.tscn", "height": 4.6,
		"name": "FIRST MATE", "health": 10400.0, "damage": 39.0, "speed": 2.8, "gold": 176,
		"shards": 15, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 0.40, 0.25),
	},
	Kind.BOSS_IRON_GALLEON: {
		"scene": "res://Scene/Enemy/Types/BossIronGalleon.tscn", "height": 8.0,
		"name": "IRON GALLEON", "health": 46800.0, "damage": 47.0, "speed": 3.4, "gold": 780,
		"shards": 60, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.30, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.60, 0.40, 0.25),
	},
	## ---- Round 14 (ghost ship): 4 mini bosses (levels 66-69) and the boss (level 70) ----
	Kind.MINI_BARNACLE_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniBarnacleCrusher.tscn", "height": 4.2,
		"name": "BARNACLE CRUSHER", "health": 8780.0, "damage": 40.0, "speed": 3.0, "gold": 173,
		"shards": 15, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.85, 0.80),
	},
	Kind.MINI_GHOST_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniGhostGunner.tscn", "height": 3.8,
		"name": "GHOST GUNNER", "health": 7450.0, "damage": 35.0, "speed": 3.0, "gold": 173,
		"shards": 15, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.85, 0.80),
	},
	Kind.MINI_BUOY_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniBuoyBomber.tscn", "height": 3.6,
		"name": "BUOY BOMBER", "health": 7980.0, "damage": 37.0, "speed": 2.8, "gold": 173,
		"shards": 15, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.85, 0.80),
	},
	Kind.MINI_PHANTOM_ADMIRAL: {
		"scene": "res://Scene/Enemy/Types/MiniPhantomAdmiral.tscn", "height": 4.6,
		"name": "PHANTOM ADMIRAL", "health": 10640.0, "damage": 40.0, "speed": 2.8, "gold": 180,
		"shards": 15, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.85, 0.80),
	},
	Kind.BOSS_SPECTRAL_ADMIRAL: {
		"scene": "res://Scene/Enemy/Types/BossSpectralAdmiral.tscn", "height": 8.0,
		"name": "SPECTRAL ADMIRAL", "health": 47900.0, "damage": 48.0, "speed": 3.4, "gold": 798,
		"shards": 62, "shard_chance": 1.0, "radius": 2.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.30, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.85, 0.80),
	},
	## ---- Round 15 (deep sea): 4 mini bosses (levels 71-74) and the boss (level 75) ----
	Kind.MINI_CRAB_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniCrabCrusher.tscn", "height": 4.2,
		"name": "CRAB CRUSHER", "health": 8980.0, "damage": 41.0, "speed": 3.0, "gold": 177,
		"shards": 16, "shard_chance": 1.0, "radius": 1.7, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.20, 0.55, 0.80),
	},
	Kind.MINI_ANGLER_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniAnglerGunner.tscn", "height": 3.8,
		"name": "ANGLER GUNNER", "health": 7620.0, "damage": 35.0, "speed": 3.0, "gold": 177,
		"shards": 16, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.20, 0.55, 0.80),
	},
	Kind.MINI_PUFFER_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniPufferBomber.tscn", "height": 3.6,
		"name": "PUFFER BOMBER", "health": 8160.0, "damage": 38.0, "speed": 2.8, "gold": 177,
		"shards": 16, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.20, 0.55, 0.80),
	},
	Kind.MINI_TRITON_COMMANDER: {
		"scene": "res://Scene/Enemy/Types/MiniTritonCommander.tscn", "height": 4.6,
		"name": "TRITON COMMANDER", "health": 10880.0, "damage": 41.0, "speed": 2.8, "gold": 184,
		"shards": 16, "shard_chance": 1.0, "radius": 1.8, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.20, 0.55, 0.80),
	},
	Kind.BOSS_KRAKEN: {
		"scene": "res://Scene/Enemy/Types/BossKraken.tscn", "height": 7.9,
		"name": "KRAKEN", "health": 49000.0, "damage": 49.0, "speed": 3.4, "gold": 816,
		"shards": 64, "shard_chance": 1.0, "radius": 2.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.30, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.20, 0.55, 0.80),
	},
	## ---- Round 16 (void): 4 mini bosses (levels 76-79) and the boss (level 80) ----
	Kind.MINI_OBSIDIAN_CRUSHER: {
		"scene": "res://Scene/Enemy/Types/MiniObsidianCrusher.tscn", "height": 4.2,
		"name": "OBSIDIAN CRUSHER", "health": 9170.0, "damage": 42.0, "speed": 3.0, "gold": 181,
		"shards": 16, "shard_chance": 1.0, "radius": 1.6, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.15, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.20, 0.85),
	},
	Kind.MINI_ECLIPSE_GUNNER: {
		"scene": "res://Scene/Enemy/Types/MiniEclipseGunner.tscn", "height": 3.8,
		"name": "ECLIPSE GUNNER", "health": 7780.0, "damage": 36.0, "speed": 3.0, "gold": 181,
		"shards": 16, "shard_chance": 1.0, "radius": 1.9, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.20, 0.85),
	},
	Kind.MINI_METEOR_BOMBER: {
		"scene": "res://Scene/Enemy/Types/MiniMeteorBomber.tscn", "height": 3.6,
		"name": "METEOR BOMBER", "health": 8340.0, "damage": 39.0, "speed": 2.8, "gold": 181,
		"shards": 16, "shard_chance": 1.0, "radius": 1.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.10, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.20, 0.85),
	},
	Kind.MINI_VOID_HERALD: {
		"scene": "res://Scene/Enemy/Types/MiniVoidHerald.tscn", "height": 4.6,
		"name": "VOID HERALD", "health": 11120.0, "damage": 42.0, "speed": 2.8, "gold": 188,
		"shards": 16, "shard_chance": 1.0, "radius": 2.0, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.20, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.20, 0.85),
	},
	Kind.BOSS_VOID_EMPEROR: {
		"scene": "res://Scene/Enemy/Types/BossVoidEmperor.tscn", "height": 9.0,
		"name": "VOID EMPEROR", "health": 50000.0, "damage": 50.0, "speed": 3.4, "gold": 834,
		"shards": 66, "shard_chance": 1.0, "radius": 2.5, "attack_range": 3.0, "attack_cd": 1.5,
		"armor": 0.30, "scale": 1.0, "ranged": false, "proj_speed": 0.0,
		"color": Color(0.55, 0.20, 0.85),
	},
}
