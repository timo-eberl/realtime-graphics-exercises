shader_type canvas_item;

// see https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
// for built-ins

uniform vec2 planks_num = vec2(1.5, 3.0);
uniform vec4 border_color : source_color;
uniform float border_thickness = 1.0;
uniform float age : hint_range(0, 100) = 20.0;
uniform float ring_compression : hint_range(0, 1) = 0.1;
uniform float snarl : hint_range(0, 1) = 0.5;

uniform float seed : hint_range(0, 1) = 0.0;

uniform float knot_size = 0.1;

uniform sampler2D knot_color_gradient : filter_linear, repeat_enable;
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform sampler2D gradient : filter_linear, repeat_enable;

float inv_lerp(float a, float b, float v) {
	return (v-a) / (b-a);
}

void fragment() {
	COLOR.w = 1.0;

	// the Panel that is used for rendering this shader has fixed aspect ratio
	float aspect_ratio = 16.0 / 9.0;
	aspect_ratio *= planks_num.y / planks_num.x;

	vec2 coords = UV; // centered at the midpoint

	coords = coords * planks_num;
	ivec2 grid = ivec2(coords);
	if (grid.y % 2 == 0) {
		coords.x += 0.5;
	}
	grid = ivec2(coords);

	coords = fract(coords);

	vec2 rand_uv = vec2(grid+1) / planks_num;
	float rand_sample  = texture(noise_texture, rand_uv + seed).x;
	float rand_sample2 = texture(noise_texture, rand_uv + seed + 0.1).x;
	float rand_sample3 = texture(noise_texture, rand_uv + seed + 0.2).x;
	float rand_sample4 = texture(noise_texture, rand_uv + seed + 0.3).x;
	float rand_sample5 = texture(noise_texture, rand_uv + seed + 0.4).x;
	float rand_sample6 = texture(noise_texture, rand_uv + seed + 0.5).x;

	vec2 center = vec2(rand_sample, rand_sample2) * 2.5;
	vec2 knot_pos = vec2(rand_sample3, rand_sample4) - 0.5;
	vec2 knot_stretch = vec2(mix(1.0, 2.5, rand_sample5), 1.0) * mix(0.5, 0.7, rand_sample6);

	coords.y = -coords.y + 1.0;
	vec2 ccoords = coords - vec2(0.5);
	coords -= center;

	float border = 0.0;
	float diff = border_thickness * 0.005;
	border += smoothstep(0.5 - diff              , 0.5, abs(ccoords.x));
	border += smoothstep(0.5 - diff * aspect_ratio, 0.5, abs(ccoords.y));

	if (aspect_ratio > 1.0) {
		coords = vec2(coords.x * aspect_ratio, coords.y ); // compensate for aspect ratio distortion
	} else {
		coords = vec2(coords.x, coords.y / aspect_ratio ); // compensate for aspect ratio distortion
	}

	float noise = texture(noise_texture, vec2(coords.x, coords.y * 5.0)).x;
	noise = noise * 2.0 - 1.0;
	vec2 distorted_coords = coords + noise * 0.05 * snarl;

	float noise2 = texture(noise_texture, coords).x;
	noise2 = noise2 * 2.0 - 1.0;
	vec2 ccoords_cor = ccoords * vec2(aspect_ratio, 1.0);
	float d1 = distance(ccoords_cor / knot_stretch, knot_pos / knot_stretch);
	vec2 ft = knot_pos - (coords / knot_stretch);

	float tk = inv_lerp(knot_size * 10.0, knot_size * 0.0, d1);
	tk = smoothstep(0,1,tk);
	tk = pow(tk, 15.0);

	distorted_coords += tk * ft * knot_size * 2.0;
	float dd = length(distorted_coords * vec2(2, 10));
	dd *= age / 10.0;
	float w = abs(dd) * pow(dd, (age / 10.0) * ring_compression);
	COLOR.xyz = texture(gradient, vec2(w, 0)).xyz;

	if (d1 < knot_size) {
		float t1 = inv_lerp(knot_size * 0.7, knot_size, d1 + noise2 * 0.02);
		t1 = smoothstep(1,0,t1);
		vec3 knot_color = texture(knot_color_gradient, vec2(d1 * 90. + noise2 * 1.5, 0)).xyz;
		COLOR.xyz = mix(COLOR.xyz, knot_color, t1);
	}

	COLOR.xyz = mix(COLOR.xyz, border_color.xyz, border * border_color.w);
}
