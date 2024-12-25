
//#extension GL_ARB_gpu_shader_int64 : enable

#include "../Utilities/ISO646.glsl"
#include "InstanceInfo.glsl"
//#include "Constants.glsl"
#include "PushConstants.glsl"
#include "VertexLayout.glsl"
#include "Limits.glsl"
#include "../Math/Math.glsl"
#include "EntityInfo.glsl"
#include "CameraInfo.glsl"
#include "UniformBlocks.glsl"
#ifdef TEXTURE_ANIMATION
#include "Materials.glsl"
#endif
#ifdef TERRAIN
//#include "Materials.glsl"
//#include "TextureArrays.glsl"
#endif
#ifdef TESSELLATION
#include "Materials.glsl"
#include "TextureArrays.glsl"
#endif
//#ifdef VERTEX_SKINNING
#include "VertexSkinning.glsl"
//#endif
#ifdef TERRAIN
//#include "../Terrain/TerrainInfo.glsl"
#endif

//Outputs
layout(location = 9) out flat uint flags;
layout(location = 25) out flat uint entityindex;
#if defined(WRITE_COLOR) || defined (TESSELLATION)
layout(location = 2) out vec4 texCoords;
layout(location = 3) out vec3 tangent;
layout(location = 4) out vec3 bitangent;
layout(location = 5) flat out uvec4 materialIndex;
layout(location = 10) flat out uint decallayers;
layout(location = 26) out vec4 materialweights;
#endif
#ifdef WRITE_COLOR
layout(location = 0) out vec4 color;
layout(location = 6) out vec4 vertexCameraPosition;
layout(location = 23) out vec3 screenvelocity;
layout(location = 12) flat out vec3 emissioncolor;
#else
vec4 color;
#endif
#if defined(WRITE_COLOR) || defined (TESSELLATION) || defined(TERRAIN)
layout(location = 1) out vec3 normal;
layout(location = 7) out vec4 vertexWorldPosition;
//layout(location = 21) out flat int out_MaxMeshMaterials;
#else
vec4 vertexWorldPosition;
#endif
#ifdef TESSELLATION
layout(location = 8) out vec4 maxDisplacedPosition;
layout(location = 11) out float vertexDisplacement;
layout(location = 20) out vec3 tessNormal;
//layout(location = 21) out flat uvec2 primitiveID_Count;
//layout(location = 24) out flat float out_meshtexturescale;
#endif
#ifdef PARALLAX_MAPPING
layout(location = 16) out vec3 eyevec;
#endif
#ifdef CLIPPINGREGION
layout(location = 17) out flat uvec4 cliprect;
#endif

#ifdef DOUBLE_FLOAT
dmat4 cameraProjectionMatrix;
dmat4 mat;
#ifdef TERRAIN
dmat4 terrainMat;
vec4 terrpos;
#endif
#else
mat4 cameraProjectionMatrix;
mat4 mat;
#ifdef TERRAIN
mat4 terrainMat;
vec3 terrpos;
#endif
#endif
int skeletonID;
vec4 qtangent;

vec4 texturemapping = vec4(0,0,1,1);
vec3 velocity = vec3(0.0f), omega = vec3(0.0f);

