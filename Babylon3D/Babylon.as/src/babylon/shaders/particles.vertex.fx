// Attributes
attribute vec3 position;
attribute vec4 color;
attribute vec4 options;

// Uniforms
uniform mat4 view;
uniform mat4 projection;
uniform float vertexConst0;
uniform float vertexConst05;

// Output
varying vec2 vUV;
varying vec4 vColor;

void main(void) {
    vec3 viewPos;
    m34 viewPos, position, view;
    vec3 cornerPos;
    float size = options.y;
    float angle = options.x;
    vec2 offset = options.zw;

    // cornerPos = vec3(offset.x - 0.5, offset.y  - 0.5, 0.) * size;
    sub cornerPos.x, offset.x, vertexConst05
    sub cornerPos.y, offset.y, vertexConst05;
    mov cornerPos.z, vertexConst0;
    mul cornerPos.xyz, cornerPos.xyz, size;

    // Rotate
    vec3 rotatedCorner;
    // rotatedCorner.x = cornerPos.x * cos(angle) - cornerPos.y * sin(angle);
    float sinAngle;
    float cosAngle;
    float temp;

    sin sinAngle, angle;
    cos cosAngle, angle;
    mul rotatedCorner.x, cornerPos.x, cosAngle;
    mul temp, cornerPos.y, sinAngle;
    sub rotatedCorner.x, rotatedCorner.x, temp;
    // rotatedCorner.y = cornerPos.x * sin(angle) + cornerPos.y * cos(angle);
    mul rotatedCorner.y, cornerPos.x, sinAngle;
    mul temp, cornerPos.y, cosAngle;
    add rotatedCorner.y, rotatedCorner.y, temp;
    mov rotatedCorner.z, vertexConst0;

    delete sinAngle;
    delete cosAngle;

    // Position
    add viewPos, viewPos, rotatedCorner;
    m44 op, viewPos, projection;

    mov vColor, color;
    mov vUV, offset;
}
