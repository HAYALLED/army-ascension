class_name Mats
extends RefCounted
## Shared mesh / material cache. Everything is built from primitives so the
## prototype needs no external art. Sharing resources keeps memory and
## state changes low on mobile.

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


static func solid(color: Color, emission: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var key := "s%s_%s_%s" % [color.to_html(true), emission, roughness]
	var cached = _mats.get(key)
	if cached != null:
		return cached
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


static func unshaded(color: Color) -> StandardMaterial3D:
	var key := "u%s" % color.to_html(true)
	var cached = _mats.get(key)
	if cached != null:
		return cached
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


## Material that reads per-instance / per-particle colors (MultiMesh, particles).
static func vcolor(lit: bool) -> StandardMaterial3D:
	var key := "v%s" % lit
	var cached = _mats.get(key)
	if cached != null:
		return cached
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	if not lit:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


## White overlay used for hit flashes (assigned to MeshInstance3D.material_overlay).
static func flash() -> StandardMaterial3D:
	return unshaded(Color(1, 1, 1, 0.6))


## Orange overlay used while the boss winds up an attack.
static func warn() -> StandardMaterial3D:
	return unshaded(Color(1.0, 0.35, 0.1, 0.4))


## Billboard bar quad material (health bars).
static func bar(color: Color, priority: int) -> StandardMaterial3D:
	var key := "bar%s_%d" % [color.to_html(true), priority]
	var cached = _mats.get(key)
	if cached != null:
		return cached
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = priority
	_mats[key] = m
	return m


static func box(size: Vector3) -> BoxMesh:
	var key := "b%.3f,%.3f,%.3f" % [size.x, size.y, size.z]
	var cached = _meshes.get(key)
	if cached != null:
		return cached
	var m := BoxMesh.new()
	m.size = size
	_meshes[key] = m
	return m


static func sphere(r: float, segments: int = 12) -> SphereMesh:
	var key := "p%.3f,%d" % [r, segments]
	var cached = _meshes.get(key)
	if cached != null:
		return cached
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segments
	m.rings = maxi(floori(segments * 0.5), 3)
	_meshes[key] = m
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var key := "c%.3f,%.3f" % [r, h]
	var cached = _meshes.get(key)
	if cached != null:
		return cached
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	_meshes[key] = m
	return m


static func cylinder(top_r: float, bottom_r: float, h: float, segments: int = 10) -> CylinderMesh:
	var key := "y%.3f,%.3f,%.3f,%d" % [top_r, bottom_r, h, segments]
	var cached = _meshes.get(key)
	if cached != null:
		return cached
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = h
	m.radial_segments = segments
	m.rings = 1
	_meshes[key] = m
	return m


static func cone(r: float, h: float, segments: int = 8) -> CylinderMesh:
	return cylinder(0.0, r, h, segments)


static func quad(size: Vector2) -> QuadMesh:
	var key := "q%.3f,%.3f" % [size.x, size.y]
	var cached = _meshes.get(key)
	if cached != null:
		return cached
	var m := QuadMesh.new()
	m.size = size
	_meshes[key] = m
	return m


static func part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi
