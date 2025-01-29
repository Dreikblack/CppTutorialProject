#version 450
//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_bindless_texture : enable

#include "../Base/Fragment.glsl"
#include "../Utilities/PackSelectionState.glsl"
#include "../Utilities/DepthFunctions.glsl"

float filterWidth2(vec2 uv)
{
     vec2 dx = dFdx(uv), dy = dFdy(uv);
    return dot(dx, dx) + dot(dy, dy) + .0001;
}

// still not happy with how it fades out too soon,
// but at least it's basically working.  Better than the others.
float gridSmooth(vec2 p, in float gridThickness)
{
    vec2 q = p;
    q += .5;
    q -= floor(q);
    q = (gridThickness + 1.) * .5 - abs(q - .5);
    float w = 12.*filterWidth2(p);
    float s = sqrt(gridThickness);
    return smoothstep(.5-w*s,.5+w, max(q.x, q.y));
}

//https://www.shadertoy.com/view/wl3Sz2
float gridAASimple(vec2 p, in float gridThickness)
{
    vec2 f = fract(p);
    float g = min(min(f.x, 1.-f.x), min(f.y, 1.-f.y)) * 2. - gridThickness
    , x = step(g, 0.) //gridUnfiltered(p)
    , w = fwidth(p.x) + fwidth(p.y)
    , r = 20.* float(BufferSize.y)
    , l = r*abs(g) / (1. + 1.*r*w) // can try different functions, divisor controls fade rate with distance
    // up close, should blend toward 0.5, but
    // far away should blend toward gridThickness, maybe sqrt'd?
    , s = sqrt(gridThickness) //gridThickness*gridThickness //gridThickness //
    , t = mix(.5, s, min(w, 1.));
    return mix(t, x, clamp(l, 0., 1.));
}

//https://www.shadertoy.com/view/wl3Sz2
float gridAAOrigin(vec2 p, in float gridThickness)
{
    const float tolerance = 0.5f;

    vec2 f = fract(p);

    if (abs(p.x) > tolerance) f.x = 0.5f;
    if (abs(p.y) > tolerance) f.y = 0.5f;
    if (f.x == 0.5f && f.y == 0.5f) return 0.0f;

    float g = min(min(f.x, 1.-f.x), min(f.y, 1.-f.y)) * 2. - gridThickness
    , x = step(g, 0.) //gridUnfiltered(p)
    , w = fwidth(p.x) + fwidth(p.y)
    , r = 20.* float(BufferSize.y)
    , l = r*abs(g) / (1. + 1.*r*w) // can try different functions, divisor controls fade rate with distance
    // up close, should blend toward 0.5, but
    // far away should blend toward gridThickness, maybe sqrt'd?
    , s = sqrt(gridThickness) //gridThickness*gridThickness //gridThickness //
    , t = mix(.5, s, min(w, 1.));
    return mix(t, x, clamp(l, 0., 1.));
}

