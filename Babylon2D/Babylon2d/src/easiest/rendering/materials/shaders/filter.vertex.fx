// Attributes
attribute vec2 vertexQuad;
attribute vec2 uvQuad;
attribute vec2 rotatedUVQuad;

// Uniforms
uniform vec4 matrix1;
uniform vec4 matrix2;
uniform vec2 widthHeight;
uniform vec2 stageWidthHeight;

uniform vec2 uvPosition;
uniform vec2 uvWidthHeight;

uniform float rotated;
uniform float mirror;
uniform float vertexConst0;
uniform float vertexConst1;

// Output
varying vec2 vDiffuseUV;

void main(void) {
    // 顶点位置计算
    vec4 pos;
    // 基于（0， 0）点算出边框
    mul pos.xy, widthHeight, vertexQuad;
    mov pos.z, vertexConst1;
    // 旋转缩放偏移计算
    dp3 pos.w, pos.xyz, matrix1;
    dp3 pos.y, pos.xyz, matrix2;
    mov pos.x, pos.w;
    // 把坐标标准化在[-1, 1]范围内
    div pos.xy, pos.xy, stageWidthHeight;
    sub pos.x, pos.x, vertexConst1;
    sub pos.y, vertexConst1, pos.y;
    mov pos.z, vertexConst0;
    mov pos.w, vertexConst1;
    mov op, pos;

    // uv计算
    vec4 result;
    // 纹理旋转
    ife rotated, vertexConst1;
        mov result, rotatedUVQuad;
        sub result.y, mirror, result.y;
        abs result.y, result.y;
    els // 不旋转
        mov result, uvQuad;
        sub result.x, mirror, result.x;
        abs result.x, result.x;
    eif

    // 纹理
    mul pos, uvWidthHeight, result;
    add pos, pos, uvPosition;
    mov vDiffuseUV, pos.xy;
}