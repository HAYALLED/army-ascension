extends Node
## Rewarded ads (autoload "AdService"). Callers do `if await AdService.show_rewarded("chest"): grant`.
## The backend is an AdProvider. Android with the AdMob plugin installed gets AdMobProvider (real ads;
## test ad units in debug builds). Otherwise debug builds get MockAdProvider; a release build without
## the plugin has no provider, so ads are simply unavailable there.
## NO RANDOM ADS (perk of the "remove_ads" product and of its free trial) only removes the random
## interstitial after battles; every rewarded ad (chests, shards, revive) is still watched.

const ADMOB_SCRIPT := "res://Scripts/Monetization/AdMobProvider.gd"

var provider: AdProvider = null

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if provider == null:
		provider = _make_admob()
	if provider == null and OS.is_debug_build():
		provider = MockAdProvider.new(self)


## Loaded by path, never referenced by name: without the plugin that script does not compile.
func _make_admob() -> AdProvider:
	if OS.get_name() != "Android":
		return null
	var script := load(ADMOB_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("AdService: AdMob plugin missing, real ads unavailable")
		return null
	return script.new(self) as AdProvider


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
## interstitial is not loaded. The player earns nothing from it.
func show_interstitial() -> void:
	if _busy or PlayerData.has_no_ads() or provider == null:
		return
	_busy = true
	provider.show.call_deferred("interstitial")
	await provider.finished
	_busy = false
