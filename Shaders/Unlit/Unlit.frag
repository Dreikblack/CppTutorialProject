#version 450
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#include "../Base/Fragment.glsl"
#include "../Utilities/DepthFunctions.glsl"

void main()
{    
    Material mtl = materials[materialID];
    vec4 basecolor = mtl.diffuseColor * color;

    outColor[0] = basecolor;

    texcoords.xyz += GetMaterialTextureOffset(mtl, CurrentTime);

    // Base texture color
    if (mtl.textureHandle[0] != uvec2(0)) outColor[0] *= texture(sampler2D(mtl.textureHandle[0]), texcoords.xy);

    //Camera distance fog
    if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(outColor[0].rgb, vertexWorldPosition.xyz, CameraPosition);
    
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
    {
        outColor[0].rgb *= outColor[0].a;
    }

    int attachmentindex=0;
    //Deferred normals
    if ((RenderFlags & RENDERFLAGS_OUTPUT_NORMALS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex] = vec4(0,1,0,basecolor.a);
    }

    //Deferred metal / roughness
    if ((RenderFlags & RENDERFLAGS_OUTPUT_METALLICROUGHNESS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].r = 0.0f;//thickness
        outColor[attachmentindex].g = 1.0f;
        outColor[attachmentindex].b = 0.0f;
        outColor[attachmentindex].a = basecolor.a;
#ifdef PREMULTIPLY_AlPHA
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
        {
            outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        }
#endif
    }

    //Deferred base color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ALBEDO) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex] = vec4(1.0f, 1.0f, 1.0f, basecolor.a);
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
        //    outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }

    //Deferred Z-position
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ZPOSITION) != 0)
    {
        ++attachmentindex;
        float d = PositionToDepth(vertexCameraPosition.z, CameraRange);
        outColor[attachmentindex] = vec4(d, d, d, 1.0f);
        //outColor[attachmentindex] = vec4(1.0f);
    }      
}