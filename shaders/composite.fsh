#version 120

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex1;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float frameTimeCounter;
uniform int worldTime;
uniform float rainStrength;

#include "/shaders/settings.glsl"

float linearizeDepthFast(float depth) {
   return (near * far) / (depth * (near - far) + far);
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(){
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex1, texcoord).r;
    
    if(depth == 1.0f){
        // 하늘 색상 조정 (방송용으로 보기 좋게)
        bool isDay = worldTime >= 1000 && worldTime < 12000;
        bool isDusk = (worldTime >= 12000 && worldTime < 13000) || (worldTime >= 500 && worldTime < 1000);
        bool isNight = worldTime >= 13000 || worldTime < 500;
        
        if (isDay) {
            // 낮: 비올 것 같은 흐린 하늘
            color = mix(color, vec3(0.55, 0.54, 0.52), 0.55);
            // 먼지/수증기 효과
            float dust = noise(texcoord * 80.0 + frameTimeCounter * 0.008);
            color += vec3(0.06, 0.06, 0.05) * dust * 0.25;
        } else if (isDusk) {
            // 황혼: 어두운 주황빛 하늘
            color = mix(color, vec3(0.5, 0.35, 0.25), 0.6);
        } else if (isNight) {
            // 밤: 확실히 어두운 하늘
            color *= 0.05;
            color = mix(color, vec3(0.01, 0.01, 0.02), 0.7);
        }
        gl_FragData[0] = vec4(color, 1.0f);
        return;
    }
    
    depth = linearizeDepthFast(depth);
    vec3 normal = texture2D(colortex1, texcoord).rgb * 2.0 - 1.0;
    vec3 lightmap = texture2D(colortex2, texcoord).rgb;
    
    // 플래시라이트 효과 (개선된 버전)
    float flashlightDepth = min(depth, 50.0); // 최대 거리 50블록으로 증가
    float dist = length((texcoord - 0.5) * vec2(max(aspectRatio, 1.0), max(1.0 / aspectRatio, 1.0)));
    
    // 플래시라이트 범위 (더 넓고 자연스럽게)
    float flashlight = clamp((1.0 - (dist / (0.8 + flashlightDepth * 0.008)) * 4.5 + 3.5), 0.0, 1.0);
    flashlight = smoothstep(0.0, 1.0, flashlight);
    
    // 중심부 밝기 (더 선명하고 멀리 보이도록)
    float centerBoost = clamp(1.0 - dist * 1.2, 0.0, 1.0);
    centerBoost = pow(centerBoost, 1.8);
    flashlight += centerBoost * 1.2;
    
    // 거리 감쇠 (더 멀리까지 보이도록 완화)
    flashlight *= clamp(1.0 - flashlightDepth * 0.015, 0.3, 1.0);
    flashlight *= sqrt(max(normal.z, 0.0)) * 0.6 + 0.4;
    
    // 시간대별 플래시라이트 강도
    bool isNight = worldTime >= 13000 || worldTime < 500;
    bool isDusk = (worldTime >= 12000 && worldTime < 13000) || (worldTime >= 500 && worldTime < 1000);
    
    if (isNight) {
        flashlight *= 3.5; // 밤: 매우 강한 플래시라이트로 멀리까지 보임
    } else if (isDusk) {
        flashlight *= 1.8; // 황혼: 중간보다 강한 강도
    } else {
        flashlight *= 0.6; // 낮: 약한 보조광
    }
    
    // 플래시라이트 깜빡임 (방송용으로 약하게)
    #ifdef FLASHLIGHT_FLICKER
        float flicker = sin(frameTimeCounter * 15.0) * 0.02 + 0.98;
        if (rand(floor(frameTimeCounter * 0.3)) < 0.02) {
            flicker *= 0.8; // 가끔 약간 깜빡임
        }
        flashlight *= flicker;
    #endif
    
    // 바닐라 조명
    float vanillaLight = lightmap.x;
    
    // 밤에는 바닐라 조명을 더욱 어둡게
    if (isNight) {
        vanillaLight = pow(vanillaLight, 4.0) * 0.3; // 밤은 확실히 어둡게
    } else if (isDusk) {
        vanillaLight = pow(vanillaLight, 3.0) * 0.7;
    } else {
        vanillaLight = pow(vanillaLight, 2.0) * 1.0;
    }
    
    // 조명 적용
    float finalLight = max(vanillaLight, flashlight);
    color *= finalLight;
    
    // 안개 효과
    float fogDist = depth + dist * 1.5 - vanillaLight * 3.0 - flashlight * 2.0;
    float fogStrength = (fogDist - 4.0) * 0.1;
    fogStrength = clamp(fogStrength, 0.0, 0.75);
    
    // 시간대별 안개 색상
    if (isNight) {
        // 밤 안개 (매우 어두운 푸른빛, 플래시라이트에 의해서만 보임)
        vec3 nightFogColor = vec3(0.02, 0.02, 0.04);
        color = mix(color, nightFogColor + flashlight * 0.01, fogStrength * 0.9);
    } else if (isDusk) {
        // 황혼 안개 (어두운 주황빛)
        vec3 duskFogColor = vec3(0.35, 0.25, 0.2);
        color = mix(color, duskFogColor, fogStrength * 0.6);
    } else {
        // 낮 안개 (비올 것 같은 흐린 느낌)
        vec3 dustColor = vec3(0.6, 0.58, 0.55);
        color = mix(color, dustColor, fogStrength * 0.55);
    }
    
    // 회색조 효과 (약하게)
    float grayEffect = fogStrength * (1.0 - vanillaLight * 0.5) * GRAY_FOG;
    vec3 grayColor = vec3(dot(color, vec3(0.2125, 0.7154, 0.0721)));
    color = mix(color, grayColor, min(grayEffect, 0.5));
    
    // 비 올 때 효과
    if (rainStrength > 0.0) {
        color *= (1.0 - rainStrength * 0.25);
        color = mix(color, vec3(0.3, 0.3, 0.35), rainStrength * 0.2);
    }
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0f);
}