shader_type canvas_item;

// for numeric test

const float FAR = 10000.0;   // distance to background
const float EPSILON = 0.001; // larger than 0, but so small every smaller value is negative …
const float GRADIENT_DT = 0.05; // half of the step size

// generic shader parameters ...

// .. Vectors

uniform vec3 P;
uniform vec3 Q;
uniform vec3 R;
uniform vec3 S;

// ... scalars

uniform float lambda;
uniform float mu;
uniform float nu;

// ... angles, in degrees

uniform float theta;
uniform float phi;

// converted to radians

varying float _theta;
varying float _phi;

// in sRGB curve

uniform vec3 colorA;
uniform vec3 colorB;
uniform vec3 colorC;
uniform vec3 colorD;

// linearized

varying vec3 _colorA;
varying vec3 _colorB;
varying vec3 _colorC;
varying vec3 _colorD;

// camera

uniform float ASPECT_RATIO = 1.77777777778; // 16.0/9.0

uniform float cameraDistance = 1.0;
uniform float azimuth = 0.0;
uniform float elevation = 0.0;

uniform float vFoV_degrees : hint_range(0.0, 180.0)= 45.0;

// sky

uniform vec3 zenithColor  : source_color = vec3(0.2,0.3,0.5);
uniform vec3 horizonColor : source_color = vec3(0.2,0.45,0.75);

uniform vec3 sunColor : source_color = vec3(1.0);
uniform vec3 sunDirection = vec3(0.7,0.7,-0.7); // normalized in shader
uniform float sunRadiusDegrees : hint_range(0.0,90.0) = 0.5;

// ground

uniform float groundLevel = -1.0;
uniform vec3 groundAlbedoA : source_color = vec3(0.3);
uniform vec3 groundAlbedoB : source_color = vec3(0.7);

// tone mapper

uniform float L_white : hint_range(0.0, 10.0) = 1.0;
uniform float exposure : hint_range(-10.0, 10.0) = 0.0;

// ray marcher

const int MAX_STEPS = 100;
const float BACKGROUND_DISTANCE = 10.0; // from surface; if we are that far, we will never hit anything

// the coordinates that are used by the ray generator

varying vec3 _eye;

varying vec3 _right;
varying vec3 _up;
varying vec3 _forward;

// linearized colors

varying vec3 _zenithColor;
varying vec3 _horizonColor;
varying vec3 _sunColor;

varying vec3 _groundAlbedoA;
varying vec3 _groundAlbedoB;

// sky varyings

varying vec3  _sunDirection;
varying float _cosSunRadius;

struct Ray {
	vec3 p;
	vec3 dir;
};

// tone mapping and sRGB conversion

/**
 * sRGB response curve. See: https://en.wikipedia.org/wiki/SRGB#Specification_of_the_transformation
 */

float linearize( float c ) {
  return (c < 0.04045) ? (c / 12.92) : (pow( (c + 0.055) / 1.055, 2.4));
}

vec3 sRGB_to_linear( vec3 sRGB) {

  // alpha channel is always linear: pass it through

  return vec3( linearize(sRGB.r), linearize(sRGB.g), linearize(sRGB.b));
}

float unlinearize(float f) {

  // alpha channel is always linear: pass it through

 return (f < 0.0031308) ? (12.92 * f) : (1.055 * pow(f, 0.416666667) - 0.055);
}

vec3 linear_to_sRGB( vec3 RGB) {

  // alpha channel is always linear: pass it through

  return vec3( unlinearize(RGB.r),
               unlinearize(RGB.g),
			   unlinearize(RGB.b));
}



