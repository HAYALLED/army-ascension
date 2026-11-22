class_name LevelDB
extends RefCounted
## Level and chapter layout. Chapters are derived from the level number; only the level number is saved.

## A chapter is a round: levels 1-5 = round 1, 6-10 = round 2, 11-15 = round 3 (enemy art + roster, see RoundDB).
const LEVELS_PER_CHAPTER := 5
const CHAPTER_COUNT := 3
const TOTAL_LEVELS := LEVELS_PER_CHAPTER * CHAPTER_COUNT
## Every BOSS_EVERY-th level (5, 10, 15...) is a full boss fight; every other level ends with a mini boss. Both depend on the round.
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


## Full boss of each round (levels 5, 10, 15).
const BOSS_KIND_BY_ROUND := [EnemyDB.Kind.BOSS, EnemyDB.Kind.BOSS_YETI, EnemyDB.Kind.BOSS_DRAKE]

## Mini bosses of each round in the order they appear (4 mini levels per round).
const MINI_BOSS_KINDS_BY_ROUND := [
	[EnemyDB.Kind.MINI_CRUSHER, EnemyDB.Kind.MINI_GATLING, EnemyDB.Kind.MINI_BOMBER, EnemyDB.Kind.MINI_COMMANDER],
	[EnemyDB.Kind.MINI_ICEBREAKER, EnemyDB.Kind.MINI_BLIZZARD, EnemyDB.Kind.MINI_SLED, EnemyDB.Kind.MINI_FROST_COMMANDER],
	[EnemyDB.Kind.MINI_FORGE_SMASHER, EnemyDB.Kind.MINI_FLAMECASTER, EnemyDB.Kind.MINI_LAVA_MORTAR, EnemyDB.Kind.MINI_FOUNDRY_OVERSEER],
]


## Boss kind that ends a level. Round 1: Crusher, Gatling, Bomber Chief, Commander (levels 1-4), Iron Colossus (5).
## Round 2: Icebreaker, Blizzard Gunner, Sled Rider, Frost Commander (6-9), Yeti King (10).
## Round 3: Forge Smasher, Flamecaster, Lava Mortar, Foundry Overseer (11-14), Magma Drake (15).
static func boss_kind(level: int) -> int:
	var round_index := clampi(chapter_of(level) - 1, 0, CHAPTER_COUNT - 1)
	if is_boss_level(level):
		return BOSS_KIND_BY_ROUND[round_index]
	var lv := maxi(level, 1)
	var mini_index := lv - 1 - floori(lv / float(BOSS_EVERY))
	var list: Array = MINI_BOSS_KINDS_BY_ROUND[round_index]
	return list[mini_index % list.size()]
