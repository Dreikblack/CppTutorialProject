#ifndef _ERRORCOLOR
#define _ERRORCOLOR

vec4 ErrorColor()
{   
    //if (gl_FragCoord.x) 
    //gl_FragCoord.x / 
    return vec4(1,0,1,1);
    else return vec4(0,0,0,1);
}

#endif
