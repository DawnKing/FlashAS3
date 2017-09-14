/**
 * Created by caijingxiao on 2016/10/17.
 */
package babylon.mesh {
    import babylon.Node;
    import babylon.Scene;
    import babylon.bones.Skeleton;
    import babylon.cameras.Camera;
    import babylon.culling.BoundingInfo;
    import babylon.lights.Light;
    import babylon.materials.Material;
    import babylon.materials.MaterialDefines;
    import babylon.math.Color3;
    import babylon.math.MathTools;
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Quaternion;
    import babylon.math.Tmp;
    import babylon.math.Vector3;

    public class AbstractMesh extends Node {
        // Statics
        public static const BILLBOARDMODE_NONE: int = 0;
        public static const BILLBOARDMODE_X: int = 1;
        public static const BILLBOARDMODE_Y: int = 2;
        public static const BILLBOARDMODE_Z: int = 4;
        public static const BILLBOARDMODE_ALL: int = 7;

        // Events

        // Properties
        public var definedFacingForward:Boolean = true; // orientation for POV movement & rotation
        public var position: Vector3 = new Vector3(0, 0, 0);
        private var _rotation: Vector3 = new Vector3(0, 0, 0);
        public var _rotationQuaternion: Quaternion;
        private var _scaling: Vector3 = new Vector3(1, 1, 1);
        public var billboardMode: int = BILLBOARDMODE_NONE;
        public var visibility: Number = 1.0;
        public var alphaIndex: Number = Number.MAX_VALUE;
        public var infiniteDistance:Boolean = false;
        public var isVisible:Boolean = true;
        public var isPickable:Boolean = true;
        public var showBoundingBox:Boolean = false;
        public var showSubMeshesBoundingBox:Boolean = false;
        public var isBlocker:Boolean = false;
        public var renderingGroupId: Number = 0;
        public var material: Material;
        public var receiveShadows:Boolean = false;
        public var renderOutline:Boolean = false;
        public var outlineColor: Color3 = Color3.Red();
        public var outlineWidth: Number = 0.02;
        public var renderOverlay:Boolean = false;
        public var overlayColor: Color3 = Color3.Red();
        public var overlayAlpha: Number = 0.5;
        public var hasVertexAlpha:Boolean = false;
        public var useVertexColors:Boolean = true;
        public var applyFog:Boolean = true;
        public var computeBonesUsingShaders:Boolean = true;
        public var scalingDeterminant: Number = 1;
        public var numBoneInfluencers: Number = 4;

        public var useOctreeForRenderingSelection:Boolean = true;
        public var useOctreeForPicking:Boolean = true;
        public var useOctreeForCollisions:Boolean = true;

        public var layerMask: Number = 0x0FFFFFFF;

        public var alwaysSelectAsActiveMesh:Boolean = false;

//        public var actionManager: ActionManager;

        // Physics
//        public var physicsImpostor: BABYLON.PhysicsImpostor;
        //Deprecated, Legacy support
//        public var onPhysicsCollide: (collidedMesh: AbstractMesh, contact: any) => void;

        // Collisions
//        private var _checkCollisions:Boolean = false;
        public var ellipsoid: Vector3 = new Vector3(0.5, 1, 0.5);
        public var ellipsoidOffset: Vector3 = new Vector3(0, 0, 0);
//        private var _collider = new Collider();
//        private var _oldPositionForCollisions: Vector3 = new Vector3(0, 0, 0);
//        private var _diffPositionForCollisions: Vector3 = new Vector3(0, 0, 0);
//        private var _newPositionForCollisions: Vector3 = new Vector3(0, 0, 0);

        // Attach to bone
        private var _meshToBoneReferal: AbstractMesh;

        // Edges
//        public var edgesWidth = 1;
//        public var edgesColor = new Color4(1, 0, 0, 1);
//        public var _edgesRenderer: EdgesRenderer;

        // Cache
        private var _localWorld: Matrix = Matrix.Zero();
        public var _worldMatrix: Matrix = Matrix.Zero();
//        private var _rotateYByPI: Matrix = Matrix.RotationY(Math.PI);
        private var _absolutePosition: Vector3 = Vector3.Zero();
//        private var _collisionsTransformMatrix: Matrix = Matrix.Zero();
//        private var _collisionsScalingMatrix: Matrix = Matrix.Zero();
        public var _positions: Vector.<Vector3>;
        private var _isDirty:Boolean = false;
        public var _masterMesh: AbstractMesh;
        public var _materialDefines: MaterialDefines;

        public var _boundingInfo: BoundingInfo;
        private var _pivotMatrix: Matrix = Matrix.Identity();
        public var _isDisposed:Boolean = false;
        public var _renderId: int = 0;

        public var subMeshes: Vector.<SubMesh>;
//        public var _submeshesOctree: Octree<SubMesh>;
        public var _intersectionsInProgress: Vector.<AbstractMesh> = new <AbstractMesh>[];

        private var _isWorldMatrixFrozen:Boolean = false;

        public var _poseMatrix: Matrix;

        // Loading properties
//        public var _waitingActions: any;
        public var _waitingFreezeWorldMatrix: Boolean;

        // Skeleton
        private var _skeleton: Skeleton;
        public var _bonesTransformMatrices: Vector.<Number>;

        public function set skeleton(value: Skeleton): void {
            if (this._skeleton && this._skeleton.needInitialSkinMatrix) {
                this._skeleton._unregisterMeshWithPoseMatrix(this);
            }

            if (value && value.needInitialSkinMatrix) {
                value._registerMeshWithPoseMatrix(this);
            }

            this._skeleton = value;

            if (!this._skeleton) {
                this._bonesTransformMatrices = null;
            }
        }

        public function get skeleton(): Skeleton {
            return this._skeleton;
        }

        public function AbstractMesh(name: String, scene: Scene) {
            super(name, scene);

            scene.addMesh(this);
        }

        public function toString(fullDetails: Boolean = false): String {
            var ret: String = "Name: " + this.name + ", isInstance: ";
            ret += ", # of submeshes: " + (this.subMeshes ? this.subMeshes.length : 0);

            if (fullDetails) {
                ret += ", billboard mode: " + (["NONE", "X", "Y", null, "Z", null, null, "ALL"])[this.billboardMode];
            }
            return ret;
        }

        public function get rotation(): Vector3 {//229
            return this._rotation;
        }

        public function set rotation(newRotation: Vector3): void {
            this._rotation = newRotation;
        }

        public function get scaling(): Vector3 {
            return this._scaling;
        }

        public function set scaling(newScaling: Vector3): void {
            this._scaling = newScaling;
        }

        public function get rotationQuaternion(): Quaternion {
            return this._rotationQuaternion;
        }

        public function set rotationQuaternion(quaternion: Quaternion): void {//252
            this._rotationQuaternion = quaternion;
            // reset the rotation vector.
            if (quaternion && this.rotation.length()) {
                this.rotation.copyFromFloats(0, 0, 0);
            }
        }

        public function getPoseMatrix(): Matrix {
            return this._poseMatrix;
        }

        public function get isBlocked(): Boolean {//281
            return false;
        }

        public function getLOD(): AbstractMesh {
            return this;
        }

        public function getTotalVertices(): int {//289
            return 0;
        }

        public function getIndices(copyWhenShared: Boolean = false): Vector.<uint> {
            return null;
        }

        public function getVerticesData(kind: String, copyWhenShared: Boolean = false): Vector.<Number> {
            return null;
        }

        public function isVerticesDataPresent(kind: String): Boolean {
            return false;
        }

        public function getBoundingInfo(): BoundingInfo {//305
            return null;
        }

        public function get useBones(): Boolean {
            return this.skeleton && this.getScene().skeletonsEnabled && this.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind) && this.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind);
        }

        public function _preActivate(): void {//324
        }

        public function _preActivateForIntermediateRendering(): void {
        }

        public function _activate(renderId: int): void {//330
            this._renderId = renderId;
        }

        override public function getWorldMatrix(): Matrix {//334
            if (this._masterMesh) {
                return this._masterMesh.getWorldMatrix();
            }

            if (this._currentRenderId != this.getScene().getRenderId()) {
                this.computeWorldMatrix();
            }
            return this._worldMatrix;
        }

        public function get worldMatrixFromCache(): Matrix {
            return this._worldMatrix;
        }

        public function get absolutePosition(): Vector3 {//349
            return this._absolutePosition;
        }

        private static var _rotationAxisCache: Quaternion = new Quaternion();
        public function rotate(axis: Vector3, amount: Number, space: int = 0): void {//335
            axis.normalize();

            if (!this.rotationQuaternion) {
                this.rotationQuaternion = Quaternion.RotationYawPitchRoll(this.rotation.y, this.rotation.x, this.rotation.z);
                this.rotation = Vector3.Zero();
            }
            var rotationQuaternion: Quaternion;
            if (space == MathTools.SPACE_LOCAL) {
                rotationQuaternion = Quaternion.RotationAxisToRef(axis, amount, AbstractMesh._rotationAxisCache);
                this.rotationQuaternion.multiplyToRef(rotationQuaternion, this.rotationQuaternion);
            }
            else {
                if (this.parent) {
                    var invertParentWorldMatrix: Matrix = this.parent.getWorldMatrix().clone();
                    invertParentWorldMatrix.invert();

                    axis = Vector3.TransformNormal(axis, invertParentWorldMatrix);
                }
                rotationQuaternion = Quaternion.RotationAxisToRef(axis, amount, AbstractMesh._rotationAxisCache);
                rotationQuaternion.multiplyToRef(this.rotationQuaternion, this.rotationQuaternion);
            }
        }

        public function translate(axis: Vector3, distance: Number, space: int = 0): void {//379
            var displacementVector: Vector3 = axis.scale(distance);

            if (space == MathTools.SPACE_LOCAL) {
                var tempV3: Vector3 = this.getPositionExpressedInLocalSpace().add(displacementVector);
                this.setPositionWithLocalVector(tempV3);
            }
            else {
                this.setAbsolutePosition(this.getAbsolutePosition().add(displacementVector));
            }
        }

        public function getAbsolutePosition(): Vector3 {
            this.computeWorldMatrix();
            return this._absolutePosition;
        }

        public function setAbsolutePosition(absolutePosition: Vector3): void {
            if (!absolutePosition) {
                return;
            }

            var absolutePositionX: Number;
            var absolutePositionY: Number;
            var absolutePositionZ: Number;

            if (isNaN(absolutePosition.x)) {
                if (arguments.length < 3) {
                    return;
                }
                absolutePositionX = arguments[0];
                absolutePositionY = arguments[1];
                absolutePositionZ = arguments[2];
            }
            else {
                absolutePositionX = absolutePosition.x;
                absolutePositionY = absolutePosition.y;
                absolutePositionZ = absolutePosition.z;
            }

            if (this.parent) {
                var invertParentWorldMatrix: Matrix = this.parent.getWorldMatrix().clone();
                invertParentWorldMatrix.invert();

                var worldPosition: Vector3 = new Vector3(absolutePositionX, absolutePositionY, absolutePositionZ);

                this.position = Vector3.TransformCoordinates(worldPosition, invertParentWorldMatrix);
            } else {
                this.position.x = absolutePositionX;
                this.position.y = absolutePositionY;
                this.position.z = absolutePositionZ;
            }
        }

        override public function _isSynchronized(): Boolean {//510
            if (this._isDirty) {
                return false;
            }

            if (this.infiniteDistance) {
                return false;
            }

            if (!this._cache.position.equals(this.position))
                return false;

            if (this.rotationQuaternion) {
                if (!this._cache.rotationQuaternion.equals(this.rotationQuaternion))
                    return false;
            }

            if (!this._cache.rotation.equals(this.rotation))
                return false;

            if (!this._cache.scaling.equals(this.scaling))
                return false;

            return true;
        }


        override public function _initCache(): void {//543
            super._initCache();

            this._cache.localMatrixUpdated = false;
            this._cache.position = Vector3.Zero();
            this._cache.scaling = Vector3.Zero();
            this._cache.rotation = Vector3.Zero();
            this._cache.rotationQuaternion = new Quaternion(0, 0, 0, 0);
            this._cache.billboardMode = -1;
        }

        public function _updateBoundingInfo(): void {//562
            this._boundingInfo ||= new BoundingInfo(this.absolutePosition, this.absolutePosition);

            this._boundingInfo.update(this.worldMatrixFromCache);

            this._updateSubMeshesBoundingInfo(this.worldMatrixFromCache);
        }

        public function _updateSubMeshesBoundingInfo(matrix: Matrix): void {
            if (!this.subMeshes) {
                return;
            }

            for (var subIndex: int = 0; subIndex < this.subMeshes.length; subIndex++) {
                var subMesh: SubMesh = this.subMeshes[subIndex];

                if (!subMesh.IsGlobal) {
                    subMesh.updateBoundingInfo(matrix);
                }
            }
        }

        public function computeWorldMatrix(force: Boolean = false): Matrix {//584
            if (this._isWorldMatrixFrozen) {
                return this._worldMatrix;
            }

            if (!force && (this._currentRenderId == this.getScene().getRenderId() || this.isSynchronized(true))) {
                this._currentRenderId = this.getScene().getRenderId();
                return this._worldMatrix;
            }

            this._cache.position.copyFrom(this.position);
            this._cache.scaling.copyFrom(this.scaling);
            this._cache.pivotMatrixUpdated = false;
            this._cache.billboardMode = this.billboardMode;
            this._currentRenderId = this.getScene().getRenderId();
            this._isDirty = false;

            // Scaling
            Matrix.ScalingToRef(this.scaling.x * this.scalingDeterminant, this.scaling.y * this.scalingDeterminant, this.scaling.z * this.scalingDeterminant, Tmp.MATRIX[1]);

            // Rotation

            //rotate, if quaternion is set and rotation was used
            if (this.rotationQuaternion) {
                var len: Number = this.rotation.length();
                if (len) {
                    this.rotationQuaternion.multiplyInPlace(Quaternion.RotationYawPitchRoll(this.rotation.y, this.rotation.x, this.rotation.z));
                    this.rotation.copyFromFloats(0, 0, 0);
                }
            }

            if (this.rotationQuaternion) {
                this.rotationQuaternion.toRotationMatrix(Tmp.MATRIX[0]);
                this._cache.rotationQuaternion.copyFrom(this.rotationQuaternion);
            } else {
                Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, Tmp.MATRIX[0]);
                this._cache.rotation.copyFrom(this.rotation);
            }

            // Translation
            if (this.infiniteDistance && !this.parent) {
                var camera: Camera = this.getScene().activeCamera;
                if (camera) {
                    var cameraWorldMatrix: Matrix = camera.getWorldMatrix();

                    var cameraGlobalPosition: Vector3 = new Vector3(cameraWorldMatrix.m[12], cameraWorldMatrix.m[13], cameraWorldMatrix.m[14]);

                    Matrix.TranslationToRef(this.position.x + cameraGlobalPosition.x, this.position.y + cameraGlobalPosition.y,
                            this.position.z + cameraGlobalPosition.z, Tmp.MATRIX[2]);
                }
            } else {
                Matrix.TranslationToRef(this.position.x, this.position.y, this.position.z, Tmp.MATRIX[2]);
            }

            // Composing transformations
            this._pivotMatrix.multiplyToRef(Tmp.MATRIX[1], Tmp.MATRIX[4]);
            Tmp.MATRIX[4].multiplyToRef(Tmp.MATRIX[0], Tmp.MATRIX[5]);

            // Local world
            Tmp.MATRIX[5].multiplyToRef(Tmp.MATRIX[2], this._localWorld);

            // Parent
            if (this.parent && this.parent.getWorldMatrix && this.billboardMode === AbstractMesh.BILLBOARDMODE_NONE) {
                this._markSyncedWithParent();

                if (this._meshToBoneReferal) {
                    this._localWorld.multiplyToRef(this.parent.getWorldMatrix(), Tmp.MATRIX[6]);
                    Tmp.MATRIX[6].multiplyToRef(this._meshToBoneReferal.getWorldMatrix(), this._worldMatrix);
                } else {
                    this._localWorld.multiplyToRef(this.parent.getWorldMatrix(), this._worldMatrix);
                }
            } else {
                this._worldMatrix.copyFrom(this._localWorld);
            }

            // Bounding info
            this._updateBoundingInfo();

            // Absolute position
            this._absolutePosition.copyFromFloats(this._worldMatrix.m[12], this._worldMatrix.m[13], this._worldMatrix.m[14]);

            if (!this._poseMatrix) {
                this._poseMatrix = Matrix.Invert(this._worldMatrix);
            }

            return this._worldMatrix;
        }

        public function setPositionWithLocalVector(vector3: Vector3): void {//718
            this.computeWorldMatrix();

            this.position = Vector3.TransformNormal(vector3, this._localWorld);
        }

        public function getPositionExpressedInLocalSpace(): Vector3 {//724
            this.computeWorldMatrix();
            var invLocalWorldMatrix: Matrix = this._localWorld.clone();
            invLocalWorldMatrix.invert();

            return Vector3.TransformNormal(this.position, invLocalWorldMatrix);
        }

        public function isInFrustum(frustumPlanes: Vector.<Plane>): Boolean {//789
            return this._boundingInfo.isInFrustum(frustumPlanes);
        }

        override public function dispose(doNotRecurse: Boolean = false): void {
            var index: int;

            // Action manager
//            if (this.actionManager) {
//                this.actionManager.dispose();
//                this.actionManager = null;
//            }

            // Skeleton
            this.skeleton = null;

            // Animations
            this.getScene().stopAnimation(this);

            // Physics
//            if (this.physicsImpostor) {
//                this.physicsImpostor.dispose(/*!doNotRecurse*/);
//            }

            // Intersections in progress
            for (index = 0; index < this._intersectionsInProgress.length; index++) {
                var other: AbstractMesh = this._intersectionsInProgress[index];

                var pos: int = other._intersectionsInProgress.indexOf(this);
                other._intersectionsInProgress.splice(pos, 1);
            }

            this._intersectionsInProgress.length = 0;

            // Lights
            var lights: Vector.<Light> = this.getScene().lights;
            var t: AbstractMesh = this;

            lights.forEach(function (light: Light, index: int, vector: Vector.<Light>): void {
                var meshIndex: int = light.includedOnlyMeshes.indexOf(t);

                if (meshIndex !== -1) {
                    light.includedOnlyMeshes.splice(meshIndex, 1);
                }

                meshIndex = light.excludedMeshes.indexOf(t);

                if (meshIndex !== -1) {
                    light.excludedMeshes.splice(meshIndex, 1);
                }

                // Shadow generators
//                var generator: IShadowGenerator = light.getShadowGenerator();
//                if (generator) {
//                    meshIndex = generator.getShadowMap().renderList.indexOf(t);
//
//                    if (meshIndex !== -1) {
//                        generator.getShadowMap().renderList.splice(meshIndex, 1);
//                    }
//                }
            });

            // Edges
//            if (this._edgesRenderer) {
//                this._edgesRenderer.dispose();
//                this._edgesRenderer = null;
//            }

            // SubMeshes
            this.releaseSubMeshes();

            // Engine
//            this.getScene().getEngine().unbindAllAttributes();

            // Remove from scene
            this.getScene().removeMesh(this);

            if (!doNotRecurse) {
                // Particles
                for (index = 0; index < this.getScene().particleSystems.length; index++) {
                    if (this.getScene().particleSystems[index].emitter === this) {
                        this.getScene().particleSystems[index].dispose();
                        index--;
                    }
                }

                // Children
                var objects: Vector.<Node> = this.getDescendants(true);
                for (index = 0; index < objects.length; index++) {
                    objects[index].dispose();
                }
            } else {
                var childMeshes: Vector.<Node> = this.getChildMeshes(true);
                for (index = 0; index < childMeshes.length; index++) {
                    var child: AbstractMesh = childMeshes[index] as AbstractMesh;
                    child.parent = null;
                    child.computeWorldMatrix(true);
                }
            }

//            this.onAfterWorldMatrixUpdateObservable.clear();
//            this.onCollideObservable.clear();
//            this.onCollisionPositionChangeObservable.clear();

            this._isDisposed = true;

            super.dispose();
        }

        public function releaseSubMeshes(): void {//1110
            if (this.subMeshes) {
                while (this.subMeshes.length) {
                    this.subMeshes[0].dispose();
                }
            } else {
                this.subMeshes = new <SubMesh>[];
            }
        }
    }
}
