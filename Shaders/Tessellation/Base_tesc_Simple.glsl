#ifndef TESSELLATION
	#define TESSELLATION
#endif

#include "Primitives.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Math/Plane.glsl"
#include "../Math/Math.glsl"
#include "../Base/Materials.glsl"
#include "../Base/StorageBufferBindings.glsl"

layout (vertices = PATCH_VERTICES) out;

//----------------------------------------------------------------
// Inputs
//----------------------------------------------------------------

layout(location = 21) in flat uint primitiveID[];
layout(location = 9) in flat uint flags[];

layout(location = 2) in vec4 texCoords[];
#ifdef WRITE_COLOR
layout(location = 0) in vec4 color[];
//Inputs
//layout(location = 18) in vec4 VertexColor[];
//layout(location = 4) in vec3 bitangent[];
layout(location = 6) in vec4 vertexCameraPosition[];
layout(location = 23) in vec3 screenvelocity[];
#endif
layout(location = 1) in vec3 normal[];
layout(location = 3) in vec3 tangent[];
layout(location = 4) in vec3 bitangent[];
layout(location = 7) in vec4 vertexWorldPosition[];
layout(location = 5) flat in uint materialID[];
layout(location = 25) flat in uint entityID[];
layout(location = 8) in vec4 maxDisplacedPosition[];
//layout(location = 9) in vec3 displacement[];
layout(location = 11) in float vertexDisplacement[];
//layout(location = 10) flat in float cameraDistance[];
//layout(location = 20) in vec3 tessNormal2[];

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

layout(location = 2) out vec4 tess_texCoords[];
layout(location = 22) out patch uint primitiveFlags;
layout(location = 9) out flat uint tess_flags[];
layout(location = 3) out vec3 tess_tangent[];
layout(location = 4) out vec3 tess_bitangent[];
#ifdef WRITE_COLOR
layout(location = 0) out vec4 tess_color[];
//Outputs
//layout(location = 18) out vec4 tess_VertexColor[];
//layout(location = 4) out vec3 tess_bitangent[];
layout(location = 6) out vec4 tess_vertexCameraPosition[];
layout(location = 23) out vec3 tess_screenvelocity[];
#endif
//layout(location = 9) out vec3 tess_displacement[];
layout(location = 1) out vec3 tess_normal[];
layout(location = 7) out vec4 tess_vertexWorldPosition[];
layout(location = 5) out patch uint tess_materialID;
layout(location = 25) out patch uint tess_entityID;
//layout(location = 10) flat out float tess_cameraDistance[];
layout(location = 11) out float tess_vertexDisplacement[];
//layout(location = 20) out vec3 tess_Normal2[];

const float ntolerance = 0.001f;
const float tolerance_squared = ntolerance * ntolerance;
vec2 screenvertex[PATCH_VERTICES * 2];
float edgeLength[PATCH_VERTICES];

