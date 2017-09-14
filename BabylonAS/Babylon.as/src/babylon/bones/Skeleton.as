/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.bones {
    import babylon.Scene;
    import babylon.animations.Animatable;
    import babylon.animations.Animation;
    import babylon.animations.AnimationRange;
    import babylon.math.Matrix;
    import babylon.math.Tmp;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;
    import babylon.tools.ObjectUtils;
    import babylon.tools.Tools;

    import easiest.unit.asserts.fail;

    import flash.utils.Dictionary;

    public class Skeleton {
        public var name: String;
        public var id: String;

        public var bones: Vector.<Bone>;
        public var dimensionsAtRest: Vector3;
        public var needInitialSkinMatrix: Boolean = false;

        private var _scene: Scene;
        private var _isDirty: Boolean = true;
        private var _transformMatrices: Vector.<Number>;
        private var _meshesWithPoseMatrix: Vector.<AbstractMesh> = new <AbstractMesh>[];
        private var _animatables: Array;
        private var _identity: Matrix = Matrix.Identity();

        private var _ranges: Dictionary = new Dictionary(true); // [name: String]: AnimationRange;

        public function Skeleton(name: String, id: String, scene: Scene) {
            this.name = name;
            this.id = id;
            this.bones = new <Bone>[];

            this._scene = scene;

            scene.skeletons.push(this);

            //make sure it will recalculate the matrix next time prepare is called.
            this._isDirty = true;
        }

        // Members
        public function getTransformMatrices(mesh: AbstractMesh): Vector.<Number> {
            if (this.needInitialSkinMatrix && mesh._bonesTransformMatrices) {
                return mesh._bonesTransformMatrices;
            }
            return this._transformMatrices;
        }

        public function getScene(): Scene {
            return this._scene;
        }

        // Methods

        /**
         * @param {Boolean} fullDetails - support for multiple levels of logging within scene loading
         */
        public function toString(fullDetails: Boolean = false): String {
            var ret: String = "Name:" + this.name + "nBones:" + this.bones.length;
            ret += ", nAnimationRanges:" + this._ranges ? ObjectUtils.keys(this._ranges).length.toString() : "none";
            if (fullDetails) {
                ret += ", Ranges: {";
                var first: Boolean = true;
                for (var name: String in this._ranges) {
                    if (first) {
                        ret += ", ";
                        first = false;
                    }
                    ret += name;
                }
                ret += "}";
            }
            return ret;
        }

        /**
         * Get bone's index searching by name
         * @param {String} name is bone's name to search for
         * @return {Number} Indice of the bone. Returns -1 if not found
         */
        public function getBoneIndexByName(name: String): Number {
            for (var boneIndex: int = 0, cache: int = this.bones.length; boneIndex < cache; boneIndex++) {
                if (this.bones[boneIndex].name === name) {
                    return boneIndex;
                }
            }
            return -1;
        }

        public function createAnimationRange(name: String, from: Number, to: Number): void {
            // check name not already in use
            if (!this._ranges[name]) {
                this._ranges[name] = new AnimationRange(name, from, to);
                for (var i: int = 0, nBones: int = this.bones.length; i < nBones; i++) {
                    if (this.bones[i].animations[0]) {
                        this.bones[i].animations[0].createRange(name, from, to);
                    }
                }
            }
        }

        public function deleteAnimationRange(name: String, deleteFrames: Boolean = true): void {
            for (var i: int = 0, nBones: int = this.bones.length; i < nBones; i++) {
                if (this.bones[i].animations[0]) {
                    this.bones[i].animations[0].deleteRange(name, deleteFrames);
                }
            }
            this._ranges[name] = undefined; // said much faster than 'delete this._range[name]'
        }

        public function getAnimationRange(name: String): AnimationRange {
            return this._ranges[name];
        }

        /**
         *  Returns as an Array, all AnimationRanges defined on this skeleton
         */
        public function getAnimationRanges(): Vector.<AnimationRange> {
            var animationRanges: Vector.<AnimationRange> = new <AnimationRange>[];
            var name: String;
            var i: Number = 0;
            for (name in this._ranges) {
                animationRanges[i] = this._ranges[name];
                i++;
            }
            return animationRanges;
        }

        /**
         *  note: This is not for a complete retargeting, only between very similar skeleton's with only possible bone length differences
         */
        public function copyAnimationRange(source: Skeleton, name: String, rescaleAsRequired: Boolean = false): Boolean {
            if (this._ranges[name] || !source.getAnimationRange(name)) {
                return false;
            }
            var ret: Boolean = true;
            var frameOffset: int = this._getHighestAnimationFrame() + 1;

            // make a dictionary of source skeleton's bones, so exact same order or doublely nested loop is not required
            var boneDict: Object = {};
            var sourceBones: Vector.<Bone> = source.bones;
            var nBones: Number;
            var i: Number;
            for (i = 0, nBones = sourceBones.length; i < nBones; i++) {
                boneDict[sourceBones[i].name] = sourceBones[i];
            }

            if (this.bones.length !== sourceBones.length) {
                Tools.Warn("copyAnimationRange: this rig has" + this.bones.length + " bones, while source as " + sourceBones.length);
                ret = false;
            }

            var skelDimensionsRatio: Vector3 = (rescaleAsRequired && this.dimensionsAtRest && source.dimensionsAtRest) ? this.dimensionsAtRest.divide(source.dimensionsAtRest) : null;

            for (i = 0, nBones = this.bones.length; i < nBones; i++) {
                var boneName: String = this.bones[i].name;
                var sourceBone: Bone = boneDict[boneName];
                if (sourceBone) {
                    ret = ret && this.bones[i].copyAnimationRange(sourceBone, name, frameOffset, rescaleAsRequired, skelDimensionsRatio);
                } else {
                    Tools.Warn("copyAnimationRange: not same rig, missing source bone " + boneName);
                    ret = false;
                }
            }
            // do not call createAnimationRange(), since it also is done to bones, which was already done
            var range: AnimationRange = source.getAnimationRange(name);
            this._ranges[name] = new AnimationRange(name, range.from + frameOffset, range.to + frameOffset);
            return ret;
        }

        public function returnToRest(): void {
            for (var index: int = 0; index < this.bones.length; index++) {
                this.bones[index].returnToRest();
            }
        }

        private function _getHighestAnimationFrame(): int {
            var ret: int = 0;
            for (var i: int = 0, nBones: int = this.bones.length; i < nBones; i++) {
                if (this.bones[i].animations[0]) {
                    var highest: int = this.bones[i].animations[0].getHighestFrame();
                    if (ret < highest) {
                        ret = highest;
                    }
                }
            }
            return ret;
        }

        public function beginAnimation(name: String, loop: Boolean = false, speedRatio: Number = NaN, onAnimationEnd: Function = null): Animatable {
            var range: AnimationRange = this.getAnimationRange(name);

            if (!range) {
                return null;
            }

            return this._scene.beginAnimation(this, range.from, range.to, loop, speedRatio, onAnimationEnd);
        }

        public function _markAsDirty(): void {
            this._isDirty = true;
        }

        public function _registerMeshWithPoseMatrix(mesh: AbstractMesh): void {
            this._meshesWithPoseMatrix.push(mesh);
        }

        public function _unregisterMeshWithPoseMatrix(mesh: AbstractMesh): void {
            var index: int = this._meshesWithPoseMatrix.indexOf(mesh);

            if (index > -1) {
                this._meshesWithPoseMatrix.splice(index, 1);
            }
        }

        public function _computeTransformMatrices(targetMatrix: Vector.<Number>, initialSkinMatrix: Matrix): void {
            for (var index: int = 0; index < this.bones.length; index++) {
                var bone: Bone = this.bones[index];
                var parentBone: Bone = bone.getParent();

                if (parentBone) {
                    bone.getLocalMatrix().multiplyToRef(parentBone.getWorldMatrix(), bone.getWorldMatrix());
                } else {
                    if (initialSkinMatrix) {
                        bone.getLocalMatrix().multiplyToRef(initialSkinMatrix, bone.getWorldMatrix());
                    } else {
                        bone.getWorldMatrix().copyFrom(bone.getLocalMatrix());
                    }
                }

                bone.getInvertedAbsoluteTransform().multiplyToArray(bone.getWorldMatrix(), targetMatrix, index * 16);
            }

            this._identity.copyToArray(targetMatrix, this.bones.length * 16);
        }

        public function prepare(): void {
            if (!this._isDirty) {
                return;
            }

            if (this.needInitialSkinMatrix) {
                for (var index: int = 0; index < this._meshesWithPoseMatrix.length; index++) {
                    var mesh: AbstractMesh = this._meshesWithPoseMatrix[index];

                    if (!mesh._bonesTransformMatrices || mesh._bonesTransformMatrices.length !== 16 * (this.bones.length + 1)) {
                        mesh._bonesTransformMatrices = new Vector.<Number>(16 * (this.bones.length + 1));
                    }

                    var poseMatrix: Matrix = mesh.getPoseMatrix();

                    // Prepare bones
                    for (var boneIndex: int = 0; boneIndex < this.bones.length; boneIndex++) {
                        var bone: Bone = this.bones[boneIndex];

                        if (!bone.getParent()) {
                            var matrix: Matrix = bone.getBaseMatrix();
                            matrix.multiplyToRef(poseMatrix, Tmp.MATRIX[0]);
                            bone._updateDifferenceMatrix(Tmp.MATRIX[0]);
                        }
                    }

                    this._computeTransformMatrices(mesh._bonesTransformMatrices, poseMatrix);
                }
            } else {
                if (!this._transformMatrices || this._transformMatrices.length !== 16 * (this.bones.length + 1)) {
                    this._transformMatrices = new Vector.<Number>(16 * (this.bones.length + 1));
                }

                this._computeTransformMatrices(this._transformMatrices, null);
            }

            this._isDirty = false;

            this._scene._activeBones.addCount(this.bones.length, false);
        }

        public function getAnimatables(): Array {
            if (!this._animatables || this._animatables.length !== this.bones.length) {
                this._animatables = [];

                for (var index: int = 0; index < this.bones.length; index++) {
                    this._animatables.push(this.bones[index]);
                }
            }

            return this._animatables;
        }

        public function clone(name: String, id: String): Skeleton {
            var result: Skeleton = new Skeleton(name, id || name, this._scene);

            result.needInitialSkinMatrix = this.needInitialSkinMatrix;

            for (var index: int = 0; index < this.bones.length; index++) {
                var source: Bone = this.bones[index];
                var parentBone: Bone = null;

                if (source.getParent()) {
                    var parentIndex: int = this.bones.indexOf(source.getParent());
                    parentBone = result.bones[parentIndex];
                }

//                var bone: Bone = new Bone(source.name, result, parentBone, source.getBaseMatrix().clone(), source.getRestPose().clone());
//                Tools.DeepCopy(source.animations, bone.animations);
                fail();
            }

            if (this._ranges) {
                result._ranges = new Dictionary(true);
                for (var rangeName: String in this._ranges) {
                    result._ranges[rangeName] = this._ranges[rangeName].clone();
                }
            }

            this._isDirty = true;

            return result;
        }

        public function enableBlending(blendingSpeed: Number = 0.01): void {
            this.bones.forEach(function (bone: Bone): void {
                bone.animations.forEach(function (animation: Animation): void {
                    animation.enableBlending = true;
                    animation.blendingSpeed = blendingSpeed;
                });
            });
        }

        public function dispose(): void {
            this._meshesWithPoseMatrix = new <AbstractMesh>[];

            // Animations
            this.getScene().stopAnimation(this);

            // Remove from scene
            this.getScene().removeSkeleton(this);
        }

        public function serialize(): Object {
            var serializationObject: Object = {};

            serializationObject.name = this.name;
            serializationObject.id = this.id;
            serializationObject.dimensionsAtRest = this.dimensionsAtRest;

            serializationObject.bones = [];

            serializationObject.needInitialSkinMatrix = this.needInitialSkinMatrix;

            for (var index: int = 0; index < this.bones.length; index++) {
                var bone: Bone = this.bones[index];

                var serializedBone: Object = {
                    parentBoneIndex: bone.getParent() ? this.bones.indexOf(bone.getParent()) : -1,
                    name: bone.name,
                    matrix: bone.getLocalMatrix().toArray(),
                    rest: bone.getRestPose().toArray()
                };

                serializationObject.bones.push(serializedBone);

                if (bone.length) {
                    serializedBone.length = bone.length;
                }

                if (bone.animations && bone.animations.length > 0) {
                    serializedBone.animation = bone.animations[0].serialize();
                }

                serializationObject.ranges = [];
                for (var name: String in this._ranges) {
                    var range: Object = {};
                    range.name = name;
                    range.from = this._ranges[name].from;
                    range.to = this._ranges[name].to;
                    serializationObject.ranges.push(range);
                }
            }
            return serializationObject;
        }

        public static function Parse(parsedSkeleton: Object, scene: Scene): Skeleton {
            var skeleton: Skeleton = new Skeleton(parsedSkeleton.name, parsedSkeleton.id, scene);
            if (parsedSkeleton.dimensionsAtRest) {
                skeleton.dimensionsAtRest = Vector3.FromArray(parsedSkeleton.dimensionsAtRest);
            }

            skeleton.needInitialSkinMatrix = parsedSkeleton.needInitialSkinMatrix;

            var index: int;
            for (index = 0; index < parsedSkeleton.bones.length; index++) {
                var parsedBone: Object = parsedSkeleton.bones[index];

                var parentBone: Bone = null;
                if (parsedBone.parentBoneIndex > -1) {
                    parentBone = skeleton.bones[parsedBone.parentBoneIndex];
                }
                var rest: Matrix = parsedBone.rest ? Matrix.FromArray(parsedBone.rest) : null;
                var bone: Bone = new Bone(parsedBone.name, skeleton, parentBone, Matrix.FromArray(Vector.<Number>(parsedBone.matrix)), rest);

                if (parsedBone.length) {
                    bone.length = parsedBone.length;
                }

                if (parsedBone.animation) {
                    bone.animations.push(Animation.Parse(parsedBone.animation));
                }
            }

            // placed after bones, so createAnimationRange can cascade down
            if (parsedSkeleton.ranges) {
                for (index = 0; index < parsedSkeleton.ranges.length; index++) {
                    var data: Object = parsedSkeleton.ranges[index];
                    skeleton.createAnimationRange(data.name, data.from, data.to);
                }
            }
            return skeleton;
        }
    }
}
