#define LIGHTING // Comment this out to disable lighting

#include "../Base/Surface.glsl"
#include "../Base/UniformBlocks.glsl"

const float Speed = 1.0f;

vec3 slerpNormals(vec3 start, vec3 end, float percent)
{
     // Dot product - the cosine of the angle between 2 vectors.
     float dot = dot(start, end);     
     // Clamp it to be in the range of Acos()
     // This may be unnecessary, but floating point
     // precision can be a fickle mistress.
     dot = clamp(dot, -1.0, 1.0);
     // Acos(dot) returns the angle between start and end,
     // And multiplying that by percent returns the angle between
     // start and the final result.
     float theta = acos(dot)*percent;
     vec3 RelativeVec = normalize(end - start*dot); // Orthonormal basis
     // The final result.
     return ((start*cos(theta)) + (RelativeVec*sin(theta)));
}

void UserHook(inout Surface surface, in Material material)
{
        surface.basecolor *= material.diffuseColor;
        surface.thickness = 10;// material.thickness;
        surface.roughness = material.roughness;
        surface.metallic = material.metalness;   

        const float frames = textureSize(sampler2DArray(material.textureHandle[TEXTURE_NORMAL]), 0).z;
        float frame = (float(CurrentTime) / 200.0f) * Speed;
        vec4 tc = surface.texcoords;
        tc.z = mod(floor(frame), frames);
        tc.w = mod(ceil(frame), frames);

        //-----------------------------------------------------------------------------------------
        // Normal map
        //-----------------------------------------------------------------------------------------

                if (material.textureHandle[0] != uvec2(0))
                {
                        vec3 flown;
                        float fs = 0.001f;
                        flown = texture(sampler2D(material.textureHandle[0]), tc.xy * 0.5f).rgb * 2.0f - 1.0f;
                 //       tc.xy += flown.rg * 0.01f;
                }

        if (material.textureHandle[TEXTURE_NORMAL] != uvec2(0))
        {
                vec3 n1 = texture(sampler2DArray(material.textureHandle[TEXTURE_NORMAL]), tc.xyz).rgb * 2.0f - 1.0f;
                vec3 n2 = texture(sampler2DArray(material.textureHandle[TEXTURE_NORMAL]), tc.xyw).rgb * 2.0f - 1.0f;

                //n1.xy *= surface.normalscale;
                //n2.xy *= surface.normalscale;

                //Extract normal map Z component
  /*              if ((material.flags & MATERIAL_EXTRACTNORMALMAPZ) != 0)
                {
                        n1.z = sqrt( max(0.0f, 1.0f - (n1.x * n1.x + n1.y * n1.y)));
                        n2.z = sqrt( max(0.0f, 1.0f - (n2.x * n2.x + n2.y * n2.y)));
                }
                else
                {
                        n1 = normalize(n1);
                        n2 = normalize(n2);
                }
*/
                vec3 n = mix(n1, n2, mod(frame, 1.0f) );
                //vec3 n = slerpNormals(n1, n2, mod(frame, 1.0f));   

                //tc.xy += n.xy * 0.1f;// probably slower since the texcoord calculation is deferred

                // This helps to hide the animation frames
                if (material.textureHandle[0] != uvec2(0))
                {
                        vec3 flown;
                        float fs = 0.005f;
                        flown = texture(sampler2D(material.textureHandle[0]), tc.xy + vec2(frame,0) * fs ).rgb;
                        flown = mix(flown, (texture(sampler2D(material.textureHandle[0]), tc.xy - vec2(frame,0) * fs + vec2(0.5f) ).rgb), 0.5f);
                        flown = flown * 2.0f - 1.0f;
                        n = mix(n, flown, 0.5f);
                }

                n.xy *= surface.normalscale;
                n.z = sqrt( max(0.0f, 1.0f - (n.x * n.x + n.y * n.y)));
                //n = normalize(n);// probably not needed most of the time

                surface.perturbation = n.xy;
                surface.normal = surface.tangent * n.x + surface.bitangent * n.y + surface.normal * n.z;
	}
}

#include "../PBR/Fragment.glsl"