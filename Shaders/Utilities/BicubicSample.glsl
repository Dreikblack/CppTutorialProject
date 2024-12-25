#ifndef _BICUBIC_SAMPLE
#define _BICUBIC_SAMPLE

vec4 cubic(float v){
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler_, vec2 texCoords){

   vec2 texSize = textureSize(sampler_, 0);
   vec2 invTexSize = 1.0 / texSize;
   
   texCoords = texCoords * texSize - 0.5;

   
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;
    
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;
    
    offset *= invTexSize.xxyy;
    
    vec4 sample0 = texture(sampler_, offset.xz);
    vec4 sample1 = texture(sampler_, offset.yz);
    vec4 sample2 = texture(sampler_, offset.xw);
    vec4 sample3 = texture(sampler_, offset.yw);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
       mix(sample3, sample2, sx), mix(sample1, sample0, sx)
    , sy);
}

vec4 textureLodBicubic(sampler2D sampler_, vec2 texCoords, in float lod){

   vec2 texSize = textureSize(sampler_, 0);
   vec2 invTexSize = 1.0 / texSize;
   
   texCoords = texCoords * texSize - 0.5;

   
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;
    
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;
    
    offset *= invTexSize.xxyy;
    
    vec4 sample0 = textureLod(sampler_, offset.xz, lod);
    vec4 sample1 = textureLod(sampler_, offset.yz, lod);
    vec4 sample2 = textureLod(sampler_, offset.xw, lod);
    vec4 sample3 = textureLod(sampler_, offset.yw, lod);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
       mix(sample3, sample2, sx), mix(sample1, sample0, sx)
    , sy);
}

vec4 betterTextureEx(const in sampler2D tex, vec2 uvw, int lod) {
  vec2 textureResolution = textureSize(tex, lod).xy;
  vec2 uv = fma(uvw.xy, textureResolution, vec2(0.5));
  vec2 fuv = fract(uv);
  return textureLod(tex, vec2((floor(uv) + ((fuv * fuv) * fma(fuv, vec2(-2.0), vec2(3.0))) - vec2(0.5)) / textureResolution), float(lod));
}

vec4 betterTexture(const in sampler2D tex, vec2 uvw, float lod, int maxLod) {
  int ilod = int(floor(lod));
  lod -= float(ilod); 
  return (lod < float(maxLod)) ? mix(betterTextureEx(tex, uvw, ilod), betterTextureEx(tex, uvw, ilod + 1), lod) : betterTextureEx(tex, uvw, maxLod);
}

#endif