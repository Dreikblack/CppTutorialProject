#version 450

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D CopyBuffer;
layout(location = 1) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / DrawViewport.zw;
	outColor = texture(CopyBuffer,uv);
}