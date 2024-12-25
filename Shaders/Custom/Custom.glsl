#include "../Base/SurfaceIO.glsl"

void UserHook(in SurfaceInput surfinput, out SurfaceOutput surfoutput)
{
    vec4 prevcolor = surfinput.color * surfinput.material.diffuseColor;
    surfoutput.basecolor = vec4(1.0f);
    uint mtlflags = surfinput.material.flags; //GetMaterialFlags(surfinput.material);

    //Base texture
    if (surfinput.material.textureHandle[TEXTURE_BASE] != uvec2(0))
    {
        surfoutput.basecolor = texture(sampler2D(surfinput.material.textureHandle[0]), surfinput.texcoords.xy);
    }
    
    //Normal map
    if (surfinput.material.textureHandle[TEXTURE_NORMAL] != uvec2(0))
    {
		vec4 nsample = texture(sampler2D(surfinput.material.textureHandle[TEXTURE_NORMAL]), surfinput.texcoords.xy);
        vec3 n = nsample.xyz * 2.0f - 1.0f;
        if ((mtlflags & MATERIAL_EXTRACTNORMALMAPZ) != 0) n.z = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.y * n.y)));
        surfoutput.normal = surfinput.tangent * n.x + surfinput.bitangent * n.y + surfinput.normal * n.z;
	}
    else
    {
        surfoutput.normal = surfinput.normal;
    }
    surfoutput.normal = normalize(surfoutput.normal);

    if (surfinput.material.textureHandle[6] != uvec2(0))
    {
        float mask = texture(sampler2D(surfinput.material.textureHandle[6]), surfinput.texcoords.xy).r;
        surfoutput.basecolor = surfoutput.basecolor * (1.0f - mask) + surfoutput.basecolor * prevcolor * mask;
    }
}

#include "../PBR/Fragment.glsl"