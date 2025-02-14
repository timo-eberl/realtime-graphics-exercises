shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled, blend_add;

// paper that describes this technique:
// https://developer.nvidia.com/gpugems/gpugems3/part-ii-light-and-shadows/chapter-13-volumetric-light-scattering-post-process

uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_linear;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_linear;
uniform vec3 light_position_world;
uniform float decay : hint_range(0.0, 1.0) = 0.5;
uniform float weight : hint_range(0.0, 1.0) = 0.1;

varying vec2 light_position_screen;

const int NUM_SAMPLES = 128;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);

	vec4 light_pos_ndc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(light_position_world, 1);
	light_pos_ndc /= light_pos_ndc.w;
	light_position_screen = (light_pos_ndc.xy * 0.5 + 0.5);
}

void fragment() {
	vec2 delta_uv = SCREEN_UV - light_position_screen;
	delta_uv /= float(NUM_SAMPLES);

	vec2 uv = SCREEN_UV;
	float acc_light = 0.0;

	float current_decay = 1.0;
	for (int i = 0; i < NUM_SAMPLES; i++) {
		// the screen_textures alpha channel is 0 where no objects were drawn (background)
		// (for this to work SSR must be disabled)
		//float light = 1.0 - texture(screen_texture, uv).a;
		
		// alternative: if the depth is 0.0, we can assume no objects were drawn
		// (works with SSR enabled)
		float light = float(texture(depth_texture, uv).r <= 0.0);
		
		light *= current_decay * weight;
		acc_light += light;
		current_decay *= decay;

		uv -= delta_uv;
		if (uv.x > 1.0 || uv.x < 0.0 || uv.y > 1.0 || uv.y < 0.0) {
			break;
		}
	}

	float d = distance(light_position_screen, SCREEN_UV);
	ALBEDO.xyz = vec3(acc_light);
}
