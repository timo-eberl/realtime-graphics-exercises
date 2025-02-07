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

float sdPlane( vec3 p, vec3 n, float h ) {
	// n must be normalized
	return dot(p,n) + h;
}

float opUnion( float d1, float d2 ) {
	return min(d1,d2);
}

float opSmoothUnion( float d1, float d2, float k ) {
	float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
	return mix( d2, d1, h ) - k*h*(1.0-h);
}
