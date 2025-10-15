#version 120

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 Normal;
varying vec4 Color;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
    vec4 color = texture2D(texture, texcoord) * Color;
    
    vec3 lightColor = texture2D(lightmap, lmcoord).rgb;
    
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1.0);
    gl_FragData[2] = vec4(lightColor, 1.0);
}
