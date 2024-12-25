#version 460
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable

#define WRITE_COLOR

#include "../Base/VertexLayout.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/UniformBlocks.glsl"

//Outputs
layout(location = 0) out vec3 texCoords;
layout(location = 1) out flat uint materialIndex;

void main()
{
	materialIndex = MaterialID;
	texCoords = normalize(VertexPosition.xyz);
	mat4 cameraMatrix = ExtractEntityMatrix(CameraID);
	vec4 pos = VertexPosition;
	pos.xyz *= CameraRange.x + (CameraRange.y - CameraRange.x) * 0.5f;
	pos.xyz += cameraMatrix[3].xyz;
	gl_Position = CameraProjectionViewMatrix * pos;
}