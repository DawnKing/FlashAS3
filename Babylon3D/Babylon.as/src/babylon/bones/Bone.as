/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.bones {
    import babylon.Node;
    import babylon.animations.Animation;
    import babylon.animations.AnimationRange;
    import babylon.math.Matrix;
    import babylon.math.Vector3;

    public class Bone extends Node {
        public var children: Vector.<Bone> = new <Bone>[];
        public var length: Number;

        private var _skeleton: Skeleton;
        public var _matrix: Matrix;
        private var _restPose: Matrix;
        private var _baseMatrix: Matrix;
        private var _worldTransform: Matrix = new Matrix();
        private var _absoluteTransform: Matrix = new Matrix();
        private var _invertedAbsoluteTransform: Matrix = new Matrix();
        private var _parent: Bone;

        public function Bone(name: String, skeleton: Skeleton, parentBone: Bone, matrix: Matrix, restPose: Matrix = null) {
            super(name, skeleton.getScene());
            this._skeleton = skeleton;
            this._matrix = matrix;
            this._baseMatrix = matrix;
            this._restPose = restPose ? restPose : matrix.clone();

            skeleton.bones.push(this);

            if (parentBone) {
                this._parent = parentBone;
                parentBone.children.push(this);
            } else {
                this._parent = null;
            }

            this._updateDifferenceMatrix();
        }

        // Members
        public function getParent(): Bone {
            return this._parent;
        }

        public function getLocalMatrix(): Matrix {
            return this._matrix;
        }

        public function getBaseMatrix(): Matrix {
            return this._baseMatrix;
        }

        public function getRestPose(): Matrix {
            return this._restPose;
        }

        public function returnToRest(): void {
            this.updateMatrix(this._restPose.clone());
        }

        override public function getWorldMatrix(): Matrix {
            return this._worldTransform;
        }

        public function getInvertedAbsoluteTransform(): Matrix {
            return this._invertedAbsoluteTransform;
        }

        public function getAbsoluteTransform(): Matrix {
            return this._absoluteTransform;
        }

        // Methods
        public function updateMatrix(matrix: Matrix, updateDifferenceMatrix: Boolean = true): void {
            this._baseMatrix = matrix.clone();
            this._matrix = matrix.clone();

            this._skeleton._markAsDirty();

            if (updateDifferenceMatrix) {
                this._updateDifferenceMatrix();
            }
        }

        public function _updateDifferenceMatrix(rootMatrix: Matrix = null): void {
            if (!rootMatrix) {
                rootMatrix = this._baseMatrix;
            }

            if (this._parent) {
                rootMatrix.multiplyToRef(this._parent._absoluteTransform, this._absoluteTransform);
            } else {
                this._absoluteTransform.copyFrom(rootMatrix);
            }

            this._absoluteTransform.invertToRef(this._invertedAbsoluteTransform);

            for (var index: int = 0; index < this.children.length; index++) {
                this.children[index]._updateDifferenceMatrix();
            }
        }

        public function markAsDirty(): void {
            this._currentRenderId++;
            this._skeleton._markAsDirty();
        }

        public function copyAnimationRange(source: Bone, rangeName: String, frameOffset: Number, rescaleAsRequired: Boolean = false, skelDimensionsRatio: Vector3 = null): Boolean {
            // all animation may be coming from a library skeleton, so may need to create animation
            if (this.animations.length === 0) {
                this.animations.push(new Animation(this.name, "_matrix", source.animations[0].framePerSecond, Animation.ANIMATIONTYPE_MATRIX, 0));
                this.animations[0].setKeys(new <Object>[]);
            }

            // get animation info / verify there is such a range from the source bone
            var sourceRange: AnimationRange = source.animations[0].getRange(rangeName);
            if (!sourceRange) {
                return false;
            }
            var from: int = sourceRange.from;
            var to: int = sourceRange.to;
            var sourceKeys: Vector.<Object> = source.animations[0].getKeys();

            // rescaling prep
            var sourceBoneLength: int = source.length;
            var sourceParent: Bone = source.getParent();
            var parent: Bone = this.getParent();
            var parentScalingReqd: Boolean = rescaleAsRequired && sourceParent && sourceBoneLength && this.length && sourceBoneLength !== this.length;
            var parentRatio: int = parentScalingReqd ? parent.length / sourceParent.length : 0;

            var dimensionsScalingReqd: Boolean = rescaleAsRequired && !parent && skelDimensionsRatio && (skelDimensionsRatio.x !== 1 || skelDimensionsRatio.y !== 1 || skelDimensionsRatio.z !== 1);

            var destKeys: Vector.<Object> = this.animations[0].getKeys();

            // loop vars declaration
            var orig: Object;   // frame: Number, value: Matrix
            var origTranslation : Vector3;
            var mat: Matrix;

            for (var key: int = 0, nKeys: int = sourceKeys.length; key < nKeys; key++) {
                orig = sourceKeys[key];
                if (orig.frame >= from && orig.frame <= to) {
                    if (rescaleAsRequired) {
                        mat = orig.value.clone();

                        // scale based on parent ratio, when bone has parent
                        if (parentScalingReqd) {
                            origTranslation = mat.getTranslation();
                            mat.setTranslation(origTranslation.scaleInPlace(parentRatio));

                            // scale based on skeleton dimension ratio when root bone, and value is passed
                        } else if (dimensionsScalingReqd) {
                            origTranslation = mat.getTranslation();
                            mat.setTranslation(origTranslation.multiplyInPlace(skelDimensionsRatio));

                            // use original when root bone, and no data for skelDimensionsRatio
                        } else {
                            mat = orig.value;
                        }
                    } else {
                        mat = orig.value;
                    }
                    destKeys.push({ frame: orig.frame + frameOffset, value: mat });
                }
            }
            this.animations[0].createRange(rangeName, from + frameOffset, to + frameOffset);
            return true;
        }
    }
}
