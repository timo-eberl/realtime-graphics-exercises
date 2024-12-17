shader_type canvas_item;
// constants
const float EPSILON = 0.5; // larger than 0, but so small every smaller value is negative
const float GRADIENT_DT = 0.25;
const int MAX_STEPS = 150; // ray march steps
const float MAX_DISTANCE = 1000.0; // from surface; if we are that far, we won't hit anything
const bool ORTHO_VIEW = false;
const bool SHOW_HEIGHT_CONTOUR_LINES = false;
const bool VISUALIZE_NORMALS = false;
const float HEIGHT_CONTOUR_LINES_DISTANCE = 5.0;
const float ORTHO_CAM_SIZE_Y = 200.0;
// generic shader parameters ... (set from script)
uniform vec3 P; uniform vec3 Q; uniform vec3 R; uniform vec3 S; // ... vectors
uniform float lambda; uniform float mu; uniform float nu; // ... scalars
uniform float theta; uniform float phi; // ... angles, in radians
uniform vec3 color_a; uniform vec3 color_b; uniform vec3 color_c; uniform vec3 color_d; // in sRGB
// camera (set from script)
uniform float aspect_ratio = 1.0; uniform vec3 camera_position = vec3(0,1.5,0);
uniform float azimuth = 0.0; uniform float elevation = 0.0;
uniform float vertical_fov_radians = 0.7854; // 45 degrees
// sky (set from script)
uniform float time_of_day = 12.0; // 0 - 24
uniform float cos_sun_radius = 0.999961923; // cos(0.5 degrees)
// tone mapper (set from script)
uniform float l_white : hint_range(0.0, 10.0) = 1.0;
uniform float exposure : hint_range(-10.0, 10.0) = 0.0;
// rock
uniform float rock_height_offset = 0.0;
uniform float rock_height = 200.0;
uniform float sand_on_rock_amount = 0.5;
// sky
uniform sampler2D zenith_color_gradient : filter_linear, repeat_enable;
uniform sampler2D horizon_color_gradient : filter_linear, repeat_enable;
uniform sampler2D sun_color_gradient : filter_linear, repeat_enable;
uniform sampler2D bloom_radius_gradient : filter_linear, repeat_enable;
uniform sampler2D bloom_strength_gradient : filter_linear, repeat_enable;
// surface textures
uniform sampler2D sand_albedo_texture : filter_linear, repeat_enable;
uniform sampler2D rock_albedo_texture : filter_linear, repeat_enable;
// clouds
uniform sampler2D cloud_texture : filter_linear, repeat_enable;
uniform sampler2D cloud_strength_gradient : filter_linear, repeat_enable;
// controls after what distance the rocks will start to disappear
uniform float cam_rock_fade_distance_start = 2000.0;
uniform float cam_rock_fade_distance_end = 3000.0;
// used to generate the ray
varying vec3 _ray_p; varying vec3 _ray_dir;
// linearized colors
varying vec3 _color_a; varying vec3 _color_b; varying vec3 _color_c; varying vec3 _color_d;
varying vec3 _zenith_color; varying vec3 _horizon_color; varying vec3 _sun_color;
varying vec3 _ground_albedo_a; varying vec3 _ground_albedo_b;

#include "res://inc/tone_mapping.gdshaderinc"
#include "res://inc/sdf_primitives.gdshaderinc"
#include "res://inc/matrices.gdshaderinc"
#include "res://inc/ray_generation.gdshaderinc"
#include "res://webgl-noise/src/cellular2x2.gdshaderinc"
#include "res://webgl-noise/src/noise2D.gdshaderinc"

float inv_lerp(float a, float b, float v) { return (v-a) / (b-a); }

float remap(float i_a, float i_b, float o_a, float o_b, float v) {
	return mix(o_a, o_b, inv_lerp(i_a, i_b, v));
}

float fractal_snoise( vec2 x, int from, int to, int last ) {
	float persistence = 0.27;
	float lacunarity = 3.8;
	float n = 0.0;
	float frequency = 1.0;
	float amplitude = 1.0;
	float max_n = 0.0;
	
	for (int i = 0; i < from; i++) {
		max_n += amplitude;
		frequency *= lacunarity;
		amplitude *= persistence;
	}
	for (int i = from; i < to; i++) {
		n += snoise(x * frequency) * amplitude;
		max_n += amplitude;
		frequency *= lacunarity;
		amplitude *= persistence;
	}
	for (int i = to; i < last; i++) {
		max_n += amplitude;
		frequency *= lacunarity;
		amplitude *= persistence;
	}

	return n / max_n; // normalize the result
}

