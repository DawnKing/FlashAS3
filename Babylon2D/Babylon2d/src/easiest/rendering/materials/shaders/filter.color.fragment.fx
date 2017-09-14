// Uniforms
uniform mat4 colorMatrixFilter;
uniform vec4 colorMatrixOffset;
uniform vec4 minColor;

// Samplers
uniform sampler2D diffuseSampler;

// Input
varying vec2 vDiffuseUV;

void main(void) {
    vec4 baseColor;
	tex baseColor, vDiffuseUV, diffuseSampler

	// color matrix
    max baseColor, baseColor, minColor;                 // avoid division through zero in next step
    div baseColor.xyz, baseColor.xyz, baseColor.www;    // restore original (non-PMA) RGB values
    m44 baseColor, baseColor, colorMatrixFilter;        // multiply color with 4x4 matrix
    add baseColor, baseColor, colorMatrixOffset;        // add offset
    mul baseColor.xyz, baseColor.xyz, baseColor.www;    // multiply with alpha again (PMA)

    mov oc, baseColor;
}