#version 450
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#include "../Base/Fragment.glsl"

void main()
{
    Material mtl = materials[materialID];
    outColor[0] = mtl.diffuseColor * color;

    // Base texture color
    if (mtl.textureHandle[0] != uvec2(0))
    {
        //outColor[0] *= texelFetch(sampler2DMS(mtl.textureHandle[0]), ivec2(gl_FragCoord.x, gl_FragCoord.y), 0);
        outColor[0] *= texelFetch(sampler2DMS(mtl.textureHandle[0]), ivec2(gl_FragCoord.x, DrawViewport.w - gl_FragCoord.y), 0);
    }
}