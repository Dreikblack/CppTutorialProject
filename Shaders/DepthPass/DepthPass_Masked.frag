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
#include "../Base/Fragment.glsl"

void main()
{
	Material material = materials[materialID];
	vec4 color = material.diffuseColor;
	uvec2 textureID = material.textureHandle[0];
	if (textureID != uvec2(0)) color.a *= texture(sampler2D(textureID), texcoords.xy).a;
    if (color.a < material.alphacutoff) discard;
}