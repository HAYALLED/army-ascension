extends Node
## Dev tool: steers the army automatically and prints a battle report.
## Run headless:  godot --headless --path . --fixed-fps 60 -- --sim
## (Battle adds this node only when the --sim argument is present.)

const TIMEOUT := 420.0

var _t: float = 0.0
var _log_t: float = 0.0
var _done: bool = false
var _restarted: bool = false


func _ready() -> void:
	Game.battle_won.connect(func() -> void: _finish("WIN"))
	Game.battle_lost.connect(func() -> void: _finish("LOSE"))


func _process(delta: float) -> void:
	var army := Game.army
	if army == null or _done:
		return
	_t += delta
	if "--sim-restart" in OS.get_cmdline_user_args() and not _restarted and _t > 6.0:
		_restarted = true
		print("[SIM] testing restart")
		Game.restart()
		return
	_log_t += delta
	if Game.state == Game.State.PLAYING:
		_steer(army)
	if _log_t >= 10.0:
		_log_t = 0.0
		var hp := 0.0
		var mx := 0.0
		for s in Game.soldiers:
			hp += s.hp
			mx += s.max_hp
		print("[SIM] t=%3.0f z=%4.0f soldiers=%2d hp=%3.0f%% enemies=%2d gold=%d kills=%d dmg=x%.2f rate=x%.2f" % [
			_t, army.position.z, Game.soldiers.size(), 100.0 * hp / maxf(mx, 1.0),
			Game.enemies.size(), Game.gold, Game.kills, Game.damage_buff, Game.rate_buff])
	if _log_t == 0.0:
		for e in Game.enemies:
			if e.kind == EnemyDB.Kind.BOSS:
				var tg := 0
				for s in Game.soldiers:
					if is_instance_valid(s.target) and s.target == e:
						tg += 1
				print("[SIM]   boss hp=%.0f/%.0f z=%.1f state=%d targeting=%d" % [e.hp, e.max_hp, e.position.z, e._state, tg])
	if _t > TIMEOUT:
		_finish("TIMEOUT")


func _steer(army: Army) -> void:
	var best_x := army.target_x
	var best_cost := INF
	var limit := army.max_offset()
	for step in range(-14, 15):
		var cx := step * 0.5
		if absf(cx) > limit:
			continue
		var cost := 0.0
		for w in Game.walls:
			if w["done"]:
				continue
			var dz: float = army.position.z - float(w["z"])
			if dz < -2.0 or dz > 22.0:
				continue
			var hits := 0
			for s in Game.soldiers:
				if absf(cx + s.slot.x - float(w["x"])) <= float(w["hw"]) + 0.3:
					hits += 1
			cost += hits * 1.5
		for g in Game.gates:
			if g.used:
				continue
			var gz: float = army.position.z - g.position.z
			if gz < 0.0 or gz > 30.0:
				continue
			var def: Dictionary = g.left_def if cx < 0.0 else g.right_def
			cost -= GatePair.worth(def)
		cost += absf(cx - army.target_x) * 0.05
		if cost < best_cost:
			best_cost = cost
			best_x = cx
	army.target_x = best_x


func _finish(result: String) -> void:
	if _done:
		return
	_done = true
	print("[SIM] RESULT=%s time=%.1fs survivors=%d kills=%d gold=%d shards=%d" % [
		result, _t, Game.soldiers.size(), Game.kills, Game.gold, Game.shards])
	get_tree().quit()
