#include "matrices.gdshaderinc"

struct Ray { vec3 p; vec3 dir; };

Ray perspective_ray(
		float p_azimuth, float p_elevation, vec3 p_camera_position, float p_aspect, float p_fov_y,
		vec2 p_uv
	) {
	// rotate - first x, then y
	mat3 rotation = mat3_rotate_y(p_azimuth) * mat3_rotate_x(p_elevation);
	// right-handed, y up
	vec3 forward = rotation * vec3(0, 0,-1);
	vec3 right   = rotation * vec3(1, 0, 0);
	vec3 up      = rotation * vec3(0, 1, 0);
	// scale camera for FoV and focal length
	// our y coordinate system is 2 high, from -1.0 to 1,0
	float focal_length = 2.0 / (2.0 * tan(p_fov_y * 0.5));
	// scale vectors; by construction, they are already normalized
	right = right * p_aspect;
	forward = forward * focal_length;
	// center on (0.0) ; make the y range from -1 to 1 and point upwards
	vec2 xy = (p_uv - vec2(0.5)) * vec2(2, -2);
	return Ray(p_camera_position, forward + xy.x * right + xy.y * up);
}

Ray orthographic_ray(float p_size_y, float p_aspect_ratio, vec2 p_uv) {
	Ray ray;
	ray.dir = vec3(0,-1,0);
	ray.p.y = 100.0;
	ray.p.x = mix(-p_size_y * p_aspect_ratio, p_size_y * p_aspect_ratio, p_uv.x);
	ray.p.z = mix(-p_size_y, p_size_y, p_uv.y);
	return ray;
}
