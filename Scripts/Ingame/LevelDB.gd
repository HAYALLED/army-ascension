class_name LevelDB
extends RefCounted
## Level and chapter layout. Chapters are derived from the level number; only the level number is saved.

## A chapter is a round: levels 1-5 = round 1, 6-10 = round 2 ... 76-80 = round 16 (enemy art + roster, see RoundDB).
const LEVELS_PER_CHAPTER := 5
const CHAPTER_COUNT := 16
const TOTAL_LEVELS := LEVELS_PER_CHAPTER * CHAPTER_COUNT
## Every BOSS_EVERY-th level (5, 10, 15 ... 80) is a full boss fight; every other level ends with a mini boss. Both depend on the round.
const BOSS_EVERY := 5


## 1-based chapter of a 1-based level number.
static func chapter_of(level: int) -> int:
	return floori((maxi(level, 1) - 1) / float(LEVELS_PER_CHAPTER)) + 1


## True on levels 5, 10, 15... (full boss fight).
static func is_boss_level(level: int) -> bool:
	return level >= 1 and level % BOSS_EVERY == 0


## True on every level that is not a boss level: it ends with a mini boss.
static func is_mini_level(level: int) -> bool:
	return level >= 1 and not is_boss_level(level)


## Full boss of each round (levels 5, 10, 15 ... 80).
const BOSS_KIND_BY_ROUND := [
	EnemyDB.Kind.BOSS, EnemyDB.Kind.BOSS_YETI, EnemyDB.Kind.BOSS_DRAKE,
	EnemyDB.Kind.BOSS_BONE_REAPER,
	EnemyDB.Kind.BOSS_GOLDEN_SPHINX,
	EnemyDB.Kind.BOSS_BOG_HYDRA,
	EnemyDB.Kind.BOSS_SCRAP_TITAN,
	EnemyDB.Kind.BOSS_NEON_SHOGUN,
	EnemyDB.Kind.BOSS_ORBITAL_GUARDIAN,
	EnemyDB.Kind.BOSS_HIVE_QUEEN,
	EnemyDB.Kind.BOSS_MUTANT_BEHEMOTH,
	EnemyDB.Kind.BOSS_PRISM_GUARDIAN,
	EnemyDB.Kind.BOSS_IRON_GALLEON,
	EnemyDB.Kind.BOSS_SPECTRAL_ADMIRAL,
	EnemyDB.Kind.BOSS_KRAKEN,
	EnemyDB.Kind.BOSS_VOID_EMPEROR,
]

