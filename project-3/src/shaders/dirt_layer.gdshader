shader_type spatial;

uniform sampler3D cor_texture : filter_linear, repeat_enable;

uniform float dirt_level;
uniform float transition = 0.1;
uniform vec3 dirt_color : source_color = vec3(0);

float inv_lerp(float a, float b, float t) {
	return (t - a) / (b - a);
}

float remap(float a1, float b1, float a2, float b2, float t) {
	return mix(a2, b2, inv_lerp(a1, b1, t));
}

void fragment() {
	vec3 world_vert = (INV_VIEW_MATRIX * vec4(VERTEX,1)).xyz;
	float c = texture(cor_texture, world_vert * 10.0).x;

	c = remap(dirt_level, dirt_level+transition, 1, 0, c);
	c = clamp(c,0,1);

	ALPHA = c;
	ALBEDO = dirt_color;
	ROUGHNESS = 1.0;
}