float rock_height_at(vec3 p, vec3 cam_pos, float threshold) {
	float cam_distance = distance(cam_pos.xz, p.xz);
	if (cam_distance > cam_rock_fade_distance_end) {
		return 0.0;
	}

	vec2 uv = p.xz / 1000.0;
	float h0 = rock_height_offset / rock_height;
	float fn02 = fractal_snoise(uv, 0, 2, 6); // first 2 of 5 octaves
	float noise = fn02 * rock_height + rock_height_offset;
	// only if the rock is above the sand, we calculate the other octaves
	if (noise > threshold - rock_height * 0.1) {
		float fn25 = fractal_snoise(uv, 2, 6, 6);
		noise = (fn02+fn25) * rock_height + rock_height_offset;
	}

	if (cam_distance > cam_rock_fade_distance_start) {
		// cam_distance is between cam_rock_fade_distance_start and cam_rock_fade_distance_end
		return remap(cam_rock_fade_distance_start, cam_rock_fade_distance_end, noise, 0.0, cam_distance);
	}

	return noise;// * rock_height + rock_height_offset;
}

float sand_height_at(vec3 p, vec3 cam_pos) {
	float cam_distance = distance(cam_pos.xz, p.xz);

	vec2 uv = p.xz / 250.0;
	float noise = snoise(uv * 2.5) * 0.7;
	uv += noise * 0.1;
	float height = cellular2x2(uv).x;
	height = smoothstep(0, 1, height);
	height *= 60.0;

	return height;
}

float smooth_height_at(vec3 p, vec3 cam_pos) {
	float sh = sand_height_at(p, cam_pos);
	// pass high threshold height so the rock height is calculated with less detail
	float rh = rock_height_at(p, cam_pos, sh) + 0.0;
	return max(sh, rh);
}

float sdf_detail(vec3 p, out bool is_close_to_rock) {
	float sh = sand_height_at(p, _ray_p);
	// pass the sand height so the rock height can be calculated with less detail
	// where the sand is covering the rocks
	float rh = rock_height_at(p, _ray_p, sh);
	float sdSand = sdPlane(p, vec3(0,1,0), -sh);
	float sdRock = sdPlane(p, vec3(0,1,0), -rh);
	is_close_to_rock = sdRock - sdSand < 10.0 && sdRock < 50.0;
	return opSmoothUnion(sdSand, sdRock, 5.0);
	// return opUnion(sdSand, sdRock);
}

float sdfSand(vec3 p) { return sdPlane(p, vec3(0,1,0), -sand_height_at(p, _ray_p)); }

float sdf(vec3 p) { bool b; return sdf_detail(p, b); }

vec3 gradient(vec3 p) {
	const vec3 dx = vec3(GRADIENT_DT, 0.0, 0.0);
	const vec3 dy = vec3(0.0, GRADIENT_DT, 0.0);
	const vec3 dz = vec3(0.0, 0.0, GRADIENT_DT);
	return vec3( (sdf(p + dx) - sdf(p - dx)) / (2.0 * GRADIENT_DT),
				 (sdf(p + dy) - sdf(p - dy)) / (2.0 * GRADIENT_DT),
		 		 (sdf(p + dz) - sdf(p - dz)) / (2.0 * GRADIENT_DT)
	);
}

vec3 sun_direction() {
	// 0 (0:00) to TAU (24:00)
	float remapped_time = remap(0.0, 24.0, 0.0, TAU, time_of_day);

	float az = remapped_time; // east and west directions are incorrect but whatever

	// cos wave that is lowest at 0:00, peaks at 12:00 and goes through 0 at sunrise (6:00) and sunset (18:00)
	// peak is 45° or pi/4, which is roughly the maximum altitude at the equator (https://www.suncalc.org)
	float el = -cos( remapped_time ) * PI * 0.25;

	// convert spherical coordinates (azimuth, elevation) to direction
	float x = cos(el) * cos(az);
	float y = sin(el);
	float z = cos(el) * sin(az);
	return normalize(vec3(x,y,z));
}

float fog_density() {
	float cloud_strength = texture(cloud_strength_gradient, vec2(time_of_day/24.0, 0)).x;
	return mix(0.0001, 0.0004, cloud_strength);
}

// https://iquilezles.org/articles/fog/
vec3 applyFog( in vec3  col,   // color of pixel
			   in float t,	   // distance to point
			   in vec3  rd,	   // camera to point
			   in vec3  lig )  // sun direction
{
	float b = fog_density();
	float sunAmount = max( dot(rd, lig), 0.0 );
	vec3  fogColor  = mix( mix(_zenith_color, vec3(0.5,0.6,0.7), 0.7),
						   _sun_color,
						   pow(sunAmount,4.0) );
	return col*exp(-t*b) + fogColor*(1.0-exp(-t*b));
}

