#version 460
#extension GL_ARB_bindless_texture : enable

#define UNIFORMSTARTINDEX 2

#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/ReconstructPosition.frag"
#include "../Utilities/DepthFunctions.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/Lighting.glsl"
#include "../Math/Math.glsl"
#include "../Khronos/tonemapping.glsl"

//Outputs
layout(location = 0) out vec4 outColor;

layout(location = 0, binding = 0) uniform sampler2DMS DepthBuffer;
layout(location = 1, binding = 1) uniform sampler2D PrevBuffer;

const float StepSize = 0.05f;
const int MaxSteps = 128;
const float G_SCATTERING_DEFAULT = 0.7f;
const float G_SCATTERING_DIRECTIONAL = 0.7f;
const float exposure = 20.0f;
const float gamma = 2.2;

#define saturate(x) clamp(x,0,1)

#define PI 3.1415926536f

float ComputeScattering(float lightDotView, float g)
{
float result = 1.0 - g * g;
result /= (4.0f * PI * pow(1.0f + g * g - (2.0f * g) *      lightDotView, 1.5f));
return result;
}

#define BAYER_LIMIT 16
#define BAYER_LIMIT_H 4

// 4 x 4 Bayer matrix
const int bayerFilter_[BAYER_LIMIT] = int[]
(
	 0,  8,  2, 10,
	12,  4, 14,  6,
	 3, 11,  1,  9,
	15,  7, 13,  5
);

const mat4 bayerMat = mat4(
    0.0f, 0.5f, 0.125f, 0.625f,
    0.75f, 0.22f, 0.875f, 0.375f,
    0.1875f, 0.6875f, 0.0625f, 0.5625,
    0.9375f, 0.4375f, 0.8125f, 0.3125
);

#define PHI 1.6180339

#define Bayer4(a)   (Bayer2(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer128(a) (Bayer64( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer256(a) (Bayer128(0.5 * (a)) * 0.25 + Bayer2(a))

const float TAU = radians(360.0f);
const float PHI2 = sqrt(5.0f) * 0.5f + 0.5f;
const float GOLDEN_ANGLE = TAU / PHI2 / PHI2;

