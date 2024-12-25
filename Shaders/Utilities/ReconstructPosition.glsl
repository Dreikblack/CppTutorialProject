#ifndef _RECONSTRUCTPOSITION
#define _RECONSTRUCTPOSITION

#include "DepthFunctions.glsl"
#include "../Base/CameraInfo.glsl"

vec3 ScreenCoordToWorldPosition(in vec3 position)
{
	vec4 coord = InverseCameraProjectionViewMatrix * vec4(position.xy * 2.0f - 1.0f, position.z * 2.0f - 1.0f, 1.0f);
	return coord.xyz / coord.w;
	/*float aspect = BufferSize.x / BufferSize.y;
	position.x = (position.x + 0.5f) * 2.0f * aspect;
 	position.y = (position.y + 0.5f) * 2.0f;
	position.x *= position.z / CameraZoom;
	position.y *= -position.z / CameraZoom;
    return CameraNormalMatrix * position + CameraPosition;*/
}

vec3 ScreenCoordToCameraPosition(in vec3 position)
{
	vec4 coord = InverseCameraProjectionMatrix * vec4(position.xy * 2.0f - 1.0f, position.z * 2.0f - 1.0f, 1.0f);
	return coord.xyz / coord.w;
	/*float aspect = BufferSize.x / BufferSize.y;
	position.x = (position.x + 0.5f) * 2.0f * aspect;
 	position.y = (position.y + 0.5f) * 2.0f;
	position.x *= position.z / CameraZoom;
	position.y *= -position.z / CameraZoom;
    return position;*/
}

vec3 WorldPositionToScreenCoord(in vec3 position)
{
	vec4 coord = vec4(position, 1.0f);
	coord = CameraProjectionViewMatrix * coord;
	coord.z = (coord.z + coord.w) * 0.5f;
	coord.xy = coord.xy / coord.w * 0.5f + 0.5f;  
	return coord.xyz;
	/*float aspect = BufferSize.x / BufferSize.y;
	position -= CameraPosition;
	position = CameraInverseNormalMatrix * position;
	position.x /= position.z / CameraZoom;
	position.y /= -position.z / CameraZoom;
	position.x /= 2.0f * aspect;
	position.y /= 2.0f;
	position.xy += 0.5f;
	return position;*/
}

vec3 CameraPositionToScreenCoord(in vec3 position)
{
	//gl_DepthRange.nearest;
	//gl_DepthRange.far;
	vec4 coord = vec4(position, 1.0f);
	coord = CameraProjectionMatrix * coord;
	coord.z = (coord.z + coord.w) * 0.5f;
	coord.xy = coord.xy / coord.w * 0.5f + 0.5f;  
	return coord.xyz;
	/*float aspect = BufferSize.x / BufferSize.y;
	position.x /= position.z / CameraZoom;
	position.y /= -position.z / CameraZoom;
	position.x /= 2.0f * aspect;
	position.y /= 2.0f;
	position.xy += 0.5f;
	return position;*/
}

vec3 CameraPositionToScreenCoord2(in vec3 position)
{
	float aspect = float(BufferSize.y) / float(BufferSize.x);
	position.x /= position.z / CameraZoom;
	position.y /= -position.z / CameraZoom;
	position.x *= 0.5f * aspect;
	position.y *= -0.5f;
	position.xy += 0.5f;
	return position;
}

#endif