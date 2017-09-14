#ifndef FULLFLOAT
uniform float fragmentConst255;

pack(vec4 res, float depth) {
	//const vec4 bit_shift = vec4(255.0 * 255.0 * 255.0, 255.0 * 255.0, 255.0, 1.0);
	vec4 bit_shift;
	mov bit_shift.x, fragmentConst255;
	mul bit_shift.x, bit_shift.x, fragmentConst255;
	mul bit_shift.x, bit_shift.x, fragmentConst255;
	mov bit_shift.y, fragmentConst255;
	mul bit_shift.y, bit_shift.y, fragmentConst255;
	mov bit_shift.z, fragmentConst255;
	mov bit_shift.w, fragmentConst0;

	// const vec4 bit_mask = vec4(0.0, 1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0);
	vec4 bit_mask;
	mov bit_mask.x, fragmentConst0;
	mov bit_mask.y, fragmentConst1;
	div bit_mask.y, bit_mask.y, fragmentConst255;
	mov bit_mask.z, bit_mask.y;
	mov bit_mask.w, bit_mask.y;

	// vec4 res = fract(depth * bit_shift);
	mul bit_shift, bit_shift, depth;
	frc res, bit_shift;

	// res -= res.xxyz * bit_mask;
	vec4 temp;
	mul temp, res.xxyz, bit_mask;
	sub res, res, temp;

	delete bit_shift;
	delete bit_mask;
}

// Thanks to http://devmaster.net/
packHalf(vec2 color, float depth) {
	// const vec2 bitOffset = vec2(1.0 / 255., 0.);
	vec4 bitOffset;
	div bitOffset.x, fragmentConst1, fragmentConst255;
	mov bitOffset.y, fragmentConst0;

	// vec2 color = vec2(depth, fract(depth * 255.));
	mov bitOffset.z, depth;
	mul bitOffset.w, depth, fragmentConst255;
	frc bitOffset.w, bitOffset.w;
	mov color, bitOffset.zw;

	// return color - (color.yy * bitOffset);
	mul bitOffset.zw, bitOffset.ww, bitOffset.xy;
	sub color, color, bitOffset.zw;
}
#endif

varying vec4 vPosition;

#ifdef ALPHATEST
varying vec2 vUV;
uniform sampler2D diffuseSampler;
uniform float cutOff;
#endif

#ifdef CUBEMAP
uniform vec3 lightPosition;
uniform vec2 depthValues;
#endif

uniform float fragmentConst0;
uniform float fragmentConst05;
uniform float fragmentConst1;

void main(void) {
#ifdef ALPHATEST
//	if (texture2D(diffuseSampler, vUV).a < 0.4)
//		discard;
	// baseColor = texture2D(diffuseSampler, vUV);
	vec4 baseColor;
	tex baseColor, vUV, diffuseSampler
	sub baseColor.w, baseColor.w, cutOff;
	kil baseColor.w;
	add baseColor.w, baseColor.w, cutOff;
#endif

#ifdef CUBEMAP
	// vec3 directionToLight = vPosition.xyz - lightPosition;
	vec3 directionToLight;
	sub directionToLight, vPosition.xyz, lightPosition;
	
	// float depth = length(directionToLight);
	float depth;
	dp3 depth, directionToLight, directionToLight;
	sqt depth, depth;

	// depth = (depth - depthValues.x) / (depthValues.y - depthValues.x);
	vec4 temp;
	sub temp.x, depth, depthValues.x;
	mov temp.y, depthValues.y;
	sub temp.y, temp.y, depthValues.x;
	div depth, temp.x, temp.y;

	// depth = clamp(depth, 0., 1.0);
	sat depth, depth;
#else
	// float depth = vPosition.z / vPosition.w;
	float depth;
	div depth, vPosition.z, vPosition.w;

	// depth = depth * 0.5 + 0.5;
	mul depth, depth, fragmentConst05;
	add depth, depth, fragmentConst05;
#endif

#ifdef VSM
	// float moment1 = depth;
	float moment1;
	mov moment1, depth;

	// float moment2 = moment1 * moment1;
	float moment2;
	mul moment2, moment1, moment1;

	#ifndef FULLFLOAT
		// gl_FragColor = vec4(packHalf(moment1), packHalf(moment2));
		vec4 temp;
		packHalf(temp.xy, moment1);
		packHalf(temp.zw, moment2);
		mov oc, temp;
	#else
		// gl_FragColor = vec4(moment1, moment2, 1.0, 1.0);
		vec4 temp;
		mov temp.x, moment1;
		mov temp.y, moment2;
		mov temp.z, fragmentConst1;
		mov temp.w, fragmentConst1;
		mov oc, temp;
	#endif
#else
	#ifndef FULLFLOAT
		// gl_FragColor = pack(depth);
		vec4 temp;
		pack(temp, depth);
		mov oc, temp;
	#else
		// gl_FragColor = vec4(depth, 1.0, 1.0, 1.0);
		vec4 temp;
		mov temp, fragmentConst1;
		mov temp.x, depth;
		mov oc, temp;
	#endif
#endif
}