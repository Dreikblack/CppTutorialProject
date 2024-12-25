#version 460

const vec4 vertexpos[4] = {vec4(0,-1,0,1), vec4(0,0,0,1), vec4(1,0,0,1), vec4(1,-1,0,1)};

void main()
{
	vec4 pos = vertexpos[gl_VertexID - gl_BaseVertex];// gl_BaseVertex requires GLSL 4.60
	
	mat4 orthomatrix = mat4(0.0f);
	orthomatrix[0][0] = 2.0f;
	orthomatrix[1][1] = 2.0f;
	orthomatrix[2][2] = -1.0f;
	orthomatrix[3][0] = -1.0f;
	orthomatrix[3][1] = -1.0f;
	orthomatrix[3][3] = 1.0f;
	orthomatrix[1] *= -1.0f;

	gl_Position = orthomatrix * pos;
}