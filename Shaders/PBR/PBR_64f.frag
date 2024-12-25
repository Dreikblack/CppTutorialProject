#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define USE_GAMMA
#define DOUBLE_FLOAT
//#define PARALLAX_MAPPING
#define LIGHTING_PBR
//#define LIGHTING_BLINN_PHONG
//#define ALPHA_DISCARD
//#define DISTANCE_FOG
#include "../Fragment.glsl"