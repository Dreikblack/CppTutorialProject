#ifndef _STORAGE_BUFFER_BINDINGS_GLSL
    #define _STORAGE_BUFFER_BINDINGS_GLSL
    
    #define STORAGE_BUFFER_DRAW_INDEXES 0
    #define STORAGE_BUFFER_MATRICES 1
    #define STORAGE_BUFFER_MATERIALS 2
    #define STORAGE_BUFFER_LIGHT_GRID 3
    #define STORAGE_BUFFER_BONES 4
    #define STORAGE_BUFFER_BONES2 5
    #define STORAGE_BUFFER_PRIMITIVES 6
    #define STORAGE_BUFFER_AUX 7
    #define STORAGE_BUFFER_DRAWCOMMANDS 8

//layout(std430, binding = STORAGE_BUFFER_AUX) readonly buffer AuxBlock { mat4 AuxData[]; };

#endif