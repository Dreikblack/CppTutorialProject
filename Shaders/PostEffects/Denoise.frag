//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"
#include "../Utilities/Dither.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Utilities/DepthFunctions.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

//   GLfloat sigma = 11.0f, threshold = .180f, slider = 0.f; //running
//    // GLfloat sigma = 7.0f, threshold = .180f, slider = 0.f; //running
//    GLfloat kSigma = 2.f;

float uSigma = 3.0f;
float uThreshold = 1.0f;
float uKSigma = 2.0f * 0.5;
vec2 wSize = BufferSize;

#define INV_SQRT_OF_2PI 0.39894228040143267793994605993439  // 1.0/SQRT_OF_2PI
#define INV_PI 0.31830988618379067153776752674503
//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D tex     - sampler image / texture
//  vec2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//      kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 

vec4 smartDeNoise(sampler2D tex, vec2 uv, float sigma, float kSigma, float threshold)
{
    float radius = round(kSigma*sigma);
    float radQ = radius * radius;

    float invSigmaQx2 = .5 / (sigma * sigma);      // 1.0 / (sigma^2 * 2.0)
    float invSigmaQx2PI = INV_PI * invSigmaQx2;    // // 1/(2 * PI * sigma^2)

    float invThresholdSqx2 = .5 / (threshold * threshold);     // 1.0 / (sigma^2 * 2.0),
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI / threshold;   // 1.0 / (sqrt(2*PI) * sigma)

    vec4 centrPx = texture(tex,uv); 
    //ivec2 ic = ivec2(uv * textureSize(texture2DSampler[NormalTextureID], 0));
    //vec3 centernormal = texelFetch(texture2DSampler[NormalTextureID], ic, 0).rgb;
    //if (centernormal.x == 0.0f && centernormal.y == 0.0f && centernormal.z == 0.0f) return centrPx;
    //float centerdepth = texelFetch(texture2DSampler[DepthTextureID], ic, 0).r;
    //centerdepth = DepthToPosition(centerdepth, CameraRange);

    float zBuff = 0.0;
    vec4 aBuff = vec4(0.0);
    vec2 size = vec2(textureSize(tex, 0));

    float weight;

    vec2 d;
    for (d.x=-radius; d.x <= radius; d.x++) {
        float pt = sqrt(radQ-d.x*d.x);       // pt = yRadius: have circular trend
        for (d.y=-pt; d.y <= pt; d.y++) {
            
            float blurFactor = exp( -dot(d , d) * invSigmaQx2 ) * invSigmaQx2PI;
            
            vec2 tc = uv+d / size;

            //float sampledepth = textureLod(texture2DSampler[DepthTextureID], tc, 0.0f).r;
            //if (sampledepth >= 1.0f) continue;
weight=1;
            //vec3 samplenormal = textureLod(texture2DSampler[NormalTextureID], tc, 0.0f).rgb;
            //if (samplenormal.x == 0.0f && samplenormal.y == 0.0f && samplenormal.z == 0.0f) continue;
            //weight = dot(centernormal, samplenormal);
            //if (weight <= 0.0f) continue;

            //sampledepth = DepthToPosition(sampledepth, CameraRange);
            //float diff = abs(centerdepth - sampledepth);
            //if (diff > 1.0f) weight *= max(0.0f, 1.0f - (diff - 1.0f) / 1.0f);

            vec4 walkPx =  texture(tex, tc);
            vec4 dC = walkPx-centrPx;
            float deltaFactor = exp( -dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

            zBuff += deltaFactor;
            aBuff += deltaFactor * walkPx;
        }
    }
    if (zBuff <= 0.0f) return centrPx;
    return aBuff/zBuff;
}

//  About Standard Deviations (watch Gauss curve)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  kSigma = 1*sigma cover 68% of data
//  kSigma = 2*sigma cover 95% of data - but there are over 3 times 
//                   more points to compute
//  kSigma = 3*sigma cover 99.7% of data - but needs more than double 
//                   the calculations of 2*sigma


//  Optimizations (description)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  fX = exp( -(x*x) * invSigmaSqx2 ) * invSigmaxSqrt2PI; 
//  fY = exp( -(y*y) * invSigmaSqx2 ) * invSigmaxSqrt2PI; 
//  where...
//      invSigmaSqx2     = 1.0 / (sigma^2 * 2.0)
//      invSigmaxSqrt2PI = 1.0 / (sqrt(2 * PI) * sigma)
//
//  now, fX*fY can be written in unique expression...
//
//      e^(a*X) * e^(a*Y) * c*c
//
//      where:
//        a = invSigmaSqx2, X = (x*x), Y = (y*y), c = invSigmaxSqrt2PI
//
//           -[(x*x) * 1/(2 * sigma^2)]             -[(y*y) * 1/(2 * sigma^2)] 
//          e                                      e
//  fX = -------------------------------    fY = -------------------------------
//                ________                               ________
//              \/ 2 * PI  * sigma                     \/ 2 * PI  * sigma
//
//      now with... 
//        a = 1/(2 * sigma^2), 
//        X = (x*x) 
//        Y = (y*y) ________
//        c = 1 / \/ 2 * PI  * sigma
//
//      we have...
//              -[aX]              -[aY]
//        fX = e      * c;   fY = e      * c;
//
//      and...
//                 -[aX + aY]    [2]     -[a(X + Y)]    [2]
//        fX*fY = e           * c     = e            * c   
//
//      well...
//
//                    -[(x*x + y*y) * 1/(2 * sigma^2)]
//                   e                                
//        fX*fY = --------------------------------------
//                                        [2]           
//                          2 * PI * sigma           
//      
//      now with assigned constants...
//
//          invSigmaQx2   = 1/(2 * sigma^2)
//          invSigmaQx2PI = 1/(2 * PI * sigma^2) = invSigmaQx2 * INV_PI 
//
//      and the kernel vector 
//
//          k = vec2(x,y)
//
//      we can write:
//
//          fXY = exp( -dot(k,k) * invSigmaQx2) * invSigmaQx2PI
//

void main()
{
    if (PostEffectTextureID1 != -1)
    {
        float z = textureLod(texture2DSampler[PostEffectTextureID1], gl_FragCoord.xy / BufferSize, 0).r;
        if (z == 1.0f)
        {
        //    outColor = textureLod(texture2DSampler[PostEffectTexture0], gl_FragCoord.xy / BufferSize, 0);
        //    return;
        }
    }

    outColor = smartDeNoise(texture2DSampler[PostEffectTextureID0], texCoords, uSigma, uKSigma, uThreshold);
    //outColor.rgb += dither(ivec2(gl_FragCoord.xy));
}