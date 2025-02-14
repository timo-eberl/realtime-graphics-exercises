shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;
render_mode unshaded; // for testing

// shells
uniform int u_shell_index;
uniform int u_shell_count;

void vertex() {
	float height_normalized = float(u_shell_index) / float(u_shell_count); // [0;1]
	
	vec3 height_offset = height_normalized * NORMAL;
	
	VERTEX += height_offset;
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

void fragment() {
	float height_normalized = float(u_shell_index) / float(u_shell_count-1); // [0;1]
	ALBEDO.xyz = vec3(height_normalized);
}