void vertex() {
		// set up forward, up and right vectors

	// start with a standard system: look towards -z
	vec3 forward = vec3( 0.0,  0.0,  1.0);
	vec3 right   = vec3( 1.0,  0.0,  0.0);
	vec3 up      = vec3( 0.0,  1.0,  0.0);

	// then, rotate by azimuth and elevation
	float _azimuth  = radians(azimuth);
	float _elevation = radians(elevation);

	// for easier readability, use generic rotation matrices

	// Godot's GLSL constructs matrices out of colum vectors
	// write them as rows
	mat3 rotateX = transpose(
		mat3( vec3(1.0,                0.0,              0.0),
	          vec3(0.0,    cos(_elevation),   -sin(_elevation)),
			  vec3(0.0,    sin(_elevation),    cos(_elevation))
			));

	mat3 rotateY = transpose(
		mat3( vec3(cos(_azimuth), 0.0, -sin(_azimuth)),
	          vec3(          0.0, 1.0,            0.0),
			  vec3(sin(_azimuth), 0.0,  cos(_azimuth))
			));

	mat3 combined_rotation = rotateY * rotateX;

	_forward = combined_rotation * forward;
	_right   = combined_rotation * right;
	_up      = combined_rotation * up;

	_eye = -_forward * cameraDistance;

	// scale camera for FoV and focal length

	// our y coordinate system is 2 high, from -1.0 to 1,0

	float focalLength = 2.0 / (2.0 * tan(radians(vFoV_degrees / 2.0))) ;

	// scale vectors; by construction, they are already normalized

	_right = _right * ASPECT_RATIO;
	_forward = _forward * focalLength;

	// sky precompations

	_sunDirection = normalize(sunDirection);
	_cosSunRadius = cos(radians(sunRadiusDegrees));

	// color space conversions

	_zenithColor = sRGB_to_linear(zenithColor);
	_horizonColor = sRGB_to_linear(horizonColor);
	_sunColor = sRGB_to_linear(sunColor);

	_groundAlbedoA = sRGB_to_linear(groundAlbedoA);
	_groundAlbedoB = sRGB_to_linear(groundAlbedoB);

	_colorA = sRGB_to_linear(colorA);
	_colorB = sRGB_to_linear(colorB);
	_colorC = sRGB_to_linear(colorC);
	_colorD = sRGB_to_linear(colorD);

	// angle conversions

	_theta = radians(theta);
	_phi = radians(phi);

}


vec3 sky(vec3 dir) {
	dir = normalize(dir);
	return mix(mix(_horizonColor, _zenithColor, dir.y),
			   _sunColor,
			   smoothstep(_cosSunRadius*0.9999,
						  _cosSunRadius,
						  dot(dir,_sunDirection)));

}

// normal is normalized

vec3 shade(vec3 albedo, vec3 point, vec3 normal) {

	// sun : Lambertian
	// the integral over the upper hemisphere times cos(theta) equals to pi
	// this cancels out with albedo/pi from lambertian BRDF
	vec3 res = albedo * max(0.0, dot(normal, sunDirection));
	res += albedo * max(0.0, normal.y) * _zenithColor;
	res += albedo * vec3(0.1); // ambient

	// point can be used later for a simple shadow calculation

	return res;
}

vec3 groundColor(vec3 p) {
	vec3 quadrantMultiplier = vec3(0.2, 0.2, 0.2);
	if (p.x >= 0.0) {
		quadrantMultiplier.r = 1.0;
	}
	if (p.z >= 0.0) {
		quadrantMultiplier.g = 1.0;
	}

	vec3 pf = fract(p * 0.5); // make grid cell 1m large
	// checkerboard
	if ((pf.x > 0.5) == (pf.z > 0.5)) {
		return shade(_groundAlbedoA * quadrantMultiplier, p, vec3(0.0,1.0,0.0));
	} else {
		return shade(_groundAlbedoB * quadrantMultiplier, p, vec3(0.0,1.0,0.0));
	}
}

vec3 background(Ray ray) {
	// intersect against ground plane

	float t = (groundLevel - ray.p.y) / (ray.dir.y);
	if (t <= 0.0) { // intersection not in front? show background
		return sky(ray.dir);
	} else {
		vec3 hitpoint = ray.p + t * ray.dir;
		vec3 a = abs(hitpoint);
		if (max(a.x, max(a.y, a.z)) > 2.0) { // no checkerboard in the distance
			return sky(ray.dir);
		} else {
			return groundColor(hitpoint);
		}
	}
}

// SDF primitives ============================================================

// ... insert here ...

// SDF primitives and operations from
//
// Inigo Quilez: Computer Graphcis, Mathematics, Shaders, Fractals, Demoscene and
// More – Articles -- Distance Functions
// https://iquilezles.org/articles/distfunctions/
// retrieved 2023-11-12 under the [MIT license](https://opensource.org/licenses/MIT)
//
// Copyright <YEAR> <COPYRIGHT HOLDER>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// eventual modifications are limited to make them work in this code environment and/or cosmetic

float sdSphere( vec3 p, float s ) {
	return length(p)-s;
}

