#version 460 core

precision mediump float;

layout (location = 0) in vec2 v_pos;

layout (location = 0) out vec2 tex_coords;
out gl_PerVertex {
    vec4 gl_Position;
};

void main(void) {
    gl_Position = vec4(v_pos, 0.0, 1.0);
    tex_coords = v_pos * 0.5 + 0.5;
}