// https://iquilezles.org/articles/functions/
float rational_bump( float x, float k ) { return 1.0/(1.0+k*x*x); }

vec3 sky(vec3 dir) {
	float bloom_strength = texture(bloom_strength_gradient, vec2(time_of_day/24.0, 0)).x;
	float bloom_radius = texture(bloom_radius_gradient, vec2(time_of_day/24.0, 0)).x;

	dir = normalize(dir);
	vec3 sky_color = mix(_horizon_color, _zenith_color, clamp(pow(dir.y, 0.2), 0, 1));
	float t = smoothstep(cos_sun_radius*0.9998, cos_sun_radius, dot(dir, sun_direction()));
	float t_bloom = inv_lerp(cos_sun_radius, cos_sun_radius*mix(1.0, 0.8, bloom_radius), dot(dir, sun_direction()));
	t_bloom = rational_bump(t_bloom, 64.0) * bloom_strength * 15.0;

	vec3 col = mix(sky_color, _sun_color * 100.0, t) + mix(sky_color, _sun_color, t_bloom);
	vec3 col_with_fog = applyFog( col, 100000.0, normalize(dir), sun_direction() );
	float ti = clamp( smoothstep(0.0,0.1, dir.y) ,0,1);
	return mix(col_with_fog, col, ti);
}

/*
night
	zenith: 010411
	horizon: 243a51
morning
	zenith: 005291
	horizon: fa2e00
	sun: ff621f
	bloom radius: 0.6855
	bloom strength: 0.0667
day
	zenith: 2124db
	horizon: 92ebfc
	sun: f7edcb
	bloom radius: 0.0035
	bloom strength: 1
evening
	zenith: 133142
	horizon: ff5e00
	sun: cf8c55
	bloom radius: 0.11
	bloom strength: 0.366
*/

vec3 shade(vec3 albedo, vec3 point, vec3 normal) {
	// sun : Lambertian
	// the integral over the upper hemisphere times cos(theta) equals to pi
	// this cancels out with albedo/pi from lambertian BRDF
	vec3 res = albedo * max(0.0, dot(normal, sun_direction() * _sun_color));
	res += albedo * max(0.0, normal.y) * _zenith_color;
	res += albedo * vec3(0.1); // ambient
	return res;
}

vec3 ground_color(vec3 p) {
	vec3 albedo = vec3(p.x >= 0.0 ? 1.0 : 0.2, 0.2, p.z >= 0.0 ? 1.0 : 0.2);
	vec3 pf = fract(p * 0.5); // make grid cell 1m large
	bool checkerboard = (pf.x > 0.5) == (pf.z > 0.5);
	albedo *= (checkerboard ? 0.15 : 0.5);
	return shade(albedo, p, vec3(0.0,1.0,0.0));
}

vec3 visualize_normal(vec3 n) {
	vec3 color = vec3(0);
	// the same as dot(N,L) lighting, but cheaper
	if (n.x > 0.0) { color += n.x * vec3(1.0, 0.0, 0.0); }
	else { color += -n.x * vec3(0.8, 0.0, 0.5); }
	if (n.z > 0.0) { color += n.z * vec3(0.0, 0.0, 1.0); }
	else { color += -n.z * vec3(0.0, 0.5, 1.0); }
	if (n.y > 0.0) { color += n.y * vec3(0, 0.1, 0); }
	return color;
}

vec3 shade_surface(vec3 p, vec3 normal) {
	if (SHOW_HEIGHT_CONTOUR_LINES) {
		float t = distance( fract( p.y/HEIGHT_CONTOUR_LINES_DISTANCE + 0.5 ), 0.5 );
		if (t < 0.03) { return vec3(0); }
	}
	if (VISUALIZE_NORMALS) { return visualize_normal(normal); }
	vec2 sand_uv = vec2(p.x, -p.z) * 0.2;
	vec2 rock_uv = vec2(p.x, -p.z) * 0.05;
	vec3 sand_albedo = texture(sand_albedo_texture, sand_uv).xyz;
	vec3 rock_albedo = texture(rock_albedo_texture, rock_uv).xyz;
	sand_albedo = sRGB_to_linear(sand_albedo) * vec3(1.0, 0.9, 0.9);
	rock_albedo = sRGB_to_linear(rock_albedo) * vec3(1.0, 0.9, 0.8);

	// add some sand on top of the rocks based on the normal y direction
	float t = remap(0.5, 0.9, 0.0, sand_on_rock_amount, normal.y);
	t = clamp(t, 0, sand_on_rock_amount);
	vec3 rock_with_sand_albedo = mix(rock_albedo, sand_albedo, t);

	// mix colors based on sdf
	float distance_to_sand = sdfSand(p) - EPSILON;
	vec3 albedo = mix(sand_albedo, rock_with_sand_albedo, clamp(distance_to_sand,0,1));

	return applyFog(
		shade(albedo, p, normal),
		distance(p, _ray_p), normalize(_ray_dir), sun_direction()
	);
}

