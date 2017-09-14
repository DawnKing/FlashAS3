/**
 * Created by caijingxiao on 2016/11/16.
 */
package babylon.materials {
    import babylon.Scene;
    import babylon.lights.Light;
    import babylon.lights.PointLight;
    import babylon.lights.shadows.ShadowGenerator;
    import babylon.math.Tmp;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.VertexBuffer;

    import easiest.unit.asserts.fail;

    public class MaterialHelper {
        public static function PrepareDefinesForLights(scene: Scene, mesh: AbstractMesh, defines: MaterialDefines, maxSimultaneousLights: int = 4): Boolean {
            var lightIndex: int = 0;
            var needNormals: Boolean = false;
            var needShadows: Boolean = false;
//            var lightmapMode: Boolean = false;

            for (var index: int = 0; index < scene.lights.length; index++) {
                var light: Light = scene.lights[index];

                if (!light.isEnabled()) {
                    continue;
                }

                // Excluded check
                if (light._excludedMeshesIds.length > 0) {
                    for (var excludedIndex: int = 0; excludedIndex < light._excludedMeshesIds.length; excludedIndex++) {
                        var excludedMesh: AbstractMesh = scene.getMeshByID(light._excludedMeshesIds[excludedIndex]);

                        if (excludedMesh) {
                            light.excludedMeshes.push(excludedMesh);
                        }
                    }

                    light._excludedMeshesIds = new <String>[];
                }

                // Included check
                if (light._includedOnlyMeshesIds.length > 0) {
                    for (var includedOnlyIndex: int = 0; includedOnlyIndex < light._includedOnlyMeshesIds.length; includedOnlyIndex++) {
                        var includedOnlyMesh: AbstractMesh = scene.getMeshByID(light._includedOnlyMeshesIds[includedOnlyIndex]);

                        if (includedOnlyMesh) {
                            light.includedOnlyMeshes.push(includedOnlyMesh);
                        }
                    }

                    light._includedOnlyMeshesIds = new <String>[];
                }

                if (!light.canAffectMesh(mesh)) {
                    continue;
                }
                needNormals = true;

                defines.setKey("LIGHT" + lightIndex, true);

                var type: String;
//                if (light is SpotLight) {
//                    type = "SPOTLIGHT" + lightIndex;
//                } else if (light is HemisphericLight) {
//                    type = "HEMILIGHT" + lightIndex;
//                } else
                if (light is PointLight) {
                    type = "POINTLIGHT" + lightIndex;
                } else {
                    type = "DIRLIGHT" + lightIndex;
                }

                defines.setKey(type, true);

                // Specular
                if (!light.specular.equalsFloats(0, 0, 0) && defines["SPECULARTERM"] !== undefined) {
                    defines["SPECULARTERM"] = true;
                }

                // Shadows
                if (scene.shadowsEnabled) {
                    var shadowGenerator: ShadowGenerator = light.getShadowGenerator() as ShadowGenerator;
                    if (mesh && mesh.receiveShadows && shadowGenerator) {
                        defines.setKey("SHADOW" + lightIndex, true);

                        defines.setKey("SHADOWS", true);

//                        if (shadowGenerator.useVarianceShadowMap || shadowGenerator.useBlurVarianceShadowMap) {
//                            if (defines["SHADOWVSM" + lightIndex] === undefined) {
//                                needRebuild = true;
//                            }
//
//                            defines["SHADOWVSM" + lightIndex] = true;
//                        }

                        if (shadowGenerator.usePoissonSampling) {
                            defines.setKey("SHADOWPCF" + lightIndex, true);
                        }

                        needShadows = true;
                    }
                }

//                if (light.lightmapMode != Light.LIGHTMAP_DEFAULT ) {
//                    lightmapMode = true;
//                    if (defines["LIGHTMAPEXCLUDED" + lightIndex] === undefined) {
//                        defines.setKey("LIGHTMAPEXCLUDED" + lightIndex, true);
//                    }
//                    if (defines["LIGHTMAPNOSPECULAR" + lightIndex] === undefined) {
//                        defines.setKey("LIGHTMAPNOSPECULAR" + lightIndex, true);
//                    }
//                    defines["LIGHTMAPEXCLUDED" + lightIndex] = true;
//                    if (light.lightmapMode == Light.LIGHTMAP_SHADOWSONLY) {
//                        defines["LIGHTMAPNOSPECULAR" + lightIndex] = true;
//                    }
//                }

                lightIndex++;
                if (lightIndex === maxSimultaneousLights)
                    break;
            }

//            var caps = scene.getEngine().getCaps();
//            if (needShadows && caps.textureFloat && caps.textureFloatLinearFiltering && caps.textureFloatRender) {
//                if (defines["SHADOWFULLFLOAT"] === undefined) {
//                    needRebuild = true;
//                }
//
//                defines["SHADOWFULLFLOAT"] = true;
//            }

            if (needShadows) {
                defines.setKey("SHADOWFULLFLOAT", true);
            }

//            if (!defines.hasOwnProperty("LIGHTMAPEXCLUDED")) {
//                defines.setKey("LIGHTMAPEXCLUDED", true);
//            }
//            if (lightmapMode) {
//                defines["LIGHTMAPEXCLUDED"] = true;
//            }

            return needNormals;
        }

        public static function PrepareUniformsAndSamplersList(uniformsList: Vector.<String>, samplersList: Vector.<String>, defines: MaterialDefines, maxSimultaneousLights: int = 4): void {
            for (var lightIndex: int = 0; lightIndex < maxSimultaneousLights; lightIndex++) {
                if (!defines["LIGHT" + lightIndex]) {
                    break;
                }

                uniformsList.push(
                        "vLightData" + lightIndex,
                        "vLightDiffuse" + lightIndex,
                        "vLightSpecular" + lightIndex,
                        "vLightDirection" + lightIndex,
                        "vLightGround" + lightIndex,
                        "lightMatrix" + lightIndex,
                        "shadowsInfo" + lightIndex
                );

                samplersList.push("shadowSampler" + lightIndex);
            }
        }

        public static function PrepareAttributesForBones(attribs: Vector.<String>, defines: MaterialDefines): void {//193
            if (defines["NUM_BONE_INFLUENCERS"]) {
                attribs.push(VertexBuffer.MatricesIndicesKind);
                attribs.push(VertexBuffer.MatricesWeightsKind);
                if (defines["NUM_BONE_INFLUENCERS"] > 4) {
                    fail();
                }
            }
        }

        // Bindings
        public static function BindLightShadow(light: Light, scene: Scene, mesh: AbstractMesh, lightIndex: int, effect: Effect, depthValuesAlreadySet: Boolean): Boolean {
            var shadowGenerator: ShadowGenerator = ShadowGenerator(light.getShadowGenerator());
            if (mesh.receiveShadows && shadowGenerator) {
                if (!Object(light).needCube()) {
                    fail();
                    effect.setMatrix("lightMatrix" + lightIndex, shadowGenerator.getTransformMatrix(), true);
                } else {
                    if (!depthValuesAlreadySet) {
                        depthValuesAlreadySet = true;
                        effect.setFloat2("depthValues", scene.activeCamera.minZ, scene.activeCamera.maxZ);
                    }
                }
                effect.setTexture("shadowSampler" + lightIndex, shadowGenerator.getShadowMapForRendering());
                effect.setFloat3("shadowsInfo" + lightIndex, shadowGenerator.getDarkness(), shadowGenerator.blurScale / shadowGenerator.getShadowMap().getSize().width, shadowGenerator.bias);
            }

            return depthValuesAlreadySet;
        }

        public static function BindLightProperties(light: Light, effect: Effect, lightIndex: int): void {
            if (light is PointLight) {
                // Point Light
                light.transferToEffect(effect, "vLightData" + lightIndex);
            }
//            else if (light is DirectionalLight) {
//                // Directional Light
//                light.transferToEffect(effect, "vLightData" + lightIndex);
//            } else if (light is SpotLight) {
//                // Spot Light
//                light.transferToEffect(effect, "vLightData" + lightIndex, "vLightDirection" + lightIndex);
//            } else if (light is HemisphericLight) {
//                // Hemispheric Light
//                light.transferToEffect(effect, "vLightData" + lightIndex, "vLightGround" + lightIndex);
//            }
        }

        public static function BindLights(scene: Scene, mesh: AbstractMesh, effect: Effect, defines: MaterialDefines, maxSimultaneousLights: int = 4): void {
            var lightIndex: int = 0;
            var depthValuesAlreadySet: Boolean = false;
            for (var index: int = 0; index < scene.lights.length; index++) {
                var light: Light = scene.lights[index];

                if (!light.isEnabled()) {
                    continue;
                }

                if (!light.canAffectMesh(mesh)) {
                    continue;
                }

                BindLightProperties(light, effect, lightIndex);

                light.diffuse.scaleToRef(light.intensity, Tmp.COLOR3[0]);
                effect.setColor4("vLightDiffuse" + lightIndex, Tmp.COLOR3[0], light.range);
                if (defines["SPECULARTERM"]) {
                    light.specular.scaleToRef(light.intensity, Tmp.COLOR3[1]);
                    effect.setColor3("vLightSpecular" + lightIndex, Tmp.COLOR3[1]);
                }

                // Shadows
                if (scene.shadowsEnabled) {
                    depthValuesAlreadySet = BindLightShadow(light, scene, mesh, lightIndex, effect, depthValuesAlreadySet);
                }

                lightIndex++;

                if (lightIndex === maxSimultaneousLights)
                    break;
            }
        }

        public static function BindBonesParameters(mesh: AbstractMesh, effect: Effect): void {
            if (mesh && mesh.useBones && mesh.computeBonesUsingShaders) {
                var matrices: Vector.<Number> = mesh.skeleton.getTransformMatrices(mesh);

                if (matrices) {
                    effect.setMatrices("mBones", matrices, false);
                }
            }
        }
    }
}
