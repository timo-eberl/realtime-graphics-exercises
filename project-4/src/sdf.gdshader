shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform float morph_progress : hint_range(0.0, 1.0, 0.01) = 0.0;

// constants
const float EPSILON = 0.001; // larger than 0, but so small every smaller value is negative
const float GRADIENT_DT = 0.05; // half of the step size
const int MAX_STEPS = 100; // ray march steps
const float MAX_DISTANCE = 100.0; // from surface; if we are that far, we won't hit anything

struct Ray { vec3 p; vec3 dir; };

#include "res://inc/sdf_primitives.gdshaderinc"

uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
	// don't do any transformations
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float sdf(vec3 p) {
	float torus = sdTorus(p, vec2(1.0, 0.5));
	float box = sdBox(p, vec3(1.0, 1.0, 1.0));
	return mix(torus, box, morph_progress);
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
		albedo * max(0.0, dot(normal, sun_direction)) // diffuse
		+ albedo * vec3(0.1); // ambient
}

bool sphere_trace_ray(Ray ray, vec3 depth_map_position, out vec3 normal) {
	// step front-to-back over the ray
	vec3 p = ray.p;
	float d;
	for (int i = 0; i < MAX_STEPS; ++i) {
		if (distance(p, ray.p) > distance(depth_map_position, ray.p)) {
			return false;
		}
		d = sdf(p);
		if (d < EPSILON || d > MAX_DISTANCE) {
			break;
		}
		p = p + ray.dir * d;
	}

	if (d < EPSILON) {
		normal = normalize(gradient(p));
		return true;
	}
	else {
		return false;
	}
}

void fragment() {
	// https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
	float depth = texture(depth_texture, SCREEN_UV).x;
	// This assumes the use of the Forward+ or Mobile renderers
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// Use this for the compatibility renderer
	//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	mat4 inv_model_matrix = inverse(MODEL_MATRIX);
	vec3 local = (inv_model_matrix * vec4(world_position, 1.0)).xyz;
	vec3 local_cam_pos = (inv_model_matrix * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	Ray ray = Ray(local_cam_pos, normalize(local - local_cam_pos));
	
	vec3 normal;
	bool hit = sphere_trace_ray(ray, local, normal);
	if (!hit) {
		discard;
	}
	
	normal = mat3(MODEL_MATRIX) * normal;
	vec3 albedo = vec3(1,0,0);
	vec3 color = shade(albedo, normal);
	ALBEDO.xyz = color;
}
