#ifndef PUSH_CONSTANTS_GLSL
	#define PUSH_CONSTANTS_GLSL

#ifndef UNIFORMSTARTINDEX
	#define UNIFORMSTARTINDEX 0
#endif

layout(location = UNIFORMSTARTINDEX) uniform int CameraID;
layout(location = (UNIFORMSTARTINDEX + 1)) uniform ivec4 DrawViewport;
layout(location = (UNIFORMSTARTINDEX + 2)) uniform uint LightGridOffset = 0;
layout(location = (UNIFORMSTARTINDEX + 3)) uniform uint RenderFlags = 0;

/*#ifdef GL_EXT_multiview
	const int PassIndex = gl_ViewIndex;
#else*/
	layout(location = (UNIFORMSTARTINDEX + 4)) uniform int PassIndex = 0;
//#endif

layout(location = (UNIFORMSTARTINDEX + 5)) uniform float CameraTessellation = 0.0f;
layout(location = (UNIFORMSTARTINDEX + 6)) uniform float InverseGammaLevel = 1.0f / 2.2f;
layout(location = (UNIFORMSTARTINDEX + 7)) uniform uvec4 ReflectionMapHandles = uvec4(0);
layout(location = (UNIFORMSTARTINDEX + 8)) uniform float ShadowScale = 1.0f;
layout(location = (UNIFORMSTARTINDEX + 9)) uniform vec4 PaintBrushPosition = vec4(0.0);
layout(location = (UNIFORMSTARTINDEX + 10)) uniform int CameraProjectionMode = 2;
layout(location = (UNIFORMSTARTINDEX + 11)) uniform int TerrainID = 0;
layout(location = (UNIFORMSTARTINDEX + 12)) uniform int TerrainMaterialID = 0;

/*
layout(binding = 7, location = (UNIFORMSTARTINDEX + 8)) uniform sampler2DArray TerrainAtlas;
layout(binding = 8, location = (UNIFORMSTARTINDEX + 9)) uniform sampler2DArray TerrainNormalAtlas;
layout(binding = 9, location = (UNIFORMSTARTINDEX + 10)) uniform sampler2DArrayShadow ShadowmapAtlas;
layout(binding = 10, location = (UNIFORMSTARTINDEX + 11)) uniform sampler2DArrayShadow DirectionalShadowmapAtlas;
layout(binding = 11, location = (UNIFORMSTARTINDEX + 12)) uniform samplerCubeArray ProbeDiffuseAtlas;
layout(binding = 12, location = (UNIFORMSTARTINDEX + 13)) uniform samplerCubeArray ProbeSpecularAtlas;
layout(binding = 13, location = (UNIFORMSTARTINDEX + 14)) uniform sampler2D Lut_GGX;
layout(binding = 14, location = (UNIFORMSTARTINDEX + 15)) uniform samplerCube DiffuseEnvironmentMap;
layout(binding = 15, location = (UNIFORMSTARTINDEX + 16)) uniform samplerCube SpecularEnvironmentMap;
*/

//layout(binding = 7) uniform sampler2DArray TerrainAtlas;
//layout(binding = 8) uniform sampler2DArray TerrainNormalAtlas;
//layout(binding = 9) uniform sampler2DArrayShadow ShadowmapAtlas;
//layout(binding = 10) uniform sampler2DArrayShadow DirectionalShadowmapAtlas;
//layout(binding = 11) uniform samplerCubeArray ProbeDiffuseAtlas;
//layout(binding = 12) uniform samplerCubeArray ProbeSpecularAtlas;

layout(binding = 13) uniform sampler2D Lut_GGX;
layout(binding = 14) uniform samplerCube DiffuseEnvironmentMap;
layout(binding = 15) uniform samplerCube SpecularEnvironmentMap;

ivec2 BufferSize = DrawViewport.zw;

#define RENDERFLAGS_NO_IBL 1
#define RENDERFLAGS_FINAL_PASS 2
#define RENDERFLAGS_OUTPUT_NORMALS 4
#define RENDERFLAGS_OUTPUT_METALLICROUGHNESS 8
#define RENDERFLAGS_OUTPUT_ALBEDO 16
#define RENDERFLAGS_OUTPUT_ZPOSITION 32
#define RENDERFLAGS_OUTPUT_SPECULAR 64
#define RENDERFLAGS_NO_LIGHTING 128
#define RENDERFLAGS_NO_MATERIAL_EMISSION 256
#define RENDERFLAGS_SSR 512
#define RENDERFLAGS_NO_SPECULAR 1024
#define RENDERFLAGS_TRANSPARENCY 2048

#endif