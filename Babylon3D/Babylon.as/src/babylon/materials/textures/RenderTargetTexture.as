/**
 * Created by caijingxiao on 2017/1/9.
 */
package babylon.materials.textures {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.Camera;
    import babylon.math.Matrix;
    import babylon.math.Size;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.SubMesh;
    import babylon.rendering.RenderingManager;
    import babylon.tools.observable.Observable;
    import babylon.tools.observable.Observer;

    public class RenderTargetTexture extends Texture {

        public static const REFRESHRATE_RENDER_ONCE: int = 0;
        public static const REFRESHRATE_RENDER_ONEVERYFRAME: int = 1;
        public static const REFRESHRATE_RENDER_ONEVERYTWOFRAMES: int = 2;

        /**
         * Use this predicate to dynamically define the list of mesh you want to render.
         * If set, the renderList property will be overwritten.
         */
        public var renderListPredicate: Function;   // (AbstractMesh: AbstractMesh) => Boolean;

        /**
         * Use this list to define the list of mesh you want to render.
         */
        public var renderList: Vector.<AbstractMesh> = new <AbstractMesh>[];
        public var renderParticles: Boolean = true;
        public var renderSprites: Boolean = false;
        public var activeCamera: Camera;
        public var customRenderFunction: Function;  // (opaqueSubMeshes: SmartArray<SubMesh>, transparentSubMeshes: SmartArray<SubMesh>, alphaTestSubMeshes: SmartArray<SubMesh>, beforeTransparents?: () => void) => void;
        public var useCameraPostProcesses: Boolean;

        // Events

        /**
         * An event triggered when the texture is unbind.
         */
        public var onAfterUnbindObservable: Observable = new Observable();

        private var _onAfterUnbindObserver: Observer;
        public function set onAfterUnbind(callback: Function): void {
            if (this._onAfterUnbindObserver) {
                this.onAfterUnbindObservable.remove(this._onAfterUnbindObserver);
            }
            this._onAfterUnbindObserver = this.onAfterUnbindObservable.add(callback);
        }

        /**
         * An event triggered before rendering the texture
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
         * An event triggered after rendering the texture
         */
        public var onAfterRenderObservable: Observable = new Observable;

        private var _onAfterRenderObserver: Observer;
        public function set onAfterRender(callback: Function): void {
            if (this._onAfterRenderObserver) {
                this.onAfterRenderObservable.remove(this._onAfterRenderObserver);
            }
            this._onAfterRenderObserver = this.onAfterRenderObservable.add(callback);
        }

        /**
         * An event triggered after the texture clear
         */
        public var onClearObservable: Observable = new Observable();

        private var _onClearObserver: Observer;
        public function set onClear(callback: Function): void {
            if (this._onClearObserver) {
                this.onClearObservable.remove(this._onClearObserver);
            }
            this._onClearObserver = this.onClearObservable.add(callback);
        }

        private var _size: Number;
        public var _generateMipMaps: Boolean;
        private var _renderingManager: RenderingManager;
        public var _waitingRenderList: Vector.<String>;
        private var _doNotChangeAspectRatio: Boolean;
        private var _currentRefreshId: int = -1;
        private var _refreshRate: int = 1;
        private var _textureMatrix: Matrix;
        protected var _renderTargetOptions: Object = {
            generateMipMaps: Boolean,
            type: Number,
            samplingMode: Number,
            generateDepthBuffer: Boolean,
            generateStencilBuffer: Boolean
        };

        public var isCube: Boolean = false;

        public function RenderTargetTexture(name: String, size: Number, scene: Scene, generateMipMaps: Boolean = false, doNotChangeAspectRatio: Boolean = true, type: Number = Engine.TEXTURETYPE_UNSIGNED_INT, isCube: Boolean = false, samplingMode: int = Texture.TRILINEAR_SAMPLINGMODE, generateDepthBuffer: Boolean = true, generateStencilBuffer: Boolean = false) {
            super(null, scene, !generateMipMaps);

            coordinatesMode = PROJECTION_MODE;

            this.isCube = isCube;

            this.name = name;
            this.isRenderTarget = true;
            this._size = size;
            this._generateMipMaps = generateMipMaps;
            this._doNotChangeAspectRatio = doNotChangeAspectRatio;

            this._renderTargetOptions = {
                generateMipMaps: generateMipMaps,
                type: type,
                samplingMode: samplingMode,
                generateDepthBuffer: generateDepthBuffer,
                generateStencilBuffer: generateStencilBuffer
            };

            if (samplingMode === Texture.NEAREST_SAMPLINGMODE) {
                this.wrapU = Texture.CLAMP_ADDRESSMODE;
                this.wrapV = Texture.CLAMP_ADDRESSMODE;
            }

            if (isCube) {
                this._texture = scene.getEngine().createRenderTargetCubeTexture(size, this._renderTargetOptions);
                this.coordinatesMode = Texture.INVCUBIC_MODE;
                this._textureMatrix = Matrix.Identity();
            } else {
                this._texture = scene.getEngine().createRenderTargetTexture(size, this._renderTargetOptions);
            }

            // Rendering groups
            this._renderingManager = new RenderingManager(scene);
        }

        public function resetRefreshCounter(): void {
            this._currentRefreshId = -1;
        }

        public function get refreshRate(): Number {
            return this._refreshRate;
        }

        // Use 0 to render just once, 1 to render on every frame, 2 to render every two frames and so on...
        public function set refreshRate(value: Number): void {
            this._refreshRate = value;
            this.resetRefreshCounter();
        }

        public function _shouldRender(): Boolean {
            if (this._currentRefreshId === -1) { // At least render once
                this._currentRefreshId = 1;
                return true;
            }

            if (this.refreshRate === this._currentRefreshId) {
                this._currentRefreshId = 1;
                return true;
            }

            this._currentRefreshId++;
            return false;
        }

        override public function isReady(): Boolean {
            if (!this.getScene().renderTargetsEnabled) {
                return false;
            }
            return super.isReady();
        }

        public function getRenderSize(): Number {
            return this._size;
        }

        public function get canRescale(): Boolean {
            return true;
        }

        public function scale(ratio: Number): void {
            var newSize: Number = this._size * ratio;

            this.resize(newSize);
        }

        override public function getReflectionTextureMatrix(): Matrix {
            if (this.isCube) {
                return this._textureMatrix;
            }

            return super.getReflectionTextureMatrix();
        }

        public function resize(size: Object): void {
            this.releaseInternalTexture();
            if (this.isCube) {
                this._texture = this.getScene().getEngine().createRenderTargetCubeTexture(Number(size), this._renderTargetOptions);
            } else {
                this._texture = this.getScene().getEngine().createRenderTargetTexture(size, this._renderTargetOptions);
            }
        }

        public function render(useCameraPostProcess: Boolean = false, dumpForDebug: Boolean = false): void {
            var scene: Scene = this.getScene();
            var engine: Engine = scene.getEngine();

            if (this.useCameraPostProcesses !== false) {
                useCameraPostProcess = this.useCameraPostProcesses;
            }

            if (this._waitingRenderList) {
                this.renderList = new <AbstractMesh>[];
                for (var index: int = 0; index < this._waitingRenderList.length; index++) {
                    var id: String = this._waitingRenderList[index];
                    this.renderList.push(scene.getMeshByID(id));
                }

                this._waitingRenderList = null;
            }

            // Is predicate defined?
            if (this.renderListPredicate) {
                this.renderList.length = 0; // Clear previous renderList

                var sceneMeshes: Vector.<AbstractMesh> = this.getScene().meshes;

                for (index = 0; index < sceneMeshes.length; index++) {
                    var mesh: AbstractMesh = sceneMeshes[index];
                    if (this.renderListPredicate(mesh)) {
                        this.renderList.push(mesh);
                    }
                }
            }

            if (this.renderList && this.renderList.length === 0) {
                return;
            }

            // Set custom projection.
            // Needs to be before binding to prevent changing the aspect ratio.
            if (this.activeCamera) {
                engine.setViewport(this.activeCamera.viewport);

                if (this.activeCamera !== scene.activeCamera)
                {
                    scene.setTransformMatrix(this.activeCamera.getViewMatrix(), this.activeCamera.getProjectionMatrix(true));
                }
            }
            else {
                engine.setViewport(scene.activeCamera.viewport);
            }

            // Prepare renderingManager
            this._renderingManager.reset();

            var currentRenderList: Vector.<AbstractMesh> = this.renderList ? this.renderList : Vector.<AbstractMesh>(scene.getActiveMeshes());
            var currentRenderListLength: uint = this.renderList ? this.renderList.length : scene.getActiveMeshes().length;
            var sceneRenderId: Number = scene.getRenderId();
            for (var meshIndex: int = 0; meshIndex < currentRenderListLength; meshIndex++) {
                mesh = currentRenderList[meshIndex];

                if (mesh) {
                    if (!mesh.isReady()) {
                        // Reset _currentRefreshId
                        this.resetRefreshCounter();
                        continue;
                    }

                    mesh._preActivateForIntermediateRendering();

                    if (mesh.isEnabled() && mesh.isVisible && mesh.subMeshes && ((mesh.layerMask & scene.activeCamera.layerMask) !== 0)) {
                        mesh._activate(sceneRenderId);

                        for (var subIndex: int = 0; subIndex < mesh.subMeshes.length; subIndex++) {
                            var subMesh: SubMesh = mesh.subMeshes[subIndex];
                            scene._activeIndices.addCount(subMesh.indexCount, false);
                            this._renderingManager.dispatch(subMesh);
                        }
                    }
                }
            }

            if (this.isCube) {
                for (var face: int = 0; face < 6; face++) {
                    this.renderToTarget(face, currentRenderList, useCameraPostProcess, dumpForDebug);
                    scene.incrementRenderId();
                    scene.resetCachedMaterial();
                }
            } else {
                this.renderToTarget(0, currentRenderList, useCameraPostProcess, dumpForDebug);
            }

            this.onAfterUnbindObservable.notifyObservers(this);

            if (this.activeCamera && this.activeCamera !== scene.activeCamera) {
                scene.setTransformMatrix(scene.activeCamera.getViewMatrix(), scene.activeCamera.getProjectionMatrix(true));
            }
            engine.setViewport(scene.activeCamera.viewport);

            scene.resetCachedMaterial();
        }

        public function renderToTarget(faceIndex: Number, currentRenderList: Vector.<AbstractMesh>, useCameraPostProcess: Boolean, dumpForDebug: Boolean): void {
            var scene: Scene = this.getScene();
            var engine: Engine = scene.getEngine();

            // Bind
            if (!useCameraPostProcess || !scene.postProcessManager._prepareFrame(this._texture)) {
                if (this.isCube) {
                    engine.bindFramebuffer(this._texture, faceIndex);
                } else {
                    engine.bindFramebuffer(this._texture);
                }
            }

            this.onBeforeRenderObservable.notifyObservers(faceIndex);

            // Clear
            if (this.onClearObservable.hasObservers()) {
                this.onClearObservable.notifyObservers(engine);
            } else {
                engine.clear(scene.clearColor, true, true, true);
            }

            if (!this._doNotChangeAspectRatio) {
                scene.updateTransformMatrix(true);
            }

            // Render
            this._renderingManager.render(this.customRenderFunction, currentRenderList, this.renderParticles);

            if (useCameraPostProcess) {
                scene.postProcessManager._finalizeFrame(false, this._texture, faceIndex);
            }

            if (!this._doNotChangeAspectRatio) {
                scene.updateTransformMatrix(true);
            }

            this.onAfterRenderObservable.notifyObservers(faceIndex);

            // Dump ?
            if (dumpForDebug) {
//                Tools.DumpFramebuffer(this._size, this._size, engine);
            }

            // Unbind
            if (!this.isCube || faceIndex === 5) {
                if (this.isCube) {

                    if (faceIndex === 5) {
//                        engine.generateMipMapsForCubemap(this._texture);
                    }
                }

                engine.unBindFramebuffer();
            }
        }

        /**
         * Overrides the default sort function applied in the renderging group to prepare the meshes.
         * This allowed control for front to back rendering or reversly depending of the special needs.
         *
         * @param renderingGroupId The rendering group id corresponding to its index
         * @param opaqueSortCompareFn The opaque queue comparison function use to sort.
         * @param alphaTestSortCompareFn The alpha test queue comparison function use to sort.
         * @param transparentSortCompareFn The transparent queue comparison function use to sort.
         */
        public function setRenderingOrder(renderingGroupId: Number,
                                          opaqueSortCompareFn: Function,    //(a: SubMesh, b: SubMesh) => Number = null,
                                          alphaTestSortCompareFn: Function,   // (a: SubMesh, b: SubMesh) => Number = null,
                                          transparentSortCompareFn: Function): void { // (a: SubMesh, b: SubMesh) => Number = null): void {

            this._renderingManager.setRenderingOrder(renderingGroupId,
                    opaqueSortCompareFn,
                    alphaTestSortCompareFn,
                    transparentSortCompareFn);
        }

        /**
         * Specifies whether or not the stencil and depth buffer are cleared between two rendering groups.
         *
         * @param renderingGroupId The rendering group id corresponding to its index
         * @param autoClearDepthStencil Automatically clears depth and stencil between groups if true.
         */
        public function setRenderingAutoClearDepthStencil(renderingGroupId: Number, autoClearDepthStencil: Boolean): void {
            this._renderingManager.setRenderingAutoClearDepthStencil(renderingGroupId, autoClearDepthStencil);
        }

        public function clone(): RenderTargetTexture {
            var textureSize: Size = this.getSize();
            var newTexture: RenderTargetTexture = new RenderTargetTexture(
                    this.name,
                    textureSize.width,
                    this.getScene(),
                    this._renderTargetOptions.generateMipMaps,
                    this._doNotChangeAspectRatio,
                    this._renderTargetOptions.type,
                    this.isCube,
                    this._renderTargetOptions.samplingMode,
                    this._renderTargetOptions.generateDepthBuffer,
                    this._renderTargetOptions.generateStencilBuffer
            );

            // Base texture
            newTexture.hasAlpha = this.hasAlpha;
            newTexture.level = this.level;

            // RenderTarget Texture
            newTexture.coordinatesMode = this.coordinatesMode;
            newTexture.renderList = this.renderList.slice(0);

            return newTexture;
        }

        override public function serialize(): Object {
            if (!this.name) {
                return null;
            }

            var serializationObject: Object = super.serialize();

            serializationObject.renderTargetSize = this.getRenderSize();
            serializationObject.renderList = [];

            for (var index: int = 0; index < this.renderList.length; index++) {
                serializationObject.renderList.push(this.renderList[index].id);
            }

            return serializationObject;
        }
    }
}