## Mini bosses of each round in the order they appear (4 mini levels per round).
const MINI_BOSS_KINDS_BY_ROUND := [
	[EnemyDB.Kind.MINI_CRUSHER, EnemyDB.Kind.MINI_GATLING, EnemyDB.Kind.MINI_BOMBER, EnemyDB.Kind.MINI_COMMANDER],
	[EnemyDB.Kind.MINI_ICEBREAKER, EnemyDB.Kind.MINI_BLIZZARD, EnemyDB.Kind.MINI_SLED, EnemyDB.Kind.MINI_FROST_COMMANDER],
	[EnemyDB.Kind.MINI_FORGE_SMASHER, EnemyDB.Kind.MINI_FLAMECASTER, EnemyDB.Kind.MINI_LAVA_MORTAR, EnemyDB.Kind.MINI_FOUNDRY_OVERSEER],
	[EnemyDB.Kind.MINI_GRAVEDIGGER, EnemyDB.Kind.MINI_COFFIN_CANNON, EnemyDB.Kind.MINI_PUMPKIN_BOMBER, EnemyDB.Kind.MINI_LICH_COMMANDER],
	[EnemyDB.Kind.MINI_SARCOPHAGUS_SMASHER, EnemyDB.Kind.MINI_ANUBIS_GUNNER, EnemyDB.Kind.MINI_SCARAB_BOMBER, EnemyDB.Kind.MINI_PHARAOH_COMMANDER],
	[EnemyDB.Kind.MINI_BOG_BRUTE, EnemyDB.Kind.MINI_CAULDRON_WITCH, EnemyDB.Kind.MINI_TOADSTOOL_BOMBER, EnemyDB.Kind.MINI_HAG_COMMANDER],
	[EnemyDB.Kind.MINI_WRECKER, EnemyDB.Kind.MINI_TURBINE_GUNNER, EnemyDB.Kind.MINI_DUMPSTER_BOMBER, EnemyDB.Kind.MINI_FOREMAN_COMMANDER],
	[EnemyDB.Kind.MINI_NEON_ENFORCER, EnemyDB.Kind.MINI_LASER_DJ, EnemyDB.Kind.MINI_DRONE_CARRIER, EnemyDB.Kind.MINI_NEON_OVERLORD],
	[EnemyDB.Kind.MINI_AIRLOCK_CRUSHER, EnemyDB.Kind.MINI_SATELLITE_GUNNER, EnemyDB.Kind.MINI_MINE_BOMBER, EnemyDB.Kind.MINI_STATION_COMMANDER],
	[EnemyDB.Kind.MINI_MANDIBLE_CRUSHER, EnemyDB.Kind.MINI_WASP_GUNNER, EnemyDB.Kind.MINI_LADYBUG_BOMBER, EnemyDB.Kind.MINI_MANTIS_COMMANDER],
	[EnemyDB.Kind.MINI_SLUDGE_SMASHER, EnemyDB.Kind.MINI_HAZMAT_GUNNER, EnemyDB.Kind.MINI_BARREL_BOMBER, EnemyDB.Kind.MINI_MUTANT_COMMANDER],
	[EnemyDB.Kind.MINI_GEODE_CRUSHER, EnemyDB.Kind.MINI_PRISM_GUNNER, EnemyDB.Kind.MINI_BAT_BOMBER, EnemyDB.Kind.MINI_GEM_COMMANDER],
	[EnemyDB.Kind.MINI_ANCHOR_SMASHER, EnemyDB.Kind.MINI_BROADSIDE_GUNNER, EnemyDB.Kind.MINI_POWDER_KEG_BOMBER, EnemyDB.Kind.MINI_FIRST_MATE],
	[EnemyDB.Kind.MINI_BARNACLE_CRUSHER, EnemyDB.Kind.MINI_GHOST_GUNNER, EnemyDB.Kind.MINI_BUOY_BOMBER, EnemyDB.Kind.MINI_PHANTOM_ADMIRAL],
	[EnemyDB.Kind.MINI_CRAB_CRUSHER, EnemyDB.Kind.MINI_ANGLER_GUNNER, EnemyDB.Kind.MINI_PUFFER_BOMBER, EnemyDB.Kind.MINI_TRITON_COMMANDER],
	[EnemyDB.Kind.MINI_OBSIDIAN_CRUSHER, EnemyDB.Kind.MINI_ECLIPSE_GUNNER, EnemyDB.Kind.MINI_METEOR_BOMBER, EnemyDB.Kind.MINI_VOID_HERALD],
]


## Boss kind that ends a level. Round 1: Crusher, Gatling, Bomber Chief, Commander (levels 1-4), Iron Colossus (5).
## Round 2: Icebreaker, Blizzard Gunner, Sled Rider, Frost Commander (6-9), Yeti King (10).
## Round 3: Forge Smasher, Flamecaster, Lava Mortar, Foundry Overseer (11-14), Magma Drake (15).
## Rounds 4-16: smasher, gunner, bomber, commander (levels x1-x4) and the round boss (x5), see BOSS_KIND_BY_ROUND / MINI_BOSS_KINDS_BY_ROUND.
static func boss_kind(level: int) -> int:
	var round_index := clampi(chapter_of(level) - 1, 0, CHAPTER_COUNT - 1)
	if is_boss_level(level):
		return BOSS_KIND_BY_ROUND[round_index]
	var lv := maxi(level, 1)
	var mini_index := lv - 1 - floori(lv / float(BOSS_EVERY))
	var list: Array = MINI_BOSS_KINDS_BY_ROUND[round_index]
	return list[mini_index % list.size()]
