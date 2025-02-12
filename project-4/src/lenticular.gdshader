shader_type spatial;
//render_mode unshaded;

uniform int images = 3; // every slice consists of that many strips/lenticules
uniform int slices = 10;
// if <0 one lenticular lens shows only a portion of a strip
uniform float lenticular_magnification : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float intended_max_angle : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D sliced_image : source_color, filter_linear, repeat_disable;

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0);
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

varying vec2 view_local_2d;
varying vec2 normal_local_2d;

void vertex() {
	normal_local_2d = NORMAL.xz;
	vec3 camera_position_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	view_local_2d = (camera_position_local - VERTEX).xz;
}

void fragment() {
	vec2 v = normalize(view_local_2d); // local direction from fragment to camera, y ignored
	vec2 n = normalize(normal_local_2d); // local normal, y ignored
	float n_dot_v = dot(n,v);
	// make it so that 45° angle results in 0.5 instead of 0.707
	float n_dot_v_linear = -acos(n_dot_v)/(PI*0.5) + 1.0;
	float a;
	if (v.x - n.x > 0.0) { // viewing from right side
		a = mix(1.0, 0.5, n_dot_v_linear);
	}
	else { // viewing from left side
		a = mix(0.0, 0.5, n_dot_v_linear);
	}
	// a is [0;1]
	float range_abs = 1.0 / intended_max_angle;
	// indicates viewing angle. 0.5 = from front, 0 = from left, 1 = from right
	// 0 and 1 are maximum intended viewing angles, values outside the range are possible
	a = mix(0.5 - range_abs*0.5, 0.5 + range_abs*0.5, a);

	int slice = int(UV.x * float(slices)); // id of the slice [0;slices[
	float slice_u = fract(UV.x * float(slices)); // u of the slice [0;1]

	float o = 0.5 / float(images);
	float inner_u_center = mix(1.0-o, o, a);
	float inner_u_from = inner_u_center - o * lenticular_magnification;
	float inner_u_to = inner_u_center + o * lenticular_magnification;
	float inner_u = mix(inner_u_from, inner_u_to, slice_u);

	float outer_u_from = float(slice) / float(slices);
	float outer_u_to = float(slice+1) / float(slices);
	float final_u = mix(outer_u_from, outer_u_to, inner_u);

	vec2 uv = vec2(final_u, UV.y);
	ALBEDO.xyz = texture(sliced_image, uv).xyz;

	//ALBEDO.xyz = texture(sliced_image, UV).xyz;

	ROUGHNESS = roughness;
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal, UV * vec2(1.0, 0.01)).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
