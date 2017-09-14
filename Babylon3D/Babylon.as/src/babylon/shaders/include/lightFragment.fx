#ifdef LIGHT{X}
	#ifndef SPECULARTERM
		// vec3 vLightSpecular{X} = vec3(0.);
		vec3 vLightSpecular{X};
		mov vLightSpecular{X}, fragmentConst0;
	#endif
	#ifdef POINTLIGHT{X}
		computeLighting(viewDirectionW, normalW, vLightData{X}, vLightDiffuse{X}.rgb, vLightSpecular{X}, vLightDiffuse{X}.a, glossiness);
	#endif

	#ifndef SPECULARTERM
		delete vLightSpecular{X};
	#endif

	float shadow;

	#ifdef SHADOW{X}
		#ifdef SHADOWVSM{X}
			computeShadowWithVSM(shadow, vPositionFromLight{X}, shadowSampler{X}, shadowsInfo{X}.z, shadowsInfo{X}.x);
		#else
		#ifdef SHADOWPCF{X}
			#if defined(POINTLIGHT{X})
				computeShadowWithPCFCube(shadow, vLightData{X}.xyz, shadowSampler{X}, shadowsInfo{X}.y, shadowsInfo{X}.z, shadowsInfo{X}.x);
			#else
				computeShadowWithPCF(shadow, vPositionFromLight{X}, shadowSampler{X}, shadowsInfo{X}.y, shadowsInfo{X}.z, shadowsInfo{X}.x);
			#endif
		#else
			#if defined(POINTLIGHT{X})
				computeShadowCube(shadow, vLightData{X}.xyz, shadowSampler{X}, shadowsInfo{X}.x, shadowsInfo{X}.z);
			#else
				computeShadow(shadow, vPositionFromLight{X}, shadowSampler{X}, shadowsInfo{X}.x, shadowsInfo{X}.z);
			#endif
		#endif
	#endif
	#else
		mov shadow, fragmentConst1;
	#endif

	// diffuseBase += info.diffuse * shadow;
	mul lightingInfoDiffuse, lightingInfoDiffuse, shadow;
	add diffuseBase, diffuseBase, lightingInfoDiffuse;
	delete lightingInfoDiffuse;

	#ifdef SPECULARTERM
		// specularBase += info.specular * shadow;
		mul lightingInfoSpecular, lightingInfoSpecular, shadow;
		add specularBase, specularBase, lightingInfoSpecular;
		delete lightingInfoSpecular;
	#endif

	delete shadow;
#endif