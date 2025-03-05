#ifndef TESSELLATION
	#define TESSELLATION
#endif

#include "../Tessellation/Primitives.glsl"
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

//layout(location = 21) in flat uvec2 primitiveID_Count[];
layout(location = 9) in flat uint flags[];
layout(location = 2) in vec4 texCoords[];
#ifdef WRITE_COLOR
layout(location = 0) in vec4 color[];
layout(location = 23) in vec3 screenvelocity[];
//Inputs
//layout(location = 18) in vec4 VertexColor[];
//layout(location = 4) in vec3 bitangent[];
layout(location = 6) in vec4 vertexCameraPosition[];
layout(location = 12) flat in vec3 emissioncolor[];
layout(location = 10) flat in uint decallayers[];
#endif
layout(location = 1) in vec3 normal[];
layout(location = 3) in vec3 tangent[];
layout(location = 4) in vec3 bitangent[];
layout(location = 7) in vec4 vertexWorldPosition[];
layout(location = 5) flat in uvec4 materialID[];
layout(location = 25) flat in uint entityID[];
layout(location = 8) in vec4 maxDisplacedPosition[];
//layout(location = 9) in vec3 displacement[];
layout(location = 11) in float vertexDisplacement[];
layout(location = 20) in vec3 tessNormal2[];
layout(location = 24) flat in float in_meshtexturescale[];
layout(location = 26) in vec4 in_materialweights[];

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

layout(location = 2) out vec4 tess_texCoords[];
//layout(location = 22) out patch uint primitiveFlags;
layout(location = 9) out flat uint tess_flags[];
layout(location = 3) out vec3 tess_tangent[];
layout(location = 4) out vec3 tess_bitangent[];
layout(location = 8) out vec4 tess_maxDisplacedPosition[];
layout(location = 26) out vec4 tess_materialweights[];
#ifdef WRITE_COLOR
layout(location = 0) out vec4 tess_color[];
//Outputs
//layout(location = 18) out vec4 tess_VertexColor[];
//layout(location = 4) out vec3 tess_bitangent[];
layout(location = 6) out vec4 tess_vertexCameraPosition[];
layout(location = 23) out vec3 tess_screenvelocity[];
layout(location = 12) flat out vec3 tess_emissioncolor[];
layout(location = 10) out patch uint tess_decallayers;
#endif
//layout(location = 9) out vec3 tess_displacement[];
layout(location = 1) out vec3 tess_normal[];
layout(location = 7) out vec4 tess_vertexWorldPosition[];
layout(location = 5) out patch uvec4 tess_materialID;
layout(location = 25) out patch uint tess_entityID;
//layout(location = 10) flat out float tess_cameraDistance[];
layout(location = 11) out float tess_vertexDisplacement[];
layout(location = 20) out vec3 tess_Normal2[];
layout(location = 24) patch out float out_meshtexturescale;

const float ntolerance = 0.001f;
const float tolerance_squared = ntolerance * ntolerance;
vec2 screenvertex[PATCH_VERTICES * 2];
float edgeLength[PATCH_VERTICES];

vec4 TessLevelOuter = vec4(1);
vec2 TessLevelInner = vec2(2);

