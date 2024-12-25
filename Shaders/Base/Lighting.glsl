#ifndef _BASE_LIGHTING
#define _BASE_LIGHTING

#include "../Base/StorageBufferBindings.glsl"
#include "EntityInfo.glsl"
#include "LightInfo.glsl"
#include "../Math/Math.glsl"
#include "../Math/FastSqrt.glsl"
#include "../Utilities/ISO646.glsl"
#include "../Utilities/ReconstructPosition.glsl"

const ivec3 lightGridSize = ivec3(16,8,24);

layout(binding = STORAGE_BUFFER_LIGHT_GRID) readonly buffer LightGridBlock { uint lightGrid[]; };

float SKyVisibility = 0.0f;

/*float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float pcf(in sampler2DArrayShadow depthTex, in vec4 shadowcoord, in int numOfSamples) {
    float shadow = 0.0;
    float texelSize = 1.0 / textureSize(depthTex, 0).x;
    float angle = rand(shadowcoord.xy) * 360.0; // Generate a random angle based on the shadow coordinate

    for (int i = 0; i < numOfSamples; i++) {
        float radius = float(i) + 1.0; // Increase the radius for each sample
        vec2 offset = vec2(cos(radians(angle)) * radius, sin(radians(angle)) * radius) * texelSize;
        float depth = textureLod(depthTex, shadowcoord + vec4(offset, 0, 0), 0.0f).r;        
        shadow += shadowcoord.w > depth ? 1.0 : 0.0;
    }
    
    return shadow / float(numOfSamples);
}*/

#define KERNEL 3

