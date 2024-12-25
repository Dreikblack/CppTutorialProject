#version 460
#extension GL_ARB_bindless_texture : enable

uint decallayers = 0;

#include "../Base/CameraInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Khronos/functions.glsl"
#include "../Khronos/brdf.glsl"
#include "../Khronos/material_info.glsl"
#include "../Khronos/ibl.glsl"
#include "../Khronos/tonemapping.glsl"
#include "../Base/CameraInfo.glsl"
#include "../PBR/Lighting.glsl"

layout(location = 0) out vec4 outcolor;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec3 tangent;
layout(location = 4) in vec3 bitangent;
layout(location = 2) in vec4 texcoords; 
layout(location = 5) in flat uvec4 materialIDs;
layout(location = 7) in vec4 vertexWorldPosition;

uint materialID = materialIDs[0];

layout(location = 30) flat in vec3 suncolor;
layout(location = 31) flat in vec3 sundirection;
layout(location = 29) flat in float cameraangle;

const uint ditherpattern[64] = {
    1, 32,  8, 40,  2, 34, 10, 42,   /* 8x8 Bayer ordered dithering  */
    48, 16, 56, 24, 50, 18, 58, 26,  /* pattern.  Each input pixel   */
    12, 44,  4, 36, 14, 46,  6, 38,  /* is scaled to the 0..63 range */
    60, 28, 52, 20, 62, 30, 54, 22,  /* before looking in this table */
    3, 35, 11, 43,  1, 33,  9, 41,   /* to determine the action.     */
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21 };

float dither(ivec2 coord)
{
	int dithercoord = coord.x * 8 + coord.y;
	dithercoord = dithercoord % 64;
	return float(ditherpattern[dithercoord]) / 63.0f;
}

