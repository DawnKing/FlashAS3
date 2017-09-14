/**
 * Created by caijingxiao on 2016/11/9.
 */
package babylon.materials.textures {
    import babylon.Scene;
    import babylon.math.Matrix;

    import easiest.unit.Assert;

    public class BaseTexture {
        public var name: String;
        public var hasAlpha: Boolean = false;
        public var getAlphaFromRGB: Boolean = false;
        public var level: int = 1;
        public var coordinatesIndex: int = 0;
        public var coordinatesMode: int = Texture.EXPLICIT_MODE;
        public var wrapU: int = Texture.WRAP_ADDRESSMODE;
        public var wrapV: int = Texture.WRAP_ADDRESSMODE;
        public var anisotropicFilteringLevel: int = 4;
        public var isRenderTarget: Boolean = false;

        private var _scene: Scene;
        public var _texture: WebGLTexture;

        public var scale:Number = 1;

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

        public function get width():int
        {
            return _texture._width;
        }

        public function get height():int
        {
            return _texture._height;
        }

        public function releaseInternalTexture(): void {
            if (this._texture) {
                Assert.fail();
//                this._scene.getEngine().releaseInternalTexture(this._texture);
//                this._texture.dispose();
            }
        }

        public function dispose(): void {
            Assert.fail();
            // Animations
//            this.getScene().stopAnimation(this);

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
            Assert.fail();
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
