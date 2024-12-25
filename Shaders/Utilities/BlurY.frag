#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

int EXTENTS = floatBitsToInt(PostEffectParameter0);
int READMIPLEVEL = floatBitsToInt(PostEffectParameter1);

vec4 Blur(in sampler2D tex, in vec2 texcoords, in int miplevel)
{
    vec2 texelsize = 1.0f / textureSize(tex, miplevel);
    vec4 c = vec4(0);
    float sum = 0.0f;
    vec4 samp;
    for (int n = 0; n < EXTENTS * 2; ++n)
    {
        samp = textureLod(tex, texcoords + vec2(float(n) - float(EXTENTS) + 0.5f, 0.0f) * texelsize, miplevel);
        //if (samp.r > 0.99f) continue;
        sum += 1.0f;
        c += samp;
    }
    if (sum == 0.0f) return vec4(1,0,0,0);
    return c / sum;
    //return min(c / sum, textureLod(tex, texcoords, 0.0f));
}

void main()
{
    //PostEffectMipLevel = 1;
    outColor = Blur(texture2DSampler[ PostEffectTextureID0 ], texCoords, READMIPLEVEL);
}