#ifndef _VERTEXLAYOUT
    #define _VERTEXLAYOUT

#include "InstanceInfo.glsl"
#include "../Math/Quaternion.glsl"

layout(location = 0) in vec3 VertexPositionDisplacement;
layout(location = 1) in vec4 VertexTexCoords_;
layout(location = 2) in uvec2 VertexQTangent_;
layout(location = 3) in uvec4 VertexBoneIndices;
layout(location = 4) in uvec4 VertexBoneWeights_;
layout(location = 5) in uvec4 VertexMaterialWeights_;

vec4 ExtractVertexMaterialWeights()
{
	vec4 weights;
	weights.x = 1.0f;
	weights.y = float(VertexMaterialWeights_.y) / 255.0f;
	weights.z = float(VertexMaterialWeights_.z) / 255.0f;
	weights.w = float(VertexMaterialWeights_.w) / 255.0f;
	return weights;
}
vec4 VertexMaterialWeights = ExtractVertexMaterialWeights();

vec4 ExtractVertexBoneWeights()
{
	vec4 weights;
	weights.x = float(VertexBoneWeights_.x) / 255.0f;
	weights.y = float(VertexBoneWeights_.y) / 255.0f;
	weights.z = float(VertexBoneWeights_.z) / 255.0f;
	weights.w = max(0.0f, 1.0f - (weights.x + weights.y + weights.z));
	return weights;
}
vec4 VertexBoneWeights = ExtractVertexBoneWeights();

const float one_over_16 = 0.0625f;
const float one_over_65535 = 1.0f / 65535.0f;

float ExtractVertexTextureScaleAndDisplacement()
{
	uint a = VertexBoneWeights_[3];
	uint b = VertexMaterialWeights_[0];
	uint i = (b << 8) | a;
	return unpackHalf2x16(i).x;
}
float VertexDisplacement = ExtractVertexTextureScaleAndDisplacement();

vec4 ExtractVertexTexCoords()
{
	return VertexTexCoords_;
	//vec4 t;
	//t.xy = unpackHalf2x16(VertexTexCoords_.x);
	//t.zw = unpackHalf2x16(VertexTexCoords_.y);
	//return t;
}

vec4 VertexTexCoords = ExtractVertexTexCoords();

vec4 ExtractVertexPosition()
{
    ExtractInstanceInfo();
	//vec4 v;
	//vec2 a;
	//v.xy = unpackHalf2x16(VertexPositionDisplacement.x);
	//a = unpackHalf2x16(VertexPositionDisplacement.y);
	//v.z = a.x;
	//v.w = 1.0f;
	//return v;

	return vec4(VertexPositionDisplacement.xyz, 1.0f);
    
	/*vec4 position;
    position.x = float(VertexPositionBoneWeightsDisplacement.x);
    position.y = float(VertexPositionBoneWeightsDisplacement.y);
    position.z = float(VertexPositionBoneWeightsDisplacement.z);
    position.w = 1.0f;
    position.xyz *= one_over_65535;
    ExtractInstanceMeshExtents(minima, maxima);
    position.xyz *= (maxima - minima);
    position.xyz += minima;
    return position;*/
}

void ExtractVertexNormal(out vec3 normal)
{
	vec4 VertexQTangent;
	VertexQTangent.xy = unpackHalf2x16(VertexQTangent_.x);
	VertexQTangent.zw = unpackHalf2x16(VertexQTangent_.y);
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	normal.x = 2.0f * (xz - wy);    normal.y = 2.0f * (yz + wx);    normal.z = 1.0f - 2.0f * (xx + yy);
}

void ExtractVertexNormalAndTangent(out vec3 normal, out vec4 tangent)
{
	vec4 VertexQTangent;
	VertexQTangent.xy = unpackHalf2x16(VertexQTangent_.x);
	VertexQTangent.zw = unpackHalf2x16(VertexQTangent_.y);
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float zz = VertexQTangent.z * VertexQTangent.z;
	const float xy = VertexQTangent.x * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	const float wz = VertexQTangent.w * VertexQTangent.z;
	tangent.x = 1.0f - 2.0f * (yy + zz);	tangent.y = 2.0f * (xy - wz);	tangent.z = 2.0f * (xz + wy);
	normal.x = 2.0f * (xz - wy);		    normal.y = 2.0f * (yz + wx);	normal.z = 1.0f - 2.0f * (xx + yy);
}

void ExtractVertexNormalTangentBitangent(out vec3 normal, out vec3 tangent, out vec3 bitangent)
{
	vec4 VertexQTangent;
	VertexQTangent.xy = unpackHalf2x16(VertexQTangent_.x);
	VertexQTangent.zw = unpackHalf2x16(VertexQTangent_.y);
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float zz = VertexQTangent.z * VertexQTangent.z;
	const float xy = VertexQTangent.x * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	const float wz = VertexQTangent.w * VertexQTangent.z;
	tangent.x = 1.0f - 2.0f * (yy + zz);	tangent.y = 2.0f * (xy - wz);	tangent.z = 2.0f * (xz + wy);
	normal.x = 2.0f * (xz - wy);		    normal.y = 2.0f * (yz + wx);	normal.z = 1.0f - 2.0f * (xx + yy);
    bitangent = cross(normal, tangent);
    if (VertexQTangent.w < 0.0f) bitangent *= -1.0f;
	//normal = VertexHPNormal;
}

vec4 VertexPosition = ExtractVertexPosition();

#endif