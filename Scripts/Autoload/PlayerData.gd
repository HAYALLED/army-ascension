extends Node
## Player profile (autoload "PlayerData"): wallet, soldier levels, class shards,
## army-wide upgrades, settings and level progress. Persistence lives in SaveManager; this script only
## serialises (to_save) and validates (apply_save). Every transaction is validated:
## balances never go negative.

signal wallet_changed()
signal soldier_changed(type: int)
signal global_upgrade_changed(id: int)
signal level_progress_changed()
signal settings_changed()
## Purchases or timers changed (shop, chest cooldown).
signal shop_changed()
## A chest slot was filled or emptied.
signal chests_changed()
## The equipped army (Prepare your army) changed.
signal equipped_changed()
## Gold was spent on an upgrade (soldier or army). Missions count it.
signal spent(gold: int)

## Dev starting wallet so the upgrade menu can be tried right away.
const START_GOLD := 600
const START_SHARDS := 12
const START_GEMS := 0
const MAX_CURRENCY := 999_999_999
## Battles a new player gets the NO RANDOM ADS perk for free (auto 2X gold, no random ads).
const NO_ADS_TRIAL_BATTLES := 3
## Soldier classes owned from the start. Every other class is unlocked by a chest.
const STARTER_TYPES := [
	SoldierDB.Type.RIFLEMAN, SoldierDB.Type.MACHINE_GUNNER, SoldierDB.Type.SNIPER,
	SoldierDB.Type.ROCKET, SoldierDB.Type.MEDIC,
]
## Most unit classes the player can bring to a battle (the army always needs at least 1).
const MAX_EQUIPPED := 5

var gold: int = START_GOLD
var gems: int = START_GEMS
var levels: Dictionary = {}   # SoldierDB.Type -> level
var shards: Dictionary = {}   # SoldierDB.Type -> shard count
## Army-wide upgrades (Upgrades tab): GlobalUpgradeDB.Id -> level. Per-unit levels above
## belong to the Soldiers tab; the two systems never touch each other.
var upgrades: Dictionary = {}
## Highest level number the player has completed (0 = none).
var highest_level: int = 0
## Player settings. sfx / music mirror AudioManager, which owns the live flags.
var settings: Dictionary = {}
## One-time shop products the player owns: ProductDB id -> true.
var purchases: Dictionary = {}
## Unix time when the next free chest is ready (0 = ready now).
var chest_ready_at: int = 0
## Free-trial battles left of the NO RANDOM ADS perk (counts down once per battle until the product is bought).
var no_ads_trial_left: int = NO_ADS_TRIAL_BATTLES
## Soldier classes the player owns: SoldierDB.Type -> true.
var unlocked: Dictionary = {}
## Chests waiting on the home page, ChestDB.SLOTS entries; {} = empty slot (see ChestDB for the format).
var chest_slots: Array[Dictionary] = []
## Soldier classes taken to battle, in slot order. 1..MAX_EQUIPPED owned classes, never duplicated.
var equipped: Array[int] = []


func _ready() -> void:
	reset_to_defaults()


## Fresh profile. Does not emit signals (see notify_all).
func reset_to_defaults() -> void:
	gold = START_GOLD
	gems = START_GEMS
	levels.clear()
	shards.clear()
	upgrades.clear()
	for t in SoldierDB.DATA:
		levels[t] = 1
		shards[t] = 0
	for u in GlobalUpgradeDB.DATA:
		upgrades[u] = 0
	shards[SoldierDB.Type.RIFLEMAN] = START_SHARDS
	highest_level = 0
	purchases.clear()
	chest_ready_at = 0
	no_ads_trial_left = NO_ADS_TRIAL_BATTLES
	unlocked.clear()
	for t in STARTER_TYPES:
		unlocked[t] = true
	equipped.assign(STARTER_TYPES.slice(0, MAX_EQUIPPED))
	chest_slots.clear()
	for i in ChestDB.SLOTS:
		chest_slots.append({})
	MissionManager.reset()
	settings = {"vibration": true, "graphics_high": true, "sfx": true, "music": true}
	_push_audio_settings()


## Tells every listener to refresh after a bulk change (load, reset).
func notify_all() -> void:
	wallet_changed.emit()
	for t in SoldierDB.DATA:
		soldier_changed.emit(t)
	for u in GlobalUpgradeDB.DATA:
		global_upgrade_changed.emit(u)
	level_progress_changed.emit()
	settings_changed.emit()
	shop_changed.emit()
	chests_changed.emit()
	equipped_changed.emit()


func set_setting(key: String, value: bool) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	settings_changed.emit()


func level_of(type: int) -> int:
	return int(levels.get(type, 1))


func shards_of(type: int) -> int:
	return int(shards.get(type, 0))


func total_shards() -> int:
	var n := 0
	for t in shards:
		n += int(shards[t])
	return n


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	wallet_changed.emit()


