#version 460 core

precision mediump float;

layout (location = 0) in vec3 colour;

layout (location = 0) out vec4 fragment;

void main(void) {
    fragment = vec4(colour, 1.f);
}
