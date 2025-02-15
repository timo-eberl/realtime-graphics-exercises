// SDF primitives ============================================================
//
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

float sdCylinder( vec3 p, vec3 c ) {
	return length(p.xz-c.xy)-c.z;
}

float sdCappedCylinder( vec3 p, float h, float r ) {
	vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// torus that faces the y direction
float sdTorus( vec3 p, vec2 t ) {
	vec2 q = vec2(length(p.xz)-t.x,p.y);
	return length(q)-t.y;
}

vec3 opElongatePos( in vec3 p, in vec3 h ) {
	return p - clamp( p, -h, h );
}

// torus that faces the z direction
float sdTorusZ( vec3 p, vec2 t ) {
	vec2 q = vec2(length(p.xy)-t.x,p.z);
	return length(q)-t.y;
}

float sdPlane( vec3 p, vec3 n, float h ) {
	// n must be normalized
	return dot(p,n) + h;
}

float opUnion( float d1, float d2 ) {
	return min(d1,d2);
}
float opSubtraction( float d1, float d2 ) {
	return max(-d1,d2);
}
float opIntersection( float d1, float d2 ) {
	return max(d1,d2);
}
float opXor(float d1, float d2 ) {
	return max(min(d1,d2),-max(d1,d2));
}

float opSmoothUnion( float d1, float d2, float k ) {
	float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) - k*h*(1.0-h);
}
