

#ifndef _DITHER
#define _DITHER

//https://www.anisopteragames.com/how-to-fix-color-banding-with-dithering/

const uint ditherpattern[64] = {
    0, 32,  8, 40,  2, 34, 10, 42,   /* 8x8 Bayer ordered dithering  */
    48, 16, 56, 24, 50, 18, 58, 26,  /* pattern.  Each input pixel   */
    12, 44,  4, 36, 14, 46,  6, 38,  /* is scaled to the 0..63 range */
    60, 28, 52, 20, 62, 30, 54, 22,  /* before looking in this table */
    3, 35, 11, 43,  1, 33,  9, 41,   /* to determine the action.     */
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21 };

// "Then at the end of the fragment shader add the scaled dither texture to the fragment color. I don’t fully understand the 32.0 divisor here – I think 64 is the correct value but 32 (or even 16) looks much better."

float dither(ivec2 coord)
{
	int dithercoord = coord.x * 8 + coord.y;
	dithercoord = dithercoord % 64;
	float d = float(ditherpattern[dithercoord]) / 255.0f;
	d /= 16.0f - (1.0f / 128.0f);
    return d;
}
#endif
