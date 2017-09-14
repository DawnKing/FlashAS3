/**
 * Created by caijingxiao on 2017/1/6.
 */
package babylon.postProcess {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.Camera;
    import babylon.materials.Effect;
    import babylon.materials.textures.Texture;
    import babylon.materials.textures.WebGLTexture;
    import babylon.math.Color4;
    import babylon.math.Vector2;
    import babylon.tools.Tools;
    import babylon.tools.observable.Observable;
    import babylon.tools.observable.Observer;

    public class PostProcess {
        public var width: Number = -1;
        public var height: Number = -1;
        public var renderTargetSamplingMode: Number;
        public var clearColor: Color4;

        /*
         Enable Pixel Perfect mode where texture is not scaled to be power of 2.
         Can only be used on a single postprocess or on the last one of a chain.
         */
        public var enablePixelPerfectMode: Boolean = false;

        private var _camera: Camera;
        private var _scene: Scene;
        private var _engine: Engine;
        private var _options: Object;
        private var _reusable: Boolean = false;
        private var _textureType: Number;
        public var _textures: Vector.<WebGLTexture> = new <WebGLTexture>[];
        public var _currentRenderTextureInd: int = 0;
        private var _effect: Effect;
        private var _samplers: Vector.<String>;
        private var _fragmentUrl: String;
        private var _parameters: Vector.<String>;
        private var _scaleRatio: Vector2 = new Vector2(1, 1);

        // Events

        /**
         * An event triggered when the postprocess is activated.
         */
        public var onActivateObservable: Observable = new Observable();

        private var _onActivateObserver: Observer;
        public function set onActivate(callback: Function): void {
            if (this._onActivateObserver) {
                this.onActivateObservable.remove(this._onActivateObserver);
            }
            this._onActivateObserver = this.onActivateObservable.add(callback);
        }

        /**
         * An event triggered when the postprocess changes its size.
         */
        public var onSizeChangedObservable: Observable = new Observable();

        private var _onSizeChangedObserver: Observer;
        public function set onSizeChanged(callback: Function): void {
            if (this._onSizeChangedObserver) {
                this.onSizeChangedObservable.remove(this._onSizeChangedObserver);
            }
            this._onSizeChangedObserver = this.onSizeChangedObservable.add(callback);
        }

        /**
         * An event triggered when the postprocess applies its effect.
         */
        public var onApplyObservable: Observable = new Observable();

        private var _onApplyObserver: Observer;
        public function set onApply(callback: Function): void {
            if (this._onApplyObserver) {
                this.onApplyObservable.remove(this._onApplyObserver);
            }
            this._onApplyObserver = this.onApplyObservable.add(callback);
        }

        /**
         * An event triggered before rendering the postprocess
         */
        public var onBeforeRenderObservable: Observable = new Observable();

        private var _onBeforeRenderObserver: Observer;
        public function set onBeforeRender(callback: Function): void {
            if (this._onBeforeRenderObserver) {
                this.onBeforeRenderObservable.remove(this._onBeforeRenderObserver);
            }
            this._onBeforeRenderObserver = this.onBeforeRenderObservable.add(callback);
        }

        /**
         * An event triggered after rendering the postprocess
         */
        public var onAfterRenderObservable: Observable = new Observable();

        private var _onAfterRenderObserver: Observer;
        public function set onAfterRender(callback: Function): void {
            if (this._onAfterRenderObserver) {
                this.onAfterRenderObservable.remove(this._onAfterRenderObserver);
            }
            this._onAfterRenderObserver = this.onAfterRenderObservable.add(callback);
        }

        public var name: String;


        public function PostProcess(name: String, fragmentUrl: String, parameters: Vector.<String>, samplers: Vector.<String>, options: Object, camera: Camera, samplingMode: Number = Texture.NEAREST_SAMPLINGMODE, engine: Engine = null, reusable: Boolean = false, defines: String = null, textureType: Number = Engine.TEXTURETYPE_UNSIGNED_INT) {
            this.name = name;

            if (camera != null) {
                this._camera = camera;
                this._scene = camera.getScene();
                camera.attachPostProcess(this);
                this._engine = this._scene.getEngine();
            }
            else {
                this._engine = engine;
            }

            this._options = options;
            this.renderTargetSamplingMode = samplingMode ? samplingMode : Texture.NEAREST_SAMPLINGMODE;
            this._reusable = reusable || false;
            this._textureType = textureType;

            this._samplers = samplers || new <String>[];
            this._samplers.push("textureSampler");

            this._fragmentUrl = fragmentUrl;
            this._parameters = parameters || new <String>[];

            this._parameters.push("scale");

            this.updateEffect(defines);
        }

        public function updateEffect(defines: String = null): void {
            this._effect = this._engine.createEffect({ vertex: "postprocess", fragment: this._fragmentUrl },
                    new <String>["position"],
                    this._parameters,
                    this._samplers, defines !== null ? defines : "");
        }

        public function isReusable(): Boolean {
            return this._reusable;
        }

        /** invalidate frameBuffer to hint the postprocess to create a depth buffer */
        public function markTextureDirty() : void{
            this.width = -1;
        }

        public function activate(camera: Camera, sourceTexture: WebGLTexture = null): void {
            camera = camera || this._camera;

            var scene: Scene = camera.getScene();
            var maxSize: Number = camera.getEngine().getCaps().maxTextureSize;

            var requiredWidth: Number = ((sourceTexture ? sourceTexture._width : this._engine.getRenderingCanvas().width) * Number(this._options)) | 0;
            var requiredHeight: Number = ((sourceTexture ? sourceTexture._height : this._engine.getRenderingCanvas().height) * Number(this._options)) | 0;

            var desiredWidth: Number = (this._options).width || requiredWidth;
            var desiredHeight: Number = (this._options).height || requiredHeight;

            if (this.renderTargetSamplingMode !== Texture.NEAREST_SAMPLINGMODE) {
                if (!(this._options).width) {
                    desiredWidth = Tools.GetExponentOfTwo(desiredWidth, maxSize);
                }

                if (!(this._options).height) {
                    desiredHeight = Tools.GetExponentOfTwo(desiredHeight, maxSize);
                }
            }

            if (this.width !== desiredWidth || this.height !== desiredHeight) {
                if (this._textures.length > 0) {
                    for (var i: int = 0; i < this._textures.length; i++) {
                        this._engine._releaseTexture(this._textures[i]);
                    }
                    this._textures.length = 0;
                }
                this.width = desiredWidth;
                this.height = desiredHeight;

                var textureSize: Object = { width: this.width, height: this.height };
                var textureOptions: Object = {
                    generateMipMaps: false,
                    generateDepthBuffer: camera._postProcesses.indexOf(this) === 0,
                    generateStencilBuffer: camera._postProcesses.indexOf(this) === 0 && this._engine.isStencilEnable,
                    samplingMode: this.renderTargetSamplingMode,
                    type: this._textureType
                };

                this._textures.push(this._engine.createRenderTargetTexture(textureSize, textureOptions));

                if (this._reusable) {
                    this._textures.push(this._engine.createRenderTargetTexture(textureSize, textureOptions));
                }

                this.onSizeChangedObservable.notifyObservers(this);
            }

//            if (this.enablePixelPerfectMode) {
//                this._scaleRatio.copyFromFloats(requiredWidth / desiredWidth, requiredHeight / desiredHeight);
//                this._engine.bindFramebuffer(this._textures[this._currentRenderTextureInd], 0, requiredWidth, requiredHeight);
//            }
//            else {
//                this._scaleRatio.copyFromFloats(1, 1);
//                this._engine.bindFramebuffer(this._textures[this._currentRenderTextureInd]);
//            }

            this.onActivateObservable.notifyObservers(camera);

            // Clear
            if (this.clearColor) {
                this._engine.clear(this.clearColor, true, true, true);
            } else {
                this._engine.clear(scene.clearColor, scene.autoClear || scene.forceWireframe, true, true);
            }

            if (this._reusable) {
                this._currentRenderTextureInd = (this._currentRenderTextureInd + 1) % 2;
            }
        }

        public function get isSupported(): Boolean {
            return this._effect.isSupported;
        }

        public function apply(): Effect {
            // Check
            if (!this._effect.isReady())
                return null;

            // States
            this._engine.enableEffect(this._effect);
            this._engine.setState(false);
            this._engine.setAlphaMode(Engine.ALPHA_DISABLE);
            this._engine.setDepthBuffer(false);
            this._engine.setDepthWrite(false);

            // Texture
            this._effect._bindTexture("textureSampler", this._textures[this._currentRenderTextureInd]);

            // Parameters
            this._effect.setVector2("scale", this._scaleRatio);
            this.onApplyObservable.notifyObservers(this._effect);

            return this._effect;
        }

        public function dispose(camera: Camera = null): void {
            camera = camera || this._camera;

            if (this._textures.length > 0) {
                for (var i: int = 0; i < this._textures.length; i++) {
                    this._engine._releaseTexture(this._textures[i]);
                }
                this._textures.length = 0;
            }

            if (!camera) {
                return;
            }
            camera.detachPostProcess(this);

            var index: int = camera._postProcesses.indexOf(this);
            if (index === 0 && camera._postProcesses.length > 0) {
                this._camera._postProcesses[0].markTextureDirty();
            }

            this.onActivateObservable.clear();
            this.onAfterRenderObservable.clear();
            this.onApplyObservable.clear();
            this.onBeforeRenderObservable.clear();
            this.onSizeChangedObservable.clear();
        }
    }
}
