#ifndef _FASTSQRT
    #define _FASTSQRT

//Fast Sqrt increases framerate by about 3% with one point light
//#define USEFASTSQRT

#ifdef USEFASTSQRT

//https://www.shadertoy.com/view/wlGSRt
//https://www.shadertoy.com/view/wlyXRt
float sqrtFast(in float x)
{
	return uintBitsToFloat((floatBitsToUint(x) >> 1) + 0x1FC00000u);
	//float X = intBitsToFloat(     (floatBitsToInt(x) & 0xff000000) / 2 +(1 << 29) ); // Simplified
	//float  X0 = intBitsToFloat(      floatBitsToInt(x)               / 2 +(1 << 29) ), // ( less good )
	//float X = uintBitsToFloat( (floatBitsToUint(x) +  0x3F800000u ) / 2u ); // Even faster, see https://www.shadertoy.com/view/wlyXRt
	//X = ( X + x/(X) ) * 0.5f;
	//return X;
}

float lengthFast(in vec3 v)
{
	return sqrtFast(v.x * v.x + v.y * v.y + v.z * v.z);
}

//https://en.wikipedia.org/wiki/Fast_inverse_square_root#Worked_example
//https://www.shadertoy.com/view/wlyXRt
float inversesqrtFast(in float number)
{
	return uintBitsToFloat(0x7F000000u - floatBitsToUint(number));
	//uint conv = floatBitsToUint(number);
	//conv  = 0x5f3759df - (conv >> 1);
	//float f = uintBitsToFloat(conv);
	//f *= 1.5f - (number * 0.5f * f * f);
	//return f;
}

vec3 normalizeFast(in vec3 v)
{
	return v * inversesqrtFast(v.x * v.x + v.y * v.y + v.z * v.z);
}

#else

#define normalizeFast normalize
#define lengthFast length
#define sqrtFast sqrt
#define inversesqrtFast inversesqrt

#endif

#endif
