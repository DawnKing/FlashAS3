/**
 * Created by caijingxiao on 2016/11/10.
 */
package babylon.materials.textures {
    import flash.display.BitmapData;
    import flash.display3D.textures.TextureBase;

    public class WebGLTexture {
        public var bitmapData: BitmapData;
        public var flashTexture: TextureBase;
        public var generateMipMaps: Boolean;
        public var enableDepthAndStencil: Boolean;
        public var isReady: Boolean = false;

        private var _w: Number;
        private var _h: Number;

        public function get _width(): Number {
            return this.bitmapData ? this.bitmapData.width : this._w;
        }

        public function set _width(value: Number): void {
            this._w = value;
        }

        public function get _height(): Number {
            return this.bitmapData ? this.bitmapData.height : this._h;
        }

        public function set _height(value: Number): void {
            this._h = value;
        }
    }
}
