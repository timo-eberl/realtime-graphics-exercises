// hash functions and operations from
// Integer Hash21 by Inigo Quilez
// https://www.shadertoy.com/view/4tXyWN
// 
// The MIT License
// Copyright © 2017,2024 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 
// eventual modifications are limited to make them work in this code environment and/or cosmetic

uint hash21( uvec2 p ) {
	p *= uvec2(73333,7777);

	//p ^= (uvec2(3333777777)>>(p>>28));
	p ^= (uvec2(3333777777u)>>(p>>28u));

	uint n = p.x*p.y;

	//return n^(n>>15);
	return n^(n>>15u);
}

float hash( uvec2 p ) {
	// we only need the top 24 bits to be good really
	uint h = hash21( p );

	// straight to float, see https://iquilezles.org/articles/sfrand/
	// return uintBitsToFloat((h>>9)|0x3f800000u)-1.0;

	return float(h)*(1.0/float(0xffffffffU));
}