void main()
{
	vec4 TessLevelOuter = vec4(1);
	vec2 TessLevelInner = vec2(2);

	if (gl_InvocationID == 0)
	{
		float polygonsize = CameraTessellation;

		//Calculate screen coordinates
		for (int n = 0; n < PATCH_VERTICES; ++n)
		{
			screenvertex[n] = BufferSize.xy * (1.0 + gl_in[n].gl_Position.xy / gl_in[n].gl_Position.w) / 2.0;
			if (gl_in[n].gl_Position.z < 0.0f)
			{
				screenvertex[n].x *= -1.0f;
			}
			screenvertex[PATCH_VERTICES + n] = BufferSize.xy * (1.0 + maxDisplacedPosition[n].xy / maxDisplacedPosition[n].w) / 2.0;
			if (gl_in[n].gl_Position.z < 0.0f)
			{
				screenvertex[PATCH_VERTICES + n].x *= -1.0f;
			}
		}
		
		//Discard offscreen triangle
		/*
		if (screenvertex[0].x < 0.0 && screenvertex[1].x < 0.0 && screenvertex[2].x < 0.0 && screenvertex[3].x < 0.0 && screenvertex[4].x < 0.0 && screenvertex[5].x < 0.0) return;
		if (screenvertex[0].y < 0.0 && screenvertex[1].y < 0.0 && screenvertex[2].y < 0.0 && screenvertex[3].y < 0.0 && screenvertex[4].y < 0.0 && screenvertex[5].y < 0.0) return;
		if (gl_in[0].gl_Position.z < cameraRangeAndZoom[0] && gl_in[0].gl_Position.z < cameraRangeAndZoom[0] && gl_in[0].gl_Position.z < cameraRangeAndZoom[0] && maxDisplacedPosition[gl_InvocationID].z < cameraRangeAndZoom[0] && maxDisplacedPosition[gl_InvocationID].z < cameraRangeAndZoom[0] && maxDisplacedPosition[gl_InvocationID].z < cameraRangeAndZoom[0]) return;
		if (screenvertex[0].x > BufferSize.x && screenvertex[1].x > BufferSize.x && screenvertex[2].x > BufferSize.x && screenvertex[3].x > BufferSize.x && screenvertex[4].x > BufferSize.x && screenvertex[5].x > BufferSize.x) return;
		if (screenvertex[0].y > BufferSize.y && screenvertex[1].y > BufferSize.y && screenvertex[2].y > BufferSize.y && screenvertex[3].y > BufferSize.y && screenvertex[4].y > BufferSize.y && screenvertex[5].y > BufferSize.y) return;
		if (gl_in[0].gl_Position.z > cameraRangeAndZoom[1] && gl_in[0].gl_Position.z > cameraRangeAndZoom[1] && gl_in[0].gl_Position.z > cameraRangeAndZoom[1] && maxDisplacedPosition[gl_InvocationID].z > cameraRangeAndZoom[1] && maxDisplacedPosition[gl_InvocationID].z > cameraRangeAndZoom[1] && maxDisplacedPosition[gl_InvocationID].z > cameraRangeAndZoom[1]) return;
		*/

#if PATCH_VERTICES == 2
		edgeLength[0] = length(screenvertex[1] - screenvertex[0]);
#endif
#if PATCH_VERTICES == 3
		//http://ogldev.atspace.co.uk/www/tutorial30/tutorial30.html
		edgeLength[0] = length(screenvertex[2] - screenvertex[1]);
		edgeLength[1] = length(screenvertex[2] - screenvertex[0]);
		edgeLength[2] = length(screenvertex[1] - screenvertex[0]);
#endif
#if PATCH_VERTICES == 4
		//https://gamedev.stackexchange.com/questions/87616/opengl-quad-tessellation-control-shader
		edgeLength[0] = length(screenvertex[0] - screenvertex[1]);
		edgeLength[1] = length(screenvertex[3] - screenvertex[0]);
		edgeLength[2] = length(screenvertex[2] - screenvertex[3]);
		edgeLength[3] = length(screenvertex[1] - screenvertex[2]);
#endif
		TessLevelOuter[0] = max(1.0f, edgeLength[0] / polygonsize);
#if PATCH_VERTICES > 2
		TessLevelOuter[1] = max(1.0f, edgeLength[1] / polygonsize);
		TessLevelOuter[2] = max(1.0f, edgeLength[2] / polygonsize);
	#if PATCH_VERTICES == 4
		TessLevelOuter[3] = max(1.0f, edgeLength[3] / polygonsize);
	#endif
#endif
	}

	tess_flags[gl_InvocationID] = flags[gl_InvocationID];
#ifdef WRITE_COLOR
	tess_color[gl_InvocationID] = color[gl_InvocationID];
	tess_vertexCameraPosition[gl_InvocationID] = vertexCameraPosition[gl_InvocationID];
	tess_screenvelocity[gl_InvocationID] = screenvelocity[gl_InvocationID];
#endif

	if (gl_InvocationID == 0)
	{
		/*const float range = 20.0f;
		const float padding = 4.0f;
		float dist = length(CameraPosition - vertexWorldPosition[gl_InvocationID].xyz);
		if (dist > range - padding)
		{
			float m = clamp((dist - (range - padding)) / padding, 0.0f, 1.0f);
			for (int n = 0; n < 4; ++n)
			{
				TessLevelOuter[n] = max(1.0f, mix(TessLevelOuter[n], 1.0f, m));
			}
		}*/
#if PATCH_VERTICES == 3
		TessLevelInner[0] = max(TessLevelOuter[2], max(TessLevelOuter[0], TessLevelOuter[1]));
#endif
#if PATCH_VERTICES == 4
		TessLevelInner[0] = max(TessLevelOuter[3], TessLevelOuter[1]);
		TessLevelInner[1] = max(TessLevelOuter[0], TessLevelOuter[2]);
#endif
	}

	gl_TessLevelOuter[0] = TessLevelOuter[0];
	gl_TessLevelOuter[1] = TessLevelOuter[1];
	gl_TessLevelOuter[2] = TessLevelOuter[2];
	gl_TessLevelOuter[3] = TessLevelOuter[3];
	gl_TessLevelInner[0] = TessLevelInner[0];
	gl_TessLevelInner[1] = TessLevelInner[1];

	//tess_Normal2[gl_InvocationID] = tessNormal2[gl_InvocationID];
	tess_tangent[gl_InvocationID] = tangent[gl_InvocationID];
	tess_bitangent[gl_InvocationID] = bitangent[gl_InvocationID];
	tess_texCoords[gl_InvocationID] = texCoords[gl_InvocationID];
	tess_normal[gl_InvocationID] = normal[gl_InvocationID];
	tess_vertexWorldPosition[gl_InvocationID] = vertexWorldPosition[gl_InvocationID];
	tess_materialID = materialID[gl_InvocationID];
	tess_entityID = entityID[gl_InvocationID];
	tess_vertexDisplacement[gl_InvocationID] = vertexDisplacement[gl_InvocationID];
	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}