float Bayer2(vec2 a) 
{
    a = floor(a);
    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

bool writeToPixel(vec2 fragCoord)
{
	return fract(fract(mod(float(CurrentFrame), 384.0f) * (1.0 / PHI)) + Bayer16(fragCoord)) > 0.5;
    ivec2 iFragCoord = ivec2(fragCoord);
    uint index = CurrentFrame % BAYER_LIMIT;
	 //uint index = uint(CurrentTime * 0.001) % BAYER_LIMIT;
    return (((iFragCoord.x + BAYER_LIMIT_H * iFragCoord.y) % BAYER_LIMIT)
            == bayerFilter_[index]);	
}

float ScatteringIntegral(vec3 cameraPos, vec3 lightPos, vec3 direction, float thickness) {
    
    vec3 lightToCam = cameraPos - lightPos;

    // coefficients
    float direct = dot(direction, lightToCam);
    float scattered = dot(lightToCam, lightToCam);
    //c = length(lightToCam)*length(lightToCam);

    // evaluate integral
    float scattering = 1.0 / sqrt(scattered - direct*direct);
    return scattering*(atan( (thickness+direct)*scattering) - atan(direct*scattering));
}

float HG( float sundotrd, float g) {
	float gg = g * g;
	return (1. - gg) / pow( 1. + gg - 2. * g * sundotrd, 1.5);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 RenderLight(in uint lightIndex, in vec3 position, in vec3 normal)
{	
	float g = G_SCATTERING_DEFAULT; //default for all lights except directional
	bool backfacing = false;
	float visibility = 0.0f;
	int ShadowSoftness = 4;
	const float minlight = 0.004f;
	vec3 shadowCoord, lightDir, lightPosition;
	vec4 color;
	vec4 specular;
	bool transparent = false;
	mat4 lightmatrix;
	uint flags, lightflags;
	int lighttype;
	uvec2 shadowmap;
	uint shadowMapLayer;
	float attenuation = 1.0f;
	int shadowkernel;
	vec4 cascadedistance;
	dFloat d;
#ifdef DOUBLE_FLOAT
	dvec2 lightrange, coneangles, shadowrange;
#else
	vec2 lightrange, coneangles, shadowrange;
#endif
	uint decal;
	uint materialid;
	
//	struct EntityExtras
//{
//    vec3 emissioncolor;
//    vec2 textureoffset;
//    vec2 texturescale;
//    float texturerotation;
//};

    EntityExtras extras = ExtractEntityExtras(lightIndex);
	EntityInfo info = ExtractEntityInfo(lightIndex);	
	
	ExtractEntityInfo(lightIndex, lightmatrix, color, flags, decal);	
	if (color.a < 0.001f) return vec3(0.0f);
	
	ExtractLightInfo(lightIndex, shadowmap, lightrange, coneangles, shadowrange, lightflags, shadowkernel, cascadedistance, materialid);
	color = sRGBToLinear(color);
	specular = color;

	const int falloffmode = ((lightflags & ENTITYFLAGS_LIGHT_LINEARFALLOFF) != 0) ? LIGHTFALLOFF_LINEAR : LIGHTFALLOFF_INVERSESQUARE;
	if ((lightflags & ENTITYFLAGS_LIGHT_STRIP) != 0) lighttype = LIGHT_STRIP; // This needs to come first because the flag is a combination of others
	else if ((lightflags & ENTITYFLAGS_LIGHT_BOX) != 0) lighttype = LIGHT_BOX;
	else if ((lightflags & ENTITYFLAGS_LIGHT_DIRECTIONAL) != 0) lighttype = LIGHT_DIRECTIONAL;
	else if ((lightflags & ENTITYFLAGS_LIGHT_SPOT) != 0) lighttype = LIGHT_SPOT;
	else if ((lightflags & ENTITYFLAGS_LIGHT_DECAL) != 0) lighttype = LIGHT_DECAL;
	else if ((lightflags & ENTITYFLAGS_LIGHT_PROBE) != 0) lighttype = LIGHT_PROBE;
	else lighttype = LIGHT_POINT;
	if (lighttype == LIGHT_DECAL) return vec3(0);

	//if(extras.texturescale.y < 0.000001 && lighttype != LIGHT_DIRECTIONAL)
	//	return vec3(0.0);
	
	if(lighttype == LIGHT_DIRECTIONAL)
		extras.texturescale.y = 100.0;
		
	float intensity = extras.texturescale.y / 100.0; 
	
	switch (lighttype)
	{
	case LIGHT_SPOT:
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(position - lightPosition);
#else
		lightDir = position - lightPosition;
#endif
		float dp = dot(lightDir, normal);
		//if (dp > 0.0f) return vec3(0.0);	//no!	
		float dist_ = length(lightDir);
		lightDir /= dist_;
		dp = dot((lightDir), (normal));

		mat4 camerainfomatrix = ExtractCameraInfoMatrix(lightIndex, 0);
		float zoom = camerainfomatrix[2].z;

		shadowCoord.xyz = (inverse(lightmatrix) * vec4(position, 1.0f)).xyz;
		shadowCoord.xy /= shadowCoord.z * 2.0f / zoom;
		shadowCoord.y *= -1.0f;
		shadowCoord.xy += 0.5f;
		if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f || shadowCoord.z < lightrange.x || shadowCoord.z > lightrange.y) return vec3(0.0);
		vec3 spotvector = normalize(lightmatrix[2].xyz);
		float anglecos = dot(spotvector, lightDir);
		if (anglecos < coneangles.x) return vec3(0.0);
		if (anglecos < coneangles.y) attenuation *= 1.0f - (abs(anglecos - coneangles.y)) / abs(coneangles.x - coneangles.y);
		attenuation *= DistanceAttenuation(dist_, lightrange.y, falloffmode);
		if (shadowmap != uvec2(0))
		{
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(lightIndex);
			if (shadowrendermatrix != lightmatrix)
			{
				shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
				shadowCoord.xy /= shadowCoord.z * 2.0f / zoom;
				shadowCoord.y *= -1.0f;
				shadowCoord.xy += 0.5f;
			}
			shadowCoord.z *= 0.98f;
			shadowCoord.z = PositionToDepth(shadowCoord.z, shadowrange);
			//shadowCoord.w = shadowCoord.z;
			//shadowCoord.z = float(shadowMapLayer - 1);
			//attenuation *= shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
			attenuation *= texture(sampler2DShadow(shadowmap), shadowCoord).r;
		}
		//return vec3(0,100,0) * attenuation;
		break;

	case LIGHT_PROBE:
		return vec3(0.0);
		break;

	case LIGHT_POINT:
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(position - lightPosition);
#else
		lightDir = position - lightPosition;
#endif
		d = dot(lightDir, lightDir);
		//if (d > lightrange.y * lightrange.y) return vec3(0.0);

		if (d > 0.0f)
		{
			d = sqrt(d);
			lightDir /= d;
			attenuation *= DistanceAttenuation(d, lightrange.y, falloffmode);
			if (attenuation <= minlight) return vec3(0.0);
		}

		if ( shadowmap != uvec2(0) )
		{
			shadowCoord.xyz = position - ExtractLightShadowRenderPosition(lightIndex);
			int majoraxis = getMajorAxis(shadowCoord.xyz);
			int face = majoraxis * 2;
			if (shadowCoord[majoraxis] < 0.0f) ++face;
			mat4 lightProjMat = ExtractCameraProjectionMatrix(lightIndex, face);
			shadowCoord.xyz = (lightProjMat * vec4(position, 1.0f)).xyz;
			shadowCoord.xy /= shadowCoord.z * 2.0f;
			shadowCoord.xy += 0.5f;

			float dp = 1.0f - dot(normal, lightDir);
			float angle = radians(90.0f * dp);
			shadowCoord.z *= 0.99f;
			shadowCoord.z = PositionToDepth(shadowCoord.z, lightrange);
			//shadowCoord.z = float(shadowMapLayer - 1 + face);
			//attenuation *= textureLod(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord, 0.0f).r;
			vec4 cubeshadowcoord;
			cubeshadowcoord.xyw = shadowCoord;
			cubeshadowcoord.z = face;
			attenuation *= shadowSample(sampler2DArrayShadow(shadowmap), cubeshadowcoord).r;		
			//attenuation *= shadowSample(samplerCubeShadow(shadowmap), shadowCoord).r;	
		}
		break;
		
	case LIGHT_BOX:
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		//if (dot(lightDir, normal) > 0.0f) return vec3(0.0);
		shadowCoord.xyz = (inverse(lightmatrix) * vec4(position, 1.0f)).xyz;
		shadowCoord.y *= -1.0f;
		shadowCoord.xy /= coneangles;
		shadowCoord.xy += 0.5f;
		if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f || shadowCoord.z < shadowrange.x || shadowCoord.z > shadowrange.y) return vec3(0.0);
		//f_diffuse = vec3(shadowCoord.z / (lightrange.y - lightrange.x));
		//return 1;
		if ( shadowmap != uvec2(0) )
		{
			//shadowCoord.z -= shadowrange.x;
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(lightIndex);
			shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
			shadowCoord.y *= -1.0f;
			shadowCoord.xy /= coneangles;
			shadowCoord.xy += 0.5f;
			shadowCoord.z = (shadowCoord.z - shadowrange.x) / (shadowrange.y - shadowrange.x);
			shadowCoord.z -= 0.001f;
			//shadowCoord.z = float(shadowMapLayer.x - 1);
			//attenuation *= shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
			attenuation *= shadowSample(sampler2DShadow(shadowmap), shadowCoord).r;
		}
		break;

	case LIGHT_DIRECTIONAL:
		g = G_SCATTERING_DIRECTIONAL;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		vec3 camspacepos = (CameraInverseMatrix * vec4(position, 1.0)).xyz;
		mat4 shadowmat;
		visibility = 1.0f;
		if (camspacepos.z <= cascadedistance[3])
		{
			int index = 0;
			shadowmat = ExtractCameraProjectionMatrix(lightIndex, index);
			if (camspacepos.z > cascadedistance[0]) index = 1;
			if (camspacepos.z > cascadedistance[1]) index = 2;
			if (camspacepos.z > cascadedistance[2]) index = 3;
			uint sublight = floatBitsToUint(shadowmat[0][index]);
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(sublight);
			shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
			shadowCoord.y *= -1.0f;
			ExtractLightInfo(sublight, coneangles, shadowkernel, shadowmap);
			shadowCoord.xy /= coneangles;
			shadowCoord.xy += 0.5f;
			shadowrange = vec2(-500, 500);
			if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f) return vec3(0.0);
			if ( shadowmap != uvec2(0) )
			{
				shadowCoord.z = PositionToLinearDepth(shadowCoord.z, shadowrange);
				shadowCoord.z -= 0.00015f * float(index + 1);	
				//shadowCoord.z = float(shadowMapLayer.x - 1);
				//float samp = shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
				float samp = shadowSample(sampler2DShadow(shadowmap), shadowCoord).r;
				//cascadedistance *= 8.0f;
				if (camspacepos.z > cascadedistance[3] * 0.9f) samp = 1.0f - (1.0f - samp) * (1.0 - (camspacepos.z - cascadedistance[3] * 0.9f) / (cascadedistance[3] * 0.1f));
				visibility = samp;
				//probespecular.a = 1.0f - visibility;
				attenuation *= samp;
			}
		}
		break;
	
	default:
		return vec3(0.0);
		break;
	}
	
	if (attenuation <= minlight) return vec3(0.0f);
	intensity = 1.0f;
	float hg = 1.0f;//max(0.0,HG(dot(normalize(position - CameraPosition), -lightDir),g));
	return color.rgb  * hg * attenuation * intensity * color.a;
}

