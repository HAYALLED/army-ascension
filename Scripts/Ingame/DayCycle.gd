class_name DayCycle
extends Node3D
## Gameplay day cycle. Builds sky, WorldEnvironment, sun light and the mountain backdrop,
## then follows Game.progress_changed (0 = morning, 0.4 = afternoon, 0.72 = sunset, 1 = night).
## Tune the look in KEYS; every value is blended between neighbouring keys.

const SKY_SHADER := preload("res://Assets/Ingame/Env/sky_daycycle.gdshader")
const BACKDROP_SCENE := preload("res://Assets/Ingame/Env/backdrop_day.glb")
const BACKDROP_Z := -150.0 ## backdrop distance in front of the camera
const CAMERA_FAR := 230.0 ## backdrop sits 150-170 m out
const MOON_COLOR := Color(1.0, 0.96, 0.82)

const KEYS := [
 {"p": 0.0, "top": "#4F7FE0", "mid": "#C4B8E8", "horizon": "#FFB88C", "ground": "#8A6A7A", "glow": "#FFB070", "sun": "#FFF1C2",
  "cloud_lit": "#FFE7DC", "cloud_shade": "#E9A9A8", "cloud_cover": 0.45, "stars": 0.0,
  "ambient": "#FFD1C7", "ambient_e": 0.8, "light": "#FFC28C", "light_e": 1.0, "light_pitch": -26.0, "light_yaw": -40.0,
  "mountain": "#C28FA4", "fog_begin": 70.0, "fog_end": 190.0},
 {"p": 0.4, "top": "#3A80E0", "mid": "#9FD0F6", "horizon": "#CBE8FB", "ground": "#9DBBA8", "glow": "#FFF2A8", "sun": "#FFFBE0",
  "cloud_lit": "#FFFFFF", "cloud_shade": "#C3D9EE", "cloud_cover": 0.5, "stars": 0.0,
  "ambient": "#DBEDFF", "ambient_e": 0.85, "light": "#FFF5E0", "light_e": 1.1, "light_pitch": -55.0, "light_yaw": -25.0,
  "mountain": "#7DAFC0", "fog_begin": 70.0, "fog_end": 190.0},
 {"p": 0.72, "top": "#4B4C9C", "mid": "#D36A8C", "horizon": "#FF8A5C", "ground": "#7A4A5A", "glow": "#FF7A3C", "sun": "#FFB070",
  "cloud_lit": "#FFC0A0", "cloud_shade": "#B0507A", "cloud_cover": 0.5, "stars": 0.0,
  "ambient": "#FFB0A0", "ambient_e": 0.75, "light": "#FF9A60", "light_e": 0.95, "light_pitch": -16.0, "light_yaw": 35.0,
  "mountain": "#B8607A", "fog_begin": 60.0, "fog_end": 180.0},
 {"p": 0.86, "top": "#16206B", "mid": "#4A4F9A", "horizon": "#9A5A8A", "ground": "#3A2E5A", "glow": "#C07090", "sun": "#FFB070",
  "cloud_lit": "#8A6AA0", "cloud_shade": "#4A3A80", "cloud_cover": 0.4, "stars": 0.4,
  "ambient": "#8A80D0", "ambient_e": 0.7, "light": "#9A90E0", "light_e": 0.7, "light_pitch": -35.0, "light_yaw": 30.0,
  "mountain": "#6A5A9A", "fog_begin": 55.0, "fog_end": 175.0},
 {"p": 1.0, "top": "#070B26", "mid": "#1B2459", "horizon": "#34427F", "ground": "#141C48", "glow": "#8FA4E8", "sun": "#FFF1C2",
  "cloud_lit": "#4A5896", "cloud_shade": "#2A3470", "cloud_cover": 0.3, "stars": 1.0,
  "ambient": "#6B80E0", "ambient_e": 0.75, "light": "#90A3EB", "light_e": 0.55, "light_pitch": -50.0, "light_yaw": 20.0,
  "mountain": "#3A4A8C", "fog_begin": 50.0, "fog_end": 175.0}
]

