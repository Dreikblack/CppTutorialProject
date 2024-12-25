#version 450
//#extension GL_GOOGLE_include_directive : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#define PATCH_VERTICES 4
#define PNQUADS

#include "../Tessellation/base_tese.glsl"