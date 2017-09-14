/**
 * Created by caijingxiao on 2016/10/14.
 */
package babylon.materials {
    import babylon.Engine;
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.textures.BaseTexture;
    import babylon.math.Matrix;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;

    public class Material {
        public static const TriangleFillMode: int = 0;
        public static const WireFrameFillMode: int = 1;
        public static const PointFillMode: int = 2;
        public static const ClockWiseSideOrientation: int = 0;
        public static const CounterClockWiseSideOrientation: int = 1;

        [Serialize]
        public var id: String;

        [Serialize]
        public var name: String;

        [Serialize]
        public var checkReadyOnEveryCall: Boolean = false;

        [Serialize]
        public var checkReadyOnlyOnce: Boolean = false;

        [Serialize]
        public var alpha: Number = 1.0;
        [Serialize]
        public var backFaceCulling: Boolean = true;
        [Serialize]
        public var sideOrientation: Number;

        public var onCompiled: Function; // function(effect: Effect): void
        public var onError: Function;   // function(effect: Effect, errors: String): void
        public var getRenderTargetTextures: Function;   // function(): Vector.<RenderTargetTexture>

        [Serialize]
        public var alphaMode: int = Engine.ALPHA_COMBINE;

        [Serialize]
        public var zOffset: Number = 0;

        public var _effect: Effect;

        private var _scene: Scene;
        public var fillMode: int = TriangleFillMode;

        public function Material(name: String, scene: Scene, doNotAdd: Boolean = false) {
            this.id = name;

            this._scene = scene;

            this.sideOrientation = CounterClockWiseSideOrientation;

            if (!doNotAdd) {
                scene.materials.push(this);
            }
        }

        public function toString(fullDetails: Boolean = false): String {
            var ret: String = "Name: " + this.name;
            if (fullDetails){
            }
            return ret;
        }

        public function get isFrozen(): Boolean {
            return this.checkReadyOnlyOnce;
        }

        public function isReady(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {//246
            return true;
        }

        public function getEffect(): Effect {//250
            return this._effect;
        }

        public function getScene(): Scene {
            return this._scene;
        }

        public function needAlphaBlending(): Boolean {
            return (this.alpha < 1.0);
        }

        public function needAlphaTesting(): Boolean {//262
            return false;
        }

        public function getAlphaTestTexture(): BaseTexture {
            return null;
        }

        public function _preBind(): void {//274
            var engine: Engine = this._scene.getEngine();

            var reverse: Boolean = this.sideOrientation === ClockWiseSideOrientation;

            engine.enableEffect(this._effect);
            engine.setState(this.backFaceCulling, this.zOffset, false, reverse);
        }

        public function bind(world: Matrix, mesh: Mesh = null): void {//283
            this._scene._cachedMaterial = this;
        }

        public function bindOnlyWorldMatrix(world: Matrix): void {//295
        }

        public function unbind(): void {//298
            var engine: Engine = this._scene.getEngine();
            engine.resetTextureCache();
        }

        public static function ParseMultiMaterial(parsedMultiMaterial: Object, scene: Scene): Material {
            var multiMaterial: MultiMaterial = new MultiMaterial(parsedMultiMaterial.name, scene);

            multiMaterial.id = parsedMultiMaterial.id;

            for (var matIndex: int = 0; matIndex < parsedMultiMaterial.materials.length; matIndex++) {
                var subMatId: String = parsedMultiMaterial.materials[matIndex];

                if (subMatId) {
                    multiMaterial.subMaterials.push(scene.getMaterialByID(subMatId));
                } else {
                    multiMaterial.subMaterials.push(null);
                }
            }

            return multiMaterial;
        }

        public static function Parse(parsedMaterial: Object, scene: Scene, rootUrl: String): Material {
            if (!parsedMaterial.customType) {
                return StandardMaterial.Parse(parsedMaterial, scene, rootUrl);
            }

            throw new Error();
        }
    }
}
