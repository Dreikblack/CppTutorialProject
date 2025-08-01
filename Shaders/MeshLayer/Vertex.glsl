#include "../Base/DrawElementsIndirectCommand.glsl"
#include "../Base/Lighting.glsl"

#define MESHLAYER_ALIGN_CENTER 0
#define MESHLAYER_ALIGN_VERTEX 1
#define MESHLAYER_ALIGN_ROTATE 2

//Uniforms
layout(binding = 0) uniform sampler2D elevationmap;
layout(binding = 1) uniform sampler2D normalmap;
layout(location = 15) uniform ivec2 resolution;
layout(location = 16) uniform vec2 spacing = vec2(2.0f);
layout(location = 17) uniform uint offset = 0;
layout(location = 18) uniform vec3 terrainscale = vec3(1.0f);

layout(std430, binding = 8) buffer IndirectDrawBlock { DrawElementsIndirectCommand drawcommands[]; };
layout(binding = 9) buffer DrawInstancesIDBlock { uint instanceids[]; };
layout(binding = 11) buffer MeshLayerNoiseBlock { mat4 meshlayeroffsets[]; };

#include "../Base/Vertex.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/VertexLayout.glsl"
#include "../Base/Materials.glsl"

#ifdef IMPOSTER
layout(location = 29) flat out float cameraangle;
layout(location = 30) flat out vec3 suncolor;
layout(location = 31) flat out vec3 sundirection;
#endif

void main()
{
    color = vec4(1.0f);
    
    vec4 p;
    p.xyz = VertexPosition.xyz;
    p.w = 1.0f;

    int id = int(instanceids[gl_BaseInstanceARB + gl_InstanceID]);

    int y = id / resolution.x;
    int x = id - resolution.x * y;

    int noiseid = (y % 16) * 16 + (x % 16);
    mat4 noise = meshlayeroffsets[noiseid];

    uint alignment = drawcommands[gl_DrawID + offset].alignment;

    vec2 texcoord = vec2(0.0f);
#ifdef WRITE_COLOR
    emissioncolor = vec3(1.0f);
#endif
#ifdef IMPOSTER

    vec3 center;
    center.xz = vec2(x, y) * spacing;

    center.xz -= textureSize(elevationmap, 0) * 0.5f;
    center.xz += noise[3].xz;  
    texcoord = center.xz / textureSize(elevationmap, 0);    
    center.y = textureLod(elevationmap, texcoord, 0).r * terrainscale.y;

    mat4 mat = noise;
    mat[0][3] = 0.0f; mat[1][3] = 0.0f; mat[2][3] = 0.0f; mat[3][3] = 1.0f;
    mat[3].xyz = center;

    vec4 relcampos = inverse(mat) * vec4(CameraPosition, 1.0f);
    vec2 d = -relcampos.xz;

    cameraangle = mod(degrees(atan(d.x, d.y)), 360.0f);
    
    mat3 rotationmat;
    d = normalize(d);
    rotationmat[2].xyz = vec3(d.x, 0, d.y);
    rotationmat[1].xyz = vec3(0.0f, 1.0f, 0.0f);
    rotationmat[0].xyz = cross(rotationmat[2].xyz, rotationmat[1].xyz);

    p.xyz = rotationmat * p.xyz;
    
#endif

    if (alignment == MESHLAYER_ALIGN_ROTATE || alignment == MESHLAYER_ALIGN_CENTER)
    {
        vec2 center = vec2(x, y) * spacing;
        center += noise[3].xz;
        ivec2 ts = textureSize(elevationmap, 0);
        vec2 fts = vec2(ts.x, ts.y);    
        texcoord = (center + 0.5f) / fts;
       
        if (alignment == MESHLAYER_ALIGN_ROTATE)
        {
            vec2 ntexcoord = texcoord;

            vec3 n;
            n.xz = textureLod(normalmap, ntexcoord, 0).rg * 2.0f - 1.0f;
            n.y = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.z * n.z)));

            mat3 base;
            
            vec3 i, j, k;

            j = normalize(n);
            i = -normalize(cross(j, vec3(0,1,0)));
            k = normalize(cross(i, j));

            if (j.y > 0.5f)
            {
                //color = vec4(1,0,0,1);                
                float yaw = atan(n.x, n.z);
                float pitch = acos(n.y);
                vec4 q = RotationToQuat(pitch, yaw);
                float d = degrees(asin((j.y - 0.5f) * 2.0f)) / 90.0f;
                q = Slerp(q, vec4(0.0f, 0.0f, 0.0f, 1.0f), d);
                mat3 m = QuatToMat3(q);
                i = m[0];
                j = m[1];
                k = m[2];
            }
            
            base[0].xyz = i;
            base[1].xyz = j;
            base[2].xyz = k;

            base *= mat3(noise);
            noise[0].xyz = base[0];
            noise[1].xyz = base[1];
            noise[2].xyz = base[2];
        }
    }

    noise[0][3] = 0.0f; noise[1][3] = 0.0f; noise[2][3] = 0.0f; noise[3][3] = 1.0f;
    p = noise * p;

    if (alignment == MESHLAYER_ALIGN_VERTEX)
    {
        texcoord = (vec2(x, y) * spacing + p.xz + 0.5f) / textureSize(elevationmap, 0);

#ifndef DEPTHRENDER
        /*vec3 n;
        n.xz = textureLod(normalmap, texcoord, 0).rg * 2.0f - 1.0f;
        n.y = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.z * n.z)));
        normal = n;*/
#endif
    }

    p.xz -= textureSize(elevationmap, 0) * 0.5f;
    p.xz += vec2(x, y) * spacing;
    p.y += textureLod(elevationmap, texcoord, 0).r * terrainscale.y;

    vertexWorldPosition = p;
    flags = 0;

