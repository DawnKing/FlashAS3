// Attributes
attribute vec2 vertexQuad;
attribute vec2 uvQuad;
attribute vec2 rotatedUVQuad;

// Uniforms
uniform vec2 position;
uniform vec2 widthHeight;

uniform vec2 uvPosition;
uniform vec2 uvWidthHeight;

uniform float vertexConst0;
uniform float vertexConst1;
uniform float rotated;
uniform float mirror;

// Output
varying vec2 vDiffuseUV;

void main(void) {
    // 顶点位置
    vec4 pos;
    mul pos, widthHeight, vertexQuad;
    add pos, pos, position;
    mov pos.z, vertexConst0;
    mov pos.w, vertexConst1;
    mov op, pos;

    // uv计算
    // 纹理是否旋转
    float rot;
    float notRot;
    mov rot rotated;
    sub notRot, vertexConst1, rot;

    vec4 result;
    vec4 temp;
    // 未旋转纹纹理镜像
    mov result, uvQuad;
    sub result.x, mirror, result.x;
    abs result.x, result.x;
    // 未旋转纹理
    mul result, result, notRot;
    // 旋转纹理镜像
    mov temp, rotatedUVQuad;
    sub temp.y, mirror, temp.y;
    abs temp.y, temp.y;
    // 旋转纹理
    mul temp, temp, rot;
    // 纹理位置计算
    add result, result, temp;
    // 纹理
    mul pos, uvWidthHeight, result;
    add pos, pos, uvPosition;
    mov vDiffuseUV, pos.xy;
}