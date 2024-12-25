#ifndef GAMMA_GLSL
#define GAMMA_GLSL

vec3 _linOut;
vec3 _bLess;
float _linOutf;
float _bLessf;

#ifdef USE_GAMMA
	//#define MANUAL_SRGB
	#define SRGB_FAST_APPROXIMATION
#endif

vec3 (in vec3 linear)
{
    #ifdef MANUAL_SRGB
	return pow(linear,vec3(1.0f/CameraGamma));
	#else
	return linear;
	#endif
}

float (in float srgbIn)
{
    #ifdef MANUAL_SRGB
    #ifdef SRGB_FAST_APPROXIMATION
    _linOutf = pow(srgbIn,(CameraGamma));
    #else //SRGB_FAST_APPROXIMATION
    _bLessf = step((0.04045),srgbIn);
    _linOutf = mix( srgbIn/(12.92), pow((srgbIn+(0.055))/(1.055),(2.4)), _bLessf );
    #endif //SRGB_FAST_APPROXIMATION
    return _linOutf;
	//return vec4(_linOut,srgbIn.w);;
    #else //MANUAL_SRGB
    return srgbIn;
    #endif //MANUAL_SRGB
}

vec3 (in vec3 srgbIn)
{
    #ifdef MANUAL_SRGB
    #ifdef SRGB_FAST_APPROXIMATION
    _linOut = pow(srgbIn.xyz,vec3(CameraGamma));
    #else //SRGB_FAST_APPROXIMATION
    _bLess = step(vec3(0.04045),srgbIn.xyz);
    _linOut = mix( srgbIn.xyz/vec3(12.92), pow((srgbIn.xyz+vec3(0.055))/vec3(1.055),vec3(2.4)), _bLess );
    #endif //SRGB_FAST_APPROXIMATION
    return _linOut;
	//return vec4(_linOut,srgbIn.w);;
    #else //MANUAL_SRGB
    return srgbIn;
    #endif //MANUAL_SRGB
}

#endif