func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	gems = mini(gems + amount, MAX_CURRENCY)
	wallet_changed.emit()


## Spends gems. Returns false (and changes nothing) when the player has too few.
func spend_gems(amount: int) -> bool:
	if amount <= 0 or gems < amount:
		return false
	gems -= amount
	wallet_changed.emit()
	return true


func add_shards(type: int, amount: int) -> void:
	if amount <= 0 or not shards.has(type):
		return
	shards[type] += amount
	wallet_changed.emit()
	soldier_changed.emit(type)


func can_upgrade(type: int) -> bool:
	var lv := level_of(type)
	return owns(type) \
		and lv < SoldierDB.MAX_LEVEL \
		and gold >= SoldierDB.upgrade_gold(lv, type) \
		and shards_of(type) >= SoldierDB.upgrade_shards(lv, type)


## Spends gold + class shards and raises the level. Returns false (and
## changes nothing) when the player cannot afford it.
func try_upgrade(type: int) -> bool:
	if not can_upgrade(type):
		return false
	var lv := level_of(type)
	var cost := SoldierDB.upgrade_gold(lv, type)
	gold -= cost
	shards[type] -= SoldierDB.upgrade_shards(lv, type)
	levels[type] = lv + 1
	wallet_changed.emit()
	soldier_changed.emit(type)
	spent.emit(cost)
	return true


## ---- Army-wide upgrades (Upgrades tab) ---------------------------------------

func upgrade_level(id: int) -> int:
	return int(upgrades.get(id, 0))


func can_buy_upgrade(id: int) -> bool:
	if not GlobalUpgradeDB.DATA.has(id):
		return false
	var lv := upgrade_level(id)
	return not GlobalUpgradeDB.is_capped(id, lv) and lv < GlobalUpgradeDB.MAX_SAVED_LEVEL and gold >= GlobalUpgradeDB.cost(id, lv)


## Spends gold and raises the upgrade one level. Returns false (and changes nothing) when
## the player cannot afford it or the upgrade is capped (only Reinforcements has a cap).
func try_buy_upgrade(id: int) -> bool:
	if not can_buy_upgrade(id):
		return false
	var lv := upgrade_level(id)
	var cost := GlobalUpgradeDB.cost(id, lv)
	gold -= cost
	upgrades[id] = lv + 1
	wallet_changed.emit()
	global_upgrade_changed.emit(id)
	spent.emit(cost)
	return true


## Multipliers / bonuses read by the battle (1.0 = no upgrade bought).
func income_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.INCOME, upgrade_level(GlobalUpgradeDB.Id.INCOME))


func damage_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.DAMAGE, upgrade_level(GlobalUpgradeDB.Id.DAMAGE))


func health_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.HEALTH, upgrade_level(GlobalUpgradeDB.Id.HEALTH))


func rate_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.FIRE_RATE, upgrade_level(GlobalUpgradeDB.Id.FIRE_RATE))


func shard_mult() -> float:
	return 1.0 + GlobalUpgradeDB.value(GlobalUpgradeDB.Id.SHARD_LUCK, upgrade_level(GlobalUpgradeDB.Id.SHARD_LUCK))


## Extra soldiers every battle starts with.
func start_bonus_soldiers() -> int:
	return int(round(GlobalUpgradeDB.value(GlobalUpgradeDB.Id.REINFORCEMENTS, upgrade_level(GlobalUpgradeDB.Id.REINFORCEMENTS))))


## ---- Ownership, rewards, shop ------------------------------------------------

## True when the player has this soldier class (STARTER_TYPES, or unlocked by a chest).
func owns(type: int) -> bool:
	return unlocked.has(type)


func is_equipped(type: int) -> bool:
	return equipped.has(type)


## Adds an owned class to the army. Returns false (and changes nothing) when it is not owned,
## already equipped, or all MAX_EQUIPPED slots are taken.
func equip(type: int) -> bool:
	if not owns(type) or equipped.has(type) or equipped.size() >= MAX_EQUIPPED:
		return false
	equipped.append(type)
	equipped_changed.emit()
	return true


## Removes a class from the army. Returns false (and changes nothing) when it is not equipped or
## it is the last one: an army needs at least 1 unit.
func unequip(type: int) -> bool:
	if equipped.size() <= 1 or not equipped.has(type):
		return false
	equipped.erase(type)
	equipped_changed.emit()
	return true


## Gives the player a soldier class. Returns false when it is unknown or already owned.
func unlock(type: int) -> bool:
	if not SoldierDB.DATA.has(type) or unlocked.has(type):
		return false
	unlocked[type] = true
	soldier_changed.emit(type)
	return true


func owned_types() -> Array[int]:
	var out: Array[int] = []
	for t in SoldierDB.DATA:
		if owns(t):
			out.append(t)
	return out