void main()
{
    vec4 basecolor = vec4(1,1,1,1);
    vec3 n;

    MaterialInfo materialinfo;
    materialinfo.f0 = vec3(0.04f);
    materialinfo.f90 = vec3(1.0);
    materialinfo.specularWeight = 1.0f;
    materialinfo.c_diff = basecolor.rgb;
    materialinfo.metallic = 0.0f;
    materialinfo.perceptualRoughness = 1.0f;
    materialinfo.f90 = vec3(1.0f);

    if (materialID == 0)
    {
        outcolor = vec4(1,0,1,1);
        return;
    }

    Material mtl;

    if (materialID != 0)
    {
        float d = dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));

        const int sides = 32;

        float w = 0.0f;
        float w0, w1, m;
        mtl = materials[materialID];

        w = cameraangle / 360.0f * float(sides);
        w0 = int(w);
        w1 = w0 + 1;
        w0 = mod(w0, float(sides));
        w1 = mod(w1, float(sides));
        m = mod(w, 1.0f);
        if (d > m)
        {
            w = w0;
        }
        else
        {
            w = w1;
        }

        // Base color texture
        if (mtl.textureHandle[0] != uvec2(0))
        {
            basecolor = texture(sampler2DArray(mtl.textureHandle[0]), vec3(texcoords.xy, w));
            basecolor.rgb = sRGBToLinear(basecolor.rgb);
            if (basecolor.a < mtl.alphacutoff) discard;
        }
        materialinfo.baseColor = basecolor.rgb;

        // Normal map
        if (mtl.textureHandle[1] != uvec2(0))
        {
            n = (texture(sampler2DArray(mtl.textureHandle[1]), vec3(texcoords.xy, w)).rgb * 2.0f - 1.0f);
            mat3 nmat = mat3(tangent, bitangent, normal);
            n = nmat * n;
            n = normalize(n);
        }

        // Metallic-roughness map
        if (mtl.textureHandle[TEXTURE_METALLICROUGHNESS] != uvec2(0))
        {
            vec4 mrsample = texture(sampler2DArray(mtl.textureHandle[TEXTURE_METALLICROUGHNESS]), vec3(texcoords.xy, w));
            materialinfo.metallic = mrsample.b;
            materialinfo.perceptualRoughness = mrsample.g;
        }
        materialinfo.perceptualRoughness = clamp(materialinfo.perceptualRoughness, 0.0f, 1.0f);
        materialinfo.metallic = clamp(materialinfo.metallic, 0.0f, 1.0f);    
        materialinfo.alphaRoughness = materialinfo.perceptualRoughness * materialinfo.perceptualRoughness;

        // Achromatic f0 based on IOR.
        materialinfo.c_diff = mix(materialinfo.baseColor.rgb,  vec3(0.0f), materialinfo.metallic);
        materialinfo.f0 = mix(materialinfo.f0, materialinfo.baseColor.rgb, materialinfo.metallic);       
    }

    vec3 f_diffuse = vec3(0.0f);
    vec3 f_specular = vec3(0.0f);
    vec3 cnv = normalize(CameraPosition - vertexWorldPosition.xyz);
    dFloat NdotV = dot(n, cnv);
    vec4 ibldiffuse = vec4(0);
    vec4 iblspecular = vec4(0);

    //outcolor.rgb = n;
    //return;

    vec3 emission = vec3(0.0);
    RenderLighting(mtl, materialinfo, vertexWorldPosition.xyz, n, n, cnv, NdotV, f_diffuse, f_specular, true, ibldiffuse, iblspecular, emission);

    //outcolor.rgb = linearTosRGB(f_specular, InverseGammaLevel);
    //return;

    //if (dot(n, sundirection) < 0.0f)
    if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
    {  
        if (iblspecular.a < 1.0f && IBLIntensity > 0.0f)
        {
            //u_MipCount = textureQueryLevels(samplerCube(EnvironmentMap_Specular));
            uint u_MipCount = textureQueryLevels(SpecularEnvironmentMap);
            float lod = materialinfo.perceptualRoughness * float(u_MipCount - 1);
            lod = min(lod, 5.0f);
            //vec3 sky = textureLod(samplerCube(EnvironmentMap_Specular), reflect(-v,n), lod).rgb * (1.0f - iblspecular.a) * IBLIntensity;
            vec3 sky = sRGBToLinear(textureLod(SpecularEnvironmentMap, reflect(-cnv,n), lod).rgb) * (1.0f - iblspecular.a) * IBLIntensity;
            //const float maxbrightness = 16.0f;
            //sky.r = min(sky.r, maxbrightness);
            //sky.g = min(sky.g, maxbrightness);
            //sky.b = min(sky.b, maxbrightness);
            iblspecular.rgb += sky;
        }
        //iblspecular *= ao;
        if (iblspecular.r + iblspecular.g + iblspecular.b > 0.0f)
        {
            f_specular += (getIBLRadianceGGX(Lut_GGX, iblspecular.rgb, n, cnv, materialinfo.perceptualRoughness, materialinfo.f0, materialinfo.specularWeight));
        }
        
        //Diffuse reflection
        vec3 ibldiffuse;
        if (IBLIntensity > 0.0f)
        {
            ibldiffuse += sRGBToLinear(textureLod(DiffuseEnvironmentMap, n, 0.0f).rgb) * IBLIntensity;
        }
        if (ibldiffuse.r + ibldiffuse.g + ibldiffuse.b > 0.0f)
        {
            f_diffuse += getIBLRadianceLambertian(Lut_GGX, ibldiffuse, n, cnv, materialinfo.perceptualRoughness, materialinfo.c_diff, materialinfo.f0, materialinfo.specularWeight);
        }
    }

    f_diffuse += sRGBToLinear(AmbientLight) * materialinfo.baseColor.rgb;

    outcolor.rgb = f_diffuse + f_specular;
    outcolor.a = basecolor.a;

    outcolor.rgb = linearTosRGB(outcolor.rgb);

    //Camera distance fog
    //if ((entityflags & ENTITYFLAGS_NOFOG) == 0)
    ApplyDistanceFog(outcolor.rgb, vertexWorldPosition.xyz, CameraPosition);
}