class_name SoldierDB
extends RefCounted
## Soldier class definitions + level scaling. Every number here is a
## starting balance value and can be tuned freely.

enum Type {
	RIFLEMAN, MACHINE_GUNNER, SNIPER, ROCKET, MEDIC,
	RIFLEMAN_RARE, MACHINE_GUNNER_RARE, SNIPER_RARE, ROCKET_RARE, MEDIC_SUPER_RARE,
	MORTAR, MORTAR_RARE, WEAKENER, WEAKENER_RARE, DRUMMER, DRUMMER_RARE,
	BLINDER, BLINDER_RARE, SHIELD_KNIGHT, SHIELD_KNIGHT_RARE,
}
## Rank (Common/Rare/...) and class (Deadeye/Assault/...) are ids defined by the
## RankDB / UnitClassDB resources (Resources/ranks, Resources/classes). Look and
## colors live there; here a soldier only stores which ids it uses.

## Rifleman L1 -> L2: damage 10 -> 15, health 100 -> 120 (matches design doc).
const DAMAGE_PER_LEVEL := 0.5
const HEALTH_PER_LEVEL := 0.2

## Stable string ids used by the save file (never save enum ints or display names).
const IDS := {
	Type.RIFLEMAN: "rifleman",
	Type.MACHINE_GUNNER: "machine_gunner",
	Type.SNIPER: "sniper",
	Type.ROCKET: "rocket",
	Type.MEDIC: "medic",
	Type.RIFLEMAN_RARE: "rifleman_rare",
	Type.MACHINE_GUNNER_RARE: "machine_gunner_rare",
	Type.SNIPER_RARE: "sniper_rare",
	Type.ROCKET_RARE: "rocket_rare",
	Type.MEDIC_SUPER_RARE: "medic_super_rare",
	Type.MORTAR: "mortar",
	Type.MORTAR_RARE: "mortar_rare",
	Type.WEAKENER: "weakener",
	Type.WEAKENER_RARE: "weakener_rare",
	Type.DRUMMER: "drummer",
	Type.DRUMMER_RARE: "drummer_rare",
	Type.BLINDER: "blinder",
	Type.BLINDER_RARE: "blinder_rare",
	Type.SHIELD_KNIGHT: "shield_knight",
	Type.SHIELD_KNIGHT_RARE: "shield_knight_rare",
}

## Weighted pool used by "+N soldiers" gates.
const SPAWN_WEIGHTS := {
	Type.RIFLEMAN: 40,
	Type.MACHINE_GUNNER: 22,
	Type.SNIPER: 14,
	Type.ROCKET: 14,
	Type.MEDIC: 10,
	Type.RIFLEMAN_RARE: 6,
	Type.MACHINE_GUNNER_RARE: 4,
	Type.SNIPER_RARE: 3,
	Type.ROCKET_RARE: 3,
	Type.MEDIC_SUPER_RARE: 2,
	Type.MORTAR: 8,
	Type.MORTAR_RARE: 3,
	Type.WEAKENER: 6,
	Type.WEAKENER_RARE: 2,
	Type.DRUMMER: 6,
	Type.DRUMMER_RARE: 2,
	Type.BLINDER: 6,
	Type.BLINDER_RARE: 2,
	Type.SHIELD_KNIGHT: 8,
	Type.SHIELD_KNIGHT_RARE: 3,
}

