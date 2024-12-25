#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
////#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#define MATERIAL_METALLICROUGHNESS
#define USE_IBL
#define PREMULTIPLY_AlPHA
#define LIGHTING
#define MAX_MATERIALS 2

const int SpecularModel = 0;

#include "Fragment.glsl"
