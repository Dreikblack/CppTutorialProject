#ifndef _LIMITS_GLSL

    #define _LIMITS_GLSL

    #ifdef DYNAMIC_DESCRIPTORS

        #define MAX_TEXTURES_2D 8
        #define MAX_TEXTURES_CUBE 1
        #define MAX_TEXTURES_SHADOW 1
        #define MAX_TEXTURES_2D_INTEGER 1
        #define MAX_TEXTURES_2D_UINTEGER 1
        #define MAX_TEXTURES_CUBE_SHADOW 1
        #define MAX_VOLUME_TEXTURES 1
        #define MAX_TEXTURES_STORAGE_2D 1
        #define MAX_TEXTURES_STORAGE_3D 1
        #define MAX_TEXTURES_STORAGE_CUBE 1
        //#define MAX_TEXTURES_2DMS 32

    #else

        #define MAX_TEXTURES_2D 512
        #define MAX_TEXTURES_CUBE 128
        #define MAX_TEXTURES_SHADOW 64
        #define MAX_TEXTURES_2D_INTEGER 32
        #define MAX_TEXTURES_2D_UINTEGER 32
        #define MAX_TEXTURES_CUBE_SHADOW 128
        #define MAX_VOLUME_TEXTURES 128
        #define MAX_TEXTURES_STORAGE_2D 32
        #define MAX_TEXTURES_STORAGE_3D 128
        #define MAX_TEXTURES_STORAGE_CUBE 128
        #define MAX_TEXTURES_2DMS 32

        #define MAX_IMAGES_2D MAX_TEXTURES_2D
        #define MAX_IMAGES_3D 128
        #define MAX_IMAGES_CUBE 128

    #endif

#endif