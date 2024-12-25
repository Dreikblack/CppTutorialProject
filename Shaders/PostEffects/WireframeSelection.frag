#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable

#include "../Base/PushConstants.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Utilities/Dither.glsl"

layout(location = 0) in vec2 texCoords;
layout(location = 1, binding = 0) sampler2DMS DepthBuffer;
layout(location = 0) out vec4 outColor;

const vec4 SelectionColor = vec4(1,1,1,1);

void main()
{
    //outColor = SelectionColor;
    //outColor.a = 0.0f;
    
    outColor = vec4(1,0,0,1);

    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    float depth = texelFetch(DepthBuffer, coord, gl_SampleID).r;

    if (depth < 1.0f) outColor = SelectionColor;
}