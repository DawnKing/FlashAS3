/**
 * Created by caijingxiao on 2017/1/6.
 */
package babylon.lights.shadows {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.lights.IShadowLight;
    import babylon.lights.Light;
    import babylon.lights.PointLight;
    import babylon.materials.Effect;
    import babylon.materials.Material;
    import babylon.materials.textures.BaseTexture;
    import babylon.materials.textures.RenderTargetTexture;
    import babylon.materials.textures.Texture;
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;
    import babylon.mesh.SubMesh;
    import babylon.mesh.VertexBuffer;
    import babylon.mesh._InstanceBatch;
    import babylon.postProcess.PassPostProcess;
    import babylon.postProcess.PostProcess;

    import easiest.unit.asserts.fail;

    public class ShadowGenerator implements IShadowGenerator {
        // Static
        private static const FILTER_NONE: int = 0;
        private static const FILTER_VARIANCESHADOWMAP: int = 1;
        private static const FILTER_POISSONSAMPLING: int = 2;
        private static const FILTER_BLURVARIANCESHADOWMAP: int = 3;

        // Members
        private var _filter: int = ShadowGenerator.FILTER_NONE;
        public var blurScale: Number = 2;
        private var _blurBoxOffset: Number = 0;
        private var _bias: Number = 0.00005;
        private var _lightDirection: Vector3 = Vector3.Zero();

        public var forceBackFacesOnly: Boolean = false;

        public function get bias(): Number {
            return this._bias;
        }

        public function set bias(bias: Number): void {
            this._bias = bias;
        }
        public function get blurBoxOffset(): Number {
            return this._blurBoxOffset;
        }

        public function set blurBoxOffset(value: Number):void {
            if (this._blurBoxOffset === value) {
                return;
            }

            this._blurBoxOffset = value;

            if (this._boxBlurPostprocess) {
                this._boxBlurPostprocess.dispose();
            }

            this._boxBlurPostprocess = new PostProcess("DepthBoxBlur", "depthBoxBlur", new <String>["screenSize", "boxOffset"], new <String>[], 1.0 / this.blurScale, null, Texture.BILINEAR_SAMPLINGMODE, this._scene.getEngine(), false, "#define OFFSET " + value);
            this._boxBlurPostprocess.onApplyObservable.add(function (effect: Effect): void {
                effect.setFloat2("screenSize", this._mapSize / this.blurScale, this._mapSize / this.blurScale);
            });
        }

        public function get filter(): Number {
            return this._filter;
        }

        public function set filter(value: Number): void {
            if (this._filter === value) {
                return;
            }

            this._filter = value;

            if (this.useVarianceShadowMap || this.useBlurVarianceShadowMap || this.usePoissonSampling) {
                this._shadowMap.anisotropicFilteringLevel = 16;
                this._shadowMap.updateSamplingMode(Texture.BILINEAR_SAMPLINGMODE);
            } else {
                this._shadowMap.anisotropicFilteringLevel = 1;
                this._shadowMap.updateSamplingMode(Texture.NEAREST_SAMPLINGMODE);
            }
        }

        public function get useVarianceShadowMap(): Boolean {
            return this.filter === ShadowGenerator.FILTER_VARIANCESHADOWMAP && this._light.supportsVSM();
        }
        public function set useVarianceShadowMap(value: Boolean): void {
            this.filter = (value ? ShadowGenerator.FILTER_VARIANCESHADOWMAP : ShadowGenerator.FILTER_NONE);
        }

        public function get usePoissonSampling(): Boolean {
            return this.filter === ShadowGenerator.FILTER_POISSONSAMPLING ||
                    (!this._light.supportsVSM() && (
                    this.filter === ShadowGenerator.FILTER_VARIANCESHADOWMAP ||
                    this.filter === ShadowGenerator.FILTER_BLURVARIANCESHADOWMAP
                    ));
        }
        public function set usePoissonSampling(value: Boolean): void {
            this.filter = (value ? ShadowGenerator.FILTER_POISSONSAMPLING : ShadowGenerator.FILTER_NONE);
        }

        public function get useBlurVarianceShadowMap(): Boolean {
            return this.filter === ShadowGenerator.FILTER_BLURVARIANCESHADOWMAP && this._light.supportsVSM();
        }
        public function set useBlurVarianceShadowMap(value: Boolean): void {
            this.filter = (value ? ShadowGenerator.FILTER_BLURVARIANCESHADOWMAP : ShadowGenerator.FILTER_NONE);
        }

        private var _light: IShadowLight;
        private var _scene: Scene;
        private var _shadowMap: RenderTargetTexture;
        private var _shadowMap2: RenderTargetTexture;
        private var _darkness: Number = 0;
        private var _transparencyShadow: Boolean = false;
        private var _effect: Effect;

        private var _viewMatrix: Matrix = Matrix.Zero();
        private var _projectionMatrix: Matrix = Matrix.Zero();
        private var _transformMatrix: Matrix = Matrix.Zero();
//        private var _worldViewProjection: Matrix = Matrix.Zero();
        private var _cachedPosition: Vector3;
        private var _cachedDirection: Vector3;
        private var _cachedDefines: String;
        private var _currentRenderID: Number;
        private var _downSamplePostprocess: PassPostProcess;
        private var _boxBlurPostprocess: PostProcess;
        private var _mapSize: Number;
        private var _currentFaceIndex: int = 0;
        private var _currentFaceIndexCache: int = 0;

        private var _useFullFloat: Boolean = true;

        public function ShadowGenerator(mapSize: Number, light: IShadowLight) {
            this._light = light;
            this._scene = light.getScene();
            this._mapSize = mapSize;

            Light(light)._shadowGenerator = this;

            // Texture type fallback from float to int if not supported.
            var textureType: Number;
//            var caps: EngineCapabilities = this._scene.getEngine().getCaps();
//            if (caps.textureFloat && caps.textureFloatLinearFiltering && caps.textureFloatRender) {
                this._useFullFloat = true;
                textureType = Engine.TEXTURETYPE_FLOAT;
//            }
//            else {
//            this._useFullFloat = false;
//            textureType = Engine.TEXTURETYPE_UNSIGNED_INT;
//            }

            // Render target
            this._shadowMap = new RenderTargetTexture(Light(light).name + "_shadowMap", mapSize, this._scene, false, true, textureType, light.needCube());
            this._shadowMap.wrapU = Texture.CLAMP_ADDRESSMODE;
            this._shadowMap.wrapV = Texture.CLAMP_ADDRESSMODE;
            this._shadowMap.anisotropicFilteringLevel = 1;
            this._shadowMap.updateSamplingMode(Texture.NEAREST_SAMPLINGMODE);
            this._shadowMap.renderParticles = false;

            this._shadowMap.onBeforeRenderObservable.add(function (faceIndex: Number): void {
                _currentFaceIndex = faceIndex;
            });

            this._shadowMap.onAfterUnbindObservable.add(function(): void {
                if (!useBlurVarianceShadowMap) {
                    return;
                }

                if (!_shadowMap2) {
                    _shadowMap2 = new RenderTargetTexture(Light(light).name + "_shadowMap", mapSize, _scene, false, true, textureType);
                    _shadowMap2.wrapU = Texture.CLAMP_ADDRESSMODE;
                    _shadowMap2.wrapV = Texture.CLAMP_ADDRESSMODE;
                    _shadowMap2.updateSamplingMode(Texture.TRILINEAR_SAMPLINGMODE);

                    _downSamplePostprocess = new PassPostProcess("downScale", 1.0 / blurScale, null, Texture.BILINEAR_SAMPLINGMODE, _scene.getEngine());
                    _downSamplePostprocess.onApplyObservable.add(function (effect: Effect): void {
                        effect.setTexture("textureSampler", _shadowMap);
                    });

                    blurBoxOffset = 1;
                }

                _scene.postProcessManager.directRender(new <PostProcess>[_downSamplePostprocess, _boxBlurPostprocess], _shadowMap2.getInternalTexture());
            });

            // Custom render function
            function renderSubMesh(subMesh: SubMesh): void {
                var mesh: Mesh = subMesh.getRenderingMesh();
                var scene: Scene = _scene;
                var engine: Engine = scene.getEngine();

                // Culling
                engine.setState(subMesh.getMaterial().backFaceCulling);

                // Managing instances
                var batch: _InstanceBatch = mesh._getInstancesRenderList(subMesh._id);

                if (batch.mustReturn) {
                    return;
                }

                var hardwareInstancedRendering: Boolean = (batch.visibleInstances[subMesh._id] !== null) && (batch.visibleInstances[subMesh._id] !== null);

                if (isReady(subMesh, hardwareInstancedRendering)) {
                    engine.enableEffect(_effect);
                    mesh._bind(subMesh, _effect, Material.TriangleFillMode);
                    var material: Material = subMesh.getMaterial();

                    _effect.setMatrix("viewProjection", getTransformMatrix(), true);
                    _effect.setVector3("lightPosition", getLight().position);

                    _effect.setFloat("vertexConst0", 0);
                    _effect.setFloat("vertexConst1", 1);
                    _effect.setFloat("fragmentConst0", 0);
                    _effect.setFloat("fragmentConst1", 1);

                    if (_useFullFloat) {
                        _effect.setFloat("fragmentConst255", 255);
                    }

                    if (getLight().needCube()) {
                        _effect.setFloat2("depthValues", scene.activeCamera.minZ, scene.activeCamera.maxZ);
                    } else {
                        _effect.setFloat("fragmentConst05", 0.5);
                    }

                    // Alpha test
                    if (material && material.needAlphaTesting()) {
                        var alphaTexture: BaseTexture = material.getAlphaTestTexture();
                        _effect.setTexture("diffuseSampler", alphaTexture);
                        _effect.setMatrix("diffuseMatrix", alphaTexture.getTextureMatrix(), true);

                        _effect.setFloat("cutOff", 0.4);
                    }

                    // Bones
                    if (mesh.useBones && mesh.computeBonesUsingShaders) {
                        _effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices(mesh), false);
                    }

                    if (forceBackFacesOnly) {
                        engine.setState(true, 0, false, true);
                    }

                    // Draw
                    mesh._processRendering(subMesh, Material.TriangleFillMode, batch,
                            function (isInstance: Boolean, world: Matrix): void { _effect.setMatrix("world", world, false) });

                    if (forceBackFacesOnly) {
                        engine.setState(true, 0, false, false);
                    }
                } else {
                    // Need to reset refresh rate of the shadowMap
                    _shadowMap.resetRefreshCounter();
                }
            }

            this._shadowMap.customRenderFunction = function (opaqueSubMeshes: Vector.<SubMesh>, alphaTestSubMeshes: Vector.<SubMesh>, transparentSubMeshes: Vector.<SubMesh>): void {
                var index: Number;

                for (index = 0; index < opaqueSubMeshes.length; index++) {
                    renderSubMesh(opaqueSubMeshes[index]);
                }

                for (index = 0; index < alphaTestSubMeshes.length; index++) {
                    renderSubMesh(alphaTestSubMeshes[index]);
                }

                if (_transparencyShadow) {
                    for (index = 0; index < transparentSubMeshes.length; index++) {
                        renderSubMesh(transparentSubMeshes[index]);
                    }
                }
            };

            this._shadowMap.onClearObservable.add(function (engine: Engine): void {
                if (useBlurVarianceShadowMap || useVarianceShadowMap) {
                    engine.clear(new Color4(0, 0, 0, 0), true, true, true);
                } else {
                    engine.clear(new Color4(1.0, 1.0, 1.0, 1.0), true, true, true);
                }
            });
        }

        public function isReady(subMesh: SubMesh, useInstances: Boolean): Boolean {
            var defines: Vector.<String> = new <String>[];

            if (this._useFullFloat) {
                defines.push("#define FULLFLOAT");
            }

            if (this.useVarianceShadowMap || this.useBlurVarianceShadowMap) {
                defines.push("#define VSM");
            }

            if (this.getLight().needCube()) {
                defines.push("#define CUBEMAP");
            }

            var attribs: Vector.<String> = new <String>[VertexBuffer.PositionKind];

            var mesh: AbstractMesh = subMesh.getMesh();
            var material: Material = subMesh.getMaterial();

            // Alpha test
            if (material && material.needAlphaTesting()) {
                defines.push("#define ALPHATEST");
                if (mesh.isVerticesDataPresent(VertexBuffer.UVKind)) {
                    attribs.push(VertexBuffer.UVKind);
                    defines.push("#define UV1");
                }
                if (mesh.isVerticesDataPresent(VertexBuffer.UV2Kind)) {
                    fail("uv2");
                    var alphaTexture: BaseTexture = material.getAlphaTestTexture();

                    if (alphaTexture.coordinatesIndex === 1) {
                        attribs.push(VertexBuffer.UV2Kind);
                        defines.push("#define UV2");
                    }
                }
            }

            // Bones
            if (mesh.useBones && mesh.computeBonesUsingShaders) {
                attribs.push(VertexBuffer.MatricesIndicesKind);
                attribs.push(VertexBuffer.MatricesWeightsKind);
                if (mesh.numBoneInfluencers > 4) {
                    fail();
//                    attribs.push(VertexBuffer.MatricesIndicesExtraKind);
//                    attribs.push(VertexBuffer.MatricesWeightsExtraKind);
                }
                defines.push("#define NUM_BONE_INFLUENCERS " + mesh.numBoneInfluencers);
                defines.push("#define BonesPerMesh " + (mesh.skeleton.bones.length + 1));
            } else {
                defines.push("#define NUM_BONE_INFLUENCERS 0");
            }

            // Instances
            if (useInstances) {
                defines.push("#define INSTANCES");
                attribs.push("world0");
                attribs.push("world1");
                attribs.push("world2");
                attribs.push("world3");
            }

            // Get correct effect
            var join: String = defines.join("\n");
            if (this._cachedDefines !== join) {
                this._cachedDefines = join;
                this._effect = this._scene.getEngine().createEffect("shadowMap",
                        attribs,
                        new <String>["world", "mBones", "viewProjection", "diffuseMatrix", "lightPosition", "depthValues",
                            "vertexConst0", "vertexConst1", "fragmentConst255", "fragmentConst0", "fragmentConst1", "cutOff"],
                        new <String>["diffuseSampler"], join);
            }

            return this._effect.isReady();
        }

        public function getShadowMap(): RenderTargetTexture {
            return this._shadowMap;
        }

        public function getShadowMapForRendering(): RenderTargetTexture {
            if (this._shadowMap2) {
                return this._shadowMap2;
            }

            return this._shadowMap;
        }

        public function getLight(): IShadowLight {
            return this._light;
        }

        // Methods
        public function getTransformMatrix(): Matrix {
            var scene: Scene = this._scene;
            if (this._currentRenderID === scene.getRenderId() && this._currentFaceIndexCache === this._currentFaceIndex) {
                return this._transformMatrix;
            }

            this._currentRenderID = scene.getRenderId();
            this._currentFaceIndexCache = this._currentFaceIndex;

            var lightPosition: Vector3 = this._light.position;
            Vector3.NormalizeToRef(this._light.getShadowDirection(this._currentFaceIndex), this._lightDirection);

            if (Math.abs(Vector3.Dot(this._lightDirection, Vector3.Up())) === 1.0) {
                this._lightDirection.z = 0.0000000000001; // Required to avoid perfectly perpendicular light
            }

            if (this._light.computeTransformedPosition()) {
                lightPosition = this._light.transformedPosition;
            }

            if (this._light.needRefreshPerFrame() || !this._cachedPosition || !this._cachedDirection || !lightPosition.equals(this._cachedPosition) || !this._lightDirection.equals(this._cachedDirection)) {

                this._cachedPosition = lightPosition.clone();
                this._cachedDirection = this._lightDirection.clone();

                Matrix.LookAtLHToRef(lightPosition, lightPosition.add(this._lightDirection), Vector3.Up(), this._viewMatrix);

                this._light.setShadowProjectionMatrix(this._projectionMatrix, this._viewMatrix, this.getShadowMap().renderList);

                this._viewMatrix.multiplyToRef(this._projectionMatrix, this._transformMatrix);
            }

            return this._transformMatrix;
        }

        public function getDarkness(): Number {
            return this._darkness;
        }

        public function setDarkness(darkness: Number): void {
            if (darkness >= 1.0)
                this._darkness = 1.0;
            else if (darkness <= 0.0)
                this._darkness = 0.0;
            else
                this._darkness = darkness;
        }

        public function setTransparencyShadow(hasShadow: Boolean): void {
            this._transparencyShadow = hasShadow;
        }

        public function dispose(): void {
            this._shadowMap.dispose();

            if (this._shadowMap2) {
                this._shadowMap2.dispose();
            }

            if (this._downSamplePostprocess) {
                this._downSamplePostprocess.dispose();
            }

            if (this._boxBlurPostprocess) {
                this._boxBlurPostprocess.dispose();
            }
        }

        public function serialize(): Object {
            var serializationObject: Object = {};

            serializationObject.lightId = Light(this._light).id;
            serializationObject.mapSize = this.getShadowMap().getRenderSize();
            serializationObject.useVarianceShadowMap = this.useVarianceShadowMap;
            serializationObject.usePoissonSampling = this.usePoissonSampling;
            serializationObject.forceBackFacesOnly = this.forceBackFacesOnly;

            serializationObject.renderList = [];
            for (var meshIndex: int = 0; meshIndex < this.getShadowMap().renderList.length; meshIndex++) {
                var mesh: AbstractMesh = this.getShadowMap().renderList[meshIndex];

                serializationObject.renderList.push(mesh.id);
            }

            return serializationObject;
        }

        public static function Parse(parsedShadowGenerator: Object, scene: Scene): ShadowGenerator {
            //casting to point light, as light is missing the position attr and typescript complains.
            var light: PointLight = PointLight(scene.getLightByID(parsedShadowGenerator.lightId));
            var shadowGenerator: ShadowGenerator = new ShadowGenerator(parsedShadowGenerator.mapSize, light);

            for (var meshIndex: int = 0; meshIndex < parsedShadowGenerator.renderList.length; meshIndex++) {
                var meshes: Vector.<AbstractMesh> = scene.getMeshesByID(parsedShadowGenerator.renderList[meshIndex]);
                meshes.forEach(function (mesh: AbstractMesh): void {
                    shadowGenerator.getShadowMap().renderList.push(mesh);
                });
            }

            if (parsedShadowGenerator.usePoissonSampling) {
                shadowGenerator.usePoissonSampling = true;
            } else if (parsedShadowGenerator.useVarianceShadowMap) {
                shadowGenerator.useVarianceShadowMap = true;
            } else if (parsedShadowGenerator.useBlurVarianceShadowMap) {
                shadowGenerator.useBlurVarianceShadowMap = true;

                if (parsedShadowGenerator.blurScale) {
                    shadowGenerator.blurScale = parsedShadowGenerator.blurScale;
                }

                if (parsedShadowGenerator.blurBoxOffset) {
                    shadowGenerator.blurBoxOffset = parsedShadowGenerator.blurBoxOffset;
                }
            }

            if (parsedShadowGenerator.bias !== undefined) {
                shadowGenerator.bias = parsedShadowGenerator.bias;
            }

            shadowGenerator.forceBackFacesOnly = parsedShadowGenerator.forceBackFacesOnly;

            return shadowGenerator;
        }
    }
}