#ifdef WRITE_COLOR
    
    texCoords = VertexTexCoords;

    materialIndex[0] = drawcommands[gl_DrawID + offset].materialID;
    materialIndex[1] = 0;
    materialIndex[2] = 0;
    materialIndex[3] = 0;

    materialweights = vec4(1,0,0,0);

    #ifndef DEPTHRENDER
    
    //if (alignment != MESHLAYER_ALIGN_VERTEX)
    {
        ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
        mat3 nmat = mat3(noise);
        
        normal = normalize(nmat * normal);
        tangent = normalize(nmat * tangent);
        bitangent = normalize(nmat * bitangent);
    }

    #endif

#endif
	
	// Wind effect
	if ((drawcommands[gl_DrawID + offset].meshflags & MESHFLAGS_WIND) != 0)
	{
#ifdef DEPTHRENDER
		vec3 normal, tangent, bitangent;
		ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
        mat3 nmat = mat3(noise);        
        normal = normalize(nmat * normal);
#endif
		float seed = mod(CurrentTime * 0.0015f, 360.0f);
		seed += float(x) * 33.0f + float(y) * 67.8f;
		seed += VertexPosition.x + VertexPosition.y + VertexPosition.z;
		vec3 movement = normal * color.a * 0.02f * (sin(seed)+0.25f * cos(seed * 5.2f + 3.2f ));
		p.xyz += movement;		
	}


    mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, 0);
    gl_Position = cameraProjectionMatrix * p;

#ifdef IMPOSTER

    tangent = normalize(noise[0].xyz);
    bitangent = normalize(noise[1].xyz);
    normal = normalize(noise[2].xyz);

    suncolor = vec3(0.0f);
    uint lightlistpos = int(GetGlobalLightsReadPosition());
    uint countlights = ReadLightGridValue(lightlistpos);
    if (countlights > 0)
    {
        ++lightlistpos;
        uint lightIndex = ReadLightGridValue(uint(lightlistpos));
        mat4 lightmatrix;
        vec4 lightcolor;
        uint lightflags, lightdecallayers;
        ExtractEntityInfo(lightIndex, lightmatrix, lightcolor, lightflags, lightdecallayers);
        suncolor = lightcolor.rgb;
        sundirection = normalize(lightmatrix[2].xyz);
    }
#endif

}