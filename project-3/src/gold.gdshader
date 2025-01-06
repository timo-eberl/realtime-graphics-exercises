shader_type spatial;

uniform vec3 albedo_new : source_color = vec3(0);
uniform float roughness_new = 0.27;

void fragment() {
	METALLIC = 1.0;
	ALBEDO = albedo_new;
	ROUGHNESS = roughness_new;
}
