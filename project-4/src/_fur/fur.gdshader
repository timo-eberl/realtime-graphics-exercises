shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;
//render_mode unshaded; // for testing

// shells
uniform int u_shell_index;
uniform int u_shell_count;
// fur
uniform float u_length;
uniform float u_length_uniformity;
uniform float u_distance_shell_density_attenuation; // controls density distribution of shells. <1 -> greater density outside
uniform float u_density;
uniform float u_thickness;
uniform float u_strand_roundness;
// shading
uniform vec3 u_color;
uniform float u_occlusion_attenuation;
// physics
uniform float u_displacement_strength;
uniform float u_curvature;
uniform vec3 u_displacement_vector; // world space - updated on CPU to match movement
uniform mat3 u_rotation_displacement; // local space - updated on CPU to match movement

varying float v_height_normalized;
varying float v_ambient_occlusion;
varying vec3 v_debug;

#include "res://inc/hash.gdshaderinc"

void vertex() {
	v_height_normalized = float(u_shell_index) / float(u_shell_count); // [0;1] linear
	v_height_normalized = pow(v_height_normalized, u_distance_shell_density_attenuation); // [0;1]
	
	v_ambient_occlusion = pow(v_height_normalized, u_occlusion_attenuation);
	
	// hair stiffness
	float k = pow(v_height_normalized, 1.0 + u_curvature);
	// physics rotation displacement
	// it would be more correct to take a quaternion instead of a matrix and interpolate it
	// instead of interpolating between original and rotated position. but this also works fine
	vec3 rot_vert = u_rotation_displacement * VERTEX;
	VERTEX = mix(VERTEX, rot_vert, k);
	
	vec3 height_offset = v_height_normalized * u_length * NORMAL;
	VERTEX += height_offset;
	
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// if strands are facing the displacement direction - displace less
	float n_dot_disp = max( dot(NORMAL, normalize(u_displacement_vector)), 0.0);
	float displacement_strength = u_displacement_strength * mix(1.0, 0.5, n_dot_disp);
	
	vec3 physics_translation_offset = k * displacement_strength * u_displacement_vector;
	VERTEX += physics_translation_offset;
	
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

void fragment() {
	// The UVs should have a relatively uniform rate of change (no stretching).
	// seams are not an issue.
	// blenders smart projection provides good UVs for this usecase.
	
	vec2 scaled_uv = UV * u_density;
	
	uvec2 strand_id = uvec2(scaled_uv);
	float rand = hash(strand_id); // [0;1]
	rand = mix(u_length_uniformity, 1.0, rand);
	
	vec2 local_uv_centered = fract(scaled_uv) * 2.0 - 1.0;
	float local_center_distance = length(local_uv_centered);
	float thickness = u_thickness * (rand - v_height_normalized);
	thickness = clamp(thickness,0,1);
	thickness = pow(thickness, 1.0 - u_strand_roundness);
	bool clip = local_center_distance > thickness;

	// always draw the inner shell
	if (clip && u_shell_index > 0) discard;
	
	ALBEDO.xyz = u_color;
}

void light() {
	float n_dot_l = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	// this is not physically correct at all, but it looks good.
	float lighting = n_dot_l * 0.5 + 0.5;
	lighting = lighting * lighting;
	DIFFUSE_LIGHT += lighting * ATTENUATION * v_ambient_occlusion * LIGHT_COLOR;
}
