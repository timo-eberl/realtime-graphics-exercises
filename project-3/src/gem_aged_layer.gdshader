shader_type spatial;

uniform float age = 0.0;
uniform vec3 albedo : source_color = vec3(0);

void fragment() {
	ALPHA = mix(0.0, 0.8, age);
	ALBEDO = albedo;
	ROUGHNESS = mix(0.0, 0.6, age);
}
