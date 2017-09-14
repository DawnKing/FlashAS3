/**
 * Created by caijingxiao on 2016/11/9.
 */
package babylon.materials.textures {
    import babylon.Scene;
    import babylon.animations.Animation;
    import babylon.math.Matrix;
    import babylon.math.Size;
    import babylon.tools.SerializationHelper;

    import easiest.unit.asserts.fail;

    public class BaseTexture {
        [Serialize]
        public var name: String;
        [Serialize]
        public var hasAlpha: Boolean = false;
        [Serialize]
        public var getAlphaFromRGB: Boolean = false;
        [Serialize]
        public var level: int = 1;
        [Serialize]
        public var coordinatesIndex: int = 0;
        [Serialize]
        public var coordinatesMode: int = Texture.EXPLICIT_MODE;
        [Serialize]
        public var wrapU: int = Texture.WRAP_ADDRESSMODE;
        [Serialize]
        public var wrapV: int = Texture.WRAP_ADDRESSMODE;
        [Serialize]
        public var anisotropicFilteringLevel: int = 4;
        [Serialize]
        public var isRenderTarget: Boolean = false;

        private var _scene: Scene;
        public var _texture: WebGLTexture;

        public function BaseTexture(scene: Scene) {
            this._scene = scene;
            this._scene.textures.push(this);
        }

        public function getScene(): Scene {
            return this._scene;
        }

        public function getTextureMatrix(): Matrix {
            return null;
        }

        public function getInternalTexture(): WebGLTexture {
            return this._texture;
        }

        public function isReady(): Boolean {
            if (this._texture.flashTexture) {
                return true;
            }

            return false;
        }

        public function getSize(): Size {
            if (this._texture._width) {
                return new Size(this._texture._width, this._texture._height);
            }

            return Size.Zero();
        }

        public function releaseInternalTexture(): void {
            if (this._texture) {
                fail();
//                this._scene.getEngine().releaseInternalTexture(this._texture);
//                this._texture.dispose();
            }
        }

        public function dispose(): void {
            // Animations
            this.getScene().stopAnimation(this);

            // Remove from scene
            var index: int = this._scene.textures.indexOf(this);

            if (index >= 0) {
                this._scene.textures.splice(index, 1);
            }

            if (this._texture == null) {
                return;
            }

            // Release
            this.releaseInternalTexture();

            // Callback
        }

        public function serialize(): Object {
            fail();
            return null;
//            if (!this.name) {
//                return null;
//            }
//
//            var serializationObject: Object = SerializationHelper.Serialize(this);
//
//            // Animations
//            Animation.AppendSerializedAnimations(this, serializationObject);
//
//            return serializationObject;
        }
    }
}
