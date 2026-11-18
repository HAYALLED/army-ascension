class_name GatePair
extends Node3D
## Two side-by-side gates spanning the lane. The army picks one by which
## half of the field its center is in when it crosses the line.

enum Effect { ADD, MULTIPLY, DAMAGE, RATE, SUBTRACT }

const GATE_X := 3.5
const GATE_W := 6.2

var left_def: Dictionary = {}
var right_def: Dictionary = {}
var used: bool = false
var _sides: Array = []


static func make_def(effect: int, value: float, risky: bool = false) -> Dictionary:
	var d := {"effect": effect, "value": value, "risky": risky}
	match effect:
		Effect.ADD:
			d["label"] = "+%d" % int(value)
			d["sub"] = "SOLDIERS"
			d["color"] = Color(0.2, 0.55, 1.0)
		Effect.MULTIPLY:
			d["label"] = "x%d" % int(value)
			d["sub"] = "SOLDIERS"
			d["color"] = Color(0.15, 0.8, 0.95)
		Effect.DAMAGE:
			d["label"] = "+%d%%" % int(round(value * 100.0))
			d["sub"] = "DAMAGE"
			d["color"] = Color(1.0, 0.5, 0.15)
		Effect.RATE:
			d["label"] = "+%d%%" % int(round(value * 100.0))
			d["sub"] = "FIRE RATE"
			d["color"] = Color(1.0, 0.85, 0.2)
		Effect.SUBTRACT:
			d["label"] = "-%d" % int(value)
			d["sub"] = "SOLDIERS"
			d["color"] = Color(0.9, 0.2, 0.2)
	if risky:
		d["sub"] = str(d["sub"]) + "  RISKY"
		d["color"] = Color(1.0, 0.7, 0.1)
	return d


## Rough value in "soldier equivalents" (used by the dev autopilot).
static func worth(def: Dictionary) -> float:
	var n := float(Game.soldiers.size())
	var v: float = def["value"]
	match int(def["effect"]):
		Effect.ADD:
			return v
		Effect.MULTIPLY:
			return n * (v - 1.0)
		Effect.DAMAGE, Effect.RATE:
			return n * v
		Effect.SUBTRACT:
			return -v
	return 0.0


func setup(z: float, left: Dictionary, right: Dictionary) -> void:
	position = Vector3(0, 0, z)
	left_def = left
	right_def = right


func _ready() -> void:
	Game.gates.append(self)
	var dark := Mats.solid(Color(0.15, 0.16, 0.2))
	var pillar := Models.find("res://Assets/Ingame/gate_pillar")
	for px in [-6.95, 0.0, 6.95]:
		if pillar != null:
			var p := pillar.instantiate() as Node3D
			p.position = Vector3(px, 0, 0)
			add_child(p)
		else:
			Mats.part(self, Mats.box(Vector3(0.3, 3.4, 0.3)), dark, Vector3(px, 1.7, 0))
	Mats.part(self, Mats.box(Vector3(14.2, 0.3, 0.3)), dark, Vector3(0, 3.45, 0))
	_sides.append(_build_side(left_def, -GATE_X))
	_sides.append(_build_side(right_def, GATE_X))


func _build_side(def: Dictionary, x: float) -> Node3D:
	var side := Node3D.new()
	side.position = Vector3(x, 0, 0)
	add_child(side)
	var col: Color = def["color"]
	Mats.part(side, Mats.box(Vector3(GATE_W, 0.03, 3.0)), Mats.unshaded(Color(col.r, col.g, col.b, 0.35)), Vector3(0, 0.09, 0))
	Mats.part(side, Mats.box(Vector3(GATE_W, 1.9, 0.12)), Mats.unshaded(Color(col.r, col.g, col.b, 0.5)), Vector3(0, 2.3, 0))
	var main := _label(str(def["label"]), 150, Vector3(0, 2.6, 0.1))
	side.add_child(main)
	var sub := _label(str(def["sub"]), 60, Vector3(0, 1.75, 0.1))
	side.add_child(sub)
	return side


func _label(text: String, size: int, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.011
	l.shaded = false
	l.outline_size = 22
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.modulate = Color.WHITE
	l.position = pos
	l.no_depth_test = false
	return l


func _process(_delta: float) -> void:
	if used or Game.army == null or Game.state != Game.State.PLAYING:
		return
	if Game.army.position.z <= position.z:
		used = true
		var left := Game.army.position.x < 0.0
		_apply(left_def if left else right_def, _sides[0] if left else _sides[1])


func _apply(def: Dictionary, node: Node3D) -> void:
	var army := Game.army
	var value: float = def["value"]
	match int(def["effect"]):
		Effect.ADD:
			army.add_random_soldiers(int(value))
		Effect.MULTIPLY:
			army.multiply_soldiers(value)
		Effect.DAMAGE:
			Game.add_damage_buff(value)
		Effect.RATE:
			Game.add_rate_buff(value)
		Effect.SUBTRACT:
			army.remove_soldiers(int(value))
	var bad := int(def["effect"]) == Effect.SUBTRACT
	AudioManager.play("gate_bad" if bad else "gate_good")
	Game.banner_requested.emit("%s %s" % [def["label"], str(def["sub"]).strip_edges()], def["color"])
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3(1.08, 1.12, 1.0), 0.12)
	tw.tween_property(node, "scale", Vector3.ONE, 0.2)
