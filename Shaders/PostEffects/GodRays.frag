#version 450
//#extension GL_EXT_multiview : enable

#define UNIFORMSTARTINDEX 4

#include "../Base/EntityInfo.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/Lighting.glsl"
#include "../Utilities/ReconstructPosition.glsl"

#define RAYSAMPLES 64
#define NOISEAMOUNT 1.0

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1) uniform float Exposure = 0.25f;
layout(location = 2) uniform float MaxEffect = 0.25f;

// Outputs
layout(location = 0) out vec4 fragData0;

void main()
{
    vec2 buffersize = vec2(DrawViewport.z, DrawViewport.w);
    vec2 texcoord = vec2(gl_FragCoord.xy/buffersize);
    float maxraylength = 0.8;
    float maxlight = 8.0f;
    //vec4 scene = itexture(ColorBuffer, texcoord);

    mat4 lightmatrix;
    vec4 elightcolor = vec4(0.0f);
    int lightlistpos = int(GetGlobalLightsReadPosition());
    uint countlights = ReadLightGridValue(uint(lightlistpos));
    if (countlights > 0)
    {
        for (uint n = 0; n < countlights; ++n)
        {
            uint flags;
            ++lightlistpos;
            uint lightIndex = ReadLightGridValue(uint(lightlistpos));
            ExtractEntityInfo(lightIndex, lightmatrix, elightcolor, flags);
            break;
        }
    }
    if (elightcolor == vec4(0.0f))
    {
        fragData0 = vec4(0);
        //fragData0 = scene;
        return;
    }
    vec3 lightvector = lightmatrix[2].xyz;
    vec3 lightcolor = elightcolor.rgb;
    vec3 lightposition = CameraPosition - lightvector * 1000.0f;

    //lightvector = (CameraMatrix * vec4(lightvector, 1.0f)).xyz;
    vec3 glightvector = lightvector;
    lightvector = CameraNormalMatrix * lightvector;
    lightposition = WorldPositionToScreenCoord(lightposition);
	
	vec3 screenlightcoord = lightposition;
	vec2 deltaTexCoord = ( screenlightcoord.xy - texcoord );
	
	deltaTexCoord *= sign(lightposition.z);

	float length = length( deltaTexCoord );
	deltaTexCoord /= length;
	length = min(length, maxraylength);
	deltaTexCoord *= length;

	vec2 godraycoord = texcoord;// make a modifiable variable	
	
	float d;
	
	if ((texcoord.x + deltaTexCoord.x - 1.0) > 0.0) {
		d = (1.0 - godraycoord.x)/deltaTexCoord.x;
		deltaTexCoord *= d;	
	}
	if ((texcoord.y + deltaTexCoord.y - 1.0) > 0.0) {
		d = (1.0 - godraycoord.y)/deltaTexCoord.y;
		deltaTexCoord *= d;
	}	
	if ((texcoord.x + deltaTexCoord.x) < 0.0) {
		d = godraycoord.x/-deltaTexCoord.x;
		deltaTexCoord *= d;
	}
	if ((texcoord.y + deltaTexCoord.y)<0.0) {
		d = godraycoord.y/-deltaTexCoord.y;
		deltaTexCoord *= d;
	}
	
	deltaTexCoord /= RAYSAMPLES;
	
	float illuminationDecay = 1.0;
	
	vec4 sample_;
	float weight = 1.0;
	float decay = 1.0;
	
	float b;
	float godray = 0.0;
	float avg=0.0;
	
	float ok=0.0;
	
	vec2 dc;
	float dd;
	float randomnoise;
	
	randomnoise = 1.0 - NOISEAMOUNT * 0.5 + NOISEAMOUNT * rand(gl_FragCoord.xy * lightvector.xy);
	godraycoord += deltaTexCoord * randomnoise;
	
	float aspect = buffersize.x / buffersize.y;
	
    int count = 0;;
	for (int i = 0; i < RAYSAMPLES; i++ )
	{
        ++count;
		godraycoord += deltaTexCoord;
		godray += illuminationDecay * 0.5*(textureLod( ColorBuffer, godraycoord, 0).x);
		illuminationDecay *= decay;
		
        //if (godray >= maxlight) break;

		//dc=godraycoord-screenlightcoord.xy;
		//dd=sqrt(dc.x*dc.x+dc.y*dc.y);
		//dd=1.0-clamp(0.05-dd,0.0,1.0);
		//ok=1.0;
		//ok=max(ok,dd);
	}
	godray /= float(count);
	godray *= Exposure;
	
	//Darken the ray if it is in the foreground and camera faces away from light source
	//Enable the depth check if you want rays to appear when facing away from the camera.
	//However, due to the reduced size buffer, this will cause jaggies to appear along the skyline
	//so I commented it out.  :(
	//if (depth<1.0) {	
        vec3 eyevec = CameraNormalMatrix[2].xyz;
    	godray = godray * max((-dot(eyevec, glightvector) + 1.0f) * 0.5f, 0.0f);
	//}
	
	godray = clamp(godray, 0.0f, MaxEffect);
	
	//fragData0 = scene;
    //fragData0.rgb += lightcolor * godray;
    fragData0.rgb = lightcolor * godray;
    fragData0.a = 1.0f;
}