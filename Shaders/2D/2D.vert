#version 460
#extension GL_ARB_shader_draw_parameters : enable
#extension GL_ARB_bindless_texture : enable

// Inputs
layout(location = 0) uniform mat4 matrix;
layout(location = 1) uniform uvec2 texturehandle = uvec2(0);
layout(location = 2) uniform vec4 clipregion = vec4(0);

#define UNIFORMSTARTINDEX 8

#include "../Utilities/ISO646.glsl"
#include "../Base/InstanceInfo.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/VertexLayout.glsl"
#include "../Base/Limits.glsl"
#include "../Math/Math.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/UniformBlocks.glsl"

// Outputs
layout(location = 0) out vec4 color;
layout(location = 1) flat out vec3 emissioncolor;
layout(location = 2) out vec2 texcoords;

#ifndef RENDERFLAGS_RENDERTOTEXTURE
    #define RENDERFLAGS_RENDERTOTEXTURE 4096
#endif

void main()
{
    int flip = 0;
    if ((RenderFlags & RENDERFLAGS_RENDERTOTEXTURE) != 0) flip = 1;

    vec2 BufferSize = vec2(DrawViewport.z, DrawViewport.w);
    vec2 pixeloffset = vec2(0.5f, -0.5f);

    vec4 pos = VertexPosition;
    
    if (flip == 1) pixeloffset.y *= 1.0f;

    mat4 m = matrix;
    m[0][3] = 0.0f; m[1][3] = 0.0f; m[2][3] = 0.0f; m[3][3] = 1.0f;

    color.r = matrix[0][3];
    color.g = matrix[1][3];
    color.b = matrix[2][3];
    color.a = matrix[3][3];

    pos = m * pos;

    pos.xy += pixeloffset;
    
    if (flip == 1) pos.y = BufferSize.y + 1.0f - pos.y;

    pos.y -= BufferSize.y;

    pos.xy /= BufferSize;

	mat4 orthomatrix = mat4(0.0f);
	orthomatrix[0][0] = 2.0f;
	orthomatrix[1][1] = 2.0f;
	orthomatrix[2][2] = -1.0f;
	orthomatrix[3][0] = -1.0f;
	orthomatrix[3][1] = -1.0f;
	orthomatrix[3][3] = 1.0f;
	orthomatrix[1] *= -1.0f;

    texcoords = ExtractVertexTexCoords().xy;

    gl_Position = orthomatrix * pos;

    vec2 clippos = (m * VertexPosition).xy;

    gl_ClipDistance[0] = (clippos.x - clipregion.x) / BufferSize.x;
    gl_ClipDistance[1] = (clippos.y - clipregion.y) / BufferSize.y;
    gl_ClipDistance[2] = -(clippos.x - (clipregion.x + clipregion.z)) / BufferSize.x;
    gl_ClipDistance[3] = -(clippos.y - (clipregion.y + clipregion.w)) / BufferSize.y;
}