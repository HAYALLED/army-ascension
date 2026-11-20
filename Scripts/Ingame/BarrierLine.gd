class_name BarrierLine
extends Node3D
## A row of road barriers drawn with ONE MultiMesh per variant (cheap on
## mobile). Place it in the level and set length / spacing in the inspector.
## Variants come from Assets/Ingame/barrier_a.glb and barrier_b.glb.

const VARIANTS := ["res://Assets/Ingame/barrier_a", "res://Assets/Ingame/barrier_b"]

## Barriers run from this node toward -Z.
@export var length: float = 320.0
@export var spacing: float = 2.1
## Use only barrier_a (white/red) when false.
@export var mix_variants: bool = false


func _ready() -> void:
	var variants: Array = []
	for v in VARIANTS:
		var p := Models.prop(v)
		if not p.is_empty():
			variants.append(p)
	if variants.is_empty():
		return
	if not mix_variants:
		variants = [variants[0]]
	var buckets: Array = []
	for v in variants:
		buckets.append([])
	var count := int(length / spacing)
	for i in count:
		var vi := i % variants.size()
		var xf := Transform3D(Basis.IDENTITY, Vector3(0, 0, -i * spacing))
		buckets[vi].append(xf * (variants[vi]["xform"] as Transform3D))
	for vi in variants.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = variants[vi]["mesh"]
		mm.instance_count = buckets[vi].size()
		for i in buckets[vi].size():
			mm.set_instance_transform(i, buckets[vi][i])
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		add_child(inst)