vec3 background(Ray ray) {
	// draw ground plane shaded as sand ("beneath" sdf) to hide that sometimes the sdf becomes invisible
	// intersect against ground plane
	float t = (-ray.p.y) / (ray.dir.y);
	// intersection in front? draw ground
	if (t > 0.0) {
		vec3 hitpoint = ray.p + t * ray.dir;
		float cam_distance = distance(ray.p.xz, hitpoint.xz);
		return shade_surface(hitpoint, vec3(0,1,0));
	}

	// draw clouds on a plane in the sky
	float cloud_height = 500.0;
	float t2 = (-ray.p.y + 500.0) / (ray.dir.y);
	float clouds = 0.0;
	vec3 cloud_color = vec3(0.7);
	if (t2 > 0.0) {
		vec3 hitpoint = ray.p + t2 * ray.dir;
		vec2 uv = hitpoint.xz * 0.00003;
		uv.x += time_of_day * 0.1;
		clouds = texture(cloud_texture, uv).x;
		float cam_distance = distance(ray.p.xz, hitpoint.xz);
		clouds *= clamp( inv_lerp(50000.0, 10000.0, cam_distance) ,0,1); // fade out in distance
		float cloud_strength = texture(cloud_strength_gradient, vec2(time_of_day/24.0, 0)).x;
		cloud_strength = mix(0.1, 1.0, cloud_strength);
		clouds = clamp( mix(-cloud_strength, cloud_strength, clouds) ,0,1);
		// transmittance + reflection
		cloud_color = shade(cloud_color, hitpoint, ray.dir) + shade(cloud_color, hitpoint, vec3(0,1,0));
		cloud_color *= 0.5;
	}

	return sky(ray.dir) + cloud_color * clouds;
}

vec3 sphere_trace_ray(Ray ray) {
	// step front-to-back over the ray
	vec3 p = ray.p;
	float d;
	for (int i = 0; i < MAX_STEPS; ++i) {
		bool is_close_to_rock;
		d = sdf_detail(p, is_close_to_rock);
		if (d < EPSILON || d > MAX_DISTANCE) {
			break;
		}
		if (is_close_to_rock) {
			// decrease stepsize the closer we are to a rock to avoid rendering artifacts
			// caused by the fact that the rock sdf has a lipschitz constant > 1
			float step_shrink = 0.25; // compromise between artifacts and performance. lower = less artifacts
			float t = remap(40.0, 0.0, 1.0, step_shrink, d);
			t = min(1.0, t);
			d *= t;
		}
		p = p + ray.dir * d;
	}

	if (d < EPSILON) {
		vec3 normal = normalize(gradient(p));
		return shade_surface(p, normal);
	}
	else {
		return background(ray);
	}
}

void vertex() {
	Ray ray;
	if (ORTHO_VIEW) {
		ray = orthographic_ray(ORTHO_CAM_SIZE_Y, aspect_ratio, UV);
	}
	else {
		vec3 cam_pos = camera_position + vec3(0, smooth_height_at(camera_position, camera_position), 0);
		ray = perspective_ray(azimuth, elevation, cam_pos, aspect_ratio, vertical_fov_radians, UV);
	}
	_ray_p = ray.p; _ray_dir = ray.dir;
	// color space conversions
	_zenith_color = sRGB_to_linear( texture(zenith_color_gradient, vec2(time_of_day/24.0, 0.0)).xyz );
	_horizon_color = sRGB_to_linear( texture(horizon_color_gradient, vec2(time_of_day/24.0, 0.0)).xyz );
	_sun_color = sRGB_to_linear( texture(sun_color_gradient, vec2(time_of_day/24.0, 0.0)).xyz );
	_color_a = sRGB_to_linear(color_a); _color_b = sRGB_to_linear(color_b);
	_color_c = sRGB_to_linear(color_c); _color_d = sRGB_to_linear(color_d);
}

void fragment() {
	Ray ray = Ray(_ray_p, normalize(_ray_dir));

	COLOR = vec4(linear_to_sRGB(tonemap_reinhard(
		sphere_trace_ray(ray) * pow(2.0, exposure), l_white
	)), 1.0);
}
