#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
#extension GL_ARB_bindless_texture : enable

#define WRITE_COLOR
#define TERRAIN

#include "TerrainInfo.glsl"
#include "Vertex.glsl"