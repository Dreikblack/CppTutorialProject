#version 450
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable

#define MATERIAL_TRANSMISSION

//Includes
#define UNIFORMSTARTINDEX 8
#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Utilities/ISO646.glsl"
#include "../Utilities/DepthFunctions.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/ReconstructPosition.frag"
#include "../Khronos/ibl.glsl"

vec3 mygetTransmissionSample(in sampler2D u_TransmissionFramebufferSampler, ivec2 fragCoord, float roughness, float ior)
{
    float framebufferLod = log2(float(BufferSize.x)) * applyIorToRoughness(roughness, ior);
    //framebufferLod = min(float(textureQueryLevels(u_TransmissionFramebufferSampler))-1.5f, framebufferLod);

    framebufferLod = 0.0f;//roughness * float(textureQueryLevels(u_TransmissionFramebufferSampler) - 1);

    fragCoord.x = clamp(fragCoord.x, 0, DrawViewport.z - 1);
    fragCoord.y = clamp(fragCoord.y, 0, DrawViewport.w - 1);
    vec3 transmittedLight = texelFetch(u_TransmissionFramebufferSampler, fragCoord.xy, 0).rgb;
    //if (framebufferLod > 0.01f)
    //{
    //    transmittedLight = (transmittedLight + textureLod(u_TransmissionFramebufferSampler, fragCoord.xy, 1).rgb) * 0.5f;
    //}
    return transmittedLight;
}

// Uniforms
layout(binding = 0) uniform sampler2D DiffuseTextureID;
layout(binding = 1) uniform sampler2DMS DepthTextureID;
layout(binding = 2) uniform sampler2DMS TransparencyNormalTextureID;
layout(binding = 3) uniform sampler2DMS TransparencyTextureID;
layout(binding = 4) uniform sampler2DMS MetallicRoughnessTextureID;
layout(binding = 5) uniform sampler2DMS ZPositionTextureID;

//Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);

    /*outColor = texelFetch(ZPositionTextureID, coord, gl_SampleID) * 0.5f;
    //vec4 c = texelFetch(TransparencyNormalTextureID, coord, gl_SampleID);
    //outColor.rgb += c.rgb * c.a;
    return;*/

    vec4 csample = texelFetch(TransparencyTextureID, coord, gl_SampleID);

    if (csample.a == 0.0f)
    {
        //Unmodified background
        outColor = texelFetch(DiffuseTextureID, coord, 0);
        return;
    }

    vec2 texCoords = gl_FragCoord.xy / BufferSize;
    vec4 nsample = texelFetch(TransparencyNormalTextureID, coord, gl_SampleID);

    vec3 n = normalize(nsample.xyz);
    vec3 background;
    mat4 u_ModelMatrix = mat4(1.0f);
    mat4 u_ProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
    mat4 u_ViewMatrix = mat4(1.0f);

    //Reconstruct position
    vec3 screenpos;
    screenpos.xy = texCoords;
    screenpos.z = texelFetch(ZPositionTextureID, coord, gl_SampleID).r;

    vec3 v_Position = ScreenCoordToWorldPosition(screenpos);
    screenpos.z = DepthToPosition(screenpos.z, CameraRange);

#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - v_Position);
#else
    vec3 v = normalize(CameraPosition - v_Position);
