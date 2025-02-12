shader_type spatial;
render_mode unshaded, cull_disabled;

uniform int images = 3; // every slice consists of that many strips/lenticules
uniform int slices = 10;

uniform sampler2D image_0 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_1 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_2 : source_color, filter_linear, repeat_disable;

void vertex() {
	POSITION = vec4(VERTEX.xy * vec2(2.0,-2.0), 1.0, 1.0);
}

vec4 interlaced_texture(vec2 uv) {
	int total_strips = images * slices;
	float m = fract(uv.x * float(total_strips));
	float slice_size = 1.0 / float(slices);
	int slice = int(uv.x * float(slices)); // id of the slice [0;slices[
	float n = (m + float(slice)) * slice_size;
	float slice_u = fract(uv.x * float(slices)); // u of the slice [0;1]

	vec4 sample_0 = texture(image_0, vec2(n, uv.y));
	vec4 sample_1 = texture(image_1, vec2(n, uv.y));
	vec4 sample_2 = texture(image_2, vec2(n, uv.y));
	//return sample_0;
	if (slice_u < 1.0/3.0) {
		return sample_0;
	}
	else if (slice_u < 2.0/3.0) {
		return sample_1;
	}
	else {
		return sample_2;
	}
}

void fragment() {
	ALBEDO.xyz = interlaced_texture(UV).xyz;
}
