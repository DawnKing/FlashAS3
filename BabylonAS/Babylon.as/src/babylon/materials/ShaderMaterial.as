/**
 * Created by caijingxiao on 2016/10/27.
 */
package babylon.materials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;

    import flash.utils.Dictionary;

    public class ShaderMaterial extends Material {
        private var _shaderPath: String;
        private var _options: Object;

        private var _colors4: Dictionary = new Dictionary(true);    // name - Color4

        private var _cachedWorldViewMatrix: Matrix = new Matrix();
        private var _renderId: int;

        public function ShaderMaterial(name: String, scene: Scene, shaderPath:String, options: Object) {
            super(name, scene);
            this._shaderPath = shaderPath;

            options.needAlphaBlending = options.needAlphaBlending || false;
            options.needAlphaTesting = options.needAlphaTesting || false;
            options.attributes = options.attributes || new <String>["position", "normal", "uv"];
            options.uniforms = options.uniforms || new <String>["worldViewProjection"];
            options.samplers = options.samplers || new <String>[];
            options.defines = options.defines || new <String>[];

            this._options = options;
        }


        override public function needAlphaBlending(): Boolean {//34
            return this._options.needAlphaBlending;
        }

        override public function needAlphaTesting(): Boolean {//38
            return this._options.needAlphaTesting;
        }

        private function _checkUniform(uniformName: String): void {//42
            if (this._options.uniforms.indexOf(uniformName) == -1) {
                this._options.uniforms.push(uniformName);
            }
        }

        public function setColor4(name: String, value: Color4): ShaderMaterial {//90
            this._checkUniform(name);
            this._colors4[name] = value;

            return this;
        }

        override public function isReady(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {//139
            var scene: Scene = this.getScene();
            var engine: Engine = scene.getEngine();

            if (!this.checkReadyOnEveryCall) {
                if (this._renderId == scene.getRenderId()) {
                    return true;
                }
            }

            // Instances
            var defines: Vector.<String> = new <String>[];

            var previousEffect: Effect = this._effect;
            var join: String = defines.join("\n");

            this._effect = engine.createEffect(this._shaderPath,
                this._options.attributes,
                this._options.uniforms,
                this._options.samplers,
                join, this.onCompiled, this.onError);

            if (!this._effect.isReady()) {
                return false;
            }

            if (previousEffect != this._effect) {
                scene.resetCachedMaterial();
            }

            this._renderId = scene.getRenderId();

            return true;
        }

        override public function bindOnlyWorldMatrix(world: Matrix): void {//194
            var scene: Scene = this.getScene();

            if (this._options.uniforms.indexOf("world") != -1) {
                this._effect.setMatrix("world", world, true);
            }

            if (this._options.uniforms.indexOf("worldView") != -1) {
                world.multiplyToRef(scene.getViewMatrix(), this._cachedWorldViewMatrix);
                this._effect.setMatrix("worldView", this._cachedWorldViewMatrix, true);
            }

            if (this._options.uniforms.indexOf("worldViewProjection") != -1) {
                this._effect.setMatrix("worldViewProjection", world.multiply(scene.getTransformMatrix()), true);
            }
        }

        override public function bind(world: Matrix, mesh: Mesh = null): void {
            // Std values
            this.bindOnlyWorldMatrix(world);

            if (this.getScene().getCachedMaterial() != this) {
                if (this._options.uniforms.indexOf("view") != -1) {
                    this._effect.setMatrix("view", this.getScene().getViewMatrix(), true);
                }

                if (this._options.uniforms.indexOf("projection") != -1) {
                    this._effect.setMatrix("projection", this.getScene().getProjectionMatrix(), true);
                }

                if (this._options.uniforms.indexOf("viewProjection") != -1) {
                    this._effect.setMatrix("viewProjection", this.getScene().getTransformMatrix(), true);
                }

                // Bones

                var name: String;
                // Texture

                // Texture arrays

                // Float

                // Float s

                // Color3

                // Color4
                for (name in this._colors4) {
                    var color: Color4 = this._colors4[name];
                    this._effect.setFloat4(name, color.r, color.g, color.b, color.a);
                }

                // Vector2

                // Vector3

                // Vector4

                // Matrix

                // Matrix 3x3

                // Matrix 2x2
            }

            super.bind(world, mesh);
        }
    }
}
