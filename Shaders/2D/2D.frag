#version 460
#extension GL_ARB_bindless_texture : enable

// Inputs
layout(location = 1) uniform uvec2 texturehandle = uvec2(0);

#define UNIFORMSTARTINDEX 8

#include "../Base/PushConstants.glsl"

// Inputs
layout(location = 0) in vec4 color;
layout(location = 1) flat in vec3 emissioncolor;
layout(location = 2) in vec2 texcoords;

// Outputs
layout(location = 0) out vec4 outcolor;

void main()
{
    outcolor = color;

    if (texturehandle != uvec2(0))
    {
        outcolor *= texture(sampler2D(texturehandle), texcoords);
    }

    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
    {
        outcolor.rgb *= outcolor.a;
    }
}

