class_name RoundDB
extends RefCounted
## Which enemies appear on which level. A round is a chapter (LevelDB.chapter_of):
##   Round 1  levels 1-5    original enemies (grunt, scout, brute, gunner, warlord, kamikaze,
##                          marksman, medic) + new ones: Mortar from level 2, Blinder from 3,
##                          Weakener from 4 (see R1_NEW).
##   Round 2  levels 6-10   ALL round 2 enemies on every level (roster_for(2), _r2 models).
##   Round 3  levels 11-15  ALL round 3 enemies on every level (roster_for(3), _r3 models).
## The WaveTrigger counts in the level scene are the "template": round 1 keeps them as they are
## (plus the new enemies), rounds 2 and 3 keep the same enemy total per wave but spread it
## over the whole roster by weight, every kind at least once per wave.

## Round 2 / 3 roster candidates: kind -> weight (share of every wave). A kind only takes part
## in a round when its model for that round exists (Assets/Enemy/<model>_r2.glb / _r3.glb), see
## roster_for(). The 5 original kinds (grunt, scout, brute, gunner, warlord) join automatically
## the moment their _r2 / _r3 files are added to the project.
const R23_ROSTER := {
	EnemyDB.Kind.BREACHER: 24,
	EnemyDB.Kind.SHOTGUNNER: 20,
	EnemyDB.Kind.KAMIKAZE: 14,
	EnemyDB.Kind.SNIPER: 8,
	EnemyDB.Kind.MEDIC: 6,
	EnemyDB.Kind.MORTAR: 10,
	EnemyDB.Kind.BLINDER: 9,
	EnemyDB.Kind.WEAKENER: 9,
	EnemyDB.Kind.BASIC: 22,
	EnemyDB.Kind.FAST: 10,
	EnemyDB.Kind.ARMORED: 12,
	EnemyDB.Kind.RANGED: 10,
	EnemyDB.Kind.ELITE: 3,
}

## Round 1 additions: [kind, first level, last level, extra enemies in wave 1, wave 2, wave 3].
## Each 2 levels after the first level add one more to every wave that has any.
const R1_NEW := [
	[EnemyDB.Kind.MORTAR, 2, 5, 1, 2, 3],
	[EnemyDB.Kind.BLINDER, 3, 5, 0, 2, 3],
	[EnemyDB.Kind.WEAKENER, 4, 5, 0, 1, 2],
]


static func round_of(level: int) -> int:
	return LevelDB.chapter_of(level)


## Kinds that fill round 2 / 3 waves: the roster candidates whose model for that round exists.
static func roster_for(round_number: int) -> Dictionary:
	var out := {}
	for kind in R23_ROSTER:
		if EnemyDB.round_model_path(int(kind), round_number) != "":
			out[kind] = R23_ROSTER[kind]
	return out


## Every enemy kind a normal wave of `level` can contain.
static func kinds_for(level: int) -> Array:
	if round_of(level) > 1 and not roster_for(round_of(level)).is_empty():
		return roster_for(round_of(level)).keys()
	var list: Array = EnemyDB.MINION_POOL.duplicate()
	for e in R1_NEW:
		if level >= int(e[1]) and level <= int(e[2]):
			list.append(e[0])
	return list


## Random kind for boss / mini boss reinforcement waves on `level`.
static func random_minion_kind(level: int) -> int:
	var list := kinds_for(level)
	return int(list[randi() % list.size()])


## Final wave list [[kind, count], ...] for wave `wave_index` (0-based) of `level`.
## `template` is WaveTrigger.composition().
static func wave_composition(level: int, wave_index: int, template: Array) -> Array:
	if round_of(level) <= 1 or roster_for(round_of(level)).is_empty():
		return _round1(level, wave_index, template)
	return _roster_wave(template, roster_for(round_of(level)))


static func _round1(level: int, wave_index: int, template: Array) -> Array:
	var out: Array = []
	for entry in template:
		if int(entry[1]) > 0:
			out.append([int(entry[0]), int(entry[1])])
	for e in R1_NEW:
		var first := int(e[1])
		if level < first or level > int(e[2]):
			continue
		var n := int(e[3 + clampi(wave_index, 0, 2)])
		if n > 0:
			out.append([int(e[0]), n + floori((level - first) / 2.0)])
	return out


static func _roster_wave(template: Array, roster: Dictionary) -> Array:
	var total := 0
	for entry in template:
		total += int(entry[1])
	var weight_sum := 0
	for k in roster:
		weight_sum += int(roster[k])
	var out: Array = []
	for k in roster:
		var n := maxi(1, int(round(float(total) * float(roster[k]) / float(weight_sum))))
		out.append([int(k), n])
	return out
