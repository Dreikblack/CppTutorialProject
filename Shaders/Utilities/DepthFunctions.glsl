#ifndef _DEPTH_FUNCTIONS
    #define _DEPTH_FUNCTIONS

#ifdef DOUBLE_FLOAT
double PositionToDepth(in double z, in dvec2 depthrange)
#else
float PositionToDepth(in float z, in vec2 depthrange)
#endif
{
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);// Vulkan
	//return depthrange.x / (depthrange.y - z * (depthrange.y - depthrange.x)) * depthrange.y;// OpenGL
}

float PositionToDepthGL(in float z, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - z * (depthrange.y - depthrange.x)) * depthrange.y;// OpenGL
}

#ifdef DOUBLE_FLOAT
double DepthToPosition(in double depth, in dvec2 depthrange)
#else
float DepthToPosition(in float depth, in vec2 depthrange)
#endif
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x) ) * depthrange.y;// Vulkan
	//return (depthrange.x / (depth / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);// OpenGL
}

#ifdef DOUBLE_FLOAT
double PositionToLinearDepth(in double z, in dvec2 depthrange)
#else
float PositionToLinearDepth(in float z, in vec2 depthrange)
#endif
{
	return (z - depthrange.x) / (depthrange.y - depthrange.x);
}

#endif