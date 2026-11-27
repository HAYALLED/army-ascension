class_name EnvTheme
extends RefCounted
## Environment themes of the battlefield. Chapter 1 = meadow, 2 = ice, 3 = lava (levels 1-15).
## Later chapters have no env art yet and keep the plain look: of() returns {}.
## Add a theme: drop its glb folder in Assets/Ingame/Env/ and add an entry to THEMES.
##
## Prop entry keys (all props are glb files "<dir>/<prefix><n>.glb"):
##   n  file stem            w  pick weight           s  [min, max] scale
##   r  footprint radius (m, at scale 1; keeps props from overlapping)
##   x  closest |x| to the lane centre (the real minimum is also pushed out by the radius)
## "runs" are rows of one piece laid end to end along the road (len = piece length along z).
## "landmarks" are big props, 2-4 per side per level.

const DIR := "res://Assets/Ingame/Env/"
const LAST_THEMED_CHAPTER := 3

const THEMES := {
	1: {
		"dir": "r1_meadow", "prefix": "env_r1_", "backdrop": "backdrop_day",
		"ground": Color(0.435, 0.690, 0.310), "ground_alt": Color(0.540, 0.700, 0.290),
		"fill": [
			{"n": "tree_pine", "w": 3.0, "s": [0.8, 1.3], "r": 1.2, "x": 9.0},
			{"n": "tree_round", "w": 3.0, "s": [0.8, 1.3], "r": 1.5, "x": 9.0},
			{"n": "bush", "w": 3.0, "s": [0.8, 1.4], "r": 0.7, "x": 8.8},
			{"n": "rock_small", "w": 2.0, "s": [0.8, 1.4], "r": 0.6, "x": 8.8},
			{"n": "rock_cluster", "w": 1.0, "s": [0.8, 1.3], "r": 1.5, "x": 10.0},
			{"n": "hay_bale", "w": 1.5, "s": [0.9, 1.2], "r": 0.65, "x": 9.0},
			{"n": "crate_stack", "w": 0.6, "s": [0.9, 1.1], "r": 0.9, "x": 9.5},
		],
		"decals": [{"n": "flower_patch", "w": 1.0, "s": [0.8, 1.5], "x": 9.0}],
		"runs": [
			{"n": "fence", "len": 3.0, "x": 10.0},
			{"n": "sandbag_wall", "len": 2.6, "x": 9.8},
		],
		"landmarks": [
			{"n": "windmill", "r": 1.9, "x": 15.0},
			{"n": "watchtower", "r": 1.3, "x": 13.0},
			{"n": "army_tent", "r": 2.2, "x": 14.0},
		],
	},
	2: {
		"dir": "r2_ice", "prefix": "env_r2_", "backdrop": "backdrop_ice",
		"ground": Color(0.950, 0.970, 0.980), "ground_alt": Color(0.800, 0.880, 0.960),
		"fill": [
			{"n": "pine_snow_tall", "w": 3.0, "s": [0.8, 1.3], "r": 1.4, "x": 9.0},
			{"n": "pine_snow_small", "w": 3.0, "s": [0.8, 1.3], "r": 0.9, "x": 9.0},
			{"n": "dead_tree", "w": 1.5, "s": [0.8, 1.2], "r": 1.1, "x": 9.0},
			{"n": "snow_mound", "w": 2.5, "s": [0.8, 1.5], "r": 1.3, "x": 9.0},
			{"n": "ice_boulder", "w": 2.0, "s": [0.8, 1.4], "r": 0.8, "x": 9.0},
			{"n": "ice_crystal_cluster", "w": 1.0, "s": [0.8, 1.3], "r": 1.1, "x": 9.5},
			{"n": "snowman", "w": 0.4, "s": [0.9, 1.1], "r": 0.6, "x": 9.5},
			{"n": "broken_sled", "w": 0.4, "s": [0.9, 1.1], "r": 1.1, "x": 9.5},
		],
		"decals": [{"n": "frozen_pond", "w": 1.0, "s": [0.7, 1.3], "x": 11.5}],
		"runs": [{"n": "lamp_post", "len": 14.0, "x": 9.4}],
		"landmarks": [
			{"n": "igloo", "r": 1.8, "x": 13.0},
			{"n": "log_cabin", "r": 2.3, "x": 14.0},
			{"n": "icicle_rock_arch", "r": 3.0, "x": 16.0},
		],
	},
	3: {
		"dir": "r3_lava", "prefix": "env_r3_", "backdrop": "backdrop_lava",
		"ground": Color(0.230, 0.180, 0.210), "ground_alt": Color(0.300, 0.150, 0.130),
		"fill": [
			{"n": "charred_tree", "w": 3.0, "s": [0.8, 1.3], "r": 1.0, "x": 9.0},
			{"n": "basalt_rock", "w": 3.0, "s": [0.8, 1.4], "r": 0.9, "x": 9.0},
			{"n": "basalt_columns", "w": 1.5, "s": [0.8, 1.2], "r": 1.9, "x": 10.0},
			{"n": "ember_crystal", "w": 1.5, "s": [0.8, 1.3], "r": 0.8, "x": 9.0},
			{"n": "scrap_pile", "w": 1.2, "s": [0.8, 1.3], "r": 1.3, "x": 9.5},
			{"n": "anvil", "w": 0.4, "s": [0.9, 1.1], "r": 0.7, "x": 9.5},
			{"n": "gear_large", "w": 0.5, "s": [0.8, 1.2], "r": 1.6, "x": 10.0},
		],
		"decals": [
			{"n": "lava_cracks", "w": 2.0, "s": [0.8, 1.5], "x": 9.0},
			{"n": "lava_pool", "w": 1.0, "s": [0.7, 1.3], "x": 11.5},
		],
		"runs": [{"n": "pipe_run", "len": 4.0, "x": 9.6}],
		"landmarks": [
			{"n": "mini_volcano", "r": 4.6, "x": 20.0},
			{"n": "smokestack", "r": 1.2, "x": 13.0},
			{"n": "furnace", "r": 1.8, "x": 14.0},
		],
	},
}


## Theme of a 1-based level, or {} when its chapter has no env art yet.
static func of(level: int) -> Dictionary:
	var chapter := LevelDB.chapter_of(level)
	if chapter > LAST_THEMED_CHAPTER:
		return {}
	return THEMES.get(chapter, {})


## Mountain backdrop scene path for a level (the day backdrop when the chapter has no theme).
static func backdrop_path(level: int) -> String:
	var t := of(level)
	var stem: String = t["backdrop"] if not t.is_empty() else "backdrop_day"
	return DIR + stem + ".glb"


## Path of a theme prop, no extension: "<DIR>/<dir>/<prefix><name>".
static func prop_base(theme: Dictionary, prop_name: String) -> String:
	return "%s%s/%s%s" % [DIR, theme["dir"], theme["prefix"], prop_name]
