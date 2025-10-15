#version 120

varying vec4 Color;

void main() {
    gl_Position = ftransform();
    Color = gl_Color;
}
