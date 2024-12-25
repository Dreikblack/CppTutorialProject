#version 450

// Uniforms
layout(binding = 0) uniform sampler2D ColorBuffer;
layout(location = 0) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    vec2 coord = gl_FragCoord.xy / vec2(DrawViewport.z, DrawViewport.w);
    vec4 c = textureLod(ColorBuffer, coord, 0);
    outColor.rgb = vec3(c.r * 0.2126f + c.g * 0.7152f + c.b * 0.0722f);
    outColor.a = c.a;
}