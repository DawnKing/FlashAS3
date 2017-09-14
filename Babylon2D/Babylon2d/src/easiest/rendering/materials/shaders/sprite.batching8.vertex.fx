// Attributes
attribute vec2 vertexQuad;
attribute vec2 uvQuad;
attribute vec2 rotatedUVQuad;
attribute float batchIndex;

// Uniforms
uniform float vertexConst0;      // 常量0
uniform float vertexConst1;      // 常量1
uniform float vertexConst2;      // 常量2
uniform float vertexConst3;      // 常量3
uniform float vertexConst4;      // 常量4
uniform float vertexConst5;      // 常量5
uniform float vertexConst6;      // 常量6
uniform float vertexConst7;      // 常量7

// Output
varying vec2 vDiffuseUV;
varying float vBatchIndex;

void main(void) {
    vec4 matrix;
    vec4 matrix_;
    vec4 spriteData;    // width height stageWidth stageHeight
    vec4 uvData;    // u v width height
    vec4 rotatedMirror; // AGAL不支持形如vc[index].x的格式，只能是vc[index]

    float index;
    mov index, batchIndex.x;
    mov matrix, vc[index];
    add index, index, vertexConst1;
    mov matrix_, vc[index];
    add index, index, vertexConst1;
    mov spriteData, vc[index];
    add index, index, vertexConst1;
    mov uvData, vc[index];
    add index, index, vertexConst1;
    mov rotatedMirror, vc[index];

    // 顶点位置计算
    vec4 pos;

    // 基于（0， 0）点算出边框
    mul pos.xy, spriteData.xy, vertexQuad;
    mov pos.z, vertexConst1;

    // 旋转缩放偏移计算
    dp3 pos.w, pos.xyz, matrix;
    dp3 pos.y, pos.xyz, matrix_;
    mov pos.x, pos.w;
    // 把坐标标准化在[-1, 1]范围内
    div pos.xy, pos.xy, spriteData.zw;
    sub pos.x, pos.x, vertexConst1;
    sub pos.y, vertexConst1, pos.y;
    mov pos.z, vertexConst0;
    mov pos.w, vertexConst1;
    mov op, pos;

    // uv计算
    vec4 result;
    // 纹理旋转
    ife rotatedMirror.x, vertexConst1;
        mov result, rotatedUVQuad;
        sub result.y, rotatedMirror.y, result.y;
        abs result.y, result.y;
    els // 不旋转
        mov result, uvQuad;
        sub result.x, rotatedMirror.y, result.x;
        abs result.x, result.x;
    eif

    // 纹理
    mul pos, uvData.zw, result;
    add pos, pos, uvData.xy;
    mov vDiffuseUV, pos.xy;

    float temp;
    // 当前合并渲染的寄存器偏移 = i * 5(shader占用的寄存器) + 2(常量数值占用的寄存器)，传到片段着色器的时候要变为0-7的索引
    sub temp, batchIndex.x, vertexConst2;
    div vBatchIndex, temp, vertexConst5;
}