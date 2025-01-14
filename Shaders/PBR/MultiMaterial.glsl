//#define MAX_MATERIALS 4

const float smoothness = 0.75f;
const uvec2 NullHandle = uvec2(0);

vec3 sharpmix(in vec3 color1, in vec3 color2, in float alpha, in float smoothness)
{
	if (smoothness == 1.0f) return mix(color1, color2, alpha);
	
	// Define the edges for the smoothstep function
    float edge0 = 0.5 - smoothness * 0.5f; // Lower edge
    float edge1 = 0.5 + smoothness * 0.5f; // Upper edge

    // Calculate the smooth interpolation factor
    //float smoothAlpha = smoothstep(edge0, edge1, alpha);
	float smoothAlpha = clamp((alpha - edge0) / (edge1 - edge0), 0.0f, 1.0f);

    // Perform the mix using the smooth interpolation factor
    return mix(color1, color2, smoothAlpha);
}

vec4 sharpmix(vec4 color1, vec4 color2, in float alpha, in float smoothness)
{
	if (smoothness == 1.0f) return mix(color1, color2, alpha);
	
	// Define the edges for the smoothstep function
    float edge0 = 0.5 - smoothness * 0.5f; // Lower edge
    float edge1 = 0.5 + smoothness * 0.5f; // Upper edge

    // Calculate the smooth interpolation factor
    //float smoothAlpha = smoothstep(edge0, edge1, alpha);
	float smoothAlpha = clamp((alpha - edge0) / (edge1 - edge0), 0.0f, 1.0f);

    // Perform the mix using the smooth interpolation factor
    return mix(color1, color2, smoothAlpha);
}

/*float CalculateBlendAlpha(in float alpha, in float smoothness)
{
	// Define the edges for the smoothstep function
    float edge0 = 0.5 - smoothness * 0.5f; // Lower edge
    float edge1 = 0.5 + smoothness * 0.5f; // Upper edge

    // Calculate the smooth interpolation factor
    return clamp((alpha - edge0) / (edge1 - edge0), 0.0f, 1.0f);
}*/

float CalculateBlendAlpha(in float alpha, in float smoothness)
{
    // Calculate the smooth interpolation factor directly
    return clamp((alpha - (0.5f - smoothness * 0.5f)) / (smoothness), 0.0f, 1.0f);
}

vec4 PBRBaseColor(in Material material, in vec2 texcoords)
{
	vec4 subs = material.diffuseColor;
	uvec2 handle = material.textureHandle[TEXTURE_BASE];
	if (handle != NullHandle)
	{
		subs *= texture(sampler2D(handle), texcoords);
		//if (material.saturation != 1.0f) 
		subs.rgb = mix(vec3(subs.r * 0.299f + subs.g * 0.587f + subs.b * 0.114f), subs.rgb, material.saturation);
		/*if ((material.flags & MATERIAL_BLEND_ALPHA) != 0)
		{
			weight *= subs.a;// alpha blended materials
		}
		if (material.alphacutoff > 0.0f)
		{
			if (subs.a < material.alphacutoff) weight = 0.0f;// alpha discard
		}*/
	}
	return subs;
}

vec3 PBRNormals(in Material material, in vec2 texcoords, in float normalscale)
{
	vec3 normal = vec3(0.0f);
	vec3 subsample;
	uvec2 handle = material.textureHandle[TEXTURE_NORMAL];
	if (handle == NullHandle) return vec3(0.0f);
	{
		normal = texture(sampler2D(handle), texcoords).rgb * 2.0f - 1.0f;
		//normal = sharpmix(normal, subsample, weight, material.blendsmoothing);
		//if ((material.flags & MATERIAL_EXTRACTNORMALMAPZ) != 0) normal.z = sqrt(max(0.0f, 1.0f - (normal.x * normal.x + normal.y * normal.y)));
		normal.xy *= normalscale;
	}
	return normal;
}

void PBRNormals(out vec3 normal, in Material material, in vec2 texcoords, in float normalscale)
{
	uvec2 handle = material.textureHandle[TEXTURE_NORMAL];
	if (handle == NullHandle)
	{
		normal = vec3(0.0f);
		return;
	}
	{
		normal = texture(sampler2D(handle), texcoords).rgb * 2.0f - 1.0f;		
		normal.xy *= normalscale;
		if ((material.flags & MATERIAL_EXTRACTNORMALMAPZ) != 0) normal.z = sqrt(max(0.0f, 1.0f - (normal.x * normal.x + normal.y * normal.y)));
	}
}

