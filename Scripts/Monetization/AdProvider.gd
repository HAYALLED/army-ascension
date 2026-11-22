class_name AdProvider
extends RefCounted
## Contract of a rewarded-ad backend. AdService owns one. A real adapter (AdMob plugin, ...) extends
## this class, overrides is_ready() and show(), and is assigned to AdService.provider.
## show() must emit `finished` later (never inside the same call): true only when the player earned
## the reward, false when the ad failed or was closed early.

signal finished(earned: bool)


func is_ready() -> bool:
	return false


func show(_placement: String) -> void:
	finished.emit.call_deferred(false)
