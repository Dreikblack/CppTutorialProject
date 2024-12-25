#ifndef _ENTITYINFO
    #define _ENTITYINFO

#include "UniformBlocks.glsl"
#include "../Math/FloatPrecision.glsl"
#include "../Math/Math.glsl"

// Entity state flags
const int ENTITYFLAGS_NOFOG = 1;
const int ENTITYFLAGS_STATIC = 2;
const int ENTITYFLAGS_MATRIXNORMALIZED = 4;
const int ENTITYFLAGS_EXTENDEDDATA = 1024;
const int ENTITYFLAGS_SHOWGRID = 64;
const int ENTITYFLAGS_SPRITE = 128;

#define ENTITYFLAGS_SUBDIVISION 2147483648u

const int ENTITYFLAGS_PARTICLEVIEWMODE_VELOCITY = 256;

const int ENTITYFLAGS_LIGHT_LINEARFALLOFF = 8;
const int ENTITYFLAGS_LIGHT_DIRECTIONAL = 16;
const int ENTITYFLAGS_LIGHT_SPOT = 32;
const int ENTITYFLAGS_LIGHT_STRIP = 64;
const int ENTITYFLAGS_LIGHT_BOX = 128;
const int ENTITYFLAGS_LIGHT_PROBE = 256;
const int ENTITYFLAGS_LIGHT_DECAL = 512;

const int ENTITYFLAGS_CAMERA_PERSPECTIVE_PROJECTION = 8;

const int ENITYFLAGS_CAMERA_SSR = 64;

//Sprite view modes
const int SPRITEVIEW_DEFAULT = 0;
const int SPRITEVIEW_BILLBOARD = 1;
const int SPRITEVIEW_XROTATION = 2;
const int SPRITEVIEW_YROTATION = 3;
const int SPRITEVIEW_ZROTATION = 4;

#define ONE_OVER_255 0.003921568627f
#define MAX_ENTITY_COLOR (ONE_OVER_255 * 8.0f)
#define MAX_ENTITY_VELOCITY (ONE_OVER_255 * 10.0f * 0.5f)
#define MAX_ENTITY_TEXTURE_SCALE (ONE_OVER_255 * 16.0f * 0.5f)
#define PIf 3.1415926538f

struct EntityInfo
{
    mat4 matrix;
    uint flags;
    uint renderlayers;
    uint decallayers;
    int skeletonid;
    vec4 color;
    vec3 emissioncolor;
    vec2 textureoffset;
    vec2 texturescale;
    float texturerotation;
};

struct EntityExtras
{
    vec3 emissioncolor;
    vec2 textureoffset;
    vec2 texturescale;
    float texturerotation;
};

EntityExtras ExtractEntityExtras(in uint id)
{
    EntityExtras info;
    mat4 exmat = entityMatrix[id + 1];
    info.emissioncolor.rg = unpackHalf2x16(floatBitsToUint(exmat[0][2]));
    vec2 v = unpackHalf2x16(floatBitsToUint(exmat[0][3]));
    info.emissioncolor.b = v.x;
    info.texturerotation = v.y; 
    info.textureoffset = unpackHalf2x16(floatBitsToUint(exmat[1][0]));
    info.texturescale = unpackHalf2x16(floatBitsToUint(exmat[1][1]));
    return info;
}

void RepairEntityMatrix(inout mat4 mat)
{
    mat[2].xyz = cross(mat[0].xyz, mat[1].xyz) * mat[2][0];
    mat[0][3] = 0.0f; mat[1][3] = 0.0f; mat[2][3] = 0.0f; mat[3][3] = 1.0f;
}

mat4 ExtractEntityMatrix(in uint id)
{
    mat4 mat = entityMatrix[id];
    RepairEntityMatrix(mat);
    return mat;
}