#ifdef DOUBLE_FLOAT
vec3 CalculateLighting(in dvec3 position, in dvec3 vertexCameraPosition, in dvec3 cameraPosition, in vec3 normal, in float specularity, in float glossiness, in float alpha, in bool transparent)
#else
vec3 CalculateLighting(in vec3 position, in vec3 vertexCameraPosition, in vec3 normal, in mat4 cullmat)
#endif
{
	vec3 lighting = vec3(0.0);
	
	uint n;
    uint lightIndex;
	uint countlights;
	float dirlightshadow = 1.0f;
	float skycolor = 0.0f;

	vec3 cameraspaceposition;
	//mat4 cullmat = ExtractCameraCullingMatrix(CameraID);
	cameraspaceposition = (cullmat * vec4(position, 1.0f) ).xyz;

    // Cell lights (affects this cell only)
    int lightlistpos = int(GetCellLightsReadPosition(cameraspaceposition));
    if (lightlistpos != -1)
    {
		uint countlights = ReadLightGridValue(uint(lightlistpos));
		if (countlights > 0)
		{
			for (uint  n = 0; n < countlights; ++n)
			{
				++lightlistpos;
				lightIndex = ReadLightGridValue(uint(lightlistpos));
				lighting += RenderLight(lightIndex, position.xyz, normal);
				if (lighting.r >= 1.0f && lighting.g >= 1.0f && lighting.b >= 1.0f) break;
			}
		}
		++lightlistpos;
    }
	
   	// Global lights (affects all cells)
	if (dirlightshadow > 0.0f)
	{
    	lightlistpos = int(GetGlobalLightsReadPosition());
		uint countlights = ReadLightGridValue(uint(lightlistpos));
    	if (countlights > 0) skycolor = 0.0f;
		if (countlights > 0)
		{
			for (uint n = 0; n < countlights; ++n)
			{
				++lightlistpos;
				lightIndex = ReadLightGridValue(uint(lightlistpos));
				lighting += RenderLight(lightIndex, position.xyz, normal);
			}
		}
	}
	
	return lighting;
}

