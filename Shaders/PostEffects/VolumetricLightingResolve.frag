#version 450
#include "../Khronos/tonemapping.glsl"

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 1, binding = 1) uniform sampler2D VolumetricLight;
layout(location = 2, binding = 2) uniform sampler2DMS Depth;
layout(location = 3) uniform ivec4 DrawViewport;

// Outputs
layout(location = 0) out vec4 outColor;

vec3 aces(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

#define saturate(a) clamp(a,0.0,1.0)

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = texelFetch(ColorBuffer, coord, 0);
    //outColor.rgb =  sRGBToLinear(outColor.rgb);
    
    float z = texelFetch(Depth, coord, 0).r;
    
    vec2 uv = vec2(gl_FragCoord.x / float(DrawViewport.z), gl_FragCoord.y / float(DrawViewport.w));

    vec2 pixelsize = vec2(1.0f) / vec2(DrawViewport.z, DrawViewport.w);

    float dz = 10000.0;
    vec3 vol_info = vec3(0.0);
	float c = 0;
    for(int x = -1; x <= 1; x++)
	for(int y = -1; y <= 1; y++)
	{
        //vec4 info = texture(VolumetricLight, vec2(coord + ivec2(x,y), )  );
        vec4 info = textureLod(VolumetricLight, uv + vec2(x+4, y+4) * pixelsize, 0); // The offset makes edges lines up the best
		if(z-info.a < dz)
		{
			vol_info = sRGBToLinear(info.rgb);
			dz = z-info.a;
		}
	}

    outColor.rgb += vol_info;
   // outColor.rgb = linearTosRGB(outColor.rgb);
}