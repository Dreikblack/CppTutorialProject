#version 450
#extension GL_ARB_separate_shader_objects : enable
#ifdef GL_GOOGLE_include_directive
    #extension GL_GOOGLE_include_directive : enable
#endif
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#define LIGHTING
#define USE_IBL
#define DEFERRED_NORMALS 1
#define DEFERRED_METALLICROUGHNESS 2
#define DEFERRED_REFLECTIONCOLOR 3

#define MASK_DISCARD

#include "Fragment.glsl"