const DATA := {
	Type.RIFLEMAN: {
		"scene": "res://Scene/Units/Soldiers/Rifleman.tscn",
		"model": "res://Assets/Units/rifleman.glb", "icon": "res://Assets/UI/class_rifleman.png",
		"name": "Rifleman", "rank": &"common", "class": &"assault",
		"desc": "Balanced damage and fire rate. The backbone of every army.",
		"health": 100.0, "damage": 10.0, "attack_speed": 3.0, "follow_rate": 11.0, "range": 15.0,
		"bullet_speed": 48.0, "pierce": 0, "aoe": 0.0, "spread": 0.03,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 1,
		"body": Color(0.2, 0.45, 0.9), "accent": Color(0.12, 0.2, 0.5),
	},
	Type.MACHINE_GUNNER: {
		"scene": "res://Scene/Units/Soldiers/MachineGunner.tscn",
		"model": "res://Assets/Units/machine_gunner.glb", "icon": "res://Assets/UI/class_machinegunner.png",
		"name": "Machine Gunner", "rank": &"common", "class": &"assault",
		"desc": "Very fast fire, moderate damage. Melts crowds up close.",
		"health": 90.0, "damage": 6.0, "attack_speed": 7.0, "follow_rate": 10.0, "range": 12.0,
		"bullet_speed": 44.0, "pierce": 0, "aoe": 0.0, "spread": 0.1,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_mg", "row": 0,
		"body": Color(0.95, 0.55, 0.12), "accent": Color(0.45, 0.25, 0.05),
	},
	Type.SNIPER: {
		"scene": "res://Scene/Units/Soldiers/Sniper.tscn",
		"model": "res://Assets/Units/sniper.glb", "icon": "res://Assets/UI/class_sniper.png",
		"name": "Sniper", "rank": &"common", "class": &"deadeye",
		"desc": "Slow, powerful shots that pierce enemies and reach far.",
		"health": 60.0, "damage": 60.0, "attack_speed": 0.8, "follow_rate": 9.0, "range": 30.0,
		"bullet_speed": 95.0, "pierce": 2, "aoe": 0.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_sniper", "row": 3, "prefer": &"strongest",
		"body": Color(0.22, 0.4, 0.22), "accent": Color(0.1, 0.2, 0.1),
	},
	Type.ROCKET: {
		"scene": "res://Scene/Units/Soldiers/RocketSoldier.tscn",
		"model": "res://Assets/Units/rocket_soldier.glb", "icon": "res://Assets/UI/class_rocket.png",
		"name": "Rocket Soldier", "rank": &"common", "class": &"explosive",
		"desc": "Explosive rockets that damage whole groups of enemies.",
		"health": 80.0, "damage": 32.0, "attack_speed": 0.6, "follow_rate": 9.0, "range": 17.0,
		"bullet_speed": 26.0, "pierce": 0, "aoe": 3.0, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 2,
		"body": Color(0.8, 0.2, 0.18), "accent": Color(0.35, 0.08, 0.08),
	},
	Type.MEDIC: {
		"scene": "res://Scene/Units/Soldiers/Medic.tscn",
		"model": "res://Assets/Units/medic.glb", "icon": "res://Assets/UI/class_medic.png",
		"name": "Medic", "rank": &"rare", "class": &"support",
		"desc": "Heals nearby soldiers. Keep the medics in the back rows.",
		"health": 90.0, "damage": 4.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 10.0,
		"bullet_speed": 40.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 8.0, "heal_interval": 1.2, "heal_range": 6.5,
		"sfx": "shoot_rifle", "row": 3,
		"body": Color(0.95, 0.95, 0.95), "accent": Color(0.25, 0.7, 0.35),
	},
	Type.RIFLEMAN_RARE: {
		"scene": "res://Scene/Units/Soldiers/RiflemanRare.tscn",
		"model": "res://Assets/Units/rifleman_rare.glb", "icon": "res://Assets/UI/class_rifleman_rare.png",
		"name": "Elite Rifleman", "rank": &"rare", "class": &"assault",
		"desc": "Upgraded rifleman: tactical armor, a scoped rifle and a longer reach.",
		"health": 140.0, "damage": 15.0, "attack_speed": 3.4, "follow_rate": 11.0, "range": 17.0,
		"bullet_speed": 52.0, "pierce": 0, "aoe": 0.0, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 1,
		"proj": 8, "start": 2,
		"body": Color(0.14, 0.20, 0.43), "accent": Color(0.11, 0.16, 0.37),
	},
	Type.MACHINE_GUNNER_RARE: {
		"scene": "res://Scene/Units/Soldiers/MachineGunnerRare.tscn",
		"model": "res://Assets/Units/machine_gunner_rare.glb", "icon": "res://Assets/UI/class_machine_gunner_rare.png",
		"name": "Heavy Gunner", "rank": &"rare", "class": &"assault",
		"desc": "Armored machine gunner. Soaks up damage and keeps the barrel hot.",
		"health": 150.0, "damage": 8.5, "attack_speed": 7.5, "follow_rate": 10.0, "range": 13.0,
		"bullet_speed": 46.0, "pierce": 0, "aoe": 0.0, "spread": 0.09,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_mg", "row": 0,
		"proj": 9, "start": 2,
		"body": Color(0.95, 0.55, 0.12), "accent": Color(0.17, 0.17, 0.20),
	},
	Type.SNIPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/SniperRare.tscn",
		"model": "res://Assets/Units/sniper_rare.glb", "icon": "res://Assets/UI/class_sniper_rare.png",
		"name": "Marksman", "rank": &"rare", "class": &"deadeye",
		"desc": "Long-range sniper. Heavy shots pierce through and pick the strongest enemy first.",
		"health": 80.0, "damage": 95.0, "attack_speed": 0.9, "follow_rate": 9.0, "range": 33.0,
		"bullet_speed": 100.0, "pierce": 3, "aoe": 0.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_sniper", "row": 3,
		"proj": 10, "start": 1, "prefer": &"strongest",
		"body": Color(0.12, 0.23, 0.25), "accent": Color(0.09, 0.16, 0.17),
	},
	Type.ROCKET_RARE: {
		"scene": "res://Scene/Units/Soldiers/RocketSoldierRare.tscn",
		"model": "res://Assets/Units/rocket_soldier_rare.glb", "icon": "res://Assets/UI/class_rocket_rare.png",
		"name": "Demolition Trooper", "rank": &"rare", "class": &"explosive",
		"desc": "Bigger rockets with a wider blast. Wipes out packed groups.",
		"health": 115.0, "damage": 48.0, "attack_speed": 0.65, "follow_rate": 9.0, "range": 18.0,
		"bullet_speed": 27.0, "pierce": 0, "aoe": 3.6, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 2,
		"proj": 11, "start": 1,
		"body": Color(0.80, 0.20, 0.19), "accent": Color(0.15, 0.15, 0.18),
	},
	Type.MEDIC_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/MedicSuperRare.tscn",
		"model": "res://Assets/Units/medic_super_rare.glb", "icon": "res://Assets/UI/class_medic_super_rare.png",
		"name": "Combat Surgeon", "rank": &"super_rare", "class": &"support",
		"desc": "Elite medic. Heals more, faster and in a wider area.",
		"health": 130.0, "damage": 6.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 11.0,
		"bullet_speed": 42.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 14.0, "heal_interval": 1.0, "heal_range": 8.0,
		"sfx": "shoot_rifle", "row": 3,
		"proj": 12, "start": 1,
		"body": Color(0.95, 0.95, 0.95), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.MORTAR: {
		"scene": "res://Scene/Units/Soldiers/Mortar.tscn",
		"model": "res://Assets/Units/mortar_common.glb", "icon": "res://Assets/UI/class_mortar.png",
		"name": "Mortarman", "rank": &"common", "class": &"explosive",
		"desc": "Lobs shells over the front line onto the biggest enemy crowd.",
		"health": 70.0, "damage": 42.0, "attack_speed": 0.45, "follow_rate": 9.0, "range": 26.0,
		"bullet_speed": 20.0, "pierce": 0, "aoe": 3.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 3,
		"proj": 0, "start": 1, "prefer": &"cluster", "lob": true, "flight": 0.9,
		"body": Color(0.36, 0.40, 0.46), "accent": Color(0.24, 0.27, 0.33),
	},
	Type.MORTAR_RARE: {
		"scene": "res://Scene/Units/Soldiers/MortarRare.tscn",
		"model": "res://Assets/Units/mortar_rare.glb", "icon": "res://Assets/UI/class_mortar_rare.png",
		"name": "Siege Mortarman", "rank": &"rare", "class": &"explosive",
		"desc": "Heavy mortar with bigger shells and a wider blast.",
		"health": 95.0, "damage": 68.0, "attack_speed": 0.5, "follow_rate": 9.0, "range": 28.0,
		"bullet_speed": 20.0, "pierce": 0, "aoe": 3.6, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 3,
		"proj": 0, "start": 1, "prefer": &"cluster", "lob": true, "flight": 0.9,
		"body": Color(0.18, 0.20, 0.25), "accent": Color(0.29, 0.20, 0.13),
	},
	Type.WEAKENER: {
		"scene": "res://Scene/Units/Soldiers/Weakener.tscn",
		"model": "res://Assets/Units/weakener_common.glb", "icon": "res://Assets/UI/class_weakener.png",
		"name": "Weakener", "rank": &"common", "class": &"debuffer",
		"desc": "Sprays a weakening cloud over nearby enemies.",
		"health": 80.0, "damage": 4.0, "attack_speed": 2.0, "follow_rate": 10.0, "range": 10.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 13, "start": 1, "weaken": 0.25, "aura_range": 8.0,
		"body": Color(0.12, 0.65, 0.63), "accent": Color(0.06, 0.37, 0.36),
	},
	Type.WEAKENER_RARE: {
		"scene": "res://Scene/Units/Soldiers/WeakenerRare.tscn",
		"model": "res://Assets/Units/weakener_rare.glb", "icon": "res://Assets/UI/class_weakener_rare.png",
		"name": "Hex Doctor", "rank": &"rare", "class": &"debuffer",
		"desc": "Plague doctor curse caster. Cripples every enemy in a wide area.",
		"health": 105.0, "damage": 7.0, "attack_speed": 2.0, "follow_rate": 10.0, "range": 11.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 13, "start": 1, "weaken": 0.4, "aura_range": 10.0,
		"body": Color(0.06, 0.37, 0.36), "accent": Color(0.54, 0.25, 0.82),
	},
	Type.DRUMMER: {
		"scene": "res://Scene/Units/Soldiers/Drummer.tscn",
		"model": "res://Assets/Units/drummer_common.glb", "icon": "res://Assets/UI/class_drummer.png",
		"name": "Drummer", "rank": &"common", "class": &"support",
		"desc": "Plays a battle rhythm that drives nearby soldiers to fight harder.",
		"health": 85.0, "damage": 3.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 9.0,
		"bullet_speed": 38.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 15, "start": 1, "buff_dmg": 0.12, "buff_rate": 0.15, "aura_range": 6.0,
		"body": Color(0.91, 0.71, 0.14), "accent": Color(0.36, 0.24, 0.13),
	},
	Type.DRUMMER_RARE: {
		"scene": "res://Scene/Units/Soldiers/DrummerRare.tscn",
		"model": "res://Assets/Units/drummer_rare.glb", "icon": "res://Assets/UI/class_drummer_rare.png",
		"name": "Drum Major", "rank": &"rare", "class": &"support",
		"desc": "Commands the march. A stronger rhythm over a wider area.",
		"health": 110.0, "damage": 5.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 9.0,
		"bullet_speed": 38.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 15, "start": 1, "buff_dmg": 0.2, "buff_rate": 0.25, "aura_range": 7.5,
		"body": Color(0.91, 0.71, 0.14), "accent": Color(0.54, 0.25, 0.82),
	},
	Type.BLINDER: {
		"scene": "res://Scene/Units/Soldiers/Blinder.tscn",
		"model": "res://Assets/Units/blinder_common.glb", "icon": "res://Assets/UI/class_blinder.png",
		"name": "Blinder", "rank": &"common", "class": &"debuffer",
		"desc": "Throws flash and smoke so nearby enemies lose their aim.",
		"health": 80.0, "damage": 4.0, "attack_speed": 2.0, "follow_rate": 10.0, "range": 10.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 14, "start": 1, "blind": 0.25, "aura_range": 8.0,
		"body": Color(0.85, 0.72, 0.47), "accent": Color(0.42, 0.27, 0.14),
	},
	Type.BLINDER_RARE: {
		"scene": "res://Scene/Units/Soldiers/BlinderRare.tscn",
		"model": "res://Assets/Units/blinder_rare.glb", "icon": "res://Assets/UI/class_blinder_rare.png",
		"name": "Flash Specialist", "rank": &"rare", "class": &"debuffer",
		"desc": "Blinding lamps and flares. Enemies in a wide area miss far more often.",
		"health": 105.0, "damage": 7.0, "attack_speed": 2.0, "follow_rate": 10.0, "range": 11.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 14, "start": 1, "blind": 0.4, "aura_range": 10.0,
		"body": Color(0.55, 0.44, 0.26), "accent": Color(0.54, 0.25, 0.82),
	},
	Type.SHIELD_KNIGHT: {
		"scene": "res://Scene/Units/Soldiers/ShieldKnight.tscn",
		"model": "res://Assets/Units/shield_knight_common.glb", "icon": "res://Assets/UI/class_shield_knight.png",
		"name": "Shield Knight", "rank": &"common", "class": &"defender",
		"desc": "Frontline tank. Draws enemy attention and only fights up close.",
		"health": 260.0, "damage": 16.0, "attack_speed": 1.4, "follow_rate": 10.0, "range": 2.4,
		"bullet_speed": 0.0, "pierce": 0, "aoe": 0.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "hit", "row": -1,
		"proj": 0, "start": 2, "melee": true, "armor": 0.35, "taunt": 9.0, "radius": 0.42,
		"body": Color(0.66, 0.69, 0.74), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.SHIELD_KNIGHT_RARE: {
		"scene": "res://Scene/Units/Soldiers/ShieldKnightRare.tscn",
		"model": "res://Assets/Units/shield_knight_rare.glb", "icon": "res://Assets/UI/class_shield_knight_rare.png",
		"name": "Bulwark Knight", "rank": &"rare", "class": &"defender",
		"desc": "Heavy knight with a tower shield and a cleaving mace. Enemies cannot ignore him.",
		"health": 400.0, "damage": 26.0, "attack_speed": 1.3, "follow_rate": 10.0, "range": 2.8,
		"bullet_speed": 0.0, "pierce": 0, "aoe": 0.0, "spread": 0.0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "hit", "row": -1,
		"proj": 0, "start": 1, "melee": true, "armor": 0.5, "taunt": 12.0, "cleave": 1.6, "radius": 0.5,
		"body": Color(0.43, 0.47, 0.53), "accent": Color(0.54, 0.25, 0.82),
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


## One-line summary of what a class does beyond shooting (for the detail popup). "" = nothing special.
## Built from the numbers in DATA so it never goes stale when the balance changes.
static func ability_text(type: int) -> String:
	var d: Dictionary = DATA[type]
	var parts: Array[String] = []
	if float(d["heal"]) > 0.0:
		parts.append("Heals %d every %.1fs within %dm" % [int(d["heal"]), float(d["heal_interval"]), int(d["heal_range"])])
	if d.has("lob"):
		parts.append("Lobbed shell, %dm blast, targets the biggest crowd" % int(d["aoe"]))
	if d.has("buff_dmg"):
		parts.append("Allies within %dm: +%d%% damage, +%d%% fire rate" % [int(d["aura_range"]), roundi(float(d["buff_dmg"]) * 100.0), roundi(float(d["buff_rate"]) * 100.0)])
	if d.has("weaken"):
		parts.append("Enemies within %dm deal %d%% less damage (not bosses)" % [int(d["aura_range"]), roundi(float(d["weaken"]) * 100.0)])
	if d.has("blind"):
		parts.append("Enemies within %dm miss %d%% of their attacks (not bosses)" % [int(d["aura_range"]), roundi(float(d["blind"]) * 100.0)])
	if d.has("melee"):
		parts.append("Melee only, takes %d%% less damage" % roundi(float(d.get("armor", 0.0)) * 100.0))
	if d.has("taunt"):
		parts.append("Taunt: enemies within %dm attack this unit" % int(d["taunt"]))
	if d.has("cleave"):
		parts.append("Cleave hits nearby enemies")
	return "\n".join(parts)


## ---- Upgrade economy (starting balance, all values tunable) ----------------
const MAX_LEVEL := 10
const UPGRADE_GOLD_BASE := 500
const UPGRADE_SHARDS_BASE := 10

static var _scenes: Dictionary = {}


## Gold needed to go from `level` to `level + 1`. With `type` the class's rank scales it
## (RankData.upgrade_cost_mult: Rare x1.25, Super Rare x1.5, Legend x2, Unique x3). Without it: the base cost.
static func upgrade_gold(level: int, type: int = -1) -> int:
	var base := UPGRADE_GOLD_BASE * level
	if type < 0 or not DATA.has(type):
		return base
	return RankDB.get_rank(DATA[type]["rank"]).scale_upgrade_cost(base)


## Class shards needed to go from `level` to `level + 1`. With `type` the rank scales it
## (RankData.shards_to_unlock_mult: Rare x1.5, Super Rare x2, Legend x3, Unique x5).
static func upgrade_shards(level: int, type: int = -1) -> int:
	var base := UPGRADE_SHARDS_BASE * level
	if type < 0 or not DATA.has(type):
		return base
	return RankDB.get_rank(DATA[type]["rank"]).scale_unlock_shards(base)


## Soldier scene of a class (loaded lazily; scenes live in Scene/Units/Soldiers).
static func scene(type: int) -> PackedScene:
	if not _scenes.has(type):
		_scenes[type] = load(DATA[type]["scene"])
	return _scenes[type]


## Weighted random class among the classes the player owns.
static func random_type() -> int:
	var total := 0
	for k in SPAWN_WEIGHTS:
		if PlayerData.owns(k):
			total += int(SPAWN_WEIGHTS[k])
	if total <= 0:
		return Type.RIFLEMAN
	var roll := randi() % total
	for k in SPAWN_WEIGHTS:
		if not PlayerData.owns(k):
			continue
		roll -= int(SPAWN_WEIGHTS[k])
		if roll < 0:
			return k
	return Type.RIFLEMAN


## Save-file id of a class.
static func id_of(type: int) -> String:
	return String(IDS.get(type, ""))


## Class of a save-file id, or -1 for an unknown id.
static func type_of(id: String) -> int:
	for t in IDS:
		if IDS[t] == id:
			return int(t)
	return -1
