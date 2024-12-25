#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define PREMULTIPLY_ALPHA

const int SpecularModel = 0;

#include "../Base/Settings.glsl"
#include "Fragment.glsl"