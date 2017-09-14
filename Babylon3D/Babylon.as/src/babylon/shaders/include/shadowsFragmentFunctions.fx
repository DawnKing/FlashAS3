#ifdef SHADOWS
	#ifndef SHADOWFULLFLOAT
		unpack(float result, vec4 color) {
			// const vec4 bit_shift = vec4(1.0 / (255.0 * 255.0 * 255.0), 1.0 / (255.0 * 255.0), 1.0 / 255.0, 1.0);
			vec4 bit_shift;
            mov bit_shift.x, fragmentConst255;
            mul bit_shift.x, bit_shift.x, fragmentConst255;
            mul bit_shift.x, bit_shift.x, fragmentConst255;
            div bit_shift.x, fragmentConst1, bit_shift.x;
            mov bit_shift.y, fragmentConst255;
            mul bit_shift.y, bit_shift.y, fragmentConst255;
            div bit_shift.y, fragmentConst1, bit_shift.y;
            mov bit_shift.z, fragmentConst255;
            div bit_shift.z, fragmentConst1, bit_shift.z;
            mov bit_shift.w, fragmentConst1;
            // return dot(color, bit_shift);
            dot4 float, color, bit_shift;
            delete bit_shift;
		}
	#endif

	uniform vec2 depthValues;

	computeShadowCube(float result, vec3 lightPosition, samplerCube shadowSampler, float darkness, float bias) {
		// vec3 directionToLight = vPositionW - lightPosition;
		vec3 directionToLight;
		sub directionToLight, vPositionW, lightPosition;

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

		// directionToLight = normalize(directionToLight);
		nrm directionToLight, directionToLight;
		// directionToLight.y = -directionToLight.y;
		neg directionToLight.y, directionToLight.y;

		#ifndef SHADOWFULLFLOAT
			// float shadow = unpack(textureCube(shadowSampler, directionToLight)) + bias;
			float shadow2;
			vec4 temp;
			tex temp, directionToLight, shadowSampler;
			unpack(shadow2, temp);
			add shadow2, shadow2, bias;
		#else
			// float shadow2 = textureCube(shadowSampler, directionToLight).x + bias;
			float shadow2;
            vec4 temp;
            tex temp, directionToLight, shadowSampler;
            add shadow2, temp.x, bias;
		#endif

		delete directionToLight;

//		if (depth > shadow) {
//			return darkness;
//		}
        float if;
        slt if, shadow2, depth;
        mul result, if, darkness;
//		return 1.0;
        sub if, fragmentConst1, if;
        mul if, fragmentConst1, if;
        add result, result, if;

        delete depth;
        delete shadow2;
        delete if;
	}

	computeShadowWithPCFCube(float result, vec3 lightPosition, samplerCube shadowSampler, float mapSize, float bias, float darkness) {
		// vec3 directionToLight = vPositionW - lightPosition;
		vec3 directionToLight;
		sub directionToLight, vPositionW, lightPosition;

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

		// directionToLight = normalize(directionToLight);
		nrm directionToLight, directionToLight;
		// directionToLight.y = -directionToLight.y;
		neg directionToLight.y, directionToLight.y;

		// float visibility = 1.;
		float visibility;
		mov visibility, fragmentConst1;

//		vec3 poissonDisk[4];
//		poissonDisk[0] = vec3(-1.0, 1.0, -1.0);
//		poissonDisk[1] = vec3(1.0, -1.0, -1.0);
//		poissonDisk[2] = vec3(-1.0, -1.0, -1.0);
//		poissonDisk[3] = vec3(1.0, -1.0, 1.0);
		vec3 poissonDisk0;
		vec3 poissonDisk1;
		vec3 poissonDisk2;
		vec3 poissonDisk3;
		mov poissonDisk0, fragmentConst1;
		mov poissonDisk1, fragmentConst1;
		mov poissonDisk2, fragmentConst1;
		mov poissonDisk3, fragmentConst1;
		neg poissonDisk0.x, poissonDisk0.x;
		neg poissonDisk0.z, poissonDisk0.z;
		neg poissonDisk1.y, poissonDisk1.y;
		neg poissonDisk1.z, poissonDisk1.z;
		neg poissonDisk2, poissonDisk2;
		neg poissonDisk3.y, poissonDisk3.y;

		// Poisson Sampling
		// float biasedDepth = depth - bias;
		float biasedDepth;
		sub biasedDepth, depth, bias;

		delete depth;

		float const025;
		mov const025, fragmentConst1;
		add const025, const025, fragmentConst1;
		add const025, const025, fragmentConst1;
		add const025, const025, fragmentConst1;
		div const025, fragmentConst1, const025;

		#ifndef SHADOWFULLFLOAT
			// if (unpack(textureCube(shadowSampler, directionToLight + poissonDisk[0] * mapSize)) < biasedDepth) visibility -= 0.25;
			float shadow2;
			vec3 temp;
			mul temp, poissonDisk0, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			unpack(shadow2, temp);

			float if;
            slt if, shadow2, biasedDepth;
            mul if, if, const025;
            sub visibility, visibility, if;

			// if (unpack(textureCube(shadowSampler, directionToLight + poissonDisk[1] * mapSize)) < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk1, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			unpack(shadow2, temp);

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;

			// if (unpack(textureCube(shadowSampler, directionToLight + poissonDisk[2] * mapSize)) < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk2, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			unpack(shadow2, temp);

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;

			// if (unpack(textureCube(shadowSampler, directionToLight + poissonDisk[3] * mapSize)) < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk3, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			unpack(shadow2, temp);

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;
		#else
			// if (textureCube(shadowSampler, directionToLight + poissonDisk[0] * mapSize).x < biasedDepth) visibility -= 0.25;
			float shadow2;
			vec3 temp;
			mul temp, poissonDisk0, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			mov shadow2, temp.x;

			float if;
			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;

			// if (textureCube(shadowSampler, directionToLight + poissonDisk[1] * mapSize).x < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk1, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			mov shadow2, temp.x;

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;

			// if (textureCube(shadowSampler, directionToLight + poissonDisk[2] * mapSize).x < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk2, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			mov shadow2, temp.x;

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;

			// if (textureCube(shadowSampler, directionToLight + poissonDisk[3] * mapSize).x < biasedDepth) visibility -= 0.25;
			vec3 temp;
			mul temp, poissonDisk3, mapSize;
			add temp, temp, directionToLight;
			tex temp, temp, shadowSampler;
			mov shadow2, temp.x;

			slt if, shadow2, biasedDepth;
			mul if, if, const025;
			sub visibility, visibility, if;
		#endif

		delete directionToLight;
		delete visibility;
		delete poissonDisk0;
		delete poissonDisk1;
		delete poissonDisk2;
		delete poissonDisk3;
		delete const025;
		delete shadow2;
		delete if;

		// return  min(1.0, visibility + darkness);
		add result, visibility, darkness;
		min result, result, fragmentConst1;
	}
#endif