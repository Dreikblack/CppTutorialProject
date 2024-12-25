#ifndef _LIGHTINFO
    #define _LIGHTINFO

#include "UniformBlocks.glsl"

//Matrix offsets
#define LIGHT_INFO_OFFSET (11 + 1)
#define LIGHT_SHADOW_RENDER_MATRIX_OFFSET (12 + 1)
#define PROBE_INFO_OFFSET (21 + 1)

//Light falloff mode
#define LIGHTFALLOFF_INVERSESQUARE 0
#define LIGHTFALLOFF_LINEAR 1

//Light types
#define LIGHT_DECAL 0
#define LIGHT_PROBE 1
#define LIGHT_SPOT 2
#define LIGHT_STRIP 3
#define LIGHT_BOX 4
#define LIGHT_POINT 5
#define LIGHT_DIRECTIONAL 6// this one always last

mat4 ExtractLightShadowRenderMatrix(in uint lightID)
{
    return entityMatrix[lightID + LIGHT_SHADOW_RENDER_MATRIX_OFFSET];
}

vec3 ExtractLightShadowRenderPosition(in uint lightID)
{
    return entityMatrix[lightID + LIGHT_SHADOW_RENDER_MATRIX_OFFSET][3].xyz;
}

void ExtractLightInfo(in uint lightID, out uvec2 shadowmap, out vec2 range, out vec2 coneangles, out vec2 shadowrange, out uint lightflags, out int shadowkernel, out float cascadedistance, out uint materialid)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	//shadowmaplayer = floatBitsToUint(lightinfo[2][0]);
	coneangles = lightinfo[0].zw;
	shadowkernel = floatBitsToInt(lightinfo[3][2]);
	lightflags = floatBitsToUint(lightinfo[3][3]);
	shadowmap.x = floatBitsToUint(lightinfo[2].x);
	shadowmap.y = floatBitsToUint(lightinfo[2].y);
	range = lightinfo[0].xy;
    shadowrange = lightinfo[2].zw;
	cascadedistance = lightinfo[1].z;
	materialid = floatBitsToUint(lightinfo[3].x);
}

void ExtractLightInfo(in uint lightID, out vec2 coneangles, out int shadowkernel, out uvec2 shadowmap)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	coneangles = vec2(lightinfo[0].zw);
	shadowkernel = floatBitsToInt(lightinfo[3][2]);
	shadowmap.x = floatBitsToUint(lightinfo[2].x);
	shadowmap.y = floatBitsToUint(lightinfo[2].y);
	//shadowmaplayer = floatBitsToUint(lightinfo[2][0]);
}

uint ExtractLightFlags(in uint lightID)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	return floatBitsToUint(lightinfo[3][3]);
}

mat4 ExtractProbeInfo(in uint lightID)
{
	return entityMatrix[lightID + PROBE_INFO_OFFSET];
}

#endif