float sdBox( vec3 p, vec3 b ) {
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdBoxFrame( vec3 p, vec3 b, float e ) {
	p = abs(p)-b;
	vec3 q = abs(p+e)-e;
	return min(min(
	length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
	length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
	length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdCappedCylinder( vec3 p, float h, float r ) {
	vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float opOnion( in float sdf, in float thickness ) {
	return abs(sdf)-thickness;
}

float opSubtraction( float d1, float d2 ) { 
	return max(-d1,d2); 
}

// end of SDF primitives and operations based on Inigo Quilez' code

float sdf(vec3 p) {
	vec3 offset = vec3(0,-1,0);
	p -= offset;
	
	float box = sdBox(p - P - vec3(0,4.0,0), vec3(2.0));
	float cylinder = sdCappedCylinder(p - P - vec3(0,1.5,0), 1.5, 0.75);
	float cylinder_boundary = opOnion(cylinder, 0.03);
	return opSubtraction(box, cylinder_boundary);
}

vec3 gradient(vec3 p) {
	const vec3 dx = vec3(GRADIENT_DT, 0.0, 0.0);
	const vec3 dy = vec3(0.0, GRADIENT_DT, 0.0);
	const vec3 dz = vec3(0.0, 0.0, GRADIENT_DT);

	return vec3( (sdf(p + dx) - sdf(p - dx))
				/ (2.0 * GRADIENT_DT),
				 (sdf(p + dy) - sdf(p - dy))
				/ (2.0 * GRADIENT_DT),
		 		 (sdf(p + dz) - sdf(p - dz))
				/ (2.0 * GRADIENT_DT)
	);
}

float calcTexcoordU(vec2 dir) {
	float longitude = atan(-dir.y, dir.x); // [-pi;pi]
	return (longitude / 3.141) * 0.5 + 0.5; // [0;1]
}

vec3 sphereTraceRay(Ray ray) {

	// step front-to-back over the ray

	vec3 p = ray.p;
	float d;

	for (int i = 0; i < MAX_STEPS; ++i) {
		d = sdf(p);
		if (d < EPSILON || d > BACKGROUND_DISTANCE) {
			break;
		}
		p = p + ray.dir * d;
	}

	if (d < EPSILON) { // shade surface
		vec3 normal = normalize(gradient(p));
		vec2 normal_plane = normalize(vec2(p.x, p.z));
		vec2 uv = vec2(calcTexcoordU(normal_plane), (p.y * 0.5) + 0.5);
		uv.x += smoothstep(0, 1, uv.y) * 0.2;
		float frequency = 10.0;
		float thickness = 0.03;
		
		// candle
		vec3 light_pos = vec3(0, -0.5, 0);
		float d = distance(light_pos, p);
		vec3 l = normalize(p - light_pos);
		float nDotL = dot(normal, l);
		float lightStrength = 3.0;
		float lightTransparencyStrength = 3.0;
		float lighting = nDotL * lightStrength / (d*d);
		float alpha = 0.7;
		
		bool isSideStrip = fract(uv.x * frequency) < thickness * frequency;
		bool isTopOrBottom = abs(normal.y) > 0.1;
		if (isSideStrip || isTopOrBottom) {
			// metal material
			vec3 light = max(0,(-lighting)) * _colorA * 0.15;
			return light + shade(_colorB, p, normal);
		}
		else {
			bool isInside = lighting < 0.0;
			vec3 light = abs(lighting) * _colorA;
			vec3 shading = light + shade(vec3(1), p, normal) * 0.25;
			return isInside
				? mix(background(ray), shading, alpha)
				: shading * lightTransparencyStrength;
		}
	} else {
		return background(ray);
	}
}

Ray makeRay(vec2 xy) {
	// construct ray

	Ray ray;
	ray.p = _eye;
	ray.dir = normalize(_forward + xy.x * _right + xy.y * _up);
	return ray;
}


/* see: Equation (4) in
 *
 * Reinhard, E., Stark, M., Shirley, P., and Ferwerda, J. 2002.
 * Photographic tone reproduction for digital images.
 * ACM Trans. Graph. (Proc. SIGGRAPH 2002 special issue) 21, 3, 267–276.
 */

vec3 tonemap(vec3 v) {
    float L = dot(vec3(0.2126, 0.7152, 0.0722), v);
    return v * (1.0 + L / (L_white * L_white) ) / (1.0 + L);
}

void fragment() {

	// center on (0.0) ; make the y range from -1 to 1 and point upwards
	vec2 xy = (UV - vec2(0.5,0.5)) * 2.0;
	xy.y *= -1.0;

	COLOR = vec4(linear_to_sRGB(tonemap(sphereTraceRay(makeRay(xy)) * pow(2.0, exposure))), 1.0);
}
