#include "../Base/Settings.glsl"
#include "../Utilities/ISO646.glsl"
#include "../Base/Fragment.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Khronos/material_info.glsl"
#include "../Khronos/ibl.glsl"
#include "../Khronos/brdf.glsl"
#include "../Khronos/tonemapping.glsl"
#include "../Khronos/punctual.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/Dither.glsl"
#include "../Editor/Grid.glsl"
#ifdef USE_IBL
#include "../Lighting/SSRTrace.glsl"
#endif

#include "MultiMaterial.glsl"

#ifdef LIGHTING
#include "Lighting.glsl"
#endif

int textureID;
MaterialInfo materialInfo;
vec4 baseColor = vec4(1);

vec3 f_specular = vec3(0.0f);
vec3 f_diffuse = vec3(0.0f);
vec3 f_emissive = vec3(0.0f);
vec3 f_clearcoat = vec3(0.0f);
vec3 f_sheen = vec3(0.0f);
vec3 f_transmission = vec3(0.0f);
float albedoSheenScaling = 1.0f;

#ifndef SPECULARMODEL
    #define SPECULARMODEL 0
#endif

#define USE_IBL

void main()
{
    Material material = materials[ materialIDs[0] ];
    texcoords.xyz += GetMaterialTextureOffset(material, CurrentTime);
    
    vec3 norm = vec3(0.0f);

#ifdef MATERIAL_METALLICROUGHNESS    
    vec4 materialweights_ = materialweights;
    
    vec3 pbr_omr;
    vec3 f_emissive;

    vec4 m_color;
    vec3 m_norm, m_omr, m_emissive;

    PBRMaterial(material, texcoords.xy, baseColor, norm, pbr_omr, f_emissive);
#if MAX_MATERIALS > 1
    if (materialIDs[1] != 0 && materialweights_[1] > 0.0f)
    {
        PBRMaterial(materials[ materialIDs[1] ], texcoords.xy, materialweights_[1], baseColor, norm, pbr_omr, f_emissive);
    }
#endif
#if MAX_MATERIALS > 2
    if (materialIDs[2] != 0 && materialweights_[2] > 0.0f)
    {
        PBRMaterial(materials[ materialIDs[2] ], texcoords.xy, materialweights_[2], baseColor, norm, pbr_omr, f_emissive);
    }
#endif
#if MAX_MATERIALS > 3
    if (materialIDs[3] != 0 && materialweights_[3] > 0.0f)
    {
        PBRMaterial(materials[ materialIDs[3] ], texcoords.xy, materialweights_[3], baseColor, norm, pbr_omr, f_emissive);
    }
#endif
#if MAX_MATERIALS > 1
	norm.z = sqrt(max(0.0f, 1.0f - (norm.x * norm.x + norm.y * norm.y)));
#endif   

#else
    
    baseColor = PBRBaseColor(material, texcoords.xy);
    norm = PBRNormals(material, texcoords.xy);
    if ((material.flags & MATERIAL_EXTRACTNORMALMAPZ) != 0) norm.z = sqrt(max(0.0f, 1.0f - (norm.x * norm.x + norm.y * norm.y)));
    f_emissive = PBREmissionColor(material, texcoords.xy);

#endif

    baseColor *= color;
    f_emissive *= emissioncolor;

    u_EnvIntensity = IBLIntensity;
    uint materialFlags = material.flags; //GetMaterialFlags(material);

    // The default index of refraction of 1.5 yields a dielectric normal incidence reflectance of 0.04.
    materialInfo.ior = 1.5f;//ExtractMaterialRefractionIndex(material);
    materialInfo.f0 = vec3(0.04f);//0.04 is default
    materialInfo.specularWeight = 1.0f;
    materialInfo.attenuationDistance = 0.0f;
    materialInfo.attenuationColor = vec3(1.0f);
    materialInfo.transmissionFactor = 1.0f;//GetMaterialTransmission(material);

	//--------------------------------------------------------------------------
    // Displacement, for blending
    //--------------------------------------------------------------------------

    //vec4 materialweights_ = materialweights;
    //multiTextureDisplacement(texcoords.xy, materialweights_);

	//--------------------------------------------------------------------------
    // Diffuse / albedo
    //--------------------------------------------------------------------------
    
    //baseColor = material.diffuseColor * color;
    //vec4 basesample = multiTextureBaseColor(texcoords.xy, materialweights_);
    //baseColor *= sRGBToLinear(basesample);
    baseColor = sRGBToLinear(baseColor);
    
#ifdef ALPHA_DISCARD
    if (baseColor.a < material.alphacutoff) discard;
#endif
    materialInfo.baseColor = baseColor.rgb;

    //--------------------------------------------------------------------------
    // Normal map
    //--------------------------------------------------------------------------

#ifdef DOUBLE_FLOAT
    dvec3 n = normal;
    dvec3 facenormal = n;
#else
    vec3 n = normal;
    vec3 facenormal = n;
#endif

#ifndef USER_HOOK
    if ((materialFlags & MATERIAL_IGNORENORMALS) == 0)
	{
        //pbr_normal
        //vec3 norm = multiTextureNormals(texcoords.xy, materialweights_);
        if (norm != vec3(0.0f)) n = tangent.xyz * norm.x + bitangent * norm.y + normal * norm.z;
        n = normalize(n);
    }
    else
    {
        n = vec3(0.0f, 1.0f, 0.0f);
    }
#endif

#ifdef USER_HOOK

    SurfaceInput surfinput;
    surfinput.texcoords = texcoords;
    surfinput.color = color;
    surfinput.normal = normal;
    surfinput.tangent = tangent;
    surfinput.bitangent = bitangent;
    surfinput.material = material;

    SurfaceOutput surfinfo;
    surfinfo.normal = n;
    surfinfo.basecolor = vec4(1.0f);
    surfinfo.metallic = 0.0f;
    surfinfo.roughness = 1.0f;
    surfinfo.reflectance = vec3(0.0f);
    surfinfo.emission = vec3(0.0f);

    UserHook(surfinput, surfinfo);
    
    materialInfo.metallic = surfinfo.metallic;
	materialInfo.f0 = surfinfo.reflectance;
    materialInfo.perceptualRoughness = surfinfo.roughness;
    materialInfo.c_diff = surfinfo.basecolor.rgb;
    baseColor = surfinfo.basecolor;

#endif

//outColor[0].rgb = n * 0.5 + 0.5;
//return;

// Used in lighting and transmission
#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#else
    vec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#endif
	dFloat NdotV = dot(n, v);

#ifdef MATERIAL_SPECULARGLOSSINESS
	
    //--------------------------------------------------------------------------
    // Specular glossiness
    //--------------------------------------------------------------------------
    
    materialInfo.metallic = 0;
	materialInfo.f0 = material.speculargloss.rgb;
    materialInfo.perceptualRoughness = 1.0f - material.speculargloss.a;
    if (material.textureHandle[TEXTURE_METALLICROUGHNESS] != uvec2(0))
    {
        vec4 sgSample = (texture(sampler2D(material.textureHandle[TEXTURE_METALLICROUGHNESS]), texcoords.xy));
        materialInfo.perceptualRoughness *= 1.0f - sgSample.a; // glossiness to roughness
        materialInfo.f0 *= sgSample.rgb; // specular
    }

    //Detail map
    /*if (material.textureHandle[TEXTURE_AMBIENTOCCLUSION + 1] != uvec2(0))
    {
        float roughnessdetailscale = 0;
        //materialInfo.perceptualRoughness = mix(materialInfo.perceptualRoughness, materialInfo.perceptualRoughness * (1.0f - detail.b) * 2.0f, roughnessdetailscale);
    }*/
    
    materialInfo.c_diff = materialInfo.baseColor.rgb * (1.0f - max(max(materialInfo.f0.r, materialInfo.f0.g), materialInfo.f0.b));
    
#endif

#ifdef MATERIAL_LAMBERTIAN

    materialInfo.c_diff = materialInfo.baseColor.rgb;
    materialInfo.perceptualRoughness = 1.0f;
    materialInfo.metallic = 0.0f;
    materialInfo.specularWeight = 0.0f;

#endif

#ifdef MATERIAL_METALLICROUGHNESS

    //--------------------------------------------------------------------------
    // Metallic roughness
    //--------------------------------------------------------------------------

    //vec3 omr = multiOcclusionMetalRoughness(texcoords.xy, materialweights_);
    materialInfo.metallic = pbr_omr.b;
    materialInfo.perceptualRoughness = pbr_omr.g;
    materialInfo.perceptualRoughness = clamp(materialInfo.perceptualRoughness, 0.04f, 1.0f);
    materialInfo.metallic = clamp(materialInfo.metallic, 0.0f, 1.0f);    

    // Achromatic f0 based on IOR.
    materialInfo.c_diff = mix(materialInfo.baseColor.rgb,  vec3(0.0f), materialInfo.metallic);
    materialInfo.f0 = mix(materialInfo.f0, materialInfo.baseColor.rgb, materialInfo.metallic);

#endif

    //--------------------------------------------------------------------------
    // Miscellaneous stuff...
    //--------------------------------------------------------------------------
    
    // Roughness is authored as perceptual roughness; as is convention,
    // convert to material roughness by squaring the perceptual roughness.
    materialInfo.alphaRoughness = materialInfo.perceptualRoughness * materialInfo.perceptualRoughness;

    // Compute reflectance.
    float reflectance = max(max(materialInfo.f0.r, materialInfo.f0.g), materialInfo.f0.b);

    // Anything less than 2% is physically impossible and is instead considered to be shadowing. Compare to "Real-Time-Rendering" 4th editon on page 325.
    materialInfo.f90 = vec3(1.0f);

    //--------------------------------------------------------------------------
    // Lighting
    //--------------------------------------------------------------------------

    vec4 ibldiffuse = vec4(0.0f);
    vec4 iblspecular = vec4(0.0f);
	uint cameraflags = ExtractEntityFlags(CameraID);
	bool renderprobes = (RenderFlags & RENDERFLAGS_NO_IBL) == 0;

#ifndef USE_IBL
    renderprobes = false;
#endif

#ifdef LIGHTING
    if ((RenderFlags & RENDERFLAGS_NO_LIGHTING) == 0)
    {
        //if ((materialFlags & MATERIAL_BACKFACELIGHTING) == 0) facenormal = n;
        materialInfo.alpha = baseColor.a;
        RenderLighting(material, materialInfo, vertexWorldPosition.xyz, n, facenormal, v, NdotV, f_diffuse, f_specular, renderprobes, ibldiffuse, iblspecular, f_emissive);
        baseColor.a = materialInfo.alpha;
        
        if (!renderprobes)
        {
            ibldiffuse = vec4(0.0f);
            iblspecular = vec4(0.0f);
            f_specular = vec3(0.0);// we don't want specular reflection in probe renders since it is view-dependent
        }
    }
    else
    {
        renderprobes = false;
        f_diffuse.rgb = materialInfo.c_diff * AmbientLight;
        f_specular = vec3(0.0f);// we don't want specular reflection in probe renders since it is view-dependent
    }    
#else
    f_diffuse.rgb = baseColor.rgb;
#endif

    float ao = 1.0f;

    //--------------------------------------------------------------------------
    // Ambient occlusion
    //--------------------------------------------------------------------------

    /*
    // Apply optional PBR terms for additional (optional) shading
	if (material.textureHandle[TEXTURE_AMBIENTOCCLUSION] != uvec2(0))
    {
        ao = texture(sampler2D(material.textureHandle[TEXTURE_AMBIENTOCCLUSION]), texcoords.xy).r;
        //ao = 0.5 + ao * 0.5;
        f_diffuse *= ao;
        f_specular *=ao;
    }
    */
    
    //--------------------------------------------------------------------------
    // Calculate lighting contribution from image based lighting source (IBL)
    //--------------------------------------------------------------------------

    //outColor[0].rgb = linearTosRGB(f_specular, InverseGammaLevel);
    //return;

#ifdef USE_IBL

    //Screen-space reflection, only when roughness < 1
    if (materialInfo.specularWeight > 0.001f && (RenderFlags & RENDERFLAGS_SSR) != 0 && ReflectionMapHandles.xy != uvec2(0) && ReflectionMapHandles.zw != uvec2(0))
    {
        //if (material.roughness < 0.999f || material.metalness > 0.001f)
        {
            /*{
                vec2 screencoord = gl_FragCoord.xy / BufferSize * 4.0f;
                if (screencoord.x < 1.0f && screencoord.y < 1.0f)
                {
                    float d = textureLod(sampler2D(ReflectionMapHandles.zw), screencoord, 0).r;
                    //d = DepthToPosition(d, CameraRange) / 2.0f;
                    outColor[0].rgb = vec3(d);
                    outColor[0].a = 1.0f;
                    //outColor[0] = textureLod(sampler2D(ReflectionMapHandles.xy), screencoord, 0);
                    return;
                }
            }*/
            vec2 screencoord = gl_FragCoord.xy / BufferSize;
            float ssrblend;
            vec4 ssr = SSRTrace(vertexWorldPosition.xyz, n, materialInfo.perceptualRoughness, sampler2D(ReflectionMapHandles.xy), sampler2D(ReflectionMapHandles.zw), ssrblend);            
            ssr.rgb = sRGBToLinear(ssr.rgb);
            iblspecular = iblspecular * (1.0f - ssrblend) + ssr * ssrblend;
        }
    }

    if (!gl_FrontFacing)
    {
        if (((materialFlags & MATERIAL_BACKFACELIGHTING) == 0) || n.y < 0.0f)
        {
            n *= -1.0f;
        }
    }
    //if (!gl_FrontFacing) n *= -1.0f;

    vec3 prev_f_specular = f_specular;

    if (renderprobes)
    {
        int u_MipCount;
        float lod;
        
        {
            //Specular reflection
            if (materialInfo.specularWeight > 0.001f && (RenderFlags & RENDERFLAGS_NO_IBL) == 0)// && ( material.roughness < 0.999f || material.metalness > 0.001f ))
            {   
                if (iblspecular.a < 1.0f && IBLIntensity > 0.0f)
                {
                    u_MipCount = textureQueryLevels(SpecularEnvironmentMap);
                    lod = materialInfo.perceptualRoughness * float(u_MipCount - 1);
                    lod = min(lod, 5);
                    vec3 sky = sRGBToLinear(textureLod(SpecularEnvironmentMap, reflect(-v,n), lod).rgb) * (1.0f - iblspecular.a) * IBLIntensity;
                    iblspecular.rgb += sky;
                }
                //iblspecular *= ao;
                if (iblspecular.r + iblspecular.g + iblspecular.b > 0.0f)
                {
                    f_specular += (getIBLRadianceGGX(Lut_GGX, iblspecular.rgb, n, v, materialInfo.perceptualRoughness, materialInfo.f0, materialInfo.specularWeight));
                }
                //f_specular.r = 1.0f;// for testing...
            }
 
            //Diffuse reflection
            if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
            {
                if (ibldiffuse.a < 1.0f && IBLIntensity > 0.0f)
                {
                    ibldiffuse.rgb += sRGBToLinear(textureLod(DiffuseEnvironmentMap, n, 0.0f).rgb) * (1.0f - ibldiffuse.a) * IBLIntensity;
                }
                //ibldiffuse *= ao;
                if (ibldiffuse.r + ibldiffuse.g + ibldiffuse.b > 0.0f)
                {
                    f_diffuse += (getIBLRadianceLambertian(Lut_GGX, ibldiffuse.rgb, n, v, materialInfo.perceptualRoughness, materialInfo.c_diff, materialInfo.f0, materialInfo.specularWeight));
                }
            }
        }
    }

#endif

    //--------------------------------------------------------------------------
    // Diffuse blend
    //--------------------------------------------------------------------------

    vec3 diffuse = f_diffuse;
    /*if (!Transparency)
    {
        //if ((materialFlags & MATERIAL_BLEND_TRANSMISSION) != 0)
        //{
        //    diffuse = mix(f_diffuse, f_transmission, materialInfo.transmissionFactor);
        //}
        //else
        if ((materialFlags & MATERIAL_BLEND_ALPHA) != 0)
        {
            diffuse = mix(f_transmission, f_diffuse, baseColor.a);
        }
        else
        {
            diffuse = f_diffuse;
        }
    }
    else
    {
        diffuse = f_diffuse;
    }*/

    //--------------------------------------------------------------------------
    // Final blend
    //--------------------------------------------------------------------------

    if ((RenderFlags & RENDERFLAGS_NO_SPECULAR) != 0) f_specular = vec3(0.0f);

    vec3 color = vec3(0.0f);
#ifdef MATERIAL_UNLIT
    color = baseColor.rgb;
#else
    color = diffuse + f_specular;
#ifdef MATERIAL_SHEEN
    color = f_sheen + color * albedoSheenScaling;
#endif
#ifdef MATERIAL_CLEARCOAT
    if (materialInfo.clearcoatFactor > 0.0f)
    {
        vec3 clearcoatFresnel = F_Schlick(materialInfo.clearcoatF0, materialInfo.clearcoatF90, clampedDot(materialInfo.clearcoatNormal, v));
        f_clearcoat *= materialInfo.clearcoatFactor;
        color = color * (1.0f - materialInfo.clearcoatFactor * clearcoatFresnel) + f_clearcoat;
    }
#endif
#endif

    color += f_emissive;

#ifdef DEFERRED_REFLECTIONCOLOR
    //baseColor.a = clamp(baseColor.a, 0.05f, 1.0f);
#endif

    color.rgb = linearTosRGB(color.rgb, InverseGammaLevel);

    //Camera distance fog
    if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(color.rgb, vertexWorldPosition.xyz, CameraPosition);

    outColor[0] = vec4(color.rgb, baseColor.a);

    int attachmentindex = 0;
    
    //Deferred normals
    if ((RenderFlags & RENDERFLAGS_OUTPUT_NORMALS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = n;// * 0.5f + 0.5f;
        outColor[attachmentindex].a = baseColor.a;
    }

    //Deferred metal / roughness
    if ((RenderFlags & RENDERFLAGS_OUTPUT_METALLICROUGHNESS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].r = material.thickness;//float(SPECULARMODEL);
        outColor[attachmentindex].g = materialInfo.perceptualRoughness;
        outColor[attachmentindex].b = materialInfo.metallic;
        outColor[attachmentindex].a = baseColor.a;
#ifdef PREMULTIPLY_AlPHA
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
        {
            outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        }
#endif
    }

    //Deferred base color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ALBEDO) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = linearTosRGB(materialInfo.c_diff);
        outColor[attachmentindex].a = baseColor.a;
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
        //    outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }

    //Deferred Z-position
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ZPOSITION) != 0)
    {
        ++attachmentindex;
        float d = PositionToDepth(vertexCameraPosition.z, CameraRange);
        outColor[attachmentindex] = vec4(d, d, d, 1.0f);
        //outColor[attachmentindex] = vec4(1.0f);
    }

    /*//Deferred specular color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_SPECULAR) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = materialInfo.f0;
        outColor[attachmentindex].a = baseColor.a;
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
         //   outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }
    */

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

    //Clamp alpha
    outColor[0].a = clamp(outColor[0].a, 0.0f, 1.0f);
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) == 0) outColor[0].a = 1.0f;

    //Editor grid
    if ((cameraflags & ENTITYFLAGS_SHOWGRID) != 0)
    {
        if ((entityflags & ENTITYFLAGS_SHOWGRID) != 0) outColor[0].rgb += WorldGrid(vertexWorldPosition.xyz, normal, d);
    }
    
    //Dither final pass
    if (renderprobes)
    {
        if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
        {
            outColor[0].rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
        }
    }

    // Selection mask - This will display selected objects with a transparent red overlay
    //if ((entityflags & ENTITYFLAGS_SELECTED) != 0) outColor[0].rgb = outColor[0].rgb * 0.5f + vec3(0.5f, 0.0f, 0.0f);

    //Pre-multiply alpha
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) outColor[0].rgb *= outColor[0].a;
    
    //outColor[0].a = outColor[0].a * 0.5f + 0.5f;
    //if ((entityflags & ENTITYFLAGS_SELECTED) != 0) outColor[0].a = 0.5f - outColor[0].a;

    //Display paint brush guide
    if (PaintBrushPosition.w > 0.0f)
    {
        float d = length(vertexWorldPosition.xyz - PaintBrushPosition.xyz);
        if (d < PaintBrushPosition.w)
        {
            d /= PaintBrushPosition.w;
            d = (1.0f - d) * 0.25f;
            if (d < 0.02f) d = 1.0f;
            outColor[0] = mix(outColor[0],  vec4(0,1,0,1), d);
        }
    }

    if ( isnan(outColor[0].r) || isnan(outColor[0].g) || isnan(outColor[0].b) || isnan(outColor[0].a)) outColor[0] = vec4(0.0f);
}
