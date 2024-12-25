#version 450
//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable

#define UNIFORMSTARTINDEX 8

#include "../Base/CameraInfo.glsl"
#include "../Math/Math.glsl"
#include "../Utilities/Dither.glsl"
#include "../Utilities/DepthFunctions.glsl"
#include "../Base/PushConstants.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1, binding = 1) uniform sampler2DMS DepthBuffer;
layout(location = 2, binding = 2) uniform sampler2D BlurBuffer;
layout(location = 3) uniform vec2 FadeIn = vec2(0, 3);
layout(location = 4) uniform vec2 FadeOut = vec2(7, 20);

void main()
{
    vec2 tc = gl_FragCoord.xy / textureSize(ColorBuffer, 0).xy;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);

    vec4 blur = textureLod(BlurBuffer, tc, 0);

    vec4 background = texelFetch(ColorBuffer, coord, gl_SampleID);

    float z = texelFetch(DepthBuffer, coord, gl_SampleID).r;
    z = DepthToPosition(z, CameraRange);

    float dof = 0.0f;
    if (z < FadeIn.y)
    {
        dof = 1.0f - ((z - FadeIn.x) / (FadeIn.y - FadeIn.x));
    }
    else if (z > FadeOut.x)
    {
        dof = (z - FadeOut.x) / (FadeOut.y - FadeOut.x);
    }
    dof = clamp(dof, 0.0f, 1.0f);

    outColor = background;
    if (dof > 0.0f)
    {
        outColor = mix(background, blur, dof);        
    }

    //outColor = vec4(z / 4.0f);

    //Dither final pass
    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        outColor.rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }
}