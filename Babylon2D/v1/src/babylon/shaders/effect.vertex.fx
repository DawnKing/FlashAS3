// Attributes
attribute vec2 vertexQuad;
attribute vec2 uvQuad;

// Uniforms
uniform vec2 position;
uniform vec2 widthHeight;

uniform vec2 uvPosition;
uniform vec2 uvWidthHeight;

uniform float vertexConst0;
uniform float vertexConst1;

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

    // uv
    mul pos, uvWidthHeight, uvQuad;
    add pos, pos, uvPosition;
    mov vDiffuseUV, pos.xy;
}