var _keys: Array = []
var _mat := ShaderMaterial.new()
var _tint := StandardMaterial3D.new()
var _env := Environment.new()
var _light := DirectionalLight3D.new()
var _backdrop: Node3D
var _target := 0.0
var _shown := -1.0


func _ready() -> void:
	for k: Dictionary in KEYS:
		var d := {}
		for key: String in k:
			d[key] = Color(k[key]) if k[key] is String else k[key]
		_keys.append(d)

	_mat.shader = SKY_SHADER
	_mat.set_shader_parameter("moon_color", MOON_COLOR)
	var sky := Sky.new()
	sky.sky_material = _mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	_light.shadow_enabled = true
	_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_light.directional_shadow_max_distance = 45.0
	add_child(_light)

	_tint.roughness = 1.0
	_backdrop = BACKDROP_SCENE.instantiate() as Node3D
	add_child(_backdrop)
	for mi: MeshInstance3D in _backdrop.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if m and m.resource_name == "Tint":
				mi.set_surface_override_material(s, _tint)

	Game.progress_changed.connect(_on_progress)
	apply(0.0)


func _on_progress(t: float) -> void:
	_target = t


func _process(delta: float) -> void:
	_shown = move_toward(_shown, _target, delta * 0.5) if _shown >= 0.0 else _target
	apply(_shown)
	var cam := get_viewport().get_camera_3d()
	if cam:
		_backdrop.position = Vector3(0.0, 0.0, cam.global_position.z + BACKDROP_Z)
		cam.far = maxf(cam.far, CAMERA_FAR)


## p in 0..1
func apply(p: float) -> void:
	var s := _sample(clampf(p, 0.0, 1.0))
	for k in ["top", "mid", "horizon", "ground", "glow", "sun"]:
		_mat.set_shader_parameter(k + "_color", s[k])
	_mat.set_shader_parameter("cloud_lit", s["cloud_lit"])
	_mat.set_shader_parameter("cloud_shade", s["cloud_shade"])
	_mat.set_shader_parameter("cloud_cover", s["cloud_cover"])
	_mat.set_shader_parameter("stars", s["stars"])
	var th := PI * (p + 0.06) / 0.86
	_mat.set_shader_parameter("sun_dir", _dir(40.0 * sin(th) - 2.0, 18.0 * cos(th)))
	var tm := PI * (p - 0.6) / 0.7
	_mat.set_shader_parameter("moon_dir", _dir(20.0 * sin(tm) - 4.0, -18.0 * cos(tm)))
	_env.ambient_light_color = s["ambient"]
	_env.ambient_light_energy = s["ambient_e"]
	_env.fog_light_color = s["horizon"]
	_env.fog_depth_begin = s["fog_begin"]
	_env.fog_depth_end = s["fog_end"]
	_light.light_color = s["light"]
	_light.light_energy = s["light_e"]
	_light.rotation_degrees = Vector3(s["light_pitch"], s["light_yaw"], 0.0)
	_tint.albedo_color = s["mountain"]


func _sample(p: float) -> Dictionary:
	var i := 0
	while i < _keys.size() - 2 and p > float(_keys[i + 1]["p"]):
		i += 1
	var a: Dictionary = _keys[i]
	var b: Dictionary = _keys[i + 1]
	var t := smoothstep(0.0, 1.0, clampf((p - float(a["p"])) / (float(b["p"]) - float(a["p"])), 0.0, 1.0))
	var out := {}
	for key: String in a:
		out[key] = lerp(a[key], b[key], t)
	return out


## sky direction (-Z = forward) from elevation / azimuth in degrees; azimuth + = right
static func _dir(el_deg: float, az_deg: float) -> Vector3:
	var e := deg_to_rad(el_deg)
	var a := deg_to_rad(az_deg)
	return Vector3(cos(e) * sin(a), sin(e), -cos(e) * cos(a))
