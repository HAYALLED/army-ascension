extends Node
## Headless tests for the army-wide upgrades (Upgrades tab) vs the per-unit upgrades
## (Soldiers tab). Run: godot --headless --path . res://Tools/test_upgrades.tscn
## Never writes a save file.

const U := GlobalUpgradeDB.Id

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_costs()
	_test_buy()
	_test_separate_from_units()
	_test_effects()
	_test_save()
	_test_mini_levels()
	PlayerData.reset_to_defaults()
	get_tree().quit(0 if _failed == 0 else 1)


func _test_costs() -> void:
	var rises := true
	var resets := true
	for id in GlobalUpgradeDB.DATA:
		for lv in 60:
			var c := GlobalUpgradeDB.cost(id, lv)
			if lv % GlobalUpgradeDB.TIER_SIZE != 0:
				rises = rises and c > GlobalUpgradeDB.cost(id, lv - 1)
			else:
				# a new tier restarts at the level-1 price times TIER_MULT^tier (only the 10-rounding differs)
				var want := float(GlobalUpgradeDB.cost(id, 0)) * pow(GlobalUpgradeDB.TIER_MULT, float(GlobalUpgradeDB.tier_of(lv)))
				resets = resets and absf(float(c) - want) <= 10.0 and (lv == 0 or c < GlobalUpgradeDB.cost(id, lv - 1))
	_check("global costs rise inside a tier", rises)
	_check("every 10th level the price restarts at the level-1 price x1.75 per tier", resets)
	_check("tier 2 total costs 1.75x tier 1 total",
		absf(_tier_total(U.INCOME, 1) / _tier_total(U.INCOME, 0) - GlobalUpgradeDB.TIER_MULT) < 0.02)
	_check("costs stay inside the currency limit", GlobalUpgradeDB.cost(U.FIRE_RATE, 5000) <= PlayerData.MAX_CURRENCY and GlobalUpgradeDB.cost(U.FIRE_RATE, 5000) > 0)
	_check("tier helpers", GlobalUpgradeDB.tier_of(9.0) == 0 and GlobalUpgradeDB.tier_of(10.0) == 1 and GlobalUpgradeDB.tier_of(37.0) == 3
		and is_equal_approx(GlobalUpgradeDB.tier_progress(23.0), 0.3) and is_equal_approx(GlobalUpgradeDB.tier_progress(20.0), 0.0))
	_check("every tier has its own color, they repeat after the last",
		GlobalUpgradeDB.tier_color(0) != GlobalUpgradeDB.tier_color(1) and GlobalUpgradeDB.tier_color(0) != GlobalUpgradeDB.tier_color(2)
		and GlobalUpgradeDB.tier_color(GlobalUpgradeDB.TIER_COLORS.size()) == GlobalUpgradeDB.tier_color(0))
	_check("effect text", GlobalUpgradeDB.effect_text(U.INCOME, 3) == "+30%" and GlobalUpgradeDB.effect_text(U.REINFORCEMENTS, 2) == "+2")
	_check("ids round trip", GlobalUpgradeDB.from_id(GlobalUpgradeDB.id_of(U.HEALTH)) == U.HEALTH and GlobalUpgradeDB.from_id("nope") == -1)


func _tier_total(id: int, tier: int) -> float:
	var sum := 0.0
	for lv in range(tier * GlobalUpgradeDB.TIER_SIZE, (tier + 1) * GlobalUpgradeDB.TIER_SIZE):
		sum += GlobalUpgradeDB.cost(id, lv)
	return sum


func _test_buy() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.gold = 0
	_check("cannot buy without gold", not PlayerData.try_buy_upgrade(U.DAMAGE) and PlayerData.upgrade_level(U.DAMAGE) == 0)
	var cost := GlobalUpgradeDB.cost(U.DAMAGE, 0)
	PlayerData.gold = cost + 7
	_check("buy spends exactly the cost", PlayerData.try_buy_upgrade(U.DAMAGE) and PlayerData.gold == 7 and PlayerData.upgrade_level(U.DAMAGE) == 1)
	var all_bought := true
	for i in 45:
		PlayerData.gold = PlayerData.MAX_CURRENCY
		all_bought = all_bought and PlayerData.try_buy_upgrade(U.INCOME)
	_check("no level limit: Battle Income bought 45 times", all_bought and PlayerData.upgrade_level(U.INCOME) == 45)
	for i in 40:
		PlayerData.gold = PlayerData.MAX_CURRENCY
		PlayerData.try_buy_upgrade(U.REINFORCEMENTS)
	var cap := GlobalUpgradeDB.cap_of(U.REINFORCEMENTS)
	_check("Reinforcements stops at its army-size cap", PlayerData.upgrade_level(U.REINFORCEMENTS) == cap and PlayerData.start_bonus_soldiers() == cap)
	PlayerData.gold = PlayerData.MAX_CURRENCY
	_check("capped buy is refused and free", not PlayerData.try_buy_upgrade(U.REINFORCEMENTS) and PlayerData.gold == PlayerData.MAX_CURRENCY)
	_check("unknown id refused", not PlayerData.try_buy_upgrade(999))


func _test_separate_from_units() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.gold = 100000
	PlayerData.shards[SoldierDB.Type.SNIPER] = 100
	var rifle_before := PlayerData.level_of(SoldierDB.Type.RIFLEMAN)
	PlayerData.try_buy_upgrade(U.HEALTH)
	var ok := true
	for t in SoldierDB.DATA:
		ok = ok and PlayerData.level_of(t) == 1
	_check("army upgrade does not level any unit", ok)
	var lv_before := PlayerData.upgrade_level(U.HEALTH)
	PlayerData.try_upgrade(SoldierDB.Type.SNIPER)
	_check("unit upgrade levels only that unit", PlayerData.level_of(SoldierDB.Type.SNIPER) == 2
		and PlayerData.level_of(SoldierDB.Type.RIFLEMAN) == rifle_before
		and PlayerData.level_of(SoldierDB.Type.MEDIC) == 1)
	_check("unit upgrade does not touch army upgrades", PlayerData.upgrade_level(U.HEALTH) == lv_before)


func _test_effects() -> void:
	PlayerData.reset_to_defaults()
	_check("no upgrades = x1.0", is_equal_approx(PlayerData.damage_mult(), 1.0) and is_equal_approx(PlayerData.income_mult(), 1.0)
		and PlayerData.start_bonus_soldiers() == 0)
	PlayerData.upgrades[U.DAMAGE] = 4
	PlayerData.upgrades[U.HEALTH] = 2
	PlayerData.upgrades[U.FIRE_RATE] = 5
	PlayerData.upgrades[U.INCOME] = 5
	PlayerData.upgrades[U.REINFORCEMENTS] = 3
	var base := SoldierDB.stats(SoldierDB.Type.RIFLEMAN, 1)
	var s := SoldierDB.scene(SoldierDB.Type.RIFLEMAN).instantiate() as Soldier
	s.setup(1)
	_check("soldier damage = class stat x army damage", is_equal_approx(s.base_damage, float(base["damage"]) * 1.2))
	_check("soldier health = class stat x army health", is_equal_approx(s.max_hp, float(base["health"]) * 1.12))
	_check("soldier fire rate = class stat x army fire rate", is_equal_approx(s.attack_speed, float(base["attack_speed"]) * 1.2))
	s.free()
	_check("reinforcements = +3 start soldiers", PlayerData.start_bonus_soldiers() == 3)
	Game.gold = 100
	_check("income: victory +50%, defeat half of that", Game.final_gold(true) == 150 and Game.final_gold(false) == 75)
	Game.gold = 0


func _test_save() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.upgrades[U.INCOME] = 4
	PlayerData.upgrades[U.SHARD_LUCK] = 2
	var data := PlayerData.to_save()
	PlayerData.reset_to_defaults()
	PlayerData.apply_save(data)
	_check("upgrades survive save / load", PlayerData.upgrade_level(U.INCOME) == 4 and PlayerData.upgrade_level(U.SHARD_LUCK) == 2
		and PlayerData.upgrade_level(U.DAMAGE) == 0)
	PlayerData.apply_save({"upgrades": {"income": 999, "damage": -5, "health": "x", "bogus": 3, "fire_rate": 2.0}})
	_check("hostile upgrade data is clamped or ignored", PlayerData.upgrade_level(U.INCOME) == 999
		and PlayerData.upgrade_level(U.DAMAGE) == 0 and PlayerData.upgrade_level(U.HEALTH) == 0 and PlayerData.upgrade_level(U.FIRE_RATE) == 2)
	PlayerData.apply_save({"upgrades": {"income": 99999999, "reinforcements": 500}})
	_check("absurd levels are clamped, reinforcement effect stays at the cap",
		PlayerData.upgrade_level(U.INCOME) == GlobalUpgradeDB.MAX_SAVED_LEVEL and PlayerData.start_bonus_soldiers() == GlobalUpgradeDB.cap_of(U.REINFORCEMENTS))
	PlayerData.apply_save({"gold": 50})
	_check("old save without upgrades loads (all level 0)", PlayerData.upgrade_level(U.INCOME) == 0 and PlayerData.gold == 50)


func _test_mini_levels() -> void:
	var K := EnemyDB.Kind
	_check("levels 1-4 end with a mini boss, 5 and 10 with the Colossus",
		LevelDB.is_mini_level(1) and LevelDB.is_mini_level(4) and not LevelDB.is_mini_level(5)
		and not LevelDB.is_mini_level(10) and not LevelDB.is_mini_level(0))
	_check("mini boss order Crusher, Gatling, Bomber, Commander",
		LevelDB.boss_kind(1) == K.MINI_CRUSHER and LevelDB.boss_kind(2) == K.MINI_GATLING
		and LevelDB.boss_kind(3) == K.MINI_BOMBER and LevelDB.boss_kind(4) == K.MINI_COMMANDER)
	_check("level 5 boss = Iron Colossus, 10 = Yeti King, 15 = Magma Drake",
		LevelDB.boss_kind(5) == K.BOSS and LevelDB.boss_kind(10) == K.BOSS_YETI and LevelDB.boss_kind(15) == K.BOSS_DRAKE)
	_check("levels 6-9 use the round 2 mini bosses, 11-14 the round 3 ones",
		LevelDB.boss_kind(6) == K.MINI_ICEBREAKER and LevelDB.boss_kind(9) == K.MINI_FROST_COMMANDER
		and LevelDB.boss_kind(11) == K.MINI_FORGE_SMASHER and LevelDB.boss_kind(14) == K.MINI_FOUNDRY_OVERSEER)
