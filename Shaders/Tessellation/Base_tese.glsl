#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/CameraInfo.glsl"
#include "Primitives.glsl"
#include "../Math/Plane.glsl"

//#define DISPLACEMENTDECALS

#ifdef DISPLACEMENTDECALS
#include "../Base/Lighting.glsl"
#include "../Base/LightInfo.glsl"
#endif

//#define DEBUG_EDGES

//Layout
#if PATCH_VERTICES == 2
layout(isolines, fractional_odd_spacing, ccw) in;
#endif
#if PATCH_VERTICES == 3
layout(triangles, fractional_odd_spacing, ccw) in;
#endif
#if PATCH_VERTICES == 4
layout(quads, fractional_odd_spacing, ccw) in;
#endif

//----------------------------------------------------------------
// Inputs
//----------------------------------------------------------------

//layout(location = 21) in flat int in_MaxMeshMaterials[];
//layout(location = 22) in patch uint primitiveFlags;
//layout(location = 20) in vec3 tess_normal2[];
layout(location = 9) in flat uint tess_flags[];
layout(location = 2) in vec4 tess_texCoords[];
layout(location = 3) in vec3 tess_tangent[]; 
layout(location = 4) in vec3 tess_bitangent[];
layout(location = 8) in vec4 maxDisplacedPosition[];
#ifdef WRITE_COLOR
layout(location = 0) in vec4 tess_color[];
//Inputs
//layout(location = 18) in vec4 tess_VertexColor[];
//layout(location = 4) in vec3 tess_bitangent[];
layout(location = 6) in vec4 tess_vertexCameraPosition[];
layout(location = 23) in vec3 tess_screenvelocity[];
layout(location = 12) flat in vec3 tess_emissioncolor[];
#endif
layout(location = 1) in vec3 tess_normal[];
layout(location = 5) patch in uvec4 tess_materialIDs;
layout(location = 26) in vec4 tess_materialweights[];
layout(location = 7) in vec4 tess_vertexWorldPosition[];
//layout(location = 10) flat in float tess_cameraDistance[];
layout(location = 11) in float tess_vertexDisplacement[];
//layout(location = 9) in vec3 tess_displacement[];
layout(location = 25) patch in uint tess_entityID;
layout(location = 10) patch in uint tess_decallayers;
//layout(location = 24) patch in float in_meshtexturescale;

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

//layout(location = 21) out flat int out_MaxMeshMaterials;
layout(location = 9) out flat uint flags;
#ifdef WRITE_COLOR
layout(location = 0) out vec4 color;
//Outputs
//layout(location = 18) out vec4 VertexColor;
layout(location = 3) out vec3 tangent;
layout(location = 4) out vec3 bitangent;
//layout(location = 4) out vec3 bitangent;
layout(location = 6) out vec4 vertexCameraPosition;
layout(location = 23) out vec3 screenvelocity;
layout(location = 10) flat out uint decallayers;
layout(location = 12) flat out vec3 emissioncolor;
#else
vec3 tangent;
vec3 bitangent;
uint decallayers;
vec3 emissioncolor;
#endif
layout(location = 1) out vec3 normal;
layout(location = 2) out vec4 texCoords;
layout(location = 5) flat out uvec4 materialIDs;
layout(location = 26) out vec4 materialweights;
layout(location = 25) flat out uint entityID;
layout(location = 7) out vec4 vertexWorldPosition;
//layout(location = 10) flat out float cameraDistance;
layout(location = 8) out vec4 frag_maxDisplacedPosition;

#include "../PBR/Multimaterial.glsl"

//TODO
#ifdef PNLINES
vec3 PNLine(vec3 p0, vec3 p1, vec3 norm0, vec3 norm1, vec2 uv)
{
}
#endif

#ifdef PNQUADS
#include "PNQuad.glsl"
#endif

#ifdef PNTRIANGLES
#include "PNTriangle.glsl"
#endif

const float ntolerance = 0.01f;

