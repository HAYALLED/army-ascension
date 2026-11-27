extends Node
## Save file I/O (autoload "SaveManager"): atomic write, backup, checksum, versioning.
## Writes are event-driven only: PlayerData signals mark the profile dirty and one
## deferred flush writes it. See Docs/SAVE_SYSTEM_PLAN.md.

## Current schema version. Bump only when an existing field is renamed, moved or changes meaning.
const VERSION := 1

## Plain var so tests can redirect it. .bak / .tmp / .corrupt derive from it.
var save_path := "user://save.json"
## False when the command line has --sim or --no-save: every function below is a no-op.
var enabled := true
## True when the file on disk has a newer version than VERSION: nothing is ever written.
var read_only := false
## Number of completed writes (exposed for tests).
var write_count := 0

var _dirty := false
var _scheduled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	enabled = not ("--sim" in args or "--no-save" in args)
	load_game()
	if enabled:
		Game.level_index = PlayerData.unlocked_level()
	# Connect after the load so loading itself never triggers a write.
	PlayerData.wallet_changed.connect(request_save)
	PlayerData.soldier_changed.connect(_on_soldier_changed)
	PlayerData.level_progress_changed.connect(request_save)
	PlayerData.settings_changed.connect(request_save)
	PlayerData.shop_changed.connect(request_save)
	PlayerData.equipped_changed.connect(request_save)
	MissionManager.changed.connect(request_save)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			save_now()


## Marks the profile dirty. Many calls in one frame produce one write.
func request_save() -> void:
	if not enabled or read_only:
		return
	_dirty = true
	if not _scheduled:
		_scheduled = true
		_flush.call_deferred()


## Writes immediately when dirty. Used at critical moments and on app pause / quit.
func save_now() -> void:
	if not enabled or read_only or not _dirty:
		return
	if _write():
		_dirty = false


## Writes now and returns true only when the data is really on disk. Used before a paid purchase is
## confirmed to the store. False when the save is read-only or the write failed. With saving disabled
## (--sim / --no-save) it is true in test runs and false on a device, where nothing may be confirmed unsaved.
func persist_now() -> bool:
	if read_only:
		return false
	if not enabled:
		return not OS.has_feature("android")
	_dirty = true
	if not _write():
		return false
	_dirty = false
	return true


## Dev helper: deletes every save file and resets the profile.
func wipe() -> void:
	if not enabled:
		return
	for path in [save_path, _bak(), _tmp(), _corrupt()]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_dirty = false
	read_only = false
	PlayerData.reset_to_defaults()
	PlayerData.notify_all()
	Game.level_index = 1


## Loads the profile: main file, then backup, then defaults.
func load_game() -> void:
	if not enabled:
		return
	read_only = false
	var r: Variant = _read(save_path)
	if r == null and FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, _corrupt())
	var from_bak := false
	if r == null:
		r = _read(_bak())
		from_bak = r != null
	if r == null:
		PlayerData.reset_to_defaults()
		PlayerData.notify_all()
		return
	if int(r["version"]) > VERSION:
		read_only = true
		PlayerData.reset_to_defaults()
		PlayerData.notify_all()
		return
	PlayerData.apply_save(_migrate(r["data"], int(r["version"])))
	if from_bak:
		request_save()


func _flush() -> void:
	_scheduled = false
	save_now()


func _on_soldier_changed(_type: int) -> void:
	request_save()


## Reads and verifies one file. Returns {"version": int, "data": Dictionary} or null
## (missing, unreadable, malformed, checksum mismatch).
func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var env: Variant = _parse(text)
	if not (env is Dictionary):
		return null
	var v: Variant = env.get("version")
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return null
	var vf := float(v)
	if not is_finite(vf) or vf < 1.0 or vf != floorf(vf) or vf > 1.0e9:
		return null
	var sum: Variant = env.get("sum")
	var body: Variant = env.get("body")
	if not (sum is String) or not (body is String):
		return null
	if (body as String).sha256_text() != sum:
		return null
	var data: Variant = _parse(body)
	if not (data is Dictionary):
		return null
	return {"version": int(vf), "data": data}


## JSON text -> Variant, or null when malformed (no error spam for corrupt files).
func _parse(text: String) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## Steps a save forward one schema version at a time. v1 has no steps yet:
## add a `match` case per version when a field is renamed, moved or re-meant.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	while from_version < VERSION:
		match from_version:
			_:
				pass
		from_version += 1
	return data


## Writes tmp, backs up the last valid file, then swaps tmp in. The real file is only
## replaced after the new one is complete. Returns false (and logs) on failure.
func _write() -> bool:
	var body := JSON.stringify(PlayerData.to_save())
	var env := JSON.stringify({
		"version": VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"sum": body.sha256_text(),
		"body": body,
	})
	var tmp := _tmp()
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(env)
	f.close()
	if _read(tmp) == null:
		push_error("SaveManager: temp file failed verification, save skipped")
		DirAccess.remove_absolute(tmp)
		return false
	if _read(save_path) != null:
		DirAccess.copy_absolute(save_path, _bak())
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		DirAccess.remove_absolute(save_path)
		if DirAccess.rename_absolute(tmp, save_path) != OK:
			push_error("SaveManager: cannot replace %s" % save_path)
			return false
	write_count += 1
	return true


func _bak() -> String:
	return save_path.get_basename() + ".bak"


func _tmp() -> String:
	return save_path.get_basename() + ".tmp"


func _corrupt() -> String:
	return save_path.get_basename() + ".corrupt"
