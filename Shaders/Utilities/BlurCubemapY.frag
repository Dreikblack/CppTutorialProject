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

vec4 Blur(in sampler2DArray tex, in vec3 texcoords, in int miplevel)
{
    vec3 texelsize = vec3(vec2(1.0f / textureSize(tex, miplevel) ), 1.0f);
    vec4 c = vec4(0);
    float sum = 0.0f;
    vec4 samp;
    for (int n = 0; n < computeparams2.x * 2; ++n)
    {
        samp = textureLod(tex, texcoords + vec3(float(n) - float(computeparams2.x) + 0.5f, 0.0f, 0.0f) * texelsize, 0.0f);
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
    outColor = Blur(textureCube2DSampler[PostEffectTexture0], vec3(texCoords, PassIndex), 0);
}