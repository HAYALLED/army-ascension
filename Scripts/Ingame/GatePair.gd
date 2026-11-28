class_name GatePair
extends Node3D
## Two side-by-side buff gates (scene: Scene/Ingame/GatePair.tscn). The army
## takes the left or right buff depending on which half of the road its
## center is in when it crosses this node's z. Set the buffs in the inspector.

enum Effect { ADD, MULTIPLY, DAMAGE, RATE, SUBTRACT }

@export var left_effect: Effect = Effect.ADD
@export var left_value: float = 6.0
@export var left_risky: bool = false
@export var right_effect: Effect = Effect.DAMAGE
@export var right_value: float = 0.25
@export var right_risky: bool = false

var left_def: Dictionary = {}
var right_def: Dictionary = {}
var used: bool = false

@onready var _left: Node3D = $PanelLeft
@onready var _right: Node3D = $PanelRight


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
			d["label"] = "%s%d%%" % ["-" if value < 0.0 else "+", int(round(absf(value) * 100.0))]
			d["sub"] = "DAMAGE"
			d["color"] = Color(1.0, 0.5, 0.15)
		Effect.RATE:
			d["label"] = "%s%d%%" % ["-" if value < 0.0 else "+", int(round(absf(value) * 100.0))]
			d["sub"] = "FIRE RATE"
			d["color"] = Color(1.0, 0.85, 0.2)
		Effect.SUBTRACT:
			d["label"] = "-%d" % int(value)
			d["sub"] = "SOLDIERS"
			d["color"] = Color(0.9, 0.2, 0.2)
	if is_negative(d):
		d["color"] = Color(0.9, 0.2, 0.2)
	elif risky:
		d["sub"] = str(d["sub"]) + "  RISKY"
		d["color"] = Color(1.0, 0.7, 0.1)
	return d


## A gate that hurts: fewer soldiers, or a damage / fire rate buff below zero.
static func is_negative(def: Dictionary) -> bool:
	var effect := int(def["effect"])
	return effect == Effect.SUBTRACT or ((effect == Effect.DAMAGE or effect == Effect.RATE) and float(def["value"]) < 0.0)


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


func _ready() -> void:
	Game.gates.append(self)
	left_def = make_def(left_effect, left_value, left_risky)
	right_def = make_def(right_effect, right_value, right_risky)
	_setup_side(_left, left_def)
	_setup_side(_right, right_def)


## Writes the text and tints the panel's "Tint" material + the floor pad.
func _setup_side(panel: Node3D, def: Dictionary) -> void:
	var col: Color = def["color"]
	(panel.get_node("Value") as Label3D).text = str(def["label"])
	(panel.get_node("Sub") as Label3D).text = str(def["sub"])
	for mi in Models.collect_meshes(panel):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var mat := m.get_active_material(s)
			if mat != null and mat.resource_name == "Tint" and mat is StandardMaterial3D:
				var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				copy.albedo_color = col
				m.set_surface_override_material(s, copy)
	var pad := panel.get_node("Pad") as MeshInstance3D
	var pad_mat := pad.material_override.duplicate() as StandardMaterial3D
	pad_mat.albedo_color = Color(col.r, col.g, col.b, 0.35)
	pad.material_override = pad_mat


func _process(_delta: float) -> void:
	if used or Game.army == null or Game.state != Game.State.PLAYING:
		return
	if Game.army.position.z <= position.z:
		used = true
		var left := Game.army.position.x - position.x < 0.0
		_apply(left_def if left else right_def, _left if left else _right)


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
	AudioManager.play("gate_bad" if is_negative(def) else "gate_good")
	Game.banner_requested.emit("%s %s" % [def["label"], str(def["sub"]).strip_edges()], def["color"])
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3(1.06, 1.1, 1.0), 0.12)
	tw.tween_property(node, "scale", Vector3.ONE, 0.2)
