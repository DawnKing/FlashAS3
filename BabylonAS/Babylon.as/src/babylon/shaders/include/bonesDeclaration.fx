#if NUM_BONE_INFLUENCERS > 0
    uniform mat4 mBones[BonesPerMesh];

    attribute vec4 matricesIndices;
    attribute vec4 matricesWeights;
#endif