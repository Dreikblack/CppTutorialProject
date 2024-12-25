#version 450

// This is Klepto2's much improved bloom shader. Big thanks to you!
// https://www.ultraengine.com/community/topic/66624-kl_effects-reworked-posteffects-for-ultraengine/

#extension GL_ARB_separate_shader_objects : enable

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1) uniform ivec4 DrawViewport;


vec4 DownsampleBox13Tap(sampler2D tex, vec2 uv, vec2 texelSize)
{
    vec4 A = texture(tex, uv + texelSize * vec2(-1.0, -1.0));
    vec4 B = texture(tex, uv + texelSize * vec2( 0.0, -1.0));
    vec4 C = texture(tex, uv + texelSize * vec2( 1.0, -1.0));
    vec4 D = texture(tex, uv + texelSize * vec2(-0.5, -0.5));
    vec4 E = texture(tex, uv + texelSize * vec2( 0.5, -0.5));
    vec4 F = texture(tex, uv + texelSize * vec2(-1.0,  0.0));
    vec4 G = texture(tex, uv                               );
    vec4 H = texture(tex, uv + texelSize * vec2( 1.0,  0.0));
    vec4 I = texture(tex, uv + texelSize * vec2(-0.5,  0.5));
    vec4 J = texture(tex, uv + texelSize * vec2( 0.5,  0.5));
    vec4 K = texture(tex, uv + texelSize * vec2(-1.0,  1.0));
    vec4 L = texture(tex, uv + texelSize * vec2( 0.0,  1.0));
    vec4 M = texture(tex, uv + texelSize * vec2( 1.0,  1.0));

    vec2 div = (1.0 / 4.0) * vec2(0.5, 0.125);

    vec4 o = (D + E + I + J) * div.x;
    o += (A + B + G + F) * div.y;
    o += (B + C + H + G) * div.y;
    o += (F + G + L + K) * div.y;
    o += (G + H + M + L) * div.y;

    return o;
}

void main()
{
    vec2 tc = gl_FragCoord.xy / vec2(DrawViewport.zw);
    vec2 ts = 1.0f / vec2(DrawViewport.zw);

    outColor = DownsampleBox13Tap(ColorBuffer, tc, ts);
    outColor.a = 1.0;
}