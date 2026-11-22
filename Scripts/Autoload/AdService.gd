extends Node
## Rewarded ads (autoload "AdService"). Callers do `if await AdService.show_rewarded("chest"): grant`.
## The backend is an AdProvider. Debug builds get MockAdProvider; a release build has no provider
## until a real adapter is assigned to `provider`, so ads are simply unavailable there.
## Owners of the "remove_ads" product skip the video and get the reward at once.

var provider: AdProvider = null

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if provider == null and OS.is_debug_build():
		provider = MockAdProvider.new(self)


## True when show_rewarded can pay out right now.
func is_available() -> bool:
	return PlayerData.has_purchase("remove_ads") or (provider != null and provider.is_ready())


## Plays one rewarded ad. Returns true only when the player earned the reward.
## Returns false at once when another ad is running or none is available.
func show_rewarded(placement: String) -> bool:
	if _busy or not is_available():
		return false
	if PlayerData.has_purchase("remove_ads"):
		return true
	_busy = true
	# Deferred: the await below is registered before the provider can possibly answer.
	provider.show.call_deferred(placement)
	var earned: bool = await provider.finished
	_busy = false
	return earned
