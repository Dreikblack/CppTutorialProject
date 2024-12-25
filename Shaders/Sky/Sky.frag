#version 450
#extension GL_ARB_bindless_texture : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable

#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/StorageBufferBindings.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Utilities/ReconstructPosition.glsl"

//Inputs
layout(location = 0) in vec3 texCoords;
layout(location = 1) in flat uint materialIndex;

//Outputs
layout(location = 0) out vec4 outColor[8];

void main()
{
	Material mtl = materials[materialIndex];

	if (mtl.textureHandle[TEXTURE_DIFFUSE] != uvec2(0))
	{
		outColor[0] = textureLod(samplerCube(mtl.textureHandle[TEXTURE_DIFFUSE]), texCoords, 0);
		outColor[0].a = 1.0f;

		vec4 fogcolor;
		vec2 fogrange, fogangle;
		if (ExtractCameraFogSettings(CameraID, fogcolor, fogrange, fogangle))
		{
			float slope = degrees(asin(texCoords.y / length(texCoords.xyz)));
			if (slope < fogangle.y)
			{
				float l = clamp(1.0f - ((slope - fogangle.x) / (fogangle.y - fogangle.x)), 0.0f, 1.0f) * fogcolor.a;
				outColor[0].rgb = outColor[0].rgb * (1.0f - l) + fogcolor.rgb * l;
			}
		}
	}
	else
	{
		outColor[0] = vec4(1,0,1,1);
	}

    int attachmentindex = 0;

	//Deferred normal
    ++attachmentindex;
    outColor[attachmentindex] = vec4(0,0,1,0);

	//Metallic roughness
    ++attachmentindex;
    outColor[attachmentindex] = vec4(0);

	//Albedo
    ++attachmentindex;
    outColor[attachmentindex] = vec4(0);

	//Z position
    ++attachmentindex;
    outColor[attachmentindex] = vec4(1,0,0,0);
}