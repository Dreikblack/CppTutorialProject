#include "../Base/Limits.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Utilities/ISO646.glsl"
#include "Primitives.glsl"
#include "../Math/Plane.glsl"

//Layout
#if PATCH_VERTICES == 2
layout(isolines, fractional_odd_spacing, cw) in;
#endif
#if PATCH_VERTICES == 3
layout(triangles, fractional_odd_spacing, cw) in;
#endif
#if PATCH_VERTICES == 4
layout(quads, fractional_odd_spacing, cw) in;
#endif

//----------------------------------------------------------------
// Inputs
//----------------------------------------------------------------

layout(location = 22) in patch uint primitiveFlags;
//layout(location = 20) in vec3 tess_normal2[];
layout(location = 9) in flat uint tess_flags[];
layout(location = 2) in vec4 tess_texCoords[];
layout(location = 3) in vec3 tess_tangent[]; 
layout(location = 4) in vec3 tess_bitangent[];
#ifdef WRITE_COLOR
layout(location = 0) in vec4 tess_color[];
layout(location = 6) in vec4 tess_vertexCameraPosition[];
layout(location = 23) in vec3 tess_screenvelocity[];
#endif
layout(location = 1) in vec3 tess_normal[];
layout(location = 5) patch in uint tess_materialID;
layout(location = 7) in vec4 tess_vertexWorldPosition[];
layout(location = 11) in float tess_vertexDisplacement[];
layout(location = 25) patch in uint tess_entityID;

//----------------------------------------------------------------
// Outputs
//----------------------------------------------------------------

layout(location = 9) out flat uint flags;
#ifdef WRITE_COLOR
layout(location = 0) out vec4 color;
layout(location = 3) out vec3 tangent;
layout(location = 4) out vec3 bitangent;
layout(location = 6) out vec4 vertexCameraPosition;
layout(location = 23) out vec3 screenvelocity;
#else
vec3 tangent;
vec3 bitangent;
#endif
layout(location = 1) out vec3 normal;
layout(location = 2) out vec4 texCoords;
layout(location = 5) flat out uint materialID;
layout(location = 25) flat out uint entityID;
layout(location = 7) out vec4 vertexWorldPosition;

//TODO
#ifdef PNLINES
vec3 PNLine(vec3 p0, vec3 p1, vec3 norm0, vec3 norm1, vec2 uv)
{}
#endif

#ifdef PNQUADS
#include "PNQuad.glsl"
#endif

#ifdef PNTRIANGLES
#include "PNTriangle.glsl"
#endif

