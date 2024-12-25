#ifndef _CAMERAINFO
    #define _CAMERAINFO

#include "EntityInfo.glsl"
#include "UniformBlocks.glsl"
#include "PushConstants.glsl"

//#define CAMERA_INFO_OFFSET 1
//#define CAMERA_INFO2_OFFSET 2
//#define CAMERA_INVERSE_MATRIX_OFFSET 3
//#define CAMERA_ORTHO_MATRIX_OFFSET 4
//#define CAMERA_PROJECTION_MATRIX_OFFSET 5

#define CAMERA_INFO_OFFSET (1 + 1)
#define CAMERA_INFO2_OFFSET (2 + 1)
#define CAMERA_INVERSE_MATRIX_OFFSET (3 + 1)
#define CAMERA_ORTHO_MATRIX_OFFSET (4 + 1)
#define CAMERA_PROJECTION_MATRIX_OFFSET (5 + 1)
#define CAMERA_FRUSTUM_OFFSET (9 + 1)

bool ExtractCameraFogSettings(in uint cameraID, out vec4 color, out vec2 range, out vec2 angles)
{
    mat4 info = entityMatrix[cameraID + CAMERA_INFO2_OFFSET];
    color = info[0];
    if (color.a <= 0.0f) return false;
    range = info[1].xy;
    angles = info[1].zw;
    return true;
}

void ApplyDistanceFog(inout vec3 color, in vec3 fragpos, in vec3 campos)
{
    vec4 fogcolor;
    vec2 fogrange, fogangles;
    if (ExtractCameraFogSettings(CameraID, fogcolor, fogrange, fogangles))
    {
        float l = length(fragpos - campos);
        l = (l - fogrange.x) / (fogrange.y - fogrange.x);
        l = clamp(l, 0.0f, 1.0f) * fogcolor.a;
        if (l > 0.0f)
        {
            color.rgb = fogcolor.rgb * l + color.rgb * (1.0f - l);
        }
    }
}

int ExtractCameraGICameraID(in uint cameraID, in int index)
{
    int gicamid = -1;
    switch (index)
    {
        case 0:
            gicamid = floatBitsToInt(entityMatrix[cameraID + CAMERA_INFO_OFFSET][0][0]);
            break;
    }
    return gicamid;
}

uint ExtractCameraGIRenderTime(in uint cameraID)
{
    return floatBitsToUint(entityMatrix[cameraID + CAMERA_INFO2_OFFSET][3][3]);
}

uint ExtractCameraGILatency(in uint cameraID)
{
    return floatBitsToUint(entityMatrix[cameraID + CAMERA_INFO2_OFFSET][3][2]);
}

vec3 ExtractCameraGIComputePosition(in uint cameraID)
{
    return entityMatrix[cameraID + CAMERA_INFO2_OFFSET][0].xyz;
}

vec3 ExtractCameraGIRenderPosition(in uint cameraID, in int index)
{
    return entityMatrix[cameraID + CAMERA_INFO2_OFFSET][1 + index].xyz;
}

mat4 ExtractCameraProjectionMatrix(in uint cameraID, in int eye)
{
    if (eye > 5) return mat4(0.0f);
    return entityMatrix[cameraID + CAMERA_PROJECTION_MATRIX_OFFSET + eye];
}

mat4 ExtractCameraInverseMatrix(in uint cameraID)
{
    return entityMatrix[cameraID + CAMERA_INVERSE_MATRIX_OFFSET];
}

mat4 ExtractCameraOrthoMatrix(in uint cameraID)
{
    return entityMatrix[cameraID + CAMERA_ORTHO_MATRIX_OFFSET];
}

mat4 ExtractCameraCullingMatrix(in uint cameraID)
{
    return entityMatrix[cameraID + CAMERA_ORTHO_MATRIX_OFFSET];
}


    #ifdef DOUBLE_FLOAT

dmat4 CameraMatrix = ExtractEntityMatrix(CameraID);
dmat4 CameraInverseMatrix = ExtractCameraInverseMatrix(CameraID);
dmat3 CameraNormalMatrix = mat3(CameraMatrix);
dvec3 CameraPosition = CameraMatrix[3].xyz;
dmat3 CameraInverseNormalMatrix = inverse(CameraNormalMatrix);
dmat4 CameraProjectionViewMatrix = ExtractCameraProjectionMatrix(CameraID);
dmat4 CameraProjectionMatrix = CameraProjectionViewMatrix * CameraMatrix;
dmat4 InverseCameraProjectionViewMatrix = inverse(CameraProjectionViewMatrix);
dmat4 InverseCameraProjectionMatrix = inverse(CameraProjectionMatrix);

    #else

