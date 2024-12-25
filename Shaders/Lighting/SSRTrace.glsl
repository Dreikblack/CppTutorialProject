//#define MAX_DISTANCE 16.0f
//#define MAX_DISTANCE_SQUARED (MAX_DISTANCE*MAX_DISTANCE)
#define MAX_STEPS 64
#define MIN_STEP_SIZE 0.1f
#define RAY_SUBSAMPLES 16
#define MAX_ROUGHNESS 0.8f
#define MAX_RAYS 1
#define DEPTH_TOLERANCE 2.0f
#define STEP_DISTANCE_FACTOR 0.05f
#define MAX_JITTER 0.1f

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

#ifdef GBUFFER_MSAA
vec4 SSRTrace(in vec3 position, in vec2 texCoords, in sampler2D diffusemap, in sampler2DMS depthmap, in sampler2DMS normalmapMS, in sampler2D normalmap, in sampler2DMS metalroughnessmap, in sampler2DMS specularcolormap, in int samp)
#else
vec4 SSRTrace(in vec3 position, in vec3 normal, in float roughness, in sampler2D diffusemap, in sampler2D depthmap, out float ssrblend)
#endif
{
    vec2 texCoords;
    ssrblend = 0.0f;
    //CameraProjectionViewMatrix = PrevCameraProjectionViewMatrix;

    texCoords = WorldPositionToScreenCoord(position).xy;

    float lod = roughness * float(textureQueryLevels(diffusemap) - 1);

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
    ivec2 icoord = ivec2((gl_FragCoord.xy / BufferSize) * ntexsize);
	
    if (normal.x == 0.0f and normal.y == 0.0f and normal.z == 0.0f) return vec4(0);
    position += normal * 0.01f;

    vec3 surfacenormal = normal;
    vec4 color = textureLod(diffusemap, texCoords, 0) * 0.5;
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

    //mat4 projectionmatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
    //projectionmatrix *= CameraMatrix;
    //projectionmatrix[1] *= -1.0f;
    //projectionmatrix[2] *= scalemat;
    //mat4 inverseprojectionmatrix = inverse(projectionmatrix);

    ivec2 ic;
    ivec2 pic = ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y);
    vec4 raysample = vec4(0);

#if RAY_SAMPLES > 1
    mat3 raymat = mat4(1.0f);
    raymat[2].xyz = normal;
    raymat[1].xyz = vec3(0,1,0);
    if (dot(raymat[2].xyz, raymat[1].xyz) > 0.5f) raymat[1].xyz = vec3(1,0,0);
    raymat[0].xyz = cross(raymat[2].xyz, raymat[1].xyz);
    raymat[1].xyz = cross(raymat[2].xyz, raymat[0].xyz);
    normal = cross(raymat[0].xyz, raymat[1].xyz);

    float roll = 0;//random(gl_FragCoord.xy * position.xy * position.z) * 3.14159f * 2.0f;
    mat3 rotmat = mat4(1);
    float s = sin(roll);
    float c = cos(roll);
    rotmat[0].x = c; rotmat[0].y = s; rotmat[1].x = -s;
    rotmat[1].y = c; rotmat[2].z = 1.0f;
    raymat *= rotmat;
#endif

    vec3 startposition = position;
    vec3 startnormal = normal;

    //int raycount = 1 + int((roughness / MAX_ROUGHNESS) * float(MAX_RAYS - 1) + 0.5f);

    //if (raycount < 1) raycount = 1;

    //for (int p = 0; p < raycount; ++p)
    {
        position = startposition;
        normal = startnormal;
        stepsize = MIN_STEP_SIZE;//max(MIN_STEP_SIZE, position.z * STEP_DISTANCE_FACTOR);// * max(0.5f, 1.0f - abs(normal.z));
//#if RAY_SAMPLES        
        //if (p > 0 && roughness > 0.0f)
        //{
         //   vec3 jitter = hash(vec3(gl_FragCoord.xy, gl_FragCoord.x * gl_FragCoord.y) * fragposition * float(2.0f) * CurrentTime);// - 0.5f;
         //   normal += jitter * MAX_JITTER;
        //}
//#endif
/*#if RAY_SAMPLES > 1
        //if (p > 0)
        {
            mat4 rotmat = mat4(1.0f);
            float a = radians(22.5f);
            if (p == 2) a *= -1.0f;
            if (p == 0) a = 0;
            float s = sin(-a);
            float c = cos(-a);
            rotmat[0].x = c; rotmat[0].z = s; rotmat[1].y = 1.0f;
            rotmat[2].x = -s; rotmat[2].z = c;
            mat4 m = raymat * rotmat;
            normal = m[2].xyz;
        }
#endif*/

        position += normal * stepsize;// * random(gl_FragCoord.xy);

        for (int n = 0; n < MAX_STEPS; ++n)
        {
            stepsize = stepsize * 1.2f;//max(MIN_STEP_SIZE, position.z * STEP_DISTANCE_FACTOR);
            position += normal * stepsize;

            //screencoord = CameraPositionToScreenCoord(position);
            screencoord = WorldPositionToScreenCoord(position);

            if (screencoord.z < CameraRange.x or screencoord.z > CameraRange.y or screencoord.x < 0.0 or screencoord.x > 1.0 or screencoord.y < 0.0 or screencoord.y > 1.0) break;

            ic.x = int(screencoord.x * texsize.x);
            ic.y = int(screencoord.y * texsize.y);
            if (ic == pic) continue;
            pic = ic;

            float depth = texelFetch(depthmap, ic, samp).r;
            z = DepthToPosition(depth, CameraRange);
            if (z < screencoord.z)
            {
                //Whoa, back up!
                position -= normal * stepsize;
                stepsize /= float(RAY_SUBSAMPLES);
                for (int k = 0; k < RAY_SUBSAMPLES; ++k)
                {
                    position += normal * stepsize;
                    screencoord = WorldPositionToScreenCoord(position);
                    //screencoord = CameraPositionToScreenCoord(position);
                    depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y), samp).r;
                    z = DepthToPosition(depth, CameraRange);
                    if (z < screencoord.z) break;
                }

                if (screencoord.z < z + 0.1f)// * min(cameranormal.z * stepsize * 6.0f, 1.0f))
                {
                    float alpha = 1.0f;// - abs(z - screencoord.z);
                    
                    /*stepsize = max(STEP_SIZE, position.z * STEP_DISTANCE_FACTOR);

                    //Cheap blur effect
                    position += raymat[0].xyz * stepsize * 0.2f;
                    screencoord = CameraPositionToScreenCoord(position);
                    depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y), samp).r;
                    z = DepthToPosition(depth, CameraRange);
                    if (z > screencoord.z) alpha -= 0.333f;

                    position -= raymat[0].xyz * stepsize * 0.2f * 2.0f;
                    screencoord = CameraPositionToScreenCoord(position);
                    depth = texelFetch(depthmap, ivec2(screencoord.x * texsize.x, screencoord.y * texsize.y), samp).r;
                    z = DepthToPosition(depth, CameraRange);
                    if (z > screencoord.z) alpha -= 0.333f;*/

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
            stepsize *= STEP_DELTA;
    #endif
    #ifdef MAX_STEP_SIZE
            stepsize = min(MAX_STEP_SIZE, stepsize);
    #endif
        }
    }
    return raysample;// /= float(raycount);
}