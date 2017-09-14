#ifdef LIGHT{X}
	uniform vec4 vLightData{X};
	uniform vec4 vLightDiffuse{X};
	#ifdef SPECULARTERM
		uniform vec3 vLightSpecular{X};
	#endif
	#ifdef SHADOW{X}
		uniform samplerCube shadowSampler{X};
		uniform vec3 shadowsInfo{X};
    #endif
#endif