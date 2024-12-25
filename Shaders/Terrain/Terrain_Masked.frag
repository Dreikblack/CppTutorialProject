#version 450
#ifdef GL_GOOGLE_include_directive
    #extension GL_GOOGLE_include_directive : enable
#endif
#extension GL_ARB_separate_shader_objects : enable

#define MASK_DISCARD

#include "Fragment.glsl"