EntityInfo ExtractEntityInfo(in uint id)
{
    EntityInfo info;
    info.matrix = entityMatrix[id];
    info.renderlayers = floatBitsToUint(info.matrix[0][3]);
    info.decallayers = floatBitsToUint(info.matrix[1][3]);
    info.skeletonid = floatBitsToInt(info.matrix[2][3]);
    info.flags = floatBitsToUint(info.matrix[3][3]);    
    info.color.rg = unpackHalf2x16(floatBitsToUint(info.matrix[2][1]));
    info.color.ba = unpackHalf2x16(floatBitsToUint(info.matrix[2][2]));

    if ((info.flags & ENTITYFLAGS_EXTENDEDDATA) == 0)
    {
        info.emissioncolor = vec3(1.0f);
        info.textureoffset = vec2(0.0f);
        info.texturescale = vec2(1.0f);
        info.texturerotation = 0.0f;
    }
    else
    {
        mat4 exmat = entityMatrix[id + 1];
        info.emissioncolor.rg = unpackHalf2x16(floatBitsToUint(exmat[0][2]));
        vec2 v = unpackHalf2x16(floatBitsToUint(exmat[0][3]));
        info.emissioncolor.b = v.x;
        info.texturerotation = v.y; 
        info.textureoffset = unpackHalf2x16(floatBitsToUint(exmat[1][0]));
        info.texturescale = unpackHalf2x16(floatBitsToUint(exmat[1][1]));
    }
    RepairEntityMatrix(info.matrix);
    return info;
}

void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out uvec4 cliprect)
{
    mat = entityMatrix[id];
    flags = floatBitsToUint(mat[3][3]);

    mat4 exmat = entityMatrix[id + 1];
    
    color.rg = unpackHalf2x16(floatBitsToUint(mat[2][1]));
    color.ba = unpackHalf2x16(floatBitsToUint(mat[2][2]));

    cliprect.xy = unpackUshort2x16(floatBitsToUint(exmat[3][0]));
    cliprect.zw = unpackUshort2x16(floatBitsToUint(exmat[3][1]));

    RepairEntityMatrix(mat);
}

uint ExtractEntityFlags(in uint id)
{
    mat4 mat = entityMatrix[id];
    return floatBitsToUint(mat[3][3]);
}

void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out uint decallayers)
{
    uint rgba, rgba1;
    mat = entityMatrix[id];
    flags = floatBitsToUint(mat[3][3]);
    decallayers = floatBitsToUint(mat[1][3]);
    color.rg = unpackHalf2x16(floatBitsToUint(mat[2][1]));
    color.ba = unpackHalf2x16(floatBitsToUint(mat[2][2]));
    RepairEntityMatrix(mat);
}

//Gets skeleton or terrain ID
int ExtractEntitySkeletonID(in uint id)
{
    mat4 mat = entityMatrix[id];
    return floatBitsToInt(mat[2][3]);
}

void ExtractEntityInfo(in uint id, out mat4 mat, out uint flags, out int skeletonID)
{
    mat = entityMatrix[id];
    skeletonID = floatBitsToInt(mat[2][3]);
    flags = floatBitsToInt(mat[3][3]);
    RepairEntityMatrix(mat);
}

void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out int skeletonID)
{
    mat = entityMatrix[id];
    skeletonID = floatBitsToInt(mat[2][3]);
    flags = floatBitsToUint(mat[3][3]);
    color.rg = unpackHalf2x16(floatBitsToUint(mat[2][1]));
    color.ba = unpackHalf2x16(floatBitsToUint(mat[2][2]));
    RepairEntityMatrix(mat);
}

void ExtractEntityInfo(in uint id, out mat4 mat, out int skeletonID)
{
    mat = entityMatrix[id];
    skeletonID = floatBitsToInt(mat[2][3]);
    RepairEntityMatrix(mat);
}

void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out int skeletonID, out vec4 texturemapping, out vec3 velocity, out vec3 omega)
{
    mat = entityMatrix[id];
    skeletonID = floatBitsToInt(mat[2][3]);
    skeletonID = floatBitsToInt(mat[2][3]);
    flags = floatBitsToUint(mat[3][3]);

    color.rg = unpackHalf2x16(floatBitsToUint(mat[2][1]));
    color.ba = unpackHalf2x16(floatBitsToUint(mat[2][2]));

    if ((flags & ENTITYFLAGS_EXTENDEDDATA) == 0)
    {
        texturemapping = vec4(0.0f, 0.0f, 1.0f, 1.0f);
    }
    else
    {
        mat4 exmat = entityMatrix[id + 1];
        //emission.rg = unpackHalf2x16(floatBitsToUint(exmat[0][2]));
        //emission.b = unpackHalf2x16(floatBitsToUint(exmat[0][3])).x;
        texturemapping.xy = unpackHalf2x16(floatBitsToUint(exmat[1][0]));
        texturemapping.zw = unpackHalf2x16(floatBitsToUint(exmat[1][1]));
    }
    RepairEntityMatrix(mat);
    velocity = vec3(0.0f);
    omega = vec3(0.0f);
}

#endif
