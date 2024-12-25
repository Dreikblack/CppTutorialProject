#define MAX_DISTANCE 16.0f
#define MAX_STEPS 256
#define STEP_DELTA 1.05f
#define STEP_SIZE 0.005f
#define MAX_STEP_SIZE 0.1f
#define DEPTH_TOLERANCE 2.0f

#include "../Utilities/ReconstructPosition.frag"
#include "../Math/Math.glsl"
#include "../Khronos/ibl.glsl"
//#include "../Khronos/tonemapping.glsl"

/*float depthSample(in sampler2D t, in vec2 uv)
{
#ifdef BILINEAR_DEPTH_SAMPLING
    vec2 sz = textureSize(t, 0);
    vec2 texelSize = vec2(1.0f) / sz;

    float tl = textureLod(t, uv, 0).r;
    float tr = textureLod(t, uv + vec2(texelSize.x, 0.0), 0).r;
    float bl = textureLod(t, uv + vec2(0.0, texelSize.y), 0).r;
    float br = textureLod(t, uv + texelSize, 0).r;

    tl = DepthToPosition(tl, CameraRange);
    tr = DepthToPosition(tr, CameraRange);
    bl = DepthToPosition(bl, CameraRange);
    br = DepthToPosition(br, CameraRange);

    vec2 f = fract( uv * sz );
    float tA = mix( tl, tr, f.x );
    float tB = mix( bl, br, f.x );
    return mix( tA, tB, f.y );
#else
    float depth = textureLod(t, uv, 0).r;
    return DepthToPosition(depth, CameraRange);
#endif
}*/

