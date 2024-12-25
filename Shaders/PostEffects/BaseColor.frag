#version 450

// Uniforms
layout(binding = 0) uniform sampler2DMS ColorBuffer;
layout(location = 0) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    vec4 c = vec4(0);
    int count = textureSamples(ColorBuffer);
    for (int n = 0; n < count; ++n)
    {
        c += texelFetch(ColorBuffer, coord, n);
    }
    outColor = c / float(count);
}