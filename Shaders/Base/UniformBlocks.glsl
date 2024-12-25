#ifndef UNIFORM_BLOCKS_GLSL
#define UNIFORM_BLOCKS_GLSL

#include "PushConstants.glsl"
#include "StorageBufferBindings.glsl"
#include "Materials.glsl"

layout(binding = STORAGE_BUFFER_DRAW_INDEXES) readonly buffer InstanceIDBlock { uvec4 instanceID[]; };
#ifdef DOUBLE_FLOAT
layout(binding = STORAGE_BUFFER_MATRICES) readonly buffer EntityMatrixBlock { dmat4 entityMatrix[]; };
#else
layout(binding = STORAGE_BUFFER_MATRICES) readonly buffer EntityMatrixBlock { mat4 entityMatrix[]; };
#endif
layout(binding = STORAGE_BUFFER_PRIMITIVES) readonly buffer primitiveAttributesBlock { uint primitiveAttributes[]; };

#ifdef DOUBLE_FLOAT

dmat4 worldparams = entityMatrix[0];
uint CurrentTime = worldparams[0][0];
vec3 AmbientLight = vec3(worldparams[1].rgb);
uint CurrentFrame = uint(worldparams[1].w);
float RenderInterpolation = float(worldparams[0][1]);
float IBLIntensity = float(worldparams[3][3]);

#else

mat4 worldparams = entityMatrix[0];
uint CurrentTime = floatBitsToUint(worldparams[0][0]);
vec3 AmbientLight = worldparams[1].rgb;
uint CurrentFrame = floatBitsToUint(worldparams[1].w);
float RenderInterpolation = worldparams[0][1];
float IBLIntensity = worldparams[3][3];
Material worldmaterial = materials[floatBitsToInt(worldparams[2][0])];
mat4 worldparams2 = entityMatrix[1];
int pickedterrainiD = floatBitsToInt(worldparams2[0][0]);
vec3 pickedterraintoolposition = worldparams2[0].yzw;
vec2 pickedterraintoolradius = worldparams2[1].xy;
float GridSize = worldparams2[1].z;
int MajorGridLines = floatBitsToInt(worldparams2[1].w);

#endif

#endif