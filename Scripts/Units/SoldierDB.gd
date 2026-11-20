class_name SoldierDB
extends RefCounted
## Soldier class definitions + level scaling. Every number here is a
## starting balance value and can be tuned freely.

enum Type { RIFLEMAN, MACHINE_GUNNER, SNIPER, ROCKET, MEDIC }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := ["Common", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := [Color(0.75, 0.75, 0.78), Color(0.3, 0.6, 1.0), Color(0.7, 0.35, 0.95), Color(1.0, 0.75, 0.2)]

## Rifleman L1 -> L2: damage 10 -> 15, health 100 -> 120 (matches design doc).
const DAMAGE_PER_LEVEL := 0.5
const HEALTH_PER_LEVEL := 0.2

## Weighted pool used by "+N soldiers" gates.
const SPAWN_WEIGHTS := {
	Type.RIFLEMAN: 40,
	Type.MACHINE_GUNNER: 22,
	Type.SNIPER: 14,
	Type.ROCKET: 14,
	Type.MEDIC: 10,
}

const DATA := {
	Type.RIFLEMAN: {
		"scene": "res://Scene/Units/Soldiers/Rifleman.tscn",
		"model": "res://Assets/Units/rifleman.glb", "icon": "res://Assets/UI/class_rifleman.png",
		"name": "Rifleman", "rarity": Rarity.COMMON,
		"health": 100.0, "damage": 10.0, "attack_speed": 3.0, "follow_rate": 11.0, "range": 15.0,
		"bullet_speed": 48.0, "pierce": 0, "aoe": 0.0, "spread": 0.03,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 1,
		"body": Color(0.2, 0.45, 0.9), "accent": Color(0.12, 0.2, 0.5),
	},
	Type.MACHINE_GUNNER: {
		"scene": "res://Scene/Units/Soldiers/MachineGunner.tscn",
		"model": "res://Assets/Units/machine_gunner.glb", "icon": "res://Assets/UI/class_machinegunner.png",
		"name": "Machine Gunner", "rarity": Rarity.COMMON,
		"health": 90.0, "damage": 6.0, "attack_speed": 7.0, "follow_rate": 10.0, "range": 12.0,
		"bullet_speed": 44.0, "pierce": 0, "aoe": 0.0, "spread": 0.1,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_mg", "row": 0,
		"body": Color(0.95, 0.55, 0.12), "accent": Color(0.45, 0.25, 0.05),
	},
	Type.SNIPER: {
		"scene": "res://Scene/Units/Soldiers/Sniper.tscn",
		"model": "res://Assets/Units/sniper.glb", "icon": "res://Assets/UI/class_sniper.png",
		"name": "Sniper", "rarity": Rarity.RARE,
		"health": 60.0, "damage": 60.0, "attack_speed": 0.8, "follow_rate": 9.0, "range": 30.0,
		"bullet_speed": 95.0, "pierce": 2, "aoe": 0.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_sniper", "row": 3,
		"body": Color(0.22, 0.4, 0.22), "accent": Color(0.1, 0.2, 0.1),
	},
	Type.ROCKET: {
		"scene": "res://Scene/Units/Soldiers/RocketSoldier.tscn",
		"model": "res://Assets/Units/rocket_soldier.glb", "icon": "res://Assets/UI/class_rocket.png",
		"name": "Rocket Soldier", "rarity": Rarity.RARE,
		"health": 80.0, "damage": 32.0, "attack_speed": 0.6, "follow_rate": 9.0, "range": 17.0,
		"bullet_speed": 26.0, "pierce": 0, "aoe": 3.0, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 2,
		"body": Color(0.8, 0.2, 0.18), "accent": Color(0.35, 0.08, 0.08),
	},
	Type.MEDIC: {
		"scene": "res://Scene/Units/Soldiers/Medic.tscn",
		"model": "res://Assets/Units/medic.glb", "icon": "res://Assets/UI/class_medic.png",
		"name": "Medic", "rarity": Rarity.EPIC,
		"health": 90.0, "damage": 4.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 10.0,
		"bullet_speed": 40.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 8.0, "heal_interval": 1.2, "heal_range": 6.5,
		"sfx": "shoot_rifle", "row": 3,
		"body": Color(0.95, 0.95, 0.95), "accent": Color(0.25, 0.7, 0.35),
	},
}


## Stats for a class at a given level (damage, health and heal scale with level).
static func stats(type: int, level: int) -> Dictionary:
	var d: Dictionary = DATA[type].duplicate()
	var lv := maxi(level, 1) - 1
	d["health"] = float(d["health"]) * (1.0 + HEALTH_PER_LEVEL * lv)
	d["damage"] = float(d["damage"]) * (1.0 + DAMAGE_PER_LEVEL * lv)
	d["heal"] = float(d["heal"]) * (1.0 + DAMAGE_PER_LEVEL * lv)
	return d


## ---- Upgrade economy (starting balance, all values tunable) ----------------
const MAX_LEVEL := 10
const UPGRADE_GOLD_BASE := 500
const UPGRADE_SHARDS_BASE := 10

static var _scenes: Dictionary = {}


## Gold needed to go from `level` to `level + 1`.
static func upgrade_gold(level: int) -> int:
	return UPGRADE_GOLD_BASE * level


## Class shards needed to go from `level` to `level + 1`.
static func upgrade_shards(level: int) -> int:
	return UPGRADE_SHARDS_BASE * level


## Soldier scene of a class (loaded lazily; scenes live in Scene/Units/Soldiers).
static func scene(type: int) -> PackedScene:
	if not _scenes.has(type):
		_scenes[type] = load(DATA[type]["scene"])
	return _scenes[type]


static func random_type() -> int:
	var total := 0
	for k in SPAWN_WEIGHTS:
		total += int(SPAWN_WEIGHTS[k])
	var roll := randi() % total
	for k in SPAWN_WEIGHTS:
		roll -= int(SPAWN_WEIGHTS[k])
		if roll < 0:
			return k
	return Type.RIFLEMAN
