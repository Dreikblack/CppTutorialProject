#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable

#define CLIPPINGREGION

#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/Fragment.glsl"

void main()
{
#ifdef CLIPPINGREGION
	uvec2 screencoord;
    screencoord.x = uint(vertexWorldPosition.x);
	screencoord.y = DrawViewport.w - 1 - uint(vertexWorldPosition.y);
    if (screencoord.x < cliprect.x || screencoord.y < cliprect.y || screencoord.x > cliprect.z || screencoord.y > cliprect.w) discard;
#endif
}