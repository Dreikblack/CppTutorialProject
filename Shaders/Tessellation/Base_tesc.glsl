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

//layout(location = 21) in flat int in_MaxMeshMaterials[];
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
#endif
layout(location = 1) in vec3 normal[];
layout(location = 3) in vec3 tangent[];
layout(location = 4) in vec3 bitangent[];
layout(location = 7) in vec4 vertexWorldPosition[];
layout(location = 5) flat in uvec4 in_materialIDs[];
layout(location = 26) in vec4 materialweights[];
layout(location = 25) flat in uint entityID[];
layout(location = 8) in vec4 maxDisplacedPosition[];
//layout(location = 9) in vec3 displacement[];
layout(location = 11) in float vertexDisplacement[];
layout(location = 10) flat in uint decallayers[];
layout(location = 20) in vec3 tessNormal2[];
//layout(location = 24) flat in float in_meshtexturescale[];

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

//layout(location = 21) out flat int out_MaxMeshMaterials[];
layout(location = 2) out vec4 tess_texCoords[];
//layout(location = 22) out patch uint primitiveFlags;
layout(location = 9) out flat uint tess_flags[];
layout(location = 3) out vec3 tess_tangent[];
layout(location = 4) out vec3 tess_bitangent[];
layout(location = 8) out vec4 tess_maxDisplacedPosition[];
#ifdef WRITE_COLOR
layout(location = 0) out vec4 tess_color[];
//Outputs
//layout(location = 18) out vec4 tess_VertexColor[];
//layout(location = 4) out vec3 tess_bitangent[];
layout(location = 6) out vec4 tess_vertexCameraPosition[];
layout(location = 23) out vec3 tess_screenvelocity[];
layout(location = 12) flat out vec3 tess_emissioncolor[];
#endif
//layout(location = 9) out vec3 tess_displacement[];
layout(location = 1) out vec3 tess_normal[];
layout(location = 7) out vec4 tess_vertexWorldPosition[];
layout(location = 5) out patch uvec4 materialIDs;
layout(location = 26) out vec4 tess_materialweights[];
layout(location = 25) out patch uint tess_entityID;
layout(location = 10) out patch uint tess_decallayers;
//layout(location = 10) flat out float tess_cameraDistance[];
layout(location = 11) out float tess_vertexDisplacement[];
//layout(location = 20) out vec3 tess_Normal2[];
//layout(location = 24) patch out float out_meshtexturescale;

#include "../PBR/MultiMaterial.glsl"

const float ntolerance = 0.001f;
const float tolerance_squared = ntolerance * ntolerance;
vec2 screenvertex[PATCH_VERTICES * 2];
float edgeLength[PATCH_VERTICES];

vec4 TessLevelOuter = vec4(1);
vec2 TessLevelInner = vec2(2);

float GetTextureMappingScale(in vec3 v0, in vec3 v1, in vec3 v2, in vec2 t0, in vec2 t1, in vec2 t2)
{
	const float almostzero = 0.0001f;
	float dp = length(v0 - v1);
	float dt = length(t0 - t1);
	if (dt > almostzero && dp > almostzero) return dp / dt;
	dp = length(v0 - v2);
	dt = length(t0 - t2);
	if (dt > almostzero && dp > almostzero) return dp / dt;
	return 0.0;// this should never happen
}

float GetUVScale(in vec3 a, in vec3 b, in vec3 c, in vec2 ta, in vec2 tb, in vec2 tc, in sampler2D tex)
{
    // Get the texture dimensions
    vec2 texSize = textureSize(tex, 0); // Get the size of the texture at mip level 0

	// Exit early with simpler calculation
	// This only works if the texture is not stretched on one axis
	if (texSize.x == texSize.y)
	{
		float dp = length(c - b);
		float dt = length(tc - tb);
		if (dt < 0.00001f) return 0.0f;
		return dp / dt;
	}

    // Calculate the lengths of the edges in 3D space
    float edgeAB = length(b - a);
    float edgeAC = length(c - a);
    float edgeBC = length(c - b);

    // Calculate the lengths of the edges in UV space
    float uvEdgeAB = length(tb - ta);
    float uvEdgeAC = length(tc - ta);
    float uvEdgeBC = length(tc - tb);

    // Calculate the UV scale based on the edge lengths
    return (edgeAB / uvEdgeAB + edgeAC / uvEdgeAC + edgeBC / uvEdgeBC) * 0.3333333f;
}