#ifdef GBUFFER_MSAA
vec4 SSRTrace(in vec2 texCoords, in sampler2D diffusemap, in sampler2DMS depthmap, in sampler2DMS normalmapMS, in sampler2D normalmap, in sampler2DMS metalroughnessmap, in sampler2DMS specularcolormap, in int samp, out float ssrambiguity)
#else
vec4 SSRTrace(in vec2 texCoords, in sampler2D diffusemap, in sampler2D depthmap, in vec3 normal, in float metallic, in float roughness, in vec3 specularcolor, out float ssrambiguity)
#endif
{
    ssrambiguity = 1.0f;

#ifdef GBUFFER_MSAA
    vec3 position = GetFragmentWorldPosition(depthmap, samp);
#else
    vec3 position = GetFragmentWorldPosition(depthmap);
    int samp = 0;
#endif
    vec3 fragposition = position;

    vec3 screencoord;
    screencoord.xy = texCoords;

    vec3 f_specular = vec3(0.0f);

    if (normal.x == 0.0f and normal.y == 0.0f and normal.z == 0.0f) return vec4(0);

    position += normal * 0.25f;

    normal.x += random(gl_FragCoord.xy * normal.xy * CurrentTime) * 0.1f;
    normal.y += random(gl_FragCoord.yx * normal.zy * CurrentTime * 0.1f) * 0.1f;
    normal.z += random(gl_FragCoord.xy * normal.zx * CurrentTime * 0.2f) * 0.1f;
    normal = normalize(normal);

    //roughness = max(roughness, minroughness);

    //vec3 roffset;
    //roffset.x = random(gl_FragCoord.xy * normal.xy * CurrentTime);
    //roffset.y = random(gl_FragCoord.yx * normal.yz * CurrentTime);
    //roffset.z = random(gl_FragCoord.xy * normal.zy * CurrentTime);
    //normal += roffset * roughness * 5.0f;

    //normal = normalize(normal);

    vec3 surfacenormal = normal;
    vec4 color = textureLod(diffusemap, texCoords, 0) * 0.5;
    //f_specular = color.rgb;

    //if (abs(normal.y) < 0.707f) return;

    vec3 viewdir = normalize(position - CameraPosition);
    normal = reflect(viewdir, normal);

#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - fragposition);
#else
    vec3 v = normalize(CameraPosition - fragposition);
#endif

    vec2 texsize = BufferSize;
    vec2 texelSize = 1.0f / texsize;

    float hit = 0.0f;

    float z;
    vec3 prevscreencoord = WorldPositionToScreenCoord(position);
    vec3 prevposition = position;

    float stepsize = STEP_SIZE;//
    
    vec3 cameranormal = CameraInverseNormalMatrix * normal;
    
    //outColor.rgb = cameranormal * 0.5 + 0.5;
    //return;

    //position += normal / length(cameranormal.xy);

    //Nudge the position off the surface so it doesn't self-detect
    //position += surfacenormal * 0.05f;

    //vec3 f_emissive = vec3(0);

    float speccutoff = 0.0;

    float disttravelled = 0.0f;

    stepsize = 1.0f * texelSize.y / length(cameranormal.xy);

    if (cameranormal.z > -0.9f)
    {
        int countsteps = 0;
        //for (int n = 0; n < MAX_STEPS; ++n)
        while (true)
        {
            ++countsteps;
            
            // This should not happen...
            if (countsteps >= MAX_STEPS)
            {
                //outColor = vec4(1,0,1,1);
                break;
            }
            
            disttravelled += stepsize;
            if (disttravelled >= MAX_DISTANCE) break;

            position += normal * stepsize;
            screencoord = WorldPositionToScreenCoord(position);
            
            //screencoord.xy += cameranormal.xy * texelSize;
            //screencoord.z += cameranormal.z;
            //position = ScreenCoordToWorldPosition(screencoord);

            if (screencoord.z < CameraRange.x or screencoord.x < 0.0 or screencoord.x > 1.0 or screencoord.y < 0.0 or screencoord.y > 1.0)
            {
                //ssrambiguity = 0.0f;
                break;
            }
//#ifdef GBUFFER_MSAA
            float depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x + 0.0f, screencoord.y * texsize.y + 0.0f), 0).r;//textureLod(depthmap, screencoord.xy, 0).r;
//#else
//            float depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x + 0.5f, screencoord.y * texsize.y + 0.5f), 0).r;//textureLod(depthmap, screencoord.xy, 0).r;
//#endif
            z = DepthToPosition(depth, CameraRange);
            //z = depthSample(texture2DSampler[DepthTextureID], screencoord.xy);
            if (screencoord.z > CameraRange.y *0.99f) break;

            if (screencoord.z > z)
            {
                if (screencoord.z < z + cameranormal.z * stepsize * 6.0)
                {
                    float alpha = 1.0f - length(screencoord.y - 0.5) * 6.0f;
                    if (alpha > 0.5f) alpha = 1.0f;
                    vec2 dCoords = smoothstep(0.2f, 0.6f, abs(vec2(0.5f) - screencoord.xy));
                    alpha = clamp(1.0f - (dCoords.x + dCoords.y), 0.0f, 1.0f);

                    if (disttravelled > MAX_DISTANCE * 0.9f)
                    {
                        alpha *= 1.0f - float(disttravelled - MAX_DISTANCE * 0.9f) / float(MAX_DISTANCE * 0.1f);
                    }
                    //ssrambiguity = 0.0f;// - alpha;

                    float diff = (z - screencoord.z) / (stepsize * 2.0);
                    //alpha *= 1.0f - diff;

                    //vec3 nsample = normalize(textureLod(normalmap, screencoord.xy, 0).rgb);
                    //if (dot(nsample, normal) < 0.0f)
                    {
                        //float d = min(dot(-viewdir, nsample) * 100.0f, 1.0f);
                        vec3 diffuse = vec3(1);//textureLod(diffusemap, screencoord.xy, 0).rgb;
                        
                        //Reflections in reflections!!!
                        /*if (EnvironmentMap_Specular != -1)
                        {
                            vec3 mrsample = textureLod(texture2DSampler[MetallicRoughnessTextureID], screencoord.xy, 0).rgb;
                            int u_MipCount = textureQueryLevels(textureCubeSampler[EnvironmentMap_Specular]);
                            roughness = mrsample.y;
                            float lod = roughness * float(u_MipCount - 1);
                            vec3 norm = textureLod(normalmap, screencoord.xy, 0).rgb;
                            vec3 reflection = reflect(normalize(position - CameraPosition),norm);
                            vec3 speccolor = textureLod(texture2DSampler[SpecularColorTextureID], screencoord.xy, 0).rgb;
                            diffuse.rgb += textureLod(textureCubeSampler[EnvironmentMap_Specular], reflection, lod).rgb * speccolor;
                        }*/
                        f_specular += diffuse * alpha;
                        hit += alpha;
                        
                    }
                    //else
                    {
                        //ssrambiguity = 1.0f;
                    }
                }
                else
                {
                    //ssrambiguity = 0.0f;
                }
                break;

                /*float l2 = length(screencoord.xy - prevscreencoord.xy);
                int substeps = 8;//max(1, int(l2));
                position = prevposition;
                screencoord = prevscreencoord;
                float substepsize = stepsize / float(substeps);
                float tolerance = DEPTH_TOLERANCE / float(substeps);
                for (int m = 0; m < substeps; ++m)
                {
                    position += normal * substepsize;
                    screencoord = WorldPositionToScreenCoord(position);
                    //depth = textureLod(texture2DSampler[DepthTextureID], screencoord.xy, 0).r;
                    //z = DepthToPosition(depth, CameraRange);
                    z = depthSample(texture2DSampler[DepthTextureID], screencoord.xy);
                    if (screencoord.z > z and screencoord.z < z + tolerance)
                    {
                        if (depth < CameraRange.y)
                        {
                            vec2 dCoords = smoothstep(0.2, 0.6, abs(vec2(0.5, 0.5) - screencoord.xy));
                            float alpha = clamp(1.0 - (dCoords.x + dCoords.y), 0.0, 1.0);
                            color.rgb += textureLod(texture2DSampler[DiffuseTextureID], screencoord.xy, 0).rgb * alpha * specularcolor;
                            break;
                        }
                    }
                }
                break;*/
            }

            stepsize = min(MAX_STEP_SIZE, stepsize * STEP_DELTA);
            prevscreencoord = screencoord;
            prevposition = position;
        }
    }
    return vec4(f_specular, hit);
}