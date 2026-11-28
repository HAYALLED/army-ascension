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
## Paid purchases remembered by token hash (newest last) so a store purchase is never granted twice.
const MAX_DELIVERED := 50
## Paid purchases that wait for the player's choice at the same time.
const MAX_PENDING := 8
## Battles a new player gets the NO RANDOM ADS perk for free (auto 2X gold, no random ads). 0 = no trial.
const NO_ADS_TRIAL_BATTLES := 0
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
## SHA-256 of the store token of every paid purchase already granted (never the raw token), newest last, MAX_DELIVERED entries.
var delivered_tokens: Array[String] = []
## Paid purchases not delivered yet because the player must pick a soldier first: {"id": product id, "hash": token hash}.
var pending_deliveries: Array[Dictionary] = []
## Unix time when the next free chest is ready (0 = ready now).
var chest_ready_at: int = 0
## Shop ad gold chest: ads watched so far (0 .. ChestDB.SHOP_GOLD_ADS - 1) and the unix time it can be earned again (0 = ready).
var gold_ads_watched: int = 0
var gold_ads_ready_at: int = 0
## Free-trial battles left of the NO RANDOM ADS perk (counts down once per battle until the product is bought).
var no_ads_trial_left: int = NO_ADS_TRIAL_BATTLES
## Soldier classes the player owns: SoldierDB.Type -> true.
var unlocked: Dictionary = {}
## Chests waiting on the home page, ChestDB.SLOTS entries; {} = empty slot (see ChestDB for the format).
var chest_slots: Array[Dictionary] = []
## Soldier classes taken to battle, in slot order. 1..MAX_EQUIPPED owned classes, never duplicated.
var equipped: Array[int] = []
## Time of day of the next battle: 0 morning, 1 evening, 2 night. Steps once after every finished
## battle (win or loss) while the "day_cycle" setting is on. See battle_day_phase().
const DAY_PHASES := 3
var day_phase: int = 0
## True once the beginner tutorial was finished or skipped. Saved as a top-level boolean (no schema bump).
var tutorial_done: bool = false


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
	delivered_tokens.clear()
	pending_deliveries.clear()
	chest_ready_at = 0
	gold_ads_watched = 0
	gold_ads_ready_at = 0
	no_ads_trial_left = NO_ADS_TRIAL_BATTLES
	unlocked.clear()
	for t in STARTER_TYPES:
		unlocked[t] = true
	equipped.assign(STARTER_TYPES.slice(0, MAX_EQUIPPED))
	chest_slots.clear()
	for i in ChestDB.SLOTS:
		chest_slots.append({})
	MissionManager.reset()
	day_phase = 0
	tutorial_done = false
	settings = {"vibration": true, "graphics_high": true, "sfx": true, "music": true, "day_cycle": true}
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


## Time of day the next battle uses; always morning while the day cycle setting is off.
func battle_day_phase() -> int:
	return day_phase if bool(settings.get("day_cycle", true)) else 0


## Called when a battle ends for good (win or loss). Does nothing while the day cycle is off.
func advance_day_phase() -> void:
	if bool(settings.get("day_cycle", true)):
		day_phase = (day_phase + 1) % DAY_PHASES


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
	gold = mini(gold + amount, MAX_CURRENCY)
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
	return unlocked.has(type) and SoldierDB.is_listed(type)


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
	if not SoldierDB.DATA.has(type) or not SoldierDB.is_listed(type) or unlocked.has(type):
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


## ---- Paid purchase bookkeeping (see PurchaseManager) -------------------------------

func is_delivered(token_hash: String) -> bool:
	return delivered_tokens.has(token_hash)


## Remembers a granted purchase (and drops its pending entry). Keeps the newest MAX_DELIVERED hashes.
func record_delivery(token_hash: String) -> void:
	if not delivered_tokens.has(token_hash):
		delivered_tokens.append(token_hash)
		while delivered_tokens.size() > MAX_DELIVERED:
			delivered_tokens.remove_at(0)
	for i in range(pending_deliveries.size() - 1, -1, -1):
		if pending_deliveries[i]["hash"] == token_hash:
			pending_deliveries.remove_at(i)
	shop_changed.emit()


func has_pending(token_hash: String) -> bool:
	for e in pending_deliveries:
		if e["hash"] == token_hash:
			return true
	return false


## Queues a paid purchase that needs a soldier pick. False when it is already queued or the queue is full.
func add_pending(id: String, token_hash: String) -> bool:
	if has_pending(token_hash) or pending_deliveries.size() >= MAX_PENDING:
		return false
	pending_deliveries.append({"id": id, "hash": token_hash})
	shop_changed.emit()
	return true


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


