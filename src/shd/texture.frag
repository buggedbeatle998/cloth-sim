#version 460 core

precision mediump float;

layout (location = 0) uniform sampler2D tex;

layout (location = 0) in vec2 tex_coords;

layout (location = 0) out vec4 fragment;

void main(void) {
    fragment = texture(tex, tex_coords);
}
