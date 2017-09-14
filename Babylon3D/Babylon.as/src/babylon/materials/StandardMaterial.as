/**
 * Created by caijingxiao on 2016/10/18.
 */
package babylon.materials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.textures.BaseTexture;
    import babylon.math.Color3;
    import babylon.math.Matrix;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;
    import babylon.mesh.VertexBuffer;
    import babylon.tools.SerializationHelper;

    public class StandardMaterial extends Material {
        [Serialize(type="texture")]
        public var diffuseTexture: BaseTexture;

        [Serialize(type="color3")]
        public var specularColor: Color3 = new Color3(1, 1, 1);

        [Serialize]
        public var specularPower: int = 64;

        [Serialize]
        public var useAlphaFromDiffuseTexture: Boolean = false;

        [Serialize]
        public var disableLighting: Boolean = false;

        public var maxSimultaneousLights: int = 4;

        private var _renderId: int;

        private var _defines: StandardMaterialDefines = new StandardMaterialDefines();
        private var _cachedDefines: StandardMaterialDefines = new StandardMaterialDefines();

        public function StandardMaterial(name: String, scene: Scene) {
            super(name, scene);

            this._cachedDefines.BonesPerMesh = -1;
        }

        override public function needAlphaBlending(): Boolean {
            return (this.alpha < 1.0) || this._shouldUseAlphaFromDiffuseTexture();
        }

        override public function needAlphaTesting(): Boolean {
            return this.diffuseTexture != null && this.diffuseTexture.hasAlpha;
        }

        private function _shouldUseAlphaFromDiffuseTexture(): Boolean {
            return this.diffuseTexture != null && this.diffuseTexture.hasAlpha && this.useAlphaFromDiffuseTexture;
        }

        override public function getAlphaTestTexture(): BaseTexture {
            return this.diffuseTexture;
        }

        private function _checkCache(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {//257
            if (!mesh) {
                return true;
            }

            if (this._defines.INSTANCES !== useInstances) {
                return false;
            }

            if (mesh._materialDefines && mesh._materialDefines.isEqual(this._defines)) {
                return true;
            }

            return false;
        }

        override public function isReady(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {//273

            var scene: Scene = this.getScene();
            var engine: Engine = scene.getEngine();

            if (!this.checkReadyOnEveryCall) {
                if (this._renderId === scene.getRenderId()) {
                    if (this._checkCache(mesh, useInstances)) {
                        return true;
                    }
                }
            }

            var needUVs: Boolean = false;
            var needNormals: Boolean = false;

            this._defines.reset();

            // Lights
            if (scene.lightsEnabled && !this.disableLighting) {
                needNormals = MaterialHelper.PrepareDefinesForLights(scene, mesh, this._defines, this.maxSimultaneousLights);
            }

            // Textures
            if (scene.texturesEnabled) {
                if (this.diffuseTexture && DiffuseTextureEnabled) {
                    if (!this.diffuseTexture.isReady()) {
                        return false;
                    } else {
                        needUVs = true;
                        this._defines.DIFFUSE = true;
                    }
                }
            }

            // Effect

            if (engine.getAlphaTesting()) {
                this._defines.ALPHATEST = true;
            }

            // Point size

            // Fog

            // Fresnel

            // Attribs
            if (mesh) {
                if (needNormals && mesh.isVerticesDataPresent(VertexBuffer.NormalKind)) {
                    this._defines.NORMAL = true;
                }

                if (needUVs) {
                    if (mesh.isVerticesDataPresent(VertexBuffer.UVKind)) {
                        this._defines.UV1 = true;
                    }
                }

                if (mesh.useVertexColors && mesh.isVerticesDataPresent(VertexBuffer.ColorKind)) {
                    this._defines.VERTEXCOLOR = true;

                    if (mesh.hasVertexAlpha) {
                        this._defines.VERTEXALPHA = true;
                    }
                }

                if (mesh.useBones && mesh.computeBonesUsingShaders) {
                    this._defines.NUM_BONE_INFLUENCERS = mesh.numBoneInfluencers;
                    this._defines.BonesPerMesh = mesh.skeleton.bones.length + 1;
                }

                // Instances
            }

            // Get correct effect
            if (!this._defines.isEqual(this._cachedDefines)) {
                this._defines.cloneTo(this._cachedDefines);

                scene.resetCachedMaterial();

                // Fallbacks

                // Attributes
                var attribs: Vector.<String> = new <String>[VertexBuffer.PositionKind];

                if (this._defines.NORMAL) {
                    attribs.push(VertexBuffer.NormalKind);
                }

                if (this._defines.UV1) {
                    attribs.push(VertexBuffer.UVKind);
                }

                if (this._defines.VERTEXCOLOR) {
                    attribs.push(VertexBuffer.ColorKind);
                }

                MaterialHelper.PrepareAttributesForBones(attribs, this._defines);

                var shaderName: String = "default";

                var join: String = this._defines.toString();
                var uniforms: Vector.<String> = new <String>["world", "viewProjection", "vEyePosition", "vSpecularColor",
                    "mBones",
                    "diffuseMatrix",
                    "depthValues",
                    "cutOff", "vertexConst0", "vertexConst1", "fragmentConst0", "fragmentConst1"];

                var samplers: Vector.<String> = new <String>["diffuseSampler"];

                MaterialHelper.PrepareUniformsAndSamplersList(uniforms, samplers, this._defines, this.maxSimultaneousLights);

                this._effect = scene.getEngine().createEffect(shaderName,
                        attribs, uniforms, samplers,
                        join, this.onCompiled, this.onError, { maxSimultaneousLights: this.maxSimultaneousLights - 1 });
            }
            if (!this._effect.isReady()) {
                return false;
            }

            this._renderId = scene.getRenderId();

            if (mesh) {
                if (!mesh._materialDefines) {
                    mesh._materialDefines = new StandardMaterialDefines();
                }

                this._defines.cloneTo(mesh._materialDefines);
            }

            return true;
        }

        override public function unbind(): void {
            super.unbind();
        }

        override public function bindOnlyWorldMatrix(world: Matrix): void {
            this._effect.setMatrix("world", world, false);
        }

        override public function bind(world: Matrix, mesh: Mesh = null): void {
            var scene: Scene = this.getScene();

            // Matrices
            this.bindOnlyWorldMatrix(world);

            // Bones
            MaterialHelper.BindBonesParameters(mesh, this._effect);

            if (scene.getCachedMaterial() !== this) {
                this._effect.setMatrix("viewProjection", scene.getTransformMatrix(), true);

                // Fresnel

                // Textures
                if (scene.texturesEnabled) {
                    if (this.diffuseTexture && DiffuseTextureEnabled) {
                        this._effect.setTexture("diffuseSampler", this.diffuseTexture);

//                        this._effect.setFloat2("vDiffuseInfos", this.diffuseTexture.coordinatesIndex, this.diffuseTexture.level);
                        this._effect.setMatrix("diffuseMatrix", this.diffuseTexture.getTextureMatrix(), true);

                        if (this._defines.ALPHATEST) {
                            this._effect.setFloat("cutOff", 0.4);
                        }
                    }
                }

                // Clip plane

                // Point size

                // Colors

                this._effect.setVector3("vEyePosition", scene.activeCamera.position);

                if (this._defines.SPECULARTERM) {
                    this._effect.setColor4("vSpecularColor", this.specularColor, this.specularPower);
                }
            }

            if (scene.getCachedMaterial() !== this || !this.isFrozen) {
                // Lights
                if (scene.lightsEnabled && !this.disableLighting) {
                    MaterialHelper.BindLights(scene, mesh, this._effect, this._defines, this.maxSimultaneousLights);
                }
            }

            this._effect.setFloat("vertexConst0", 0);
            this._effect.setFloat("vertexConst1", 1);
            this._effect.setFloat("fragmentConst0", 0);
            this._effect.setFloat("fragmentConst1", 1);

            super.bind(world, mesh);
        }

        public static function Parse(source: Object, scene: Scene, rootUrl: String): StandardMaterial {
            return SerializationHelper.Parse(function f(): Object { return new StandardMaterial(source.name, scene); }, source, scene, rootUrl) as StandardMaterial;
        }

        // Flags used to enable or disable a type of texture for all Standard Materials
        public static const DiffuseTextureEnabled: Boolean = true;
        public static const AmbientTextureEnabled: Boolean = true;
        public static const OpacityTextureEnabled: Boolean = true;
        public static const ReflectionTextureEnabled: Boolean = true;
        public static const EmissiveTextureEnabled: Boolean = true;
        public static const SpecularTextureEnabled: Boolean = true;
        public static const BumpTextureEnabled: Boolean = true;
        public static const FresnelEnabled: Boolean = true;
        public static const LightmapTextureEnabled: Boolean = true;
        public static const RefractionTextureEnabled: Boolean = true;
        public static const ColorGradingTextureEnabled: Boolean = true;
    }
}
