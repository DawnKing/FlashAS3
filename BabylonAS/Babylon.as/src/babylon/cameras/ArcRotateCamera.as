/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras {
    import babylon.Scene;
    import babylon.cameras.inputs.ArcRotateCameraPointersInput;
    import babylon.math.MathTools;
    import babylon.math.Matrix;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;

    import flash.events.EventDispatcher;

    public class ArcRotateCamera extends TargetCamera {

        [Serialize]
        public var alpha: Number;

        [Serialize]
        public var beta: Number;

        [Serialize]
        public var radius: Number;

        [Serialize(type="vector3")]
        public var target: Vector3;

        [Serialize]
        public var inertialAlphaOffset: Number = 0;

        [Serialize]
        public var inertialBetaOffset : Number= 0;

        [Serialize]
        public var inertialRadiusOffset: Number = 0;

        [Serialize]
        public var lowerAlphaLimit: Number;

        [Serialize]
        public var upperAlphaLimit: Number;

        [Serialize]
        public var lowerBetaLimit: Number = 0.01;

        [Serialize]
        public var upperBetaLimit: Number = Math.PI;

        [Serialize]
        public var lowerRadiusLimit: Number;

        [Serialize]
        public var upperRadiusLimit: Number;

        [Serialize]
        public var inertialPanningX: Number = 0;

        [Serialize]
        public var inertialPanningY: Number = 0;

        //-- begin properties for backward compatibility for inputs       
        public function get angularSensibilityX(): Number {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers)
                return pointers.angularSensibilityX;
            return NaN;
        }

        public function set angularSensibilityX(value: Number): void {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers) {
                pointers.angularSensibilityX = value;
            }
        }

        public function get angularSensibilityY(): Number {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers)
                return pointers.angularSensibilityY;
            return NaN;
        }

        public function set angularSensibilityY(value: Number): void {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers) {
                pointers.angularSensibilityY = value;
            }
        }

        public function get pinchPrecision(): Number {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers)
                return pointers.pinchPrecision;
            return NaN;
        }

        public function set pinchPrecision(value: Number): void {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers) {
                pointers.pinchPrecision = value;
            }
        }

        public function get panningSensibility(): Number {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers)
                return pointers.panningSensibility;
            return NaN;
        }

        public function set panningSensibility(value: Number): void {
            var pointers: ArcRotateCameraPointersInput = this.inputs.attached["pointers"];
            if (pointers) {
                pointers.panningSensibility = value;
            }
        }

//        public function get keysUp() {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                return keyboard.keysUp;
//        }
//
//        public function set keysUp(value): void {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                keyboard.keysUp = value;
//        }
//
//        public function get keysDown() {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                return keyboard.keysDown;
//        }
//
//        public function set keysDown(value): void {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                keyboard.keysDown = value;
//        }
//
//        public function get keysLeft() {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                return keyboard.keysLeft;
//        }
//
//        public function set keysLeft(value): void {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                keyboard.keysLeft = value;
//        }
//
//        public function get keysRight() {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                return keyboard.keysRight;
//        }
//
//        public function set keysRight(value): void {
//            var keyboard = this.inputs.attached["keyboard"];
//            if (keyboard)
//                keyboard.keysRight = value;
//        }
//
//        public function get wheelPrecision() {
//            var mousewheel = this.inputs.attached["mousewheel"];
//            if (mousewheel)
//                return mousewheel.wheelPrecision;
//        }
//
//        public function set wheelPrecision(value): void {
//            var mousewheel = this.inputs.attached["mousewheel"];
//            if (mousewheel)
//                mousewheel.wheelPrecision = value;
//        }

        //-- end properties for backward compatibility for inputs

        [Serialize]
        public var zoomOnFactor: Number = 1;

        public var targetScreenOffset: Vector2 = Vector2.Zero();

        [Serialize]
        public var allowUpsideDown: Boolean = true;

        public var _useCtrlForPanning: Boolean;
        public var _panningMouseButton: Number;
        public var inputs: ArcRotateCameraInputsManager;

        public var _reset: Function;    // () => void;

        // Panning
        public var panningAxis: Vector3 = new Vector3(1, 1, 0);
        private var _localDirection: Vector3;
        private var _transformedDirection: Vector3;

        // Collisions
        public var onCollide: Function; // (collidedMesh: AbstractMesh) => void;
        public var checkCollisions: Boolean = false;
        public var collisionRadius: Vector3 = new Vector3(0.5, 0.5, 0.5);
