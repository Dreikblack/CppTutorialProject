#ifndef _KHRONOS_IBL
#define _KHRONOS_IBL

#include "functions.glsl"
#include "../Base/PushConstants.glsl"
#include "Punctual.glsl"

float u_EnvIntensity = 1.0f;
mat3 u_EnvRotation = mat3(1.0f);

vec3 getDiffuseLight(in samplerCube u_LambertianEnvSampler, vec3 n)
{
    return texture(u_LambertianEnvSampler, u_EnvRotation * n).rgb * u_EnvIntensity;
}

vec3 getIBLRadianceGGX(in sampler2D u_GGXLUT, in vec3 specularSample, vec3 n, vec3 v, float roughness, vec3 F0, float specularWeight)
{
    float NdotV = clampedDot(n, v);
    vec3 reflection = normalize(reflect(-v, n));

    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;
    //vec4 specularSample = getSpecularSample(u_GGXEnvSampler, reflection, lod);

    vec3 specularLight = specularSample.rgb;

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera
    vec3 Fr = max(vec3(1.0 - roughness), F0) - F0;
    vec3 k_S = F0 + Fr * pow(1.0 - NdotV, 5.0);
    vec3 FssEss = k_S * f_ab.x + f_ab.y;

    return specularWeight * specularLight * FssEss;
}

vec4 getSpecularSample(in samplerCube u_GGXEnvSampler, vec3 reflection, float lod)
{
    vec3 coord = u_EnvRotation * reflection;
    lod = max(lod, textureQueryLod(u_GGXEnvSampler, coord).y);
    return textureLod(u_GGXEnvSampler, coord, lod) * u_EnvIntensity;
}


vec4 getSheenSample(in samplerCube u_CharlieEnvSampler, vec3 reflection, float lod)
{
    return textureLod(u_CharlieEnvSampler, u_EnvRotation * reflection, lod) * u_EnvIntensity;
}


vec3 getIBLRadianceGGX(in sampler2D u_GGXLUT, in samplerCube u_GGXEnvSampler, vec3 n, vec3 v, float roughness, vec3 F0, float specularWeight)
{
    int u_MipCount = textureQueryLevels(u_GGXEnvSampler);
    float NdotV = clampedDot(n, v);
    float lod = roughness * float(u_MipCount - 1);
    vec3 reflection = normalize(reflect(-v, n));

    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;
    vec4 specularSample = getSpecularSample(u_GGXEnvSampler, reflection, lod);

    vec3 specularLight = specularSample.rgb;

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera
    vec3 Fr = max(vec3(1.0 - roughness), F0) - F0;
    vec3 k_S = F0 + Fr * pow(1.0 - NdotV, 5.0);
    vec3 FssEss = k_S * f_ab.x + f_ab.y;

    return specularWeight * specularLight * FssEss;
}


#ifdef MATERIAL_IRIDESCENCE
vec3 getIBLRadianceGGXIridescence(in sampler2D u_GGXLUT, in samplerCube u_GGXEnvSampler, vec3 n, vec3 v, float roughness, vec3 F0, vec3 iridescenceFresnel, float iridescenceFactor, float specularWeight)
{
    int u_MipCount = textureQueryLevels(u_GGXEnvSampler);
    float NdotV = clampedDot(n, v);
    float lod = roughness * float(u_MipCount - 1);
    vec3 reflection = normalize(reflect(-v, n));

    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;
    vec4 specularSample = getSpecularSample(u_GGXEnvSampler, reflection, lod);

    vec3 specularLight = specularSample.rgb;

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera
    vec3 Fr = max(vec3(1.0 - roughness), F0) - F0;
    vec3 k_S = mix(F0 + Fr * pow(1.0 - NdotV, 5.0), iridescenceFresnel, iridescenceFactor);
    vec3 FssEss = k_S * f_ab.x + f_ab.y;

    return specularWeight * specularLight * FssEss;
}
#endif