#endif
    float ior = 1.5f;
    vec3 ray = normalize(v_Position - CameraPosition);
    float glance = 1.0f + dot(ray,n);
    //glance = clamp(glance, 0.0f, 1.0f);
    //vec3 camdir = CameraMatrix[2].xyz;
    //glance = 1.0f - dot(ray, camdir);
    //glance = 1.0f + dot(camdir,n);
    //outColor = vec4(glance);
    //ior = mix(ior, 0.0f, glance);

    vec4 mrsample = texelFetch(MetallicRoughnessTextureID, coord, gl_SampleID);
    //float thickness = mrsample.r;
    float perceptualRoughness = mrsample.g / mrsample.a;
  
    float thickness = nsample.b;

    //thickness = mix(thickness, 0.0, glance);

    float zpositionatrefractedpoint = texelFetch(DepthTextureID, coord, gl_SampleID).r;
    zpositionatrefractedpoint = DepthToPosition(zpositionatrefractedpoint, CameraRange);
    
    float diff = zpositionatrefractedpoint - screenpos.z;

    if (diff < thickness)
    {
        float og = nsample.a;
       nsample.a *= max(0.1, diff / thickness);
       nsample.a = max(og * 0.1f, nsample.a);
    }
    thickness = max(thickness, 0.02);

    thickness = min(thickness, diff);
    //thickness = mix(thickness, 0.0, glance);

    vec3 transmissionRay = getVolumeTransmissionRay(n, v, thickness, ior, u_ModelMatrix);
    vec3 refractedRayExit = v_Position + transmissionRay;

    // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
    vec4 ndcPos = u_ProjectionMatrix * vec4(refractedRayExit, 1.0);
    vec2 refractionCoords_ = ndcPos.xy / ndcPos.w;

    refractionCoords_ += 1.0f;
    refractionCoords_ *= 0.5f;

    //refractionCoords_.x = clamp(refractionCoords_.x, 0.0f, 1.0f);
    //refractionCoords_.y = clamp(refractionCoords_.y, 0.0f, 1.0f);

    //n = inverse(CameraNormalMatrix) * n;
    vec3 sn = n;//mat3(inverse(CameraNormalMatrix)) * n;
    refractionCoords_ = (texCoords.xy - 0.5f) + n.xy * 0.5f * thickness + 0.5f;
    ior = 0;//

    if (refractionCoords_.y < 0.5f)
    {
        float m = refractionCoords_.y / 0.5f;
        refractionCoords_.y = mix(texCoords.y, refractionCoords_.y, m);
    }
    else// if (refractionCoords_.y > 0.5f)
    {
        float m = (refractionCoords_.y - 0.5f) / 0.5f;
        refractionCoords_.y = mix(refractionCoords_.y, texCoords.y, m);
    }
    if (refractionCoords_.x < 0.1f)
    {
        float m = refractionCoords_.x / 0.1f;
        refractionCoords_.x = mix(refractionCoords_.x, texCoords.x, 1.0f - m);
    }
    else if (refractionCoords_.x > 0.9f)
    {
        float m = (refractionCoords_.x - 0.9f) / 0.1f;
        refractionCoords_.x = mix(refractionCoords_.x, texCoords.x, m);
    }

    ivec2 refractionCoords;

    refractionCoords.x = int(refractionCoords_.x * BufferSize.x + 0.5f);
    refractionCoords.y = int(refractionCoords_.y * BufferSize.y + 0.5f);

    refractionCoords.x = clamp(refractionCoords.x, 0, DrawViewport.z);
    refractionCoords.y = clamp(refractionCoords.y, 0, DrawViewport.w);

    /*float zpositionatrefractedpoint = texelFetch(DepthTextureID, refractionCoords, gl_SampleID).r;

    //If depth at refracted texture coordinate is closer than depth at original position, bail out
    if (zpositionatrefractedpoint < zpositionatthispoint)
    {
        zpositionatrefractedpoint = DepthToPosition(zpositionatrefractedpoint, CameraRange);
        zpositionatthispoint = DepthToPosition(zpositionatthispoint, CameraRange);
        if (zpositionatrefractedpoint < zpositionatthispoint + 0.25f)
        {
            refractionCoords = coord;
        }
    }*/

    // Sample framebuffer to get pixel the refracted ray hits.
    //perceptualRoughness = 0;
    //background = mygetTransmissionSample(DiffuseTextureID, refractionCoords, perceptualRoughness, ior);
    background = textureLod(DiffuseTextureID, refractionCoords_.xy, 0).rgb;

    // Experimenting with deep water
    /*const float deeparea = 1.0f;
    if (diff > deeparea)
    {
        const float deeprange = 1.0f;
        nsample.a = mix(nsample.a, 1.0f, min((diff - deeparea) / deeprange, 1.0f));
    }*/

    outColor.rgb = mix(background, csample.rgb, nsample.a);

    //outColor = texelFetch(DiffuseTextureID, coord, 0);
    //return;

    // For water edges, not very apparent on other surfaces
    const float softarea = 0.025;    
    if (diff < softarea)
    {
        float f = 1.0f - diff / softarea;
        f = min(f, 1.0f);
        vec3 bg = texelFetch(DiffuseTextureID, coord, 0).rgb;
        outColor.rgb = mix(outColor.rgb, bg, f);
        outColor.a = f;
    }
   
    outColor.a = 1.0f;
}