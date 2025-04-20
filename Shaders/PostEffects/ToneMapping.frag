#version 450
#extension GL_ARB_separate_shader_objects : enable

#include "../Khronos/tonemapping.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

//Output
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform sampler2D ColorBuffer;

// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
vec3 aces(vec3 x) {
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
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = texelFetch(ColorBuffer, coord, 0);
    outColor.rgb = sRGBToLinear(outColor.rgb);
    outColor.rgb = aces(outColor.rgb);
    outColor.rgb = linearTosRGB(outColor.rgb);
}