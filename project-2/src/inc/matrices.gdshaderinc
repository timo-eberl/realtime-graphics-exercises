// right-handed coordinate system

mat3 mat3_rotate_x(float angle_radians) {
	return transpose(mat3(
		vec3(1.0,                   0.0,                   0.0),
		vec3(0.0,    cos(angle_radians),    sin(angle_radians)),
		vec3(0.0,   -sin(angle_radians),    cos(angle_radians))
	));
}

mat3 mat3_rotate_y(float angle_radians) {
	return transpose(mat3(
		vec3(cos(angle_radians),   0.0,   -sin(angle_radians)),
		vec3(               0.0,   1.0,                   0.0),
		vec3(sin(angle_radians),   0.0,    cos(angle_radians))
	));
}

mat3 mat3_rotate_z(float angle_radians) {
	return transpose(mat3(
		vec3( cos(angle_radians),    sin(angle_radians),    0.0),
		vec3(-sin(angle_radians),    cos(angle_radians),    0.0),
		vec3(                0.0,                   0.0,    1.0)
	));
}
