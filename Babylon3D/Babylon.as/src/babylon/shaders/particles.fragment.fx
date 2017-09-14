// Samplers
varying vec2 vUV;
varying vec4 vColor;
uniform vec4 textureMask;
uniform sampler2D diffuseSampler;
uniform float fragmentConst1;

void main(void) {
    // 	vec4 baseColor = texture2D(diffuseSampler, vUV);
    vec4 baseColor;

    tex baseColor, vUV, diffuseSampler;

    // gl_FragColor = (baseColor * textureMask + (vec4(1., 1., 1., 1.) - textureMask)) * vColor;
    vec4 temp;

    mul baseColor, baseColor, textureMask;
    mov temp, fragmentConst1;
    sub temp, temp, textureMask;
    add baseColor, baseColor, temp;
    mul baseColor, baseColor, vColor;
    mov oc, baseColor;
}