void main()
{
	if (gl_InvocationID == 0)
	{
		uint pprimitiveFlags = PRIMITIVE_TESSELLATE_ALL;
		/*if (primitiveID_Count[0].x == 0)
		{
			pprimitiveFlags = PRIMITIVE_TESSELLATE_ALL;
		}
		else
		{
			uint index = primitiveID_Count[0].x;
			index += gl_PrimitiveID % primitiveID_Count[0].y;
			pprimitiveFlags = Primitives[index];
		}*/
		//pprimitiveFlags = PRIMITIVE_TESSELLATE_ALL;
		//pprimitiveFlags = PRIMITIVE_TESSELLATE_OUTER1 | PRIMITIVE_TESSELLATE_OUTER3;

		float polygonsize = CameraTessellation;

	const float tessfactor = 0.35f * float(BufferSize.y) * CameraZoom / CameraTessellation;

	#if PATCH_VERTICES == 3

		float edgelength0 = length(vertexWorldPosition[0].xyz - vertexWorldPosition[1].xyz);
		float edgelength1 = length(vertexWorldPosition[1].xyz - vertexWorldPosition[2].xyz);
		float edgelength2 = length(vertexWorldPosition[2].xyz - vertexWorldPosition[0].xyz);
		
		if (CameraProjectionMode == 2)
		{
			float edgedistance0 = length((vertexWorldPosition[0].xyz + vertexWorldPosition[1].xyz) * 0.5f - CameraPosition.xyz);
			float edgedistance1 = length((vertexWorldPosition[1].xyz + vertexWorldPosition[2].xyz) * 0.5f - CameraPosition.xyz);
			float edgedistance2 = length((vertexWorldPosition[2].xyz + vertexWorldPosition[0].xyz) * 0.5f - CameraPosition.xyz);

			TessLevelOuter[2] = max(1.0f, ((tessfactor * edgelength0) / edgedistance0 + 0.5f));
			TessLevelOuter[0] = max(1.0f, ((tessfactor * edgelength1) / edgedistance1 + 0.5f));
			TessLevelOuter[1] = max(1.0f, ((tessfactor * edgelength2) / edgedistance2 + 0.5f));
		}
		else
		{
			TessLevelOuter[0] = max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength0) + 0.5f));
			TessLevelOuter[1] = max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength1) + 0.5f));
			TessLevelOuter[2] = max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength2) + 0.5f));
		}
		TessLevelInner[0] = (TessLevelOuter[0] + TessLevelOuter[1] + TessLevelOuter[2]) * 0.33333f;

	#endif

	#if PATCH_VERTICES == 4

		float edgelength0 = length(vertexWorldPosition[0].xyz - vertexWorldPosition[1].xyz);
		float edgelength1 = length(vertexWorldPosition[3].xyz - vertexWorldPosition[0].xyz);
		float edgelength2 = length(vertexWorldPosition[2].xyz - vertexWorldPosition[3].xyz);
		float edgelength3 = length(vertexWorldPosition[1].xyz - vertexWorldPosition[2].xyz);

		if (CameraProjectionMode == 2)
		{
			float edgedistance0 = length((vertexWorldPosition[0].xyz + vertexWorldPosition[1].xyz) * 0.5f - CameraPosition.xyz);
			float edgedistance1 = length((vertexWorldPosition[3].xyz + vertexWorldPosition[0].xyz) * 0.5f - CameraPosition.xyz);
			float edgedistance2 = length((vertexWorldPosition[2].xyz + vertexWorldPosition[3].xyz) * 0.5f - CameraPosition.xyz);
			float edgedistance3 = length((vertexWorldPosition[1].xyz + vertexWorldPosition[2].xyz) * 0.5f - CameraPosition.xyz);

			TessLevelOuter[0] = max(1.0f, ((tessfactor * edgelength0) / edgedistance0 + 0.5f));
			TessLevelOuter[1] = max(1.0f, ((tessfactor * edgelength1) / edgedistance1 + 0.5f));
			TessLevelOuter[2] = max(1.0f, ((tessfactor * edgelength2) / edgedistance2 + 0.5f));
			TessLevelOuter[3] = max(1.0f, ((tessfactor * edgelength3) / edgedistance3 + 0.5f));
		}
		else
		{
			TessLevelOuter[0] = 1.0f;//max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength0) + 0.5f));
			TessLevelOuter[1] = 1.0f;//max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength1) + 0.5f));
			TessLevelOuter[2] = 1.0f;//max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength2) + 0.5f));
			TessLevelOuter[3] = 1.0f;//max(1.0f, (1.0f / CameraTessellation) * 2.1f * ((CameraZoom * edgelength3) + 0.5f));
		}

		TessLevelInner[0] = max(TessLevelOuter[3], TessLevelOuter[1]);
		TessLevelInner[1] = max(TessLevelOuter[0], TessLevelOuter[2]);
	#endif

		gl_TessLevelOuter[0] = TessLevelOuter[0];
		gl_TessLevelOuter[1] = TessLevelOuter[1];
		gl_TessLevelOuter[2] = TessLevelOuter[2];
		gl_TessLevelOuter[3] = TessLevelOuter[3];
		gl_TessLevelInner[0] = TessLevelInner[0];
		gl_TessLevelInner[1] = TessLevelInner[1];
		
#ifdef USERFUNCTION
		//UserFunction(entityID[gl_InvocationID], materials[materialID[gl_InvocationID]], texCoords[gl_InvocationID]);
#endif
	}

	tess_flags[gl_InvocationID] = flags[gl_InvocationID];
#ifdef WRITE_COLOR
	tess_color[gl_InvocationID] = color[gl_InvocationID];
	tess_vertexCameraPosition[gl_InvocationID] = vertexCameraPosition[gl_InvocationID];
	tess_screenvelocity[gl_InvocationID] = screenvelocity[gl_InvocationID];
	tess_emissioncolor[gl_InvocationID] = emissioncolor[gl_InvocationID];
#endif

	const float range = 20.0f;
	const float padding = 4.0f;
	float dist = length(CameraPosition - vertexWorldPosition[gl_InvocationID].xyz);
	if (dist > range - padding)
	{
		float m = clamp((dist - (range - padding)) / padding, 0.0f, 1.0f);
		for (int n = 0; n < 4; ++n)
		{
			//TessLevelOuter[n] = mix(TessLevelOuter[n], 1.0f, m);
			//if (n < 2) TessLevelInner[n] = mix(TessLevelInner[n], 2.0f, m);
		}
	}

	tess_Normal2[gl_InvocationID] = tessNormal2[gl_InvocationID];

	/*if (abs(tess_Normal2[gl_InvocationID].x) + abs(tess_Normal2[gl_InvocationID].y) + abs(tess_Normal2[gl_InvocationID].z) < 0.1f)
	{
		//tess_Normal2[gl_InvocationID] = normal[gl_InvocationID];
	}*/
	
	tess_tangent[gl_InvocationID] = tangent[gl_InvocationID];
	tess_bitangent[gl_InvocationID] = bitangent[gl_InvocationID];
	tess_texCoords[gl_InvocationID] = texCoords[gl_InvocationID];
	tess_normal[gl_InvocationID] = normal[gl_InvocationID];
	tess_vertexWorldPosition[gl_InvocationID] = vertexWorldPosition[gl_InvocationID];
#ifdef WRITE_COLOR
	tess_decallayers = decallayers[gl_InvocationID];
#endif
	tess_vertexDisplacement[gl_InvocationID] = vertexDisplacement[gl_InvocationID];
	tess_materialweights[gl_InvocationID] = in_materialweights[gl_InvocationID];

	if (gl_InvocationID == 0)
	{
		out_meshtexturescale = in_meshtexturescale[gl_InvocationID];
		tess_materialID = materialID[gl_InvocationID];
		tess_entityID = entityID[gl_InvocationID];	
	}

	{
		
		/*//Calculate texture mapping scale		
		if (in_meshtexturescale[0] <= 0.0f)
		{
			tess_vertexDisplacement[gl_InvocationID] *= length(tess_vertexWorldPosition[0] - tess_vertexWorldPosition[1]) / length(tess_texCoords[0] - tess_texCoords[1]);
		}
		else
		{
			tess_vertexDisplacement[gl_InvocationID] *= in_meshtexturescale[0];
		}*/
	}

	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}