mat4 CameraMatrix = ExtractEntityMatrix(CameraID);
mat4 CameraInverseMatrix = ExtractCameraInverseMatrix(CameraID);
mat3 CameraNormalMatrix = mat3(CameraMatrix);
vec3 CameraPosition = CameraMatrix[3].xyz;
mat3 CameraInverseNormalMatrix = inverse(CameraNormalMatrix);
mat4 CameraProjectionViewMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
mat4 PrevCameraProjectionViewMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex + 2);
mat4 InversePrevCameraProjectionViewMatrix = inverse(PrevCameraProjectionViewMatrix);
mat4 CameraProjectionMatrix = CameraProjectionViewMatrix * CameraMatrix;
mat4 InverseCameraProjectionViewMatrix = inverse(CameraProjectionViewMatrix);
mat4 InverseCameraProjectionMatrix = inverse(CameraProjectionMatrix);
vec3 CameraGIRenderPosition[2] = { entityMatrix[CameraID + CAMERA_INFO2_OFFSET][1].xyz, entityMatrix[CameraID + CAMERA_INFO2_OFFSET][2].xyz};

// Camera frustum
mat4 CameraFrustumMatrix0 = entityMatrix[CameraID + CAMERA_FRUSTUM_OFFSET];
mat4 CameraFrustumMatrix1 = entityMatrix[CameraID + CAMERA_FRUSTUM_OFFSET + 1];
vec4 CameraFrustumPlane0 = CameraFrustumMatrix0[0];
vec4 CameraFrustumPlane1 = CameraFrustumMatrix0[1];
vec4 CameraFrustumPlane2 = CameraFrustumMatrix0[2];
vec4 CameraFrustumPlane3 = CameraFrustumMatrix0[3];
vec4 CameraFrustumPlane4 = CameraFrustumMatrix1[0];
vec4 CameraFrustumPlane5 = CameraFrustumMatrix1[1];

vec4 CameraClipPlane0 = CameraFrustumMatrix1[2];

//vec3 CameraGIComputePosition = entityMatrix[CameraID + CAMERA_INFO2_OFFSET][0].xyz;
//mat4 CameraMatrix = GetEntityMatrix(CameraID);
//mat3 CameraNormalMatrix = mat3(CameraMatrix);

mat4 ExtractCameraInfoMatrix(in uint cameraID, in int index)
{
    //index can be 0 or 1
    return entityMatrix[cameraID + CAMERA_INFO_OFFSET + index];
}

int ExtractCameraGIDisplayMaterialID(in int GICameraID)
{
#ifdef DOUBLE_FLOAT
    dmat4 camerainfomatrix = ExtractCameraInfoMatrix(uint(GICameraID), 0);
    return int(camerainfomatrix[0][1]);
#else
    mat4 camerainfomatrix = ExtractCameraInfoMatrix(uint(GICameraID), 0);
    return floatBitsToInt(camerainfomatrix[0][1]);
#endif
}

mat4 camerainfomatrix = ExtractCameraInfoMatrix(CameraID, 0);
mat4 camerainfo2matrix = ExtractCameraInfoMatrix(CameraID, 1);
vec4 CameraViewport = camerainfomatrix[1];
vec2 CameraRange = camerainfomatrix[2].xy;
float CameraZoom = camerainfomatrix[2].z;
float CameraGamma = camerainfomatrix[2].w;
float GIVoxelSize = camerainfomatrix[0][3];
int CameraGIStages = floatBitsToInt(camerainfomatrix[3][1]);
int GIStage = floatBitsToInt(camerainfomatrix[3][2]);
//vec3 CameraPosition = CameraMatrix[3].xyz;
//vec3 GICameraPosition = vec3(0.0f);
vec3 GICoordinate = camerainfo2matrix[0].xyz;
int CameraGIRenderTextureIndex = floatBitsToInt(camerainfo2matrix[0].w);
vec3 GIRenderOffset = camerainfo2matrix[0].xyz;
int GICameraID = floatBitsToInt(camerainfo2matrix[2].w);
vec3 CameraGIComputePosition = camerainfo2matrix[0].xyz;

    #endif

#endif
