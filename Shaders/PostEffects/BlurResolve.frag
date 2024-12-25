#version 450

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    vec2 texcoord = gl_FragCoord.xy / vec2(DrawViewport.z, DrawViewport.w);
    outColor = textureLod(ColorBuffer, texcoord, 0);
}