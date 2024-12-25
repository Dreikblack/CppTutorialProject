#ifndef _PBRLIGHTING
#define _PBRLIGHTING

//#include "../GI/GI.glsl"
#include "../Math/Math.glsl"
#include "../Math/FastSqrt.glsl"

//const float M_PI = 3.141592653589793f;
const float c_MinRoughness = 0.04f;

// The following equation models the Fresnel reflectance term of the spec equation (aka F())
// Implementation of fresnel from [4], Equation 15
vec3 specularReflection(PBRInfo pbrInputs)
{
    return pbrInputs.reflectance0 + (pbrInputs.reflectance90 - pbrInputs.reflectance0) * pow(clamp(1.0f - pbrInputs.VdotH, 0.0f, 1.0f), 5.0f);
}

float geometricOcclusion(PBRInfo pbrInputs)
{
	float rr = pbrInputs.alphaRoughness * pbrInputs.alphaRoughness;
    float attenuationL = 2.0f * pbrInputs.NdotL / (pbrInputs.NdotL + sqrtFast(rr + (1.0f - rr) * (pbrInputs.NdotL * pbrInputs.NdotL)));
    float attenuationV = 2.0f * pbrInputs.NdotV / (pbrInputs.NdotV + sqrtFast(rr + (1.0f - rr) * (pbrInputs.NdotV * pbrInputs.NdotV)));
    return attenuationL * attenuationV;
}

// The following equation(s) model the distribution of microfacet normals across the area being drawn (aka D())
// Implementation from "Average Irregularity Representation of a Roughened Surface for Ray Reflection" by T. S. Trowbridge, and K. P. Reitz
// Follows the distribution function recommended in the SIGGRAPH 2013 course notes from EPIC Games [1], Equation 3.

float microfacetDistribution(PBRInfo pbrInputs)
{
    float microfacetDistribution_roughnessSq = pbrInputs.alphaRoughness * pbrInputs.alphaRoughness;
    float microfacetDistribution_f = (pbrInputs.NdotH * microfacetDistribution_roughnessSq - pbrInputs.NdotH) * pbrInputs.NdotH + 1.0f;
    return microfacetDistribution_roughnessSq / (M_PI * microfacetDistribution_f * microfacetDistribution_f);
}

// Basic Lambertian diffuse
// Implementation from Lambert's Photometria https://archive.org/details/lambertsphotome00lambgoog
// See also [1], Equation 1
vec3 diffuse(PBRInfo pbrInputs)
{
    return pbrInputs.diffuseColor;// / M_PI; //// Why are wwe dividing the diffuse color by Pi????
}

vec3 CalcLuminosity(PBRInfo pbrInputs, vec3 n, vec3 v, vec3 l, vec3 lightcolor, bool transparent)
{
	vec3 h;
	vec3 F;
	float G;
	float D;
	vec3 diffuseContrib;
	vec3 specContrib;

    h = normalizeFast(l + v);                          // Half vector between both l and v   
    pbrInputs.LdotH = clamp(dot(l, h), 0.0f, 1.0f);
    pbrInputs.VdotH = clamp(dot(v, h), 0.0f, 1.0f);
	pbrInputs.NdotH = clamp(dot(n, h), 0.0f, 1.0f);

	float NDotL = dot(n, l);
	bool spec = true;

	if (transparent == true && NDotL < 0.0f)
	{
		n *= -1.0f;
		NDotL = dot(n, l);
		spec = false;
	}

	pbrInputs.NdotL = clamp(NDotL, 0.001f, 1.0f);
	
	// Calculate the shading terms for the microfacet specular shading model
	F = specularReflection(pbrInputs);
	G = geometricOcclusion(pbrInputs);
	D = microfacetDistribution(pbrInputs);

	// Calculation of analytical lighting contribution
	specContrib = F * G * D / (4.0f * pbrInputs.NdotL * pbrInputs.NdotV);	
	diffuseContrib = (1.0f - F) * pbrInputs.diffuseColor;

    // Obtain final intensity as reflectance (BRDF) scaled by the energy of the light (cosine law)
    return pbrInputs.NdotL * lightcolor * (diffuseContrib + specContrib);
}

