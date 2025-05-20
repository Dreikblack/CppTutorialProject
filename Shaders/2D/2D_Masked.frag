#version 460
#extension GL_ARB_bindless_texture : enable

// Inputs
layout(location = 0) in vec4 color;
layout(location = 1) flat in vec3 emissioncolor;
layout(location = 2) in flat uvec4 cliprect;

// Outputs
layout(location = 0) out vec4 outcolor;

void main()
{
    outcolor = vec4(1,1,1,1);
}

