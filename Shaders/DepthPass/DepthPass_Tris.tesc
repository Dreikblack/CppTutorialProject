#version 450
#ifdef GL_GOOGLE_include_directive
//    #extension GL_GOOGLE_include_directive : enable
#endif
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#define PATCH_VERTICES 3

#include "../Tessellation/base_tesc.glsl"