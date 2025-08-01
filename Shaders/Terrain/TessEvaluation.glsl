uvec2 textureID;

void UserFunction(in uint entityID, inout vec4 position, inout vec3 normal, inout vec4 texCoords, in Material material)
{
	int terrainID = ExtractEntitySkeletonID(uint(entityID));
	textureID = material.textureHandle[TEXTURE_TERRAINMATERIAL];

	if (textureID != uvec2(0))
	{
		uvec2 alphatexID = GetMaterialTextureHandle(material, TEXTURE_TERRAINALPHA);
		vec2 imagesize = textureSize(usampler2D(textureID),0).xy;
		//vec2 imagesize = textureSize(texture2DUIntegerSampler[textureID],0).xy;
		//vec2 imagesize = textureSize(terrainmaterialmap,0).xy;
		vec2 alphapixelsize = 0.5 / imagesize;
		vec2 imagepixelsize = 1.0 / imagesize;
		vec2 tilef = texCoords.xy * imagesize;
		vec2 tile = floor(tilef);
		vec2 rem = (tilef - tile);
		vec2 acoords = tile * imagepixelsize + alphapixelsize * 0.5 + rem * alphapixelsize;	
		vec4 textureAlpha = texture(sampler2D(alphatexID),acoords.xy);
		//vec4 textureAlpha = texture(terrainalphamap,acoords.xy);
		float terraindisplacement = 0.0;
		Material submtl;
		ivec2 tilecoord;
		tilecoord.x = int(texCoords.x * float(imagesize.x));
		tilecoord.y = int(texCoords.y * float(imagesize.y));
		uvec4 materialIDs = texelFetch(usampler2D(textureID), tilecoord, 0);
		//uvec4 materialIDs = texelFetch(terrainmaterialmap, tilecoord, 0);
		vec2 terrcoords = texCoords.xy * 32.0f;//* terrainScale.xz;
		TerrainLayerInfo layerinfo;
		vec3 layercoords;
		for (int channel = 0; channel < 4; ++channel)
		{
			if (textureAlpha[channel] < 0.001f) continue;
			//if (materialIDs[channel] == 0 or textureAlpha[channel] == 0.0f) break;

			ExtractTerrainLayerInfo(terrainID, materialIDs[channel], layerinfo);

            layercoords.xz = texCoords.xy * layerinfo.scale * 512.0f;
            layercoords.y = texCoords.z * layerinfo.scale;

			int submtlID = layerinfo.materialID;
			//int submtlID = ExtractTerrainLayerInfo(terrainID, materialIDs[channel]);
			if (submtlID == -1) continue;
			submtl = materials[submtlID];
			uint mtlflags = submtl.flags;//GetMaterialFlags(submtl);
			uvec2 subtex = GetMaterialTextureHandle(submtl, TEXTURE_DISPLACEMENT);			
			if ((mtlflags & MATERIAL_TESSELLATION) == 0) continue;
			if (subtex != uvec2(0))
			{
				float maxDisplacement = submtl.displacement.x;
				float offset = submtl.displacement.y;
				float layerscale = 1.0f / layerinfo.scale;
				layerscale *= textureSize(sampler2D(subtex), 0).x / 1024.0f;
				layerscale *= float(imagesize).x / 512.0f;
				float uvscale = layerscale;
				terraindisplacement += uvscale * offset * textureAlpha[channel];
				terraindisplacement += maxDisplacement * uvscale * TerrainSample(sampler2D(subtex), layercoords, normal, layerinfo.mappingmode).r * textureAlpha[channel];

//				terraindisplacement += uvscale * (((offset + maxDisplacement) * TerrainSample(sampler2D(subtex), layercoords, normal, layerinfo.mappingmode).r) * textureAlpha[channel]);
			}
		}
		position.xyz += normal * terraindisplacement;		
	}
}