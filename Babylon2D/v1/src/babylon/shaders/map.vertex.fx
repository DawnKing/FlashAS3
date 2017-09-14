// Attributes
attribute vec2 vertexPosition;
attribute vec2 uv;

// Uniforms
uniform vec2 position;

uniform float vertexConst0;
uniform float vertexConst1;

// Output
varying vec2 vDiffuseUV;

void main(void) {
    vec4 pos;
    add pos, vertexPosition, position;
    mov pos.z, vertexConst0;
    mov pos.w, vertexConst1;
    mov op, pos;

    mov vDiffuseUV, uv;
}