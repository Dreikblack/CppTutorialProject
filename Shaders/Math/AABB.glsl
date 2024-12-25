#ifndef _AABB
    #define _AABB

/*struct AABB
{
    vec3 min,max,center,size;
    float radius;
};

void AABBUpdate(inout AABB bounds)
{
    bounds.size = bounds.max - bounds.min;
    bounds.center = bounds.min + bounds.size * 0.5f;
    bounds.radius = length(bounds.size) * 0.5f;
}

bool AABBIntersectsPoint(in AABB bounds, in vec3 p)
{
    if (p.x < bounds.min.x) { return false; }
    if (p.y < bounds.min.y) { return false; }
    if (p.z < bounds.min.z ) { return false; }
    if (p.x > bounds.max.x ) { return false; }
    if (p.y > bounds.max.y ) { return false; }
    if (p.z > bounds.max.z ) { return false; }
    return true;
}

bool AABBContainsAABB(in AABB b0, in AABB b1)
{
    if (b1.min.x < b0.min.x || b1.min.y < b0.min.y || b1.min.z < b0.min.z) return false;
    if (b1.max.x > b0.max.x || b1.max.y > b0.max.y || b1.max.z > b0.max.z) return false;
    return true;
}*/

float BoxIntersectsRay(in vec3 bounds0, in vec3 bounds1, in vec3 rpos, in vec3 dir)
{
    float t[10];
    vec3 rdir = 1.0f / dir;
    t[1] = (bounds0.x - rpos.x) * rdir.x;
    t[2] = (bounds1.x - rpos.x) * rdir.x;
    t[3] = (bounds0.y - rpos.y) * rdir.y;
    t[4] = (bounds1.y - rpos.y) * rdir.y;
    t[5] = (bounds0.z - rpos.z) * rdir.z;
    t[6] = (bounds1.z - rpos.z) * rdir.z;
    t[7] = max(max(min(t[1], t[2]), min(t[3], t[4])), min(t[5], t[6]));
    t[8] = min(min(max(t[1], t[2]), max(t[3], t[4])), max(t[5], t[6]));
    t[9] = (t[8] < 0 || t[7] > t[8]) ? -1.0f : t[7];
    return t[9];
}

#endif