vec3 CalcLuminosity(in PBRInfo pbrInputs, in vec3 n, in vec3 v, in vec3 l, in vec3 lightcolor, in vec3 sl, in bool transparent)
{
	vec3 h;
	vec3 F;
	float G;
	float D;
	vec3 diffuseContrib;
	vec3 specContrib;

    h = normalizeFast(l + v);                          // Half vector between both l and v   
    pbrInputs.NdotL = clamp(dot(n, l), 0.001f, 1.0f);
    pbrInputs.NdotH = clamp(dot(n, h), 0.0f, 1.0f);
    pbrInputs.LdotH = clamp(dot(l, h), 0.0f, 1.0f);
    pbrInputs.VdotH = clamp(dot(v, h), 0.0f, 1.0f);

	float NdotL0 = pbrInputs.NdotL;

    // Calculate the shading terms for the microfacet specular shading model
    F = specularReflection(pbrInputs);
    G = geometricOcclusion(pbrInputs);
    D = microfacetDistribution(pbrInputs);

    // Calculation of analytical lighting contribution
    diffuseContrib = (1.0f - F) * diffuse(pbrInputs);

    h = normalizeFast(sl + v);                          // Half vector between both l and v   
    pbrInputs.NdotL = clamp(dot(n, sl), 0.001f, 1.0f);
    pbrInputs.NdotH = clamp(dot(n, h), 0.0f, 1.0f);
    pbrInputs.LdotH = clamp(dot(sl, h), 0.0f, 1.0f);
    pbrInputs.VdotH = clamp(dot(v, h), 0.0f, 1.0f);

    // Calculate the shading terms for the microfacet specular shading model
    F = specularReflection(pbrInputs);
    G = geometricOcclusion(pbrInputs);
    D = microfacetDistribution(pbrInputs);

    specContrib = F * G * D / (4.0f * pbrInputs.NdotL * pbrInputs.NdotV);

	//return pbrInputs.NdotL * lightcolor * min(vec3(30), specContrib);

    // Obtain final intensity as reflectance (BRDF) scaled by the energy of the light (cosine law)
    return NdotL0 * lightcolor * diffuseContrib + pbrInputs.NdotL * lightcolor * min(vec3(30.0f), specContrib);
}

