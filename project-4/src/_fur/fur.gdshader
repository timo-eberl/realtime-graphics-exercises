shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;
render_mode unshaded; // for testing

// shells
uniform int u_shell_index;
uniform int u_shell_count;
// fur
uniform float u_length;
uniform float u_distance_density_attenuation; // controls density distribution of shells. <1 -> greater density outside
uniform float u_density;

varying float v_height_normalized;

#include "res://inc/hash.gdshaderinc"

void vertex() {
	v_height_normalized = float(u_shell_index) / float(u_shell_count); // [0;1] linear
	v_height_normalized = pow(v_height_normalized, u_distance_density_attenuation); // [0;1]
	
	vec3 height_offset = v_height_normalized * u_length * NORMAL;
	
	VERTEX += height_offset;
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	
	ALBEDO.xyz = vec3(rand);
}
