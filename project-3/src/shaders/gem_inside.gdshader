shader_type spatial;

uniform sampler2D gem_noise_texture : filter_nearest, repeat_enable;
uniform vec2 gem_noise_scale = vec2(1);
uniform sampler2D random_1d_texture_0 : filter_nearest, repeat_enable;
uniform sampler2D random_1d_texture_1 : filter_nearest, repeat_enable;
uniform sampler2D random_1d_texture_2 : filter_nearest, repeat_enable;

// diamond: 	2.417 		https://en.wikipedia.org/wiki/Diamond
// sapphire: 	1.77 		https://en.wikipedia.org/wiki/Sapphire
// ruby: 		1.77 		https://en.wikipedia.org/wiki/Ruby
// amethyst: 	1.55 		https://en.wikipedia.org/wiki/Amethyst
// emerald: 	1.57 		https://en.wikipedia.org/wiki/Emerald
uniform float refractive_index = 2.417;
uniform vec3 color_0 : source_color = vec3(0);
uniform vec3 color_1 : source_color = vec3(1);
uniform float fake_distance;

struct Ray {
	vec3 p; // ray origin
	vec3 dir;
};

struct Plane {
	vec3 p; // point on the plane
	vec3 n; // normal
};

bool ray_plane_intersection(Ray ray, Plane plane, out vec3 intersection_point) {
	float denominator = dot(ray.dir, plane.n);
	// if denominator is 0, the ray is parallel
	if (denominator == 0.0) return false;

	vec3 ray_to_plane = plane.p - ray.p;
	float t = dot(ray_to_plane, plane.n) / denominator;
	// if t is negative, the intersection is behind the rays origin
	if (t < 0.0) return false;

	intersection_point = ray.p + t * ray.dir;
	return true;
}

vec2 uv_on_plane(Plane plane, vec3 intersection_point) {
	// choose a non-parallel vector a
	vec3 a = (abs(plane.n.x) < 0.99) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	// compute tangent vectors in the plane
	vec3 t1 = normalize(cross(a, plane.n));
	vec3 t2 = normalize(cross(plane.n, t1));
	// vector from plane position to the intersection point
	vec3 v = intersection_point - plane.p;
	// project the vector onto the tangent vectors to get the UV coordinates
	vec2 uv;
	uv.x = dot(v, t1);
	uv.y = dot(v, t2);
	return uv;
}

void fragment() {
	ROUGHNESS = 0.2;
	METALLIC = 0.0;
	SPECULAR = 0.15;

	vec3 r = refract(-VIEW, NORMAL, 1.0 / refractive_index);
	r = mat3(INV_VIEW_MATRIX) * r;
	vec3 v = mat3(INV_VIEW_MATRIX) * -VIEW;

	Ray ray = Ray(
		(INV_VIEW_MATRIX * vec4(VERTEX, 1)).xyz, r
	);

	vec3 p_n = mat3(INV_VIEW_MATRIX) * NORMAL;
	Plane plane = Plane(
		NODE_POSITION_WORLD - p_n * fake_distance, p_n
	);

	vec3 intersection_point;
	bool is_intersecting = ray_plane_intersection(ray, plane, intersection_point);

	if (is_intersecting) {
		vec2 inner_uv = uv_on_plane(plane, intersection_point) * gem_noise_scale + 0.5;
		float s = texture(gem_noise_texture, inner_uv).x;

		ALBEDO = mix(color_0, color_1, s);

		NORMAL = normalize(vec3(
			texture(random_1d_texture_0, vec2(s, 0)).x,
			texture(random_1d_texture_1, vec2(s, 0)).x,
			texture(random_1d_texture_2, vec2(s, 0)).x
		));
		NORMAL = normalize( mix(vec3(-1), vec3(1), NORMAL) );
		NORMAL = mat3(VIEW_MATRIX) * NORMAL;
	}
}
