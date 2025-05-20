#include "../Base/Materials.glsl"

#define USER_HOOK

struct Surface
{
    Material material;
    vec4 texcoords;
    vec3 normal, tangent, bitangent;
    vec4 basecolor;
    float metallic;
    float roughness;
    vec3 reflectance;
    vec3 emission;
    float occlusion;
    float normalscale;
    float thickness;
    float displacement;
    vec2 perturbation;
};