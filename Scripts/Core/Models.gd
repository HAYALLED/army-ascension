class_name Models
extends RefCounted
## Loads real 3D assets (glb / gltf / tscn) and falls back to the primitive
## placeholders when a file is missing, so the game always runs.
##
## Asset paths are given WITHOUT extension, e.g. "res://Assets/Units/rifleman".
## Every extension in EXTS is tried in order.
##
## Conventions for assets (see Docs/ASSET_PROMPTS.md):
##   * origin at the feet, 1 unit = 1 meter
##   * glb / gltf: the model FRONT faces +Z (glTF standard). It is rotated
##     180 deg on load so it faces -Z, the direction the army advances.
##   * optional node named "Muzzle" = bullet spawn point
##   * optional AnimationPlayer with clips: idle, run / walk, attack, shoot, die

const EXTS := [".glb", ".gltf", ".tscn"]
const IMPORT_YAW_DEG := 180.0

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


## Instance a unit model. Returns
## { root, meshes: Array, muzzle: Node3D|null, anim: AnimationPlayer|null, external: bool }
## `fallback` is called when no asset file exists and must return { root, meshes }.
static func unit(base: String, fallback: Callable) -> Dictionary:
	var scene := find(base)
	if scene == null:
		var d: Dictionary = fallback.call()
		d["muzzle"] = null
		d["anim"] = null
		d["external"] = false
		return d
	var inst := scene.instantiate() as Node3D
	var holder := Node3D.new()
	holder.add_child(inst)
	var path := ""
	for ext in EXTS:
		if ResourceLoader.exists(base + ext):
			path = base + ext
			break
	if path.ends_with(".glb") or path.ends_with(".gltf"):
		inst.rotation_degrees.y += IMPORT_YAW_DEG
	var meshes: Array = []
	_collect_meshes(inst, meshes)
	return {
		"root": holder,
		"meshes": meshes,
		"muzzle": inst.find_child("Muzzle", true, false),
		"anim": _find_anim_player(inst),
		"external": true,
	}


## First MeshInstance3D of a prop scene with its transform relative to the
## scene root: { "mesh": Mesh, "xform": Transform3D } or {} when missing.
## Used to feed MultiMesh scatter (trees, rocks, buildings, barriers).
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


## All existing variants out of a list of base paths.
static func prop_variants(bases: Array) -> Array:
	var out: Array = []
	for b in bases:
		var p := prop(b)
		if not p.is_empty():
			out.append(p)
	return out


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


static func _collect_meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null


static func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r != null:
			return r
	return null
