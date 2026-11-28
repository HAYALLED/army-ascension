extends Node
## Rewarded ads (autoload "AdService"). Callers do `if await AdService.show_rewarded("chest"): grant`.
## The backend is an AdProvider. Android and the editor get AdMobProvider (real ads; test ad units in debug
## builds), created START_DELAY seconds after boot. On PC the plugin shows its own fake ad. A build without
## the plugin has no provider, so ads are simply unavailable there.
## NO RANDOM ADS (perk of the "remove_ads" product and of its free trial) only removes the random
## interstitial after battles; every rewarded ad (chests, shards, revive) is still watched.

const ADMOB_SCRIPT := "res://Scripts/Monetization/AdMobProvider.gd"
## The SDK starts this long after boot, so the engine and the first menu frame are already up.
const START_DELAY := 2.0
## Crash-loop guard (release builds only): when the SDK start was never confirmed on GUARD_LIMIT
## launches in a row, ads stay off for GUARD_PAUSE_DAYS so a device where the SDK crashes can still play.
const GUARD_PATH := "user://ads_guard.cfg"
const GUARD_LIMIT := 2
const GUARD_PAUSE_DAYS := 3

var provider: AdProvider = null

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if provider != null:
		return
	if OS.get_name() == "Android" or OS.has_feature("editor"):
		_start_admob()


## Waits START_DELAY, then starts AdMob. Ads count as unavailable until the SDK has loaded one.
func _start_admob() -> void:
	await get_tree().create_timer(START_DELAY).timeout
	if provider != null:
		return
	if not OS.is_debug_build():
		var step := guard_step(_guard_load(), int(Time.get_unix_time_from_system()))
		_guard_save(step)
		if step["blocked"]:
			push_warning("AdService: ads paused, the SDK did not start on recent launches")
			return
	provider = _make_admob()


## Loaded by path, never referenced by name: without the plugin that script does not compile.
func _make_admob() -> AdProvider:
	var script := load(ADMOB_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("AdService: AdMob plugin missing, real ads unavailable")
		return null
	return script.new(self, _on_sdk_ready) as AdProvider


## Called by AdMobProvider once the SDK reports it is initialized: the start did not crash.
func _on_sdk_ready() -> void:
	_guard_save({"pending": false, "crashes": 0, "until": 0})


## One launch of the crash-loop guard. `state` is the saved guard (may be empty or damaged).
## Returns the state to save plus "blocked": true when ads must stay off this launch.
static func guard_step(state: Dictionary, now: int) -> Dictionary:
	var crashes := _int_of(state.get("crashes"))
	var until := _int_of(state.get("until"))
	if state.get("pending") is bool and state["pending"]:
		crashes += 1
	if crashes >= GUARD_LIMIT:
		crashes = 0
		until = now + GUARD_PAUSE_DAYS * 86400
	var blocked := now < until
	return {"pending": not blocked, "crashes": crashes, "until": until, "blocked": blocked}


static func _int_of(value: Variant) -> int:
	return maxi(0, int(value)) if value is int or value is float else 0


func _guard_load() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(GUARD_PATH) != OK:
		return {}
	var state := {}
	for key in ["pending", "crashes", "until"]:
		state[key] = cfg.get_value("guard", key, null)
	return state


func _guard_save(state: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for key in ["pending", "crashes", "until"]:
		cfg.set_value("guard", key, state[key])
	cfg.save(GUARD_PATH)


## True when show_rewarded can pay out right now.
func is_available() -> bool:
	return provider != null and provider.is_ready()


## Plays one rewarded ad. Returns true only when the player earned the reward.
## Returns false at once when another ad is running or none is available.
func show_rewarded(placement: String) -> bool:
	if _busy or not is_available():
		return false
	_busy = true
	# Deferred: the await below is registered before the provider can possibly answer.
	provider.show.call_deferred(placement)
	var earned: bool = await provider.finished
	_busy = false
	return earned


## Random ad between battles (Game decides when). Skipped when the NO RANDOM ADS perk is active,
## when there is no provider or another ad is running; the provider answers false at once when its
## interstitial is not loaded. The player earns nothing from it. Returns true when the ad was shown.
func show_interstitial() -> bool:
	if _busy or PlayerData.has_no_ads() or provider == null:
		return false
	_busy = true
	provider.show.call_deferred("interstitial")
	var shown: bool = await provider.finished
	_busy = false
	return shown