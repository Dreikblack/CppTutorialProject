#version 450
#ifdef GL_GOOGLE_include_directive
    #extension GL_GOOGLE_include_directive : enable
#endif
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable
//#extension GL_ARB_bindless_texture : enable

#include "../Base/Limits.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/Fragment.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "TerrainInfo.glsl"

layout(binding = TEXTURE_TERRAINMASK) uniform sampler2D terrainmaskmap;

void main()
{
    Material material = materials[materialID];
    if (material.textureHandle[0] != uvec2(0))
	{
       if (texture(terrainmaskmap, texcoords.xy).r > 0.0f) discard;
    }
}