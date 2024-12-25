#include "../Base/Materials.glsl"

#define USER_HOOK

struct SurfaceInput
{
    Material material;
    vec4 texcoords;
    vec4 color;
    vec3 normal, tangent, bitangent;
};

struct SurfaceOutput
{
    vec4 basecolor;
    vec3 normal;
    float metallic;
    float roughness;
    vec3 reflectance;
    vec3 emission;
};