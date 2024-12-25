#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

layout(push_constant) uniform PostEffectParameters {
    int textureID[16];
    float params[16];
} pushconstants;

#include "../Base/TextureArrays.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 color;

void main()
{
    const float blend = 0.5f;
    vec4 c0 = textureLod(texture2DSampler[pushconstants.textureID[0]], texCoords, 0);
    vec4 c1 = textureLod(texture2DSampler[pushconstants.textureID[1]], texCoords, 0);
    color = c0;// * (1.0f - blend) + c1 * blend;
}
