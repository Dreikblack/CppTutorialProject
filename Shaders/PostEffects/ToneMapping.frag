#version 450
#extension GL_ARB_separate_shader_objects : enable

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

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = texelFetch(ColorBuffer, coord, 0);
    outColor.rgb = aces(outColor.rgb);
}