//#define MAX_DISTANCE 16.0f
//#define MAX_DISTANCE_SQUARED (MAX_DISTANCE*MAX_DISTANCE)
#define MAX_STEPS 64
#define MIN_STEP_SIZE 0.05f
#define RAY_SUBSAMPLES 16
#define MAX_ROUGHNESS 0.8f
#define MAX_RAYS 1
//#define STEP_DISTANCE_FACTOR 0.05f
//#define MAX_JITTER 0.1f
#define STEP_DELTA 1.1f
#define DEPTH_ERROR 0.0f

#include "../Math/Math.glsl"
#include "../Khronos/ibl.glsl"
#include "../Utilities/ReconstructPosition.glsl"

vec3 hash(vec3 a)
{
    const vec3 Scale = vec3(0.8f);
    const float K = 19.19f;
    a = fract(a * Scale);
    a += dot(a, a.yxz + K);
    return fract((a.xxy + a.yxx)*a.zyx);
}

//mat3 samplepattern[4] = { mat3(vec3(1,0,1), vec3(0), vec3(1,1,1)), mat3(vec3(0), vec3(1,0,1), vec3(1,1,1)) };

vec4 SSRTrace(in vec3 position, in vec3 normal, in float roughness, in sampler2D diffusemap, in sampler2D depthmap, out float ssrblend)
{
    vec2 texCoords;
    ssrblend = 0.0f;
    mat4 temp = CameraProjectionViewMatrix;
    CameraProjectionViewMatrix = PrevCameraProjectionViewMatrix;

    texCoords = WorldPositionToScreenCoord(position).xy;
    //if ((RenderFlags & 4096) != 0)
    //texCoords.y = 1.0f - texCoords.y;

    //ssrblend=1;
    //return vec4(texCoords,0,1);

    float lod = roughness * 2.0f * float(textureQueryLevels(diffusemap) - 1);

#ifndef GBUFFER_MSAA
    int samp = 0;
#endif
    vec3 fragposition = position;
    vec3 screencoord;
    screencoord.xy = texCoords;
    vec3 f_specular = vec3(0.0f);
#ifdef GBUFFER_MSAA
    vec2 ntexsize = textureSize(diffusemap);
#else
    vec2 ntexsize = textureSize(diffusemap, 0);
#endif
    //ivec2 icoord = ivec2(gl_FragCoord.x, gl_FragCoord.y);//ivec2((gl_FragCoord.xy / BufferSize) * ntexsize);
	
    if (normal.x == 0.0f and normal.y == 0.0f and normal.z == 0.0f) return vec4(0);
    position += normal * 0.01f;

    vec3 surfacenormal = normal;
    //vec4 color = textureLod(diffusemap, texCoords, 0) * 0.5;
    vec3 viewdir = normalize(position - CameraPosition);
    normal = reflect(viewdir, normal);

#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - fragposition);
#else
    vec3 v = normalize(CameraPosition - fragposition);
#endif

#ifdef GBUFFER_MSAA
    vec2 texsize = vec2(textureSize(depthmap));
#else
    vec2 texsize = vec2(textureSize(depthmap, 0));
#endif

    vec2 texelSize = 1.0f / texsize;
    //vec3 specularcolor = texelFetch(specularcolormap, icoord, samp).rgb;
    float hit = 0.0f;
    float z;
    //vec3 prevscreencoord = WorldPositionToScreenCoord(position);
    vec3 prevposition = position;
    float stepsize;// = STEP_SIZE;
    //vec3 cameranormal = CameraInverseNormalMatrix * normal;    
    float speccutoff = 0.0;
    float disttravelled = 0.0f;
    vec3 gnormal = normal;
    vec3 gposition = position;
    //position = (CameraInverseMatrix * vec4(position, 1.0f)).xyz;
    //normal = CameraInverseNormalMatrix * normal;

    ivec2 ic;
    ivec2 pic = ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y);
    vec4 raysample = vec4(0);

    vec3 startposition = position;
    vec3 startnormal = normal;

    {
        position = startposition;
        normal = startnormal;
        stepsize = MIN_STEP_SIZE;//max(MIN_STEP_SIZE, position.z * STEP_DISTANCE_FACTOR);// * max(0.5f, 1.0f - abs(normal.z));

        position += normal * stepsize;// * random(gl_FragCoord.xy);

        for (int n = 0; n < MAX_STEPS; ++n)
        {
            stepsize = stepsize * STEP_DELTA;//max(MIN_STEP_SIZE, position.z * STEP_DISTANCE_FACTOR);
            position += normal * stepsize;

            //screencoord = CameraPositionToScreenCoord(position);
            screencoord = WorldPositionToScreenCoord(position);
            
            //if ((RenderFlags & 4096) != 0)
 //           screencoord.y = 1.0f - screencoord.y;

            if (screencoord.z < CameraRange.x or screencoord.z > CameraRange.y or screencoord.x < 0.0 or screencoord.x > 1.0 or screencoord.y < 0.0 or screencoord.y > 1.0) break;

            ic.x = int(screencoord.x * texsize.x);
            ic.y = int(screencoord.y * texsize.y);
            if (ic == pic) continue;
            pic = ic;

            float depth = texelFetch(depthmap, ic, samp).r;
            z = DepthToPosition(depth, CameraRange);
            if (z < screencoord.z - DEPTH_ERROR)
            {
                //Whoa, back up!
                position -= normal * stepsize;
                stepsize /= float(RAY_SUBSAMPLES);
                for (int k = 0; k < RAY_SUBSAMPLES; ++k)
                {
                    position += normal * stepsize;
                    screencoord = WorldPositionToScreenCoord(position);

                    //if ((RenderFlags & 4096) != 0)
//                    screencoord.y = 1.0f - screencoord.y;

                    //screencoord = CameraPositionToScreenCoord(position);
                    depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y), samp).r;
                    z = DepthToPosition(depth, CameraRange);
                    if (z < screencoord.z) break;
                }

                if (screencoord.z < z + 1.0f)// * min(cameranormal.z * stepsize * 6.0f, 1.0f))
                {
                    float alpha = 1.0f;// - abs(z - screencoord.z);
                    
                    //Distance fade
                    alpha *= 1.0f - abs(z - screencoord.z) / 0.5f;               
                    alpha = clamp(alpha, 0.0f, 1.0f);

                    //Screen position fade
                    vec2 dCoords = smoothstep(0.2f, 0.6f, abs(vec2(0.5f) - screencoord.xy));
                    alpha *= clamp(1.0f - (dCoords.x + dCoords.y), 0.0f, 1.0f);

                    //Distance fade
                    if (n > MAX_STEPS * 3 / 4)
                    {
                        alpha *= 1.0f - (float(n) - float(MAX_STEPS) * 0.75f) / (float(MAX_STEPS) * 0.25f);
                    }

                    //dist = sqrt(dist);
                    //if (dist > MAX_DISTANCE * 0.75f)
                    //{
                    //    alpha *= 1.0f - (dist - MAX_DISTANCE * 0.75f) / (MAX_DISTANCE * 0.25f);
                    //}
                    //vec3 nsample = normalize(textureLod(normalmap, screencoord.xy, 0).rgb);
                    //float dp = dot(nsample, gnormal);
                    //if (dp < 0.0f)
                    {
                        //alpha *= clamp(-dp / 0.1f, 0.0f, 1.0f);
                        ssrblend = alpha;
                        return textureLod(diffusemap, screencoord.xy, lod);
                    }
                }
                break;
            }
    #ifdef STEP_DELTA
            //stepsize *= STEP_DELTA;
    #endif
    #ifdef MAX_STEP_SIZE
            stepsize = min(MAX_STEP_SIZE, stepsize);
    #endif
        }
    }

    CameraProjectionViewMatrix = temp;

    return raysample;// /= float(raycount);
}