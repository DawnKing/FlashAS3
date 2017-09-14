/**
 * Created by caijingxiao on 2016/10/26.
 */
package babylon.cameras {
    import babylon.Scene;
    import babylon.math.MathTools;
    import babylon.math.Matrix;
    import babylon.math.Quaternion;
    import babylon.math.Vector2;
    import babylon.math.Vector3;

    public class TargetCamera extends Camera {

        public var cameraDirection: Vector3 = new Vector3(0, 0, 0);
        public var cameraRotation: Vector2 = new Vector2(0, 0);

        [Serialize(type="vector3")]
        public var rotation: Vector3 = new Vector3(0, 0, 0);

        public var rotationQuaternion: Quaternion;


        [Serialize]
        public var speed: Number = 2.0;

        public var noRotationConstraint: Boolean = false;

        public var lockedTarget: Object = null;

        public var _currentTarget: Vector3 = Vector3.Zero();
        public var _viewMatrix: Matrix = Matrix.Zero();
        public var _camMatrix: Matrix = Matrix.Zero();
        public var _cameraTransformMatrix: Matrix = Matrix.Zero();
        public var _cameraRotationMatrix: Matrix = Matrix.Zero();
        private var _rigCamTransformMatrix: Matrix;

        public var _referencePoint: Vector3 = new Vector3(0, 0, 1);
        private var _defaultUpVector: Vector3 = new Vector3(0, 1, 0);
        public var _transformedReferencePoint: Vector3 = Vector3.Zero();

        public function TargetCamera(name: String, position: Vector3, scene: Scene) {
            super(name, position, scene);
        }

        public function _getLockedTargetPosition(): Vector3 {
            if (!this.lockedTarget) {
                return null;
            }

            return this.lockedTarget as Vector3 || this.lockedTarget.position as Vector3;
        }

        // Cache
        override public function _initCache(): void {
            super._initCache();
            this._cache.lockedTarget = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
            this._cache.rotation = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
            this._cache.rotationQuaternion = new Quaternion(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
        }

        override public function _updateCache(ignoreParentClass: Boolean = false): void {
            if (!ignoreParentClass) {
                super._updateCache();
            }

            var lockedTargetPosition: Vector3 = this._getLockedTargetPosition();
            if (!lockedTargetPosition) {
                this._cache.lockedTarget = null;
            }
            else {
                if (!this._cache.lockedTarget) {
                    this._cache.lockedTarget = lockedTargetPosition.clone();
                }
                else {
                    this._cache.lockedTarget.copyFrom(lockedTargetPosition);
                }
            }

            this._cache.rotation.copyFrom(this.rotation);
            if (this.rotationQuaternion)
                this._cache.rotationQuaternion.copyFrom(this.rotationQuaternion);
        }

        // Synchronized
        override public function _isSynchronizedViewMatrix(): Boolean {
            if (!super._isSynchronizedViewMatrix()) {
                return false;
            }

            var lockedTargetPosition: Vector3 = this._getLockedTargetPosition();

            return (this._cache.lockedTarget ? this._cache.lockedTarget.equals(lockedTargetPosition) : !lockedTargetPosition)
                    && (this.rotationQuaternion ? this.rotationQuaternion.equals(this._cache.rotationQuaternion) : this._cache.rotation.equals(this.rotation));
        }

        // Target
        public function setTarget(target: Vector3, toBoundingCenter: Boolean = false): void {//104
            this.upVector.normalize();

            Matrix.LookAtLHToRef(this.position, target, this._defaultUpVector, this._camMatrix);
            this._camMatrix.invert();

            this.rotation.x = Math.atan(this._camMatrix.m[6] / this._camMatrix.m[10]);

            var vDir: Vector3 = target.subtract(this.position);

            if (vDir.x >= 0.0) {
                this.rotation.y = (-Math.atan(vDir.z / vDir.x) + Math.PI / 2.0);
            } else {
                this.rotation.y = (-Math.atan(vDir.z / vDir.x) - Math.PI / 2.0);
            }

            this.rotation.z = 0;

            if (isNaN(this.rotation.x)) {
                this.rotation.x = 0;
            }

            if (isNaN(this.rotation.y)) {
                this.rotation.y = 0;
            }

            if (isNaN(this.rotation.z)) {
                this.rotation.z = 0;
            }

            if (this.rotationQuaternion)
                Quaternion.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this.rotationQuaternion);
        }

        public function  getTarget(): Vector3 {
            return this._currentTarget;
        }


        public function  _decideIfNeedsToMove(): Boolean {
            return Math.abs(this.cameraDirection.x) > 0 || Math.abs(this.cameraDirection.y) > 0 || Math.abs(this.cameraDirection.z) > 0;
        }

        public function  _updatePosition(): void {
            this.position.addInPlace(this.cameraDirection);
        }
        override public function  _checkInputs(): void {
            var needToMove: Boolean = this._decideIfNeedsToMove();
            var needToRotate: Boolean = Math.abs(this.cameraRotation.x) > 0 || Math.abs(this.cameraRotation.y) > 0;

            // Move
            if (needToMove) {
                this._updatePosition();
            }

            // Rotate
            if (needToRotate) {
                this.rotation.x += this.cameraRotation.x;
                this.rotation.y += this.cameraRotation.y;


                if (!this.noRotationConstraint) {
                    var limit: Number = (Math.PI / 2) * 0.95;


                    if (this.rotation.x > limit)
                        this.rotation.x = limit;
                    if (this.rotation.x < -limit)
                        this.rotation.x = -limit;
                }
            }

            // Inertia
            if (needToMove) {
                if (Math.abs(this.cameraDirection.x) < MathTools.Epsilon) {
                    this.cameraDirection.x = 0;
                }

                if (Math.abs(this.cameraDirection.y) < MathTools.Epsilon) {
                    this.cameraDirection.y = 0;
                }

                if (Math.abs(this.cameraDirection.z) < MathTools.Epsilon) {
                    this.cameraDirection.z = 0;
                }

                this.cameraDirection.scaleInPlace(this.inertia);
            }
            if (needToRotate) {
                if (Math.abs(this.cameraRotation.x) < MathTools.Epsilon) {
                    this.cameraRotation.x = 0;
                }

                if (Math.abs(this.cameraRotation.y) < MathTools.Epsilon) {
                    this.cameraRotation.y = 0;
                }
                this.cameraRotation.scaleInPlace(this.inertia);
            }

            super._checkInputs();
        }

        private function _updateCameraRotationMatrix(): void {
            if (this.rotationQuaternion) {
                this.rotationQuaternion.toRotationMatrix(this._cameraRotationMatrix);
                // update the up vector!
                Vector3.TransformNormalToRef(this._defaultUpVector, this._cameraRotationMatrix, this.upVector);
            } else {
                Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this._cameraRotationMatrix);
            }
        }

        override public function _getViewMatrix(): Matrix {//217
            if (!this.lockedTarget) {
                // Compute
                this._updateCameraRotationMatrix();

                Vector3.TransformCoordinatesToRef(this._referencePoint, this._cameraRotationMatrix, this._transformedReferencePoint);

                // Computing target and final matrix
                this.position.addToRef(this._transformedReferencePoint, this._currentTarget);
            } else {
                this._currentTarget.copyFrom(this._getLockedTargetPosition());
            }

            if (this.getScene().useRightHandedSystem) {
                Matrix.LookAtRHToRef(this.position, this._currentTarget, this.upVector, this._viewMatrix);
            } else {
                Matrix.LookAtLHToRef(this.position, this._currentTarget, this.upVector, this._viewMatrix);
            }

            return this._viewMatrix;
        }

        /**
         * @override
         * Override Camera._updateRigCameras
         */
        override public function _updateRigCameras(): void {//262
            var camLeft: TargetCamera = this._rigCameras[0] as TargetCamera;
            var camRight: TargetCamera = this._rigCameras[1] as TargetCamera;

            switch (this.cameraRigMode) {
                case Camera.RIG_MODE_STEREOSCOPIC_ANAGLYPH:
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_PARALLEL:
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED:
                case Camera.RIG_MODE_STEREOSCOPIC_OVERUNDER:
                    //provisionnaly using _cameraRigParams.stereoHalfAngle instead of calculations based on _cameraRigParams.interaxialDistance:
                    var leftSign: int = (this.cameraRigMode === Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED) ? 1 : -1;
                    var rightSign: int = (this.cameraRigMode === Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED) ? -1 : 1;
                    this._getRigCamPosition(this._cameraRigParams.stereoHalfAngle * leftSign, camLeft.position);
                    this._getRigCamPosition(this._cameraRigParams.stereoHalfAngle * rightSign, camRight.position);

                    camLeft.setTarget(this.getTarget());
                    camRight.setTarget(this.getTarget());
                    break;

                case Camera.RIG_MODE_VR:
                case Camera.RIG_MODE_WEBVR:
                    if (camLeft.rotationQuaternion) {
                        camLeft.rotationQuaternion.copyFrom(this.rotationQuaternion);
                        camRight.rotationQuaternion.copyFrom(this.rotationQuaternion);
                    } else {
                        camLeft.rotation.copyFrom(this.rotation);
                        camRight.rotation.copyFrom(this.rotation);
                    }
                    camLeft.position.copyFrom(this.position);
                    camRight.position.copyFrom(this.position);

                    break;
            }
            super._updateRigCameras();
        }

        private function _getRigCamPosition(halfSpace: Number, result: Vector3): void {
            if (!this._rigCamTransformMatrix) {
                this._rigCamTransformMatrix = new Matrix();
            }
            var target: Vector3 = this.getTarget();
            Matrix.Translation(-target.x, -target.y, -target.z).multiplyToRef(Matrix.RotationY(halfSpace), this._rigCamTransformMatrix);

            this._rigCamTransformMatrix = this._rigCamTransformMatrix.multiply(Matrix.Translation(target.x, target.y, target.z));

            Vector3.TransformCoordinatesToRef(this.position, this._rigCamTransformMatrix, result);
        }
    }
}
