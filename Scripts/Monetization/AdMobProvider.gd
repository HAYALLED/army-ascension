extends AdProvider
## Real AdMob backend (Poing Studios "AdMob" plugin, Android). Created by AdService only on Android
## when the plugin is installed. No class_name on purpose: this script references plugin classes
## (MobileAds, RewardedAdLoader, ...), so nothing may load it unless the plugin exists.
## Both ads are preloaded once the SDK reports it is initialized; after each show the next one loads. A failed load retries every
## RETRY_SECONDS. Debug builds use Google's test ad units (showing / clicking real ads while
## developing can get the AdMob account suspended), release builds use the real ones.

const REWARDED_ID := "ca-app-pub-6794417930793183/2283672426"
const INTERSTITIAL_ID := "ca-app-pub-6794417930793183/9098287392"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const INTERSTITIAL_PLACEMENT := "interstitial"
const RETRY_SECONDS := 30.0

var _host: Node
var _rewarded_id: String
var _interstitial_id: String
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _rewarded_loading := false
var _interstitial_loading := false
var _active := false
var _earned := false
var _init_listener: OnInitializationCompleteListener
var _content_callback: FullScreenContentCallback
var _reward_listener: OnUserEarnedRewardListener


func _init(host: Node) -> void:
	_host = host
	var debug := OS.is_debug_build()
	_rewarded_id = TEST_REWARDED_ID if debug else REWARDED_ID
	_interstitial_id = TEST_INTERSTITIAL_ID if debug else INTERSTITIAL_ID
	# The SDK must finish initializing before any ad is requested.
	_init_listener = OnInitializationCompleteListener.new()
	_init_listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_load_rewarded()
		_load_interstitial()
	MobileAds.initialize(_init_listener)


## Rewarded readiness only: the interstitial is optional and show() answers false when it is missing.
func is_ready() -> bool:
	return _rewarded != null


func show(placement: String) -> void:
	if _active:
		finished.emit.call_deferred(false)
		return
	_active = true
	_earned = false
	if placement == INTERSTITIAL_PLACEMENT:
		_show_interstitial()
	else:
		_show_rewarded()


func _show_rewarded() -> void:
	var ad := _rewarded
	if ad == null:
		_finish.call_deferred(false)
		return
	_rewarded = null
	_content_callback = FullScreenContentCallback.new()
	_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_load_rewarded()
		_finish(_earned)
	_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_load_rewarded()
		_finish(false)
	_reward_listener = OnUserEarnedRewardListener.new()
	_reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_earned = true
	ad.full_screen_content_callback = _content_callback
	ad.show(_reward_listener)


func _show_interstitial() -> void:
	var ad := _interstitial
	if ad == null:
		_finish.call_deferred(false)
		return
	_interstitial = null
	_content_callback = FullScreenContentCallback.new()
	_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_load_interstitial()
		_finish(false)
	_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_load_interstitial()
		_finish(false)
	ad.full_screen_content_callback = _content_callback
	ad.show()


## Emits `finished` once per show(); late duplicate callbacks are ignored.
func _finish(earned: bool) -> void:
	if not _active:
		return
	_active = false
	finished.emit(earned)


func _load_rewarded() -> void:
	if _rewarded != null or _rewarded_loading:
		return
	_rewarded_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_rewarded_loading = false
		_retry(_load_rewarded)
	RewardedAdLoader.new().load(_rewarded_id, AdRequest.new(), callback)


func _load_interstitial() -> void:
	if _interstitial != null or _interstitial_loading:
		return
	_interstitial_loading = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_interstitial_loading = false
		_retry(_load_interstitial)
	InterstitialAdLoader.new().load(_interstitial_id, AdRequest.new(), callback)


func _retry(loader: Callable) -> void:
	_host.get_tree().create_timer(RETRY_SECONDS).timeout.connect(loader, CONNECT_ONE_SHOT)