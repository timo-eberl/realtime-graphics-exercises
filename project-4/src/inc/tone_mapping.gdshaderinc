// tone mapping and sRGB conversion

// sRGB response curve. See: https://en.wikipedia.org/wiki/SRGB#Specification_of_the_transformation
float linearize(float c) {
	return (c < 0.04045) ? (c / 12.92) : (pow( (c + 0.055) / 1.055, 2.4));
}
float unlinearize(float f) {
	return (f < 0.0031308) ? (12.92 * f) : (1.055 * pow(f, 0.416666667) - 0.055);
}
vec3 sRGB_to_linear(vec3 sRGB) {
	return vec3(linearize(sRGB.r), linearize(sRGB.g), linearize(sRGB.b));
}
vec3 linear_to_sRGB(vec3 RGB) {
	return vec3(unlinearize(RGB.r), unlinearize(RGB.g), unlinearize(RGB.b));
}

/*
* see: Equation (4) in
* Reinhard, E., Stark, M., Shirley, P., and Ferwerda, J. 2002.
* Photographic tone reproduction for digital images.
* ACM Trans. Graph. (Proc. SIGGRAPH 2002 special issue) 21, 3, 267–276.
*/
vec3 tonemap_reinhard(vec3 v, float white) {
    float L = dot(vec3(0.2126, 0.7152, 0.0722), v);
    return v * (1.0 + L / (white * white) ) / (1.0 + L);
}
