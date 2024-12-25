#version 450
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Math/Math.glsl"
#include "../Khronos/tonemapping.glsl"

//Output
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform sampler2D ColorBuffer;
layout(binding = 1) uniform sampler2D AvgLuminanceBuffer;

/// Bleed RGB channels into each other so that bright colors saturate to white.
vec3 bleedChannels( vec3 color, float amount)
{
	// Squaring color makes the effect stronger at higher brightness.
	vec3 bleed = color * amount;
	
	// Mix each channel into the others.
	color.gb += bleed.r;
	color.rb += bleed.g;
	color.rg += bleed.b;
	
	return color;
}

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = sRGBToLinear(texelFetch(ColorBuffer, coord, 0));

	vec4 exposurecolor = (texelFetch(AvgLuminanceBuffer, ivec2(0), textureQueryLevels(AvgLuminanceBuffer) - 1));

	float avgLuminance = exposurecolor.r * 0.2125 + exposurecolor.g * 0.7154 + exposurecolor.b * 0.0721;	
	
	float irisadjustment = 1.0 / (avgLuminance * 4.0);
	irisadjustment = clamp(irisadjustment, 0.0, 5.0);
	outColor.rgb *= irisadjustment;

	//avgLuminance = outColor.r * 0.2125 + outColor.g * 0.7154 + outColor.b * 0.0721;
	//float bleach = clamp((avgLuminance - 0.5) / 0.5, 0.0, 1.0);
	//bleach *= bleach;
	//if (bleach > 0.0) outColor.rgb = bleedChannels(outColor.rgb, bleach * 0.1);

	outColor.rgb = linearTosRGB(outColor.rgb);
}
