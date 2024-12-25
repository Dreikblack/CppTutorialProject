#version 450

// This is Klepto2's much improved bloom shader. Big thanks to you!
// https://www.ultraengine.com/community/topic/66624-kl_effects-reworked-posteffects-for-ultraengine/

//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Math/Math.glsl"
#include "../Utilities/Dither.glsl"
#include "../Khronos/tonemapping.glsl"

#define UNIFORMSTARTINDEX 8
#include "../Base/PushConstants.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1, binding = 1) uniform sampler2D BloomBuffer;
layout(location = 3) uniform float Threshold = 0.5f;
layout(location = 5) uniform float Exposure = 1.0f;

void main()
{
    vec2 tc = gl_FragCoord.xy / textureSize(ColorBuffer, 0).xy;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);

    vec3 bloom = (textureLod(BloomBuffer, tc, 0).rgb);
    vec4 background = (texelFetch(ColorBuffer, coord, 0));

    //bloom = sRGBToLinear(bloom);
   // background = sRGBToLinear(background);

    float wt = 0.75f;

    float brightness = max(max(bloom.r, bloom.g), bloom.b);
    //if (brightness < sRGBToLinear(0.5f))
    if (brightness < 0.5f)
    {
        wt = wt * (brightness * 2.0f);
    }

    outColor = background;
    outColor.rgb = mix(outColor.rgb, bloom, wt);

    outColor.r = max(outColor.r, background.r);
    outColor.g = max(outColor.g, background.g);
    outColor.b = max(outColor.b, background.b);

    //outColor.rgb = linearTosRGB(outColor.rgb);

    //Dither final pass
    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        outColor.rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }
}