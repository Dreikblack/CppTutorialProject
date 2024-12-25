//Uniforms
layout(binding = 0) uniform sampler2D elevationmap;
layout(binding = 1) uniform sampler2D normalmap;
layout(location = 15) uniform ivec2 resolution;
layout(location = 16) uniform vec2 spacing = vec2(2.0f);
layout(location = 17) uniform uint offset = 0;
layout(location = 18) uniform int alignment = 0;

#include "../Base/Vertex.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/VertexLayout.glsl"
#include "../Base/Materials.glsl"
#include "../Base/Lighting.glsl"

layout(location = 30) flat out vec3 suncolor;
layout(location = 31) flat out vec3 sundirection;
layout(location = 29) flat out float cameraangle;
 
void main()
{
    vec4 p;
    p.xyz = VertexPositionDisplacement.xyz;
    p.w = 1.0f;

    mat4 mat;
    vec4 color;
    uint flags;

    ExtractEntityInfo(EntityID, mat, color, flags, decallayers);

    //vec2 d = normalize(mat[3].xz - CameraPosition.xz);
    //d = normalize(d);
    
    vec4 relcampos = inverse(mat) * vec4(CameraPosition, 1.0f);
    vec2 d = -normalize(relcampos.xz);

    cameraangle = mod(degrees(atan(d.x, d.y)), 360.0f);
    
    mat3 rotationmat;
    rotationmat[2].xyz = vec3(d.x, 0, d.y);
    rotationmat[1].xyz = vec3(0,1,0);
    rotationmat[0].xyz = cross(rotationmat[2].xyz, rotationmat[1].xyz);
    p.xyz = rotationmat * p.xyz;
    //p.y += VertexTexCoords.w;
    
    p = mat * p;
    
    vertexWorldPosition = p;
    flags = 0;

#ifdef WRITE_COLOR

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

    texCoords = VertexTexCoords;

    #ifndef DEPTHRENDER
    color = vec4(1.0f);

    ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
    normal = normalize(normal);

    tangent = normalize(mat[0].xyz);
    bitangent = normalize(mat[1].xyz);
    normal = normalize(mat[2].xyz);

    #endif

    materialIndex = MaterialIDs;

#endif

    mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, 0);
    gl_Position = cameraProjectionMatrix * p;
}