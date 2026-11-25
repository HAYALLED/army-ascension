class_name SoldierDB
extends RefCounted
## Soldier class definitions + level scaling. Every number here is a
## starting balance value and can be tuned freely.

enum Type {
	RIFLEMAN, MACHINE_GUNNER, SNIPER, ROCKET, MEDIC,
	RIFLEMAN_RARE, MACHINE_GUNNER_RARE, SNIPER_RARE, ROCKET_RARE, MEDIC_SUPER_RARE,
	MORTAR, MORTAR_RARE, WEAKENER, WEAKENER_RARE, DRUMMER, DRUMMER_RARE,
	BLINDER, BLINDER_RARE, SHIELD_KNIGHT, SHIELD_KNIGHT_RARE,
	# Added with the rank-ladder models. Append only: scene files store the enum int.
	RIFLEMAN_SUPER_RARE, RIFLEMAN_LEGEND, MACHINE_GUNNER_SUPER_RARE, MACHINE_GUNNER_LEGEND, SNIPER_SUPER_RARE, SNIPER_LEGEND, ROCKET_SUPER_RARE, ROCKET_LEGEND, MEDIC_COMMON, MEDIC_LEGEND, MORTAR_SUPER_RARE, MORTAR_LEGEND, WEAKENER_SUPER_RARE, WEAKENER_LEGEND, DRUMMER_SUPER_RARE, DRUMMER_LEGEND, BLINDER_SUPER_RARE, BLINDER_LEGEND, SHIELD_KNIGHT_SUPER_RARE, SHIELD_KNIGHT_LEGEND,
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
	Type.RIFLEMAN_SUPER_RARE: "rifleman_super_rare",
	Type.RIFLEMAN_LEGEND: "rifleman_legend",
	Type.MACHINE_GUNNER_SUPER_RARE: "machine_gunner_super_rare",
	Type.MACHINE_GUNNER_LEGEND: "machine_gunner_legend",
	Type.SNIPER_SUPER_RARE: "sniper_super_rare",
	Type.SNIPER_LEGEND: "sniper_legend",
	Type.ROCKET_SUPER_RARE: "rocket_soldier_super_rare",
	Type.ROCKET_LEGEND: "rocket_soldier_legend",
	Type.MEDIC_COMMON: "medic_common",
	Type.MEDIC_LEGEND: "medic_legend",
	Type.MORTAR_SUPER_RARE: "mortar_super_rare",
	Type.MORTAR_LEGEND: "mortar_legend",
	Type.WEAKENER_SUPER_RARE: "weakener_super_rare",
	Type.WEAKENER_LEGEND: "weakener_legend",
	Type.DRUMMER_SUPER_RARE: "drummer_super_rare",
	Type.DRUMMER_LEGEND: "drummer_legend",
	Type.BLINDER_SUPER_RARE: "blinder_super_rare",
	Type.BLINDER_LEGEND: "blinder_legend",
	Type.SHIELD_KNIGHT_SUPER_RARE: "shield_knight_super_rare",
	Type.SHIELD_KNIGHT_LEGEND: "shield_knight_legend",
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
	Type.RIFLEMAN_SUPER_RARE: 2,
	Type.RIFLEMAN_LEGEND: 1,
	Type.MACHINE_GUNNER_SUPER_RARE: 2,
	Type.MACHINE_GUNNER_LEGEND: 1,
	Type.SNIPER_SUPER_RARE: 2,
	Type.SNIPER_LEGEND: 1,
	Type.ROCKET_SUPER_RARE: 2,
	Type.ROCKET_LEGEND: 1,
	Type.MEDIC_COMMON: 1,
	Type.MEDIC_LEGEND: 1,
	Type.MORTAR_SUPER_RARE: 2,
	Type.MORTAR_LEGEND: 1,
	Type.WEAKENER_SUPER_RARE: 2,
	Type.WEAKENER_LEGEND: 1,
	Type.DRUMMER_SUPER_RARE: 2,
	Type.DRUMMER_LEGEND: 1,
	Type.BLINDER_SUPER_RARE: 2,
	Type.BLINDER_LEGEND: 1,
	Type.SHIELD_KNIGHT_SUPER_RARE: 2,
	Type.SHIELD_KNIGHT_LEGEND: 1,
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
	Type.RIFLEMAN_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/RiflemanSuperRare.tscn",
		"model": "res://Assets/Units/rifleman_super_rare.glb", "icon": "res://Assets/UI/class_rifleman_super_rare.png",
		"name": "Vanguard Captain", "rank": &"super_rare", "class": &"assault",
		"desc": "Elite captain: energy-cell rifle, steel-blue armor and a long reach.",
		"health": 190.0, "damage": 22.0, "attack_speed": 3.8, "follow_rate": 10.0, "range": 19.0,
		"bullet_speed": 56.0, "pierce": 0, "aoe": 0.0, "spread": 0.015,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 1,
		"proj": 8,
		"body": Color(0.23, 0.37, 0.66), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.RIFLEMAN_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/RiflemanLegend.tscn",
		"model": "res://Assets/Units/rifleman_legend.glb", "icon": "res://Assets/UI/class_rifleman_legend.png",
		"name": "Golden Marshal", "rank": &"legend", "class": &"assault",
		"desc": "Legendary marshal. A golden rifle that punches through enemies at long range.",
		"health": 260.0, "damage": 34.0, "attack_speed": 4.2, "follow_rate": 10.0, "range": 21.0,
		"bullet_speed": 60.0, "pierce": 1, "aoe": 0.0, "spread": 0.01,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 1,
		"proj": 8,
		"body": Color(0.95, 0.94, 0.9), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.MACHINE_GUNNER_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/MachineGunnerSuperRare.tscn",
		"model": "res://Assets/Units/machine_gunner_super_rare.glb", "icon": "res://Assets/UI/class_machine_gunner_super_rare.png",
		"name": "Siege Gunner", "rank": &"super_rare", "class": &"assault",
		"desc": "Wide, heavy twin-barrel gunner. Huge ammo supply, brutal close range.",
		"health": 215.0, "damage": 12.0, "attack_speed": 8.0, "follow_rate": 10.0, "range": 14.0,
		"bullet_speed": 48.0, "pierce": 0, "aoe": 0.0, "spread": 0.085,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_mg", "row": 0,
		"proj": 9,
		"body": Color(0.95, 0.55, 0.12), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.MACHINE_GUNNER_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/MachineGunnerLegend.tscn",
		"model": "res://Assets/Units/machine_gunner_legend.glb", "icon": "res://Assets/UI/class_machine_gunner_legend.png",
		"name": "Gatling Warlord", "rank": &"legend", "class": &"assault",
		"desc": "Legendary rotary gatling. Shreds everything in front of the army.",
		"health": 300.0, "damage": 17.0, "attack_speed": 8.5, "follow_rate": 10.0, "range": 15.0,
		"bullet_speed": 50.0, "pierce": 0, "aoe": 0.0, "spread": 0.08,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_mg", "row": 0,
		"proj": 9,
		"body": Color(0.12, 0.12, 0.15), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.SNIPER_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/SniperSuperRare.tscn",
		"model": "res://Assets/Units/sniper_super_rare.glb", "icon": "res://Assets/UI/class_sniper_super_rare.png",
		"name": "Shadow Sniper", "rank": &"super_rare", "class": &"deadeye",
		"desc": "Stealth sniper with a half-ghillie cloak. Shots pierce far and strong.",
		"health": 105.0, "damage": 140.0, "attack_speed": 1.0, "follow_rate": 10.0, "range": 36.0,
		"bullet_speed": 105.0, "pierce": 4, "aoe": 0.0, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_sniper", "row": 3,
		"proj": 10, "prefer": &"strongest",
		"body": Color(0.17, 0.21, 0.27), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.SNIPER_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/SniperLegend.tscn",
		"model": "res://Assets/Units/sniper_legend.glb", "icon": "res://Assets/UI/class_sniper_legend.png",
		"name": "Ghillie Phantom", "rank": &"legend", "class": &"deadeye",
		"desc": "Legendary camouflage sniper, a walking bush. Pierces through whole lines.",
		"health": 135.0, "damage": 210.0, "attack_speed": 1.1, "follow_rate": 10.0, "range": 40.0,
		"bullet_speed": 110.0, "pierce": 5, "aoe": 0.0, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_sniper", "row": 3,
		"proj": 10, "prefer": &"strongest",
		"body": Color(0.24, 0.34, 0.16), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.ROCKET_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/RocketSoldierSuperRare.tscn",
		"model": "res://Assets/Units/rocket_soldier_super_rare.glb", "icon": "res://Assets/UI/class_rocket_soldier_super_rare.png",
		"name": "Rocketeer", "rank": &"super_rare", "class": &"explosive",
		"desc": "Missile pod and shoulder launcher. Rockets with a big blast radius.",
		"health": 160.0, "damage": 70.0, "attack_speed": 0.7, "follow_rate": 10.0, "range": 19.0,
		"bullet_speed": 28.0, "pierce": 0, "aoe": 4.2, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 2,
		"proj": 11,
		"body": Color(0.8, 0.2, 0.19), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.ROCKET_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/RocketSoldierLegend.tscn",
		"model": "res://Assets/Units/rocket_soldier_legend.glb", "icon": "res://Assets/UI/class_rocket_soldier_legend.png",
		"name": "Doomsday Bombardier", "rank": &"legend", "class": &"explosive",
		"desc": "Legendary triple launcher. Gigantic explosions that erase packed groups.",
		"health": 220.0, "damage": 105.0, "attack_speed": 0.75, "follow_rate": 10.0, "range": 20.0,
		"bullet_speed": 30.0, "pierce": 0, "aoe": 5.0, "spread": 0.02,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 2,
		"proj": 11,
		"body": Color(0.7, 0.08, 0.12), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.MEDIC_COMMON: {
		"scene": "res://Scene/Units/Soldiers/MedicCommon.tscn",
		"model": "res://Assets/Units/medic_common.glb", "icon": "res://Assets/UI/class_medic_common.png",
		"name": "Field Orderly", "rank": &"common", "class": &"support",
		"desc": "Basic field medic. Patches up nearby soldiers, slowly.",
		"health": 70.0, "damage": 3.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 9.0,
		"bullet_speed": 38.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 5.0, "heal_interval": 1.5, "heal_range": 5.0,
		"sfx": "shoot_rifle", "row": 3,
		"proj": 4,
		"body": Color(0.95, 0.95, 0.95), "accent": Color(0.25, 0.7, 0.35),
	},
	Type.MEDIC_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/MedicLegend.tscn",
		"model": "res://Assets/Units/medic_legend.glb", "icon": "res://Assets/UI/class_medic_legend.png",
		"name": "Archangel Surgeon", "rank": &"legend", "class": &"support",
		"desc": "Legendary healer with wings and a halo. Heals a huge area very fast.",
		"health": 190.0, "damage": 8.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 12.0,
		"bullet_speed": 44.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 24.0, "heal_interval": 0.8, "heal_range": 10.0,
		"sfx": "shoot_rifle", "row": 3,
		"proj": 12,
		"body": Color(0.96, 0.96, 0.96), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.MORTAR_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/MortarSuperRare.tscn",
		"model": "res://Assets/Units/mortar_super_rare.glb", "icon": "res://Assets/UI/class_mortar_super_rare.png",
		"name": "Artillery Sergeant", "rank": &"super_rare", "class": &"explosive",
		"desc": "Big mortar with a shell rack. Larger blasts, longer range.",
		"health": 130.0, "damage": 100.0, "attack_speed": 0.55, "follow_rate": 10.0, "range": 30.0,
		"bullet_speed": 20.0, "pierce": 0, "aoe": 4.2, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 3,
		"proj": 0, "prefer": &"cluster", "lob": true, "flight": 0.9,
		"body": Color(0.29, 0.32, 0.38), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.MORTAR_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/MortarLegend.tscn",
		"model": "res://Assets/Units/mortar_legend.glb", "icon": "res://Assets/UI/class_mortar_legend.png",
		"name": "Siege Marshal", "rank": &"legend", "class": &"explosive",
		"desc": "Legendary twin-tube golden mortar. Devastating blasts on the biggest crowd.",
		"health": 175.0, "damage": 150.0, "attack_speed": 0.6, "follow_rate": 10.0, "range": 32.0,
		"bullet_speed": 20.0, "pierce": 0, "aoe": 5.0, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "rocket_launch", "row": 3,
		"proj": 0, "prefer": &"cluster", "lob": true, "flight": 0.9,
		"body": Color(0.29, 0.32, 0.38), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.WEAKENER_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/WeakenerSuperRare.tscn",
		"model": "res://Assets/Units/weakener_super_rare.glb", "icon": "res://Assets/UI/class_weakener_super_rare.png",
		"name": "Plague Alchemist", "rank": &"super_rare", "class": &"debuffer",
		"desc": "Alchemist with glowing flasks. Cripples every enemy in a very wide area.",
		"health": 140.0, "damage": 10.0, "attack_speed": 2.2, "follow_rate": 10.0, "range": 12.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 13, "weaken": 0.5, "aura_range": 11.5,
		"body": Color(0.07, 0.21, 0.25), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.WEAKENER_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/WeakenerLegend.tscn",
		"model": "res://Assets/Units/weakener_legend.glb", "icon": "res://Assets/UI/class_weakener_legend.png",
		"name": "Hexlord Archdoctor", "rank": &"legend", "class": &"debuffer",
		"desc": "Legendary hex doctor. A curse that withers everything on the battlefield.",
		"health": 185.0, "damage": 14.0, "attack_speed": 2.4, "follow_rate": 10.0, "range": 13.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 13, "weaken": 0.6, "aura_range": 13.0,
		"body": Color(0.14, 0.09, 0.19), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.DRUMMER_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/DrummerSuperRare.tscn",
		"model": "res://Assets/Units/drummer_super_rare.glb", "icon": "res://Assets/UI/class_drummer_super_rare.png",
		"name": "Band Captain", "rank": &"super_rare", "class": &"support",
		"desc": "Marching-band captain. A thunderous rhythm over a wide area.",
		"health": 145.0, "damage": 7.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 9.0,
		"bullet_speed": 38.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 15, "buff_dmg": 0.28, "buff_rate": 0.35, "aura_range": 9.0,
		"body": Color(0.16, 0.31, 0.66), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.DRUMMER_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/DrummerLegend.tscn",
		"model": "res://Assets/Units/drummer_legend.glb", "icon": "res://Assets/UI/class_drummer_legend.png",
		"name": "War Drum Warlord", "rank": &"legend", "class": &"support",
		"desc": "Legendary war drummer. The whole army fights in a frenzy.",
		"health": 190.0, "damage": 10.0, "attack_speed": 1.5, "follow_rate": 10.0, "range": 9.0,
		"bullet_speed": 38.0, "pierce": 0, "aoe": 0.0, "spread": 0.05,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 15, "buff_dmg": 0.38, "buff_rate": 0.45, "aura_range": 10.5,
		"body": Color(0.56, 0.11, 0.14), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.BLINDER_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/BlinderSuperRare.tscn",
		"model": "res://Assets/Units/blinder_super_rare.glb", "icon": "res://Assets/UI/class_blinder_super_rare.png",
		"name": "Flare Operator", "rank": &"super_rare", "class": &"debuffer",
		"desc": "Spotlight and flare rack. Enemies over a huge area miss half their attacks.",
		"health": 140.0, "damage": 10.0, "attack_speed": 2.2, "follow_rate": 10.0, "range": 12.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 14, "blind": 0.5, "aura_range": 11.5,
		"body": Color(0.23, 0.25, 0.29), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.BLINDER_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/BlinderLegend.tscn",
		"model": "res://Assets/Units/blinder_legend.glb", "icon": "res://Assets/UI/class_blinder_legend.png",
		"name": "Solar Illuminator", "rank": &"legend", "class": &"debuffer",
		"desc": "Legendary light bearer. A blinding sun that ruins the aim of every enemy.",
		"health": 185.0, "damage": 14.0, "attack_speed": 2.4, "follow_rate": 10.0, "range": 13.0,
		"bullet_speed": 36.0, "pierce": 0, "aoe": 0.0, "spread": 0.06,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "shoot_rifle", "row": 2,
		"proj": 14, "blind": 0.6, "aura_range": 13.0,
		"body": Color(0.95, 0.94, 0.9), "accent": Color(0.85, 0.65, 0.18),
	},
	Type.SHIELD_KNIGHT_SUPER_RARE: {
		"scene": "res://Scene/Units/Soldiers/ShieldKnightSuperRare.tscn",
		"model": "res://Assets/Units/shield_knight_super_rare.glb", "icon": "res://Assets/UI/class_shield_knight_super_rare.png",
		"name": "Royal Guard", "rank": &"super_rare", "class": &"defender",
		"desc": "Royal guard with a spiked tower shield and a flanged mace. Draws all the fire.",
		"health": 580.0, "damage": 38.0, "attack_speed": 1.25, "follow_rate": 10.0, "range": 3.0,
		"bullet_speed": 0.0, "pierce": 0, "aoe": 0.0, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "hit", "row": -1,
		"proj": 0, "melee": true, "armor": 0.6, "taunt": 14.0, "cleave": 2.0, "radius": 0.55,
		"body": Color(0.66, 0.69, 0.74), "accent": Color(0.18, 0.48, 1.00),
	},
	Type.SHIELD_KNIGHT_LEGEND: {
		"scene": "res://Scene/Units/Soldiers/ShieldKnightLegend.tscn",
		"model": "res://Assets/Units/shield_knight_legend.glb", "icon": "res://Assets/UI/class_shield_knight_legend.png",
		"name": "Paladin Lord", "rank": &"legend", "class": &"defender",
		"desc": "Legendary paladin with a radiant tower shield and a golden warhammer.",
		"health": 800.0, "damage": 55.0, "attack_speed": 1.2, "follow_rate": 10.0, "range": 3.2,
		"bullet_speed": 0.0, "pierce": 0, "aoe": 0.0, "spread": 0,
		"heal": 0.0, "heal_interval": 0.0, "heal_range": 0.0,
		"sfx": "hit", "row": -1,
		"proj": 0, "melee": true, "armor": 0.7, "taunt": 16.0, "cleave": 2.5, "radius": 0.6,
		"body": Color(0.91, 0.72, 0.1), "accent": Color(0.85, 0.65, 0.18),
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
