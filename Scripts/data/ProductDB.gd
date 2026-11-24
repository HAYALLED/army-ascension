class_name ProductDB
extends RefCounted
## Shop products (ids match the item_id fields in ShopPage.tscn and the store product ids).
## reward: gold / gems / shards (shards go to the soldier the player picks when pick_unit is true) / chest.
## once: bought one time, saved in PlayerData.purchases. available false: shown as SOON.

const PRODUCTS := {
	"gold_s": {"reward": {"gold": 500}},
	"gold_m": {"reward": {"gold": 1500}},
	"gold_l": {"reward": {"gold": 5000}},
	"gems_s": {"reward": {"gems": 40}},
	"gems_m": {"reward": {"gems": 150}},
	"gems_l": {"reward": {"gems": 500}},
	"starter_bundle": {"reward": {"gold": 1000, "shards": 30, "chest": true}, "pick_unit": true, "once": true},
	"remove_ads": {"reward": {}, "once": true,
		"note": "No more ad after every 2 games! Reward ads now pay out instantly."},
}


static func has(id: String) -> bool:
	return PRODUCTS.has(id)


static func get_product(id: String) -> Dictionary:
	return PRODUCTS.get(id, {})


static func is_once(id: String) -> bool:
	return bool(get_product(id).get("once", false))


static func is_available(id: String) -> bool:
	return has(id) and bool(get_product(id).get("available", true))


## Reward of a product in the RewardDB format. `unit` is the picked soldier class.
static func reward_of(id: String, unit: int, rng: RandomNumberGenerator) -> Dictionary:
	var spec: Dictionary = get_product(id).get("reward", {})
	var r := RewardDB.empty()
	r["gold"] = int(spec.get("gold", 0))
	r["gems"] = int(spec.get("gems", 0))
	if int(spec.get("shards", 0)) > 0 and unit >= 0:
		r["shards"][unit] = int(spec["shards"])
	if bool(spec.get("chest", false)):
		r = RewardDB.merge(r, RewardDB.roll_chest(rng))
	return r
