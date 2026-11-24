class_name Models
extends RefCounted
## Helpers for imported 3D assets (glb) and their optional animations.
##
## Asset conventions (see Docs/ASSET_PROMPTS.md):
##   * origin at the feet, 1 unit = 1 meter, glb front faces +Z
##     (unit scenes rotate the glb 180 deg so it faces -Z, the advance direction)
##   * optional node "Muzzle" = bullet spawn point
##   * optional AnimationPlayer with clips: idle, run / walk, attack, shoot, die

## Extensions tried by `find` (path given without extension).
const EXTS := [".glb", ".gltf", ".tscn"]

static var _scenes: Dictionary = {}


static func find(base: String) -> PackedScene:
	if _scenes.has(base):
		return _scenes[base]
	var found: PackedScene = null
	for ext in EXTS:
		if ResourceLoader.exists(base + ext):
			found = load(base + ext) as PackedScene
			if found != null:
				break
	_scenes[base] = found
	return found


## First MeshInstance3D of a scene with its transform relative to the scene
## root: { "mesh": Mesh, "xform": Transform3D } or {} when missing.
## Used for MultiMesh scatter (see BarrierLine.gd).
static func prop(base: String) -> Dictionary:
	var scene := find(base)
	if scene == null:
		return {}
	var inst := scene.instantiate() as Node3D
	var mesh_node := _first_mesh(inst)
	if mesh_node == null:
		inst.free()
		return {}
	var xf := Transform3D.IDENTITY
	var n: Node = mesh_node
	while n != null:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	var result := {"mesh": mesh_node.mesh, "xform": xf}
	inst.free()
	return result


## `prop` of every base name that exists, in order. Missing assets are skipped, so the
## result is empty when none of them is imported (callers fall back to placeholders).
static func prop_variants(bases: Array) -> Array:
	var out: Array = []
	for base in bases:
		var p := prop(String(base))
		if not p.is_empty():
			out.append(p)
	return out


static func collect_meshes(root: Node) -> Array:
	var out: Array = []
	_collect(root, out)
	return out


static func find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for c in root.get_children():
		var r := find_anim_player(c)
		if r != null:
			return r
	return null


## Case-insensitive animation lookup: "run" matches "Run", "Armature|Run_loop".
static func find_anim(ap: AnimationPlayer, anim_name: String) -> StringName:
	if ap == null:
		return &""
	var map: Dictionary = ap.get_meta("anim_map", {})
	if map.is_empty():
		for a in ap.get_animation_list():
			var key := String(a).to_lower().replace("-loop", "").replace("_loop", "")
			key = key.get_slice("|", key.get_slice_count("|") - 1)
			map[key] = a
		ap.set_meta("anim_map", map)
	return map.get(anim_name, &"")


## Play a clip if it exists. Returns true when a clip is playing.
static func play(ap: AnimationPlayer, anim_name: String, speed: float = 1.0) -> bool:
	var a := find_anim(ap, anim_name)
	if a == &"":
		return false
	if ap.current_animation != String(a) or not ap.is_playing():
		ap.play(a, 0.1, speed)
	return true


static func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null