void main()
{
	materialIDs = tess_materialIDs;
	entityID = tess_entityID;
	flags = tess_flags[0];
	//out_MaxMeshMaterials = in_MaxMeshMaterials[0];

//TODO
#if PATCH_VERTICES == 2
	float vertexDisplacement = 0.0f;
#endif

	//Optimization for coplanar faces
	//if (curvededges > 0 && (primitiveFlags & PRIMITIVE_COPLANAR) != 0) curvededges = PATCH_VERTICES;
	//if ((primitiveFlags & PRIMITIVE_COPLANAR) != 0 && gl_TessCoord.x != 0.0f && gl_TessCoord.y != 0.0f && gl_TessCoord.z != 0.0f)
	{
		//curvededges = 0;
	}

#if PATCH_VERTICES == 3
	vec3 tessCoord = gl_TessCoord;
	float vertexDisplacement = tess_vertexDisplacement[0] * gl_TessCoord.x + tess_vertexDisplacement[1] * gl_TessCoord.y + tess_vertexDisplacement[2] * gl_TessCoord.z;
	normal = tess_normal[0] * gl_TessCoord.x + tess_normal[1] * gl_TessCoord.y + tess_normal[2] * gl_TessCoord.z;
	//vec3 displacementnormal = tess_normal2[0] * gl_TessCoord.x + tess_normal2[1] * gl_TessCoord.y + tess_normal2[2] * gl_TessCoord.z;
	texCoords = tess_texCoords[0] * gl_TessCoord.x + tess_texCoords[1] * gl_TessCoord.y + tess_texCoords[2] * gl_TessCoord.z;
	tangent = tess_tangent[0] * gl_TessCoord.x + tess_tangent[1] * gl_TessCoord.y + tess_tangent[2] * gl_TessCoord.z;
	bitangent = tess_bitangent[0] * gl_TessCoord.x + tess_bitangent[1] * gl_TessCoord.y + tess_bitangent[2] * gl_TessCoord.z;
	#ifdef WRITE_COLOR
	decallayers = tess_decallayers;
	emissioncolor = tess_emissioncolor[0];
	color = tess_color[0] * gl_TessCoord.x + tess_color[1] * gl_TessCoord.y + tess_color[2] * gl_TessCoord.z;
	vertexCameraPosition = tess_vertexCameraPosition[0] * gl_TessCoord.x + tess_vertexCameraPosition[1] * gl_TessCoord.y + tess_vertexCameraPosition[2] * gl_TessCoord.z;
	screenvelocity = tess_screenvelocity[0] * gl_TessCoord.x + tess_screenvelocity[1] * gl_TessCoord.y + tess_screenvelocity[2] * gl_TessCoord.z;
	#endif
	materialweights = tess_materialweights[0] * gl_TessCoord.x + tess_materialweights[1] * gl_TessCoord.y + tess_materialweights[2] * gl_TessCoord.z;
		vec3 tesscoord = gl_TessCoord.xyz;
	#ifdef PNTRIANGLES
	if ((flags & 2147483648) != 0)
	{
		vertexWorldPosition.xyz = PNTriangle(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_normal[0], tess_normal[1], tess_normal[2], tesscoord.xyz, true, true, true);
	}
	else
	{
	#endif
		vertexWorldPosition = tess_vertexWorldPosition[0] * tesscoord.x + tess_vertexWorldPosition[1] * tesscoord.y + tess_vertexWorldPosition[2] * tesscoord.z;
	#ifdef PNTRIANGLES
	}
	#endif
#endif

#if PATCH_VERTICES == 4

	vec2 tessCoord = gl_TessCoord.xy;
	float vertexDisplacement = mix(mix(tess_vertexDisplacement[0], tess_vertexDisplacement[3], tessCoord.x), mix(tess_vertexDisplacement[1], tess_vertexDisplacement[2], tessCoord.x), tessCoord.y);
	#ifdef PNQUADS
	if ((flags & 2147483648) != 0)
	{
		vertexWorldPosition.xyz = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal[0], tess_normal[1], tess_normal[2], tess_normal[3], gl_TessCoord.xy);
		//Testing...
		//vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], gl_TessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], gl_TessCoord.x), gl_TessCoord.y);
	}
	else
	{
	#endif
		vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
	#ifdef PNQUADS
	}
	#endif
	
	//vec3 displacementnormal = mix(mix(tess_normal2[0], tess_normal2[3], tessCoord.x), mix(tess_normal2[1], tess_normal2[2], tessCoord.x), tessCoord.y);
	normal = mix(mix(tess_normal[0], tess_normal[3], tessCoord.x), mix(tess_normal[1], tess_normal[2], tessCoord.x), tessCoord.y);
	texCoords = mix(mix(tess_texCoords[0], tess_texCoords[3], tessCoord.x), mix(tess_texCoords[1], tess_texCoords[2], tessCoord.x), tessCoord.y);
	#ifdef WRITE_COLOR
	color = mix(mix(tess_color[0], tess_color[3], tessCoord.x), mix(tess_color[1], tess_color[2], tessCoord.x), tessCoord.y);
	vertexCameraPosition = mix(mix(tess_vertexCameraPosition[0], tess_vertexCameraPosition[3], tessCoord.x), mix(tess_vertexCameraPosition[1], tess_vertexCameraPosition[2], tessCoord.x), tessCoord.y);
	screenvelocity = mix(mix(tess_screenvelocity[0], tess_screenvelocity[3], tessCoord.x), mix(tess_screenvelocity[1], tess_screenvelocity[2], tessCoord.x), tessCoord.y);
	//Testing...
	//vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
	emissioncolor = tess_emissioncolor[0];
	#endif
	materialweights = mix(mix(tess_materialweights[0], tess_materialweights[3], tessCoord.x), mix(tess_materialweights[1], tess_materialweights[2], tessCoord.x), tessCoord.y);
	decallayers = tess_decallayers;
	tangent = mix(mix(tess_tangent[0], tess_tangent[3], tessCoord.x), mix(tess_tangent[1], tess_tangent[2], tessCoord.x), tessCoord.y);
	bitangent = mix(mix(tess_bitangent[0], tess_bitangent[3], tessCoord.x), mix(tess_bitangent[1], tess_bitangent[2], tessCoord.x), tessCoord.y);