vec3 GetSunVisibility(vec3 position, vec2 uv)
{
	vec3 volumeillumination = vec3(0.0f);
	const vec3 diffuseColor =  vec3(1.0);
    
    vec3 cameraPosition = CameraPosition;//GetFragmentCameraPosition();
    vec3 v = (position - cameraPosition);
    float dist = length(v);
    v /= dist;
    
    const float mult = 1.005;
    
	float illuminationDecay = 1.0;
	float weight = 1.0 / MaxSteps;
	float decay = 1.01;

    //float stepsize = dist / MaxSteps;
   
    mat4 cullmat = ExtractCameraCullingMatrix(CameraID);

    position = cameraPosition + v * CameraRange.x;
	
	float ditherValue = bayerMat[int(mod(uv.x, 4.f))][int(mod(uv.y, 4.f))];
	
	float stepsize = StepSize;

	float maxdistance = stepsize * (pow(mult, float(MaxSteps)) - 1.0f) / (mult - 1.0f);
	//float maxdistance = stepsize * pow(float(MaxSteps), mult);
	float fadebegin = maxdistance * 0.75f;

	float stepdistance = 0.0f;
	int n = 0;
    for (n = 0; n < MaxSteps; ++n)
    {
        vec3 illumination = CalculateLighting(position, vec3(0.0),vec3(0.0,1.0,0.0), cullmat);
			illumination *= illuminationDecay * weight;
			if (stepdistance > fadebegin)
			{
				illumination *= 1.0f - (stepdistance - fadebegin) / (maxdistance - fadebegin);
			}
			volumeillumination += illumination;
			if (volumeillumination.r >= 1.0f && volumeillumination.g > 1.0f && volumeillumination.b >= 1.0f) break;
			illuminationDecay *= decay;
		
        stepsize *= mult;
		stepdistance += stepsize;
        if (stepdistance >= dist || illuminationDecay < 0.0001) break;

        position += v * (stepsize);
	   //if (illuminationDecay < 0.01) break;
    }
	
	vec3 result = volumeillumination / n;
	// exposure tone mapping
	result = vec3(1.0) - exp(-result * exposure);
	// gamma correction 
	result = pow(result, vec3(1.0 / gamma));
		
	return result;
}

void main()
{
	vec3 position = GetFragmentWorldPosition(DepthBuffer,gl_SampleID);
	vec2 uvz = WorldPositionToScreenCoord(position).xy;
	float z = texelFetch(DepthBuffer, ivec2(uvz.x * DrawViewport.z, uvz.y * DrawViewport.w), 0).r;
	
	vec3 mapped = vec3(1.0,0.0,0.0);
	
	if(writeToPixel(gl_FragCoord.xy))
	{
		mapped = GetSunVisibility(position, uvz.xy);
	}
	else
	{
		CameraProjectionViewMatrix = PrevCameraProjectionViewMatrix;
		vec2 uv = WorldPositionToScreenCoord(position).xy;
		if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		{
			mapped = GetSunVisibility(position,uvz.xy);
		}
		else
		{
			mapped = sRGBToLinear(texture(PrevBuffer,uv.xy).rgb);
		}
	}
	
	outColor.rgb = saturate(linearTosRGB(mapped));
    outColor.a = z;
}