#version 120

attribute vec3 mc_Entity;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;
varying float blockId;
varying vec3 worldPos;
varying float fogDistance;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

void main() {
    gl_Position = ftransform();
    
    texcoord = gl_MultiTexCoord0.st;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
    
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
    blockId = mc_Entity.x;
    
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    worldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
    fogDistance = length(viewPos.xyz);
}
