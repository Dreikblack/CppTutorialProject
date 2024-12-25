#version 450

// This is Klepto2's much improved bloom shader. Big thanks to you!
// https://www.ultraengine.com/community/topic/66624-kl_effects-reworked-posteffects-for-ultraengine/

//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Math/Math.glsl"
#include "../Utilities/Dither.glsl"
#include "../Khronos/tonemapping.glsl"

#define UNIFORMSTARTINDEX 8
#include "../Base/PushConstants.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1, binding = 1) uniform sampler2DMS DepthBuffer;
layout(location = 3) uniform float Threshold = 0.5f;
layout(location = 4) uniform float SoftThreshold = 0.5f;


float Max3(float a, float b, float c)
{
    return max(max(a, b), c);
}

vec4 DownsampleBox13Tap(sampler2D tex, vec2 uv, vec2 texelSize)
{
    vec4 A = (texture(tex, uv + texelSize * vec2(-1.0, -1.0)));
    vec4 B = (texture(tex, uv + texelSize * vec2( 0.0, -1.0)));
    vec4 C = (texture(tex, uv + texelSize * vec2( 1.0, -1.0)));
    vec4 D = (texture(tex, uv + texelSize * vec2(-0.5, -0.5)));
    vec4 E = (texture(tex, uv + texelSize * vec2( 0.5, -0.5)));
    vec4 F = (texture(tex, uv + texelSize * vec2(-1.0,  0.0)));
    vec4 G = (texture(tex, uv                               ));
    vec4 H = (texture(tex, uv + texelSize * vec2( 1.0,  0.0)));
    vec4 I = (texture(tex, uv + texelSize * vec2(-0.5,  0.5)));
    vec4 J = (texture(tex, uv + texelSize * vec2( 0.5,  0.5)));
    vec4 K = (texture(tex, uv + texelSize * vec2(-1.0,  1.0)));
    vec4 L = (texture(tex, uv + texelSize * vec2( 0.0,  1.0)));
    vec4 M = (texture(tex, uv + texelSize * vec2( 1.0,  1.0)));

    vec2 div = (1.0 / 4.0) * vec2(0.5, 0.125);

    vec4 o = (D + E + I + J) * div.x;
    o += (A + B + G + F) * div.y;
    o += (B + C + H + G) * div.y;
    o += (F + G + L + K) * div.y;
    o += (G + H + M + L) * div.y;

    return o;
}

vec4 Prefilter (vec4 c) {
	float brightness = max(c.r, max(c.g, c.b));
	float knee = Threshold * SoftThreshold;
	float soft = brightness - Threshold + knee;
	soft = clamp(soft, 0, 2.0 * knee);
	soft = soft * soft / (4.0 * knee + 0.00001);
	float contribution = max(soft, brightness - Threshold);
	contribution /= max(brightness, 0.00001);
	return c * contribution;
}
	
void main()
{
    vec2 tc = gl_FragCoord.xy / vec2(DrawViewport.zw);
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);

    vec4 background = vec4(0.0); //(texelFetch(ColorBuffer, coord, 0));
	float z = texelFetch(DepthBuffer, ivec2(tc * BufferSize.xy* 2.0),0 ).r;

	background = DownsampleBox13Tap(ColorBuffer, tc, 1.0 / vec2(DrawViewport.zw));
	outColor = Prefilter(background);

    if (isnan(outColor.r) || isnan(outColor.g) || isnan(outColor.b) || isnan(outColor.a)) outColor = vec4(0,0,0,1);
}