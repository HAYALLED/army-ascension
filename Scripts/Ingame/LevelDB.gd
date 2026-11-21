class_name LevelDB
extends RefCounted
## Level and chapter layout. Chapters are derived from the level number; only the level number is saved.

const LEVELS_PER_CHAPTER := 10
const CHAPTER_COUNT := 1
const TOTAL_LEVELS := LEVELS_PER_CHAPTER * CHAPTER_COUNT
## Every BOSS_EVERY-th level is a full boss fight (Iron Colossus); the rest are mini boss levels.
const BOSS_EVERY := 5


## 1-based chapter of a 1-based level number.
static func chapter_of(level: int) -> int:
	return floori((maxi(level, 1) - 1) / float(LEVELS_PER_CHAPTER)) + 1


## True on levels 5, 10, 15... (full boss fight).
static func is_boss_level(level: int) -> bool:
	return level >= 1 and level % BOSS_EVERY == 0
