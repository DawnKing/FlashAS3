// Samplers
uniform sampler2D diffuseSampler0;
uniform sampler2D diffuseSampler1;
uniform sampler2D diffuseSampler2;
uniform sampler2D diffuseSampler3;
uniform sampler2D diffuseSampler4;
uniform sampler2D diffuseSampler5;
uniform sampler2D diffuseSampler6;
uniform sampler2D diffuseSampler7;

// Uniforms
uniform float fragmentConst0;      // 常量0
uniform float fragmentConst1;      // 常量1
uniform float fragmentConst2;      // 常量2
uniform float fragmentConst3;      // 常量3
uniform float fragmentConst4;      // 常量4
uniform float fragmentConst5;      // 常量5
uniform float fragmentConst6;      // 常量6
uniform float fragmentConst7;      // 常量7

// Input
varying vec2 vDiffuseUV;
varying float vBatchIndex;

void main(void) {
    vec4 baseColor;
    mov baseColor, fragmentConst0;
    ife vBatchIndex.x, fragmentConst0
        tex baseColor, vDiffuseUV, diffuseSampler0;
    els
    ife vBatchIndex.x, fragmentConst1
        tex baseColor, vDiffuseUV, diffuseSampler1;
    els
    ife vBatchIndex.x, fragmentConst2
        tex baseColor, vDiffuseUV, diffuseSampler2;
    els
    ife vBatchIndex.x, fragmentConst3
        tex baseColor, vDiffuseUV, diffuseSampler3;
    eif
    eif
    eif
    eif
    ife vBatchIndex.x, fragmentConst4
        tex baseColor, vDiffuseUV, diffuseSampler4;
    els
    ife vBatchIndex.x, fragmentConst5
        tex baseColor, vDiffuseUV, diffuseSampler5;
    els
    ife vBatchIndex.x, fragmentConst6
        tex baseColor, vDiffuseUV, diffuseSampler6;
    els
    ife vBatchIndex.x, fragmentConst7
        tex baseColor, vDiffuseUV, diffuseSampler7;
    eif
    eif
    eif
    eif

    mov oc, baseColor;
}