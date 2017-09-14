#if NUM_BONE_INFLUENCERS > 0
	Transpose(finalWorld);

	mat4 tempInfluence;
	mul tempInfluence[0], mBones[matricesIndices.x+0], matricesWeights.x;
	mul tempInfluence[1], mBones[matricesIndices.x+1], matricesWeights.x;
	mul tempInfluence[2], mBones[matricesIndices.x+2], matricesWeights.x;
	mul tempInfluence[3], mBones[matricesIndices.x+3], matricesWeights.x;

//    mat4 temp;
//	#if NUM_BONE_INFLUENCERS > 1
//		mul temp[0], mBones[matricesIndices.y+0], matricesWeights.y;
//		mul temp[1], mBones[matricesIndices.y+1], matricesWeights.y;
//		mul temp[2], mBones[matricesIndices.y+2], matricesWeights.y;
//		mul temp[3], mBones[matricesIndices.y+3], matricesWeights.y;
//		add tempInfluence[0], tempInfluence[0], temp[0];
//		add tempInfluence[1], tempInfluence[1], temp[1];
//		add tempInfluence[2], tempInfluence[2], temp[2];
//		add tempInfluence[3], tempInfluence[3], temp[3];
//	#endif
//	#if NUM_BONE_INFLUENCERS > 2
//		mul temp[0], mBones[matricesIndices.z+0], matricesWeights.z;
//		mul temp[1], mBones[matricesIndices.z+1], matricesWeights.z;
//		mul temp[2], mBones[matricesIndices.z+2], matricesWeights.z;
//		mul temp[3], mBones[matricesIndices.z+3], matricesWeights.z;
//		add tempInfluence[0], tempInfluence[0], temp[0];
//		add tempInfluence[1], tempInfluence[1], temp[1];
//		add tempInfluence[2], tempInfluence[2], temp[2];
//		add tempInfluence[3], tempInfluence[3], temp[3];
//	#endif
//	#if NUM_BONE_INFLUENCERS > 3
//		mul temp[0], mBones[matricesIndices.w+0], matricesWeights.w;
//		mul temp[1], mBones[matricesIndices.w+1], matricesWeights.w;
//		mul temp[2], mBones[matricesIndices.w+2], matricesWeights.w;
//		mul temp[3], mBones[matricesIndices.w+3], matricesWeights.w;
//		add tempInfluence[0], tempInfluence[0], temp[0];
//		add tempInfluence[1], tempInfluence[1], temp[1];
//		add tempInfluence[2], tempInfluence[2], temp[2];
//		add tempInfluence[3], tempInfluence[3], temp[3];
//	#endif

	// finalWorld = finalWorld * tempInfluence;
	// Flash使用列矩阵，AGAL使用行矩阵
	m44 tempInfluence[0], tempInfluence[0], finalWorld;
	m44 tempInfluence[1], tempInfluence[1], finalWorld;
	m44 tempInfluence[2], tempInfluence[2], finalWorld;
	m44 tempInfluence[3], tempInfluence[3], finalWorld;

	mov finalWorld[0], tempInfluence[0];
	mov finalWorld[1], tempInfluence[1];
	mov finalWorld[2], tempInfluence[2];
	mov finalWorld[3], tempInfluence[3];
#endif