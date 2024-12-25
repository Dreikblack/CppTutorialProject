#version 450
#extension GL_ARB_bindless_texture : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable

#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"

layout(location = 2) in vec4 texCoords;
layout(location = 5) flat in uint materialIndex;

void main()
{
	Material material = materials[materialIndex];
	uvec2 textureID = material.textureHandle[0];
	if (textureID != uvec2(0))
    {
        if (texture(sampler2D(textureID), texCoords.xy).a < 0.5f) discard;  
    }
}