
#define TERRAIN

#include "TerrainInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/Fragment.glsl"
#include "../Utilities/iSO646.glsl"
#include "../Khronos/material_info.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Khronos/tonemapping.glsl"
#ifdef LIGHTING
#include "../PBR/Lighting.glsl"
#include "../Lighting/SSRTrace.glsl"
#endif
#include "../Editor/grid.glsl"

MaterialInfo materialInfo;
vec4 baseColor = vec4(1);
vec3 f_diffuse = vec3(0);
vec3 f_specular = vec3(0);
mat4 mat;
int terrainID;
vec4 entitycolor;
uint flags;
vec3 f_emissive = vec3(0);
float occlusion = 1.0f;
const float MinAlpha = 0.003f;

struct SubSample
{
    vec4 color;
    float metallic, roughness, occlusion;
    vec3 normal, emission;
};

SubSample subsample;

//layout(binding = 0) uniform sampler2DArray terrainbasetextureatlas;
//layout(binding = 1) uniform sampler2DArray terrainnormaltextureatlas;
//layout(binding = 2) uniform sampler2DArray displacementtextureatlas;
//layout(binding = TEXTURE_TERRAINMASK) uniform sampler2D terrainmaskmap;
//layout(binding = TEXTURE_TERRAINHEIGHT) uniform sampler2D terrainheightmap;
//layout(binding = TEXTURE_TERRAINNORMAL) uniform sampler2D terrainnormalmap;
//layout(binding = TEXTURE_TERRAINALPHA) uniform sampler2D terrainalphamap;
//layout(binding = TEXTURE_TERRAINMATERIAL) uniform usampler2D terrainmaterialmap;

