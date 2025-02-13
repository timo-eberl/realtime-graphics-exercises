shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 screen = textureLod(screen_texture, SCREEN_UV, 0.0);
	ALBEDO.xyz = screen.xyz;
	//ALBEDO.xyz = vec3(float(screen.w < 1.0));
	//ALPHA = 0.0;
}
