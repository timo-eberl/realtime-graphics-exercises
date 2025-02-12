shader_type spatial;
render_mode unshaded;

uniform int images = 3;
uniform int slices = 10;
uniform float angle : hint_range(-1.0, 2.0, 0.01) = 0.5;
uniform sampler2D sliced_image : source_color, filter_linear, repeat_disable;

void fragment() {
	float u = UV.x;
	int slice = int(u * float(slices)); // id of the slice [0;slices[
	float slice_u = fract(u * float(slices)); // u of the slice [0;1]

	// TODO calculate from viewing direction
	// indicates viewing angle. 0.5 = from front, 0 = from left, 1 = from right
	// 0 and 1 are maximum intended viewing angles, values outside the range are possible
	float a = angle;

	float o = 0.5 / float(images);
	float inner_u_center = mix(1.0-o, o, a);
	float inner_u_from = inner_u_center - o;
	float inner_u_to = inner_u_center + o;
	float inner_u = mix(inner_u_from, inner_u_to, slice_u);

	float outer_u_from = float(slice) / float(slices);
	float outer_u_to = float(slice+1) / float(slices);
	float final_u = mix(outer_u_from, outer_u_to, inner_u);

	ALBEDO.xyz = texture(sliced_image, vec2(final_u, UV.y)).xyz;
}
