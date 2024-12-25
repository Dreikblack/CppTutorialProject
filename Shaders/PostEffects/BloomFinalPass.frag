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
layout(location = 1, binding = 1) uniform sampler2DMS DepthBuffer;
layout(location = 2, binding = 2) uniform sampler2D BloomBuffer;
layout(location = 3) uniform float BloomEffect = 0.5f;

// 9-tap bilinear upsampler (tent filter)
vec4 UpsampleTent(sampler2D tex, vec2 uv, vec2 texelSize, vec4 sampleScale)
{
    vec4 d = texelSize.xyxy * vec4(1.0, 1.0, -1.0, 0.0) * sampleScale;

    vec4 s;
    s =  (texture(tex, uv - d.xy));
    s += (texture(tex, uv - d.wy)) * 2.0;
    s += (texture(tex, uv - d.zy));
                                 
    s += (texture(tex, uv + d.zw)) * 2.0;
    s += (texture(tex, uv       )) * 4.0;
    s += (texture(tex, uv + d.xw)) * 2.0;
                                 
    s += (texture(tex, uv + d.zy));
    s += (texture(tex, uv + d.wy)) * 2.0;
    s += (texture(tex, uv + d.xy));

    return s * (1.0 / 16.0);
}

// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
vec3 aces(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float aces(float x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 PBRNeutralToneMapping( vec3 color ) {
  const float startCompression = 0.8 - 0.04;
  const float desaturation = 0.15;

  float x = min(color.r, min(color.g, color.b));
  float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
  color -= offset;

  float peak = max(color.r, max(color.g, color.b));
  if (peak < startCompression) return color;

  const float d = 1. - startCompression;
  float newPeak = 1. - d * d / (peak + d - startCompression);
  color *= newPeak / peak;

  float g = 1. - 1. / (desaturation * (peak - newPeak) + 1.);
  return mix(color, newPeak * vec3(1, 1, 1), g);
}

void main()
{
    vec2 tc = gl_FragCoord.xy / textureSize(ColorBuffer, 0).xy;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    vec2 ts = vec2(1.0f) / textureSize(BloomBuffer, 0).xy;

    vec4 bloom = sRGBToLinear(UpsampleTent(BloomBuffer, tc, ts, vec4(1))); 
    vec4 background = sRGBToLinear(texelFetch(ColorBuffer, coord, 0));
    //bloom.rgb = PBRNeutralToneMapping(bloom.rgb);

    outColor = (bloom * BloomEffect + background);
    outColor.rgb = linearTosRGB(outColor.rgb);
    //outColor.rgb = aces(outColor.rgb);

   
    //outColor = bloom;
    //Dither final pass
    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        outColor.rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }
}