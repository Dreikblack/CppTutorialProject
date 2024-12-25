#ifndef _RECONSTRUCTPOSITIONFRAG
#define _RECONSTRUCTPOSITIONFRAG

#include "DepthFunctions.glsl"
#include "../Base/CameraInfo.glsl"
#include "ReconstructPosition.glsl"

vec3 GetFragmentWorldPosition(in sampler2D depthmap)
{
	const int samp = 0;
	vec3 pos;
	vec2 sz = textureSize(depthmap, 0);
	vec2 texcoords = gl_FragCoord.xy / BufferSize;
	float depth = texelFetch(depthmap, ivec2(texcoords * sz), samp).r;
	//float aspect = sz.x / sz.y;
	pos.z = depth;//DepthToPosition(depth, CameraRange);
	pos.xy = texcoords;
	return ScreenCoordToWorldPosition(pos);
	//pos.x = ((gl_FragCoord.x / BufferSize.x * 1.0f) - 0.5f) * 2.0f * aspect;
 	//pos.y = ((gl_FragCoord.y / BufferSize.y * 1.0f) - 0.5f) * 2.0f;
	//pos.x *= pos.z / CameraZoom;
	//pos.y *= -pos.z / CameraZoom;
    //return CameraNormalMatrix * pos + CameraPosition;
}

vec3 GetFragmentWorldPosition(in sampler2DMS depthmap, in int samp)
{
	vec3 pos;
	vec2 sz = textureSize(depthmap);
	vec2 texcoords = gl_FragCoord.xy / BufferSize;
	float depth = texelFetch(depthmap, ivec2(texcoords * sz), samp).r;
	//float aspect = sz.x / sz.y;
	pos.z = depth;//DepthToPosition(depth, CameraRange);
	pos.xy = texcoords;
	return ScreenCoordToWorldPosition(pos);
	//pos.x = ((gl_FragCoord.x / BufferSize.x * 1.0f) - 0.5f) * 2.0f * aspect;
 	//pos.y = ((gl_FragCoord.y / BufferSize.y * 1.0f) - 0.5f) * 2.0f;
	//pos.x *= pos.z / CameraZoom;
	//pos.y *= -pos.z / CameraZoom;
    //return CameraNormalMatrix * pos + CameraPosition;
}

vec3 GetFragmentCameraPosition(in sampler2D depthmap)
{
	const int samp = 0;
	vec3 pos;
	vec2 sz = textureSize(depthmap, 0);
	vec2 texcoords = gl_FragCoord.xy / BufferSize;
	float depth = texelFetch(depthmap, ivec2(texcoords * sz), samp).r;
	//float aspect = sz.x / sz.y;
	pos.z = depth;//DepthToPosition(depth, CameraRange);
	pos.xy = texcoords;
	return ScreenCoordToCameraPosition(pos);
	//pos.x = ((gl_FragCoord.x / BufferSize.x) - 0.5f) * 2.0f * aspect;
 	//pos.y = ((gl_FragCoord.y / BufferSize.y) - 0.5f) * 2.0f;
	//pos.x *= pos.z / CameraZoom;
	//pos.y *= -pos.z / CameraZoom;
    //return pos;
}

vec3 GetFragmentCameraPosition(in sampler2DMS depthmap, in int samp)
{
	vec3 pos;
	vec2 sz = textureSize(depthmap);
	vec2 texcoords = gl_FragCoord.xy / BufferSize;
	float depth = texelFetch(depthmap, ivec2(texcoords * sz), samp).r;
	//float aspect = sz.x / sz.y;
	pos.z = depth;//DepthToPosition(depth, CameraRange);
	pos.xy = texcoords;
	return ScreenCoordToCameraPosition(pos);
	//pos.x = ((gl_FragCoord.x / BufferSize.x) - 0.5f) * 2.0f * aspect;
 	//pos.y = ((gl_FragCoord.y / BufferSize.y) - 0.5f) * 2.0f;
	//pos.x *= pos.z / CameraZoom;
	//pos.y *= -pos.z / CameraZoom;
    //return pos;
}

#endif