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
    if (mtl.textureHandle[0] != uvec2(0)) outColor[0] *= texture(sampler2D(mtl.textureHandle[0]), texcoords.xy);

    // Alpha discard
    if (outColor[0].a < 0.5f) discard;

    //Camera distance fog
    //if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(outColor[0].rgb, vertexWorldPosition.xyz, CameraPosition);
    
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
    {
      //  outColor[0].rgb *= outColor[0].a;
    }

    //outColor[0] = vec4(outColor[0].a);
}