#ifdef DOUBLE_FLOAT
vec3 getIBLContribution(PBRInfo pbrInputs, dvec3 p, vec3 n, vec3 reflection, int brdfIndex, in dvec3 surfacenormal, out float ao, in dvec3 geonormal)
{
	//Camera GI material containing VXRT textures
	int mtlid = int(entityMatrix[CameraID + CAMERA_INFO_OFFSET][0][1]);
#else
vec3 getIBLContribution(PBRInfo pbrInputs, vec3 p, vec3 n, vec3 reflection, int brdfIndex, in vec3 surfacenormal, out float ao, in vec3 geonormal)
{
	//Camera GI material containing VXRT textures
	mat4 cameraInfoMatrix = entityMatrix[CameraID + CAMERA_INFO_OFFSET];
	int GICameraID0 = floatBitsToInt(cameraInfoMatrix[0][0]);
	int mtlid = floatBitsToInt(cameraInfoMatrix[0][1]);
	int mtlid2 = floatBitsToInt(cameraInfoMatrix[0][2]);

#endif
	float mipcount;
	float lod;
	vec3 brdf;
	vec3 diffuseLight = vec3(0.0f);
	vec3 specularLight = vec3(0.0f);
	vec3 diffuse;
	vec3 specular;
	vec4 vxrtdiffuse = vec4(0.0f);
	vec4 vxrtspecular = vec4(0.0f);

	/*if (mtlid != -1 && mtlid2 != -1)
	{
		float diffuseao = 1.0f, specularao = 1.0f;
		uint flags = materials[mtlid].flags;//GetMaterialFlags(materials[mtlid]);
		if (pbrInputs.metalness > 0.0f)
		{
			if (pbrInputs.perceptualRoughness == 1.0f)
			{
				//Nice idea but it just looks like diffuse
				vec3 viewdir = normalizeFast(p - CameraPosition);
				vec3 reflectdir = reflect(viewdir, n);
				vxrtspecular = GIDiffuse(p, reflectdir, materials[mtlid], materials[mtlid2], diffuseao, reflectdir, entityflags);
				vxrtspecular /= GIDIFFUSETRANSMISSION;
				vxrtspecular *= GISPECULAROVERDRIVE;
				vec2 brdf = texture(texture2DSampler[brdfIndex], vec2(pbrInputs.NdotV, pbrInputs.perceptualRoughness)).rg;
				vxrtspecular.rgb *= (pbrInputs.specularColor * (brdf.x + brdf.y));
			}
			else
			{
				vxrtspecular = GISpecular(pbrInputs, p, n, materials[mtlid], materials[mtlid2], brdfIndex, geonormal, specularao);
			}
			return vxrtspecular.rgb;
		}
		if (pbrInputs.metalness < 1.0f && (pbrInputs.diffuseColor.r + pbrInputs.diffuseColor.g + pbrInputs.diffuseColor.b > 0.0f))
		{
			vxrtdiffuse = GIDiffuse(p, n, materials[mtlid], materials[mtlid2], diffuseao, geonormal, ENTITYFLAGS_STATIC);
			vxrtdiffuse.rgb *= pbrInputs.diffuseColor;
		}
		ao = min(specularao, diffuseao);
	}
	else
	{
		ao = 1.0f;
	}*/
	//vxrtdiffuse.a = 1.0f;
	//vxrtspecular.a = 1.0f;
	//vxrtdiffuse = vec4(0,0,0,1);
	//vxrtspecular = vec4(0,0,0,1);
	const float cutoff = 1.0f;
	//vxrtdiffuse.a = 0.0f;
	vxrtdiffuse.a = max(vxrtdiffuse.a - SKyVisibility, 0.0f);
	//SKyVisibility = 0.0f;

	// No skybox textures or 100% coverage, so skip skybox
	//if ((vxrtdiffuse.a - SKyVisibility >= cutoff && vxrtspecular.a >= cutoff)) return (vxrtdiffuse + vxrtspecular).rgb;

	//This is causing weird problems
	/*if (skyTextureIndex.y == -1)
	{
	//	float dp = (dot(reflection, vec3(0,1,0)) + 1.0f);
	//	if (pbrInputs.metalness > 0.0f)
	//	{
	//		specularLight = (mix(AmbientLight * 0.5f,AmbientLight * 1.5f,dp));// comment these two lines out to see a weird bug
	//	}
	//	dp = dot(n, normalize(vec3(1.25f,1.5,0.75f)));
	//	diffuseLight = (mix(AmbientLight * 0.75f,AmbientLight * 1.25f,dp));// comment these two lines out to see a weird bug
	}
	else
	{
		mipcount = textureQueryLevels(textureCubeSampler[skyTextureIndex.y]);//Log2(float(textureSize(textureCubeSampler[skyTextureIndex.y],0).x)); // resolution of 512x512
		lod = (pbrInputs.perceptualRoughness * (mipcount - 1));
		lod = clamp(lod, 0, mipcount-1);
		diffuseLight = (textureLod(textureCubeSampler[skyTextureIndex.y], n, mipcount).rgb);// * ambientLight.rgb;
		if (pbrInputs.metalness > 0.0f)
		{
			specularLight = (textureLod(textureCubeSampler[skyTextureIndex.y], reflection, lod).rgb);
		}
		specularLight = (textureLod(textureCubeSampler[skyTextureIndex.y], reflection, 0.0f).rgb);
	}*/
	
	//vxrtdiffuse.a = 0.0f;
	//diffuseLight = vec3(1,0,1);

	vec3 ambience = AmbientLight * pbrInputs.diffuseColor;
    diffuse = diffuseLight * pbrInputs.diffuseColor;// + ambience;

	if (pbrInputs.metalness > 0.0f)
	{
		// retrieve a scale and bias to F0. See [1], Figure 3
	    brdf = 4.0f * (texture(texture2DSampler[brdfIndex], vec2(pbrInputs.NdotV, pbrInputs.perceptualRoughness)).rgb);
		specular = specularLight * (pbrInputs.specularColor * (brdf.x + brdf.y));// + ambience;
	}
	
	//vec3 v = diffuse + specular;
	return diffuse * (1.0f - vxrtdiffuse.a) + vxrtdiffuse.rgb + specular * (1.0f - vxrtspecular.a) + vxrtspecular.rgb;
}
#endif