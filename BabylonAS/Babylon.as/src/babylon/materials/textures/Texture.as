/**
 * Created by caijingxiao on 2016/11/10.
 */
package babylon.materials.textures {
    import babylon.Scene;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.tools.SerializationHelper;

    public class Texture extends BaseTexture {
        // Constants
        public static const NEAREST_SAMPLINGMODE: int = 1;
        public static const BILINEAR_SAMPLINGMODE: int = 2;
        public static const TRILINEAR_SAMPLINGMODE: int = 3;

        public static const EXPLICIT_MODE: int = 0;
        public static const SPHERICAL_MODE: int = 1;
        public static const PLANAR_MODE: int = 2;
        public static const CUBIC_MODE: int = 3;
        public static const PROJECTION_MODE: int = 4;
        public static const SKYBOX_MODE: int = 5;
        public static const INVCUBIC_MODE: int = 6;
        public static const EQUIRECTANGULAR_MODE: int = 7;
        public static const FIXED_EQUIRECTANGULAR_MODE: int = 8;

        public static const CLAMP_ADDRESSMODE: int = 0;
        public static const WRAP_ADDRESSMODE: int = 1;
        public static const MIRROR_ADDRESSMODE: int = 2;

        // Members
        [Serialize]
        public var url: String;

        [Serialize]
        public var uOffset: Number = 0;

        [Serialize]
        public var vOffset: Number = 0;

        [Serialize]
        public var uScale: Number = 1.0;

        [Serialize]
        public var vScale: Number = 1.0;

        [Serialize]
        public var uAng: Number = 0;

        [Serialize]
        public var vAng: Number = 0;

        [Serialize]
        public var wAng: Number = 0;

        public function get noMipmap(): Boolean {
            return this._noMipmap;
        }

        private var _noMipmap: Boolean;
        public var _invertY: Boolean;
        private var _rowGenerationMatrix: Matrix;
        private var _cachedTextureMatrix: Matrix;
        private var _projectionModeMatrix: Matrix;
        private var _t0: Vector3;
        private var _t1: Vector3;
        private var _t2: Vector3;

        private var _cachedUOffset: Number;
        private var _cachedVOffset: Number;
        private var _cachedUScale: Number;
        private var _cachedVScale: Number;
        private var _cachedUAng: Number;
        private var _cachedVAng: Number;
        private var _cachedWAng: Number;
        private var _cachedCoordinatesMode: Number;
        public var _samplingMode: Number;
//        private var _buffer: Object;
//        private var _deleteBuffer: Boolean;
//        private var _delayedOnLoad: Function;
//        private var _delayedOnError: Function;
//        private var _onLoadObservarble: Observable;

        public function Texture(url: String, scene: Scene, noMipmap: Boolean = false) {
            super(scene);

            this.url = url;
            this._noMipmap = noMipmap;

            if (!url) {
                return;
            }

            this._texture = scene.getEngine().createTexture(url);
        }


        public function updateSamplingMode(samplingMode: int): void {
            if (!this._texture) {
                return;
            }

            this._samplingMode = samplingMode;
            this.getScene().getEngine().updateTextureSamplingMode(samplingMode, this._texture);
        }

        private function _prepareRowForTextureGeneration(x: Number, y: Number, z: Number, t: Vector3): void {
            x *= this.uScale;
            y *= this.vScale;

            x -= 0.5 * this.uScale;
            y -= 0.5 * this.vScale;
            z -= 0.5;

            Vector3.TransformCoordinatesFromFloatsToRef(x, y, z, this._rowGenerationMatrix, t);

            t.x += 0.5 * this.uScale + this.uOffset;
            t.y += 0.5 * this.vScale + this.vOffset;
            t.z += 0.5;
        }

        override public function getTextureMatrix(): Matrix {
            if (
                    this.uOffset === this._cachedUOffset &&
                    this.vOffset === this._cachedVOffset &&
                    this.uScale === this._cachedUScale &&
                    this.vScale === this._cachedVScale &&
                    this.uAng === this._cachedUAng &&
                    this.vAng === this._cachedVAng &&
                    this.wAng === this._cachedWAng) {
                return this._cachedTextureMatrix;
            }

            this._cachedUOffset = this.uOffset;
            this._cachedVOffset = this.vOffset;
            this._cachedUScale = this.uScale;
            this._cachedVScale = this.vScale;
            this._cachedUAng = this.uAng;
            this._cachedVAng = this.vAng;
            this._cachedWAng = this.wAng;

            if (!this._cachedTextureMatrix) {
                this._cachedTextureMatrix = Matrix.Zero();
                this._rowGenerationMatrix = new Matrix();
                this._t0 = Vector3.Zero();
                this._t1 = Vector3.Zero();
                this._t2 = Vector3.Zero();
            }

            Matrix.RotationYawPitchRollToRef(this.vAng, this.uAng, this.wAng, this._rowGenerationMatrix);

            this._prepareRowForTextureGeneration(0, 0, 0, this._t0);
            this._prepareRowForTextureGeneration(1.0, 0, 0, this._t1);
            this._prepareRowForTextureGeneration(0, 1.0, 0, this._t2);

            this._t1.subtractInPlace(this._t0);
            this._t2.subtractInPlace(this._t0);

            Matrix.IdentityToRef(this._cachedTextureMatrix);
            this._cachedTextureMatrix.m[0] = this._t1.x; this._cachedTextureMatrix.m[1] = this._t1.y; this._cachedTextureMatrix.m[2] = this._t1.z;
            this._cachedTextureMatrix.m[4] = this._t2.x; this._cachedTextureMatrix.m[5] = this._t2.y; this._cachedTextureMatrix.m[6] = this._t2.z;
            this._cachedTextureMatrix.m[8] = this._t0.x; this._cachedTextureMatrix.m[9] = this._t0.y; this._cachedTextureMatrix.m[10] = this._t0.z;

            return this._cachedTextureMatrix;
        }

        public function getReflectionTextureMatrix(): Matrix {
            if (
                    this.uOffset === this._cachedUOffset &&
                    this.vOffset === this._cachedVOffset &&
                    this.uScale === this._cachedUScale &&
                    this.vScale === this._cachedVScale &&
                    this.coordinatesMode === this._cachedCoordinatesMode) {
                return this._cachedTextureMatrix;
            }

            if (!this._cachedTextureMatrix) {
                this._cachedTextureMatrix = Matrix.Zero();
                this._projectionModeMatrix = Matrix.Zero();
            }

            this._cachedCoordinatesMode = this.coordinatesMode;

            switch (this.coordinatesMode) {
                case Texture.PLANAR_MODE:
                    Matrix.IdentityToRef(this._cachedTextureMatrix);
                    this._cachedTextureMatrix[0] = this.uScale;
                    this._cachedTextureMatrix[5] = this.vScale;
                    this._cachedTextureMatrix[12] = this.uOffset;
                    this._cachedTextureMatrix[13] = this.vOffset;
                    break;
                case Texture.PROJECTION_MODE:
                    Matrix.IdentityToRef(this._projectionModeMatrix);

                    this._projectionModeMatrix.m[0] = 0.5;
                    this._projectionModeMatrix.m[5] = -0.5;
                    this._projectionModeMatrix.m[10] = 0.0;
                    this._projectionModeMatrix.m[12] = 0.5;
                    this._projectionModeMatrix.m[13] = 0.5;
                    this._projectionModeMatrix.m[14] = 1.0;
                    this._projectionModeMatrix.m[15] = 1.0;

                    this.getScene().getProjectionMatrix().multiplyToRef(this._projectionModeMatrix, this._cachedTextureMatrix);
                    break;
                default:
                    Matrix.IdentityToRef(this._cachedTextureMatrix);
                    break;
            }
            return this._cachedTextureMatrix;
        }

        public static function Parse(parsedTexture: Object, scene: Scene, rootUrl: String): BaseTexture {
            var texture: Object = SerializationHelper.Parse(function f(): Object {
                return new Texture(rootUrl + parsedTexture.name, scene);
            }, parsedTexture, scene);

            return texture as BaseTexture;
        }
    }
}
