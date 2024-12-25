#include "../Utilities/ISO646.glsl"

#define USERFUNCTION

void UserFunction(in uint entityID, inout vec4 position, inout vec3 normal, inout vec4 texCoords, in Material material)
{
	int terrainID = ExtractEntitySkeletonID(entityID);

	int textureID = GetMaterialTextureHandle(material, 6);
	if (textureID != -1)
	{
		int alphatexID = GetMaterialTextureHandle(material, 7);
		vec2 imagesize = textureSize(texture2DUIntegerSampler[textureID],0).xy;
		vec2 alphapixelsize = 0.5 / imagesize;
		vec2 imagepixelsize = 1.0 / imagesize;
		vec2 tilef = texCoords.xy * imagesize;
		vec2 tile = floor(tilef);
		vec2 rem = (tilef - tile);
		vec2 acoords = tile * imagepixelsize + alphapixelsize * 0.5 + rem * alphapixelsize;	
		vec4 textureAlpha = texture(texture2DSampler[alphatexID],acoords.xy);
		float terraindisplacement = 0.0;
		Material submtl;
		ivec2 tilecoord;
		tilecoord.x = int(texCoords.x * float(imagesize.x));
		tilecoord.y = int(texCoords.y * float(imagesize.y));
		uvec4 materialIDs = texelFetch(texture2DUIntegerSampler[textureID], tilecoord, 0);
		vec2 terrcoords = texCoords.xy * 32.0f;//* terrainScale.xz;
		for (int channel = 0; channel < 4; ++channel)
		{
			if (materialIDs[channel] == 0 or textureAlpha[channel] == 0.0f) break;
			int submtlID = ExtractTerrainLayerInfo(terrainID, materialIDs[channel]);
			if (submtlID == -1) continue;
			submtl = materials[submtlID];
			uint mtlflags = submtl.flags;//GetMaterialFlags(submtl);
			if ((mtlflags & MATERIAL_TESSELLATION) == 0) continue;
			continue;
			int subtex = GetMaterialTextureHandle(submtl, TEXTURE_DISPLACEMENT);
			if (subtex == -1) continue;

			float maxDisplacement = material.displacement.x;
			float offset = material.displacement.y;
			
			terraindisplacement = offset + maxDisplacement * texture(texture2DSampler[subtex], terrcoords).r * textureAlpha[channel];
		}
		position.xyz += normalize(normal) * terraindisplacement * 10.0f;
	}
}