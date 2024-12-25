#version 460
#extension GL_ARB_bindless_texture : enable

#include "../Base/CameraInfo.glsl"
#include "../Base/Materials.glsl"

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
    vec4 basecolor = vec4(1,0,1,1);
    vec3 n;
    
    if (materialID != 0)
    {
        float d = dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));

        const int sides = 32;

        float w = 0.0f;
        float w0, w1, m;
        Material mtl = materials[materialID];
        if (mtl.textureHandle[0] != uvec2(0))
        {
            //ivec3 tsize = textureSize(sampler2DArray(mtl.textureHandle[0]), 0);// using this causes AMD 6600 to stop rendering
            //w = cameraangle / 360.0f * float(tsize.z) + 0.5f;
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
            basecolor = texture(sampler2DArray(mtl.textureHandle[0]), vec3(texcoords.xy, w));            
            if (basecolor.a < mtl.alphacutoff) discard;
        }
    }
}