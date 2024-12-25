#version 450

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1, binding = 1) uniform sampler2D GodRays;
layout(location = 2) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = texelFetch(ColorBuffer, coord, gl_SampleID);
    outColor.rgb += textureLod(GodRays, gl_FragCoord.xy / vec2(DrawViewport.z, DrawViewport.w), 0).rgb;
}