void main()
{
	if (gl_InvocationID == 0)
	{
		uint pprimitiveFlags;
		//if (primitiveID_Count[0].x == 0)
		{
			pprimitiveFlags = PRIMITIVE_TESSELLATE_ALL;
		}
		/*else
		{
			uint index = primitiveID_Count[0].x;
			index += gl_PrimitiveID % primitiveID_Count[0].y;
			pprimitiveFlags = Primitives[index];
		}*/
		//pprimitiveFlags = PRIMITIVE_TESSELLATE_ALL;
		//pprimitiveFlags = PRIMITIVE_TESSELLATE_OUTER1 | PRIMITIVE_TESSELLATE_OUTER3;

		float polygonsize = CameraTessellation;

	const float tessfactor = 0.35f * float(BufferSize.y) * CameraZoom / CameraTessellation;
	float edgelength0, edgelength1, edgelength2, edgelength3, edgedistance0, edgedistance1, edgedistance2, edgedistance3;

	#if PATCH_VERTICES == 3

		if (CameraProjectionMode == 1)// ortho
		{
			const float tessfactor = 0.2f * CameraZoom / CameraTessellation;

			vec4 A = CameraInverseMatrix * vertexWorldPosition[0];
			vec4 B = CameraInverseMatrix * vertexWorldPosition[1];
			vec4 C = CameraInverseMatrix * vertexWorldPosition[2];

			edgelength0 = length(A.xy - B.xy);
			edgelength1 = length(B.xy - C.xy);
			edgelength2 = length(C.xy - A.xy);
			
			TessLevelOuter[2] = max(1.0f, ((tessfactor * edgelength0) ));
			TessLevelOuter[0] = max(1.0f, ((tessfactor * edgelength1) ));
			TessLevelOuter[1] = max(1.0f, ((tessfactor * edgelength2) ));			
		}
		else
		{
			edgelength0 = length(vertexWorldPosition[0].xyz - vertexWorldPosition[1].xyz);
			edgelength1 = length(vertexWorldPosition[1].xyz - vertexWorldPosition[2].xyz);
			edgelength2 = length(vertexWorldPosition[2].xyz - vertexWorldPosition[0].xyz);
			
			edgedistance0 = length((vertexWorldPosition[0].xyz + vertexWorldPosition[1].xyz) * 0.5f - CameraPosition.xyz);
			edgedistance1 = length((vertexWorldPosition[1].xyz + vertexWorldPosition[2].xyz) * 0.5f - CameraPosition.xyz);
			edgedistance2 = length((vertexWorldPosition[2].xyz + vertexWorldPosition[0].xyz) * 0.5f - CameraPosition.xyz);

			TessLevelOuter[2] = max(1.0f, ((tessfactor * edgelength0) / edgedistance0));
			TessLevelOuter[0] = max(1.0f, ((tessfactor * edgelength1) / edgedistance1));
			TessLevelOuter[1] = max(1.0f, ((tessfactor * edgelength2) / edgedistance2));
		}

		TessLevelInner[0] = (TessLevelOuter[0] + TessLevelOuter[1] + TessLevelOuter[2]) * 0.33333f;

	#endif

	#if PATCH_VERTICES == 4

		if (CameraProjectionMode == 1)// ortho
		{
			const float tessfactor = 0.2f * CameraZoom / CameraTessellation;

			vec4 A = CameraInverseMatrix * vertexWorldPosition[0];
			vec4 B = CameraInverseMatrix * vertexWorldPosition[1];
			vec4 C = CameraInverseMatrix * vertexWorldPosition[2];
			vec4 D = CameraInverseMatrix * vertexWorldPosition[3];
			
			edgelength0 = length(A.xy - B.xy);
			edgelength1 = length(D.xy - A.xy);
			edgelength2 = length(C.xy - D.xy);
			edgelength3 = length(B.xy - C.xy);

			TessLevelOuter[0] = max(1.0f, tessfactor * edgelength0);
			TessLevelOuter[1] = max(1.0f, tessfactor * edgelength1);
			TessLevelOuter[2] = max(1.0f, tessfactor * edgelength2);
			TessLevelOuter[3] = max(1.0f, tessfactor * edgelength3);	
		}
		else
		{
			edgelength0 = length(vertexWorldPosition[0].xyz - vertexWorldPosition[1].xyz);
			edgelength1 = length(vertexWorldPosition[3].xyz - vertexWorldPosition[0].xyz);
			edgelength2 = length(vertexWorldPosition[2].xyz - vertexWorldPosition[3].xyz);
			edgelength3 = length(vertexWorldPosition[1].xyz - vertexWorldPosition[2].xyz);

			edgedistance0 = length((vertexWorldPosition[0].xyz + vertexWorldPosition[1].xyz) * 0.5f - CameraPosition.xyz);
			edgedistance1 = length((vertexWorldPosition[3].xyz + vertexWorldPosition[0].xyz) * 0.5f - CameraPosition.xyz);
			edgedistance2 = length((vertexWorldPosition[2].xyz + vertexWorldPosition[3].xyz) * 0.5f - CameraPosition.xyz);
			edgedistance3 = length((vertexWorldPosition[1].xyz + vertexWorldPosition[2].xyz) * 0.5f - CameraPosition.xyz);

			TessLevelOuter[0] = max(1.0f, ((tessfactor * edgelength0) / edgedistance0));
			TessLevelOuter[1] = max(1.0f, ((tessfactor * edgelength1) / edgedistance1));
			TessLevelOuter[2] = max(1.0f, ((tessfactor * edgelength2) / edgedistance2));
			TessLevelOuter[3] = max(1.0f, ((tessfactor * edgelength3) / edgedistance3));			
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
		//UserFunction(entityID[gl_InvocationID], materials[materialIDs[gl_InvocationID].x], texCoords[gl_InvocationID]);
#endif
	}

	//out_MaxMeshMaterials[gl_InvocationID] = in_MaxMeshMaterials[gl_InvocationID];
	tess_flags[gl_InvocationID] = flags[gl_InvocationID];
#ifdef WRITE_COLOR
	tess_color[gl_InvocationID] = color[gl_InvocationID];
	tess_vertexCameraPosition[gl_InvocationID] = vertexCameraPosition[gl_InvocationID];
	tess_screenvelocity[gl_InvocationID] = screenvelocity[gl_InvocationID];
	tess_emissioncolor[gl_InvocationID] = emissioncolor[gl_InvocationID];
#endif

	/*const float range = 20.0f;
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
	}*/

	//tess_Normal2[gl_InvocationID] = tessNormal2[gl_InvocationID];

	/*if (abs(tess_Normal2[gl_InvocationID].x) + abs(tess_Normal2[gl_InvocationID].y) + abs(tess_Normal2[gl_InvocationID].z) < 0.1f)
	{
		//tess_Normal2[gl_InvocationID] = normal[gl_InvocationID];
	}*/
	tess_tangent[gl_InvocationID] = tangent[gl_InvocationID];
	tess_bitangent[gl_InvocationID] = bitangent[gl_InvocationID];
	tess_texCoords[gl_InvocationID] = texCoords[gl_InvocationID];
	tess_normal[gl_InvocationID] = normal[gl_InvocationID];
	tess_vertexWorldPosition[gl_InvocationID] = vertexWorldPosition[gl_InvocationID];
	materialIDs = in_materialIDs[gl_InvocationID];
	tess_materialweights[gl_InvocationID] = materialweights[gl_InvocationID];
	tess_entityID = entityID[gl_InvocationID];
	tess_decallayers = decallayers[gl_InvocationID];
	//out_meshtexturescale = in_meshtexturescale[gl_InvocationID];
	
	tess_vertexDisplacement[gl_InvocationID] = vertexDisplacement[gl_InvocationID];
	
	int disp = 0;
	uvec2 handle;
	float minweight = 0.001f;
	const vec4 nullvec4 = vec4(0.0f);
	Material material;
	for (int n = 0; n < 4; ++n)
	{
		if (tess_materialweights[0][n] > minweight || tess_materialweights[1][n] > minweight || tess_materialweights[2][n] > minweight
#if PATCH_VERTICES == 4		
		 || tess_materialweights[3][n] > minweight
#endif
		)
		{
			if (materialIDs[n] != 0)
			{
				material = materials[ materialIDs[n] ];
				if ((material.flags & MATERIAL_TESSELLATION) == 0) continue;
				handle = material.textureHandle[TEXTURE_DISPLACEMENT];
				if (handle != uvec2(0))
				{
					disp = 1;
					break;
				}
			}
		}
	}

	if (disp == 0)
	{
		gl_TessLevelInner[0] = 1;
		gl_TessLevelInner[1] = 1;
	}

	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}
