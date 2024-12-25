#ifndef _MATH
    #define _MATH

int getMajorAxis(in vec3 vn)
{
	vec3 v = abs(vn);
	/*if (v.x > v.y)
	{
		if (v.x > v.z)
		{
			return 0;
		}
		else
		{
			return 2;
		}
	}
	else
	{
		if (v.y > v.z)
		{
			return 1;
		}
		else
		{
			return 2;
		}
	}*/
	return v.y > v.x ? ( v.z > v.y ? 2 : 1 ) : ( v.z > v.x ? 2 : 0 );
}

vec3 normalizeFast(in vec3 n)
{
	float ls = dot(n, n);
	if (abs(1.0f - ls) > 0.01f) n *= inversesqrt(ls);
	return n;
}

float random(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

uvec2 unpackUshort2x16(in uint i)
{
	return uvec2(i & 0x0000FFFF, (i & 0xFFFF0000) >> 16);
}

float lengthSquared(in vec3 v)
{
	return dot(v,v);
}

float inverseLength(in vec3 v)
{
	return inversesqrt(dot(v,v));
}

vec4 mixColors(in vec4 c0, in vec4 c1, in float m)
{
	vec4 r;
	float sumalpha = c0.a + c1.a;
	float oneoversumalpha;
	if (sumalpha > 0.0f)
	{
		oneoversumalpha = 1.0f / (c0.a + c1.a);
	}
	else
	{
		oneoversumalpha = 0.0f;
	}
	r.rgb = c0.rgb * c0.a * oneoversumalpha * (1.0f - m) + c1.rgb * c1.a * oneoversumalpha * m;
    r.a = c0.a * (1.0f - m) + c1.a * m;
	return r;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 HSLToRGB( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0f+vec3(0.0f,4.0f,2.0f),6.0f)-3.0f)-1.0f, 0.0f, 1.0f );
    return c.z + c.y * (rgb-0.5f)*(1.0f-abs(2.0f*c.z-1.0f));
}

vec3 RGBToHSL( in vec3 c ){
  float h = 0.0;
	float s = 0.0;
	float l = 0.0;
	float r = c.r;
	float g = c.g;
	float b = c.b;
	float cMin = min( r, min( g, b ) );
	float cMax = max( r, max( g, b ) );

	l = ( cMax + cMin ) / 2.0;
	if ( cMax > cMin ) {
		float cDelta = cMax - cMin;
        
        //s = l < .05 ? cDelta / ( cMax + cMin ) : cDelta / ( 2.0 - ( cMax + cMin ) ); Original
		s = l < .0 ? cDelta / ( cMax + cMin ) : cDelta / ( 2.0 - ( cMax + cMin ) );
        
		if ( r == cMax ) {
			h = ( g - b ) / cDelta;
		} else if ( g == cMax ) {
			h = 2.0 + ( b - r ) / cDelta;
		} else {
			h = 4.0 + ( r - g ) / cDelta;
		}

		if ( h < 0.0) {
			h += 6.0;
		}
		h = h / 6.0;
	}
	return vec3( h, s, l );
}

#endif