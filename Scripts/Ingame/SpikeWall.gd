class_name SpikeWall
extends Node3D
## Spike barricade (scene: Scene/Ingame/SpikeWall.tscn). Soldiers overlapping
## it when they cross take damage (see Battle._check_walls).
##
## With a real asset, Assets/Ingame/spike_wall.glb is ONE segment that is
## SEGMENT_WIDTH wide; it is tiled to cover `width`. Without it a primitive
## placeholder is built.

const MODEL := "res://Assets/Ingame/spike_wall"
const SEGMENT_WIDTH := 3.5

@export var width: float = 7.0


func _ready() -> void:
	var scene := Models.find(MODEL)
	if scene != null:
		var count := maxi(int(round(width / SEGMENT_WIDTH)), 1)
		for i in count:
			var seg := scene.instantiate() as Node3D
			seg.position.x = (i - (count - 1) * 0.5) * SEGMENT_WIDTH
			seg.rotation_degrees.y = Models.IMPORT_YAW_DEG if ResourceLoader.exists(MODEL + ".glb") or ResourceLoader.exists(MODEL + ".gltf") else 0.0
			add_child(seg)
	else:
		_build_placeholder()
	# Red approach strip: gameplay telegraph, always code-built.
	Mats.part(self, Mats.box(Vector3(width, 0.02, 0.4)), Mats.unshaded(Color(1.0, 0.2, 0.15, 0.7)), Vector3(0, 0.09, 1.4))


func _build_placeholder() -> void:
	Mats.part(self, Mats.box(Vector3(width, 0.55, 0.9)), Mats.solid(Color(0.45, 0.1, 0.1)), Vector3(0, 0.275, 0))
	Mats.part(self, Mats.box(Vector3(width, 0.12, 0.92)), Mats.solid(Color(1.0, 0.8, 0.1), 0.4), Vector3(0, 0.45, 0))
	var count := int(width / 0.6)
	var spike := Mats.solid(Color(0.75, 0.78, 0.85), 0.0, 0.3)
	for i in count:
		var x := (i - (count - 1) * 0.5) * (width / count)
		Mats.part(self, Mats.cone(0.2, 0.7), spike, Vector3(x, 0.9, 0))
