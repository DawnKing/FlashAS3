/**
 * Created by caijingxiao on 2016/12/7.
 */
package babylon.materials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.textures.BaseTexture;
    import babylon.math.Matrix;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;
    import babylon.mesh.VertexBuffer;

    public class TextureMaterial extends Material {
        public var diffuseTexture: BaseTexture;

        private var _defines: TextureMaterialDefines = new TextureMaterialDefines();
        private var _cachedDefines: TextureMaterialDefines = new TextureMaterialDefines();

        public function TextureMaterial(name: String, scene: Scene, doNotAdd: Boolean = false) {
            super(name, scene, doNotAdd);
        }

        override public function needAlphaBlending(): Boolean {
            return (this.alpha < 1.0);
        }

        override public function needAlphaTesting(): Boolean {
            return this.diffuseTexture != null && this.diffuseTexture.hasAlpha;
        }

        override public function isReady(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {//273
            var scene: Scene = this.getScene();
            var engine: Engine = scene.getEngine();


            this._defines.reset();

            // Textures
            if (scene.texturesEnabled) {
                if (this.diffuseTexture) {
                    if (!this.diffuseTexture.isReady()) {
                        return false;
                    }
                }
            }

            // Effect
            if (engine.getAlphaTesting()) {
                this._defines.ALPHATEST = true;
            }

            // Attribs
            if (mesh) {
                if (mesh.useVertexColors && mesh.isVerticesDataPresent(VertexBuffer.ColorKind)) {
                    this._defines.VERTEXCOLOR = true;

                    if (mesh.hasVertexAlpha) {
                        this._defines.VERTEXALPHA = true;
                    }
                }
            }

            // Get correct effect
            if (!this._defines.isEqual(this._cachedDefines)) {
                this._defines.cloneTo(this._cachedDefines);

                scene.resetCachedMaterial();

                // Attributes
                var attribs: Vector.<String> = new <String>[VertexBuffer.PositionKind, VertexBuffer.UVKind];

                if (this._defines.VERTEXCOLOR) {
                    attribs.push(VertexBuffer.ColorKind);
                }

                var shaderName: String = "texture";

                var join: String = this._defines.toString();
                var uniforms: Vector.<String> = new <String>["world", "viewProjection",
                    "diffuseMatrix",
                    "cutOff", "vertexConst0", "vertexConst1", "constantsOffset"];

                var samplers: Vector.<String> = new <String>["diffuseSampler"];

                this._effect = scene.getEngine().createEffect(shaderName,
                        attribs, uniforms, samplers,
                        join, this.onCompiled, this.onError);
            }
            if (!this._effect.isReady()) {
                return false;
            }

            if (mesh) {
                if (!mesh._materialDefines) {
                    mesh._materialDefines = new TextureMaterialDefines();
                }

                this._defines.cloneTo(mesh._materialDefines);
            }

            return true;
        }

        override public function bindOnlyWorldMatrix(world: Matrix): void {
            this._effect.setMatrix("world", world, false);

//            var scene: Scene = this.getScene();
//            this._effect.setMatrix("world", world.multiply(scene.getTransformMatrix()), true);
        }

        override public function bind(world: Matrix, mesh: Mesh = null): void {
            var scene: Scene = this.getScene();

            // Matrices
            this.bindOnlyWorldMatrix(world);

            this._effect.setMatrix("viewProjection", scene.getTransformMatrix(), true);

            // Textures
            if (scene.texturesEnabled && this.diffuseTexture) {
                this._effect.setFloat("vertexConst0", 0);
                this._effect.setFloat("vertexConst1", 1);
                this._effect.setMatrix("diffuseMatrix", this.diffuseTexture.getTextureMatrix(), true);

                this._effect.setTexture("diffuseSampler", this.diffuseTexture);

                if (this._defines.ALPHATEST) {
                    this._effect.setFloat("cutOff", 0.4);
                }
            }

            super.bind(world, mesh);
        }
    }
}