float shadowSample(in sampler2DShadow shadowmap, in vec3 shadowcoord)
{
#if KERNEL == 1
 	return textureLod(shadowmap, shadowcoord, 0.0f);
#endif
#if KERNEL == 2
	float sz = 0.5f / float(textureSize(shadowmap, 0).x);
	float f = textureLod(shadowmap, shadowcoord + vec3(sz, sz, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec3(-sz, sz, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec3(-sz, -sz, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec3(sz, -sz, 0.0f), 0.0f);
	return f * 0.25f;
#endif
#if KERNEL == 3
	float sz = 1.0f / float(textureSize(shadowmap, 0).x);
	float f = texture(shadowmap, shadowcoord + 	vec3(sz, 	sz,		0.0f));
	f += texture(shadowmap, shadowcoord + 		vec3(-sz, 	sz, 	0.0f));
	f += texture(shadowmap, shadowcoord + 		vec3(sz, 	-sz, 	0.0f));
	f += texture(shadowmap, shadowcoord + 		vec3(-sz, 	-sz, 	0.0f));
	if (f == 0.0f or f == 4.0f) return f * 0.25f;// if all corners are the same we can probably quit here
	f += texture(shadowmap, shadowcoord + 		vec3(sz, 	0.0f, 	0.0f));
	f += texture(shadowmap, shadowcoord + 		vec3(-sz, 	0.0f, 	0.0f));
	f += texture(shadowmap, shadowcoord + 		vec3(0.0f,	sz, 	0.0f));
	f += texture(shadowmap, shadowcoord);
	f += texture(shadowmap, shadowcoord + 		vec3(0.0f,	-sz, 	0.0f));
	return f * 0.11111f;
#endif
}

float shadowSample(in sampler2DArrayShadow shadowmap, in vec4 shadowcoord)
{
#if KERNEL == 1
 	return textureLod(shadowmap, shadowcoord, 0.0f);
#endif
#if KERNEL == 2
	float sz = 0.5f / float(textureSize(shadowmap, 0).x);
	float f = textureLod(shadowmap, shadowcoord + vec4(sz, sz, 0.0f, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec4(-sz, sz, 0.0f, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec4(-sz, -sz, 0.0f, 0.0f), 0.0f);
	f += textureLod(shadowmap, shadowcoord + vec4(sz, -sz, 0.0f, 0.0f), 0.0f);
	return f * 0.25f;
#endif
#if KERNEL == 3
	float sz = 1.0f / float(textureSize(shadowmap, 0).x);
	float f = texture(shadowmap, shadowcoord + 	vec4(sz, 	sz,		0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord + 		vec4(-sz, 	sz, 	0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord + 		vec4(sz, 	-sz, 	0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord + 		vec4(-sz, 	-sz, 	0.0f, 0.0f));
	if (f == 0.0f or f == 4.0f) return f * 0.25f;// if all corners are the same we can probably quit here
	f += texture(shadowmap, shadowcoord + 		vec4(sz, 	0.0f, 	0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord + 		vec4(-sz, 	0.0f, 	0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord + 		vec4(0.0f,	sz, 	0.0f, 0.0f));
	f += texture(shadowmap, shadowcoord);
	f += texture(shadowmap, shadowcoord + 		vec4(0.0f,	-sz, 	0.0f, 0.0f));
	return f * 0.11111f;
#endif
}

#ifdef LIGHTING_PBR

#include "../PBR/PBRInputs.glsl"
#include "../PBR/PBRLighting.glsl"

#endif

#ifdef DOUBLE_FLOAT
	#define xfloat double
	#define xvec4 dvec4
	#define xvec3 dvec3
	#define xvec2 dvec2
#else
	#define xfloat float
	#define xvec4 vec4
	#define xvec3 vec3
	#define xvec2 vec2
#endif

struct StripLightDiffusePoints
{
	xvec3 distancePoint;
	xvec3 normalPoint;
};

StripLightDiffusePoints LineClosestPoint(in xvec3 Point, in xvec3 a, in xvec3 b, in xvec3 normal)
{
	StripLightDiffusePoints result;
	xvec3 c = Point - a;	// Vector from a to Point
	xvec3 v = (b - a);	// Unit Vector from a to b

	xfloat d = lengthFast(b - a);	// Length of the line segment
	v /= d;
	xvec3 nv = v;
	xfloat t = dot(v,c);	// Intersection point Distance from a

	// Check to see if the point is on the line
	// if not then return the endpoint
	t = clamp(t, 0.0f, d);

	// get the distance to move from point a
	v *= t;
	result.distancePoint = a + v;
	//}

	xfloat dp = dot(nv,normal);

	if (dp > 0.0)
	{
		result.normalPoint = mix(result.distancePoint, (b + result.distancePoint) * 0.5, dp);
	}
	else
	{
		result.normalPoint = mix(result.distancePoint, (a + result.distancePoint) * 0.5, -dp);
	}
	return result;
	// move from point a to the nearest point on the segment
	//return a + v;
}

#include "../Math/Plane.glsl"

//int lightIndex;
float d;
vec3 light;
int n;
ivec3 icoord;
int lightGridDataSize;
uint lightlistpos;
uint countLights;
//vec3 lightDir;
float falloff;
vec2 lightconeanglescos;
float denom;	
//float anglecos;
vec3 lightreflection;
vec3 reflection;
int type;
vec3 delta;
int lrgb;
#ifdef DOUBLE_FLOAT
//dmat4 lightmatrix;
//dvec3 lightposition;
double aspect;
dvec3 coord;
dvec3 lightposition2;
#else
//mat4 lightmatrix;
//vec3 lightposition;
float aspect;
vec3 coord;
vec3 lightposition2;
#endif

#include "../Utilities/DepthFunctions.glsl"

float DistanceAttenuation(in float dist, in float range, in int mode)
{
	if (mode == LIGHTFALLOFF_INVERSESQUARE)
	{
		return sqrt(max(1.0f - dist / range, 0.0f));
	}
	return max(1.0f - dist / range, 0.0f);
	//return clamp( pow((1.0f - pow((dist / range), 4.0f) ), 2.0f) / (pow(dist, 2.0f) + 1.0f), 0.0f, 1.0f);
}

uint ReadLightGridValue(in uint lightlistpos)
{
	return lightGrid[lightlistpos];

	/*uvec4 lightgridinfo;
	uint prevlightgridposition = -1;
	uint lightlistpos_over_4 = lightlistpos / 4;
	if (lightlistpos_over_4 != prevlightgridposition) lightgridinfo = lightGrid[lightlistpos_over_4];
	return lightgridinfo[lightlistpos - lightlistpos_over_4 * 4];*/
	//return lightGrid[lightlistpos_over_4][lightlistpos - lightlistpos_over_4 * 4];
}

ivec3 GetLightingGridCell(in vec3 cameraSpacePosition)
{
	ivec3 icoord;
	uint lightIndex;
	float aspect = BufferSize.y / BufferSize.x;
	const float cameraSpacePositionZ_over_one = 1.0f / cameraSpacePosition.z;
#ifdef DOUBLE_FLOAT
	dvec3 coord;
	//coord.x = double(CameraZoom) * aspect * cameraSpacePosition.x * cameraSpacePositionZ_over_one * 0.5f + 0.5f;
	//coord.y = double(CameraZoom) * cameraSpacePosition.y * cameraSpacePositionZ_over_one * 0.5f + 0.5f;
	//coord.z = cameraSpacePosition.z / double(CameraRange[1]);
#else
	vec3 coord;
	//coord.x = CameraZoom * aspect * cameraSpacePosition.x * cameraSpacePositionZ_over_one * 0.5f + 0.5f;
	//coord.y = CameraZoom * cameraSpacePosition.y * cameraSpacePositionZ_over_one * 0.5f + 0.5f;
	//coord.z = cameraSpacePosition.z / CameraRange[1];
#endif
	//coord = CameraPositionToScreenCoord(cameraSpacePosition * vec3(1.0f,-1.0f,1.0f));
	coord = CameraPositionToScreenCoord2(cameraSpacePosition);
	coord.z = cameraSpacePosition.z / CameraRange.y;
	if (coord.z > 0.0f) coord.z = pow(coord.z, 0.55f);
	icoord.x = clamp(int(coord.x * float(lightGridSize.x)), 0, lightGridSize.x - 1);
	icoord.y = clamp(int(coord.y * float(lightGridSize.y)), 0, lightGridSize.y - 1);
	icoord.z = clamp(int(coord.z * float(lightGridSize.z)), 0, lightGridSize.z - 1);	
	return icoord;
}

uint GetGlobalLightsReadPosition()
{
	return LightGridOffset + ReadLightGridValue(LightGridOffset);//lightGridSize.x * lightGridSize.y * lightGridSize.z + 0;
}

uint GetCellLightsReadPosition(in vec3 cameraSpacePosition)
{
	ivec3 cellcoord = GetLightingGridCell(cameraSpacePosition);
	return LightGridOffset + ReadLightGridValue(LightGridOffset + 1 + cellcoord.z * lightGridSize.y * lightGridSize.x + cellcoord.y * lightGridSize.x + cellcoord.x);
}

#include "Materials.glsl"

#endif