## Seconds until the shop ad gold chest can be earned again (0 = ready).
func gold_ads_seconds_left() -> int:
	return maxi(gold_ads_ready_at - int(Time.get_unix_time_from_system()), 0)


## One rewarded ad watched for the shop ad gold chest. Returns true when this was the last ad: the chest is
## due now, the progress is reset and the 1 week cooldown has started. False while ads are still missing
## or the cooldown runs (nothing is counted then).
func register_gold_ad() -> bool:
	if gold_ads_seconds_left() > 0:
		return false
	gold_ads_watched += 1
	var done := gold_ads_watched >= ChestDB.SHOP_GOLD_ADS
	if done:
		gold_ads_watched = 0
		gold_ads_ready_at = int(Time.get_unix_time_from_system()) + ChestDB.SHOP_GOLD_COOLDOWN
	shop_changed.emit()
	return done


## ---- Level progress --------------------------------------------------------

## Level the player plays next (highest completed + 1, capped at the last level).
## A fresh profile gets the tutorial automatically; a player who already won a level never is forced into it.
func should_start_tutorial() -> bool:
	return not tutorial_done and highest_level == 0


## Marks the tutorial finished (or skipped). With `reward` the first completion pays TutorialDB.REWARD_GOLD and
## puts one already-unlocked wooden chest into the first free slot. Returns {"gold": int, "slot": int}
## when the reward was paid (slot -1 = no free slot), {} otherwise. The reward is paid at most once.
func finish_tutorial(reward: bool) -> Dictionary:
	if tutorial_done:
		return {}
	tutorial_done = true
	if not reward:
		return {}
	add_gold(TutorialDB.REWARD_GOLD)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chest := ChestDB.roll(ChestDB.Tier.WOOD, rng)
	chest["ready_at"] = 0
	return {"gold": TutorialDB.REWARD_GOLD, "slot": add_chest(chest)}


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
		"billing": {"delivered": delivered_tokens.duplicate(), "pending": pending_deliveries.duplicate(true)},
		"timers": {"chest_ready_at": chest_ready_at, "gold_ads_ready_at": gold_ads_ready_at},
		"gold_ads_watched": gold_ads_watched,
		"no_ads_trial_left": no_ads_trial_left,
		"day_phase": day_phase,
		"tutorial_done": tutorial_done,
		"unlocked": _unlocked_ids(),
		"equipped": equipped.map(func(t: int) -> String: return SoldierDB.id_of(t)),
		"chests": chest_slots.map(func(c: Dictionary) -> Dictionary: return ChestDB.to_save(c)),
		"missions": MissionManager.to_save(),
		"settings": {
			"vibration": bool(settings.get("vibration", true)),
			"graphics_high": bool(settings.get("graphics_high", true)),
			"day_cycle": bool(settings.get("day_cycle", true)),
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

	var billing: Variant = d.get("billing")
	if billing is Dictionary:
		var done: Variant = billing.get("delivered")
		if done is Array:
			for h in done:
				if _is_hash(h) and not delivered_tokens.has(h):
					delivered_tokens.append(h)
			while delivered_tokens.size() > MAX_DELIVERED:
				delivered_tokens.remove_at(0)
		var waiting: Variant = billing.get("pending")
		if waiting is Array:
			for e in waiting:
				if pending_deliveries.size() < MAX_PENDING and e is Dictionary and e.get("id") is String \
						and ProductDB.has(e["id"]) and _is_hash(e.get("hash")) \
						and not delivered_tokens.has(e["hash"]) and not has_pending(e["hash"]):
					pending_deliveries.append({"id": e["id"], "hash": e["hash"]})

	var timers: Variant = d.get("timers")
	if timers is Dictionary:
		# Capped at one cooldown from now, so a bad value or a changed clock never locks the chest for long.
		var now := int(Time.get_unix_time_from_system())
		chest_ready_at = _read_int(timers.get("chest_ready_at"), 0, now + RewardDB.CHEST_COOLDOWN, 0)
		gold_ads_ready_at = _read_int(timers.get("gold_ads_ready_at"), 0, now + ChestDB.SHOP_GOLD_COOLDOWN, 0)

	gold_ads_watched = _read_int(d.get("gold_ads_watched"), 0, ChestDB.SHOP_GOLD_ADS - 1, 0)
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

	day_phase = _read_int(d.get("day_phase"), 0, DAY_PHASES - 1, 0)
	if d.get("tutorial_done") is bool:
		tutorial_done = d["tutorial_done"]
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


## True for a SHA-256 hex string (64 hex digits).
func _is_hash(v: Variant) -> bool:
	return v is String and (v as String).length() == 64 and (v as String).is_valid_hex_number()


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