void main()
{
	materialID = tess_materialID;
	entityID = tess_entityID;
	flags = tess_flags[0];

//TODO
#if PATCH_VERTICES == 2
	float vertexDisplacement = 0.0f;
#endif

#if PATCH_VERTICES == 3
	vec3 tessCoord = gl_TessCoord;
	float vertexDisplacement = tess_vertexDisplacement[0] * gl_TessCoord.x + tess_vertexDisplacement[1] * gl_TessCoord.y + tess_vertexDisplacement[2] * gl_TessCoord.z;
	normal = tess_normal[0] * gl_TessCoord.x + tess_normal[1] * gl_TessCoord.y + tess_normal[2] * gl_TessCoord.z;
	texCoords = tess_texCoords[0] * gl_TessCoord.x + tess_texCoords[1] * gl_TessCoord.y + tess_texCoords[2] * gl_TessCoord.z;
	tangent = tess_tangent[0] * gl_TessCoord.x + tess_tangent[1] * gl_TessCoord.y + tess_tangent[2] * gl_TessCoord.z;
	bitangent = tess_bitangent[0] * gl_TessCoord.x + tess_bitangent[1] * gl_TessCoord.y + tess_bitangent[2] * gl_TessCoord.z;
	#ifdef WRITE_COLOR
	color = tess_color[0] * gl_TessCoord.x + tess_color[1] * gl_TessCoord.y + tess_color[2] * gl_TessCoord.z;
	screenvelocity = tess_screenvelocity[0] * gl_TessCoord.x + tess_screenvelocity[1] * gl_TessCoord.y + tess_screenvelocity[2] * gl_TessCoord.z;
	vertexCameraPosition = tess_vertexCameraPosition[0] * gl_TessCoord.x + tess_vertexCameraPosition[1] * gl_TessCoord.y + tess_vertexCameraPosition[2] * gl_TessCoord.z;
	#endif
	#ifdef PNTRIANGLES

	int edgenum;
	vec3 edgepos;

	if (gl_TessCoord.x == 1.0f or gl_TessCoord.y == 1.0f or gl_TessCoord.z == 1.0f)
	{
		vertexWorldPosition = tess_vertexWorldPosition[0] * gl_TessCoord.x + tess_vertexWorldPosition[1] * gl_TessCoord.y + tess_vertexWorldPosition[2] * gl_TessCoord.z;
	}
	else
	{
		vertexWorldPosition.xyz = PNTriangle(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_normal[0], tess_normal[1], tess_normal[2], gl_TessCoord.xyz);
	}

	#else
	vertexWorldPosition = tess_vertexWorldPosition[0] * gl_TessCoord.x + tess_vertexWorldPosition[1] * gl_TessCoord.y + tess_vertexWorldPosition[2] * gl_TessCoord.z;
	#endif
#endif

#if PATCH_VERTICES == 4
	vec2 tessCoord = gl_TessCoord.xy;
	float vertexDisplacement = mix(mix(tess_vertexDisplacement[0], tess_vertexDisplacement[3], tessCoord.x), mix(tess_vertexDisplacement[1], tess_vertexDisplacement[2], tessCoord.x), tessCoord.y);
	#ifdef PNQUADS
	int edgenum, axis;
	vec3 edgepos;
	float af;
	vertexWorldPosition.xyz = PNQuad(tess_vertexWorldPosition[0].xyz, tess_vertexWorldPosition[1].xyz, tess_vertexWorldPosition[2].xyz, tess_vertexWorldPosition[3].xyz, tess_normal[0], tess_normal[1], tess_normal[2], tess_normal[3], gl_TessCoord.xy);
	#else
	vertexWorldPosition = mix(mix(tess_vertexWorldPosition[0], tess_vertexWorldPosition[3], tessCoord.x), mix(tess_vertexWorldPosition[1], tess_vertexWorldPosition[2], tessCoord.x), gl_TessCoord.y);
	#endif
	normal = mix(mix(tess_normal[0], tess_normal[3], tessCoord.x), mix(tess_normal[1], tess_normal[2], tessCoord.x), tessCoord.y);
	texCoords = mix(mix(tess_texCoords[0], tess_texCoords[3], tessCoord.x), mix(tess_texCoords[1], tess_texCoords[2], tessCoord.x), tessCoord.y);
	#ifdef WRITE_COLOR
	color = mix(mix(tess_color[0], tess_color[3], tessCoord.x), mix(tess_color[1], tess_color[2], tessCoord.x), tessCoord.y);
	screenvelocity = mix(mix(tess_screenvelocity[0], tess_screenvelocity[3], tessCoord.x), mix(tess_screenvelocity[1], tess_screenvelocity[2], tessCoord.x), tessCoord.y);
	vertexCameraPosition = mix(mix(tess_vertexCameraPosition[0], tess_vertexCameraPosition[3], tessCoord.x), mix(tess_vertexCameraPosition[1], tess_vertexCameraPosition[2], tessCoord.x), tessCoord.y);
	#endif
	tangent = mix(mix(tess_tangent[0], tess_tangent[3], tessCoord.x), mix(tess_tangent[1], tess_tangent[2], tessCoord.x), tessCoord.y);
	bitangent = mix(mix(tess_bitangent[0], tess_bitangent[3], tessCoord.x), mix(tess_bitangent[1], tess_bitangent[2], tessCoord.x), tessCoord.y);
#endif
	
	vertexWorldPosition.w = 1.0;

#ifdef USERFUNCTION

	UserFunction(tess_entityID, vertexWorldPosition, normal, texCoords, materials[materialID]);

#else

	//Standard displacement mapping
	if (vertexDisplacement > 0.0f)
	{
		Material material = materials[materialID];
		int textureID = material.textureHandle[0][3];
		if (textureID != -1)
		{
			vec2 d = material.displacement;//ExtractMaterialDisplacement(material);
			float maxDisplacement = material.displacement.x;//material.metalnessRoughness[2];
			float offset = material.displacement.y;
			float h = texture(texture2DSampler[textureID], texCoords.xy).r;
			vertexWorldPosition.xyz += normal * (h * maxDisplacement + offset) * vertexDisplacement;
		}
	}

#endif

	normal = normalize(normal);
	mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
	gl_Position.z = (gl_Position.z + gl_Position.w) / 2.0;
}