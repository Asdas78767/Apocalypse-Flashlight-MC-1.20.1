#version 120

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 Normal;
varying vec4 Color;

void main() {
    gl_Position = ftransform();
    
    texcoord = gl_MultiTexCoord0.st;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
}