shader_type spatial;
// render only back sides (inside), because we use our mesh essentially
// as a bounding volume and want to render the SDF also when inside the bounding volume.
// Disable Depth testing, because we do that manually.
render_mode cull_front, depth_test_disabled, shadows_disabled;

uniform float morph_progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);

// constants
const float EPSILON = 0.001; // larger than 0, but so small every smaller value is negative
const float GRADIENT_DT = 0.0005; // half of the step size
const int MAX_STEPS = 100; // ray march steps
const float MAX_DISTANCE = 100.0; // from surface; if we are that far, we won't hit anything

struct Ray { vec3 p; vec3 dir; };

#include "res://inc/sdf_primitives.gdshaderinc"

uniform sampler2D depth_texture : source_color, hint_depth_texture;

float sdf_mug(vec3 p, float radius, float height, float thickness, float handle_radius, float handle_thickness) {
    float half_height = height * 0.5;
    float half_thickness = thickness * 0.5;

	// the "sides" of the mug - an elongated torus
	float body_side = sdTorus(
		opElongatePos(p - vec3(0,half_height,0), vec3(0,half_height-half_thickness,0)), // elongation
		vec2(radius-half_thickness, half_thickness) // torus parameters
	);
	// the bottom of the mug - just a cylinder
	float body_bottom = sdCappedCylinder(p - vec3(0,half_thickness,0), half_thickness, (radius - half_thickness));
    float mug_body = opUnion(body_side, body_bottom);

	vec3 handle_pos = p - vec3(radius + 0.15, half_height * 1.15, 0.0); // translate
	handle_pos.y *= 0.7; // scale
    float handle_ring = sdTorusZ(handle_pos, vec2(handle_radius, handle_thickness));
	float inner_cylinder = sdCylinder(p, vec3(0,0,radius-half_thickness));
    float handle = opSubtraction(inner_cylinder, handle_ring);

	return opSmoothUnion(mug_body, handle, 0.07);
}

float sdf(vec3 p) {
	// adjust interpolation
	float t = smoothstep(0,1,morph_progress);
	t = pow(t, 0.5);

	float mug = sdf_mug(p, 1.0, 2.0, 0.12, 0.45, 0.08);

	// move torus to the position of the handle during interpolation, so the transition looks nicer
	vec3 torus_pos = mix(vec3(0,1,0), vec3(1.8,1.2,0), pow(t, 0.7));
	float torus = sdTorusZ(p - torus_pos, vec2(0.6, 0.4));

	// morph between the two SDFs
	return mix(torus, mug, t);
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

bool sphere_trace_ray(Ray ray, vec3 depth_map_position, out vec3 normal, out vec3 hit_pos) {
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
		hit_pos = p;
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
	//vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// Use this for the compatibility renderer
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	mat4 inv_model_matrix = inverse(MODEL_MATRIX);
	vec3 local = (inv_model_matrix * vec4(world_position, 1.0)).xyz;
	vec3 local_cam_pos = (inv_model_matrix * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	Ray ray = Ray(local_cam_pos, normalize(local - local_cam_pos));

	vec3 normal; vec3 hit_pos;
	bool hit = sphere_trace_ray(ray, local, normal, hit_pos);
	if (!hit) { discard; }

	vec3 world_normal = normalize(mat3(MODEL_MATRIX) * normal);
	NORMAL = mat3(VIEW_MATRIX) * world_normal;
	vec4 world_hit_pos = MODEL_MATRIX * vec4(hit_pos, 1.0);
	LIGHT_VERTEX = (VIEW_MATRIX * world_hit_pos).xyz; // affects lighting

	ALBEDO.xyz = vec3(0,0,0.02);
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
