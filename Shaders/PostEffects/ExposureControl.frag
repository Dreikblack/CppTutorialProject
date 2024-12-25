#version 450
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

//Output
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform sampler2D AvgLuminanceBuffer;

void main()
{
    outColor = texelFetch(AvgLuminanceBuffer, ivec2(0), textureQueryLevels(AvgLuminanceBuffer) - 1);

    // Prevent runaway brightness
    outColor.r = min(4.0f, outColor.r);
    outColor.g = min(4.0f, outColor.g);
    outColor.b = min(4.0f, outColor.b);

	outColor.a = 0.05;
}