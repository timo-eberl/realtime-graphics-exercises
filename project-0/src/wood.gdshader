shader_type canvas_item;

// see https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
// for built-ins

uniform vec3 knot_color : source_color;
uniform float knot_size = 0.1;
uniform float age = 20.0;
uniform float snarl = 0.5;

uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform sampler2D gradient : filter_linear, repeat_enable;

float inv_lerp(float a, float b, float v) {
	return (v-a) / (b-a);
}

void fragment() {
	COLOR.w = 1.0;

	// the Panel that is used for rendering this shader has fixed aspect ratio
	float aspectRatio = 16.0 / 9.0;
	
	vec2 center = vec2(0.5); // TODO randomize
	vec2 knot_pos = vec2(0.3, 0.2); // TODO randomize
	vec2 knot_stretch = vec2(1.7, 1); // TODO randomize

	vec2 coords = UV; // centered at the midpoint
	coords.y = -coords.y + 1.0;
	coords -= center;

	if (aspectRatio > 1.0) {
		coords = vec2(coords.x * aspectRatio, coords.y ); // compensate for aspect ratio distortion
	} else {
		coords = vec2(coords.x, coords.y / aspectRatio ); // compensate for aspect ratio distortion
	}

	float noise = texture(noise_texture, vec2(coords.x, coords.y * 5.0)).x;
	noise = noise * 2.0 - 1.0;
	vec2 distorted_coords = coords + noise * 0.05 * snarl;

	float noise2 = texture(noise_texture, coords).x;
	noise2 = noise2 * 2.0 - 1.0;
	float d1 = distance(coords / knot_stretch, knot_pos / knot_stretch);
	vec2 ft = knot_pos - (coords / knot_stretch);

	float tk = inv_lerp(knot_size * 3.0, knot_size * 0.0, d1);
	tk = smoothstep(0,1,tk);
	tk = pow(tk, 6.0);

	distorted_coords += tk * ft * knot_size * 100.0;
	float dd = length(distorted_coords * vec2(2, 10));
	dd *= age / 10.0;
	float w = abs(dd) * pow(dd, age / 10.0 * 0.1);
	COLOR.xyz = texture(gradient, vec2(w, 0)).xyz;

	if (d1 < knot_size) {
		float t1 = inv_lerp(knot_size * 0.75, knot_size, d1 + noise2 * 0.02);
		t1 = smoothstep(1,0,t1);
		COLOR.xyz = mix(COLOR.xyz, knot_color, t1);
	}
}
