// Constants
uniform vec3 vEyePosition;
#ifdef SPECULARTERM
uniform vec4 vSpecularColor;
#endif

// Input
varying vec3 vPositionW;

#ifdef NORMAL
varying vec3 vNormalW;
#endif

// Lights
#include<lightFragmentDeclaration>[0..maxSimultaneousLights]

#include<lightsFragmentFunctions>
#include<shadowsFragmentFunctions>

// Samplers
#ifdef DIFFUSE
varying vec2 vDiffuseUV;
uniform sampler2D diffuseSampler;
#ifdef ALPHATEST
uniform float cutOff;
#endif
#endif

uniform float fragmentConst0;
uniform float fragmentConst1;

void main(void) {
	vec3 viewDirectionW;
	sub viewDirectionW, vEyePosition, vPositionW;
	nrm viewDirectionW, viewDirectionW;

	// Base color
	vec4 baseColor;
	mov baseColor, fragmentConst1;

	// Alpha

//	Bump
#ifdef NORMAL
	vec3 normalW;
	mov normalW, vNormalW;
	nrm normalW, normalW;
#else
	vec3 normalW;
	mov normalW, fragmentConst1;
#endif

#ifdef DIFFUSE
	// baseColor = texture2D(diffuseSampler, diffuseUV);
	tex baseColor, vDiffuseUV, diffuseSampler

#ifdef ALPHATEST
	sub baseColor.w, baseColor.w, cutOff;
	kil baseColor.w;
	add baseColor.w, baseColor.w, cutOff;
#endif

#endif

	// Specular map
#ifdef SPECULARTERM
	float glossiness;
	mov glossiness, vSpecularColor.a;

	vec3 specularColor;
	mov specularColor, vSpecularColor.rgb;
#else
	float glossiness;
	mov glossiness, fragmentConst0;
#endif

	// Lighting
	vec3 diffuseBase;
	mov diffuseBase, fragmentConst0;

#ifdef SPECULARTERM
	vec3 specularBase;
	mov specularBase, fragmentConst0;
#endif

#include<lightFragment>[0..maxSimultaneousLights]

	delete viewDirectionW;
	delete normalW;
	delete glossiness;

//	vec3 finalDiffuse = clamp(diffuseBase, 0.0, 1.0) * baseColor.rgb;
	vec3 finalDiffuse;
	sat diffuseBase, diffuseBase;
	mul finalDiffuse, diffuseBase, baseColor;

	delete baseColor;
	delete diffuseBase;

#ifdef SPECULARTERM
	vec3 finalSpecular;
	mul, finalSpecular, specularBase, specularColor;

	delete specularColor;
	delete specularBase;
#else
	vec3 finalSpecular;
	mov finalSpecular, fragmentConst0;
#endif

	vec4 color;
	add color.xyz, finalDiffuse.xyz, finalSpecular.xyz;
	mov color.w, fragmentConst1;

	mov oc, color;
}