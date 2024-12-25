#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/Fragment.glsl"
#include "../Utilities/PackSelectionState.glsl"

void main()
{
    Material mtl = materials[materialID];
    outColor[0] = mtl.diffuseColor * color;
    if ((int(gl_FragCoord.x / 8.0f) % 2) == (int(gl_FragCoord.y / 8.0f) % 2)) discard;
}