#endif
	
	vertexWorldPosition.w = 1.0;

//normal = CameraNormalMatrix * normal;
//#ifdef WRITE_COLOR
//tangent.xyz = CameraNormalMatrix * tangent.xyz;
//#endif

// Edge testing:
//#define DEBUG_EDGES
#ifdef DEBUG_EDGES
#ifdef WRITE_COLOR
	#if PATCH_VERTICES == 4
if (gl_TessCoord.x == 0.0f || gl_TessCoord.x == 1.0f)
{
	color = vec4(1,0,0,1);
}
if (gl_TessCoord.y == 0.0f || gl_TessCoord.y == 1.0f)
{
	color = vec4(0,1,0,1);
}
	#endif
	#if PATCH_VERTICES == 3
if (gl_TessCoord.x == 0.0f)
{
//	if (tess_normal2[1] != vec3(0.0f) && tess_normal2[2] != vec3(0.0f))
	color = vec4(1,0,0,1);
}
if (gl_TessCoord.y == 0.0f)
{
	color = vec4(0,1,0,1);
}
if (gl_TessCoord.z == 0.0f)
{
	color = vec4(0,0,1,1);
}
	#endif
#endif
#endif

	vec3 prevpos = vertexWorldPosition.xyz;
	float displacementdistance = 0.0f;

#ifdef USERFUNCTION

	UserFunction(tess_entityID, vertexWorldPosition, normal, texCoords, materials[ materialIDs[0] ]);

#else
	
	//Standard displacement mapping
	Material material;
	float h = 0.0f;
	float displacement;
	uvec2 handle;
	float wt;
	for (int n = 0; n < 4; ++n)
	{
		if (materialIDs[n] != 0 && materialweights[n] > 0.0f)
		{
			material = materials[ materialIDs[n] ];
			if ((material.flags & MATERIAL_TESSELLATION) == 0) continue;
			handle = material.textureHandle[TEXTURE_DISPLACEMENT];
			if (handle != uvec2(0))
			{
				wt = materialweights[n];
				displacement = textureLod(sampler2D(handle), texCoords.xy, 0.0f).r;				
				if (n > 0)
				{
					wt += (displacement - 0.5) * /*material.displacementblend **/ wt;
					wt = CalculateBlendAlpha(wt, material.blendsmoothing);
					wt = clamp(wt, 0.0f, 1.0f);
				}
				displacement = displacement * material.displacement.x + material.displacement.y;				
				h = mix(h, displacement, wt);
			}
		}
	}
	vertexWorldPosition.xyz += normalize(normal) * h * vertexDisplacement;

#endif

	normal = normalize(normal);

	#ifdef WRITE_COLOR
	//color = vec4(0,0,0,1);
	//color.r = mod(texCoords.x, 1.0);
	//color.g = mod(texCoords.y, 1.0);
	#endif

	//int face = max(skyTextureIndex.y, PassIndex);
	mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);//entityMatrix[CameraID + 3 + BufferSize.z + CurrentFace];
	//mat4 cameraProjectionMatrix = entityMatrix[CameraID + 3 + BufferSize.z];
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
	vertexWorldPosition.w = 1.0f;
	//gl_Position.z = (gl_Position.z + gl_Position.w) / 2.0;// Vulkan only
}