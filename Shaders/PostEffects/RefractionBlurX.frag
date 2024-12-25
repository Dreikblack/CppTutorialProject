#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

float overdrive = 0.5f;
float threshold = 0.9f;

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

#define EXTENT 1

vec4 Blur(in sampler2D tex, in vec2 texcoords, in int miplevel)
{
    vec2 texelsize = 2.0f / textureSize(tex, miplevel);
    vec4 c = vec4(0);
    float sum = 0.0f;
    vec4 samp;
    for (int n = 0; n < EXTENT * 2; ++n)
    {
        samp = textureLod(tex, texcoords + vec2(0.0f, float(n) - float(EXTENT) + 0.5f) * texelsize, miplevel - 1);
        float wt = 1.0f - (abs(float(n) - (float(EXTENT) - 0.5f)) / (float(EXTENT) - 0.5f));
        sum += wt;
        c += samp * wt;
    }
    return c / sum;
}

void main()
{
    outColor = Blur(texture2DSampler[PostEffectTextureID0], texCoords, PostEffectMipLevel);
}