#ifndef _TERRAININFO
    #define _TERRAININFO

#include "../Base/UniformBlocks.glsl"
#include "../Math/FloatPrecision.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Math/FastSqrt.glsl"
#include "../Math/math.glsl"

#define TERRAIN_LAYERS_MATRIX_OFFSET 2

void ExtractEntityInfo(in uint id, out mat4 mat, out uint flags, out int terrainID, out ivec2 patchpos, out uint decallayers)
{
    mat = entityMatrix[id];
    decallayers = floatBitsToUint(mat[1][3]);
    terrainID = floatBitsToInt(mat[2][3]);
    flags = floatBitsToUint(mat[3][3]);
    uvec2 pack = unpackUshort2x16(floatBitsToUint(mat[2][1]));
    patchpos = ivec2(pack.x, pack.y);
    RepairEntityMatrix(mat);
}

struct TerrainLayerInfo
{
    int materialID;
    float scale;
    int mappingmode;
    uint flags;
};

/*void ExtractTerrainLayerInfo(in uint terrainID, in uint index, out TerrainLayerInfo layerinfo)
{
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#else
    mat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#endif
    uint id = index - matindex * 16;
    uint row = id / 4;
    dFloat f = mat[row][id - row * 4];
#ifdef DOUBLE_FLOAT
    uint i = int(f);
#else
    uint i = floatBitsToUint(f);
#endif
    layerinfo.scale = float(i & 0x000000FF) / 256.0f * 64.0f;
    layerinfo.mappingmode = (i & 0x0000FF00) >> 8;
    layerinfo.materialID = (i & 0xFFFF0000) >> 16;
}*/

void ExtractTerrainLayerInfo(in uint terrainID, in uint index, out TerrainLayerInfo layerinfo)
{
    uint matindex = index / 4;
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#else
    mat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#endif
    uint row = index - matindex * 4;
    layerinfo.materialID = floatBitsToInt(mat[row][0]);
    layerinfo.scale = mat[row][1];
    layerinfo.flags = floatBitsToUint(mat[row][2]);
    layerinfo.mappingmode = floatBitsToInt(mat[row][3]);
}

vec4 TerrainSample(in sampler2D tex, in vec3 texcoords, in vec3 normal, in int mappingmode)
{
    const float sharpness = 50.0f;
    normal = abs(normal);
    float sum;
    vec4 color[3];
    if (mappingmode != 1)
    {
        color[1] = texture(tex, texcoords.xz);// horizontal
    }
    if (mappingmode != 0)
    {
        color[0] = texture(tex, texcoords.zy * vec2(1, 10.0));// vertical
        color[2] = texture(tex, texcoords.xy * vec2(1, 10.0));// vertical
    }

    switch (mappingmode)
    {
    case 0://flat
        return color[1];
        break;

    case 1://vertical
        normal.xz = pow(normal.xz, vec2(sharpness));
        sum = normal.x + normal.z;
        if (sum <= 0.0) return (color[0] + color[2]) * 0.5f;
        normal.xz /= sum;
        
        //Uncomment this to see the transition line:
        /*if (normal.x > normal.z)
        {
            normal.xz = vec2(1, 0);
        }
        else
        {
            normal.xz = vec2(0, 1);
        }*/

        return color[0] * normal.x + color[2] * normal.z;
        break;

    case 2://trilinear

        /*if (normal.x + normal.y > normal.y)
        {
            normal.y = 0.0f;
        }
        else
        {
            normal.xz = vec2(0.0f);
        }*/

        // Testing...
        //color[0] = vec4(1,0,0,1);
        //color[1] = vec4(0,1,0,1);
        //color[2] = vec4(0,0,1,1);

        normal.xyz = pow(normal.xyz, vec3(sharpness));
        normal.xyz /= normal.x + normal.y + normal.z;
        return color[0] * normal.x + color[1] * normal.y + color[2] * normal.z;
        
        break;
    }
}

#endif