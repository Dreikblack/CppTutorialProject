#version 460
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

layout(binding = 0) uniform sampler2DMS DepthBuffer;
layout(binding = 1) uniform sampler2DMS NormalBuffer;
layout(binding = 2) uniform sampler2D ColorBuffer;

#define UNIFORMSTARTINDEX 1

#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/ReconstructPosition.frag"
#include "../Utilities/DepthFunctions.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

layout(location = 0) uniform int Samples = 16;

#define INTENSITY 35.0f
#define MAXEFFECT 0.667f
#define SCALE 1.25f * 16.0f
#define BIAS 0.05 * 4.0
#define SAMPLE_RAD 0.25f
#define MAX_DISTANCE 10.0

#define MOD3 vec3(.1031,.11369,.13787)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 getPosition(vec2 uv, int samp)
{
	float z = texelFetch(DepthBuffer, ivec2(uv.x * DrawViewport.z, uv.y * DrawViewport.w) * 2, samp).r;
	return ScreenCoordToWorldPosition(vec3(uv, z));
}

float doAmbientOcclusion(in vec2 tcoord,in vec2 uv, in vec3 p, in vec3 cnorm, int samp)
{
    if (tcoord.x + uv.x < 0.0f || tcoord.x + uv.x > 1.0f || tcoord.y + uv.y < 0.0f || tcoord.y + uv.y > 1.0f) return 0.0f;
    vec3 diff = getPosition(tcoord + uv, samp) - p;
    float l = length(diff);
    vec3 v = diff/l;
    float d = l*SCALE;
    float ao = max(0.0,dot(cnorm,v)-BIAS)*(1.0/(1.0+d));

#ifdef MAX_DISTANCE
    ao *= smoothstep(MAX_DISTANCE,MAX_DISTANCE * 0.5, l);
#endif
    return ao;
}

float spiralAO(vec2 uv, vec3 p, vec3 n, float rad, int samp, int aosamples)
{
    float goldenAngle = 2.4;
    float ao = 0.;
    float inv = 1. / float(aosamples);
    float radius = 0.;

    float rotatePhase = hash12( uv * 100.0f + float(16 * samp + 1) ) * 6.28;
    float rStep = inv * rad;
    vec2 spiralUV;

    for (int i = 0; i < aosamples; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radius += rStep;
        ao += doAmbientOcclusion(uv, spiralUV * radius, p, n, samp);
        rotatePhase += goldenAngle;
    }
    ao *= inv;
    return ao;
}

void main()
{
	vec2 uv = gl_FragCoord.xy / BufferSize;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y) * 2;
    int count = textureSamples(DepthBuffer);
    vec4 subsample;
    outColor = vec4(0.0f);
    float ao = 0.0f, rad, sumao = 0.0f;
    
    float z = texelFetch(DepthBuffer, coord, 0).r;
    if (z < 1.0f)
    {
        vec3 p = ScreenCoordToWorldPosition(vec3(gl_FragCoord.xy / BufferSize, z));
        vec3 n = texelFetch(NormalBuffer, coord, 0).rgb;

        //z = DepthToPosition(z, CameraRange) * 0.02f;

        rad = SAMPLE_RAD;// / z;//max(10.0f, z);
        ao = spiralAO(uv, p, n, rad, 0, Samples);
        ao = clamp(ao * INTENSITY, 0.0f, 1.0f);
    }

    ao = max(ao - 0.1f, 0.0f);
    ao = 1.0 - clamp(ao, 0.0f, MAXEFFECT);

    outColor = vec4(ao);
}