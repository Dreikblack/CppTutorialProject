#ifndef _EDITORGRID
#define _EDITORGRID

#include "../Math/math.glsl"

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

float WorldGrid(in vec3 position, in vec3 normal, in float zdistance)
{
    if (GridSize == 0.0f) return 0.0f;
    const float gridThickness = max(0.0001f, pow(zdistance, 1.0f / CameraZoom) * 0.001f) / GridSize;
    vec2 gridpos;
    switch (getMajorAxis(normal))
    {
    case 0:
        gridpos = position.zy;
        break;
    case 1:
        gridpos = position.xz;
        break;
    case 2:
        gridpos = position.xy;
        break;
    }
    float minorlines = gridAASimple(gridpos / GridSize, gridThickness) * 0.125f;
    float majorlines = gridAASimple(gridpos / GridSize / float(MajorGridLines), gridThickness) * 0.25f;
    float origin = gridAAOrigin(gridpos, gridThickness) * 0.5f;
    return max(origin, max(minorlines, majorlines));
}

float WorldGrid(in vec2 gridpos, in float zdistance)
{
    if (GridSize == 0.0f) return 0.0f;
    const float gridThickness = max(0.0001f, pow(zdistance, 1.0f / CameraZoom) * 0.001f) / GridSize;
    float minorlines = gridAASimple(gridpos / GridSize, gridThickness) * 0.5f;
    float majorlines = gridAASimple(gridpos / GridSize / float(MajorGridLines), gridThickness) * 0.75f;
    float origin = gridAAOrigin(gridpos, gridThickness);
    return max(origin, max(minorlines, majorlines));
}

#endif