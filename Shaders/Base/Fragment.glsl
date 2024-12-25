#include "../Base/PushConstants.glsl"
#include "../Base/Limits.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Utilities/Dither.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Math/FastSqrt.glsl"

//Inputs
layout(location = 0) in vec4 color;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 texcoords_;
vec4 texcoords = texcoords_;
layout(location = 3) in vec3 tangent;
layout(location = 4) in vec3 bitangent;
layout(location = 5) flat in uvec4 materialIDs;
uint materialID = materialIDs[0];
layout(location = 6) in vec4 vertexCameraPosition;
layout(location = 7) in vec4 vertexWorldPosition;
layout(location = 9) in flat uint entityflags;
layout(location = 10) flat in uint decallayers;
layout(location = 12) flat in vec3 emissioncolor;
layout(location = 26) in vec4 materialweights;
layout(location = 21) flat in int MaxMeshMaterials;

#ifdef PARALLAX_MAPPING
layout(location = 16) in vec3 eyevec;
#endif
#ifdef CLIPPINGREGION
layout(location = 17) in flat uvec4 cliprect;
#endif
layout(location = 25) in flat uint entityID;
layout(location = 23) in vec3 screenvelocity;

layout(location = 8) in vec4 maxDisplacedPosition;

//Outputs
layout(location = 0) out vec4 outColor[8];
/*#ifdef DEFERRED_NORMALS
//layout(location = 1) out vec4 outNormal;
#endif
#ifdef DEFERRED_Z_POSITION
layout(location = DEFERRED_Z_POSITION) out vec4 outZPosition;
#endif
#ifdef MOTION_BLUR
layout(location = MOTION_BLUR) out vec4 out_screenvelocity;
#endif
#ifdef DEFERRED_METALLICROUGHNESS
layout(location = DEFERRED_METALLICROUGHNESS) out vec4 outMetallicROughnessSheen;
#endif
#ifdef DEFERRED_REFLECTIONCOLOR
layout(location = DEFERRED_REFLECTIONCOLOR) out vec4 outReflectionColor;
#endif
#ifdef DEFERRED_EMISSION
layout(location = DEFERRED_EMISSION) out vec4 outEmission;
#endif*/