void main()
{
    uvec2 textureID;
    Material material = materials[materialID];

    //--------------------------------------------------------------------
    // Discard hidden tiles
    //--------------------------------------------------------------------

#ifdef MASK_DISCARD
    textureID = material.textureHandle[2];
    if (textureID != uvec2(0))
	{
        if (textureLod(sampler2D(textureID), texcoords.xy, 0).r > 0.0f) discard;
    }
#endif

    ExtractEntityInfo(entityID, mat, terrainID);

    //--------------------------------------------------------------------
    // Initialize material info
    //--------------------------------------------------------------------

    // The default index of refraction of 1.5 yields a dielectric normal incidence reflectance of 0.04.
    materialInfo.ior = 1;
    materialInfo.f0 = vec3(0.04f);//0.04 is default
    materialInfo.specularWeight = 1;
    materialInfo.attenuationDistance = 0;
    materialInfo.attenuationColor = vec3(1);
    materialInfo.thickness = 10;
    materialInfo.transmissionFactor = 0;
    materialInfo.sheenColorFactor = vec3(0);
    materialInfo.metallic = 0.0f;
    materialInfo.perceptualRoughness = 1.0f;

    //--------------------------------------------------------------------
	// Terrain normal map
    //--------------------------------------------------------------------

    mat3 tbn;
    vec3 localnormal;
	if (material.textureHandle[TEXTURE_TERRAINNORMAL] != uvec2(0))
	{
		vec4 nsample = textureLod(sampler2D(material.textureHandle[TEXTURE_TERRAINNORMAL]),texcoords.xy, 0) * 2.0f - 1.0f;
		//vec4 nsample = textureLod(terrainnormalmap,texcoords.xy, 0) * 2.0f - 1.0f;
        tbn[2].xz = nsample.xy;
        tbn[2].y = sqrt(max(0.0f, 1.0f - (tbn[2].x * tbn[2].x + tbn[2].z * tbn[2].z)));
        //tbn[0].yz = nsample.zw;
        //tbn[0].x = sqrt(max(0.0f, 1.0f - (tbn[0].z * tbn[0].z + tbn[0].y * tbn[0].y)));
        //textureID = GetMaterialTextureHandle(material, TEXTURE_TERRAINNORMAL);
        //if (textureID != -1)
        {
        //    vec4 nsample = textureLod(sampler2D(textureID),texcoords.xy, 0) * 2.0f - 1.0f;
            tbn[0].yz = nsample.xy;
            tbn[0].x = sqrt(max(0.0f, 1.0f - (tbn[0].z * tbn[0].z + tbn[0].y * tbn[0].y)));
        }
        tbn[1] = cross(tbn[2], tbn[0]);
	}
	else
	{
        tbn[0] = vec3(1,0,0);
        tbn[1] = vec3(0,0,-1);
		tbn[2] = vec3(0,1,0);
	}
    localnormal = tbn[2];

    //tbn = mat3(mat) * tbn;

    //tangent = vec3(1.0f, 0.0f, 0.0f);
    //bitangent = vec3(0.0f, 0.0f, -1.0f);
    //color.rgb = bitangent * 0.5f + 0.5f;
    //return;

    //--------------------------------------------------------------------
    // Terrain materials
    //--------------------------------------------------------------------

    textureID = material.textureHandle[TEXTURE_TERRAINMATERIAL];
	uvec2 alphamapID = material.textureHandle[TEXTURE_TERRAINALPHA];

	if (textureID != uvec2(0) && alphamapID != uvec2(0))
    {
        //ivec2 sz = textureSize(terrainmaterialmap,0);
        ivec2 sz = textureSize(usampler2D(textureID),0);
        vec2 fsz = vec2(sz);
        vec2 alphapixelsize = 0.5f / fsz;
        vec2 imagepixelsize = 1.0f / fsz;
        vec2 tilef = texcoords.xy * fsz;
        vec2 tile = floor(tilef);
        vec2 rem = (tilef - tile);
        vec2 alphacoords = tile * imagepixelsize + alphapixelsize * 0.5f + rem * alphapixelsize;
        ivec2 tilecoord;
        tilecoord.x = int(texcoords.x * float(sz.x));
        tilecoord.y = int(texcoords.y * float(sz.y));
        //uvec4 samp = texelFetch(terrainmaterialmap, tilecoord, 0);
        uvec4 samp = texelFetch(usampler2D(textureID), tilecoord, 0);
        vec4 samplealpha = textureLod(sampler2D(alphamapID), alphacoords, 0.0f);
        //vec4 samplealpha = textureLod(terrainalphamap, alphacoords, 0.0f);

        //vec2 texsize = textureSize(terrainalphamap, 0);
        vec2 texsize = textureSize(sampler2D(alphamapID), 0);
        vec2 taspect = vec2(1.0f, texsize.y / texsize.x);

        uint mtlid;
        vec3 subnormal;
        vec3 terrainnormal;
        vec3 submetalroughness;
        Material layer;
        uint materialflags, layerflags;
        bool started = false;
        vec3 o_normal = normal;
        vec4 sampl;
        float metalness = 0, roughness = 0;
        vec2 o_metalroughness = vec2(metalness, roughness);
        vec4 color;
        float alpha;
        vec4 mrsample;
        TerrainLayerInfo layerinfo[4];
        vec3 layercoords[4];
        vec4 displacement;

        /*for (int i = 0; i < 4; ++i)
        {
            ExtractTerrainLayerInfo(terrainID, samp[i], layerinfo[i]);	
            layercoords[i].xz = texcoords.xy * layerinfo[i].scale * 512.0f * 1.0f;
            layercoords[i].y = texcoords.z * layerinfo[i].scale;// * 512.0f;
        }*/

        //Displacement blending
        Material submtl;
        for (int i = 0; i < 4; ++i)
        {
            if (samplealpha[i] <= MinAlpha) continue;// end of materials

            ExtractTerrainLayerInfo(terrainID, samp[i], layerinfo[i]);	
            mtlid = layerinfo[i].materialID;
            if (mtlid == -1) continue;

            layercoords[i].xz = texcoords.xy * layerinfo[i].scale * 512.0f * taspect;
            layercoords[i].y = texcoords.z * layerinfo[i].scale;// * 512.0f;
            //layercoords[i].y = vertexWorldPosition.y * layerinfo[i].scale;

            //if ((layerinfo[i].flags & 8) != 0)
            //{
            //    float d = TerrainSample(displacementtextureatlas, layercoords[i], localnormal, layerinfo[i].mappingmode, samp[i]).r;
            //    samplealpha[i] += max(0.0f, d - 0.5f) * 10.0f * min(1.0f, samplealpha[i] * 4.0f);
            //}

            //textureID = GetMaterialTextureHandle(materials[mtlid], TEXTURE_DIFFUSE);
            //if (textureID != -1)
            //{
            //    layercoords[i] *= (vec2(1024.0f) / textureSize(sampler2D(textureID), 0));
            //}

            submtl = materials[mtlid];

            textureID = materials[mtlid].textureHandle[TEXTURE_DISPLACEMENT];//GetMaterialTextureHandle(materials[mtlid], TEXTURE_DISPLACEMENT);
            if (textureID != uvec2(0))
            {
                float maxDisplacement = submtl.displacement.x;
				float offset = submtl.displacement.y;
				float uvscale = layerinfo[i].scale * 64.0f;
                displacement[i] = (offset + maxDisplacement * TerrainSample(sampler2D(textureID), layercoords[i], localnormal, layerinfo[i].mappingmode).r) * uvscale;

                samplealpha[i] += max(0.0f, displacement[i] - 0.5f) * 10.0f * min(1.0f, samplealpha[i] * 4.0f);
                //samplealpha[i] += max(0.0f, texture(sampler2D(textureID), layercoords[i]).r - 0.5f) * 10.0f * min(1.0f, samplealpha[i] * 4.0f);
                //samplealpha[i] *= 0.9f * texture(sampler2D(textureID), texcoords.xy * 32.0f).r + 0.1f;
            }
        }

        //Normalize weights
        float sum = samplealpha[0] + samplealpha[1] + samplealpha[2] + samplealpha[3];
        if (sum != 0.0f && sum != 1.0f) samplealpha /= sum;
        sum = 0.0f;

        for (int i = 0; i < 4; ++i)
        {
            //ExtractTerrainLayerInfo(terrainID, samp[i], layerinfo[i]);	

            //if (samp[i] == 0 or samplealpha[i] == 0.0f) continue;// end of materials
            if (samplealpha[i] <= MinAlpha) continue;// end of materials

            mtlid = layerinfo[i].materialID;	
            
            alpha = samplealpha[i];

            if (!started)
            {
                started = true;
                color = vec4(0.0f);
                submetalroughness = vec3(0);
                terrainnormal = vec3(0.0f);
            }

            layer = materials[mtlid];
            uint materialFlags = layer.flags;//GetMaterialFlags(layer);

            //--------------------------------------------------------------------
            // Base color
            //--------------------------------------------------------------------

            subsample.color = layer.diffuseColor;
            //if ((layerinfo[i].flags & 1) != 0)
            //{
            //    subsample.color *= TerrainSample(terrainbasetextureatlas, layercoords[i], localnormal, layerinfo[i].mappingmode, samp[i] * 3 + 0);
            //}
            if (layer.textureHandle[TEXTURE_BASE] != uvec2(0))
            {
                subsample.color *= sRGBToLinear(TerrainSample(sampler2D(layer.textureHandle[TEXTURE_BASE]), layercoords[i], localnormal, layerinfo[i].mappingmode));
            }

            //--------------------------------------------------------------------
            // Normal map
            //--------------------------------------------------------------------

            //if ((layerinfo[i].flags & 2) != 0)
            //{
            //    subsample.normal = TerrainSample(terrainnormaltextureatlas, layercoords[i], localnormal, layerinfo[i].mappingmode, samp[i]).xyz * 2.0f - 1.0f;
            //    subsample.normal.z = sqrt(max(0.0f, 1.0f - (subsample.normal.x * subsample.normal.x + subsample.normal.y * subsample.normal.y))); //BC5 is always used
            //}
            if (layer.textureHandle[TEXTURE_NORMAL] != uvec2(0))
            {
                subsample.normal = TerrainSample(sampler2D(layer.textureHandle[TEXTURE_NORMAL]), layercoords[i], localnormal, layerinfo[i].mappingmode).xyz * 2.0f - 1.0f;
                if ((materialFlags & MATERIAL_EXTRACTNORMALMAPZ) != 0)
                {
                    subsample.normal.z = sqrt(max(0.0f, 1.0f - (subsample.normal.x * subsample.normal.x + subsample.normal.y * subsample.normal.y)));
                }
            }
            else
            {
                subsample.normal = vec3(0,0,1);
            }

            //--------------------------------------------------------------------
            // Emission
            //--------------------------------------------------------------------

            subsample.emission = layer.emissiveColor.rgb;
            if (layer.textureHandle[TEXTURE_EMISSION] != uvec2(0))
            {
                subsample.emission *= sRGBToLinear(TerrainSample(sampler2D(layer.textureHandle[TEXTURE_EMISSION]), layercoords[i], localnormal, layerinfo[i].mappingmode)).rgb;
            }
            //if ((layerinfo[i].flags & 16) != 0)
            //{
            //    subsample.emission *= TerrainSample(terrainbasetextureatlas, layercoords[i], localnormal, layerinfo[i].mappingmode, samp[i] * 3 + 2).rgb;
            //}

            //--------------------------------------------------------------------
            // Metallic roughness
            //--------------------------------------------------------------------

            subsample.metallic = layer.metalness;
            subsample.roughness = layer.roughness;
            if (layer.textureHandle[TEXTURE_METALLICROUGHNESS] != uvec2(0))
            {
                mrsample = TerrainSample(sampler2D(layer.textureHandle[TEXTURE_METALLICROUGHNESS]), layercoords[i], localnormal, layerinfo[i].mappingmode);
                subsample.metallic *= mrsample.b;
                subsample.roughness *= mrsample.g;
            }
            //if ((layerinfo[i].flags & 4) != 0)
            //{
            //    mrsample = TerrainSample(terrainbasetextureatlas, layercoords[i], localnormal, layerinfo[i].mappingmode, samp[i] * 3 + 1);
            //    subsample.metallic *= mrsample.b;
            //    subsample.roughness *= mrsample.g;
            //    if ((layerinfo[i].flags & 32) != 0) subsample.occlusion *= mrsample.r; //occlusion
            //}
            
            //--------------------------------------------------------------------
            // Combine samples
            //--------------------------------------------------------------------

            color += subsample.color * alpha;
            terrainnormal += subsample.normal * alpha;
            metalness += subsample.metallic * alpha;
            roughness += subsample.roughness * alpha;
            f_emissive += subsample.emission * alpha;
            occlusion += subsample.occlusion * alpha;

            sum += alpha;
            if (sum >= 0.99f) break;
        }

        if (started)
        {
            tbn[1] = vec3(0,1,0);
            baseColor = color;
            tbn[2] = normalize(tbn[0] * terrainnormal.x + tbn[1] * terrainnormal.y + tbn[2] * terrainnormal.z);
            materialInfo.metallic = metalness;
            materialInfo.perceptualRoughness = roughness;
        }
    }

// Used in lighting and trasmission
#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#else
    vec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#endif
	dFloat NdotV = dot(tbn[2], v);
	
    //---------------------------------------------------------------------------
    // Material properties
    //---------------------------------------------------------------------------

    materialInfo.baseColor = baseColor.rgb;
    
    materialInfo.perceptualRoughness = clamp(materialInfo.perceptualRoughness, 0.0f, 1.0f);
    materialInfo.metallic = clamp(materialInfo.metallic, 0.0f, 1.0f);
    
    // Achromatic f0 based on IOR
    materialInfo.c_diff = mix(materialInfo.baseColor.rgb,  vec3(0.0f), materialInfo.metallic);
    materialInfo.f0 = mix(materialInfo.f0, materialInfo.baseColor.rgb, materialInfo.metallic);
    materialInfo.f0 = vec3(0.04f);

    // Roughness is authored as perceptual roughness; as is convention,
    // convert to material roughness by squaring the perceptual roughness.
    materialInfo.alphaRoughness = materialInfo.perceptualRoughness * materialInfo.perceptualRoughness;

    // Compute reflectance.
    float reflectance = max(max(materialInfo.f0.r, materialInfo.f0.g), materialInfo.f0.b);

    // Anything less than 2% is physically impossible and is instead considered to be shadowing. Compare to "Real-Time-Rendering" 4th editon on page 325.
    materialInfo.f90 = vec3(1);

    vec4 ibldiffuse = vec4(0);
    vec4 iblspecular = vec4(0);
    bool renderprobes = true;

#ifdef LIGHTING




//    materialInfo.c_diff *= 2.0f;

    if ((RenderFlags & RENDERFLAGS_NO_LIGHTING) == 0)
    {
        vec3 emission = vec3(0.0f);
        RenderLighting(material, materialInfo, vertexWorldPosition.xyz, tbn[2], tbn[2], v, NdotV, f_diffuse, f_specular, renderprobes, ibldiffuse, iblspecular, emission);
    }
    
#endif

#ifdef USE_IBL

    //Screen-space reflection, only when roughness < 1
    /*if ((RenderFlags & RENDERFLAGS_SSR) != 0)
    {
        if (materialInfo.perceptualRoughness < 1.0f)
        {
            vec2 screencoord = gl_FragCoord.xy / BufferSize;
            float ssrblend;
            vec4 ssr = SSRTrace(vertexWorldPosition.xyz, tbn[2], materialInfo.perceptualRoughness, sampler2D(ReflectionMapTextureID], sampler2D(PrevFrameDepthTextureID], ssrblend);
            iblspecular = iblspecular * (1.0f - ssrblend) + ssr * ssrblend;
        }
    }*/

    if (renderprobes == true && IBLIntensity > 0.0f)// and (vxrt.a < 1.0f or vxrtspecular.a < 1.0f))
    {
        int u_MipCount;
        float lod;
    #ifdef MATERIAL_IRIDESCENCE
        f_specular += getIBLRadianceGGXIridescence(n, v, materialInfo.perceptualRoughness, materialInfo.f0, iridescenceFresnel, materialInfo.iridescenceFactor, materialInfo.specularWeight);
        f_diffuse += getIBLRadianceLambertianIridescence(n, v, materialInfo.perceptualRoughness, materialInfo.c_diff, materialInfo.f0, iridescenceF0, materialInfo.iridescenceFactor, materialInfo.specularWeight);
    #else

        //Specular reflection
        if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
        {
            if (iblspecular.a < 1.0f)
            {
                u_MipCount = textureQueryLevels((SpecularEnvironmentMap));
                lod = materialInfo.perceptualRoughness * float(u_MipCount - 1); 
                iblspecular.rgb += sRGBToLinear(textureLod((SpecularEnvironmentMap), reflect(-v, tbn[2]), lod).rgb) * (1.0f - iblspecular.a) * IBLIntensity;
            }
            if (iblspecular.r + iblspecular.g + iblspecular.b > 0.0f)
            {
                f_specular += getIBLRadianceGGX((Lut_GGX), iblspecular.rgb, tbn[2], v, materialInfo.perceptualRoughness, materialInfo.f0, materialInfo.specularWeight);
            }
        }

        //Diffuse reflection
        if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
        {
            if (/*EnvironmentMap_Diffuse != uvec2(0) &&*/ ibldiffuse.a < 1.0f)
            {
                ibldiffuse.rgb += sRGBToLinear(texture(DiffuseEnvironmentMap, tbn[2]).rgb) * (1.0f - ibldiffuse.a) * IBLIntensity;
                //ibldiffuse.rgb += texture((DiffuseEnvironmentMap), tbn[2]).rgb * (1.0f - ibldiffuse.a) * IBLIntensity;
            }
            if (ibldiffuse.r + ibldiffuse.g + ibldiffuse.b > 0.0f)
            {
                f_diffuse += getIBLRadianceLambertian((Lut_GGX), ibldiffuse.rgb, tbn[2], v, materialInfo.perceptualRoughness, materialInfo.c_diff, materialInfo.f0, materialInfo.specularWeight);
            }
        }
    #endif
    }
#endif

    //--------------------------------------------------------------------------
    // Final blend
    //--------------------------------------------------------------------------
 
    vec3 diffuse = f_diffuse;

#ifdef PREMULTIPLY_AlPHA
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) diffuse *= baseColor.a;
#endif

    vec3 color = vec3(0.0f);
