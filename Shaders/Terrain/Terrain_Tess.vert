#version 450
//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_ARB_shader_viewport_layer_array : enable
#extension GL_ARB_bindless_texture : enable

#define WRITE_COLOR
#define SPRITEVIEW
#define TERRAIN
#define TESSELLATION

#include "TerrainInfo.glsl"
#include "Vertex.glsl"
