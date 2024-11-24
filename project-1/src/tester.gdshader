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
// noise textures
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform sampler3D noise_3d_texture : filter_linear, repeat_enable;
uniform sampler2D normal_noise_texture : filter_linear, repeat_enable, hint_normal;
uniform sampler2D blue_noise_texture : filter_nearest, repeat_enable;
struct Ray {
	vec3 p;
	vec3 dir;
};
// tone mapping and sRGB conversion
// sRGB response curve. See: https://en.wikipedia.org/wiki/SRGB#Specification_of_the_transformation
float linearize( float c ) { return (c < 0.04045) ? (c / 12.92) : (pow( (c + 0.055) / 1.055, 2.4)); }
vec3 sRGB_to_linear( vec3 sRGB) { return vec3( linearize(sRGB.r), linearize(sRGB.g), linearize(sRGB.b)); }
float unlinearize(float f) { return (f < 0.0031308) ? (12.92 * f) : (1.055 * pow(f, 0.416666667) - 0.055); }
vec3 linear_to_sRGB( vec3 RGB) { return vec3( unlinearize(RGB.r), unlinearize(RGB.g), unlinearize(RGB.b)); }

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
		mat3(vec3(1.0,                0.0,                0.0),
			 vec3(0.0,    cos(_elevation),   -sin(_elevation)),
			 vec3(0.0,    sin(_elevation),    cos(_elevation))
		));
	mat3 rotateY = transpose(
		mat3(vec3(cos(_azimuth), 0.0, -sin(_azimuth)),
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
	return mix(mix(_horizonColor, _zenithColor, dir.y), _sunColor,
		smoothstep(_cosSunRadius*0.9999, _cosSunRadius, dot(dir,_sunDirection)));
}

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

vec3 shadeSpecular(vec3 albedo, vec3 point, vec3 normal, vec3 viewDir, float shininess) {
	vec3 r = reflect(-sunDirection, normal);
	// sun : Specular Phong reflection
	vec3 res = albedo * pow(max(0,(-dot(r, viewDir))), shininess);
	res += albedo * max(0.0, normal.y) * _zenithColor;
	res += albedo * vec3(0.1); // ambient
	// point can be used later for a simple shadow calculation
	return res;
}

vec3 groundColor(vec3 p) {
	vec3 quadrantMultiplier = vec3(0.2, 0.2, 0.2);
	if (p.x >= 0.0) { quadrantMultiplier.r = 1.0; }
	if (p.z >= 0.0) { quadrantMultiplier.g = 1.0; }
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
float sdBox( vec3 p, vec3 b ) {
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdCappedCylinder( vec3 p, float h, float r ) {
	vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdCappedCylinderOffset( vec3 p, float h, float r, vec2 offset ) {
	vec2 d = abs(vec2(distance(p.xz, offset),p.y)) - vec2(r,h);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdTorus( vec3 p, vec2 t ) {
	vec2 q = vec2(length(p.xz)-t.x,p.y);
	return length(q)-t.y;
}
float opOnion( in float sdf, in float thickness ) {
	return abs(sdf)-thickness;
}
float opSubtraction( float d1, float d2 ) {
	return max(-d1,d2);
}
float opUnion( float d1, float d2 ) {
	return min(d1,d2);
}
float opSmoothUnion( float d1, float d2, float k ) {
	float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) - k*h*(1.0-h);
}
vec3 opSymXZ(vec3 p) {
	p.xz = abs(p.xz);
	return p;
}
// end of SDF primitives and operations based on Inigo Quilez' code

vec4 blueNoiseAtID(vec2 id) {
	vec2 uv = id / 1024.0; // map one lantern to one pixel (1024 is noise map resolution)
	return texture(blue_noise_texture, uv);
}

const float gridSize = 7.0; // size of one tile

vec2 offset(vec2 noise) {
	return (noise * 2.0 - 1.0) * (gridSize * 0.5 - 0.75 + 0.15); // 0.75 is the radius of the lantern
}

float sdfSinglePaper(vec3 p) {
	vec3 offset = vec3(0,-1,0);
	p -= offset;

	float box = sdBox(p - vec3(0,4.0,0), vec3(2.0));
	float cylinder = sdCappedCylinder(p - vec3(0,1.5,0), 1.5, 0.75);
	float cylinder_boundary = opOnion(cylinder, 0.03);
	return opSubtraction(box, cylinder_boundary);
}

float sdfSingleMetal(vec3 p) {
	vec3 offset = vec3(0,-1,0);
	p -= offset;

	float torus1 = sdTorus(p, vec2(0.75, 0.05));
	float torus2 = sdTorus(p + vec3(0,-2.0,0), vec2(0.75, 0.05));
	float tori = opUnion(torus1, torus2);
	
	float cylindri = sdCappedCylinderOffset(opSymXZ(p + vec3(0,-1,0)), 1.03, 0.05, vec2(0.75 * 0.707));
	
	return opSmoothUnion(cylindri, tori, 0.1);
}

// https://iquilezles.org/articles/sdfrepetition/
float repeated( vec3 p3, int sdfIndex ) {
	vec2 p = p3.xz;
	vec2 id = round(p/gridSize);
	vec2  o = sign(p-gridSize*id); // neighbor offset direction

	float d = 1e20;
	for( int j=0; j<2; j++ )
	for( int i=0; i<2; i++ ) {
		vec2 rid = id + vec2(float(i),float(j))*o;
		vec2 r = p - gridSize*rid;
		vec4 blueNoise = blueNoiseAtID(rid);
		r += offset(blueNoise.xy);
		
		vec3 finalP = vec3(r.x, p3.y, r.y);
		float newD;
		switch (sdfIndex) {
			case 1: newD = sdfSinglePaper(finalP); break;
			case 2: newD = sdfSingleMetal(finalP); break;
			default: newD = opUnion(sdfSinglePaper(finalP), sdfSingleMetal(finalP)); break;
		}
		d = min(d, newD);
	}
	return d;
}

float sdf(vec3 p) {
	return repeated(p, 0);
}

vec3 gradient(vec3 p) {
	const vec3 dx = vec3(GRADIENT_DT, 0.0, 0.0);
	const vec3 dy = vec3(0.0, GRADIENT_DT, 0.0);
	const vec3 dz = vec3(0.0, 0.0, GRADIENT_DT);
	return vec3( (sdf(p + dx) - sdf(p - dx)) / (2.0 * GRADIENT_DT),
				 (sdf(p + dy) - sdf(p - dy)) / (2.0 * GRADIENT_DT),
		 		 (sdf(p + dz) - sdf(p - dz)) / (2.0 * GRADIENT_DT)
	);
}

vec2 calcCylindricalUVs(vec2 dir, vec3 p) {
	float longitude = atan(-dir.y, dir.x); // [-pi;pi]
	return vec2(
		(longitude / 3.141) * 0.5 + 0.5,
		(p.y * 0.5) + 0.5
	);
}

vec3 sphereTraceRay(Ray ray) {
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
		float frequency = 10.0;
		float thickness = 0.025;
		float bendStrength = 0.2;
		vec3 lightPos = vec3(0, -0.5, 0);
		float lightStrength = 3.0;
		float lightTransparencyStrength = 1.8;
		float metalShininess = 20.0;
		vec3 colorMetal = _colorB;
		
		vec2 id = round(p.xz/gridSize);
		vec4 blueNoise = blueNoiseAtID(id);
		vec2 gridPos = id * gridSize;
		vec2 lp2 = gridPos - offset(blueNoise.xy);
		vec3 localP = p - vec3(lp2.x, 0, lp2.y);

		vec3 normal = normalize(gradient(p));
		vec2 normal_plane = normalize(vec2(localP.x, localP.z));
		vec2 uv = calcCylindricalUVs(normal_plane, p);

		float noise = texture(noise_texture, uv * vec2(2,1)).x;
		//vec4 noise3d = texture(noise_3d_texture, p);
		//vec4 noise3d_1_5 = texture(noise_3d_texture, p * 1.5);
		
		// this is not how you would actually use a normal map
		// (to do it properly we would need a tangent and binormal)
		// but it looks fine like this
		vec3 normal_noise = texture(normal_noise_texture, uv * vec2(2,1)).xyz;
		normal_noise = normal_noise * 2.0 - 1.0;

		vec3 l = normalize(lightPos - localP);
		bool isMetal = repeated(p, 1) > repeated(p, 2);
		if (isMetal) {
			normal = normalize(
				normal + normal_noise * 0.13
			);
			colorMetal += (noise * 2.0 - 1.0) * 0.2;
			vec3 r = reflect(-l, normal);
			vec3 v = ray.dir;
			float s = pow(max(0,(-dot(r, v))), metalShininess);
			vec3 light = s * colorMetal * _colorA;
			return light + shadeSpecular(colorMetal,p,normal,ray.dir,metalShininess);
		}
		else {
			normal = normalize(
				normal + normal_noise * 0.35
			);
			
			lightStrength *= 1.0 - noise * 0.4;
			// make light flicker
			float flickerValue =
				  (cos( (TIME + blueNoise.x * 50.0) * 2.0 * PI) + 2.0) * 0.15
				+ (cos( (TIME + blueNoise.x * 40.0) * 3.0 * PI) + 1.0) * 0.1
				+ (cos( (TIME + blueNoise.x * 30.0) * 2.5 * PI) + 1.0) * 0.1;
			lightStrength *= mix(0.3, 0.8, flickerValue);
			
			float nDotL = dot(normal, l);
			float d = distance(lightPos, localP);
			float lighting = nDotL * lightStrength / (d*d);
			vec3 light = abs(lighting) * _colorA;
			vec3 shading = light + shade(vec3(1), p, normal) * 0.15;
			return shading * lightTransparencyStrength;
		}
	} else {
		return background(ray);
	}
}

Ray makeRay(vec2 xy) {
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
