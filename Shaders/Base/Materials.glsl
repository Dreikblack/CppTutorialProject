#ifndef _MATERIALS_GLSL
#define _MATERIALS_GLSL

#include "StorageBufferBindings.glsl"

#define MATERIAL_REFLECTIVE 1
#define MATERIAL_BLEND_ALPHA 2
#define MATERIAL_EXTRACTNORMALMAPZ 4
#define MATERIAL_BLEND_TRANSMISSION 8
#define MATERIAL_CAST_SHADOWS 16
#define MATERIAL_TWO_SIDED 32
#define MATERIAL_BACKFACELIGHTING 64
#define MATERIAL_IGNORENORMALS 128
#define MATERIAL_TESSELLATION 256

//Material texture slots
#define TEXTURE_DIFFUSE 0
#define TEXTURE_BASE 0
#define TEXTURE_NORMAL 1
#define TEXTURE_METALLICROUGHNESS 2
#define TEXTURE_SPECULARGLOSSINESS 2
#define TEXTURE_DISPLACEMENT 3
#define TEXTURE_EMISSION 4
#define TEXTURE_AMBIENTOCCLUSION 5

#define TEXTUREFLAGS_DIFFUSE 1
#define TEXTUREFLAGS_NORMAL 2
#define TEXTUREFLAGS_DISPLACEMENT 4
#define TEXTUREFLAGS_EMISSION 8
#define TEXTUREFLAGS_OCCLUSION 16

#define TEXTURE_TERRAINMASK 3
#define TEXTURE_TERRAINHEIGHT 4
#define TEXTURE_TERRAINNORMAL 5
#define TEXTURE_TERRAINMATERIAL 6
#define TEXTURE_TERRAINALPHA 7

#define TEXTURE_CLEARCOAT 7
#define TEXTURE_CLEARCOATROUGHNESS 8
#define TEXTURE_SHEEN 9
#define TEXTURE_SHEENROUGHNESS 10
#define TEXTURE_SHEENLUT 11
#define TEXTURE_CHARLIELUT 12
#define TEXTURE_DETAIL 13

struct Material
{
	vec4 diffuseColor;
	float metalness;
	float roughness;
	vec2 displacement;
	vec3 emissiveColor;
	uint flags;
	vec3 texturescroll;
	float alphacutoff;
	vec4 speculargloss;
	float saturation;
	float blendsmoothing;
	float thickness;
	uint occlusion;
	uvec2 textureHandle[16];
};
 
layout(std430, binding = STORAGE_BUFFER_MATERIALS) readonly buffer MaterialBlock { Material materials[]; };

// This function stays because it requires a bit of calculations
vec3 GetMaterialTextureOffset(in Material mtl, in float time)
{
	return -mtl.texturescroll.xyz * (time / 1000.0f);
}

//--------------------------------------------------------------------------------
// DEPRECATED - I left these in for convenience but they should be removed from your code
//--------------------------------------------------------------------------------

uint GetMaterialFlags(in Material material)
{
	return material.flags;
}

uvec2 GetMaterialTextureHandle(in Material material, in int n)
{
	return material.textureHandle[n];
}

vec2 ExtractMaterialDisplacement(in Material material)
{
	return material.displacement;
}

float ExtractMaterialAlphaCutoff(in Material material)
{
	return material.alphacutoff;
}

//--------------------------------------------------------------------------------


#endif
