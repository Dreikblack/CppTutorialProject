#ifndef _VERTEX_SKINNING_GLSL
#define _VERTEX_SKINNING_GLSL

#include "TextureArrays.glsl"
#include "PushConstants.glsl"
#include "../Math/Quaternion.glsl"

layout(binding = STORAGE_BUFFER_BONES) readonly buffer BoneMatricesBlock { uvec4 bonematrices[]; } bonematricesblocks[2];

mat4 GetBoneMatrix(in int skeletonID, in uint index, const in float rendertweening)
{
	vec4 pos, quat, pos1, quat1;

	uvec4 bonedata = bonematricesblocks[0].bonematrices[skeletonID * 256 + index];
	pos.xy = unpackHalf2x16(bonedata.x);
	pos.zw = unpackHalf2x16(bonedata.y);
	quat.xy = unpackHalf2x16(bonedata.z);
	quat.zw = unpackHalf2x16(bonedata.w);
	
	bonedata = bonematricesblocks[1].bonematrices[skeletonID * 256 + index];
	pos1.xy = unpackHalf2x16(bonedata.x);
	pos1.zw = unpackHalf2x16(bonedata.y);
	quat1.xy = unpackHalf2x16(bonedata.z);
	quat1.zw = unpackHalf2x16(bonedata.w);

	pos = pos * (1.0f - rendertweening) + pos1 * rendertweening;
	quat = Slerp(quat, quat1, rendertweening);

	mat4 m = QuatToMat4(quat);
	m[0].xyz *= pos.w; m[1].xyz *= pos.w; m[2].xyz *= pos.w;
	m[3].xyz = pos.xyz;

	return m;
}
#endif