## Applies a RewardDB reward ({"gold", "gems", "shards": {type: n}, "unlock": [type]}). Classes in
## "unlock" are unlocked first; shards for a class the player still does not own are dropped.
func grant(reward: Dictionary) -> void:
	add_gold(int(reward.get("gold", 0)))
	add_gems(int(reward.get("gems", 0)))
	for t in reward.get("unlock", []):
		unlock(int(t))
	var s: Dictionary = reward.get("shards", {})
	for t in s:
		if owns(t):
			add_shards(t, int(s[t]))


func has_purchase(id: String) -> bool:
	return purchases.has(id)


func mark_purchased(id: String) -> void:
	if ProductDB.is_once(id) and not purchases.has(id):
		purchases[id] = true
		shop_changed.emit()


## ---- Chest slots (chests dropped by beaten levels) ----------------------------

## Puts a chest into the first empty slot. Returns the slot index, or -1 when every slot is full.
func add_chest(chest: Dictionary) -> int:
	for i in chest_slots.size():
		if chest_slots[i].is_empty():
			chest_slots[i] = chest
			chests_changed.emit()
			return i
	return -1


## Opens the chest in `slot`: empties the slot and grants the contents. Returns the reward
## (RewardDB format), or {} when the slot is empty.
func open_chest(slot: int) -> Dictionary:
	if slot < 0 or slot >= chest_slots.size() or chest_slots[slot].is_empty() or chest_left(slot) > 0:
		return {}
	var reward := ChestDB.to_reward(chest_slots[slot])
	chest_slots[slot] = {}
	grant(reward)
	chests_changed.emit()
	return reward


## Seconds until the chest in `slot` can be opened (0 = ready or empty slot).
func chest_left(slot: int) -> int:
	if slot < 0 or slot >= chest_slots.size() or chest_slots[slot].is_empty():
		return 0
	return maxi(int(chest_slots[slot].get("ready_at", 0)) - int(Time.get_unix_time_from_system()), 0)


## Takes `seconds` off the wait of the chest in `slot` (a watched ad).
func speed_up_chest(slot: int, seconds: int) -> void:
	if chest_left(slot) <= 0:
		return
	chest_slots[slot]["ready_at"] = maxi(int(chest_slots[slot]["ready_at"]) - seconds, 0)
	chests_changed.emit()


## Pays ChestDB.skip_gems gems and makes the chest in `slot` ready now. False (nothing changes) when
## the slot is empty, already ready, or the player has too few gems.
func skip_chest_with_gems(slot: int) -> bool:
	var left := chest_left(slot)
	if left <= 0 or not spend_gems(ChestDB.skip_gems(left)):
		return false
	chest_slots[slot]["ready_at"] = 0
	chests_changed.emit()
	return true


## True while the NO RANDOM ADS perk is active: owned, or free trial battles left.
func has_no_ads() -> bool:
	return has_purchase("remove_ads") or no_ads_trial_left > 0


## One battle played: uses up a trial battle unless the product is owned.
func use_trial_battle() -> void:
	if not has_purchase("remove_ads") and no_ads_trial_left > 0:
		no_ads_trial_left -= 1
		shop_changed.emit()


func chest_seconds_left() -> int:
	return maxi(chest_ready_at - int(Time.get_unix_time_from_system()), 0)


func start_chest_cooldown() -> void:
	chest_ready_at = int(Time.get_unix_time_from_system()) + RewardDB.CHEST_COOLDOWN
	shop_changed.emit()


## ---- Level progress --------------------------------------------------------

## Level the player plays next (highest completed + 1, capped at the last level).
func unlocked_level() -> int:
	return mini(highest_level + 1, LevelDB.TOTAL_LEVELS)


## Records a completed level. Never lowers progress; out-of-range indices are ignored.
func complete_level(index: int) -> void:
	if index < 1 or index > LevelDB.TOTAL_LEVELS:
		return
	if index > highest_level:
		highest_level = index
		level_progress_changed.emit()


## ---- Serialisation ----------------------------------------------------------

## Save-file data (schema version 1, see Docs/SAVE_SYSTEM_PLAN.md).
func to_save() -> Dictionary:
	var soldiers := {}
	for t in SoldierDB.DATA:
		soldiers[SoldierDB.id_of(t)] = {"level": level_of(t), "shards": shards_of(t)}
	var global_upgrades := {}
	for u in GlobalUpgradeDB.DATA:
		global_upgrades[GlobalUpgradeDB.id_of(u)] = upgrade_level(u)
	return {
		"gold": gold,
		"gems": gems,
		"soldiers": soldiers,
		"upgrades": global_upgrades,
		"progress": {"highest_level": highest_level},
		"purchases": purchases.keys(),
		"timers": {"chest_ready_at": chest_ready_at},
		"no_ads_trial_left": no_ads_trial_left,
		"unlocked": _unlocked_ids(),
		"equipped": equipped.map(func(t: int) -> String: return SoldierDB.id_of(t)),
		"chests": chest_slots.map(func(c: Dictionary) -> Dictionary: return ChestDB.to_save(c)),
		"missions": MissionManager.to_save(),
		"settings": {
			"vibration": bool(settings.get("vibration", true)),
			"graphics_high": bool(settings.get("graphics_high", true)),
			"sfx": AudioManager.sfx_enabled,
			"music": AudioManager.music_enabled,
		},
	}