#ifdef MATERIAL_UNLIT
    color = baseColor.rgb;
#else
    color = diffuse + f_specular;
#endif

    color += f_emissive;

#ifdef DEFERRED_REFLECTIONCOLOR
    baseColor.a = clamp(baseColor.a, 0.05f, 1.0f);
#endif

    outColor[0] = vec4(linearTosRGB(color.rgb), baseColor.a);

    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) outColor[0].rgb *= outColor[0].a;
    
    int attachmentindex = 0;
    
    //Deferred screen normals
    if ((RenderFlags & RENDERFLAGS_OUTPUT_NORMALS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = tbn[2];
        outColor[attachmentindex].a = baseColor.a;
    }

    //Deferred material metal / roughness
    if ((RenderFlags & RENDERFLAGS_OUTPUT_METALLICROUGHNESS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].r = materialInfo.metallic;
        outColor[attachmentindex].g = materialInfo.perceptualRoughness;
        outColor[attachmentindex].b = 0;
        outColor[attachmentindex].a = baseColor.a;
    }

    //Deferred base color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ALBEDO) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = materialInfo.f0;
        outColor[attachmentindex].a = baseColor.a;
    }

    //Deferred Z-position
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ZPOSITION) != 0)
    {
        ++attachmentindex;
        float dd = PositionToDepth(vertexCameraPosition.z, CameraRange);
        outColor[attachmentindex] = vec4(dd, dd, dd, 1.0f);
    }
    
    //Reflection color (no specular)
    if ((RenderFlags & RENDERFLAGS_SSR) != 0)
    {
        ++attachmentindex;
        vec3 reflection = diffuse + f_emissive;
        if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(reflection, vertexWorldPosition.xyz, CameraPosition);
        outColor[attachmentindex].rgb = reflection;
        outColor[attachmentindex].a = clamp(baseColor.a, 0.0f, 1.0f);
        outColor[attachmentindex].r = min(2.0f, outColor[attachmentindex].r);
        outColor[attachmentindex].g = min(2.0f, outColor[attachmentindex].g);
        outColor[attachmentindex].b = min(2.0f, outColor[attachmentindex].b);
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) == 0) outColor[attachmentindex].a = 1.0f;
    }

    //Camera distance fog
    if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(outColor[0].rgb, vertexWorldPosition.xyz, CameraPosition);

    //Clamp alpha
    outColor[0].a = clamp(outColor[0].a, 0.0f, 1.0f);

    //Dither final pass
    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        outColor[0].rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }

    //Display editor gizmo    
    if (pickedterraintoolradius.x > 0.0f)
    {
        const float thickness = 0.25f;
        mat4 mat = ExtractEntityMatrix(terrainID);
        mat[0].xyz = normalize(mat[0].xyz);
        mat[1].xyz = normalize(mat[1].xyz);
        mat[2].xyz = normalize(mat[2].xyz);
        vec4 p0 = mat * vertexWorldPosition;
        vec4 p1 = mat * vec4(pickedterraintoolposition, 1.0f);
        float d = length((p0.xz - p1.xz));
        if (d < pickedterraintoolradius.x)
        {
            if (d > pickedterraintoolradius.x - thickness)
            {
                outColor[0] = vec4(1,1,1,1);
            }
            else if (d < pickedterraintoolradius.y && d > pickedterraintoolradius.y - thickness)
            {
                outColor[0] = vec4(1,1,0.5,1);
            }
        }
    }

    //Editor grid
    //float d = PositionToDepth(vertexCameraPosition.z, CameraRange);
    //outColor[0].rgb += WorldGrid(vertexWorldPosition.xz, d);

    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) == 0) outColor[0].a = 1.0f;

    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        //Dither final pass
        outColor[0].rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }
}