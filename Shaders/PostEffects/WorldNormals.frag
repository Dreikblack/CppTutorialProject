#version 450

#include "../Base/CameraInfo.glsl"

// Uniforms
layout(binding = 0) uniform sampler2DMS NormalBuffer;
layout(binding = 1) uniform sampler2DMS DepthBuffer;
//layout(location = 0) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{   
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    vec4 c = vec4(0);
    int count = textureSamples(NormalBuffer);
    for (int n = 0; n < count; ++n)
    {
        if (texelFetch(DepthBuffer, coord, n).r < 1.0f)
        {
            c += texelFetch(NormalBuffer, coord, n);
        }
    }
    outColor = c / float(count);
    //no don't do this...
    //outColor.rgb = outColor.rgb * outColor.a + vec3(0,0,1) * (1.0f - outColor.a);
    outColor.xyz = outColor.xyz * 0.5f + 0.5f;
}