#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define USE_GAMMA
#define TESSELLATION
#define LIGHTING_PBR
#define DEFERRED_NORMALS 1
#define DEFERRED_METALLICROUGHNESS 2
#define DEFERRED_REFLECTIONCOLOR 3
//#define LIGHTING_BLINN_PHONG
//#define ALPHA_DISCARD
//#define DISTANCE_FOG

const int SpecularModel = 0;

#include "Fragment.glsl"