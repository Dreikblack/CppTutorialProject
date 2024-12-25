#ifndef _PNQUAD
    #define _PNQUAD

//https://github.com/sayakbiswas/openGL-Tessellation/blob/master/PN_Quads/shaders/tessellationPNQuads_new.glsl
vec3 PNQuad(vec3 p0, vec3 p1, vec3 p2, vec3 p3, vec3 n0, vec3 n1, vec3 n2, vec3 n3, vec2 uv)
{
	float u = uv.x;
	float v = uv.y;

	vec3 b0 = p0;
	vec3 b1 = p1;
	vec3 b2 = p2;
	vec3 b3 = p3;

	float w01 = dot(p1 - p0, n0);
	float w10 = dot(p0 - p1, n1);
	float w12 = dot(p2 - p1, n1);
	float w21 = dot(p1 - p2, n2);
	float w23 = dot(p3 - p2, n2);
	float w32 = dot(p2 - p3, n3);
	float w30 = dot(p0 - p3, n3);
	float w03 = dot(p3 - p0, n0);

	vec3 b01 = (2.0f*p0 + p1 - w01*n0) / 3.0f;
	vec3 b10 = (2.0f*p1 + p0 - w10*n1) / 3.0f;
	vec3 b12 = (2.0f*p1 + p2 - w12*n1) / 3.0f;
	vec3 b21 = (2.0f*p2 + p1 - w21*n2) / 3.0f;
	vec3 b23 = (2.0f*p2 + p3 - w23*n2) / 3.0f;
	vec3 b32 = (2.0f*p3 + p2 - w32*n3) / 3.0f;
	vec3 b30 = (2.0f*p3 + p0 - w30*n3) / 3.0f;
	vec3 b03 = (2.0f*p0 + p3 - w03*n0) / 3.0f;

	const float div = 18.0f;
	const float hdiv = 9.0f;

	vec3 q = b01 + b10 + b12 + b21 + b23 + b32 + b30 + b03;
	vec3 e0 = (2.0f*(b01 + b03 + q) - (b21 + b23)) / div;
	vec3 v0 = (4.0f*p0 + 2.0f*(p3 + p1) + p2) / hdiv;
	vec3 b02 = e0 + (e0 - v0) / 2.0f;

	vec3 e1 = (2.0f*(b12 + b10 + q) - (b32 + b30)) / div;
	vec3 v1 = (4.0f*p1 + 2.0f*(p0 + p2) + p3) / hdiv;
	vec3 b13 = e1 + (e1 - v1) / 2.0f;

	vec3 e2 = (2.0f*(b23 + b21 + q) - (b03 + b01)) / div;
	vec3 v2 = (4.0f*p2 + 2.0f*(p1 + p3) + p0) / hdiv;
	vec3 b20 = e2 + (e2 - v2) / 2.0f;

	vec3 e3 = (2.0f*(b30 + b32 + q) - (b10 + b12)) / div;
	vec3 v3 = (4.0f*p3 + 2.0f*(p2 + p0) + p1) / hdiv;
	vec3 b31 = e3 + (e3 - v3) / 2.0f;

	float bu0 = (1.0f-u) * (1.0f-u) * (1.0f-u);
	float bu1 = 3.0f * u * (1.0f-u) * (1.0f-u);
	float bu2 = 3.0f * u * u * (1.0f-u);
	float bu3 = u * u * u;

	float bv0 = (1.0f-v) * (1.0f-v) * (1.0f-v);
	float bv1 = 3.0f * v * (1.0f-v) * (1.0f-v);
	float bv2 = 3.0f * v * v * (1.0f-v);
	float bv3 = v * v * v;

	return bu0*(bv0*b0 + bv1*b01 + bv2*b10 + bv3*b1) 
           + bu1*(bv0*b03 + bv1*b02 + bv2*b13 + bv3*b12) 
           + bu2*(bv0*b30 + bv1*b31 + bv2*b20 + bv3*b21) 
           + bu3*(bv0*b3 + bv1*b32 + bv2*b23 + bv3*b2);
}
#endif