//            private var _collider = new Collider();
        private var _previousPosition: Vector3 = Vector3.Zero();
        private var _collisionVelocity: Vector3 = Vector3.Zero();
        private var _newPosition: Vector3 = Vector3.Zero();
        private var _previousAlpha: Number;
        private var _previousBeta: Number;
        private var _previousRadius: Number;
        //due to async collision inspection
        private var _collisionTriggered: Boolean;

        private var _targetBoundingCenter: Vector3;

        public function ArcRotateCamera(name: String, alpha: Number, beta: Number, radius: Number, target: Vector3, scene: Scene) {
            super(name, Vector3.Zero(), scene);

            if (!target) {
                this.target = Vector3.Zero();
            } else {
                this.target = target;
            }

            this.alpha = alpha;
            this.beta = beta;
            this.radius = radius;

            this.getViewMatrix();
            this.inputs = new ArcRotateCameraInputsManager(this);
            this.inputs.addKeyboard().addMouseWheel().addPointers().addGamepad();
        }

        // Cache
        override public function _initCache(): void {
            super._initCache();
            this._cache.target = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
            this._cache.alpha = undefined;
            this._cache.beta = undefined;
            this._cache.radius = undefined;
            this._cache.targetScreenOffset = Vector2.Zero();
        }

        override public function _updateCache(ignoreParentClass: Boolean = false): void {
            if (!ignoreParentClass) {
                super._updateCache();
            }

            this._cache.target.copyFrom(this._getTargetPosition());
            this._cache.alpha = this.alpha;
            this._cache.beta = this.beta;
            this._cache.radius = this.radius;
            this._cache.targetScreenOffset.copyFrom(this.targetScreenOffset);
        }

        private function _getTargetPosition(): Vector3 {
//            if ((this.target).getAbsolutePosition) {
//                var pos : Vector3 = (this.target).getAbsolutePosition();
//                return this._targetBoundingCenter ? pos.add(this._targetBoundingCenter) : pos;
//            }

            return this.target;
        }

        // Synchronized
        override public function _isSynchronizedViewMatrix(): Boolean {
            if (!super._isSynchronizedViewMatrix())
                return false;

            return this._cache.target.equals(this.target)
                    && this._cache.alpha === this.alpha
                    && this._cache.beta === this.beta
                    && this._cache.radius === this.radius
                    && this._cache.targetScreenOffset.equals(this.targetScreenOffset);
        }

        // Methods
        override public function attachControl(element: EventDispatcher, noPreventDefault: Boolean = false, useCtrlForPanning: Boolean = true, panningMouseButton: Number = 2): void {
            this._useCtrlForPanning = useCtrlForPanning;
            this._panningMouseButton = panningMouseButton;

            this.inputs.attachElement(element, noPreventDefault);

            this._reset = function (): void {
                this.inertialAlphaOffset = 0;
                this.inertialBetaOffset = 0;
                this.inertialRadiusOffset = 0;
            };
        }

        override public function detachControl(element: EventDispatcher): void {
            this.inputs.detachElement(element);

            if (this._reset) {
                this._reset();
            }
        }

        override public function _checkInputs(): void {
            //if (async) collision inspection was triggered, don't update the camera's position - until the collision callback was called.
            if (this._collisionTriggered) {
                return;
            }

            this.inputs.checkInputs();
            // Inertia
            if (this.inertialAlphaOffset !== 0 || this.inertialBetaOffset !== 0 || this.inertialRadiusOffset !== 0) {

                if (this.getScene().useRightHandedSystem) {
                    this.alpha -= this.beta <= 0 ? -this.inertialAlphaOffset : this.inertialAlphaOffset;
                } else {
                    this.alpha += this.beta <= 0 ? -this.inertialAlphaOffset : this.inertialAlphaOffset;
                }

                this.beta += this.inertialBetaOffset;

                this.radius -= this.inertialRadiusOffset;
                this.inertialAlphaOffset *= this.inertia;
                this.inertialBetaOffset *= this.inertia;
                this.inertialRadiusOffset *= this.inertia;
                if (Math.abs(this.inertialAlphaOffset) < MathTools.Epsilon)
                    this.inertialAlphaOffset = 0;
                if (Math.abs(this.inertialBetaOffset) < MathTools.Epsilon)
                    this.inertialBetaOffset = 0;
                if (Math.abs(this.inertialRadiusOffset) < MathTools.Epsilon)
                    this.inertialRadiusOffset = 0;
            }

            // Panning inertia
            if (this.inertialPanningX !== 0 || this.inertialPanningY !== 0) {
                if (!this._localDirection) {
                    this._localDirection = Vector3.Zero();
                    this._transformedDirection = Vector3.Zero();
                }

                this.inertialPanningX *= this.inertia;
                this.inertialPanningY *= this.inertia;

                if (Math.abs(this.inertialPanningX) < MathTools.Epsilon)
                    this.inertialPanningX = 0;
                if (Math.abs(this.inertialPanningY) < MathTools.Epsilon)
                    this.inertialPanningY = 0;

                this._localDirection.copyFromFloats(this.inertialPanningX, this.inertialPanningY, this.inertialPanningY);
                this._localDirection.multiplyInPlace(this.panningAxis);
                this._viewMatrix.invertToRef(this._cameraTransformMatrix);
                Vector3.TransformNormalToRef(this._localDirection, this._cameraTransformMatrix, this._transformedDirection);
                //Eliminate y if map panning is enabled (panningAxis == 1,0,1)
                if (!this.panningAxis.y) {
                    this._transformedDirection.y = 0;
                }

                if (!this.target.hasOwnProperty("getAbsolutePosition")) {
                    this.target.addInPlace(this._transformedDirection);
                }
            }

            // Limits
            this._checkLimits();

            super._checkInputs();
        }

        private function _checkLimits(): void {
            if (isNaN(this.lowerBetaLimit)) {
                if (this.allowUpsideDown && this.beta > Math.PI) {
                    this.beta = this.beta - (2 * Math.PI);
                }
            } else {
                if (this.beta < this.lowerBetaLimit) {
                    this.beta = this.lowerBetaLimit;
                }
            }

            if (isNaN(this.upperBetaLimit)) {
                if (this.allowUpsideDown && this.beta < -Math.PI) {
                    this.beta = this.beta + (2 * Math.PI);
                }
            } else {
                if (this.beta > this.upperBetaLimit) {
                    this.beta = this.upperBetaLimit;
                }
            }

            if (this.lowerAlphaLimit && this.alpha < this.lowerAlphaLimit) {
                this.alpha = this.lowerAlphaLimit;
            }
            if (this.upperAlphaLimit && this.alpha > this.upperAlphaLimit) {
                this.alpha = this.upperAlphaLimit;
            }

            if (this.lowerRadiusLimit && this.radius < this.lowerRadiusLimit) {
                this.radius = this.lowerRadiusLimit;
            }
            if (this.upperRadiusLimit && this.radius > this.upperRadiusLimit) {
                this.radius = this.upperRadiusLimit;
            }
        }

        public function rebuildAnglesAndRadius(): void {
            var radiusv3: Vector3 = this.position.subtract(this._getTargetPosition());
            this.radius = radiusv3.length();

            // Alpha
            this.alpha = Math.acos(radiusv3.x / Math.sqrt(Math.pow(radiusv3.x, 2) + Math.pow(radiusv3.z, 2)));

            if (radiusv3.z < 0) {
                this.alpha = 2 * Math.PI - this.alpha;
            }

            // Beta
            this.beta = Math.acos(radiusv3.y / this.radius);

            this._checkLimits();
        }

        public function setPosition(position: Vector3): void {
            if (this.position.equals(position)) {
                return;
            }
            this.position.copyFrom(position);

            this.rebuildAnglesAndRadius();
        }

        override public function setTarget(target: Vector3, toBoundingCenter: Boolean = false): void {
            if (this._getTargetPosition().equals(target)) {
                return;
            }

//            if (toBoundingCenter && (target).getBoundingInfo){
//                this._targetBoundingCenter = (target).getBoundingInfo().boundingBox.center.clone();
//            }else{
//                this._targetBoundingCenter = null;
//            }
            this.target = target;
            this.rebuildAnglesAndRadius();
        }

        override public function _getViewMatrix(): Matrix {
            // Compute
            var cosa: Number = Math.cos(this.alpha);
            var sina: Number = Math.sin(this.alpha);
            var cosb: Number = Math.cos(this.beta);
            var sinb: Number = Math.sin(this.beta);

            if (sinb === 0) {
                sinb = 0.0001;
            }

            var target: Vector3 = this._getTargetPosition();
            target.addToRef(new Vector3(this.radius * cosa * sinb, this.radius * cosb, this.radius * sina * sinb), this._newPosition);
//            if (this.getScene().collisionsEnabled && this.checkCollisions) {
//                this._collider.radius = this.collisionRadius;
//                this._newPosition.subtractToRef(this.position, this._collisionVelocity);
//                this._collisionTriggered = true;
//                this.getScene().collisionCoordinator.getNewPosition(this.position, this._collisionVelocity, this._collider, 3, null, this._onCollisionPositionChange, this.uniqueId);
//            } else {
                this.position.copyFrom(this._newPosition);

                var up: Vector3 = this.upVector;
                if (this.allowUpsideDown && this.beta < 0) {
                    up = up.clone();
                    up = up.negate();
                }

                if (this.getScene().useRightHandedSystem) {
                    Matrix.LookAtRHToRef(this.position, target, up, this._viewMatrix);
                } else {
                    Matrix.LookAtLHToRef(this.position, target, up, this._viewMatrix);
                }
                this._viewMatrix.m[12] += this.targetScreenOffset.x;
                this._viewMatrix.m[13] += this.targetScreenOffset.y;
//            }
            return this._viewMatrix;
        }

        private function _onCollisionPositionChange(collisionId: Number, newPosition: Vector3, collidedMesh: AbstractMesh = null): void {

//            if (this.getScene().workerCollisions && this.checkCollisions) {
//                newPosition.multiplyInPlace(this._collider.radius);
//            }

            if (!collidedMesh) {
                this._previousPosition.copyFrom(this.position);
            } else {
                this.setPosition(newPosition);

                if (this.onCollide) {
                    this.onCollide(collidedMesh);
                }
            }

            // Recompute because of constraints
            var cosa: Number = Math.cos(this.alpha);
            var sina: Number = Math.sin(this.alpha);
            var cosb: Number = Math.cos(this.beta);
            var sinb: Number = Math.sin(this.beta);

            if (sinb === 0) {
                sinb = 0.0001;
            }

            var target: Vector3 = this._getTargetPosition();
            target.addToRef(new Vector3(this.radius * cosa * sinb, this.radius * cosb, this.radius * sina * sinb), this._newPosition);
            this.position.copyFrom(this._newPosition);

            var up: Vector3 = this.upVector;
            if (this.allowUpsideDown && this.beta < 0) {
                up = up.clone();
                up = up.negate();
            }

            Matrix.LookAtLHToRef(this.position, target, up, this._viewMatrix);
            this._viewMatrix.m[12] += this.targetScreenOffset.x;
            this._viewMatrix.m[13] += this.targetScreenOffset.y;

            this._collisionTriggered = false;
        }

        public function zoomOn(meshes: Vector.<AbstractMesh> = null, doNotUpdateMaxZ: Boolean = false): void {
            meshes = meshes || this.getScene().meshes;

            var minMaxVector: Object = Mesh.MinMax(meshes);
            var distance: Number = Vector3.Distance(minMaxVector.min, minMaxVector.max);

            this.radius = distance * this.zoomOnFactor;

            this.focusOn({ min: minMaxVector.min, max: minMaxVector.max, distance: distance }, doNotUpdateMaxZ);
        }

        public function focusOn(meshesOrMinMaxVectorAndDistance: Object, doNotUpdateMaxZ: Boolean = false): void {
            var meshesOrMinMaxVector: Object;
            var distance: Number;

            if (meshesOrMinMaxVectorAndDistance.min === undefined) { // meshes
                meshesOrMinMaxVector = meshesOrMinMaxVectorAndDistance || this.getScene().meshes;
                meshesOrMinMaxVector = Mesh.MinMax(Vector.<AbstractMesh>(meshesOrMinMaxVector));
                distance = Vector3.Distance(meshesOrMinMaxVector.min, meshesOrMinMaxVector.max);
            }
            else { //minMaxVector and distance
                meshesOrMinMaxVector = meshesOrMinMaxVectorAndDistance;
                distance = meshesOrMinMaxVectorAndDistance.distance;
            }

            this.target = Mesh.Center(meshesOrMinMaxVector);

            if (!doNotUpdateMaxZ) {
                this.maxZ = distance * 2;
            }
        }

        /**
         * @override
         * Override Camera.createRigCamera
         */
        public function createRigCamera(name: String, cameraIndex: Number): Camera {
            var alphaShift : Number;
            switch (this.cameraRigMode) {
                case Camera.RIG_MODE_STEREOSCOPIC_ANAGLYPH:
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_PARALLEL:
                case Camera.RIG_MODE_STEREOSCOPIC_OVERUNDER:
                case Camera.RIG_MODE_VR:
                    alphaShift = this._cameraRigParams.stereoHalfAngle * (cameraIndex === 0 ? 1 : -1);
                    break;
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED:
                    alphaShift = this._cameraRigParams.stereoHalfAngle * (cameraIndex === 0 ? -1 : 1);
                    break;
            }
            var rigCam: ArcRotateCamera = new ArcRotateCamera(name, this.alpha + alphaShift, this.beta, this.radius, this.target, this.getScene());
            rigCam._cameraRigParams = {};
            return rigCam;
        }

        /**
         * @override
         * Override Camera._updateRigCameras
         */
        override public function _updateRigCameras(): void {
            var camLeft: ArcRotateCamera  = this._rigCameras[0] as ArcRotateCamera;
            var camRight: ArcRotateCamera = this._rigCameras[1] as ArcRotateCamera;

            camLeft.beta = camRight.beta = this.beta;
            camLeft.radius = camRight.radius = this.radius;

            switch (this.cameraRigMode) {
                case Camera.RIG_MODE_STEREOSCOPIC_ANAGLYPH:
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_PARALLEL:
                case Camera.RIG_MODE_STEREOSCOPIC_OVERUNDER:
                case Camera.RIG_MODE_VR:
                    camLeft.alpha  = this.alpha - this._cameraRigParams.stereoHalfAngle;
                    camRight.alpha = this.alpha + this._cameraRigParams.stereoHalfAngle;
                    break;
                case Camera.RIG_MODE_STEREOSCOPIC_SIDEBYSIDE_CROSSEYED:
                    camLeft.alpha  = this.alpha + this._cameraRigParams.stereoHalfAngle;
                    camRight.alpha = this.alpha - this._cameraRigParams.stereoHalfAngle;
                    break;
            }
            super._updateRigCameras();
        }

        override public function dispose(doNotRecurse: Boolean = false): void {
            this.inputs.clear();
            super.dispose(doNotRecurse);
        }

        public function getTypeName(): String {
            return "ArcRotateCamera";
        }
    }
}
