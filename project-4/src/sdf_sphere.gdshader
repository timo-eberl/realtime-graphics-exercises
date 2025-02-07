shader_type canvas_item;

// constants
const float EPSILON = 0.001; // larger than 0, but so small every smaller value is negative
const float GRADIENT_DT = 0.05; // half of the step size
const int MAX_STEPS = 100; // ray march steps
const float MAX_DISTANCE = 100.0; // from surface; if we are that far, we won't hit anything
// tone mapper
uniform float l_white : hint_range(0.0, 10.0) = 1.0;
uniform float exposure : hint_range(-10.0, 10.0) = 0.0;
// camera (set from script)
uniform float aspect_ratio = 1.0; uniform vec3 camera_position = vec3(0,0,3);
uniform float azimuth = 0.0; uniform float elevation = 0.0;
uniform float vertical_fov_radians = 0.7854; // 45 degrees
// used to generate the ray
varying vec3 _ray_p; varying vec3 _ray_dir;

#include "res://inc/tone_mapping.gdshaderinc"
#include "res://inc/sdf_primitives.gdshaderinc"
#include "res://inc/matrices.gdshaderinc"
#include "res://inc/ray_generation.gdshaderinc"

void vertex() {
	Ray ray = perspective_ray(
		azimuth, elevation, camera_position, aspect_ratio, vertical_fov_radians, UV
	);
	_ray_p = ray.p; _ray_dir = ray.dir;
}

float sdf(vec3 p) {
	return sdSphere(p - 1.0, 1.0);
}

vec3 gradient(vec3 p) {
	const vec3 dx = vec3(GRADIENT_DT, 0.0, 0.0);
	const vec3 dy = vec3(0.0, GRADIENT_DT, 0.0);
	const vec3 dz = vec3(0.0, 0.0, GRADIENT_DT);
	
	return vec3( (sdf(p + dx) - sdf(p - dx)) 
				/ (2.0 * GRADIENT_DT),
				 (sdf(p + dy) - sdf(p - dy)) 
				/ (2.0 * GRADIENT_DT),
		 		 (sdf(p + dz) - sdf(p - dz))
				/ (2.0 * GRADIENT_DT)
	);
}

vec3 shade(vec3 albedo, vec3 normal) {
	vec3 sun_direction = normalize(vec3(0,1,0));
	return
		albedo * max(0.0, dot(normal, sun_direction)); // diffuse
		+ albedo * vec3(0.1); // ambient
}

bool sphere_trace_ray(Ray ray, out vec3 color) {
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

	if (d < EPSILON) {
		vec3 normal = normalize(gradient(p));
		vec3 albedo = vec3(1,0,0);
		color = shade(albedo, normal);
		return true;
	}
	else {
		return false;
	}
}

void fragment() {
	Ray ray = Ray(_ray_p, normalize(_ray_dir));

	vec3 color;
	bool hit = sphere_trace_ray(ray, color);
	if (!hit) {
		discard;
	}
	COLOR = vec4(linear_to_sRGB(tonemap_reinhard(color * pow(2.0, exposure), l_white)), 1.0);
}
