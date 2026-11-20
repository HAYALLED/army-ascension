shader_type sky;
// Toon day-cycle sky. All values are driven by DayCycle.gd (res://Scripts/Ingame/DayCycle.gd).

uniform vec3 top_color : source_color;
uniform vec3 mid_color : source_color;
uniform vec3 horizon_color : source_color;
uniform vec3 ground_color : source_color;
uniform vec3 glow_color : source_color;
uniform vec3 sun_dir;
uniform vec3 sun_color : source_color;
uniform float sun_size = 0.05;
uniform vec3 moon_dir;
uniform vec3 moon_color : source_color;
uniform float moon_size = 0.04;
uniform float stars = 0.0;
uniform vec3 cloud_lit : source_color;
uniform vec3 cloud_shade : source_color;
uniform float cloud_cover = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return 0.55 * vnoise(p) + 0.3 * vnoise(p * 2.1 + 7.3) + 0.15 * vnoise(p * 4.3 + 1.7);
}

vec3 sky_col(vec3 d, float time) {
	float y = d.y;
	float t1 = floor(smoothstep(0.0, 0.42, y) * 8.0) / 8.0;
	float t2 = floor(smoothstep(0.42, 1.0, y) * 8.0) / 8.0;
	vec3 col = mix(mix(horizon_color, mid_color, t1), top_color, t2);

	// stars
	if (stars > 0.0 && y > 0.03) {
		vec2 uv = vec2(atan(d.x, -d.z) * 150.0, asin(clamp(y, -1.0, 1.0)) * 150.0);
		vec2 id = floor(uv);
		vec2 f = fract(uv) - 0.5;
		float h = hash(id);
		float s = step(0.972, h) * smoothstep(0.24, 0.08, length(f));
		s *= 0.7 + 0.3 * sin(time * 2.0 + h * 60.0);
		col += vec3(1.0, 0.97, 0.85) * s * stars * smoothstep(0.03, 0.2, y);
	}

	// sun / moon halo
	float sd = dot(d, normalize(sun_dir));
	float sun_up = smoothstep(-0.15, 0.05, sun_dir.y);
	col += glow_color * (pow(max(sd, 0.0), 24.0) * 0.45 + pow(max(sd, 0.0), 5.0) * 0.22) * sun_up;
	float md = dot(d, normalize(moon_dir));
	col += moon_color * 0.35 * (pow(max(md, 0.0), 40.0) * 0.45 + pow(max(md, 0.0), 8.0) * 0.12) * smoothstep(-0.15, 0.05, moon_dir.y);

	// clouds: two-tone, drifting
	if (y > 0.02) {
		vec2 q = d.xz / (y + 0.14) * 2.2 + vec2(time * 0.012, 0.0);
		float n = fbm(q);
		float thr = 0.82 - cloud_cover * 0.55;
		float body = smoothstep(thr, thr + 0.025, n) * smoothstep(0.02, 0.14, y);
		float core = smoothstep(thr + 0.03, thr + 0.05, n);
		vec3 cc = mix(cloud_shade, cloud_lit, core);
		col = mix(col, cc, body);
	}

	// discs on top
	float sdisc = smoothstep(cos(sun_size) - 0.0006, cos(sun_size) + 0.0006, sd);
	col = mix(col, sun_color, sdisc * step(-0.02, sun_dir.y) * sun_up);
	float mdisc = smoothstep(cos(moon_size) - 0.0006, cos(moon_size) + 0.0006, md);
	col = mix(col, moon_color, mdisc * smoothstep(-0.05, 0.03, moon_dir.y));

	// below horizon
	col = mix(col, mix(horizon_color, ground_color, smoothstep(0.0, 0.3, -y)), step(y, 0.0));
	return col;
}

void sky() {
	COLOR = sky_col(EYEDIR, TIME);
}