void main()
{
	entityindex = EntityID;

#ifdef USERFUNCTION
	UserFunction(color, flags, entitymatrix, normalmatrix, position, normal, texcoords, boneweights, boneindexes);
#endif

#if defined (WRITE_COLOR) || defined(TESSELLATION)
	//out_MaxMeshMaterials = MaxMeshMaterials;
	ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
	#ifndef TERRAIN
	texCoords = VertexTexCoords;
	#endif
#endif

#ifdef TERRAIN
	ivec2 patchpos;
	color = vec4(1.0f);
	int terrainID;
	ExtractEntityInfo(EntityID, mat, flags, terrainID, patchpos, decallayers);
	Material mtl = materials[MaterialIDs.x];
	uvec2 textureID = GetMaterialTextureHandle(mtl, TEXTURE_TERRAINHEIGHT);
	const float patchsize = 64.0f;
	#if defined(WRITE_COLOR) || defined (TESSELLATION)
	materialIndex = MaterialIDs;
	#ifdef WRITE_COLOR
	#endif
	#else
	vec2 texCoords;
	#endif
	texCoords.x = (float(patchpos.x) * patchsize + VertexPosition.x) / float(512) - 0.0f;
	texCoords.y = (float(patchpos.y) * patchsize + VertexPosition.z) / float(512) - 0.0f;
	if (textureID != uvec2(0))
	{
		VertexPosition.y = textureLod(sampler2D(textureID), texCoords.xy, 0).r;
	}
#else
	#if defined(WRITE_COLOR) || defined (TESSELLATION)
		materialIndex = MaterialIDs;

		materialweights = VertexMaterialWeights;
		materialweights.x = 1.0f;

	#endif
	#if defined(WRITE_COLOR) || defined(VERTEX_SKINNING)
		#ifdef CLIPPINGREGION
			ExtractEntityInfo(EntityID, mat, color, flags, cliprect);
			//cliprect.xz += uint(mat[3].x + 0.01f);
			//cliprect.yw += uint(BufferSize.y - mat[3].y + 0.01f);
		#else
			EntityInfo info = ExtractEntityInfo(EntityID);
			mat = info.matrix;
			color = info.color;
			flags = info.flags;
			skeletonID = info.skeletonid;
			#if defined(WRITE_COLOR) || defined (TESSELLATION)
				texCoords.xy *= info.texturescale;
				texCoords.xy += info.textureoffset;
			#endif
			#ifdef WRITE_COLOR
				emissioncolor = info.emissioncolor;
				decallayers = info.decallayers;
			#endif
			//ExtractEntityInfo(EntityID, mat, color, flags, skeletonID, texturemapping, velocity, omega);
		#endif
	#else
		ExtractEntityInfo(EntityID, mat, flags, skeletonID);
	#endif
#endif

#ifdef PARTICLES
	int pindex = (gl_VertexID - gl_BaseVertex) / 4;
	mat4 particle = entityMatrix[EntityID + 2 + pindex];

	mat[0].xyz = CameraNormalMatrix[0];
	mat[1].xyz = CameraNormalMatrix[1];
	mat[2].xyz = CameraNormalMatrix[2];
	
	mat[3].xyz = mix(particle[1].xyz, particle[0].xyz, RenderInterpolation);
	
	vec4 color0, color1;

	uint packedcolor = floatBitsToUint(particle[2][0]);
	color0.rg = unpackHalf2x16(packedcolor);
	packedcolor = floatBitsToUint(particle[2][1]);
	color0.ba = unpackHalf2x16(packedcolor);

	packedcolor = floatBitsToUint(particle[2][2]);
	color1.rg = unpackHalf2x16(packedcolor);
	packedcolor = floatBitsToUint(particle[2][3]);
	color1.ba = unpackHalf2x16(packedcolor);

	color = mix(color0, color1, RenderInterpolation);
	
	vec4 velocity0, velocity1;
	packedcolor = floatBitsToUint(particle[3][0]);
	velocity0.rg = unpackHalf2x16(packedcolor);
	packedcolor = floatBitsToUint(particle[3][1]);
	velocity0.ba = unpackHalf2x16(packedcolor);

	packedcolor = floatBitsToUint(particle[3][2]);
	velocity1.xy = unpackHalf2x16(packedcolor);
	packedcolor = floatBitsToUint(particle[3][3]);
	velocity1.zw = unpackHalf2x16(packedcolor);
	
	vec2 size = mix(unpackHalf2x16(floatBitsToUint(particle[1][3])), unpackHalf2x16(floatBitsToUint(particle[0][3])), RenderInterpolation);
	VertexPosition.xy *= size;

	if ((flags & ENTITYFLAGS_PARTICLEVIEWMODE_VELOCITY) == 0)
	{
		float angle = mix(velocity1.w, velocity0.w, RenderInterpolation);
		float cosTheta = cos(angle);
		float sinTheta = sin(angle);
		mat2 rotationMatrix = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
		VertexPosition.xy = rotationMatrix * VertexPosition.xy * size;
	}
	else
	{
		mat4 vmat = mat4(1.0f);
		vmat[1].xyz = normalize(velocity1.xyz);
		vmat[2].xyz = normalize(mat[3].xyz - CameraPosition);
		vmat[0].xyz = normalize(-cross(vmat[2].xyz, vmat[1].xyz));
		vmat[3] = mat[3];
		mat = vmat;
	}
#endif

//#ifdef SPRITEVIEW
	if ((flags & ENTITYFLAGS_SPRITE) != 0)
	{
		switch (skeletonID)
		{
			case SPRITEVIEW_DEFAULT:
				break;
			case SPRITEVIEW_BILLBOARD:
				mat[0] = CameraMatrix[0];
				mat[1] = CameraMatrix[1];
				mat[2] = CameraMatrix[2];
				break;
			case SPRITEVIEW_XROTATION:
				break;
			case SPRITEVIEW_YROTATION:
				break;	
			case SPRITEVIEW_ZROTATION:
				break;
		}
	}
//#endif

	cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
	//cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, gl_Layer);

#ifdef VERTEX_SKINNING
	if (skeletonID > -1)
	{
		mat4 animmatrix = mat4(0.0f);
		vec4 weights = ExtractVertexBoneWeights();
		//if (VertexBoneWeights[0] != 0.0f or VertexBoneWeights[1] != 0.0f or VertexBoneWeights[2] != 0.0f or VertexBoneWeights[3] != 0.0f)
		//{
			for (int n = 0; n < 4; ++n)
			{
				if (VertexBoneWeights[n] > 0.0f)
				{
					animmatrix += GetBoneMatrix(skeletonID, VertexBoneIndices[n], RenderInterpolation) * weights[n];
				}
			}
			VertexPosition = animmatrix * VertexPosition;
			VertexPosition.w = 1.0f;
	#if defined(WRITE_COLOR) || defined(TESSELLATION)
			mat3 nanimmat = mat3(animmatrix);
			normal = nanimmat * normal;
			tangent = nanimmat * tangent;
			bitangent = nanimmat * bitangent;
	#endif
	}
#else
	if (VertexBoneIndices[0] != 255 || VertexBoneIndices[1] != 255 || VertexBoneIndices[2] != 255 || VertexBoneIndices[3] != 255)
	{
		color.r *= float(VertexBoneIndices[0]) / 255.0f;
		color.g *= float(VertexBoneIndices[1]) / 255.0f;
		color.b *= float(VertexBoneIndices[2]) / 255.0f;
		color.a *= float(VertexBoneIndices[3]) / 255.0f;
	}
#endif

#ifdef USE_SCISSOR
	#ifdef DOUBLE_FLOAT
	scissor.x = float(entityMatrix[ id + 1 ][0].x);
	scissor.y = float(entityMatrix[ id + 1 ][0].y);
	scissor.z = float(entityMatrix[ id + 1 ][0].z);
	scissor.w = float(entityMatrix[ id + 1 ][0].w);
	#else
	scissor = entityMatrix[ id + 1 ][0];
	#endif
#endif

#if defined (WRITE_COLOR) || defined(TESSELLATION)
	//#ifndef TERRAIN
	//texCoords = VertexTexCoords;
	//#endif
	bool alreadynormalized = (flags & ENTITYFLAGS_MATRIXNORMALIZED) != 0;
	//if (alreadynormalized) color = vec4(1,0,0,1);
	//#ifdef WRITE_COLOR
	//if (materials[materialIndex].textureHandle[0][1] != -1)
	//{
		//ExtractVertexNormalAndTangent(normal, qtangent);
		//tangent.xyz = CameraNormalMatrix * tangent.xyz;
		mat3 EntityNormalMatrix = mat3(mat);
		normal = EntityNormalMatrix * normal;
		tangent = EntityNormalMatrix * tangent;
		bitangent = EntityNormalMatrix * bitangent;
		//if (!alreadynormalized)
		//{
		normal = normalize(normal);
		tangent = normalize(tangent);
		bitangent = normalize(bitangent);
		//}
		//bitangent = cross(normal, tangent.xyz) * sign(qtangent.w);
	//}
	//else
	//{
	//	ExtractVertexNormal(normal);
	//}
	//bitangent = normalize(CameraNormalMatrix * VertexBitangent);
	//#else
	//	ExtractVertexNormal(normal);
	//	normal = CameraNormalMatrix * normal;
	//#endif
	//if (!alreadynormalized) 
	//normal = normalize(normal);
#endif

#ifdef DOUBLE_FLOAT
	dvec4 dposition = mat * VertexPosition;
#else
	//if ((flags & RENDERNODE_IDENTITYMATRIX) == 0)
	vertexWorldPosition = mat * VertexPosition;
#endif

#ifdef WRITE_COLOR
	#ifdef DOUBLE_FLOAT
	vertexCameraPosition = CameraInverseMatrix * dposition;
	#else
	vertexCameraPosition = CameraInverseMatrix * vertexWorldPosition;
	#endif
#endif

#ifdef PARALLAX_MAPPING
    mat3 TBN = mat3(tangent, bitangent, normal);
	#ifdef DOUBLE_FLOAT
	eyevec = vec3(CameraPosition - dposition.xyz);
	#else
	vec3 eyevec = CameraPosition - vertexWorldPosition.xyz;
	#endif
	eyevec *= TBN;
#endif

#ifdef TEXTURE_ANIMATION
	/*if (materials[materialIndex].animation.x != 0.0f || materials[materialIndex].animation.y != 0.0f || materials[materialIndex].animation.z != 0.0f)
	{
		//Texture scroll
		texCoords.xyz -= materials[materialIndex].animation.xyz * float(CurrentTime) / 1000.0f;
	}*/
#endif

#ifdef TESSELLATION
	//primitiveID_Count.x = PrimitiveID;	
	//primitiveID_Count.y = PrimitivesCount;
	//tessNormal = EntityNormalMatrix * VertexDisplacementVector.xyz;
	//tessNormal = normalize(tessNormal);
	//tessNormal.xyz = VertexDisplacementVector;
	maxDisplacedPosition = vertexWorldPosition;
	//#define MAX_DISPLACEMENT 0.025
	//float maxDisplacement = materials[MaterialID.x].metalnessRoughness[2];
	//maxDisplacedPosition.xyz += normal * maxDisplacement;
	maxDisplacedPosition = cameraProjectionMatrix * maxDisplacedPosition;
	vertexDisplacement = VertexDisplacement * length(mat[0].xyz);
	//out_meshtexturescale = MeshTextureScale * length(mat[0].xyz);
#endif

#ifdef DOUBLE_FLOAT
	vertexWorldPosition = vec4(dposition);
	gl_Position = vec4(cameraProjectionMatrix * dposition);
#else
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
#endif

	//gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5f;
#ifdef LINEAR_DEPTH
	gl_Position.z *= gl_Position.w;
#endif
#ifdef WRITE_COLOR
	screenvelocity = CameraNormalMatrix * (velocity - cross(vertexWorldPosition.xyz - mat[3].xyz, omega));
#endif

	// Adjust selection flag based on mesh settings
	//if ((flags & ENTITYFLAGS_SELECTED) != 0)
	//{
	//	if (meshflags == 0) flags -= ENTITYFLAGS_SELECTED;
	//}
	//if (meshflags != 0) flags |= ENTITYFLAGS_SELECTED;

	if (meshflags != 0) flags |= ENTITYFLAGS_SUBDIVISION;
	//gl_PointSize = 1.0f;
}