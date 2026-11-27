class_name Boss
extends Enemy
## Boss brain shared by the sixteen full bosses (one per round: levels 5, 10, 15 ... 80)
## and the sixty-four mini bosses (every other level, four per round). Sleeps until the army gets close, then cycles its pattern
## sequence from CONFIGS: FAN (projectile spread), SLAM (telegraphed ground smash),
## BOMBS (several small telegraphed blasts on random soldiers) and SUMMON
## (reinforcement wave of random enemies). Below 50% health it enrages: faster
## patterns and bigger fans. Dying ends the battle with a victory.

enum Pattern { FAN, SLAM, SUMMON, BOMBS }
enum Phase { SLEEP, WALK, WINDUP, RECOVER }

const SUMMON_WINDUP := 0.5
const SUMMON_RECOVER := 0.9
## Animation clip tried per pattern (models without clips ignore it).
const PATTERN_ANIMS := ["shoot", "slam", "roar", "attack"]

## Values every kind starts from. A CONFIGS entry only needs the keys it changes (config_of merges them).
const DEFAULTS := {
	"banner": "MINI BOSS", "wake": 48.0, "hold": 12.0, "death_blasts": 5,
	"sequence": [Pattern.SLAM, Pattern.FAN, Pattern.SUMMON],
	"fan_shots": 5, "fan_shots_enraged": 9, "fan_arc": 0.45, "fan_damage": 7.0, "fan_volleys": 2,
	"slam_radius": 3.2, "slam_damage": 32.0, "slam_time": 1.3,
	"bomb_count": 4, "bomb_count_enraged": 6, "bomb_radius": 2.4, "bomb_damage": 30.0, "bomb_time": 1.1,
	"summon_min": 8, "summon_max": 14,
	"recover": 1.8, "recover_enraged": 1.2,
}

