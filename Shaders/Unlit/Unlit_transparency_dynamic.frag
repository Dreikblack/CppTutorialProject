#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define DYNAMIC_DESCRIPTORS
#define TRANSPARENCY_PASS
#define DEFERRED_NORMALS 1
#define DEFERRED_Z_POSITION 2

#include "../Base/Base_frag.glsl"