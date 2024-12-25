#version 450
#extension GL_ARB_bindless_texture : enable
//#ifdef GL_GOOGLE_include_directive
//    #extension GL_GOOGLE_include_directive : enable
//#endif
//#extension GL_EXT_multiview : enable

#define PATCH_VERTICES 3 
#define PNTRIANGLES

#include "../Tessellation/base_tese.glsl"
