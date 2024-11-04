shader_type canvas_item;

// see https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
// for built-ins

float inv_lerp(float a, float b, float v) {
	return (v-a) / (b-a);
}

void fragment() {
	float aspectRatio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	vec2 correctedUV = UV - 0.5; // centered at the midpoint

	if (aspectRatio > 1.0) {
		correctedUV = vec2(correctedUV.x * aspectRatio, correctedUV.y ); // compensate for aspect ratio distortion
	} else {
		correctedUV = vec2(correctedUV.x, correctedUV.y / aspectRatio ); // compensate for aspect ratio distortion
	}

	correctedUV.x += 0.3;
	float d = length(correctedUV);
	float t = correctedUV.y * 75.0;

	float w = fract(abs(t) * pow(d, 0.4));

	COLOR.w = 1.0;

	vec3 color_p = vec3(0.27,0.19,0.14);
	vec3 color_s = vec3(0.55,0.33,0.19);
	if (w > 0.75) {
		COLOR.xyz = mix(color_p, color_s, inv_lerp(1.0, 0.75, w));
	} else {
		COLOR.xyz = mix(color_p, color_s, inv_lerp(0, 0.75, w));
	}
}
