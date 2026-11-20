class_name Loading
extends Control
## Loading screen: loads the battle scene in a thread, then switches to it.

const TARGET := "res://Scene/Ingame/Battle.tscn"
const MIN_TIME := 0.7

@onready var _bar: TextureProgressBar = %Bar

var _t: float = 0.0
var _done: bool = false


func _ready() -> void:
	ResourceLoader.load_threaded_request(TARGET)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(TARGET, progress)
	var p: float = progress[0] if progress.size() > 0 else 0.0
	_bar.value = maxf(_bar.value, minf(p, _t / MIN_TIME) * 100.0)
	if status == ResourceLoader.THREAD_LOAD_LOADED and _t >= MIN_TIME:
		_done = true
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(TARGET))