vec3 PBROcclusionMetalRoughness(in Material material, in vec2 texcoords, in float occlusionscale)
{
	vec3 s = vec3(0.0f, 1.0f, 0.0f);
	vec3 subsample;
	vec4 ts;
	subsample.r = 1.0f;
	subsample.g = material.roughness;
	subsample.b = material.metalness;
	uvec2 handle = material.textureHandle[TEXTURE_METALLICROUGHNESS];
	if (handle != NullHandle)
	{
		ts = texture(sampler2D(handle), texcoords);
		subsample.r = mix(1.0, ts.r, occlusionscale);
		subsample.gb *= ts.gb;
	}
	return subsample;
}

vec3 PBREmissionColor(in Material material, in vec2 texcoords)
{
	vec3 s = vec3(0.0f);
	vec3 subs;
	subs = material.emissiveColor.rgb;
	uvec2 handle = material.textureHandle[TEXTURE_EMISSION];
	if (handle != NullHandle)
	{
		subs *= texture(sampler2D(handle), texcoords).rgb;
	}
	return subs;
	//s = sharpmix(s, subs, weight, material.blendsmoothing);
	//return s;
}

float PBRDisplacement(in Material material, in vec2 texcoords, inout float weight)
{
	float displacement = 0.0f;
	float subsample, h;
	uvec2 handle = material.textureHandle[TEXTURE_DISPLACEMENT];
	if (handle != NullHandle)
	{
		subsample = texture(sampler2D(handle), texcoords).r;
		h = subsample;

		//Not sure if this should be included in the height value or not
		/*if (n > 0)
		{
			weight += (h - 0.5) * material.displacementblend * weight;
			weight = clamp(weight, 0.0f, 1.0f);
		}*/
		
		subsample = subsample * material.displacement.x + material.displacement.y; 
		displacement = mix(displacement, subsample, weight);
	}
	return displacement;
}

void PBRMaterial(in Material material, in vec2 texcoords, out vec4 color, out vec3 normal, out vec3 omr, out vec3 emissive)
{
	vec2 occlusion_normalscale = unpackHalf2x16(material.occlusion);

    color = PBRBaseColor(material, texcoords.xy);
	normal = PBRNormals(material, texcoords.xy, occlusion_normalscale.y);
    omr = PBROcclusionMetalRoughness(material, texcoords.xy, occlusion_normalscale.x);
    emissive = PBREmissionColor(material, texcoords.xy);
#if MAX_MATERIALS == 1
	if ((material.flags & MATERIAL_EXTRACTNORMALMAPZ) != 0) normal.z = sqrt(max(0.0f, 1.0f - (normal.x * normal.x + normal.y * normal.y)));
#endif   
}

void PBRMaterial(in Material material, in vec2 texcoords, inout float weight, inout vec4 color, inout vec3 normal, inout vec3 omr, inout vec3 emissive)
{
	vec2 occlusion_normalscale = unpackHalf2x16(material.occlusion);

	texcoords += GetMaterialTextureOffset(material, CurrentTime).xy;
	vec4 cc = PBRBaseColor(material, texcoords);
	if ((material.flags & MATERIAL_BLEND_ALPHA) != 0)
	{
		weight *= cc.a;// alpha blended materials
		if (weight == 0.0f) return;
	}
	if (material.alphacutoff > 0.0f && cc.a < material.alphacutoff)
	{
		weight = 0.0f;// alpha discard
		return;
	}

	uvec2 handle = material.textureHandle[TEXTURE_DISPLACEMENT];
	if (handle != NullHandle)
	{
		weight += (texture(sampler2D(handle), texcoords).r - 0.5) * /*material.displacementblend **/ weight;
		weight = clamp(weight, 0.0f, 1.0f);
	}
	
	weight = CalculateBlendAlpha(weight, material.blendsmoothing);
	//if (weight != 1.0f && material.blendsmoothing != 1.0f) weight = CalculateBlendAlpha(weight, material.blendsmoothing);
	//if (weight == 0.0f) return;
	color = mix(color, cc, weight);
	normal = mix(normal, PBRNormals(material, texcoords, occlusion_normalscale.y), weight);
    omr = mix(omr, PBROcclusionMetalRoughness(material, texcoords, occlusion_normalscale.x), weight);
    emissive = mix(emissive, PBREmissionColor(material, texcoords), weight);    
}
