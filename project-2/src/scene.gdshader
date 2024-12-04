shader_type canvas_item;
// constants
const float EPSILON = 0.5; // larger than 0, but so small every smaller value is negative
const float GRADIENT_DT = 0.5;
const int MAX_STEPS = 150; // ray march steps
const float MAX_DISTANCE = 1000.0; // from surface; if we are that far, we won't hit anything
const bool ORTHO_VIEW = false;
const bool SHOW_HEIGHT_CONTOUR_LINES = false;
const bool VISUALIZE_NORMALS = false;
const float HEIGHT_CONTOUR_LINES_DISTANCE = 5.0;
const float ORTHO_CAM_SIZE_Y = 200.0;
// generic shader parameters ... (set from script)
uniform vec3 P; uniform vec3 Q; uniform vec3 R; uniform vec3 S; // ... vectors
uniform float lambda; uniform float mu; uniform float nu; // ... scalars
uniform float theta; uniform float phi; // ... angles, in radians
uniform vec3 color_a; uniform vec3 color_b; uniform vec3 color_c; uniform vec3 color_d; // in sRGB
// camera (set from script)
uniform float aspect_ratio = 1.0; uniform vec3 camera_position = vec3(0,1.5,0);
uniform float azimuth = 0.0; uniform float elevation = 0.0;
uniform float vertical_fov_radians = 0.7854; // 45 degrees
// sky (set from script)
uniform vec3 zenith_color = vec3(0.2); uniform vec3 horizon_color = vec3(1);
uniform vec3 sun_color = vec3(1); uniform vec3 sun_direction = vec3(0,1,0); // normalized in script
uniform float cos_sun_radius = 0.999961923; // cos(0.5 degrees)
// tone mapper (set from script)
uniform float l_white : hint_range(0.0, 10.0) = 1.0;
uniform float exposure : hint_range(-10.0, 10.0) = 0.0;
// textures
uniform sampler2D noise_texture : filter_linear, repeat_enable;
// used to generate the ray
varying vec3 _ray_p; varying vec3 _ray_dir;

// linearized colors
varying vec3 _color_a; varying vec3 _color_b; varying vec3 _color_c; varying vec3 _color_d;
varying vec3 _zenith_color; varying vec3 _horizon_color; varying vec3 _sun_color;
varying vec3 _ground_albedo_a; varying vec3 _ground_albedo_b;

#include "res://inc/tone_mapping.gdshaderinc"
#include "res://inc/sdf_primitives.gdshaderinc"
#include "res://inc/matrices.gdshaderinc"
#include "res://inc/ray_generation.gdshaderinc"
#include "res://webgl-noise/src/cellular2x2.gdshaderinc"
#include "res://webgl-noise/src/noise2D.gdshaderinc"

vec3 sky(vec3 dir) {
	dir = normalize(dir);
	vec3 sky_color = mix(_horizon_color, _zenith_color, clamp(pow(dir.y, 0.5), 0, 1));
	float t = smoothstep(cos_sun_radius*0.99995, cos_sun_radius, dot(dir, sun_direction));
	return mix(sky_color, _sun_color, t);
}

vec3 shade(vec3 albedo, vec3 point, vec3 normal) {
	// sun : Lambertian
	// the integral over the upper hemisphere times cos(theta) equals to pi
	// this cancels out with albedo/pi from lambertian BRDF
	vec3 res = albedo * max(0.0, dot(normal, sun_direction));
	res += albedo * max(0.0, normal.y) * _zenith_color;
	res += albedo * vec3(0.1); // ambient
	return res;
}

vec3 ground_color(vec3 p) {
	vec3 albedo = vec3(p.x >= 0.0 ? 1.0 : 0.2, 0.2, p.z >= 0.0 ? 1.0 : 0.2);
	vec3 pf = fract(p * 0.5); // make grid cell 1m large
	bool checkerboard = (pf.x > 0.5) == (pf.z > 0.5);
	albedo *= (checkerboard ? 0.15 : 0.5);
	return shade(albedo, p, vec3(0.0,1.0,0.0));
}

vec3 background(Ray ray) {
	// intersect against ground plane
	float t = (-ray.p.y) / (ray.dir.y);
	// intersection in front? draw ground
	if (t > 0.0) {
		vec3 hitpoint = ray.p + t * ray.dir;
		vec3 a = abs(hitpoint);
		if (max(a.x, max(a.y, a.z)) <= 2.0) { // no checkerboard in the distance
			return ground_color(hitpoint);
		}
	}
	return sky(ray.dir);
}

