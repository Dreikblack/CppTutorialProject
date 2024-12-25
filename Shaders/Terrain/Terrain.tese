#version 450
#ifdef GL_GOOGLE_include_directive
	#extension GL_GOOGLE_include_directive : enable
#endif
#extension GL_ARB_bindless_texture : enable

#define PATCH_VERTICES 4
#define USERFUNCTION
#define WRITE_COLOR
//#define PNQUADS

#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Utilities/ISO646.glsl"
#include "TerrainInfo.glsl"
#include "TessEvaluation.glsl"
#include "../Tessellation/base_tese.glsl"