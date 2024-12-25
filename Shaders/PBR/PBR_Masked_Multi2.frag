#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_bindless_texture : enable

#define MATERIAL_METALLICROUGHNESS
#define USE_IBL
#define PREMULTIPLY_AlPHA
#define LIGHTING
#define ALPHA_DISCARD
#define MAX_MATERIALS 2

const int SpecularModel = 0;

#include "Fragment.glsl"