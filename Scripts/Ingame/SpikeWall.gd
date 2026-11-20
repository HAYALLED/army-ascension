class_name SpikeWall
extends Node3D
## Spike trap (scene: Scene/Ingame/SpikeWall.tscn). The scene holds four
## 3.5 m spike_wall.glb segments; `segments` of them are shown, centered.
## Soldiers overlapping the wall when they cross take damage
## (see Battle._check_walls).

const SEGMENT_WIDTH := 3.5

@export_range(1, 4) var segments: int = 2
@export var damage: float = 35.0

var width: float = 7.0


func _ready() -> void:
	width = segments * SEGMENT_WIDTH
	for i in 4:
		var seg := get_node("Seg%d" % (i + 1)) as Node3D
		seg.visible = i < segments
		seg.position.x = (i - (segments - 1) * 0.5) * SEGMENT_WIDTH
	var strip := $ApproachStrip as Node3D
	strip.scale.x = width
	Game.walls.append({"node": self, "z": position.z, "x": position.x, "hw": width * 0.5,
		"damage": damage, "hit": {}, "done": false})