## Loads save data. Every field is validated; invalid or missing fields keep their
## defaults and unknown keys are dropped. Never throws.
func apply_save(d: Dictionary) -> void:
	reset_to_defaults()
	gold = _read_int(d.get("gold"), 0, MAX_CURRENCY, gold)
	gems = _read_int(d.get("gems"), 0, MAX_CURRENCY, gems)

	var soldiers: Variant = d.get("soldiers")
	if soldiers is Dictionary:
		for id in soldiers:
			if not (id is String):
				continue
			var type := SoldierDB.type_of(id)
			if type < 0 or not (soldiers[id] is Dictionary):
				continue
			var entry: Dictionary = soldiers[id]
			levels[type] = _read_int(entry.get("level"), 1, SoldierDB.MAX_LEVEL, level_of(type))
			shards[type] = _read_int(entry.get("shards"), 0, MAX_CURRENCY, shards_of(type))

	var saved_upgrades: Variant = d.get("upgrades")
	if saved_upgrades is Dictionary:
		for uid in saved_upgrades:
			if not (uid is String):
				continue
			var u := GlobalUpgradeDB.from_id(uid)
			if u < 0:
				continue
			upgrades[u] = _read_int(saved_upgrades[uid], 0, GlobalUpgradeDB.MAX_SAVED_LEVEL, 0)

	var progress: Variant = d.get("progress")
	if progress is Dictionary:
		highest_level = _read_int(progress.get("highest_level"), 0, LevelDB.TOTAL_LEVELS, highest_level)

	var saved_purchases: Variant = d.get("purchases")
	if saved_purchases is Array:
		for pid in saved_purchases:
			if pid is String and ProductDB.is_once(pid):
				purchases[pid] = true

	var timers: Variant = d.get("timers")
	if timers is Dictionary:
		# Capped at one cooldown from now, so a bad value or a changed clock never locks the chest for long.
		var now := int(Time.get_unix_time_from_system())
		chest_ready_at = _read_int(timers.get("chest_ready_at"), 0, now + RewardDB.CHEST_COOLDOWN, 0)

	no_ads_trial_left = _read_int(d.get("no_ads_trial_left"), 0, NO_ADS_TRIAL_BATTLES, NO_ADS_TRIAL_BATTLES)

	var saved_unlocked: Variant = d.get("unlocked")
	if saved_unlocked is Array:
		for uid in saved_unlocked:
			if uid is String and SoldierDB.type_of(uid) >= 0:
				unlocked[SoldierDB.type_of(uid)] = true

	# Needs `unlocked` loaded first. Anything invalid is dropped; an empty result keeps the default army.
	var saved_equipped: Variant = d.get("equipped")
	if saved_equipped is Array:
		var team: Array[int] = []
		for uid in saved_equipped:
			var t := SoldierDB.type_of(uid) if uid is String else -1
			if t >= 0 and owns(t) and not team.has(t) and team.size() < MAX_EQUIPPED:
				team.append(t)
		if not team.is_empty():
			equipped = team

	var saved_chests: Variant = d.get("chests")
	if saved_chests is Array:
		for i in mini(saved_chests.size(), chest_slots.size()):
			chest_slots[i] = ChestDB.from_save(saved_chests[i])

	MissionManager.apply_save(d.get("missions"))

	var saved_settings: Variant = d.get("settings")
	if saved_settings is Dictionary:
		for key in settings:
			if saved_settings.get(key) is bool:
				settings[key] = saved_settings[key]
	_push_audio_settings()
	notify_all()


func _unlocked_ids() -> Array:
	var ids: Array = []
	for t in SoldierDB.DATA:
		if unlocked.has(t):
			ids.append(SoldierDB.id_of(t))
	return ids


## Number validated and clamped to lo..hi; `fallback` when the value is not a finite number.
func _read_int(v: Variant, lo: int, hi: int, fallback: int) -> int:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return fallback
	var f := float(v)
	if not is_finite(f):
		return fallback
	return int(clampf(f, float(lo), float(hi)))


func _push_audio_settings() -> void:
	AudioManager.sfx_enabled = bool(settings.get("sfx", true))
	AudioManager.music_enabled = bool(settings.get("music", true))
	if not AudioManager.music_enabled:
		AudioManager.stop_music()