#ifdef MATERIAL_TRANSMISSION
vec3 getTransmissionSample(in sampler2D u_TransmissionFramebufferSampler, vec2 fragCoord, float roughness, float ior)
{
    float framebufferLod = log2(float(BufferSize.x)) * applyIorToRoughness(roughness, ior);
    vec3 transmittedLight = textureLod(u_TransmissionFramebufferSampler, fragCoord.xy, framebufferLod).rgb;
    return transmittedLight;
}
#endif


#ifdef MATERIAL_TRANSMISSION
vec3 getIBLVolumeRefraction(in sampler2D u_GGXLUT, in sampler2D u_TransmissionFramebufferSampler, vec3 n, vec3 v, float perceptualRoughness, vec3 baseColor, vec3 f0, vec3 f90,
    vec3 position, mat4 modelMatrix, mat4 viewMatrix, mat4 projMatrix, float ior, float thickness, vec3 attenuationColor, float attenuationDistance)
{
    vec3 transmissionRay = getVolumeTransmissionRay(n, v, thickness, ior, modelMatrix);
    vec3 refractedRayExit = position + transmissionRay;

    // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
    vec4 ndcPos = projMatrix * viewMatrix * vec4(refractedRayExit, 1.0);
    vec2 refractionCoords = ndcPos.xy / ndcPos.w;
    refractionCoords += 1.0;
    refractionCoords /= 2.0;

    // Sample framebuffer to get pixel the refracted ray hits.
    vec3 transmittedLight = getTransmissionSample(u_TransmissionFramebufferSampler, refractionCoords, perceptualRoughness, ior);

    vec3 attenuatedColor = applyVolumeAttenuation(transmittedLight, length(transmissionRay), attenuationColor, attenuationDistance);

    // Sample GGX LUT to get the specular component.
    float NdotV = clampedDot(n, v);
    vec2 brdfSamplePoint = clamp(vec2(NdotV, perceptualRoughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 brdf = texture(u_GGXLUT, brdfSamplePoint).rg;
    vec3 specularColor = f0 * brdf.x + f90 * brdf.y;

    return (1.0 - specularColor) * attenuatedColor * baseColor;
}
#endif


// specularWeight is introduced with KHR_materials_specular
vec3 getIBLRadianceLambertian(in sampler2D u_GGXLUT, in samplerCube u_LambertianEnvSampler, vec3 n, vec3 v, float roughness, vec3 diffuseColor, vec3 F0, float specularWeight)
{
    float NdotV = clampedDot(n, v);
    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0f, 0.0f), vec2(1.0f, 1.0f));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;

    vec3 irradiance = getDiffuseLight(u_LambertianEnvSampler, n);

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera

    vec3 Fr = max(vec3(1.0f - roughness), F0) - F0;
    vec3 k_S = F0 + Fr * pow(1.0f - NdotV, 5.0f);
    vec3 FssEss = specularWeight * k_S * f_ab.x + f_ab.y; // <--- GGX / specular light contribution (scale it down if the specularWeight is low)

    // Multiple scattering, from Fdez-Aguera
    float Ems = (1.0f - (f_ab.x + f_ab.y));
    vec3 F_avg = specularWeight * (F0 + (1.0f - F0) / 21.0f);
    vec3 FmsEms = Ems * FssEss * F_avg / (1.0f - F_avg * Ems);
    vec3 k_D = diffuseColor * (1.0f - FssEss + FmsEms); // we use +FmsEms as indicated by the formula in the blog post (might be a typo in the implementation)

    return (FmsEms + k_D) * irradiance;
}

