#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define DYNAMIC_DESCRIPTORS

#define USE_GAMMA
#define LIGHTING_PBR
//#define PARALLAX_MAPPING
//#define LIGHTING_BLINN_PHONG
//#define ALPHA_DISCARD

const int SpecularModel = 0;

#include "Fragment.glsl"