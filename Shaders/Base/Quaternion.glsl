#ifndef _QUATERNION_GLSL
	#define _QUATERNION_GLSL

mat4 QuatToMat4(in vec4 q)
{
	float xx = q.x * q.x;// can remove?
	float yy = q.y * q.y;
	float zz = q.z * q.z;
	float xy = q.x * q.y;
	float xz = q.x * q.z;
	float yz = q.y * q.z;
	float wx = q.w * q.x;
	float wy = q.w * q.y;
	float wz = q.w * q.z;
	mat4 mat;
	mat[0].x = 1.0f - 2.0f*(yy + zz);	mat[0].y = 2.0f * (xy - wz);			mat[0].z = 2.0f * (xz + wy);			mat[0].w = 0.0f;
	mat[1].x = 2.0f * (xy + wz);		mat[1].y = 1.0f - 2.0f * (xx + zz);		mat[1].z = 2.0f * (yz - wx);			mat[1].w = 0.0f;
	mat[2].x = 2.0f * (xz - wy);		mat[2].y = 2.0f * (yz + wx);			mat[2].z = 1.0f - 2.0f * (xx + yy);		mat[2].w = 0.0f;
	//mat[1] = cross(mat[0], mat[2]);
	mat[3] = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	return mat;
}

mat3 QuatToMat3(in vec4 q)
{
	mat3 mat;
	float xx = q.x * q.x;
	float yy = q.y * q.y;
	float zz = q.z * q.z;
	float xy = q.x * q.y;
	float xz = q.x * q.z;
	float yz = q.y * q.z;
	float wx = q.w * q.x;
	float wy = q.w * q.y;
	float wz = q.w * q.z;
	mat[0].x = 1.0f - 2.0f * (yy + zz);		mat[0].y = 2.0f * (xy - wz);			mat[0].z = 2.0f * (xz + wy);
	mat[1].x = 2.0f * (xy + wz);			mat[1].y = 1.0f - 2.0f * (xx + zz);		mat[1].z = 2.0f * (yz - wx);
	mat[2].x = 2.0f * (xz - wy);			mat[2].y = 2.0f * (yz + wx);			mat[2].z = 1.0f - 2.0f * (xx + yy);
	return mat;
}

vec4 Slerp(in vec4 src, in vec4 dst, in float a)
{
	if (a==0.0f) return src;
	if (a==1.0f) return dst;
	bool f=false;
	float b=1.0f-a;
	float d=src.x*dst.x+src.y*dst.y+src.z*dst.z+src.w*dst.w;
	if (d<0.0f) {
		d=-d;
		f=true;
	}
	if (d<1.0f) {
		float om=acos(d);
		float si=sin(om);
		a=sin(a*om)/si;
		b=sin(b*om)/si;
	}
	if (f) a*=-1.0f;
	return vec4(src.x*b+dst.x*a,src.y*b+dst.y*a,src.z*b+dst.z*a,src.w*b+dst.w*a);
}
#endif