void main()
{
    float gridsize = color.r;
    
    Material material = materials[materialID];
    outColor[0] = material.diffuseColor * color;
    uvec2 textureID = material.textureHandle[TEXTURE_DIFFUSE];
    if (textureID != uvec2(0)) outColor[0] *= texcoords;

    vec3 eyedir = CameraPosition - vertexWorldPosition.xyz;
    float d = length(eyedir);
    eyedir /= d;
    float slope = degrees(asin(eyedir.y));

    float screenscale = 400.0f / float(DrawViewport.w);

    float gridThickness = max(0.0001f, pow(d, 1.0f / CameraZoom) * 0.001f) / gridsize;
    
    gridThickness *= screenscale; 

    //float gridThickness = max(0.0001f, abs(CameraPosition.y) * 0.0001f);
    //float gridThickness = 0.1f;

    //const float gridThickness = 0.0001f;

    float minorlines = gridAASimple(vertexWorldPosition.xz / gridsize, gridThickness) * 0.1251875f;

    float majorlines = gridAASimple(vertexWorldPosition.xz / float(MajorGridLines) / gridsize, gridThickness / color.g) * 0.25f;

    //float origin = min(1.0f, gridAAOrigin(vertexWorldPosition.xz, gridThickness) * 2.0f);

    //d = abs(CameraPosition.y);

    float minorlinesrange = 100.0f;
    float originrange = 500.0f;
    float majorlinesrange = originrange;

    if (d > minorlinesrange* gridsize)
    {
        minorlines *= max(0.0f, 1.0f - (d - minorlinesrange * gridsize) / (minorlinesrange * gridsize));
        //minorlines = 0.0f;
        
    }

    if (d > majorlinesrange)
    {
        //majorlines = 0.0f;
        majorlines *= max(0.0f,  1.0f - (d - majorlinesrange) / (majorlinesrange));
    }

    float origin = 0.0f;
    
    float f = abs(vertexWorldPosition.x) / d;
    float r = 0.004f;
    
    r *= screenscale; 

    //r *= 20.0f * (slope / 90.0f);
    float hr = r * 0.5f;
    if (f < r) origin = clamp(1.0f - f / r, 0.0f, 1.0f);
    f = abs(vertexWorldPosition.z) / d;
    if (f < r) origin = max(origin, clamp(1.0f - f / r, 0.0f, 1.0f));
    origin *= 0.5f;

    if (d > originrange)
    {
        //majorlines = 0.0f;
        origin *= max(0.0f,  1.0f - (d - originrange) / (originrange));
    }

    //float g = max(majorlines, minorlines);
    float g = max(max(majorlines, minorlines), origin);
    g = clamp(g, 0.0f, 1.0f);

    if (abs(slope) < 15.0)
    {
        g *= abs(slope) / 15.0;
    }
    if (abs(CameraPosition.y) < CameraRange.x * 2.0)
    {
        g *= max(0.0, (abs(CameraPosition.y) - CameraRange.x) / CameraRange.x);
    }

    outColor[0] = vec4(1.0f, 1.0f, 1.0f, g);

    /*const float tolerance = 0.1f;
    if (abs(mod(vertexWorldPosition.x, 8.0f)) < tolerance) outColor[0].rgb = vec3(1.0f);//vec3(1.0f,0.5f,0.5f);
    if (abs(mod(vertexWorldPosition.z, 8.0f)) < tolerance) outColor[0].rgb = vec3(1.0f);//vec3(0.5f,0.5f,1.0f);

    if (abs(vertexWorldPosition.x) < tolerance) outColor[0].rgb = vec3(1);//vec3(1.0f,0.5f,0.5f);
    if (abs(vertexWorldPosition.z) < tolerance) outColor[0].rgb = vec3(1);//vec3(0.5f,0.5f,1.0f);*/

    //Camera distance fog
    //ApplyDistanceFog(outColor[0].rgb, vertexWorldPosition.xyz, CameraPosition);

    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
    {
        outColor[0].rgb *= outColor[0].a;
    }  

    int attachmentindex = 0;

    //Deferred normals
    if ((RenderFlags & RENDERFLAGS_OUTPUT_NORMALS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex] = vec4(0,1,0,g);
    }

    //Deferred metal / roughness
    if ((RenderFlags & RENDERFLAGS_OUTPUT_METALLICROUGHNESS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].r = 0.0f;
        outColor[attachmentindex].g = 1.0f;
        outColor[attachmentindex].b = 0.0f;
        outColor[attachmentindex].a = g;
#ifdef PREMULTIPLY_AlPHA
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
        {
            outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        }
#endif
    }

    //Deferred base color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ALBEDO) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex] = vec4(1.0f, 1.0f, 1.0f, g);
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
        //    outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }

    //Deferred Z-position
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ZPOSITION) != 0)
    {
        ++attachmentindex;
        float d = PositionToDepth(vertexCameraPosition.z, CameraRange);
        outColor[attachmentindex] = vec4(d, d, d, 1.0f);
        //outColor[attachmentindex] = vec4(1.0f);
    }  
}