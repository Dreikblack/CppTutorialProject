#version 450

// This is Klepto2's much improved bloom shader. Big thanks to you!
// https://www.ultraengine.com/community/topic/66624-kl_effects-reworked-posteffects-for-ultraengine/

#extension GL_ARB_separate_shader_objects : enable

#include "../Math/Math.glsl"
#include "../Utilities/Dither.glsl"
#include "../Khronos/tonemapping.glsl"
//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D DownBuffer;
layout(location = 1, binding = 1) uniform sampler2D AddBuffer;
layout(location = 2) uniform ivec4 DrawViewport;


// 9-tap bilinear upsampler (tent filter)
vec4 UpsampleTent(sampler2D tex, vec2 uv, vec2 texelSize, vec4 sampleScale)
{
    vec4 d = texelSize.xyxy * vec4(1.0, 1.0, -1.0, 0.0) * sampleScale;

    vec4 s;
    s =  (texture(tex, uv - d.xy));
    s += (texture(tex, uv - d.wy)) * 2.0;
    s += (texture(tex, uv - d.zy));
         
    s += (texture(tex, uv + d.zw)) * 2.0;
    s += (texture(tex, uv       )) * 4.0;
    s += (texture(tex, uv + d.xw)) * 2.0;
         
    s += (texture(tex, uv + d.zy));
    s += (texture(tex, uv + d.wy)) * 2.0;
    s += (texture(tex, uv + d.xy));

    return s * (1.0 / 16.0);
}

void main()
{
    vec2 tc = vec2(gl_FragCoord.x / float(DrawViewport.z), gl_FragCoord.y / float(DrawViewport.w));
    vec2 ts = vec2(1.0f) / vec2(DrawViewport.zw);//textureSize(DownBuffer, 0).xy;

    outColor = (UpsampleTent(DownBuffer, tc, ts, vec4(1)));
    outColor += (texture(AddBuffer,tc));
    outColor.rgb = (outColor.rgb);
}