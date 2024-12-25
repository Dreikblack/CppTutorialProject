#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#define CLIPPINGREGION

#include "../Base/Fragment.glsl"

void main()
{
#ifdef CLIPPINGREGION
	uvec2 screencoord;
    screencoord.x = uint(vertexWorldPosition.x);
	screencoord.y = DrawViewport.w - 1 - uint(vertexWorldPosition.y);
    if (screencoord.x < cliprect.x || screencoord.y < cliprect.y || screencoord.x > cliprect.z || screencoord.y > cliprect.w) discard;
#endif

    vec4 baseColor = color;
    if (materialID != -1)
    {
        Material material = materials[materialID];
        baseColor *= material.diffuseColor;
        if (material.textureHandle[TEXTURE_DIFFUSE] != uvec2(0)) baseColor *= textureLod(sampler2D(material.textureHandle[TEXTURE_DIFFUSE]), texcoords.xy, 0);
    }
    outColor[0] = baseColor;
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) outColor[0].rgb *= outColor[0].a;
}