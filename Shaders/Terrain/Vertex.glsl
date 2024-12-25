#include "../Base/Vertex.glsl"

#ifdef DOUBLE_FLOAT
dmat4 cameraProjectionMatrix;
dmat4 mat;
dmat4 terrainMat;
vec4 terrpos;
#else
mat4 cameraProjectionMatrix;
mat4 mat;
mat4 terrainMat;
vec3 terrpos;
#endif
int terrainID;
vec4 qtangent;

layout(binding = TEXTURE_TERRAINMATERIAL) uniform usampler2D terrainmaterialmap;

void main()
{
	entityindex = EntityID;

#ifndef WRITE_COLOR
	uint decallayers;
#endif

	ivec2 patchpos;
	color = vec4(1.0f);
	ExtractEntityInfo(EntityID, mat, flags, terrainID, patchpos, decallayers);
	Material mtl = materials[MaterialID];
	uvec2 textureID = mtl.textureHandle[TEXTURE_TERRAINHEIGHT];
	const float patchsize = 64.0f;
	#if defined(WRITE_COLOR) || defined (TESSELLATION)
	materialIndex = MaterialIDs;
	#else
	vec4 texCoords;
	#endif
	if (textureID != uvec2(0))
	{
		ivec2 sz = textureSize(sampler2D(textureID), 0);
		//ivec2 sz = textureSize(sampler2D(textureID), 0);
		vec2 pixelsize;
		pixelsize.x = 0.5f / float(sz.x);
		pixelsize.y = 0.5f / float(sz.y);
		texCoords.x = (float(patchpos.x) * patchsize + VertexPosition.x) / float(sz.x) + pixelsize.x;
		texCoords.y = (float(patchpos.y) * patchsize + VertexPosition.z) / float(sz.y) + pixelsize.y;
		texCoords.x = min(1.0f, texCoords.x);
		texCoords.y = min(1.0f, texCoords.y);
		//VertexPosition.y = textureLod(sampler2D(textureID), texCoords.xy, 0).r;
		//texCoords.xy = (mat * VertexPosition).xz / (textureSize(sampler2D(textureID), 0)) + 0.5f;
		//texCoords.xy *= 0.879f;
		VertexPosition.y = textureLod(sampler2D(textureID), texCoords.xy, 0).r;
		
		texCoords.z = VertexPosition.y * length(mat[1].xyz);
	}
	else
	{
		textureID = mtl.textureHandle[TEXTURE_TERRAINMATERIAL];
		if (textureID != uvec2(0))
		{
			ivec2 sz = textureSize(terrainmaterialmap, 0);		
			vec2 pixelsize;
			pixelsize.x = 0.5f / float(sz.x);
			pixelsize.y = 0.5f / float(sz.y);
			texCoords.x = (float(patchpos.x) * patchsize + VertexPosition.x) / float(sz.x) + pixelsize.x;
			texCoords.y = (float(patchpos.y) * patchsize + VertexPosition.z) / float(sz.y) + pixelsize.y;

			texCoords.x = min(1.0f, texCoords.x);
			texCoords.y = min(1.0f, texCoords.y);
		}
	}

	cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);

#if defined (WRITE_COLOR) || defined(TESSELLATION)
	materialweights = vec4(1,0,0,0);

	ExtractVertexNormalAndTangent(normal, qtangent);

	textureID = GetMaterialTextureHandle(mtl, TEXTURE_TERRAINNORMAL);
	if (textureID != uvec2(0))
	{
		normal.xz = textureLod(sampler2D(textureID), texCoords.xy, 0).rg * 2.0f - 1.0f;
		//normal.xz = textureLod(sampler2D(textureID), texCoords.xy, 0).rg * 2.0f - 1.0f;
		normal.y = 1.0f - sqrt(normal.x * normal.x + normal.z * normal.z);		
	}

	mat3 EntityNormalMatrix = mat3(mat);
	normal = EntityNormalMatrix * normal;
	tangent.xyz = EntityNormalMatrix * tangent.xyz;
	normal = normalize(normal);
	tangent.xyz = normalize(tangent.xyz);
	#ifdef TESSELLATION
	tessNormal = normal;
	#endif
	bitangent = cross(normal, tangent.xyz);// * sign(tangent.w);
#endif

#ifdef DOUBLE_FLOAT
	dvec4 dposition = mat * VertexPosition;
#else
	vertexWorldPosition = mat * VertexPosition;
#endif

#ifdef WRITE_COLOR
	#ifdef DOUBLE_FLOAT
	vertexCameraPosition = CameraInverseMatrix * dposition;
	#else
	vertexCameraPosition = CameraInverseMatrix * vertexWorldPosition;
	#endif
#endif

#ifdef TESSELLATION
	//primitiveID.x = PrimitiveID;
	//tessNormal = ExtractVertexTessNormal();
	//if (abs(tessNormal.x) < 0.1f && abs(tessNormal.y) < 0.1f && abs(tessNormal.z) < 0.1f)
	//{
	//	tessNormal = vec3(0.0f);
	//}
	maxDisplacedPosition = vertexWorldPosition;
	//#define MAX_DISPLACEMENT 0.025
	//float maxDisplacement = materials[MaterialID].metalnessRoughness[2];
	//maxDisplacedPosition.xyz += normal * maxDisplacement;
	maxDisplacedPosition = cameraProjectionMatrix * maxDisplacedPosition;
	vertexDisplacement = VertexDisplacement;
	out_meshtexturescale = 0.0f;
	
	if (meshflags != 0) flags |= ENTITYFLAGS_SUBDIVISION; // indicates that PN curvature should be applied
#endif

#ifdef DOUBLE_FLOAT
	vertexWorldPosition = vec4(dposition);
	gl_Position = vec4(cameraProjectionMatrix * dposition);
#else
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
#endif
	//gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5f;
}