float height_at(vec3 p, out float debug) {
	float s = 250.0;
	vec2 uv = p.xz / s;
	// float noise = texture(noise_texture, uv * 2.0).x;
	float noise = snoise(uv * 2.5) * 0.7;
	uv += noise * 0.1;
	debug = noise;
	float height = cellular2x2(uv).x;
	height = smoothstep(0, 1, height);
	return height * 60.0;
}

float sdf(vec3 p) {
	float debug;
	float ground = sdPlane(p, vec3(0,1,0), 1.0-height_at(p, debug));
	return ground;
}

vec3 gradient(vec3 p) {
	const vec3 dx = vec3(GRADIENT_DT, 0.0, 0.0);
	const vec3 dy = vec3(0.0, GRADIENT_DT, 0.0);
	const vec3 dz = vec3(0.0, 0.0, GRADIENT_DT);
	return vec3( (sdf(p + dx) - sdf(p - dx)) / (2.0 * GRADIENT_DT),
				 (sdf(p + dy) - sdf(p - dy)) / (2.0 * GRADIENT_DT),
		 		 (sdf(p + dz) - sdf(p - dz)) / (2.0 * GRADIENT_DT)
	);
}

float inv_lerp(float a, float b, float v) {
	return (v-a) / (b-a);
}

vec3 visualize_normal(vec3 n) {
	vec3 color = vec3(0);
	// the same as dot(N,L) lighting, but cheaper
	if (n.x > 0.0) { color += n.x * vec3(1.0, 0.0, 0.0); }
	else { color += -n.x * vec3(0.8, 0.0, 0.5); }
	if (n.z > 0.0) { color += n.z * vec3(0.0, 0.0, 1.0); }
	else { color += -n.z * vec3(0.0, 0.5, 1.0); }
	if (n.y > 0.0) { color += n.y * vec3(0, 0.1, 0); }
	return color;
}

vec3 sphere_trace_ray(Ray ray) {
	// step front-to-back over the ray
	vec3 p = ray.p;
	float d;
	for (int i = 0; i < MAX_STEPS; ++i) {
		d = sdf(p);
		if (d < EPSILON || d > MAX_DISTANCE) {
			break;
		}
		p = p + ray.dir * d;
	}

	if (d < EPSILON) { // shade surface
		vec3 normal = normalize(gradient(p));
		float debug;
		height_at(p, debug);
		if (SHOW_HEIGHT_CONTOUR_LINES) {
			float t = distance( fract( p.y/HEIGHT_CONTOUR_LINES_DISTANCE + 0.5 ), 0.5 );
			if (t < 0.03) { return vec3(0); }
		}
		if (VISUALIZE_NORMALS) { return visualize_normal(normal); }
		return shade(_color_b, p, normal);
	} else {
		return background(ray);
	}
}

void vertex() {
	Ray ray;
	if (ORTHO_VIEW) {
		ray = orthographic_ray(ORTHO_CAM_SIZE_Y, aspect_ratio, UV);
	}
	else {
		float debug;
		vec3 cam_pos = camera_position + vec3(0, height_at(camera_position, debug), 0);
		ray = perspective_ray(azimuth, elevation, cam_pos, aspect_ratio, vertical_fov_radians, UV);
	}
	_ray_p = ray.p; _ray_dir = ray.dir;
	// color space conversions
	_zenith_color = sRGB_to_linear(zenith_color); _horizon_color = sRGB_to_linear(horizon_color);
	_sun_color = sRGB_to_linear(sun_color);
	_color_a = sRGB_to_linear(color_a); _color_b = sRGB_to_linear(color_b);
	_color_c = sRGB_to_linear(color_c); _color_d = sRGB_to_linear(color_d);
}

void fragment() {
	Ray ray = Ray(_ray_p, normalize(_ray_dir));

	//if (ORTHO_VIEW) {
		//ray.dir = vec3(0,-1,0);
		//ray.p.y = 100.0;
		//ray.p.x = mix(-ORTHO_CAM_SIZE_Y * aspect_ratio, ORTHO_CAM_SIZE_Y * aspect_ratio, UV.x);
		//ray.p.z = mix(-ORTHO_CAM_SIZE_Y, ORTHO_CAM_SIZE_Y, UV.y);
	//}

	COLOR = vec4(linear_to_sRGB(tonemap_reinhard(
		sphere_trace_ray(ray) * pow(2.0, exposure),
	l_white)), 1.0);
}
