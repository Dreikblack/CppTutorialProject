#ifndef _PLANE_GLSL
#define _PLANE_GLSL

dvec4 dPlane(in dvec3 a, in dvec3 b, in dvec3 c)
{
	dvec4 p;
	dvec3 va, vb;
	dvec3 anypos = b;
	va.x = c.x - b.x;
	va.y = c.y - b.y;
	va.z = c.z - b.z;
	vb.x = a.x - b.x;
	vb.y = a.y - b.y;
	vb.z = a.z - b.z;
	p.xyz = normalize(cross(va,vb));
	p.w = dot(-anypos,p.xyz);
	return p;
}

vec4 Plane(in vec3 a, in vec3 b, in vec3 c)
{
	vec4 p;
	vec3 va, vb;
	vec3 anypos = b;
	va.x = c.x - b.x;
	va.y = c.y - b.y;
	va.z = c.z - b.z;
	vb.x = a.x - b.x;
	vb.y = a.y - b.y;
	vb.z = a.z - b.z;
	p.xyz = normalize(cross(va,vb));
	p.w = dot(-anypos,p.xyz);
	return p;
}

// Plane constructed from point and normal
dvec4 dPlane(in dvec3 point, in dvec3 normal)
{
	dvec4 p;
	p.x = normal.x;
	p.y = normal.y;
	p.z = normal.z;
	p.w = -dot(point,normal);
	return p;
}

// Plane constructed from point and normal
vec4 Plane(in vec3 point, in vec3 normal)
{
	vec4 p;
	p.x = normal.x;
	p.y = normal.y;
	p.z = normal.z;
	p.w = -dot(point, normal);
	return p;
}

double PlaneDistanceToPoint(in dvec4 plane, in dvec3 p)
{
	return plane.x * p.x + plane.y * p.y + plane.z * p.z + plane.w;
}

float PlaneDistanceToPoint(in vec4 plane, in vec3 p)
{
	return plane.x * p.x + plane.y * p.y + plane.z * p.z + plane.w;
}

dvec3 PlaneLineClosestPoint(in dvec4 plane, in dvec3 p0, in dvec3 p1)
{
	double dist0 = PlaneDistanceToPoint(plane, p0);
	double dist1 = PlaneDistanceToPoint(plane, p1);
	if (sign(dist0) == sign(dist1))
	{
		if (abs(dist0) < abs(dist1)) return p0; else return p1;
	}
	
	double dx = p1.x - p0.x;
	double dy = p1.y - p0.y;
	double dz = p1.z - p0.z;

	dvec3 result;

	double denom = plane.x * dx + plane.y * dy + plane.z * dz;
//	if (abs(denom) < 0.0001f) return result; // should not happen, perpinducular to plane I think

	double u = -(plane.x * p0.x + plane.y * p0.y + plane.z * p0.z + plane.w) / denom;
//	if (u<0.0f || u>1.0f) return result;

	result.x = p0.x + dx * u;
	result.y = p0.y + dy * u;
	result.z = p0.z + dz * u;

	return result;
}

vec3 PlaneLineClosestPoint(in vec4 plane, in vec3 p0, in vec3 p1)
{
	float dist0 = PlaneDistanceToPoint(plane, p0);
	float dist1 = PlaneDistanceToPoint(plane, p1);
	if (sign(dist0) == sign(dist1))
	{
		if (abs(dist0) < abs(dist1)) return p0; else return p1;
	}
	
	float dx = p1.x - p0.x;
	float dy = p1.y - p0.y;
	float dz = p1.z - p0.z;

	vec3 result;

	float denom = plane.x * dx + plane.y * dy + plane.z * dz;
//	if (abs(denom) < 0.0001f) return result; // should not happen, perpinducular to plane I think

	float u = -(plane.x * p0.x + plane.y * p0.y + plane.z * p0.z + plane.w) / denom;
//	if (u<0.0f || u>1.0f) return result;

	result.x = p0.x + dx * u;
	result.y = p0.y + dy * u;
	result.z = p0.z + dz * u;

	return result;
}

bool PlaneIntersectsLine(in vec4 plane, in vec3 p0, in vec3 p1, out vec3 result, const bool twosided, const bool infinite)
{
	float u,denom,dx,dy,dz;
	
	if (twosided == false)
	{
		if (infinite)
		{
			vec3 dir = normalize(p1 - p0);
			if (dot(dir, plane.xyz) < 0.0f) return false;
		}
		else
		{
			if (PlaneDistanceToPoint(plane, p0) < 0.0f) return false;
			if (PlaneDistanceToPoint(plane, p1) > 0.0f) return false;
		}
	}
	
	dx = p1.x - p0.x;
	dy = p1.y - p0.y;
	dz = p1.z - p0.z;
	
	denom = plane.x * dx + plane.y * dy + plane.z * dz;
	if (abs(denom) < 0.0001f) return false;

	u = -(plane.x*p0.x+plane.y*p0.y+plane.z*p0.z+plane.w) / denom;
	//u=(x*p0.x+y*p0.y+z*p0.z+d)/denom;
	if (!infinite)
	{
		if (u < 0.0f || u>1.0f) return false;
	}

	//if (result!=0) {
		result.x=p0.x+dx*u;
		result.y=p0.y+dy*u;
		result.z=p0.z+dz*u;
	//}

	return true;
}

#endif