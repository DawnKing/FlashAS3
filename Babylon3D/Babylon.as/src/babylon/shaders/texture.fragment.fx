// Samplers
varying vec2 vDiffuseUV;
uniform sampler2D diffuseSampler;

#ifdef ALPHATEST
uniform float cutOff;
#endif

void main(void) {
	vec4 baseColor;

	// baseColor = texture2D(diffuseSampler, diffuseUV);
	tex baseColor, vDiffuseUV, diffuseSampler

#ifdef ALPHATEST
	sub baseColor.w, baseColor.w, cutOff;
	kil baseColor.w;
	add baseColor.w, baseColor.w, cutOff;
#endif

	mov oc, baseColor;
}