vec3 getIBLRadianceLambertian(in sampler2D u_GGXLUT, in vec3 irradiance, vec3 n, vec3 v, float roughness, vec3 diffuseColor, vec3 F0, float specularWeight)
{
    float NdotV = clampedDot(n, v);
    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0f, 0.0f), vec2(1.0f, 1.0f));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;

    //vec3 irradiance = getDiffuseLight(u_LambertianEnvSampler, n);

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera

    vec3 Fr = max(vec3(1.0f - roughness), F0) - F0;
    vec3 k_S = F0 + Fr * pow(1.0f - NdotV, 5.0f);
    vec3 FssEss = specularWeight * k_S * f_ab.x + f_ab.y; // <--- GGX / specular light contribution (scale it down if the specularWeight is low)

    // Multiple scattering, from Fdez-Aguera
    float Ems = (1.0f - (f_ab.x + f_ab.y));
    vec3 F_avg = specularWeight * (F0 + (1.0f - F0) / 21.0f);
    vec3 FmsEms = Ems * FssEss * F_avg / (1.0f - F_avg * Ems);
    vec3 k_D = diffuseColor * (1.0f - FssEss + FmsEms); // we use +FmsEms as indicated by the formula in the blog post (might be a typo in the implementation)

    return (FmsEms + k_D) * irradiance;
}

#ifdef MATERIAL_IRIDESCENCE
// specularWeight is introduced with KHR_materials_specular
vec3 getIBLRadianceLambertianIridescence(in sampler2D u_GGXLUT, in samplerCube u_LambertianEnvSampler, vec3 n, vec3 v, float roughness, vec3 diffuseColor, vec3 F0, vec3 iridescenceF0, float iridescenceFactor, float specularWeight)
{
    float NdotV = clampedDot(n, v);
    vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_GGXLUT, brdfSamplePoint).rg;

    vec3 irradiance = getDiffuseLight(u_LambertianEnvSampler, n);

    // Use the maximum component of the iridescence Fresnel color
    // Maximum is used instead of the RGB value to not get inverse colors for the diffuse BRDF
    vec3 iridescenceF0Max = vec3(max(max(iridescenceF0.r, iridescenceF0.g), iridescenceF0.b));

    // Blend between base F0 and iridescence F0
    vec3 mixedF0 = mix(F0, iridescenceF0Max, iridescenceFactor);

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera

    vec3 Fr = max(vec3(1.0 - roughness), mixedF0) - mixedF0;
    vec3 k_S = mixedF0 + Fr * pow(1.0 - NdotV, 5.0);
    vec3 FssEss = specularWeight * k_S * f_ab.x + f_ab.y; // <--- GGX / specular light contribution (scale it down if the specularWeight is low)

    // Multiple scattering, from Fdez-Aguera
    float Ems = (1.0 - (f_ab.x + f_ab.y));
    vec3 F_avg = specularWeight * (mixedF0 + (1.0 - mixedF0) / 21.0);
    vec3 FmsEms = Ems * FssEss * F_avg / (1.0 - F_avg * Ems);
    vec3 k_D = diffuseColor * (1.0 - FssEss + FmsEms); // we use +FmsEms as indicated by the formula in the blog post (might be a typo in the implementation)

    return (FmsEms + k_D) * irradiance;
}
#endif


vec3 getIBLRadianceCharlie(in sampler2D u_CharlieLUT, in samplerCube u_CharlieEnvSampler, vec3 n, vec3 v, float sheenRoughness, vec3 sheenColor)
{
    int u_MipCount = textureQueryLevels(u_CharlieEnvSampler);
    float NdotV = clampedDot(n, v);
    float lod = sheenRoughness * float(u_MipCount - 1);
    vec3 reflection = normalize(reflect(-v, n));

    vec2 brdfSamplePoint = clamp(vec2(NdotV, sheenRoughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    float brdf = texture(u_CharlieLUT, brdfSamplePoint).b;
    vec4 sheenSample = getSheenSample(u_CharlieEnvSampler, reflection, lod);

    vec3 sheenLight = sheenSample.rgb;
    return sheenLight * sheenColor * brdf;
}
#endif