computeLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec3 diffuseColor, vec3 specularColor, float range, float glossiness) {
	vec3 lightVectorW;

	// float attenuation = 1.0;
	float attenuation;
	mov attenuation, fragmentConst1;

	// if (lightData.w == 0.)
	float ifv
	mov ifv, lightData.w;
	seq ifv, ifv, fragmentConst0;

	// vec3 direction = lightData.xyz - vPositionW;
	vec3 direction;
	sub direction, lightData.xyz, vPositionW;

	// length(direction)
	float tempLength;
	dp3 tempLength, direction, direction;
	sqt tempLength, tempLength;

	// attenuation = max(0., 1.0 - length(direction) / range);
	div tempLength, tempLength, range;
	sub tempLength, fragmentConst1, tempLength;
	max attenuation, fragmentConst0, tempLength;
	mul attenuation, attenuation, ifv;

	// lightVectorW = normalize(direction);
	nrm direction, direction;
	mov lightVectorW, direction;
	mul lightVectorW, lightVectorW, ifv;

	delete direction;

	// lightVectorW = normalize(-lightData.xyz);
	vec3 temp;
	mov temp, lightData.xyz;
	neg temp, temp;
	nrm temp, temp;
	sub ifv, fragmentConst1, ifv;
	mul temp, temp, ifv;
	add lightVectorW, lightVectorW, temp;

	delete ifv;

	// diffuse
	// float ndl = max(0., dot(vNormal, lightVectorW));
	float ndl;
	vec3 temp;
	dp3 temp, vNormal, lightVectorW;
	max ndl, fragmentConst0, temp;

	vec3 angleW;
	mov angleW, lightVectorW;
	delete lightVectorW;

	// result.diffuse = ndl * diffuseColor * attenuation;
	vec3 lightingInfoDiffuse
	mul lightingInfoDiffuse, ndl, diffuseColor;
	mul lightingInfoDiffuse, lightingInfoDiffuse, attenuation;

	delete ndl;

#ifdef SPECULARTERM
	// Specular
	// vec3 angleW = normalize(viewDirectionW + lightVectorW);
	add angleW, angleW, viewDirectionW;
	nrm angleW, angleW;

	// float specComp = max(0., dot(vNormal, angleW));
	float specComp;
	dp3 specComp, vNormal, angleW;
	max specComp, fragmentConst0, specComp;

	delete angleW;

	// specComp = pow(specComp, max(1., glossiness));
	float temp;
	max temp, fragmentConst1, glossiness;
	pow specComp, specComp, temp;

	// result.specular = specComp * specularColor * attenuation;
	vec3 lightingInfoSpecular;
	mov lightingInfoSpecular, specularColor;
	mul lightingInfoSpecular, lightingInfoSpecular, specComp;
	mul lightingInfoSpecular, lightingInfoSpecular, attenuation;

    delete specComp;
#endif

	delete attenuation;
}