## Per-kind behaviour. Every number is a starting balance value and can be tuned.
const CONFIGS := {
	EnemyDB.Kind.BOSS: {
		"banner": "BOSS!", "wake": 55.0, "hold": 13.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.SUMMON, Pattern.SLAM, Pattern.SUMMON, Pattern.FAN, Pattern.SLAM],
		"fan_shots": 9, "fan_shots_enraged": 13, "fan_arc": 0.66, "fan_damage": 8.0, "fan_volleys": 2,
		"slam_radius": 3.3, "slam_damage": 40.0, "slam_time": 1.4,
		"bomb_count": 0, "bomb_count_enraged": 0, "bomb_radius": 2.0, "bomb_damage": 0.0, "bomb_time": 1.0,
		"summon_min": 8, "summon_max": 20,
		"recover": 2.2, "recover_enraged": 1.4,
	},
	## Brawler: slams the ground over and over, calls a small wave now and then.
	EnemyDB.Kind.MINI_CRUSHER: {
		"banner": "MINI BOSS: CRUSHER", "wake": 48.0, "hold": 11.0, "death_blasts": 5,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"fan_shots": 5, "fan_shots_enraged": 7, "fan_arc": 0.4, "fan_damage": 6.0, "fan_volleys": 1,
		"slam_radius": 3.6, "slam_damage": 34.0, "slam_time": 1.2,
		"bomb_count": 0, "bomb_count_enraged": 0, "bomb_radius": 2.0, "bomb_damage": 0.0, "bomb_time": 1.0,
		"summon_min": 8, "summon_max": 12,
		"recover": 1.8, "recover_enraged": 1.2,
	},
	## Gunner mech: wide minigun fans fired from its Muzzle, sometimes a wave.
	EnemyDB.Kind.MINI_GATLING: {
		"banner": "MINI BOSS: GATLING", "wake": 48.0, "hold": 12.0, "death_blasts": 5,
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 7, "fan_shots_enraged": 11, "fan_arc": 0.5, "fan_damage": 6.0, "fan_volleys": 3,
		"slam_radius": 3.0, "slam_damage": 30.0, "slam_time": 1.2,
		"bomb_count": 0, "bomb_count_enraged": 0, "bomb_radius": 2.0, "bomb_damage": 0.0, "bomb_time": 1.0,
		"summon_min": 8, "summon_max": 14,
		"recover": 1.6, "recover_enraged": 1.1,
	},
	## Bomb chief: bombs land on random soldiers, plus the biggest reinforcement waves.
	EnemyDB.Kind.MINI_BOMBER: {
		"banner": "MINI BOSS: BOMBER CHIEF", "wake": 48.0, "hold": 12.0, "death_blasts": 5,
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"fan_shots": 5, "fan_shots_enraged": 7, "fan_arc": 0.4, "fan_damage": 6.0, "fan_volleys": 1,
		"slam_radius": 3.0, "slam_damage": 30.0, "slam_time": 1.2,
		"bomb_count": 4, "bomb_count_enraged": 6, "bomb_radius": 2.4, "bomb_damage": 30.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20,
		"recover": 1.7, "recover_enraged": 1.1,
	},
	## Warlord: mostly calls reinforcements, backed by a small fan and a slam.
	EnemyDB.Kind.MINI_COMMANDER: {
		"banner": "MINI BOSS: COMMANDER", "wake": 48.0, "hold": 12.0, "death_blasts": 5,
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_shots": 5, "fan_shots_enraged": 9, "fan_arc": 0.45, "fan_damage": 7.0, "fan_volleys": 2,
		"slam_radius": 3.2, "slam_damage": 32.0, "slam_time": 1.3,
		"bomb_count": 0, "bomb_count_enraged": 0, "bomb_radius": 2.0, "bomb_damage": 0.0, "bomb_time": 1.0,
		"summon_min": 10, "summon_max": 20,
		"recover": 1.8, "recover_enraged": 1.2,
	},
	## ---- Round 2 (ice) ----
	## Yeti King: heavy slams, ice shard fans, ice bombs, big summons.
	EnemyDB.Kind.BOSS_YETI: {
		"banner": "BOSS: YETI KING", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SLAM, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM, Pattern.BOMBS, Pattern.SUMMON],
		"fan_shots": 9, "fan_shots_enraged": 13, "fan_arc": 0.7, "fan_damage": 9.0, "fan_volleys": 2,
		"slam_radius": 3.8, "slam_damage": 46.0, "slam_time": 1.4,
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.4, "bomb_damage": 34.0, "bomb_time": 1.2,
		"summon_min": 10, "summon_max": 20, "recover": 2.0, "recover_enraged": 1.3,
	},
	## Icebreaker: ground slams.
	EnemyDB.Kind.MINI_ICEBREAKER: {
		"banner": "MINI BOSS: ICEBREAKER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 3.8, "slam_damage": 38.0, "slam_time": 1.2, "summon_min": 8, "summon_max": 12,
	},
	## Blizzard Gunner: wide twin-gun fans.
	EnemyDB.Kind.MINI_BLIZZARD: {
		"banner": "MINI BOSS: BLIZZARD GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 12, "fan_arc": 0.55, "fan_damage": 7.0, "fan_volleys": 3,
	},
	## Sled Rider: lobbed ice bombs and big waves.
	EnemyDB.Kind.MINI_SLED: {
		"banner": "MINI BOSS: SLED RIDER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 7, "bomb_radius": 2.4, "bomb_damage": 32.0, "summon_min": 12, "summon_max": 20,
	},
	## Frost Commander: calls reinforcements.
	EnemyDB.Kind.MINI_FROST_COMMANDER: {
		"banner": "MINI BOSS: FROST COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 8.0, "slam_damage": 34.0, "summon_min": 10, "summon_max": 20,
	},
	## ---- Round 3 (lava) ----
	## Magma Drake: fire fans from its Muzzle, fire rain, slams, big summons.
	EnemyDB.Kind.BOSS_DRAKE: {
		"banner": "BOSS: MAGMA DRAKE", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.BOMBS, Pattern.SUMMON, Pattern.FAN, Pattern.BOMBS, Pattern.SLAM],
		"fan_shots": 11, "fan_shots_enraged": 15, "fan_arc": 0.75, "fan_damage": 10.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 50.0, "slam_time": 1.3,
		"bomb_count": 6, "bomb_count_enraged": 9, "bomb_radius": 2.5, "bomb_damage": 38.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.9, "recover_enraged": 1.2,
	},
	## Forge Smasher: ground slams.
	EnemyDB.Kind.MINI_FORGE_SMASHER: {
		"banner": "MINI BOSS: FORGE SMASHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 42.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	## Flamecaster: fire fans from its Muzzle.
	EnemyDB.Kind.MINI_FLAMECASTER: {
		"banner": "MINI BOSS: FLAMECASTER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 8.0, "fan_volleys": 3,
	},
	## Lava Mortar: lava bombs and big waves.
	EnemyDB.Kind.MINI_LAVA_MORTAR: {
		"banner": "MINI BOSS: LAVA MORTAR",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 36.0, "summon_min": 12, "summon_max": 20,
	},
	## Foundry Overseer: calls reinforcements.
	EnemyDB.Kind.MINI_FOUNDRY_OVERSEER: {
		"banner": "MINI BOSS: FOUNDRY OVERSEER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 9.0, "slam_damage": 38.0, "summon_min": 12, "summon_max": 20,
	},
	## ---- Round 4 (graveyard) ----
	EnemyDB.Kind.MINI_GRAVEDIGGER: {
		"banner": "MINI BOSS: GRAVEDIGGER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 43.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_COFFIN_CANNON: {
		"banner": "MINI BOSS: COFFIN CANNON",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 8.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_PUMPKIN_BOMBER: {
		"banner": "MINI BOSS: PUMPKIN BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 37.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_LICH_COMMANDER: {
		"banner": "MINI BOSS: LICH COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 9.0, "slam_damage": 39.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_BONE_REAPER: {
		"banner": "BOSS: BONE REAPER", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SLAM, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM, Pattern.FAN, Pattern.SUMMON],
		"fan_shots": 11, "fan_shots_enraged": 15, "fan_arc": 0.8, "fan_damage": 10.0, "fan_volleys": 3,
		"slam_radius": 4.0, "slam_damage": 52.0, "slam_time": 1.3,
		"bomb_count": 6, "bomb_count_enraged": 9, "bomb_radius": 2.5, "bomb_damage": 39.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.87, "recover_enraged": 1.19,
	},
	## ---- Round 5 (desert) ----
	EnemyDB.Kind.MINI_SARCOPHAGUS_SMASHER: {
		"banner": "MINI BOSS: SARCOPHAGUS SMASHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 45.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_ANUBIS_GUNNER: {
		"banner": "MINI BOSS: ANUBIS GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 8.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_SCARAB_BOMBER: {
		"banner": "MINI BOSS: SCARAB BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 38.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_PHARAOH_COMMANDER: {
		"banner": "MINI BOSS: PHARAOH COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 10.0, "slam_damage": 40.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_GOLDEN_SPHINX: {
		"banner": "BOSS: GOLDEN SPHINX", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.BOMBS, Pattern.FAN, Pattern.SUMMON, Pattern.BOMBS, Pattern.SLAM, Pattern.FAN],
		"fan_shots": 11, "fan_shots_enraged": 15, "fan_arc": 0.75, "fan_damage": 11.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 53.0, "slam_time": 1.3,
		"bomb_count": 6, "bomb_count_enraged": 9, "bomb_radius": 2.7, "bomb_damage": 40.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.84, "recover_enraged": 1.18,
	},
	## ---- Round 6 (swamp) ----
	EnemyDB.Kind.MINI_BOG_BRUTE: {
		"banner": "MINI BOSS: BOG BRUTE", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 46.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_CAULDRON_WITCH: {
		"banner": "MINI BOSS: CAULDRON WITCH",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 9.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_TOADSTOOL_BOMBER: {
		"banner": "MINI BOSS: TOADSTOOL BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 39.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_HAG_COMMANDER: {
		"banner": "MINI BOSS: HAG COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 10.0, "slam_damage": 41.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_BOG_HYDRA: {
		"banner": "BOSS: BOG HYDRA", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.BOMBS, Pattern.FAN, Pattern.SLAM],
		"fan_shots": 12, "fan_shots_enraged": 16, "fan_arc": 0.85, "fan_damage": 11.0, "fan_volleys": 4,
		"slam_radius": 3.8, "slam_damage": 55.0, "slam_time": 1.3,
		"bomb_count": 6, "bomb_count_enraged": 9, "bomb_radius": 2.5, "bomb_damage": 41.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.81, "recover_enraged": 1.17,
	},
	## ---- Round 7 (junkyard) ----
	EnemyDB.Kind.MINI_WRECKER: {
		"banner": "MINI BOSS: WRECKER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 47.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_TURBINE_GUNNER: {
		"banner": "MINI BOSS: TURBINE GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 9.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_DUMPSTER_BOMBER: {
		"banner": "MINI BOSS: DUMPSTER BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 40.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_FOREMAN_COMMANDER: {
		"banner": "MINI BOSS: FOREMAN COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 10.0, "slam_damage": 43.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_SCRAP_TITAN: {
		"banner": "BOSS: SCRAP TITAN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.FAN, Pattern.SLAM, Pattern.BOMBS],
		"fan_shots": 12, "fan_shots_enraged": 16, "fan_arc": 0.75, "fan_damage": 11.0, "fan_volleys": 3,
		"slam_radius": 4.2, "slam_damage": 56.0, "slam_time": 1.3,
		"bomb_count": 7, "bomb_count_enraged": 10, "bomb_radius": 2.5, "bomb_damage": 43.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.78, "recover_enraged": 1.16,
	},
	## ---- Round 8 (neon city) ----
	EnemyDB.Kind.MINI_NEON_ENFORCER: {
		"banner": "MINI BOSS: NEON ENFORCER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 48.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_LASER_DJ: {
		"banner": "MINI BOSS: LASER DJ",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 9.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_DRONE_CARRIER: {
		"banner": "MINI BOSS: DRONE CARRIER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 41.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_NEON_OVERLORD: {
		"banner": "MINI BOSS: NEON OVERLORD",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 10.0, "slam_damage": 44.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_NEON_SHOGUN: {
		"banner": "BOSS: NEON SHOGUN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.SLAM, Pattern.FAN, Pattern.SUMMON, Pattern.BOMBS, Pattern.FAN],
		"fan_shots": 12, "fan_shots_enraged": 16, "fan_arc": 0.8, "fan_damage": 12.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 57.0, "slam_time": 1.3,
		"bomb_count": 7, "bomb_count_enraged": 10, "bomb_radius": 2.5, "bomb_damage": 44.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.75, "recover_enraged": 1.15,
	},
	## ---- Round 9 (space station) ----
	EnemyDB.Kind.MINI_AIRLOCK_CRUSHER: {
		"banner": "MINI BOSS: AIRLOCK CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 50.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_SATELLITE_GUNNER: {
		"banner": "MINI BOSS: SATELLITE GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 9.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_MINE_BOMBER: {
		"banner": "MINI BOSS: MINE BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 42.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_STATION_COMMANDER: {
		"banner": "MINI BOSS: STATION COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 11.0, "slam_damage": 45.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_ORBITAL_GUARDIAN: {
		"banner": "BOSS: ORBITAL GUARDIAN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.BOMBS, Pattern.FAN, Pattern.BOMBS, Pattern.SUMMON, Pattern.SLAM, Pattern.BOMBS],
		"fan_shots": 13, "fan_shots_enraged": 17, "fan_arc": 0.75, "fan_damage": 12.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 59.0, "slam_time": 1.3,
		"bomb_count": 7, "bomb_count_enraged": 10, "bomb_radius": 2.7, "bomb_damage": 45.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.72, "recover_enraged": 1.14,
	},
	## ---- Round 10 (insect hive) ----
	EnemyDB.Kind.MINI_MANDIBLE_CRUSHER: {
		"banner": "MINI BOSS: MANDIBLE CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 51.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_WASP_GUNNER: {
		"banner": "MINI BOSS: WASP GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 10.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_LADYBUG_BOMBER: {
		"banner": "MINI BOSS: LADYBUG BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 44.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_MANTIS_COMMANDER: {
		"banner": "MINI BOSS: MANTIS COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 11.0, "slam_damage": 46.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_HIVE_QUEEN: {
		"banner": "BOSS: HIVE QUEEN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.BOMBS, Pattern.SUMMON, Pattern.SLAM],
		"fan_shots": 13, "fan_shots_enraged": 17, "fan_arc": 0.75, "fan_damage": 12.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 60.0, "slam_time": 1.3,
		"bomb_count": 7, "bomb_count_enraged": 10, "bomb_radius": 2.5, "bomb_damage": 46.0, "bomb_time": 1.1,
		"summon_min": 14, "summon_max": 20, "recover": 1.69, "recover_enraged": 1.13,
	},
	## ---- Round 11 (toxic waste) ----
	EnemyDB.Kind.MINI_SLUDGE_SMASHER: {
		"banner": "MINI BOSS: SLUDGE SMASHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 52.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_HAZMAT_GUNNER: {
		"banner": "MINI BOSS: HAZMAT GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 10.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_BARREL_BOMBER: {
		"banner": "MINI BOSS: BARREL BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 45.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_MUTANT_COMMANDER: {
		"banner": "MINI BOSS: MUTANT COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 11.0, "slam_damage": 47.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_MUTANT_BEHEMOTH: {
		"banner": "BOSS: MUTANT BEHEMOTH", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SLAM, Pattern.BOMBS, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM, Pattern.FAN],
		"fan_shots": 13, "fan_shots_enraged": 17, "fan_arc": 0.75, "fan_damage": 12.0, "fan_volleys": 3,
		"slam_radius": 4.3, "slam_damage": 62.0, "slam_time": 1.3,
		"bomb_count": 8, "bomb_count_enraged": 11, "bomb_radius": 2.5, "bomb_damage": 47.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.66, "recover_enraged": 1.12,
	},
	## ---- Round 12 (crystal cave) ----
	EnemyDB.Kind.MINI_GEODE_CRUSHER: {
		"banner": "MINI BOSS: GEODE CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 53.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_PRISM_GUNNER: {
		"banner": "MINI BOSS: PRISM GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 10.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_BAT_BOMBER: {
		"banner": "MINI BOSS: BAT BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 46.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_GEM_COMMANDER: {
		"banner": "MINI BOSS: GEM COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 11.0, "slam_damage": 48.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_PRISM_GUARDIAN: {
		"banner": "BOSS: PRISM GUARDIAN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.BOMBS, Pattern.FAN, Pattern.SLAM, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 14, "fan_shots_enraged": 18, "fan_arc": 0.9, "fan_damage": 13.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 64.0, "slam_time": 1.3,
		"bomb_count": 8, "bomb_count_enraged": 11, "bomb_radius": 2.5, "bomb_damage": 48.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.63, "recover_enraged": 1.11,
	},
	## ---- Round 13 (pirate) ----
	EnemyDB.Kind.MINI_ANCHOR_SMASHER: {
		"banner": "MINI BOSS: ANCHOR SMASHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 55.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_BROADSIDE_GUNNER: {
		"banner": "MINI BOSS: BROADSIDE GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 10.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_POWDER_KEG_BOMBER: {
		"banner": "MINI BOSS: POWDER KEG BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 47.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_FIRST_MATE: {
		"banner": "MINI BOSS: FIRST MATE",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 12.0, "slam_damage": 49.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_IRON_GALLEON: {
		"banner": "BOSS: IRON GALLEON", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.FAN, Pattern.BOMBS, Pattern.SLAM, Pattern.FAN, Pattern.SUMMON, Pattern.BOMBS],
		"fan_shots": 14, "fan_shots_enraged": 18, "fan_arc": 0.75, "fan_damage": 13.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 65.0, "slam_time": 1.3,
		"bomb_count": 8, "bomb_count_enraged": 11, "bomb_radius": 2.8, "bomb_damage": 49.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.6, "recover_enraged": 1.1,
	},
	## ---- Round 14 (ghost ship) ----
	EnemyDB.Kind.MINI_BARNACLE_CRUSHER: {
		"banner": "MINI BOSS: BARNACLE CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 56.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_GHOST_GUNNER: {
		"banner": "MINI BOSS: GHOST GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 11.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_BUOY_BOMBER: {
		"banner": "MINI BOSS: BUOY BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 48.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_PHANTOM_ADMIRAL: {
		"banner": "MINI BOSS: PHANTOM ADMIRAL",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 12.0, "slam_damage": 51.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_SPECTRAL_ADMIRAL: {
		"banner": "BOSS: SPECTRAL ADMIRAL", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.BOMBS, Pattern.SUMMON, Pattern.SLAM, Pattern.FAN],
		"fan_shots": 14, "fan_shots_enraged": 18, "fan_arc": 0.75, "fan_damage": 13.0, "fan_volleys": 3,
		"slam_radius": 3.8, "slam_damage": 66.0, "slam_time": 1.3,
		"bomb_count": 8, "bomb_count_enraged": 11, "bomb_radius": 2.5, "bomb_damage": 51.0, "bomb_time": 1.1,
		"summon_min": 14, "summon_max": 20, "recover": 1.57, "recover_enraged": 1.09,
	},
	## ---- Round 15 (deep sea) ----
	EnemyDB.Kind.MINI_CRAB_CRUSHER: {
		"banner": "MINI BOSS: CRAB CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 57.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_ANGLER_GUNNER: {
		"banner": "MINI BOSS: ANGLER GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 11.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_PUFFER_BOMBER: {
		"banner": "MINI BOSS: PUFFER BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 49.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_TRITON_COMMANDER: {
		"banner": "MINI BOSS: TRITON COMMANDER",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 12.0, "slam_damage": 52.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_KRAKEN: {
		"banner": "BOSS: KRAKEN", "wake": 55.0, "hold": 14.0, "death_blasts": 9,
		"sequence": [Pattern.SLAM, Pattern.BOMBS, Pattern.SUMMON, Pattern.SLAM, Pattern.BOMBS, Pattern.FAN],
		"fan_shots": 15, "fan_shots_enraged": 19, "fan_arc": 0.75, "fan_damage": 14.0, "fan_volleys": 3,
		"slam_radius": 4.4, "slam_damage": 68.0, "slam_time": 1.3,
		"bomb_count": 9, "bomb_count_enraged": 12, "bomb_radius": 2.8, "bomb_damage": 52.0, "bomb_time": 1.1,
		"summon_min": 12, "summon_max": 20, "recover": 1.54, "recover_enraged": 1.08,
	},
	## ---- Round 16 (void) ----
	EnemyDB.Kind.MINI_OBSIDIAN_CRUSHER: {
		"banner": "MINI BOSS: OBSIDIAN CRUSHER", "hold": 11.0,
		"sequence": [Pattern.SLAM, Pattern.SLAM, Pattern.SUMMON, Pattern.SLAM],
		"slam_radius": 4.0, "slam_damage": 58.0, "slam_time": 1.1, "summon_min": 8, "summon_max": 12,
	},
	EnemyDB.Kind.MINI_ECLIPSE_GUNNER: {
		"banner": "MINI BOSS: ECLIPSE GUNNER",
		"sequence": [Pattern.FAN, Pattern.FAN, Pattern.SUMMON, Pattern.FAN],
		"fan_shots": 8, "fan_shots_enraged": 13, "fan_arc": 0.55, "fan_damage": 11.0, "fan_volleys": 3,
	},
	EnemyDB.Kind.MINI_METEOR_BOMBER: {
		"banner": "MINI BOSS: METEOR BOMBER",
		"sequence": [Pattern.BOMBS, Pattern.SUMMON, Pattern.BOMBS, Pattern.BOMBS, Pattern.SUMMON],
		"bomb_count": 5, "bomb_count_enraged": 8, "bomb_radius": 2.6, "bomb_damage": 50.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.MINI_VOID_HERALD: {
		"banner": "MINI BOSS: VOID HERALD",
		"sequence": [Pattern.SUMMON, Pattern.FAN, Pattern.SUMMON, Pattern.SLAM],
		"fan_damage": 13.0, "slam_damage": 53.0, "summon_min": 12, "summon_max": 20,
	},
	EnemyDB.Kind.BOSS_VOID_EMPEROR: {
		"banner": "BOSS: VOID EMPEROR", "wake": 55.0, "hold": 14.0, "death_blasts": 14,
		"sequence": [Pattern.FAN, Pattern.SLAM, Pattern.BOMBS, Pattern.SUMMON, Pattern.FAN, Pattern.SLAM, Pattern.BOMBS, Pattern.SUMMON],
		"fan_shots": 15, "fan_shots_enraged": 19, "fan_arc": 0.9, "fan_damage": 14.0, "fan_volleys": 3,
		"slam_radius": 4.5, "slam_damage": 70.0, "slam_time": 1.1,
		"bomb_count": 9, "bomb_count_enraged": 12, "bomb_radius": 2.9, "bomb_damage": 53.0, "bomb_time": 1.1,
		"summon_min": 14, "summon_max": 20, "recover": 1.51, "recover_enraged": 1.07,
	},
}

var cfg: Dictionary = DEFAULTS.merged(CONFIGS[EnemyDB.Kind.BOSS], true)

var _state: int = Phase.SLEEP
var _pattern: int = Pattern.FAN
var _timer: float = 0.0
var _seq_i: int = 0
var _volleys: int = 0
var _slam_pos: Vector3 = Vector3.ZERO
var _slam_total: float = 1.4
var _bomb_spots: Array = []
var _bomb_total: float = 1.0
var _tele_rings: Array = []
var _tele_fills: Array = []
var _tele_radius: float = 1.0
var _muzzle: Node3D = null
var _enraged: bool = false


func _init() -> void:
	kind = EnemyDB.Kind.BOSS


## Behaviour table of a kind (falls back to the Iron Colossus).
static func config_of(p_kind: int) -> Dictionary:
	return DEFAULTS.merged(CONFIGS.get(p_kind, CONFIGS[EnemyDB.Kind.BOSS]), true)


func _post_ready() -> void:
	debuff_scale = BOSS_DEBUFF_SCALE
	cfg = config_of(kind)
	_slam_total = float(cfg["slam_time"])
	_muzzle = _model.find_child("Muzzle", true, false) as Node3D


func _exit_tree() -> void:
	super._exit_tree()
	for n in _tele_rings:
		if is_instance_valid(n):
			(n as Node).queue_free()
	for n in _tele_fills:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_tele_rings.clear()
	_tele_fills.clear()


func _think(delta: float) -> void:
	var army := Game.army
	if army == null:
		return
	var hold := float(cfg["hold"])
	var to := army.position - position
	to.y = 0.0
	var dist := to.length()
	var face := to / dist if dist > 0.01 else Vector3(0, 0, 1)
	match _state:
		Phase.SLEEP:
			if dist < float(cfg["wake"]):
				_wake()
			return
		Phase.WALK:
			if dist > hold:
				position += face * speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_start_pattern(army)
		Phase.WINDUP:
			_timer -= delta
			_update_windup(delta, face)
		Phase.RECOVER:
			if dist > hold:
				position += face * speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = Phase.WALK
				_timer = 0.2
	_animate(delta, face, _state == Phase.WALK and dist > hold)


func _wake() -> void:
	_state = Phase.WALK
	_timer = 1.5
	Game.boss_spawned.emit(enemy_name, max_hp)
	Game.banner_requested.emit(str(cfg["banner"]), Color(1.0, 0.25, 0.2))
	AudioManager.play("boss_roar")
	Game.camera_rig.shake(0.35)


func _start_pattern(army: Army) -> void:
	var seq: Array = cfg["sequence"]
	_pattern = int(seq[_seq_i % seq.size()])
	_seq_i += 1
	_state = Phase.WINDUP
	_set_overlay(Mats.warn())
	if _anim != null:
		Models.play(_anim, PATTERN_ANIMS[_pattern])
	match _pattern:
		Pattern.FAN:
			_timer = 0.7
			_volleys = int(cfg["fan_volleys"])
		Pattern.SLAM:
			_slam_total = float(cfg["slam_time"]) * (0.75 if _enraged else 1.0)
			_timer = _slam_total
			_slam_pos = Vector3(army.position.x, 0.0, army.position.z)
			_show_telegraph([_slam_pos], float(cfg["slam_radius"]))
		Pattern.SUMMON:
			_timer = SUMMON_WINDUP
			AudioManager.play("boss_roar", 1.3)
		Pattern.BOMBS:
			_bomb_total = float(cfg["bomb_time"]) * (0.8 if _enraged else 1.0)
			_timer = _bomb_total
			var n := int(cfg["bomb_count_enraged"] if _enraged else cfg["bomb_count"])
			_bomb_spots = _pick_bomb_spots(n)
			_show_telegraph(_bomb_spots, float(cfg["bomb_radius"]))
			AudioManager.play("boss_roar", 1.15)


func _update_windup(_delta: float, face: Vector3) -> void:
	match _pattern:
		Pattern.FAN:
			if _timer <= 0.0:
				_fire_fan(face)
				_volleys -= 1
				if _volleys > 0:
					_timer = 0.35
				else:
					_finish_pattern()
		Pattern.SLAM:
			_fill_telegraph(clampf(1.0 - _timer / _slam_total, 0.0, 1.0))
			if _timer <= 0.0:
				_do_blast(_slam_pos, float(cfg["slam_radius"]), float(cfg["slam_damage"]))
				AudioManager.play("slam")
				Game.camera_rig.shake(0.5)
				_finish_pattern()
		Pattern.BOMBS:
			_fill_telegraph(clampf(1.0 - _timer / _bomb_total, 0.0, 1.0))
			if _timer <= 0.0:
				for spot: Vector3 in _bomb_spots:
					_do_blast(spot, float(cfg["bomb_radius"]), float(cfg["bomb_damage"]))
				AudioManager.play("explosion")
				Game.camera_rig.shake(0.35)
				_finish_pattern()
		Pattern.SUMMON:
			if _timer <= 0.0:
				_do_summon()
				_finish_pattern()


func _finish_pattern() -> void:
	_set_overlay(null)
	_hide_telegraph()
	_state = Phase.RECOVER
	if _pattern == Pattern.SUMMON:
		_timer = SUMMON_RECOVER * (0.7 if _enraged else 1.0)
	else:
		_timer = float(cfg["recover_enraged"] if _enraged else cfg["recover"])


func _fire_fan(face: Vector3) -> void:
	var army := Game.army
	var from := position + Vector3(0, 2.5, 0) + face * 2.0
	if is_instance_valid(_muzzle):
		from = _muzzle.global_position
	var dir := army.position - from
	dir.y = 0.0
	dir = dir.normalized()
	var shots := int(cfg["fan_shots_enraged"] if _enraged else cfg["fan_shots"])
	var arc := float(cfg["fan_arc"])
	var dmg := float(cfg["fan_damage"]) * Game.difficulty_scale()
	for i in shots:
		var t := 0.5 if shots < 2 else float(i) / float(shots - 1)
		var ang := lerpf(-arc, arc, t)
		Game.enemy_bullets.fire(from, dir.rotated(Vector3.UP, ang), 15.0, dmg, 45.0, 0, 0.0, ProjectilePool.KIND_BOSS, 0.3)
	AudioManager.play("boss_shoot")
	Game.camera_rig.shake(0.12)


## Area damage on the player's soldiers around `center` (slam and bombs).
func _do_blast(center: Vector3, blast_radius: float, base_damage: float) -> void:
	for s: Soldier in Game.soldiers.duplicate():
		var dx := s.position.x - center.x
		var dz := s.position.z - center.z
		var r := blast_radius + s.radius
		if dx * dx + dz * dz <= r * r:
			s.take_damage(base_damage * Game.difficulty_scale())
	Game.fx.explosion(center, blast_radius)


func _pick_bomb_spots(count: int) -> Array:
	var spots: Array = []
	var pool: Array = Game.soldiers.duplicate()
	pool.shuffle()
	for i in count:
		var p: Vector3 = Game.army.position
		if i < pool.size():
			p = (pool[i] as Soldier).position
		else:
			p += Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-2.0, 2.0))
		spots.append(Vector3(p.x, 0.0, p.z))
	return spots


func _do_summon() -> void:
	Enemy.spawn_minions(get_parent(), position, int(cfg["summon_min"]), int(cfg["summon_max"]))
	Game.camera_rig.shake(0.2)


## Red warning discs on the ground: one per spot, all the same radius.
func _show_telegraph(spots: Array, p_radius: float) -> void:
	_tele_radius = p_radius
	while _tele_rings.size() < spots.size():
		var ring := MeshInstance3D.new()
		ring.mesh = Mats.cylinder(1.0, 1.0, 0.04, 32)
		ring.material_override = Mats.unshaded(Color(1.0, 0.1, 0.1, 0.28))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(ring)
		_tele_rings.append(ring)
		var fill := MeshInstance3D.new()
		fill.mesh = Mats.cylinder(1.0, 1.0, 0.05, 32)
		fill.material_override = Mats.unshaded(Color(1.0, 0.15, 0.1, 0.5))
		fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(fill)
		_tele_fills.append(fill)
	for i in _tele_rings.size():
		var ring := _tele_rings[i] as MeshInstance3D
		var fill := _tele_fills[i] as MeshInstance3D
		if i < spots.size():
			var spot: Vector3 = spots[i]
			ring.position = spot + Vector3(0, 0.1, 0)
			ring.scale = Vector3(p_radius, 1.0, p_radius)
			ring.visible = true
			fill.position = spot + Vector3(0, 0.11, 0)
			fill.scale = Vector3(0.01, 1.0, 0.01)
			fill.visible = true
		else:
			ring.visible = false
			fill.visible = false


## 0..1: how far the warning discs have filled (blast happens at 1).
func _fill_telegraph(k: float) -> void:
	var s := maxf(_tele_radius * k, 0.01)
	for fill in _tele_fills:
		if is_instance_valid(fill):
			(fill as MeshInstance3D).scale = Vector3(s, 1.0, s)


func _hide_telegraph() -> void:
	for n in _tele_rings:
		if is_instance_valid(n):
			(n as MeshInstance3D).visible = false
	for n in _tele_fills:
		if is_instance_valid(n):
			(n as MeshInstance3D).visible = false


func _on_damaged() -> void:
	Game.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
	if not _enraged and hp < max_hp * 0.5 and hp > 0.0:
		_enraged = true
		speed *= 1.3
		Game.banner_requested.emit("ENRAGED!", Color(1.0, 0.4, 0.1))
		AudioManager.play("boss_roar", 1.15)
		Game.camera_rig.shake(0.3)


func _die() -> void:
	if dead:
		return
	dead = true
	Game.enemies.erase(self)
	_hide_telegraph()
	_set_overlay(null)
	_grant_rewards()
	Game.boss_defeated.emit()
	Game.camera_rig.shake(0.6)
	AudioManager.play("explosion")
	var tw := create_tween()
	for i in int(cfg["death_blasts"]):
		tw.tween_callback(_death_blast)
		tw.tween_interval(0.2)
	tw.tween_property(_model, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish_death)


func _death_blast() -> void:
	var p := position + Vector3(randf_range(-1.8, 1.8), randf_range(0.07, 0.6) * _bar_h, randf_range(-1.5, 1.5))
	Game.fx.explosion(p, 2.2)
	Game.camera_rig.shake(0.25)


func _finish_death() -> void:
	Game.end_battle(true)
	queue_free()
