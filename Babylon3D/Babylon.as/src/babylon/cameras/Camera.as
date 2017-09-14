/**
 * Created by caijingxiao on 2016/10/14.
 */
package babylon.cameras {
    import babylon.Engine;
    import babylon.Node;
    import babylon.Scene;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.math.Viewport;
    import babylon.mesh.Mesh;
    import babylon.postProcess.PassPostProcess;
    import babylon.postProcess.PostProcess;
    import babylon.tools.Tools;

    import easiest.unit.asserts.fail;

    import flash.events.EventDispatcher;

    public class Camera extends Node {
        // Statics
        public static const PERSPECTIVE_CAMERA: int = 0;
        public static const ORTHOGRAPHIC_CAMERA: int = 1;

        public static const FOVMODE_VERTICAL_FIXED: int = 0;
        public static const FOVMODE_HORIZONTAL_FIXED: int = 1;

        public static const RIG_MODE_NONE: int = 0;
        public static const RIG_MODE_STEREOSCOPIC_ANAGLYPH: int = 10;
        public static const RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_PARALLEL: int = 11;
        public static const RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED: int = 12;
        public static const RIG_MODE_STEREOSCOPIC_OVERUNDER: int = 13;
        public static const RIG_MODE_VR: int = 20;
        public static const RIG_MODE_WEBVR: int = 21;

        public static var ForceAttachControlToAlwaysPreventDefault: Boolean = false;

        // Members
        [Serialize(type="vector3")]
        public var position: Vector3;
        [Serialize(type="vector3")]
        public var upVector: Vector3 = Vector3.Up();

        [Serialize]
        public var orthoLeft: Number;

        [Serialize]
        public var orthoRight: Number;

        [Serialize]
        public var orthoBottom: Number;

        [Serialize]
        public var orthoTop: Number;

        [Serialize]
        public var fov: Number = 0.8;
        [Serialize]
        public var minZ: Number = 1.0;
        [Serialize]
        public var maxZ: Number = 10000.0;

        [Serialize]
        public var inertia: Number = 0.9;

        [Serialize]
        public var mode: int = PERSPECTIVE_CAMERA;
        public var isIntermediate: Boolean = false;

        public var viewport: Viewport = new Viewport(0, 0, 1.0, 1.0);
        [Serialize]
        public var layerMask: uint = 0x0FFFFFFF;
        [Serialize]
        public var fovMode: int = FOVMODE_VERTICAL_FIXED;

        // Camera rig members
        [Serialize]
        public var cameraRigMode: int = RIG_MODE_NONE;

        [Serialize]
        public var interaxialDistance: Number;

        [Serialize]
        public var isStereoscopicSideBySide: Boolean;

        public var _cameraRigParams: Object;
        public var _rigCameras: Vector.<Camera> = new <Camera>[];
        public var _rigPostProcess: PostProcess;

        // Cache
        private var _computedViewMatrix: Matrix = Matrix.Identity();
        public var _projectionMatrix: Matrix = new Matrix();
        private var _worldMatrix: Matrix;
        public var _postProcesses: Vector.<PostProcess> = new <PostProcess>[];

        private var _globalPosition: Vector3 = Vector3.Zero();

        public var _activeMeshes: Vector.<Mesh> = new <Mesh>[];

        private var _refreshFrustumPlanes:Boolean = true;

        public function Camera(name: String, position: Vector3, scene: Scene) {
            super(name, scene);

            scene.addCamera(this);

            if (!scene.activeCamera) {
                scene.activeCamera = this;
            }

            this.position = position;
        }

        public function get globalPosition(): Vector3 {//164
            return this._globalPosition;
        }

        public function getActiveMeshes(): Vector.<Mesh> {//170
            return this._activeMeshes;
        }

        override public function _initCache(): void {//177
            super._initCache();

            this._cache.position = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
            this._cache.upVector = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);

            this._cache.mode = undefined;
            this._cache.minZ = undefined;
            this._cache.maxZ = undefined;

            this._cache.fov = undefined;
            this._cache.fovMode = undefined;
            this._cache.aspectRatio = undefined;

            this._cache.orthoLeft = undefined;
            this._cache.orthoRight = undefined;
            this._cache.orthoBottom = undefined;
            this._cache.orthoTop = undefined;
            this._cache.renderWidth = undefined;
            this._cache.renderHeight = undefined;
        }

        override public function _updateCache(ignoreParentClass: Boolean = false): void {
            if (!ignoreParentClass) {
                super._updateCache();
            }

            var engine: Engine = this.getEngine();

            this._cache.position.copyFrom(this.position);
            this._cache.upVector.copyFrom(this.upVector);

            this._cache.mode = this.mode;
            this._cache.minZ = this.minZ;
            this._cache.maxZ = this.maxZ;

            this._cache.fov = this.fov;
            this._cache.fovMode = this.fovMode;
            this._cache.aspectRatio = engine.getAspectRatio(this);

            this._cache.orthoLeft = this.orthoLeft;
            this._cache.orthoRight = this.orthoRight;
            this._cache.orthoBottom = this.orthoBottom;
            this._cache.orthoTop = this.orthoTop;
            this._cache.renderWidth = engine.getRenderWidth();
            this._cache.renderHeight = engine.getRenderHeight();
        }

        public function _updateFromScene(): void {
            this.updateCache();
            this.update();
        }

        public function _isSynchronizedViewMatrix(): Boolean {//235
            if (!super._isSynchronized())
                return false;

            return this._cache.position.equals(this.position)
                    && this._cache.upVector.equals(this.upVector)
                    && this.isSynchronizedWithParent();
        }

        public function _isSynchronizedProjectionMatrix(): Boolean {
            var check: Boolean = this._cache.mode == this.mode
                    && this._cache.minZ == this.minZ
                    && this._cache.maxZ == this.maxZ;

            if (!check) {
                return false;
            }

            var engine: Engine = this.getEngine();

            if (this.mode == PERSPECTIVE_CAMERA) {
                check = this._cache.fov == this.fov
                && this._cache.fovMode == this.fovMode
                && this._cache.aspectRatio == engine.getAspectRatio(this);
            } else {
                throw new Error();
            }

            return check;
        }

        // Controls
        public function attachControl(element: EventDispatcher, noPreventDefault: Boolean = false, useCtrlForPanning: Boolean = true, panningMouseButton: Number = 2): void {
        }

        public function detachControl(element: EventDispatcher): void {
        }

        public function update(): void {
            if (this.cameraRigMode !== Camera.RIG_MODE_NONE) {
                this._updateRigCameras();
            }
            this._checkInputs();
        }

        public function _checkInputs(): void {//288
        }

        private function _cascadePostProcessesToRigCams(): void {
            // invalidate framebuffer
            if (this._postProcesses.length > 0) {
                this._postProcesses[0].markTextureDirty();
            }

            // glue the rigPostProcess to the end of the user postprocesses & assign to each sub-camera
            for (var i: int = 0, len: int = this._rigCameras.length; i < len; i++) {
                var cam: Camera = this._rigCameras[i];
                var rigPostProcess: PostProcess = cam._rigPostProcess;

                // for VR rig, there does not have to be a post process
                if (rigPostProcess) {
                    var isPass: Boolean = rigPostProcess is PassPostProcess;
                    if (isPass) {
                        // any rig which has a PassPostProcess for rig[0], cannot be isIntermediate when there are also user postProcesses
                        cam.isIntermediate = this._postProcesses.length === 0;
                    }
                    cam._postProcesses = this._postProcesses.slice(0).concat(rigPostProcess);
                    rigPostProcess.markTextureDirty();

                } else {
                    cam._postProcesses = this._postProcesses.slice(0);
                }
            }
        }

        public function attachPostProcess(postProcess: PostProcess, insertAt: int = -1): Number {
            if (!postProcess.isReusable() && this._postProcesses.indexOf(postProcess) > -1) {
                Tools.Error("You're trying to reuse a post process not defined as reusable.");
                return 0;
            }

            if (insertAt < 0) {
                this._postProcesses.push(postProcess);

            } else {
                this._postProcesses.splice(insertAt, 0, postProcess);
            }
            this._cascadePostProcessesToRigCams(); // also ensures framebuffer invalidated
            return this._postProcesses.indexOf(postProcess);
        }

        public function detachPostProcess(postProcess: PostProcess, atIndices: Object = null): Vector.<int> {
            var result: Vector.<int> = new <int>[];
            var i: int;
            var index: int;

            if (!atIndices) {
                var idx: int = this._postProcesses.indexOf(postProcess);
                if (idx !== -1) {
                    this._postProcesses.splice(idx, 1);
                }
            } else {
                atIndices = (atIndices is Array) ? atIndices : [atIndices];
                // iterate descending, so can just splice as we go
                for (i = atIndices.length - 1; i >= 0; i--) {
                    if (this._postProcesses[atIndices[i]] !== postProcess) {
                        result.push(i);
                        continue;
                    }
                    this._postProcesses.splice(index, 1);
                }
            }
            this._cascadePostProcessesToRigCams(); // also ensures framebuffer invalidated
            return result;
        }

        public function _getViewMatrix(): Matrix {//369
            return Matrix.Identity();
        }

        public function getViewMatrix(force: Boolean = false): Matrix {//373
            this._computedViewMatrix = this._computeViewMatrix(force);

            if (!force && this._isSynchronizedViewMatrix()) {
                return this._computedViewMatrix;
            }

            this._refreshFrustumPlanes = true;

            if (!this.parent || !this.parent.getWorldMatrix) {
                this._globalPosition.copyFrom(this.position);
            } else {
                if (!this._worldMatrix) {
                    this._worldMatrix = Matrix.Identity();
                }

                this._computedViewMatrix.invertToRef(this._worldMatrix);

                this._worldMatrix.multiplyToRef(this.parent.getWorldMatrix(), this._computedViewMatrix);
                this._globalPosition.copyFromFloats(this._computedViewMatrix.m[12], this._computedViewMatrix.m[13], this._computedViewMatrix.m[14]);

                this._computedViewMatrix.invert();

                this._markSyncedWithParent();
            }

            this._currentRenderId = this.getScene().getRenderId();

            return _computedViewMatrix;
        }

        private function _computeViewMatrix(force: Boolean): Matrix {//404
            if (!force && this._isSynchronizedViewMatrix()) {
                return this._computedViewMatrix;
            }

            this._computedViewMatrix = this._getViewMatrix();
            this._currentRenderId = this.getScene().getRenderId();

            return this._computedViewMatrix;
        }

        public function getProjectionMatrix(force: Boolean = false): Matrix {//415
            if (!force && this._isSynchronizedProjectionMatrix()) {
                return this._projectionMatrix;
            }

            this._refreshFrustumPlanes = true;

            var engine: Engine = this.getEngine();
            var scene: Scene = this.getScene();
            if (this.mode == Camera.PERSPECTIVE_CAMERA) {
                if (this.minZ <= 0) {
                    this.minZ = 0.1;
                }

                if (scene.useRightHandedSystem) {
                    Matrix.PerspectiveFovRHToRef(this.fov,
                            engine.getAspectRatio(this),
                            this.minZ,
                            this.maxZ,
                            this._projectionMatrix,
                            this.fovMode == Camera.FOVMODE_VERTICAL_FIXED);
                } else {
                    Matrix.PerspectiveFovLHToRef(this.fov,
                            engine.getAspectRatio(this),
                            this.minZ,
                            this.maxZ,
                            this._projectionMatrix,
                            this.fovMode == Camera.FOVMODE_VERTICAL_FIXED);
                }
                return this._projectionMatrix;
            } else {
                fail();
            }

            return this._projectionMatrix;
        }

        /**
         * May need to be overridden by children
         */
        public function _updateRigCameras(): void {//664
            for (var i: int = 0; i < this._rigCameras.length; i++) {
                this._rigCameras[i].minZ = this.minZ;
                this._rigCameras[i].maxZ = this.maxZ;
                this._rigCameras[i].fov = this.fov;
            }

            // only update viewport when ANAGLYPH
            if (this.cameraRigMode === Camera.RIG_MODE_STEREOSCOPIC_ANAGLYPH) {
                this._rigCameras[0].viewport = this._rigCameras[1].viewport = this.viewport;
            }
        }
    }
}
