#version 460
#extension GL_ARB_shader_draw_parameters : enable
#extension GL_ARB_bindless_texture : enable

#define WRITE_COLOR
#define DEPTHRENDER
#define IMPOSTER

#include "../MeshLayer/Vertex.glsl" 