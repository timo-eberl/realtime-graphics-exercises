shader_type spatial;
render_mode unshaded, cull_disabled;

uniform int images = 3; // every slice consists of that many strips/lenticules
uniform int slices = 10;

uniform sampler2D image_0 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_1 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_2 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_3 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_4 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_5 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_6 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_7 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_8 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_9 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_10 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_11 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_12 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_13 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_14 : source_color, filter_linear, repeat_disable;
uniform sampler2D image_15 : source_color, filter_linear, repeat_disable;

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
	vec4 sample_3 = texture(image_3, vec2(n, uv.y));
	vec4 sample_4 = texture(image_4, vec2(n, uv.y));
	vec4 sample_5 = texture(image_5, vec2(n, uv.y));
	vec4 sample_6 = texture(image_6, vec2(n, uv.y));
	vec4 sample_7 = texture(image_7, vec2(n, uv.y));
	vec4 sample_8 = texture(image_8, vec2(n, uv.y));
	vec4 sample_9 = texture(image_9, vec2(n, uv.y));
	vec4 sample_10 = texture(image_10, vec2(n, uv.y));
	vec4 sample_11 = texture(image_11, vec2(n, uv.y));
	vec4 sample_12 = texture(image_12, vec2(n, uv.y));
	vec4 sample_13 = texture(image_13, vec2(n, uv.y));
	vec4 sample_14 = texture(image_14, vec2(n, uv.y));
	vec4 sample_15 = texture(image_15, vec2(n, uv.y));

	if (slice_u < 1.0/float(images)) { return sample_0; }
	else if (slice_u < 2.0/float(images)) { return sample_1; }
	else if (slice_u < 3.0/float(images)) { return sample_2; }
	else if (slice_u < 4.0/float(images)) { return sample_3; }
	else if (slice_u < 5.0/float(images)) { return sample_4; }
	else if (slice_u < 6.0/float(images)) { return sample_5; }
	else if (slice_u < 7.0/float(images)) { return sample_6; }
	else if (slice_u < 8.0/float(images)) { return sample_7; }
	else if (slice_u < 9.0/float(images)) { return sample_8; }
	else if (slice_u < 10.0/float(images)) { return sample_9; }
	else if (slice_u < 11.0/float(images)) { return sample_10; }
	else if (slice_u < 12.0/float(images)) { return sample_11; }
	else if (slice_u < 13.0/float(images)) { return sample_12; }
	else if (slice_u < 14.0/float(images)) { return sample_13; }
	else if (slice_u < 15.0/float(images)) { return sample_14; }
	else { return sample_15; }
}

void fragment() {
	ALBEDO.xyz = interlaced_texture(UV).xyz;
}
