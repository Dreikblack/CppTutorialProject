#ifndef _INSTANCEINFO
    #define _INSTANCEINFO

#include "UniformBlocks.glsl"
#include "DrawElementsIndirectCommand.glsl"
#include "../Math/Math.glsl"

#define MESHFLAGS_SUBDIVISION 1
#define MESHFLAGS_WIND 2

uint meshflags = 0;

#define DRAWIDSIZE 2

#if DRAWIDSIZE == 4
	#define INSTANCEOFFSET_ENTITYIDS 7
#endif
#if DRAWIDSIZE == 2
	#define INSTANCEOFFSET_ENTITYIDS 8
#endif

//uint ExtractInstanceMaterialID()
//{
//	uint id_over_four = gl_BaseInstanceARB / 4;
//	return instanceID[ id_over_four ][  gl_BaseInstanceARB - id_over_four * 4 ];
//}

/*uint ExtractMaterialID()
{
	uint id = gl_BaseInstanceARB / 8;
	uvec4 params = instanceID[ id ];
	vec2 fval;
	//Extract material ID
	uvec2 uval = unpackUshort2x16(params.x);
	return uval.x;
}*/

uint MaterialID = 0;//ExtractMaterialID();
//int MaxMeshMaterials = 1;

#ifdef TESSELLATION
//uint PrimitiveID;
//uint PrimitivesCount;
#endif

//float MeshTextureScale = 0.0f;
uvec4 MaterialIDs;

void ExtractInstanceInfo()
{
#if DRAWIDSIZE == 4
	uint id = gl_BaseInstanceARB / 4;
	uvec4 params = instanceID[ id ];
	MaterialID = params.x;
#endif
#if DRAWIDSIZE == 2
	uint id = gl_BaseInstanceARB / 8;
	uvec4 params = instanceID[ id ];
	vec2 fval;

	//Extract material ID
	uvec2 uval = unpackUshort2x16(params.x);
	MaterialID = uval.x;
	//MeshTextureScale = unpackHalf2x16(params.x).y;	
	uval = unpackUshort2x16(params.y);
	meshflags = uval.x;
	
	//MaxMeshMaterials = int(params.z);
	
#ifdef TESSELLATION
	//uint primitiveindex = params.z;
	//PrimitivesCount = params.w;
	//PrimitiveID = primitiveindex;// + gl_InstanceID * PrimitivesCount;
#endif
	
	params = instanceID[ id + 1 ];
	MaterialIDs.xy = unpackUshort2x16(params.x);
	MaterialIDs.zw = unpackUshort2x16(params.y);
	MaterialID = MaterialIDs.x;

#endif
}

uint ExtractInstanceEntityID()
{
	uint InstanceIndex = gl_BaseInstanceARB + gl_InstanceID;
#if DRAWIDSIZE == 4
	uint id = InstanceIndex + INSTANCEOFFSET_ENTITYIDS;
#endif
#if DRAWIDSIZE == 2
	uint id = InstanceIndex / 2 + INSTANCEOFFSET_ENTITYIDS;
#endif
	uint id_over_four = id / 4;
	id = instanceID[ id_over_four ][ id - id_over_four * 4 ];
#if DRAWIDSIZE == 2
	uvec2 ids = unpackUshort2x16(id);
	id = ids[InstanceIndex % 2];
	id *= 2;
#endif
    return id;
}

uint EntityID = ExtractInstanceEntityID();

#endif